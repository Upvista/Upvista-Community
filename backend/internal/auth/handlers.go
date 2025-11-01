package auth

import (
	"fmt"
	"net/http"
	"strings"
	"time"

	"upvista-community-backend/internal/config"
	"upvista-community-backend/internal/models"
	"upvista-community-backend/internal/utils"
	"upvista-community-backend/pkg/errors"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// AuthHandlers handles HTTP requests for authentication
type AuthHandlers struct {
	authSvc       *AuthService
	jwtSvc        *utils.JWTService
	rateLimiter   *utils.RateLimiter
	config        *config.Config
	googleOAuth   *GoogleOAuthService
	githubOAuth   *GitHubOAuthService
	linkedinOAuth *LinkedInOAuthService
}

// NewAuthHandlers creates new authentication handlers
func NewAuthHandlers(
	authSvc *AuthService,
	jwtSvc *utils.JWTService,
	rateLimiter *utils.RateLimiter,
	cfg *config.Config,
	googleOAuth *GoogleOAuthService,
	githubOAuth *GitHubOAuthService,
	linkedinOAuth *LinkedInOAuthService,
) *AuthHandlers {
	return &AuthHandlers{
		authSvc:       authSvc,
		jwtSvc:        jwtSvc,
		rateLimiter:   rateLimiter,
		config:        cfg,
		googleOAuth:   googleOAuth,
		githubOAuth:   githubOAuth,
		linkedinOAuth: linkedinOAuth,
	}
}

// RegisterHandler handles user registration
func (h *AuthHandlers) RegisterHandler(c *gin.Context) {
	var req models.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
			"error":   err.Error(),
		})
		return
	}

	response, err := h.authSvc.RegisterUser(c.Request.Context(), &req)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
			"error":   appErr.Details,
		})
		return
	}

	c.JSON(http.StatusOK, response)
}

// VerifyEmailHandler handles email verification
func (h *AuthHandlers) VerifyEmailHandler(c *gin.Context) {
	var req models.VerifyEmailRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
			"error":   err.Error(),
		})
		return
	}

	response, err := h.authSvc.VerifyEmail(c.Request.Context(), &req)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
			"error":   appErr.Details,
		})
		return
	}

	c.JSON(http.StatusOK, response)
}

// LoginHandler handles user login
func (h *AuthHandlers) LoginHandler(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
			"error":   err.Error(),
		})
		return
	}

	response, err := h.authSvc.LoginUser(c.Request.Context(), &req)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
			"error":   appErr.Details,
		})
		return
	}

	c.JSON(http.StatusOK, response)
}

// ForgotPasswordHandler handles password reset request
func (h *AuthHandlers) ForgotPasswordHandler(c *gin.Context) {
	var req models.ForgotPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
			"error":   err.Error(),
		})
		return
	}

	response, err := h.authSvc.ForgotPassword(c.Request.Context(), &req)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
			"error":   appErr.Details,
		})
		return
	}

	c.JSON(http.StatusOK, response)
}

// ResetPasswordHandler handles password reset
func (h *AuthHandlers) ResetPasswordHandler(c *gin.Context) {
	var req models.ResetPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
			"error":   err.Error(),
		})
		return
	}

	response, err := h.authSvc.ResetPassword(c.Request.Context(), &req)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
			"error":   appErr.Details,
		})
		return
	}

	c.JSON(http.StatusOK, response)
}

// MeHandler handles getting current user information
func (h *AuthHandlers) MeHandler(c *gin.Context) {
	userIDStr, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "User not authenticated",
		})
		return
	}

	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
		})
		return
	}

	response, err := h.authSvc.GetCurrentUser(c.Request.Context(), userID)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
			"error":   appErr.Details,
		})
		return
	}

	c.JSON(http.StatusOK, response)
}

// RefreshHandler handles token refresh
func (h *AuthHandlers) RefreshHandler(c *gin.Context) {
	userIDStr, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "User not authenticated",
		})
		return
	}

	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
		})
		return
	}

	response, err := h.authSvc.RefreshToken(c.Request.Context(), userID)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
			"error":   appErr.Details,
		})
		return
	}

	c.JSON(http.StatusOK, response)
}

// LogoutHandler handles user logout
func (h *AuthHandlers) LogoutHandler(c *gin.Context) {
	userIDStr, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "User not authenticated",
		})
		return
	}

	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
		})
		return
	}

	// Extract token from Authorization header for blacklisting
	authHeader := c.GetHeader("Authorization")
	var token string
	if authHeader != "" {
		tokenParts := strings.Split(authHeader, " ")
		if len(tokenParts) == 2 && tokenParts[0] == "Bearer" {
			token = tokenParts[1]
		}
	}

	response, err := h.authSvc.LogoutUser(c.Request.Context(), userID, token)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
			"error":   appErr.Details,
		})
		return
	}

	c.JSON(http.StatusOK, response)
}

// GoogleLoginHandler initiates Google OAuth flow
func (h *AuthHandlers) GoogleLoginHandler(c *gin.Context) {
	// Generate state token for CSRF protection
	state := uuid.New().String()

	// Get Google auth URL
	authURL := h.googleOAuth.GetAuthURL(state)

	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"auth_url": authURL,
		"state":    state, // Return state to frontend for validation
	})
}

// GoogleExchangeHandler exchanges Google OAuth code for token
func (h *AuthHandlers) GoogleExchangeHandler(c *gin.Context) {
	type ExchangeRequest struct {
		Code string `json:"code"`
	}

	var req ExchangeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
		})
		return
	}

	// Handle callback
	response, err := h.googleOAuth.HandleCallback(c.Request.Context(), req.Code)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
			"error":   appErr.Details,
		})
		return
	}

	c.JSON(http.StatusOK, response)
}

// GoogleCallbackHandler handles Google OAuth callback
func (h *AuthHandlers) GoogleCallbackHandler(c *gin.Context) {
	// Get authorization code and state
	code := c.Query("code")
	state := c.Query("state")

	if code == "" {
		// Redirect to frontend with error
		c.Redirect(http.StatusTemporaryRedirect, "http://localhost:3001/auth/callback?error=no_code&provider=google")
		return
	}

	// For direct callback from OAuth provider, redirect to frontend with code and state
	// Frontend will then call backend API to exchange code for token
	redirectURL := fmt.Sprintf("http://localhost:3001/auth/callback?provider=google&code=%s&state=%s",
		code, state)
	c.Redirect(http.StatusTemporaryRedirect, redirectURL)
}

// GitHubLoginHandler initiates GitHub OAuth flow
func (h *AuthHandlers) GitHubLoginHandler(c *gin.Context) {
	// Generate state token for CSRF protection
	state := uuid.New().String()

	// Get GitHub auth URL
	authURL := h.githubOAuth.GetAuthURL(state)

	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"auth_url": authURL,
		"state":    state,
	})
}

// GitHubExchangeHandler exchanges GitHub OAuth code for token
func (h *AuthHandlers) GitHubExchangeHandler(c *gin.Context) {
	type ExchangeRequest struct {
		Code string `json:"code"`
	}

	var req ExchangeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
		})
		return
	}

	response, err := h.githubOAuth.HandleCallback(c.Request.Context(), req.Code)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
			"error":   appErr.Details,
		})
		return
	}

	c.JSON(http.StatusOK, response)
}

// GitHubCallbackHandler handles GitHub OAuth callback
func (h *AuthHandlers) GitHubCallbackHandler(c *gin.Context) {
	// Get authorization code and state
	code := c.Query("code")
	state := c.Query("state")

	if code == "" {
		c.Redirect(http.StatusTemporaryRedirect, "http://localhost:3001/auth/callback?error=no_code&provider=github")
		return
	}

	redirectURL := fmt.Sprintf("http://localhost:3001/auth/callback?provider=github&code=%s&state=%s",
		code, state)
	c.Redirect(http.StatusTemporaryRedirect, redirectURL)
}

// LinkedInLoginHandler initiates LinkedIn OAuth flow
func (h *AuthHandlers) LinkedInLoginHandler(c *gin.Context) {
	// Generate state token for CSRF protection
	state := uuid.New().String()

	// Get LinkedIn auth URL
	authURL := h.linkedinOAuth.GetAuthURL(state)

	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"auth_url": authURL,
		"state":    state,
	})
}

// LinkedInExchangeHandler exchanges LinkedIn OAuth code for token
func (h *AuthHandlers) LinkedInExchangeHandler(c *gin.Context) {
	type ExchangeRequest struct {
		Code string `json:"code"`
	}

	var req ExchangeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request data",
		})
		return
	}

	response, err := h.linkedinOAuth.HandleCallback(c.Request.Context(), req.Code)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
			"error":   appErr.Details,
		})
		return
	}

	c.JSON(http.StatusOK, response)
}

// LinkedInCallbackHandler handles LinkedIn OAuth callback
func (h *AuthHandlers) LinkedInCallbackHandler(c *gin.Context) {
	// Get authorization code and state
	code := c.Query("code")
	state := c.Query("state")

	if code == "" {
		c.Redirect(http.StatusTemporaryRedirect, "http://localhost:3001/auth/callback?error=no_code&provider=linkedin")
		return
	}

	redirectURL := fmt.Sprintf("http://localhost:3001/auth/callback?provider=linkedin&code=%s&state=%s",
		code, state)
	c.Redirect(http.StatusTemporaryRedirect, redirectURL)
}

// SetupRoutes sets up authentication routes with rate limiting
func (h *AuthHandlers) SetupRoutes(r *gin.RouterGroup) {
	// Parse rate limit window duration
	window, err := time.ParseDuration(h.config.RateLimit.Window)
	if err != nil {
		// Default to 1 minute if parsing fails
		window = time.Minute
	}

	auth := r.Group("/auth")
	{
		// Public routes (no authentication required, but rate limited)
		auth.POST("/register",
			RateLimitMiddleware(h.config.RateLimit.Register, window, h.rateLimiter),
			h.RegisterHandler)
		auth.POST("/verify-email", h.VerifyEmailHandler)
		auth.POST("/login",
			RateLimitMiddleware(h.config.RateLimit.Login, window, h.rateLimiter),
			h.LoginHandler)
		auth.POST("/forgot-password", h.ForgotPasswordHandler)
		auth.POST("/reset-password",
			RateLimitMiddleware(h.config.RateLimit.Reset, window, h.rateLimiter),
			h.ResetPasswordHandler)

		// OAuth routes
		auth.GET("/google/login", h.GoogleLoginHandler)
		auth.GET("/google/callback", h.GoogleCallbackHandler)
		auth.POST("/google/exchange", h.GoogleExchangeHandler)
		auth.GET("/github/login", h.GitHubLoginHandler)
		auth.GET("/github/callback", h.GitHubCallbackHandler)
		auth.POST("/github/exchange", h.GitHubExchangeHandler)
		auth.GET("/linkedin/login", h.LinkedInLoginHandler)
		auth.GET("/linkedin/callback", h.LinkedInCallbackHandler)
		auth.POST("/linkedin/exchange", h.LinkedInExchangeHandler)

		// Protected routes (authentication required)
		auth.GET("/me", JWTAuthMiddleware(h.jwtSvc), h.MeHandler)
		auth.POST("/refresh", JWTAuthMiddleware(h.jwtSvc), h.RefreshHandler)
		auth.POST("/logout", JWTAuthMiddleware(h.jwtSvc), h.LogoutHandler)
	}
}
