package auth

import (
	"net/http"

	"upvista-community-backend/internal/models"
	"upvista-community-backend/internal/utils"
	"upvista-community-backend/pkg/errors"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// AuthHandlers handles HTTP requests for authentication
type AuthHandlers struct {
	authSvc *AuthService
	jwtSvc  *utils.JWTService
}

// NewAuthHandlers creates new authentication handlers
func NewAuthHandlers(authSvc *AuthService, jwtSvc *utils.JWTService) *AuthHandlers {
	return &AuthHandlers{
		authSvc: authSvc,
		jwtSvc:  jwtSvc,
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

	response, err := h.authSvc.LogoutUser(c.Request.Context(), userID)
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

// SetupRoutes sets up authentication routes
func (h *AuthHandlers) SetupRoutes(r *gin.RouterGroup) {
	auth := r.Group("/auth")
	{
		// Public routes (no authentication required)
		auth.POST("/register", h.RegisterHandler)
		auth.POST("/verify-email", h.VerifyEmailHandler)
		auth.POST("/login", h.LoginHandler)
		auth.POST("/forgot-password", h.ForgotPasswordHandler)
		auth.POST("/reset-password", h.ResetPasswordHandler)

		// Protected routes (authentication required)
		auth.GET("/me", JWTAuthMiddleware(h.jwtSvc), h.MeHandler)
		auth.POST("/refresh", JWTAuthMiddleware(h.jwtSvc), h.RefreshHandler)
		auth.POST("/logout", JWTAuthMiddleware(h.jwtSvc), h.LogoutHandler)
	}
}
