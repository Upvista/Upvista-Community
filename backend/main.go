package main

import (
	"log"
	"net/http"
	"time"

	"upvista-community-backend/internal/account"
	"upvista-community-backend/internal/auth"
	"upvista-community-backend/internal/config"
	"upvista-community-backend/internal/repository"
	"upvista-community-backend/internal/utils"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func main() {
	// Load configuration
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Set Gin mode based on configuration
	if cfg.Server.GinMode == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Initialize repositories (provider selected via env)
	userRepo, err := repository.NewUserRepository(cfg)
	if err != nil {
		log.Fatalf("Failed to initialize user repository: %v", err)
	}

	sessionRepo, err := repository.NewSessionRepository(cfg)
	if err != nil {
		log.Fatalf("Failed to initialize session repository: %v", err)
	}

	// Initialize services
	emailSvc := utils.NewEmailService(&cfg.Email)
	jwtSvc := utils.NewJWTService(cfg.JWT.Secret, 15*time.Minute)

	// Initialize rate limiter with forgiveness
	rateLimiter := utils.NewRateLimiter(cfg.RateLimit.Forgiveness)

	// Initialize token blacklist for logout functionality
	tokenBlacklist := utils.NewTokenBlacklist()

	// Set blacklist on JWT service for token validation
	jwtSvc.SetBlacklist(tokenBlacklist)

	// Initialize authentication service
	authSvc := auth.NewAuthService(userRepo, emailSvc, jwtSvc, tokenBlacklist)

	// Initialize OAuth services
	googleOAuth := auth.NewGoogleOAuthService(&cfg.Google, userRepo, jwtSvc)
	githubOAuth := auth.NewGitHubOAuthService(&cfg.GitHub, userRepo, jwtSvc)
	linkedinOAuth := auth.NewLinkedInOAuthService(&cfg.LinkedIn, userRepo, jwtSvc)

	// Initialize storage service
	storageSvc := utils.NewStorageService(&cfg.Storage, cfg.Database.SupabaseURL, cfg.Database.SupabaseServiceKey)

	// Initialize account service
	accountSvc := account.NewAccountService(userRepo, sessionRepo, emailSvc, storageSvc)

	// Initialize handlers
	authHandlers := auth.NewAuthHandlers(authSvc, jwtSvc, rateLimiter, cfg, googleOAuth, githubOAuth, linkedinOAuth, sessionRepo)
	accountHandlers := account.NewAccountHandlers(accountSvc)

	// Create Gin router with middleware
	r := gin.Default()

	// CORS middleware
	corsConfig := cors.Config{
		AllowOrigins:     cfg.GetCORSOrigins(),
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}
	r.Use(cors.New(corsConfig))

	// Health check endpoint
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "upvista-community-backend",
			"version": "1.0.0",
		})
	})

	// Welcome endpoint
	r.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "Welcome to UpVista Community Backend API",
			"service": "upvista-community-backend",
			"version": "1.0.0",
		})
	})

	// API routes group
	api := r.Group("/api/v1")
	{
		api.GET("/status", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"status": "running",
				"api":    "v1",
			})
		})

		// Test Supabase connectivity endpoint
		api.GET("/test-db", func(c *gin.Context) {
			log.Println("[Test] Testing Supabase connection...")
			emailExists, err := userRepo.CheckEmailExists(c.Request.Context(), "test@example.com")
			if err != nil {
				log.Printf("[Test] Database error: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{
					"success": false,
					"error":   err.Error(),
				})
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"success":     true,
				"message":     "Database connection successful",
				"emailExists": emailExists,
			})
		})

		// Setup authentication routes
		authHandlers.SetupRoutes(api)

		// Setup account management routes (protected by JWT middleware)
		protected := api.Group("")
		protected.Use(auth.JWTAuthMiddleware(jwtSvc))
		accountHandlers.SetupRoutes(protected)
	}

	// Start server
	log.Printf("Starting server on port %s", cfg.Server.Port)
	if err := r.Run(":" + cfg.Server.Port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
