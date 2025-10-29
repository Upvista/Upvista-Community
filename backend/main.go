package main

import (
	"log"
	"net/http"
	"time"

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

	// Initialize repository (provider selected via env)
	userRepo, err := repository.NewUserRepository(cfg)
	if err != nil {
		log.Fatalf("Failed to initialize repository: %v", err)
	}

	// Initialize services
	emailSvc := utils.NewEmailService(&cfg.Email)
	jwtSvc := utils.NewJWTService(cfg.JWT.Secret, 15*time.Minute)

	// Initialize authentication service
	authSvc := auth.NewAuthService(userRepo, emailSvc, jwtSvc)

	// Initialize handlers
	authHandlers := auth.NewAuthHandlers(authSvc, jwtSvc)

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

		// Setup authentication routes
		authHandlers.SetupRoutes(api)
	}

	// Start server
	log.Printf("Starting server on port %s", cfg.Server.Port)
	if err := r.Run(":" + cfg.Server.Port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
