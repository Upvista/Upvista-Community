package posts

import (
	"fmt"
	"net/http"
	"strconv"

	"upvista-community-backend/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// Handlers manages HTTP handlers for posts
type Handlers struct {
	service     *Service
	feedService *FeedService
}

// NewHandlers creates new post handlers
func NewHandlers(service *Service, feedService *FeedService) *Handlers {
	return &Handlers{
		service:     service,
		feedService: feedService,
	}
}

// ============================================
// POST CRUD ENDPOINTS
// ============================================

// CreatePost handles POST /api/v1/posts
func (h *Handlers) CreatePost(c *gin.Context) {
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

	var req models.CreatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	post, err := h.service.CreatePost(c.Request.Context(), &req, uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, models.PostResponse{
		Success: true,
		Post:    post,
		Message: "Post created successfully",
	})
}

// GetPost handles GET /api/v1/posts/:id
func (h *Handlers) GetPost(c *gin.Context) {
	postID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	// Get viewer ID (optional)
	var viewerID uuid.UUID
	if userID, exists := c.Get("user_id"); exists {
		viewerID, _ = uuid.Parse(userID.(string))
	}

	post, err := h.service.GetPost(c.Request.Context(), postID, viewerID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})
		return
	}

	c.JSON(http.StatusOK, models.PostResponse{
		Success: true,
		Post:    post,
	})
}

// UpdatePost handles PUT /api/v1/posts/:id
func (h *Handlers) UpdatePost(c *gin.Context) {
	postID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	uid, _ := uuid.Parse(userID.(string))

	var req models.UpdatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.service.UpdatePost(c.Request.Context(), postID, uid, &req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Post updated successfully",
	})
}

// DeletePost handles DELETE /api/v1/posts/:id
func (h *Handlers) DeletePost(c *gin.Context) {
	postID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	uid, _ := uuid.Parse(userID.(string))

	if err := h.service.DeletePost(c.Request.Context(), postID, uid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Post deleted successfully",
	})
}

// GetUserPosts handles GET /api/v1/posts/user/:username
func (h *Handlers) GetUserPosts(c *gin.Context) {
	// TODO: Convert username to user ID
	// For now, return empty

	c.JSON(http.StatusOK, models.PostsResponse{
		Success: true,
		Posts:   []models.Post{},
		Total:   0,
	})
}

// ============================================
// ENGAGEMENT ENDPOINTS
// ============================================

// LikePost handles POST /api/v1/posts/:id/like
func (h *Handlers) LikePost(c *gin.Context) {
	postID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	uid, _ := uuid.Parse(userID.(string))

	if err := h.service.LikePost(c.Request.Context(), postID, uid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Post liked",
	})
}

// UnlikePost handles DELETE /api/v1/posts/:id/like
func (h *Handlers) UnlikePost(c *gin.Context) {
	postID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	uid, _ := uuid.Parse(userID.(string))

	if err := h.service.UnlikePost(c.Request.Context(), postID, uid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Post unliked",
	})
}

// SharePost handles POST /api/v1/posts/:id/share
func (h *Handlers) SharePost(c *gin.Context) {
	postID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	uid, _ := uuid.Parse(userID.(string))

	var req struct {
		Comment string `json:"comment"`
	}
	c.ShouldBindJSON(&req)

	if err := h.service.SharePost(c.Request.Context(), postID, uid, req.Comment); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Post shared",
	})
}

// SavePost handles POST /api/v1/posts/:id/save
func (h *Handlers) SavePost(c *gin.Context) {
	postID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	uid, _ := uuid.Parse(userID.(string))

	var req struct {
		Collection string `json:"collection"`
	}
	c.ShouldBindJSON(&req)

	if req.Collection == "" {
		req.Collection = "Saved"
	}

	if err := h.service.SavePost(c.Request.Context(), postID, uid, req.Collection); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Post saved",
	})
}

// UnsavePost handles DELETE /api/v1/posts/:id/save
func (h *Handlers) UnsavePost(c *gin.Context) {
	postID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	uid, _ := uuid.Parse(userID.(string))

	if err := h.service.UnsavePost(c.Request.Context(), postID, uid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Post unsaved",
	})
}

// ============================================
// COMMENT ENDPOINTS
// ============================================

// CreateComment handles POST /api/v1/posts/:id/comments
func (h *Handlers) CreateComment(c *gin.Context) {
	postID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	uid, _ := uuid.Parse(userID.(string))

	var req models.CreateCommentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	req.PostID = postID

	comment, err := h.service.CreateComment(c.Request.Context(), &req, uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, models.CommentResponse{
		Success: true,
		Comment: comment,
		Message: "Comment created",
	})
}

// GetComments handles GET /api/v1/posts/:id/comments
func (h *Handlers) GetComments(c *gin.Context) {
	postID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	comments, total, err := h.service.GetComments(c.Request.Context(), postID, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, models.CommentsResponse{
		Success:  true,
		Comments: comments,
		Total:    total,
		Page:     offset / limit,
		Limit:    limit,
		HasMore:  total > offset+limit,
	})
}

// UpdateComment handles PUT /api/v1/comments/:id
func (h *Handlers) UpdateComment(c *gin.Context) {
	commentID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid comment ID"})
		return
	}

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	uid, _ := uuid.Parse(userID.(string))

	var req models.UpdateCommentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	comment, err := h.service.UpdateComment(c.Request.Context(), commentID, req.Content, uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, models.CommentResponse{
		Success: true,
		Comment: comment,
		Message: "Comment updated",
	})
}

// DeleteComment handles DELETE /api/v1/comments/:id
func (h *Handlers) DeleteComment(c *gin.Context) {
	commentID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid comment ID"})
		return
	}

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	uid, _ := uuid.Parse(userID.(string))

	if err := h.service.DeleteComment(c.Request.Context(), commentID, uid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Comment deleted",
	})
}

// LikeComment handles POST /api/v1/comments/:id/like
func (h *Handlers) LikeComment(c *gin.Context) {
	commentID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid comment ID"})
		return
	}

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	uid, _ := uuid.Parse(userID.(string))

	if err := h.service.LikeComment(c.Request.Context(), commentID, uid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Comment liked",
	})
}

// ============================================
// POLL ENDPOINTS
// ============================================

// VotePoll handles POST /api/v1/posts/:id/vote
func (h *Handlers) VotePoll(c *gin.Context) {
	postID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	uid, _ := uuid.Parse(userID.(string))

	var req models.VotePollRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// First verify the post exists and is a poll
	post, err := h.service.postRepo.GetPost(c.Request.Context(), postID, uid)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})
		return
	}
	
	if post.PostType != "poll" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Post is not a poll"})
		return
	}

	// Get poll by post ID
	poll, err := h.service.pollRepo.GetPollByPostID(c.Request.Context(), postID)
	if err != nil {
		fmt.Printf("[VotePoll] Failed to get poll for post %s: %v\n", postID.String(), err)
		c.JSON(http.StatusNotFound, gin.H{"error": fmt.Sprintf("Poll not found: %v", err)})
		return
	}

	if err := h.service.VotePoll(c.Request.Context(), poll.ID, req.OptionID, uid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Get updated results
	results, _ := h.service.GetPollResults(c.Request.Context(), poll.ID, uid)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Vote recorded",
		"results": results,
	})
}

// GetPollResults handles GET /api/v1/posts/:id/results
func (h *Handlers) GetPollResults(c *gin.Context) {
	postID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	// Get viewer ID (optional)
	var viewerID uuid.UUID
	if userID, exists := c.Get("user_id"); exists {
		viewerID, _ = uuid.Parse(userID.(string))
	}

	// Get poll by post ID
	poll, err := h.service.pollRepo.GetPollByPostID(c.Request.Context(), postID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Poll not found"})
		return
	}

	results, err := h.service.GetPollResults(c.Request.Context(), poll.ID, viewerID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"results": results,
	})
}

// ============================================
// FEED ENDPOINTS
// ============================================

// GetHomeFeed handles GET /api/v1/feed/home
func (h *Handlers) GetHomeFeed(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	uid, _ := uuid.Parse(userID.(string))

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	posts, total, err := h.feedService.GetHomeFeed(c.Request.Context(), uid, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, models.PostsResponse{
		Success: true,
		Posts:   posts,
		Total:   total,
		Page:    offset / limit,
		Limit:   limit,
		HasMore: total > offset+limit,
	})
}

// GetFollowingFeed handles GET /api/v1/feed/following
func (h *Handlers) GetFollowingFeed(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	uid, _ := uuid.Parse(userID.(string))

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	posts, total, err := h.feedService.GetFollowingFeed(c.Request.Context(), uid, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, models.PostsResponse{
		Success: true,
		Posts:   posts,
		Total:   total,
		Page:    offset / limit,
		Limit:   limit,
		HasMore: total > offset+limit,
	})
}

// GetExploreFeed handles GET /api/v1/feed/explore
func (h *Handlers) GetExploreFeed(c *gin.Context) {
	// Get viewer ID (optional for explore)
	var viewerID uuid.UUID
	if userID, exists := c.Get("user_id"); exists {
		viewerID, _ = uuid.Parse(userID.(string))
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	posts, total, err := h.feedService.GetExploreFeed(c.Request.Context(), viewerID, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, models.PostsResponse{
		Success: true,
		Posts:   posts,
		Total:   total,
		Page:    offset / limit,
		Limit:   limit,
		HasMore: total > offset+limit,
	})
}

// GetSavedFeed handles GET /api/v1/feed/saved
func (h *Handlers) GetSavedFeed(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	uid, _ := uuid.Parse(userID.(string))

	collection := c.DefaultQuery("collection", "Saved")
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	posts, total, err := h.feedService.GetSavedFeed(c.Request.Context(), uid, collection, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, models.PostsResponse{
		Success: true,
		Posts:   posts,
		Total:   total,
		Page:    offset / limit,
		Limit:   limit,
		HasMore: total > offset+limit,
	})
}

// GetHashtagFeed handles GET /api/v1/hashtags/:tag/posts
func (h *Handlers) GetHashtagFeed(c *gin.Context) {
	hashtag := c.Param("tag")

	// Get viewer ID (optional)
	var viewerID uuid.UUID
	if userID, exists := c.Get("user_id"); exists {
		viewerID, _ = uuid.Parse(userID.(string))
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	posts, total, err := h.feedService.GetHashtagFeed(c.Request.Context(), hashtag, viewerID, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, models.PostsResponse{
		Success: true,
		Posts:   posts,
		Total:   total,
		Page:    offset / limit,
		Limit:   limit,
		HasMore: total > offset+limit,
	})
}

// GetTrendingHashtags handles GET /api/v1/hashtags/trending
func (h *Handlers) GetTrendingHashtags(c *gin.Context) {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	hashtags, err := h.service.postRepo.GetTrendingHashtags(c.Request.Context(), limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"hashtags": hashtags,
	})
}

// FollowHashtag handles POST /api/v1/hashtags/:tag/follow
func (h *Handlers) FollowHashtag(c *gin.Context) {
	tag := c.Param("tag")

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	uid, _ := uuid.Parse(userID.(string))

	// Get hashtag by tag
	hashtag, err := h.service.postRepo.GetHashtagByTag(c.Request.Context(), tag)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Hashtag not found"})
		return
	}

	if err := h.service.postRepo.FollowHashtag(c.Request.Context(), hashtag.ID, uid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Hashtag followed",
	})
}

// UnfollowHashtag handles DELETE /api/v1/hashtags/:tag/follow
func (h *Handlers) UnfollowHashtag(c *gin.Context) {
	tag := c.Param("tag")

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	uid, _ := uuid.Parse(userID.(string))

	// Get hashtag by tag
	hashtag, err := h.service.postRepo.GetHashtagByTag(c.Request.Context(), tag)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Hashtag not found"})
		return
	}

	if err := h.service.postRepo.UnfollowHashtag(c.Request.Context(), hashtag.ID, uid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Hashtag unfollowed",
	})
}
