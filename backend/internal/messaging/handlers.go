package messaging

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv"
	"time"

	"upvista-community-backend/internal/models"
	"upvista-community-backend/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// MessageHandlers handles HTTP requests for messaging
type MessageHandlers struct {
	service        *MessagingService
	storageService *utils.StorageService
	mediaOptimizer *MediaOptimizer
}

// NewMessageHandlers creates new message handlers
func NewMessageHandlers(
	service *MessagingService,
	storageService *utils.StorageService,
	mediaOptimizer *MediaOptimizer,
) *MessageHandlers {
	return &MessageHandlers{
		service:        service,
		storageService: storageService,
		mediaOptimizer: mediaOptimizer,
	}
}

// ============================================
// CONVERSATIONS
// ============================================

// GetConversations handles GET /api/v1/conversations
func (h *MessageHandlers) GetConversations(c *gin.Context) {
	// Get current user ID from JWT
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	uid, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Parse pagination
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	if limit > 100 {
		limit = 100
	}

	// Get conversations
	conversations, err := h.service.GetConversations(c.Request.Context(), uid, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":       true,
		"conversations": conversations,
		"total":         len(conversations),
		"limit":         limit,
		"offset":        offset,
		"has_more":      len(conversations) == limit,
	})
}

// GetConversation handles GET /api/v1/conversations/:id
func (h *MessageHandlers) GetConversation(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	conversationID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid conversation ID"})
		return
	}

	conversation, err := h.service.GetConversation(c.Request.Context(), conversationID, uid)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":      true,
		"conversation": conversation,
	})
}

// StartConversation handles POST /api/v1/conversations/:userId
func (h *MessageHandlers) StartConversation(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	otherUserID, err := uuid.Parse(c.Param("userId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	if uid == otherUserID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot start conversation with yourself"})
		return
	}

	conversation, err := h.service.StartConversation(c.Request.Context(), uid, otherUserID)
	if err != nil {
		log.Printf("[MessageHandlers] Failed to start conversation: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":      true,
		"conversation": conversation,
	})
}

// GetUnreadCount handles GET /api/v1/conversations/unread-count
func (h *MessageHandlers) GetUnreadCount(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	count, err := h.service.GetUnreadCount(c.Request.Context(), uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"total":   count,
	})
}

// ============================================
// MESSAGES
// ============================================

// GetMessages handles GET /api/v1/conversations/:id/messages
func (h *MessageHandlers) GetMessages(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	conversationID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid conversation ID"})
		return
	}

	// Parse pagination
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	if limit > 100 {
		limit = 100
	}

	messages, err := h.service.GetMessages(c.Request.Context(), conversationID, uid, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"messages": messages,
		"total":    len(messages),
		"limit":    limit,
		"offset":   offset,
		"has_more": len(messages) == limit,
	})
}

// SendMessage handles POST /api/v1/conversations/:id/messages
func (h *MessageHandlers) SendMessage(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	conversationID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid conversation ID"})
		return
	}

	var req models.MessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Set default message type if not provided
	if req.MessageType == "" {
		req.MessageType = models.MessageTypeText
	}

	message, err := h.service.SendMessage(c.Request.Context(), conversationID, uid, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": message,
		"temp_id": req.TempID, // Return temp_id for optimistic UI mapping
	})
}

// MarkAsRead handles PATCH /api/v1/conversations/:id/read
func (h *MessageHandlers) MarkAsRead(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	conversationID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid conversation ID"})
		return
	}

	if err := h.service.MarkAsRead(c.Request.Context(), conversationID, uid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Messages marked as read",
	})
}

// DeleteMessage handles DELETE /api/v1/messages/:id
func (h *MessageHandlers) DeleteMessage(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	messageID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid message ID"})
		return
	}

	if err := h.service.DeleteMessage(c.Request.Context(), messageID, uid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Message deleted",
	})
}

// SearchMessages handles GET /api/v1/messages/search
func (h *MessageHandlers) SearchMessages(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Search query is required"})
		return
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	messages, err := h.service.SearchMessages(c.Request.Context(), uid, query, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"messages": messages,
		"query":    query,
	})
}

// ============================================
// ATTACHMENTS
// ============================================

// UploadImage handles POST /api/v1/messages/upload-image
func (h *MessageHandlers) UploadImage(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	// Get quality parameter
	quality := c.DefaultQuery("quality", "standard")
	var optimizeQuality OptimizeImageQuality
	if quality == "hd" {
		optimizeQuality = QualityHD
	} else {
		optimizeQuality = QualityStandard
	}

	// Get file from form
	file, header, err := c.Request.FormFile("image")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No image file provided"})
		return
	}
	defer file.Close()

	// Validate file size
	if err := ValidateFileSize(header.Size, "image_"+quality); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Read file
	fileData, err := io.ReadAll(file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read file"})
		return
	}

	// Validate image
	isValid, _, err := h.mediaOptimizer.ValidateImage(fileData)
	if !isValid || err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid image format"})
		return
	}

	// Optimize image
	optimizedData, newFormat, err := h.mediaOptimizer.OptimizeImageFromBytes(fileData, optimizeQuality)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to optimize image"})
		return
	}

	// Upload to Supabase Storage
	fileName := fmt.Sprintf("messages/%s/%s_%d.%s", uid.String(), uuid.New().String(), time.Now().Unix(), newFormat)
	uploadedURL, err := h.storageService.UploadFile(c.Request.Context(), "chat-attachments", fileName, bytes.NewReader(optimizedData), "image/"+newFormat)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload image"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"url":     uploadedURL,
		"name":    header.Filename,
		"size":    len(optimizedData),
		"type":    "image/" + newFormat,
		"format":  newFormat,
	})
}

// UploadAudio handles POST /api/v1/messages/upload-audio
func (h *MessageHandlers) UploadAudio(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	// Get file from form
	file, header, err := c.Request.FormFile("audio")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No audio file provided"})
		return
	}
	defer file.Close()

	// Validate file size
	if err := ValidateFileSize(header.Size, "audio"); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Read file
	fileData, err := io.ReadAll(file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read file"})
		return
	}

	// Validate audio
	isValid, err := h.mediaOptimizer.ValidateAudio(fileData, header.Header.Get("Content-Type"))
	if !isValid {
		log.Printf("[MessageHandlers] Audio validation failed: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid audio format: " + err.Error()})
		return
	}

	// For Phase 1, we accept WebM directly without conversion
	// Audio conversion to MP3 can be added in Phase 2 with ffmpeg

	// Upload to Supabase Storage
	fileName := fmt.Sprintf("messages/%s/audio_%s_%d.webm", uid.String(), uuid.New().String(), time.Now().Unix())
	uploadedURL, err := h.storageService.UploadFile(c.Request.Context(), "chat-attachments", fileName, bytes.NewReader(fileData), "audio/webm")
	if err != nil {
		log.Printf("[MessageHandlers] Failed to upload audio to Supabase: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload audio"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"url":     uploadedURL,
		"name":    header.Filename,
		"size":    len(fileData),
		"type":    "audio/webm", // Client can still play it as WebM
	})
}

// UploadFile handles POST /api/v1/messages/upload-file
func (h *MessageHandlers) UploadFile(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	// Get file from form
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No file provided"})
		return
	}
	defer file.Close()

	// Validate file size
	if err := ValidateFileSize(header.Size, "file"); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Read file
	fileData, err := io.ReadAll(file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read file"})
		return
	}

	// Upload to Supabase Storage
	fileName := fmt.Sprintf("messages/%s/file_%s_%s", uid.String(), uuid.New().String(), header.Filename)
	uploadedURL, err := h.storageService.UploadFile(c.Request.Context(), "chat-attachments", fileName, bytes.NewReader(fileData), header.Header.Get("Content-Type"))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload file"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"url":     uploadedURL,
		"name":    header.Filename,
		"size":    header.Size,
		"type":    header.Header.Get("Content-Type"),
	})
}

// ============================================
// REACTIONS
// ============================================

// AddReaction handles POST /api/v1/messages/:id/reactions
func (h *MessageHandlers) AddReaction(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	messageID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid message ID"})
		return
	}

	var req models.ReactionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	reaction, err := h.service.AddReaction(c.Request.Context(), messageID, uid, req.Emoji)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// If reaction is nil, it was toggled off (removed)
	if reaction == nil {
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"removed": true,
			"message": "Reaction removed",
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success":  true,
		"reaction": reaction,
	})
}

// RemoveReaction handles DELETE /api/v1/messages/:id/reactions
func (h *MessageHandlers) RemoveReaction(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	messageID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid message ID"})
		return
	}

	if err := h.service.RemoveReaction(c.Request.Context(), messageID, uid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Reaction removed",
	})
}

// ============================================
// STARRED MESSAGES
// ============================================

// StarMessage handles POST /api/v1/messages/:id/star
func (h *MessageHandlers) StarMessage(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	messageID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid message ID"})
		return
	}

	if err := h.service.StarMessage(c.Request.Context(), messageID, uid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Message starred",
	})
}

// UnstarMessage handles DELETE /api/v1/messages/:id/star
func (h *MessageHandlers) UnstarMessage(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	messageID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid message ID"})
		return
	}

	if err := h.service.UnstarMessage(c.Request.Context(), messageID, uid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Message unstarred",
	})
}

// GetStarredMessages handles GET /api/v1/messages/starred
func (h *MessageHandlers) GetStarredMessages(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	messages, err := h.service.GetStarredMessages(c.Request.Context(), uid, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"messages": messages,
	})
}

// ============================================
// TYPING INDICATORS
// ============================================

// StartTyping handles POST /api/v1/conversations/:id/typing/start
func (h *MessageHandlers) StartTyping(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	conversationID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid conversation ID"})
		return
	}

	if err := h.service.StartTyping(c.Request.Context(), conversationID, uid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true})
}

// StopTyping handles POST /api/v1/conversations/:id/typing/stop
func (h *MessageHandlers) StopTyping(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	conversationID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid conversation ID"})
		return
	}

	if err := h.service.StopTyping(c.Request.Context(), conversationID, uid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true})
}

// ============================================
// PRESENCE
// ============================================

// GetUserPresence handles GET /api/v1/users/:id/presence
func (h *MessageHandlers) GetUserPresence(c *gin.Context) {
	targetUserID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	isOnline, lastSeen, err := h.service.GetUserPresence(c.Request.Context(), targetUserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":   true,
		"user_id":   targetUserID,
		"is_online": isOnline,
		"last_seen": lastSeen,
	})
}

// GetBulkPresence handles GET /api/v1/users/presence/bulk
func (h *MessageHandlers) GetBulkPresence(c *gin.Context) {
	// Get user IDs from query parameter (comma-separated)
	userIDsStr := c.Query("user_ids")
	if userIDsStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_ids parameter required"})
		return
	}

	// Parse user IDs
	userIDStrings := splitByComma(userIDsStr)
	userIDs := make([]uuid.UUID, 0, len(userIDStrings))

	for _, idStr := range userIDStrings {
		id, err := uuid.Parse(idStr)
		if err != nil {
			continue
		}
		userIDs = append(userIDs, id)
	}

	if len(userIDs) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No valid user IDs provided"})
		return
	}

	presence, err := h.service.GetMultiplePresence(c.Request.Context(), userIDs)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"presence": presence,
	})
}

// ============================================
// HELPERS
// ============================================

func splitByComma(s string) []string {
	result := []string{}
	current := ""

	for _, char := range s {
		if char == ',' {
			if current != "" {
				result = append(result, current)
				current = ""
			}
		} else {
			current += string(char)
		}
	}

	if current != "" {
		result = append(result, current)
	}

	return result
}
