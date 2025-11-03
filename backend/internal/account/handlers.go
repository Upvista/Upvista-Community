package account

import (
	"net/http"

	"upvista-community-backend/internal/models"
	"upvista-community-backend/pkg/errors"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// AccountHandlers handles HTTP requests for account management
type AccountHandlers struct {
	accountSvc *AccountService
	profileSvc *ProfileService
}

// NewAccountHandlers creates new account handlers
func NewAccountHandlers(accountSvc *AccountService, profileSvc *ProfileService) *AccountHandlers {
	return &AccountHandlers{
		accountSvc: accountSvc,
		profileSvc: profileSvc,
	}
}

// GetProfile handles GET /api/v1/account/profile
func (h *AccountHandlers) GetProfile(c *gin.Context) {
	// Get user ID from JWT (set by auth middleware)
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Unauthorized",
		})
		return
	}

	// Parse user ID
	id, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
		})
		return
	}

	// Get profile
	user, err := h.accountSvc.GetProfile(c.Request.Context(), id)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"user":    user,
	})
}

// UpdateProfile handles PATCH /api/v1/account/profile
func (h *AccountHandlers) UpdateProfile(c *gin.Context) {
	// Get user ID from JWT
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Unauthorized",
		})
		return
	}

	// Parse user ID
	id, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
		})
		return
	}

	// Bind request
	var req models.UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request body",
		})
		return
	}

	// Update profile
	user, err := h.accountSvc.UpdateProfile(c.Request.Context(), id, &req)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Profile updated successfully",
		"user":    user,
	})
}

// ChangePassword handles POST /api/v1/account/change-password
func (h *AccountHandlers) ChangePassword(c *gin.Context) {
	// Get user ID from JWT
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Unauthorized",
		})
		return
	}

	// Parse user ID
	id, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
		})
		return
	}

	// Bind request
	var req models.ChangePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request body",
		})
		return
	}

	// Change password
	if err := h.accountSvc.ChangePassword(c.Request.Context(), id, &req); err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Password changed successfully",
	})
}

// DeleteAccount handles DELETE /api/v1/account/delete
func (h *AccountHandlers) DeleteAccount(c *gin.Context) {
	// Get user ID from JWT
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Unauthorized",
		})
		return
	}

	// Parse user ID
	id, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
		})
		return
	}

	// Bind request
	var req models.DeleteAccountRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request body",
		})
		return
	}

	// Delete account
	if err := h.accountSvc.DeleteAccount(c.Request.Context(), id, &req); err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Account deleted successfully",
	})
}

// ChangeEmailHandler handles POST /api/v1/account/change-email
func (h *AccountHandlers) ChangeEmailHandler(c *gin.Context) {
	// Get user ID from JWT
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Unauthorized",
		})
		return
	}

	// Parse user ID
	id, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
		})
		return
	}

	// Bind request
	var req models.ChangeEmailRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request body",
		})
		return
	}

	// Change email (initiates process)
	if err := h.accountSvc.ChangeEmail(c.Request.Context(), id, &req); err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Verification code sent to new email address",
	})
}

// VerifyEmailChangeHandler handles POST /api/v1/account/verify-email-change
func (h *AccountHandlers) VerifyEmailChangeHandler(c *gin.Context) {
	// Get user ID from JWT
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Unauthorized",
		})
		return
	}

	// Parse user ID
	id, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
		})
		return
	}

	// Bind request
	var req models.VerifyEmailChangeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request body",
		})
		return
	}

	// Verify email change
	if err := h.accountSvc.VerifyEmailChange(c.Request.Context(), id, &req); err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Email changed successfully",
	})
}

// ChangeUsernameHandler handles POST /api/v1/account/change-username
func (h *AccountHandlers) ChangeUsernameHandler(c *gin.Context) {
	// Get user ID from JWT
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Unauthorized",
		})
		return
	}

	// Parse user ID
	id, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
		})
		return
	}

	// Bind request
	var req models.ChangeUsernameRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request body",
		})
		return
	}

	// Change username
	if err := h.accountSvc.ChangeUsername(c.Request.Context(), id, &req); err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Username changed successfully",
	})
}

// DeactivateAccountHandler handles POST /api/v1/account/deactivate
func (h *AccountHandlers) DeactivateAccountHandler(c *gin.Context) {
	// Get user ID from JWT
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Unauthorized",
		})
		return
	}

	// Parse user ID
	id, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
		})
		return
	}

	// Bind request
	var req models.DeactivateAccountRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request body",
		})
		return
	}

	// Deactivate account
	if err := h.accountSvc.DeactivateAccount(c.Request.Context(), id, &req); err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Account deactivated successfully",
	})
}

// GetActiveSessionsHandler handles GET /api/v1/account/sessions
func (h *AccountHandlers) GetActiveSessionsHandler(c *gin.Context) {
	// Get user ID from JWT
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Unauthorized",
		})
		return
	}

	// Parse user ID
	id, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
		})
		return
	}

	// Get active sessions
	sessions, err := h.accountSvc.GetActiveSessions(c.Request.Context(), id)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"sessions": sessions,
	})
}

// DeleteSessionHandler handles DELETE /api/v1/account/sessions/:session_id
func (h *AccountHandlers) DeleteSessionHandler(c *gin.Context) {
	// Get user ID from JWT
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Unauthorized",
		})
		return
	}

	// Parse user ID
	id, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
		})
		return
	}

	// Get session ID from URL parameter
	sessionIDStr := c.Param("session_id")
	sessionID, err := uuid.Parse(sessionIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid session ID",
		})
		return
	}

	// Delete session
	if err := h.accountSvc.DeleteSession(c.Request.Context(), id, sessionID); err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Session deleted successfully. You have been logged out from that device.",
	})
}

// LogoutAllDevicesHandler handles POST /api/v1/account/logout-all
func (h *AccountHandlers) LogoutAllDevicesHandler(c *gin.Context) {
	// Get user ID from JWT
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Unauthorized",
		})
		return
	}

	// Parse user ID
	id, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
		})
		return
	}

	// Optional: Get current session ID to keep current session active
	// For now, we'll log out from ALL devices including current
	if err := h.accountSvc.LogoutAllDevices(c.Request.Context(), id, nil); err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Logged out from all devices successfully",
	})
}

// UploadProfilePictureHandler handles POST /api/v1/account/profile-picture
func (h *AccountHandlers) UploadProfilePictureHandler(c *gin.Context) {
	// Get user ID from JWT
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Unauthorized",
		})
		return
	}

	// Parse user ID
	id, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
		})
		return
	}

	// Parse multipart form
	file, header, err := c.Request.FormFile("profile_picture")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "No file uploaded or invalid form field name. Use 'profile_picture' as the field name.",
		})
		return
	}
	defer file.Close()

	// Upload profile picture
	pictureURL, err := h.accountSvc.UploadProfilePicture(c.Request.Context(), id, file, header)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":         true,
		"message":         "Profile picture uploaded successfully",
		"profile_picture": pictureURL,
	})
}

// ExportDataHandler handles GET /api/v1/account/export-data
func (h *AccountHandlers) ExportDataHandler(c *gin.Context) {
	// Get user ID from JWT
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Unauthorized",
		})
		return
	}

	// Parse user ID
	id, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
		})
		return
	}

	// Export user data
	data, err := h.accountSvc.ExportUserData(c.Request.Context(), id)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
		})
		return
	}

	// Set headers for download
	c.Header("Content-Disposition", "attachment; filename=user-data-export.json")
	c.Header("Content-Type", "application/json")

	c.JSON(http.StatusOK, data)
}

// UpdateBasicProfile handles PATCH /api/v1/account/profile/basic
func (h *AccountHandlers) UpdateBasicProfile(c *gin.Context) {
	// Get user ID from JWT
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Unauthorized",
		})
		return
	}

	// Parse user ID
	id, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
		})
		return
	}

	// Bind request
	var req models.UpdateBasicProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request body",
		})
		return
	}

	// Update basic profile
	err = h.profileSvc.UpdateBasicProfile(c.Request.Context(), id, &req)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Profile updated successfully",
	})
}

// UpdatePrivacySettings handles PATCH /api/v1/account/profile/privacy
func (h *AccountHandlers) UpdatePrivacySettings(c *gin.Context) {
	// Get user ID from JWT
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Unauthorized",
		})
		return
	}

	// Parse user ID
	id, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
		})
		return
	}

	// Bind request
	var req models.UpdatePrivacySettingsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request body",
		})
		return
	}

	// Update privacy settings
	err = h.profileSvc.UpdatePrivacySettings(c.Request.Context(), id, &req)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Privacy settings updated successfully",
	})
}

// UpdateStory handles PATCH /api/v1/account/profile/story
func (h *AccountHandlers) UpdateStory(c *gin.Context) {
	// Get user ID from JWT
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Unauthorized",
		})
		return
	}

	// Parse user ID
	id, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
		})
		return
	}

	// Bind request
	var req models.UpdateStoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request body",
		})
		return
	}

	// Validate story length if provided
	if req.Story != nil && len(*req.Story) > 2000 {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Story must be 2000 characters or less",
		})
		return
	}

	// Update story
	err = h.profileSvc.UpdateStory(c.Request.Context(), id, req.Story)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Story updated successfully",
	})
}

// UpdateAmbition handles PATCH /api/v1/account/profile/ambition
func (h *AccountHandlers) UpdateAmbition(c *gin.Context) {
	// Get user ID from JWT
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Unauthorized",
		})
		return
	}

	// Parse user ID
	id, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
		})
		return
	}

	// Bind request
	var req models.UpdateAmbitionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request body",
		})
		return
	}

	// Validate ambition length if provided
	if req.Ambition != nil && len(*req.Ambition) > 500 {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Ambition must be 500 characters or less",
		})
		return
	}

	// Update ambition
	err = h.profileSvc.UpdateAmbition(c.Request.Context(), id, req.Ambition)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Ambition updated successfully",
	})
}

// UpdateSocialLinks updates user's social media links
func (h *AccountHandlers) UpdateSocialLinks(c *gin.Context) {
	// Get user ID from JWT
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Unauthorized",
		})
		return
	}

	// Parse user ID
	id, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid user ID",
		})
		return
	}

	// Bind request
	var req models.UpdateSocialLinksRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid request body",
		})
		return
	}

	// Update social links
	err = h.profileSvc.UpdateSocialLinks(c.Request.Context(), id, &req)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Social links updated successfully",
	})
}

// GetPublicProfile handles GET /api/v1/profile/:username
func (h *AccountHandlers) GetPublicProfile(c *gin.Context) {
	username := c.Param("username")
	if username == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Username is required",
		})
		return
	}

	// Get viewer ID from JWT (optional - for privacy checks)
	var viewerID *uuid.UUID
	if userIDStr, exists := c.Get("user_id"); exists {
		if id, err := uuid.Parse(userIDStr.(string)); err == nil {
			viewerID = &id
		}
	}

	// Get public profile
	profile, err := h.profileSvc.GetPublicProfile(c.Request.Context(), username, viewerID)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"profile": profile,
	})
}

// SetupRoutes registers account management routes
func (h *AccountHandlers) SetupRoutes(router *gin.RouterGroup) {
	account := router.Group("/account")
	{
		account.GET("/profile", h.GetProfile)
		account.PATCH("/profile", h.UpdateProfile)
		account.POST("/profile-picture", h.UploadProfilePictureHandler)
		account.POST("/change-password", h.ChangePassword)
		account.POST("/change-email", h.ChangeEmailHandler)
		account.POST("/verify-email-change", h.VerifyEmailChangeHandler)
		account.POST("/change-username", h.ChangeUsernameHandler)
		account.POST("/deactivate", h.DeactivateAccountHandler)
		account.DELETE("/delete", h.DeleteAccount)

		// Data export (GDPR)
		account.GET("/export-data", h.ExportDataHandler)

		// Session management
		account.GET("/sessions", h.GetActiveSessionsHandler)
		account.DELETE("/sessions/:session_id", h.DeleteSessionHandler)
		account.POST("/logout-all", h.LogoutAllDevicesHandler)

		// Profile System Phase 1
		account.PATCH("/profile/basic", h.UpdateBasicProfile)
		account.PATCH("/profile/privacy", h.UpdatePrivacySettings)
		account.PATCH("/profile/story", h.UpdateStory)
		account.PATCH("/profile/ambition", h.UpdateAmbition)
		account.PATCH("/profile/social-links", h.UpdateSocialLinks)
	}

	// Public profile endpoint (no auth required, but optional auth for privacy checks)
	router.GET("/profile/:username", h.GetPublicProfile)
}
