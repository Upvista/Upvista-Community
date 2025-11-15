package posts

import (
	"context"
	"fmt"
	"time"

	"upvista-community-backend/internal/models"
	"upvista-community-backend/internal/repository"
	"upvista-community-backend/internal/websocket"

	"github.com/google/uuid"
)

// Service handles post business logic
type Service struct {
	postRepo    repository.PostRepository
	pollRepo    repository.PollRepository
	articleRepo repository.ArticleRepository
	commentRepo repository.CommentRepository
	wsManager   *websocket.Manager
}

// NewService creates a new post service
func NewService(
	postRepo repository.PostRepository,
	pollRepo repository.PollRepository,
	articleRepo repository.ArticleRepository,
	commentRepo repository.CommentRepository,
	wsManager *websocket.Manager,
) *Service {
	return &Service{
		postRepo:    postRepo,
		pollRepo:    pollRepo,
		articleRepo: articleRepo,
		commentRepo: commentRepo,
		wsManager:   wsManager,
	}
}

// ============================================
// POST OPERATIONS
// ============================================

// CreatePost creates a new post (any type)
func (s *Service) CreatePost(ctx context.Context, req *models.CreatePostRequest, userID uuid.UUID) (*models.Post, error) {
	// Validate request
	if err := req.Validate(); err != nil {
		return nil, err
	}

	// Create base post
	post := &models.Post{
		UserID:         userID,
		PostType:       req.PostType,
		Content:        req.Content,
		MediaURLs:      req.MediaURLs,
		MediaTypes:     req.MediaTypes,
		Visibility:     req.Visibility,
		AllowsComments: req.AllowsComments,
		AllowsSharing:  req.AllowsSharing,
		IsDraft:        req.IsDraft,
		IsPublished:    !req.IsDraft,
		IsNSFW:         req.IsNSFW,
	}

	// Set defaults
	if post.Visibility == "" {
		post.Visibility = "public"
	}

	if post.IsPublished {
		now := time.Now()
		post.PublishedAt = &now
	}

	// Create post in database
	if err := s.postRepo.CreatePost(ctx, post); err != nil {
		return nil, fmt.Errorf("failed to create post: %w", err)
	}

	// Extract and create hashtags
	if err := s.postRepo.ExtractAndCreateHashtags(ctx, post.ID, post.Content); err != nil {
		fmt.Printf("Warning: failed to extract hashtags: %v\n", err)
	}

	// Extract and create mentions
	if err := s.postRepo.ExtractAndCreateMentions(ctx, post.ID, post.Content); err != nil {
		fmt.Printf("Warning: failed to extract mentions: %v\n", err)
	}

	// Broadcast new post to all users (for real-time feed updates)
	if post.IsPublished && s.wsManager != nil {
		s.broadcastNewPost(post)
	}

	// Handle type-specific creation
	switch post.PostType {
	case "poll":
		if req.Poll != nil {
			poll := &models.Poll{
				PostID:                post.ID,
				Question:              req.Poll.Question,
				DurationHours:         req.Poll.DurationHours,
				AllowMultipleVotes:    req.Poll.AllowMultipleVotes,
				ShowResultsBeforeVote: req.Poll.ShowResultsBeforeVote,
				AllowVoteChanges:      req.Poll.AllowVoteChanges,
				AnonymousVotes:        req.Poll.AnonymousVotes,
			}

			if err := s.pollRepo.CreatePoll(ctx, poll, req.Poll.Options); err != nil {
				return nil, fmt.Errorf("failed to create poll: %w", err)
			}

			post.Poll = poll
		}

	case "article":
		if req.Article != nil {
			article := &models.Article{
				PostID:          post.ID,
				Title:           req.Article.Title,
				Subtitle:        req.Article.Subtitle,
				ContentHTML:     req.Article.ContentHTML,
				CoverImageURL:   req.Article.CoverImageURL,
				MetaTitle:       req.Article.MetaTitle,
				MetaDescription: req.Article.MetaDescription,
				Category:        req.Article.Category,
				Tags:            req.Article.Tags,
			}

			if err := s.articleRepo.CreateArticle(ctx, article); err != nil {
				return nil, fmt.Errorf("failed to create article: %w", err)
			}

			post.Article = article
		}
	}

	// Broadcast to followers (if published)
	if post.IsPublished {
		s.broadcastNewPost(post)
	}

	return post, nil
}

// GetPost retrieves a post with all data
func (s *Service) GetPost(ctx context.Context, postID, viewerID uuid.UUID) (*models.Post, error) {
	post, err := s.postRepo.GetPost(ctx, postID, viewerID)
	if err != nil {
		return nil, err
	}

	// Increment views
	go s.postRepo.IncrementViews(context.Background(), postID)

	return post, nil
}

// GetArticleBySlug retrieves an article by its slug and returns the full post
func (s *Service) GetArticleBySlug(ctx context.Context, slug string, viewerID uuid.UUID) (*models.Post, error) {
	// Get article by slug
	article, err := s.articleRepo.GetArticleBySlug(ctx, slug)
	if err != nil {
		return nil, fmt.Errorf("article not found: %w", err)
	}

	// Get the post associated with this article
	post, err := s.postRepo.GetPost(ctx, article.PostID, viewerID)
	if err != nil {
		return nil, fmt.Errorf("failed to get post: %w", err)
	}

	// Ensure article is attached (it should be from GetPost, but double-check)
	if post.Article == nil {
		post.Article = article
	}

	// Increment article views
	go s.articleRepo.IncrementViews(context.Background(), article.ID)

	return post, nil
}

// UpdatePost updates a post
func (s *Service) UpdatePost(ctx context.Context, postID, userID uuid.UUID, updates *models.UpdatePostRequest) error {
	// Verify ownership
	post, err := s.postRepo.GetPostByID(ctx, postID)
	if err != nil {
		return err
	}

	if post.UserID != userID {
		return models.ErrUnauthorized
	}

	// Build updates map
	updatesMap := make(map[string]interface{})

	if updates.Content != nil {
		updatesMap["content"] = *updates.Content
	}
	if updates.Visibility != nil {
		updatesMap["visibility"] = *updates.Visibility
	}
	if updates.AllowsComments != nil {
		updatesMap["allows_comments"] = *updates.AllowsComments
	}
	if updates.AllowsSharing != nil {
		updatesMap["allows_sharing"] = *updates.AllowsSharing
	}
	if updates.IsNSFW != nil {
		updatesMap["is_nsfw"] = *updates.IsNSFW
	}
	if updates.IsPinned != nil {
		updatesMap["is_pinned"] = *updates.IsPinned
	}

	if len(updatesMap) == 0 {
		return nil
	}

	return s.postRepo.UpdatePost(ctx, postID, updatesMap)
}

// DeletePost deletes a post
func (s *Service) DeletePost(ctx context.Context, postID, userID uuid.UUID) error {
	if err := s.postRepo.DeletePost(ctx, postID, userID); err != nil {
		return err
	}

	// Broadcast deletion
	s.broadcastPostDeleted(postID)

	return nil
}

// ============================================
// ENGAGEMENT
// ============================================

// LikePost likes a post
func (s *Service) LikePost(ctx context.Context, postID, userID uuid.UUID) error {
	if err := s.postRepo.LikePost(ctx, postID, userID); err != nil {
		return err
	}

	// Get updated post
	post, _ := s.postRepo.GetPostByID(ctx, postID)
	if post != nil {
		// Broadcast like event
		s.broadcastPostLiked(postID, post.LikesCount, userID, post.UserID)
	}

	return nil
}

// UnlikePost unlikes a post
func (s *Service) UnlikePost(ctx context.Context, postID, userID uuid.UUID) error {
	return s.postRepo.UnlikePost(ctx, postID, userID)
}

// SharePost shares a post
func (s *Service) SharePost(ctx context.Context, postID, userID uuid.UUID, comment string) error {
	if err := s.postRepo.SharePost(ctx, postID, userID, comment); err != nil {
		return err
	}

	// Get post to notify author
	post, _ := s.postRepo.GetPostByID(ctx, postID)
	if post != nil {
		s.broadcastPostShared(postID, userID, post.UserID)
	}

	return nil
}

// SavePost saves a post to collection
func (s *Service) SavePost(ctx context.Context, postID, userID uuid.UUID, collection string) error {
	return s.postRepo.SavePost(ctx, postID, userID, collection)
}

// UnsavePost removes a post from saved
func (s *Service) UnsavePost(ctx context.Context, postID, userID uuid.UUID) error {
	return s.postRepo.UnsavePost(ctx, postID, userID)
}

// ============================================
// POLLS
// ============================================

// VotePoll votes on a poll
func (s *Service) VotePoll(ctx context.Context, pollID, optionID, userID uuid.UUID) error {
	if err := s.pollRepo.VotePoll(ctx, pollID, optionID, userID); err != nil {
		return err
	}

	// Get updated results
	results, _ := s.pollRepo.GetPollResults(ctx, pollID, uuid.Nil)
	if results != nil {
		s.broadcastPollVote(pollID, results)
	}

	return nil
}

// GetPollResults retrieves poll results
func (s *Service) GetPollResults(ctx context.Context, pollID, viewerID uuid.UUID) (*models.PollResults, error) {
	return s.pollRepo.GetPollResults(ctx, pollID, viewerID)
}

// ============================================
// COMMENTS
// ============================================

// CreateComment creates a new comment
func (s *Service) CreateComment(ctx context.Context, req *models.CreateCommentRequest, userID uuid.UUID) (*models.Comment, error) {
	if err := req.Validate(); err != nil {
		return nil, err
	}

	comment := &models.Comment{
		PostID:          req.PostID,
		UserID:          userID,
		ParentCommentID: req.ParentCommentID,
		Content:         req.Content,
		MediaURL:        req.MediaURL,
		MediaType:       req.MediaType,
	}

	if err := s.commentRepo.CreateComment(ctx, comment); err != nil {
		return nil, err
	}

	// Get post to notify author
	post, _ := s.postRepo.GetPostByID(ctx, req.PostID)
	if post != nil {
		s.broadcastNewComment(comment, post.UserID)
	}

	return comment, nil
}

// GetComments retrieves comments for a post
func (s *Service) GetComments(ctx context.Context, postID uuid.UUID, limit, offset int) ([]models.Comment, int, error) {
	return s.commentRepo.GetComments(ctx, postID, limit, offset)
}

// UpdateComment updates a comment
func (s *Service) UpdateComment(ctx context.Context, commentID uuid.UUID, content string, userID uuid.UUID) (*models.Comment, error) {
	// Verify ownership
	comment, err := s.commentRepo.GetComment(ctx, commentID)
	if err != nil {
		return nil, fmt.Errorf("comment not found: %w", err)
	}

	if comment.UserID != userID {
		return nil, fmt.Errorf("unauthorized: you can only edit your own comments")
	}

	// Update comment
	if err := s.commentRepo.UpdateComment(ctx, commentID, content); err != nil {
		return nil, fmt.Errorf("failed to update comment: %w", err)
	}

	// Get updated comment
	updatedComment, err := s.commentRepo.GetComment(ctx, commentID)
	if err != nil {
		return nil, fmt.Errorf("failed to get updated comment: %w", err)
	}

	// Broadcast comment update
	if s.wsManager != nil {
		post, _ := s.postRepo.GetPostByID(ctx, updatedComment.PostID)
		if post != nil {
			event := map[string]interface{}{
				"type":    "comment_updated",
				"comment": updatedComment,
				"post_id": post.ID,
			}
			// Broadcast to post author and anyone viewing the post
			s.wsManager.BroadcastToUserWithData(post.UserID, event)
		}
	}

	return updatedComment, nil
}

// DeleteComment deletes a comment
func (s *Service) DeleteComment(ctx context.Context, commentID, userID uuid.UUID) error {
	return s.commentRepo.DeleteComment(ctx, commentID, userID)
}

// LikeComment likes a comment
func (s *Service) LikeComment(ctx context.Context, commentID, userID uuid.UUID) error {
	return s.commentRepo.LikeComment(ctx, commentID, userID)
}

// ============================================
// WEBSOCKET BROADCASTS
// ============================================

func (s *Service) broadcastNewPost(post *models.Post) {
	if s.wsManager != nil {
		// Broadcast new post to all connected users for real-time feed updates
		// In production, you might want to broadcast only to followers
		event := map[string]interface{}{
			"type": "new_post",
			"post": post,
		}
		// Broadcast to post author (they'll see it in their feed)
		// TODO: Implement broadcast to all followers or all users
		// For now, the post will appear in feeds when users refresh
		s.wsManager.BroadcastToUserWithData(post.UserID, event)
		fmt.Printf("[Posts] New post created: %s\n", post.ID)
	}
}

func (s *Service) broadcastPostLiked(postID uuid.UUID, likesCount int, likerID, authorID uuid.UUID) {
	if s.wsManager != nil {
		event := map[string]interface{}{
			"type":        "post_liked",
			"post_id":     postID,
			"likes_count": likesCount,
			"liker_id":    likerID,
		}
		// Notify post author
		s.wsManager.BroadcastToUserWithData(authorID, event)
	}
}

func (s *Service) broadcastNewComment(comment *models.Comment, postAuthorID uuid.UUID) {
	if s.wsManager != nil {
		event := map[string]interface{}{
			"type":    "new_comment",
			"comment": comment,
		}
		// Notify post author
		s.wsManager.BroadcastToUserWithData(postAuthorID, event)

		// If it's a reply, notify parent comment author
		if comment.ParentCommentID != nil {
			parentComment, _ := s.commentRepo.GetComment(context.Background(), *comment.ParentCommentID)
			if parentComment != nil {
				replyEvent := map[string]interface{}{
					"type":    "comment_reply",
					"comment": comment,
				}
				s.wsManager.BroadcastToUserWithData(parentComment.UserID, replyEvent)
			}
		}
	}
}

func (s *Service) broadcastPostShared(postID, sharerID, authorID uuid.UUID) {
	if s.wsManager != nil {
		event := map[string]interface{}{
			"type":      "post_shared",
			"post_id":   postID,
			"sharer_id": sharerID,
		}
		s.wsManager.BroadcastToUserWithData(authorID, event)
	}
}

func (s *Service) broadcastPostDeleted(postID uuid.UUID) {
	// For broadcasts to all users, would need a broadcast-all method
	// For now, just log
	fmt.Printf("[Posts] Post deleted: %s\n", postID)
}

func (s *Service) broadcastPollVote(pollID uuid.UUID, results *models.PollResults) {
	// Broadcast poll results to viewers
	fmt.Printf("[Posts] Poll vote recorded: %s\n", pollID)
}

// GetUserLikedPosts retrieves all posts that a user has liked
func (s *Service) GetUserLikedPosts(ctx context.Context, userID uuid.UUID, limit, offset int) ([]models.Post, int, error) {
	return s.postRepo.GetUserLikedPosts(ctx, userID, limit, offset)
}

// GetUserCommentedPosts retrieves all posts that a user has commented on
func (s *Service) GetUserCommentedPosts(ctx context.Context, userID uuid.UUID, limit, offset int) ([]models.Post, int, error) {
	return s.postRepo.GetUserCommentedPosts(ctx, userID, limit, offset)
}

// GetUserDeletedPosts retrieves all posts that a user has deleted (within last 30 days)
func (s *Service) GetUserDeletedPosts(ctx context.Context, userID uuid.UUID, limit, offset int) ([]models.Post, int, error) {
	return s.postRepo.GetUserDeletedPosts(ctx, userID, limit, offset)
}

// GetUserSharedPosts retrieves all posts/articles that a user has shared
func (s *Service) GetUserSharedPosts(ctx context.Context, userID uuid.UUID, postType string, limit, offset int) ([]models.Post, int, error) {
	return s.postRepo.GetUserSharedPosts(ctx, userID, postType, limit, offset)
}
