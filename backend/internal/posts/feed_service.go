package posts

import (
	"context"
	"fmt"

	"upvista-community-backend/internal/models"
	"upvista-community-backend/internal/repository"

	"github.com/google/uuid"
)

// FeedService handles feed generation and caching
type FeedService struct {
	postRepo         repository.PostRepository
	relationshipRepo repository.RelationshipRepository
}

// NewFeedService creates a new feed service
func NewFeedService(
	postRepo repository.PostRepository,
	relationshipRepo repository.RelationshipRepository,
) *FeedService {
	return &FeedService{
		postRepo:         postRepo,
		relationshipRepo: relationshipRepo,
	}
}

// GetHomeFeed retrieves the home feed for a user
// Algorithm: Chronological feed from following + own posts
func (s *FeedService) GetHomeFeed(ctx context.Context, userID uuid.UUID, limit, offset int) ([]models.Post, int, error) {
	// Get posts from following + own posts (chronological)
	posts, total, err := s.postRepo.GetHomeFeed(ctx, userID, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get home feed: %w", err)
	}

	// Enrich with user-specific data (is_liked, is_saved)
	// This is already done in the repository layer

	return posts, total, nil
}

// GetFollowingFeed retrieves posts only from users the viewer follows
func (s *FeedService) GetFollowingFeed(ctx context.Context, userID uuid.UUID, limit, offset int) ([]models.Post, int, error) {
	return s.postRepo.GetFollowingFeed(ctx, userID, limit, offset)
}

// GetExploreFeed retrieves trending/popular posts for discovery
func (s *FeedService) GetExploreFeed(ctx context.Context, userID uuid.UUID, limit, offset int) ([]models.Post, int, error) {
	return s.postRepo.GetExploreFeed(ctx, userID, limit, offset)
}

// GetUserFeed retrieves posts by a specific user
func (s *FeedService) GetUserFeed(ctx context.Context, username string, viewerID uuid.UUID, limit, offset int) ([]models.Post, int, error) {
	// First, get user ID by username
	// This would require a user repository reference
	// For now, we'll need to add this
	return []models.Post{}, 0, nil
}

// GetSavedFeed retrieves user's saved/bookmarked posts
func (s *FeedService) GetSavedFeed(ctx context.Context, userID uuid.UUID, collection string, limit, offset int) ([]models.Post, int, error) {
	return s.postRepo.GetSavedPosts(ctx, userID, collection, limit, offset)
}

// GetHashtagFeed retrieves posts with a specific hashtag
func (s *FeedService) GetHashtagFeed(ctx context.Context, hashtag string, viewerID uuid.UUID, limit, offset int) ([]models.Post, int, error) {
	return s.postRepo.GetHashtagFeed(ctx, hashtag, limit, offset)
}

// SearchPosts searches posts by query
func (s *FeedService) SearchPosts(ctx context.Context, query string, userID uuid.UUID, limit, offset int) ([]models.Post, int, error) {
	return s.postRepo.SearchPosts(ctx, query, userID, limit, offset)
}
