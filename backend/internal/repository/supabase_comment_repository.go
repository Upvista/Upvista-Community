package repository

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"upvista-community-backend/internal/models"

	"github.com/google/uuid"
)

// SupabaseCommentRepository implements CommentRepository using Supabase
type SupabaseCommentRepository struct {
	*SupabasePostRepository
}

// NewSupabaseCommentRepository creates a new comment repository
func NewSupabaseCommentRepository(supabaseURL, serviceKey string) *SupabaseCommentRepository {
	return &SupabaseCommentRepository{
		SupabasePostRepository: NewSupabasePostRepository(supabaseURL, serviceKey),
	}
}

// CreateComment creates a new comment
func (r *SupabaseCommentRepository) CreateComment(ctx context.Context, comment *models.Comment) error {
	if comment.ID == uuid.Nil {
		comment.ID = uuid.New()
	}

	payload := map[string]interface{}{
		"id":                comment.ID,
		"post_id":           comment.PostID,
		"user_id":           comment.UserID,
		"parent_comment_id": comment.ParentCommentID,
		"content":           comment.Content,
		"media_url":         comment.MediaURL,
		"media_type":        comment.MediaType,
	}

	data, err := r.makeRequest("POST", "post_comments", "", payload)
	if err != nil {
		return fmt.Errorf("failed to create comment: %w", err)
	}

	var created []models.Comment
	if err := json.Unmarshal(data, &created); err != nil {
		return fmt.Errorf("failed to unmarshal comment: %w", err)
	}

	if len(created) > 0 {
		*comment = created[0]
	}

	// Load author
	r.loadCommentAuthor(ctx, comment)

	return nil
}

// GetComment retrieves a single comment
func (r *SupabaseCommentRepository) GetComment(ctx context.Context, commentID uuid.UUID) (*models.Comment, error) {
	query := fmt.Sprintf("?id=eq.%s&deleted_at=is.null&select=*", commentID.String())

	data, err := r.makeRequest("GET", "post_comments", query, nil)
	if err != nil {
		return nil, err
	}

	var comments []models.Comment
	if err := json.Unmarshal(data, &comments); err != nil {
		return nil, err
	}

	if len(comments) == 0 {
		return nil, fmt.Errorf("comment not found")
	}

	comment := &comments[0]
	r.loadCommentAuthor(ctx, comment)

	return comment, nil
}

// GetComments retrieves top-level comments for a post
func (r *SupabaseCommentRepository) GetComments(ctx context.Context, postID uuid.UUID, limit, offset int) ([]models.Comment, int, error) {
	query := fmt.Sprintf(
		"?post_id=eq.%s&parent_comment_id=is.null&deleted_at=is.null&select=*&order=created_at.desc&limit=%d&offset=%d",
		postID.String(), limit, offset,
	)

	data, err := r.makeRequest("GET", "post_comments", query, nil)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get comments: %w", err)
	}

	var comments []models.Comment
	if err := json.Unmarshal(data, &comments); err != nil {
		return nil, 0, fmt.Errorf("failed to unmarshal comments: %w", err)
	}

	// Load authors for all comments
	for i := range comments {
		r.loadCommentAuthor(ctx, &comments[i])

		// Load first few replies (preview)
		replies, _, _ := r.GetCommentReplies(ctx, comments[i].ID, 3, 0)
		if len(replies) > 0 {
			comments[i].Replies = replies
		}
	}

	return comments, len(comments), nil
}

// GetCommentReplies retrieves replies to a comment
func (r *SupabaseCommentRepository) GetCommentReplies(ctx context.Context, parentCommentID uuid.UUID, limit, offset int) ([]models.Comment, int, error) {
	query := fmt.Sprintf(
		"?parent_comment_id=eq.%s&deleted_at=is.null&select=*&order=created_at.asc&limit=%d&offset=%d",
		parentCommentID.String(), limit, offset,
	)

	data, err := r.makeRequest("GET", "post_comments", query, nil)
	if err != nil {
		return nil, 0, err
	}

	var replies []models.Comment
	if err := json.Unmarshal(data, &replies); err != nil {
		return nil, 0, err
	}

	// Load authors
	for i := range replies {
		r.loadCommentAuthor(ctx, &replies[i])
	}

	return replies, len(replies), nil
}

// UpdateComment updates a comment's content
func (r *SupabaseCommentRepository) UpdateComment(ctx context.Context, commentID uuid.UUID, content string) error {
	updates := map[string]interface{}{
		"content":    content,
		"is_edited":  true,
		"edited_at":  time.Now(),
		"updated_at": time.Now(),
	}

	query := fmt.Sprintf("?id=eq.%s", commentID.String())

	_, err := r.makeRequest("PATCH", "post_comments", query, updates)
	return err
}

// DeleteComment soft deletes a comment
func (r *SupabaseCommentRepository) DeleteComment(ctx context.Context, commentID, userID uuid.UUID) error {
	// Verify ownership
	comment, err := r.GetComment(ctx, commentID)
	if err != nil {
		return err
	}

	if comment.UserID != userID {
		return models.ErrUnauthorized
	}

	// Soft delete
	updates := map[string]interface{}{
		"deleted_at": time.Now(),
		"content":    "[deleted]",
	}

	query := fmt.Sprintf("?id=eq.%s", commentID.String())
	_, err = r.makeRequest("PATCH", "post_comments", query, updates)

	return err
}

// LikeComment adds a like to a comment
func (r *SupabaseCommentRepository) LikeComment(ctx context.Context, commentID, userID uuid.UUID) error {
	payload := map[string]interface{}{
		"comment_id": commentID,
		"user_id":    userID,
	}

	_, err := r.makeRequest("POST", "comment_likes", "", payload)
	if err != nil {
		if strings.Contains(err.Error(), "duplicate") {
			return nil // Already liked
		}
		return fmt.Errorf("failed to like comment: %w", err)
	}

	return nil
}

// UnlikeComment removes a like from a comment
func (r *SupabaseCommentRepository) UnlikeComment(ctx context.Context, commentID, userID uuid.UUID) error {
	query := fmt.Sprintf("?comment_id=eq.%s&user_id=eq.%s", commentID.String(), userID.String())

	_, err := r.makeRequest("DELETE", "comment_likes", query, nil)
	return err
}

// IsCommentLikedByUser checks if a user has liked a comment
func (r *SupabaseCommentRepository) IsCommentLikedByUser(ctx context.Context, commentID, userID uuid.UUID) (bool, error) {
	query := fmt.Sprintf("?comment_id=eq.%s&user_id=eq.%s&select=id", commentID.String(), userID.String())

	data, err := r.makeRequest("GET", "comment_likes", query, nil)
	if err != nil {
		return false, nil
	}

	var likes []map[string]interface{}
	if err := json.Unmarshal(data, &likes); err != nil {
		return false, nil
	}

	return len(likes) > 0, nil
}

// GetCommentLikes retrieves users who liked a comment
func (r *SupabaseCommentRepository) GetCommentLikes(ctx context.Context, commentID uuid.UUID, limit, offset int) ([]models.User, int, error) {
	// Would require join or RPC
	return []models.User{}, 0, nil
}

// loadCommentAuthor loads the author for a comment
func (r *SupabaseCommentRepository) loadCommentAuthor(ctx context.Context, comment *models.Comment) error {
	query := fmt.Sprintf("?id=eq.%s&select=id,username,display_name,profile_picture,is_verified", comment.UserID.String())

	data, err := r.makeRequest("GET", "users", query, nil)
	if err != nil {
		return err
	}

	var users []models.User
	if err := json.Unmarshal(data, &users); err != nil {
		return err
	}

	if len(users) > 0 {
		comment.Author = &users[0]
	}

	return nil
}
