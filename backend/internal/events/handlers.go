package events

import (
	"fmt"
	"log"
	"net/http"
	"strconv"

	"upvista-community-backend/internal/models"
	"upvista-community-backend/internal/utils"
	"upvista-community-backend/pkg/errors"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// Handlers manages HTTP handlers for events
type Handlers struct {
	service    *Service
	storageSvc *utils.StorageService
}

// NewHandlers creates new event handlers
func NewHandlers(service *Service, storageSvc *utils.StorageService) *Handlers {
	return &Handlers{
		service:    service,
		storageSvc: storageSvc,
	}
}

// ============================================
// EVENT CRUD ENDPOINTS
// ============================================

// CreateEvent handles POST /api/v1/events
func (h *Handlers) CreateEvent(c *gin.Context) {
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

	var req models.CreateEventRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[Events] JSON binding error: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	log.Printf("[Events] Creating event: title=%s, start_date=%v, end_date=%v", req.Title, req.StartDate, req.EndDate)

	event, err := h.service.CreateEvent(c.Request.Context(), &req, uid)
	if err != nil {
		log.Printf("[Events] CreateEvent error: %v", err)
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"error":   appErr.Message,
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"event":   event,
		"message": "Event created successfully",
	})
}

// GetEvent handles GET /api/v1/events/:id
func (h *Handlers) GetEvent(c *gin.Context) {
	eventID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid event ID"})
		return
	}

	var userID *uuid.UUID
	if uidStr, exists := c.Get("user_id"); exists {
		if uid, err := uuid.Parse(uidStr.(string)); err == nil {
			userID = &uid
		}
	}

	event, err := h.service.GetEvent(c.Request.Context(), eventID, userID)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"error":   appErr.Message,
		})
		return
	}

	// Increment views
	go h.service.IncrementEventViews(c.Request.Context(), eventID)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"event":   event,
	})
}

// ListEvents handles GET /api/v1/events
func (h *Handlers) ListEvents(c *gin.Context) {
	filter := &models.EventFilter{
		Limit:  20,
		Offset: 0,
	}

	// Parse query parameters
	if status := c.Query("status"); status != "" {
		filter.Status = &status
	}
	if category := c.Query("category"); category != "" {
		filter.Category = &category
	}
	if search := c.Query("search"); search != "" {
		filter.Search = &search
	}
	if locationType := c.Query("location_type"); locationType != "" {
		filter.LocationType = &locationType
	}
	if isFreeStr := c.Query("is_free"); isFreeStr != "" {
		isFree := isFreeStr == "true"
		filter.IsFree = &isFree
	}
	if limitStr := c.Query("limit"); limitStr != "" {
		if limit, err := strconv.Atoi(limitStr); err == nil && limit > 0 {
			filter.Limit = limit
		}
	}
	if offsetStr := c.Query("offset"); offsetStr != "" {
		if offset, err := strconv.Atoi(offsetStr); err == nil && offset >= 0 {
			filter.Offset = offset
		}
	}

	var userID *uuid.UUID
	if uidStr, exists := c.Get("user_id"); exists {
		if uid, err := uuid.Parse(uidStr.(string)); err == nil {
			userID = &uid
		}
	}

	events, err := h.service.ListEvents(c.Request.Context(), filter, userID)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"error":   appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"events":  events,
		"count":   len(events),
	})
}

// UpdateEvent handles PUT /api/v1/events/:id
func (h *Handlers) UpdateEvent(c *gin.Context) {
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

	eventID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid event ID"})
		return
	}

	var req models.CreateEventRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	event, err := h.service.UpdateEvent(c.Request.Context(), eventID, uid, &req)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"error":   appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"event":   event,
		"message": "Event updated successfully",
	})
}

// DeleteEvent handles DELETE /api/v1/events/:id
func (h *Handlers) DeleteEvent(c *gin.Context) {
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

	eventID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid event ID"})
		return
	}

	if err := h.service.DeleteEvent(c.Request.Context(), eventID, uid); err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"error":   appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Event deleted successfully",
	})
}

// ============================================
// EVENT APPLICATION ENDPOINTS
// ============================================

// ApplyToEvent handles POST /api/v1/events/:id/apply
func (h *Handlers) ApplyToEvent(c *gin.Context) {
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

	eventID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid event ID"})
		return
	}

	var req models.ApplyToEventRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	application, err := h.service.ApplyToEvent(c.Request.Context(), eventID, uid, &req)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"error":   appErr.Message,
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success":     true,
		"application": application,
		"message":     "Successfully applied to event",
	})
}

// GetApplication handles GET /api/v1/events/:id/application
func (h *Handlers) GetApplication(c *gin.Context) {
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

	eventID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid event ID"})
		return
	}

	application, err := h.service.GetApplication(c.Request.Context(), eventID, uid)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"error":   appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":     true,
		"application": application,
	})
}

// GetTicket handles GET /api/v1/events/:id/ticket
func (h *Handlers) GetTicket(c *gin.Context) {
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

	eventID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid event ID"})
		return
	}

	ticket, err := h.service.GetTicket(c.Request.Context(), eventID, uid)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"error":   appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"ticket":  ticket,
	})
}

// ============================================
// EVENT APPROVAL ENDPOINTS
// ============================================

// ApproveEvent handles POST /api/v1/events/approve
func (h *Handlers) ApproveEvent(c *gin.Context) {
	// This endpoint should be protected with admin middleware
	adminID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	uid, err := uuid.Parse(adminID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	token := c.Query("token")
	if token == "" {
		var req struct {
			Token string `json:"token" binding:"required"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Token is required"})
			return
		}
		token = req.Token
	}

	var approvalReq models.ApproveEventRequest
	if err := c.ShouldBindJSON(&approvalReq); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.service.ApproveEvent(c.Request.Context(), token, uid, &approvalReq); err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"error":   appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Event approval processed successfully",
	})
}

// GetPendingApprovals handles GET /api/v1/events/approvals/pending
func (h *Handlers) GetPendingApprovals(c *gin.Context) {
	// Admin only endpoint
	limit := 20
	offset := 0

	if limitStr := c.Query("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
			limit = l
		}
	}
	if offsetStr := c.Query("offset"); offsetStr != "" {
		if o, err := strconv.Atoi(offsetStr); err == nil && o >= 0 {
			offset = o
		}
	}

	requests, err := h.service.GetPendingApprovals(c.Request.Context(), limit, offset)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"error":   appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"requests": requests,
		"count":    len(requests),
	})
}

// ============================================
// EVENT CATEGORIES
// ============================================

// GetCategories handles GET /api/v1/events/categories
func (h *Handlers) GetCategories(c *gin.Context) {
	categories, err := h.service.GetCategories(c.Request.Context())
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"error":   appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":    true,
		"categories": categories,
	})
}

// UploadEventCoverImage handles POST /api/v1/events/upload-cover-image
func (h *Handlers) UploadEventCoverImage(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"error":   "Unauthorized",
		})
		return
	}

	uid, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid user ID",
		})
		return
	}

	// Parse multipart form
	file, header, err := c.Request.FormFile("cover_image")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "No file uploaded. Use 'cover_image' as the field name.",
		})
		return
	}
	defer file.Close()

	// Upload to Supabase Storage (event-covers bucket)
	fileName := fmt.Sprintf("events/%s/%s_%s", uid.String(), uuid.New().String(), header.Filename)
	uploadedURL, err := h.storageSvc.UploadFile(c.Request.Context(), "event-covers", fileName, file, header.Header.Get("Content-Type"))
	if err != nil {
		log.Printf("[Events] Failed to upload cover image: %v", err)
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"error":   appErr.Message,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"url":     uploadedURL,
		"message": "Cover image uploaded successfully",
	})
}
