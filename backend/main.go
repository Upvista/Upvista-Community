package main

import (
	"context"
	"log"
	"net/http"
	"time"

	"upvista-community-backend/internal/account"
	"upvista-community-backend/internal/auth"
	"upvista-community-backend/internal/cache"
	"upvista-community-backend/internal/config"
	"upvista-community-backend/internal/jobs"
	"upvista-community-backend/internal/messaging"
	"upvista-community-backend/internal/notifications"
	"upvista-community-backend/internal/posts"
	"upvista-community-backend/internal/repository"
	"upvista-community-backend/internal/search"
	"upvista-community-backend/internal/social"
	"upvista-community-backend/internal/utils"
	"upvista-community-backend/internal/websocket"

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

	// Initialize experience and education repositories
	expRepo := repository.NewSupabaseExperienceRepository(cfg.Database.SupabaseURL, cfg.Database.SupabaseServiceKey)
	eduRepo := repository.NewSupabaseEducationRepository(cfg.Database.SupabaseURL, cfg.Database.SupabaseServiceKey)

	// Initialize services
	emailSvc := utils.NewEmailService(&cfg.Email)
	// JWT tokens valid for 30 days with sliding window refresh
	jwtSvc := utils.NewJWTService(cfg.JWT.Secret, 30*24*time.Hour)

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

	// Initialize profile service
	profileSvc := account.NewProfileService(userRepo)

	// Initialize experience and education service
	expEduSvc := account.NewExperienceEducationService(expRepo, eduRepo)

	// Initialize relationship repository
	relationshipRepo, err := repository.NewRelationshipRepository(cfg)
	if err != nil {
		log.Fatalf("Failed to initialize relationship repository: %v", err)
	}

	// Initialize notification repository
	notificationRepo, err := repository.NewNotificationRepository(cfg)
	if err != nil {
		log.Fatalf("Failed to initialize notification repository: %v", err)
	}

	// Initialize WebSocket manager
	wsManager := websocket.NewManager()
	go wsManager.Run() // Start WebSocket manager in background

	// Initialize notification email service
	baseURL := "http://localhost:3001" // Frontend URL for email links (configure in production)
	notificationEmailSvc := notifications.NewEmailService(emailSvc, baseURL)

	// Initialize notification service
	notificationSvc := notifications.NewNotificationService(notificationRepo, userRepo, wsManager, notificationEmailSvc)

	// Initialize relationship service with notification support
	relationshipSvc := social.NewRelationshipService(relationshipRepo, userRepo)
	relationshipSvc.SetNotificationService(notificationSvc) // Add notification support

	// Initialize search service
	searchSvc := search.NewSearchService(userRepo)

	// ============================================
	// MESSAGING SYSTEM INITIALIZATION
	// ============================================

	// Initialize Redis client for messaging cache
	redisClient, err := cache.InitializeRedis(cfg.Redis.Host, cfg.Redis.Port, cfg.Redis.Password, cfg.Redis.DB)
	if err != nil {
		log.Printf("[Warning] Failed to connect to Redis: %v (messaging cache disabled)", err)
		redisClient = nil
	} else {
		log.Println("[Redis] Connected successfully")
	}

	// Initialize message cache service (only if Redis is available)
	var messageCacheSvc *cache.MessageCacheService
	if redisClient != nil {
		messageCacheSvc = cache.NewMessageCacheService(redisClient)
	}

	// Initialize message repository
	messageRepo, err := repository.NewMessageRepository(cfg)
	if err != nil {
		log.Fatalf("Failed to initialize message repository: %v", err)
	}

	// Initialize media optimizer
	mediaOptimizer := messaging.NewMediaOptimizer()

	// Initialize messaging service (with notification support)
	messagingSvc := messaging.NewMessagingService(messageRepo, messageCacheSvc, wsManager, userRepo, notificationSvc)

	// Initialize message handlers
	messageHandlers := messaging.NewMessageHandlers(messagingSvc, storageSvc, mediaOptimizer)

	// ============================================
	// POSTS & FEED SYSTEM INITIALIZATION
	// ============================================

	// Initialize post repositories
	postRepo := repository.NewSupabasePostRepository(cfg.Database.SupabaseURL, cfg.Database.SupabaseServiceKey)
	pollRepo := repository.NewSupabasePollRepository(cfg.Database.SupabaseURL, cfg.Database.SupabaseServiceKey)
	articleRepo := repository.NewSupabaseArticleRepository(cfg.Database.SupabaseURL, cfg.Database.SupabaseServiceKey)
	commentRepo := repository.NewSupabaseCommentRepository(cfg.Database.SupabaseURL, cfg.Database.SupabaseServiceKey)

	// Initialize post service
	postSvc := posts.NewService(postRepo, pollRepo, articleRepo, commentRepo, wsManager)

	// Initialize feed service
	feedSvc := posts.NewFeedService(postRepo, relationshipRepo)

	// Initialize post handlers
	postHandlers := posts.NewHandlers(postSvc, feedSvc)

	log.Println("[Posts] Post & feed system initialized")

	// Initialize background jobs
	cleanupJob := jobs.NewNotificationCleanupJob(notificationRepo)
	digestJob := jobs.NewNotificationDigestJob(notificationRepo, userRepo, notificationEmailSvc)
	hashtagTrendingJob := jobs.NewHashtagTrendingJob(cfg.Database.SupabaseURL, cfg.Database.SupabaseServiceKey)

	// Start background jobs
	jobCtx := context.Background()
	go cleanupJob.Start(jobCtx)         // Runs daily at 2:00 AM
	go digestJob.StartDaily(jobCtx)     // Runs daily at 9:00 AM
	go digestJob.StartWeekly(jobCtx)    // Runs Monday at 9:00 AM
	go hashtagTrendingJob.Start(jobCtx) // Runs daily at 3:00 AM

	log.Println("[Jobs] Background jobs started: cleanup (2 AM), digest (9 AM), hashtag trending (3 AM)")

	// Initialize handlers
	authHandlers := auth.NewAuthHandlers(authSvc, jwtSvc, rateLimiter, cfg, googleOAuth, githubOAuth, linkedinOAuth, sessionRepo)
	accountHandlers := account.NewAccountHandlers(accountSvc, profileSvc)
	expEduHandlers := account.NewExperienceEducationHandlers(expEduSvc)
	relationshipHandlers := social.NewRelationshipHandlers(relationshipSvc)
	searchHandlers := search.NewSearchHandlers(searchSvc)
	wsHandlers := websocket.NewHandlers(wsManager, jwtSvc)
	notificationHandlers := notifications.NewHandlers(notificationSvc)

	// Create Gin router with middleware
	r := gin.Default()

	// CORS middleware
	corsConfig := cors.Config{
		AllowOrigins:     cfg.GetCORSOrigins(),
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
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

		// Experience and education routes (protected)
		protected.POST("/account/experiences", expEduHandlers.CreateExperience)
		protected.GET("/account/experiences", expEduHandlers.GetMyExperiences)
		protected.PATCH("/account/experiences/:id", expEduHandlers.UpdateExperience)
		protected.DELETE("/account/experiences/:id", expEduHandlers.DeleteExperience)

		protected.POST("/account/education", expEduHandlers.CreateEducation)
		protected.GET("/account/education", expEduHandlers.GetMyEducation)
		protected.PATCH("/account/education/:id", expEduHandlers.UpdateEducation)
		protected.DELETE("/account/education/:id", expEduHandlers.DeleteEducation)

		// Relationship routes (protected)
		relationshipHandlers.SetupRoutes(protected)

		// Notification routes (protected)
		notificationHandlers.SetupRoutes(protected)

		// Messaging routes (protected)
		messagingGroup := protected.Group("/conversations")
		{
			// Conversations list and count (must come before :id routes)
			messagingGroup.GET("", messageHandlers.GetConversations)
			messagingGroup.GET("/unread-count", messageHandlers.GetUnreadCount)

			// Messages in conversation (specific routes with :id before catch-all)
			messagingGroup.GET("/:id/messages", messageHandlers.GetMessages)
			messagingGroup.POST("/:id/messages", messageHandlers.SendMessage)
			messagingGroup.PATCH("/:id/read", messageHandlers.MarkAsRead)

			// Pinned messages and search
			messagingGroup.GET("/:id/pinned", messageHandlers.GetPinnedMessages)
			messagingGroup.GET("/:id/search", messageHandlers.SearchConversationMessages)

			// Typing indicators
			messagingGroup.POST("/:id/typing/start", messageHandlers.StartTyping)
			messagingGroup.POST("/:id/typing/stop", messageHandlers.StopTyping)

			// Single conversation and start conversation (must come last)
			messagingGroup.GET("/:id", messageHandlers.GetConversation)
			messagingGroup.POST("/start/:userId", messageHandlers.StartConversation)
		}

		// Message-specific routes (protected)
		messageGroup := protected.Group("/messages")
		{
			messageGroup.GET("/search", messageHandlers.SearchMessages)
			messageGroup.GET("/starred", messageHandlers.GetStarredMessages)
			messageGroup.DELETE("/:id", messageHandlers.DeleteMessage)

			// Reactions
			messageGroup.POST("/:id/reactions", messageHandlers.AddReaction)
			messageGroup.DELETE("/:id/reactions", messageHandlers.RemoveReaction)

			// Starred
			messageGroup.POST("/:id/star", messageHandlers.StarMessage)
			messageGroup.DELETE("/:id/star", messageHandlers.UnstarMessage)

			// Pin/Unpin
			messageGroup.POST("/:id/pin", messageHandlers.PinMessage)
			messageGroup.DELETE("/:id/pin", messageHandlers.UnpinMessage)

			// Edit
			messageGroup.PATCH("/:id", messageHandlers.EditMessage)
			messageGroup.GET("/:id/edit-history", messageHandlers.GetMessageEditHistory)

			// Forward
			messageGroup.POST("/:id/forward", messageHandlers.ForwardMessage)

			// Media uploads
			messageGroup.POST("/upload-image", messageHandlers.UploadImage)
			messageGroup.POST("/upload-audio", messageHandlers.UploadAudio)
			messageGroup.POST("/upload-file", messageHandlers.UploadFile)
			messageGroup.POST("/upload-video", messageHandlers.UploadVideo)
		}

		// Presence routes (protected)
		presenceGroup := protected.Group("/users")
		{
			presenceGroup.GET("/:id/presence", messageHandlers.GetUserPresence)
			presenceGroup.GET("/presence/bulk", messageHandlers.GetBulkPresence)
		}

		// Search routes (public - no auth required)
		searchHandlers.SetupRoutes(api)

		// ============================================
		// POSTS & FEED ROUTES
		// ============================================

		// Posts CRUD (protected)
		postsGroup := protected.Group("/posts")
		{
			postsGroup.POST("", postHandlers.CreatePost)                 // Create post
			postsGroup.GET("/:id", postHandlers.GetPost)                 // Get single post
			postsGroup.PUT("/:id", postHandlers.UpdatePost)              // Update post
			postsGroup.DELETE("/:id", postHandlers.DeletePost)           // Delete post
			postsGroup.GET("/user/:username", postHandlers.GetUserPosts) // User's posts

			// Engagement
			postsGroup.POST("/:id/like", postHandlers.LikePost)     // Like post
			postsGroup.DELETE("/:id/like", postHandlers.UnlikePost) // Unlike post
			postsGroup.POST("/:id/share", postHandlers.SharePost)   // Share post
			postsGroup.POST("/:id/save", postHandlers.SavePost)     // Save post
			postsGroup.DELETE("/:id/save", postHandlers.UnsavePost) // Unsave post

			// Comments
			postsGroup.POST("/:id/comments", postHandlers.CreateComment) // Create comment
			postsGroup.GET("/:id/comments", postHandlers.GetComments)    // Get comments

			// Polls
			postsGroup.POST("/:id/vote", postHandlers.VotePoll)         // Vote on poll
			postsGroup.GET("/:id/results", postHandlers.GetPollResults) // Get poll results
		}

		// Comments (protected)
		commentsGroup := protected.Group("/comments")
		{
			commentsGroup.PUT("/:id", postHandlers.UpdateComment)     // Update comment
			commentsGroup.DELETE("/:id", postHandlers.DeleteComment)  // Delete comment
			commentsGroup.POST("/:id/like", postHandlers.LikeComment) // Like comment
		}

		// Feed (protected)
		feedGroup := protected.Group("/feed")
		{
			feedGroup.GET("/home", postHandlers.GetHomeFeed)           // Home feed
			feedGroup.GET("/following", postHandlers.GetFollowingFeed) // Following feed
			feedGroup.GET("/explore", postHandlers.GetExploreFeed)     // Explore feed
			feedGroup.GET("/saved", postHandlers.GetSavedFeed)         // Saved posts
		}

		// Hashtags (mixed public/protected)
		hashtagGroup := api.Group("/hashtags")
		{
			hashtagGroup.GET("/:tag/posts", postHandlers.GetHashtagFeed)    // Hashtag feed (public)
			hashtagGroup.GET("/trending", postHandlers.GetTrendingHashtags) // Trending (public)

			// Protected hashtag actions
			hashtagProtected := hashtagGroup.Group("")
			hashtagProtected.Use(auth.JWTAuthMiddleware(jwtSvc))
			{
				hashtagProtected.POST("/:tag/follow", postHandlers.FollowHashtag)     // Follow hashtag
				hashtagProtected.DELETE("/:tag/follow", postHandlers.UnfollowHashtag) // Unfollow hashtag
			}
		}

		log.Println("[Routes] Post & feed routes registered")

		// WebSocket route (protected - JWT in query param or header)
		wsHandlers.SetupRoutes(api)
	}

	// Start server
	log.Printf("Starting server on port %s", cfg.Server.Port)
	if err := r.Run(":" + cfg.Server.Port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
