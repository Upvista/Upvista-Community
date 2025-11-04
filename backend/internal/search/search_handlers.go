package search

import (
	"net/http"
	"strconv"

	"upvista-community-backend/pkg/errors"

	"github.com/gin-gonic/gin"
)

// SearchHandlers handles HTTP requests for search
type SearchHandlers struct {
	service *SearchService
}

// NewSearchHandlers creates new search handlers
func NewSearchHandlers(service *SearchService) *SearchHandlers {
	return &SearchHandlers{
		service: service,
	}
}

// SearchUsers handles GET /api/v1/search/users
func (h *SearchHandlers) SearchUsers(c *gin.Context) {
	// Get search query
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Search query is required",
		})
		return
	}

	// Get pagination params
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	// Search users
	users, total, err := h.service.SearchUsers(c.Request.Context(), query, page, limit)
	if err != nil {
		appErr := errors.GetAppError(err)
		c.JSON(appErr.Code, gin.H{
			"success": false,
			"message": appErr.Message,
		})
		return
	}

	// Convert to safe user objects (remove sensitive data)
	safeUsers := make([]interface{}, 0, len(users))
	for _, user := range users {
		safeUser := map[string]interface{}{
			"id":              user.ID,
			"username":        user.Username,
			"display_name":    user.DisplayName,
			"profile_picture": user.ProfilePicture,
			"bio":             user.Bio,
			"location":        user.Location,
			"is_verified":     user.IsVerified,
			"followers_count": user.FollowersCount,
			"following_count": user.FollowingCount,
		}
		safeUsers = append(safeUsers, safeUser)
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"users":   safeUsers,
		"total":   total,
		"page":    page,
		"limit":   limit,
	})
}

// SetupRoutes registers search routes
func (h *SearchHandlers) SetupRoutes(router *gin.RouterGroup) {
	search := router.Group("/search")
	{
		search.GET("/users", h.SearchUsers)
	}
}
