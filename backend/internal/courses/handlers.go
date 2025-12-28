package courses

import (
	"fmt"
	"net/http"

	"upvista-community-backend/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// Handlers manages HTTP handlers for courses
type Handlers struct {
	service *Service
}

// NewHandlers creates new course handlers
func NewHandlers(service *Service) *Handlers {
	return &Handlers{
		service: service,
	}
}

// GetCourses handles GET /api/v1/courses
func (h *Handlers) GetCourses(c *gin.Context) {
	var userID *uuid.UUID
	if uid, exists := c.Get("user_id"); exists {
		if parsed, err := uuid.Parse(uid.(string)); err == nil {
			userID = &parsed
		}
	}

	filter := &models.CourseFilter{
		Category:        getStringPtr(c.Query("category")),
		DifficultyLevel: getStringPtr(c.Query("difficulty_level")),
		Language:        getStringPtr(c.Query("language")),
		Search:          getStringPtr(c.Query("search")),
		SortBy:          getStringOrDefault(c.Query("sort_by"), "popular"),
		Limit:           getIntOrDefault(c.Query("limit"), 20),
		Offset:          getIntOrDefault(c.Query("offset"), 0),
	}

	if c.Query("is_free") != "" {
		isFree := c.Query("is_free") == "true"
		filter.IsFree = &isFree
	}

	courses, err := h.service.ListCourses(c.Request.Context(), filter, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"courses": courses,
	})
}

// GetCourse handles GET /api/v1/courses/:id
func (h *Handlers) GetCourse(c *gin.Context) {
	courseID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid course ID",
		})
		return
	}

	var userID *uuid.UUID
	if uid, exists := c.Get("user_id"); exists {
		if parsed, err := uuid.Parse(uid.(string)); err == nil {
			userID = &parsed
		}
	}

	course, err := h.service.GetCourse(c.Request.Context(), courseID, userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "Course not found",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"course":  course,
	})
}

// GetCourseBySlug handles GET /api/v1/courses/slug/:slug
func (h *Handlers) GetCourseBySlug(c *gin.Context) {
	slug := c.Param("slug")
	if slug == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid slug",
		})
		return
	}

	var userID *uuid.UUID
	if uid, exists := c.Get("user_id"); exists {
		if parsed, err := uuid.Parse(uid.(string)); err == nil {
			userID = &parsed
		}
	}

	course, err := h.service.courseRepo.GetCourseBySlug(c.Request.Context(), slug)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "Course not found",
		})
		return
	}

	// Check enrollment and collaborator status
	if userID != nil {
		enrollment, _ := h.service.courseRepo.GetEnrollment(c.Request.Context(), course.ID, *userID)
		if enrollment != nil {
			course.IsEnrolled = true
			course.Enrollment = enrollment
		}

		collab, _ := h.service.courseRepo.GetCollaborator(c.Request.Context(), course.ID, *userID)
		if collab != nil && collab.Status == "accepted" {
			course.IsCollaborator = true
			collabRole := collab.Role
			course.CollaboratorRole = &collabRole
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"course":  course,
	})
}

// CreateCourse handles POST /api/v1/courses
func (h *Handlers) CreateCourse(c *gin.Context) {
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

	var req models.CreateCourseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	course, err := h.service.CreateCourse(c.Request.Context(), &req, uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"course":  course,
	})
}

// EnrollInCourse handles POST /api/v1/courses/:id/enroll
func (h *Handlers) EnrollInCourse(c *gin.Context) {
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

	courseID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "Invalid course ID",
		})
		return
	}

	enrollment, err := h.service.EnrollInCourse(c.Request.Context(), courseID, uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":    true,
		"enrollment": enrollment,
	})
}

// GetMaterials handles GET /api/v1/learning-materials
func (h *Handlers) GetMaterials(c *gin.Context) {
	var userID *uuid.UUID
	if uid, exists := c.Get("user_id"); exists {
		if parsed, err := uuid.Parse(uid.(string)); err == nil {
			userID = &parsed
		}
	}

	filter := &models.CourseFilter{
		Category: getStringPtr(c.Query("category")),
		Search:   getStringPtr(c.Query("search")),
		SortBy:   getStringOrDefault(c.Query("sort_by"), "popular"),
		Limit:    getIntOrDefault(c.Query("limit"), 20),
		Offset:   getIntOrDefault(c.Query("offset"), 0),
	}

	materials, err := h.service.courseRepo.ListMaterials(c.Request.Context(), filter, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":   true,
		"materials": materials,
	})
}

// Helper functions
func getStringPtr(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

func getStringOrDefault(s, def string) string {
	if s == "" {
		return def
	}
	return s
}

func getIntOrDefault(s string, def int) int {
	if s == "" {
		return def
	}
	var result int
	fmt.Sscanf(s, "%d", &result)
	if result == 0 {
		return def
	}
	return result
}
