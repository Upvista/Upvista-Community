package search

import (
	"context"
	"upvista-community-backend/internal/models"
	"upvista-community-backend/internal/repository"
)

// SearchService handles search business logic
type SearchService struct {
	userRepo repository.UserRepository
}

// NewSearchService creates a new search service
func NewSearchService(userRepo repository.UserRepository) *SearchService {
	return &SearchService{
		userRepo: userRepo,
	}
}

// SearchUsers searches for users matching the query
func (s *SearchService) SearchUsers(ctx context.Context, query string, page int, limit int) ([]*models.User, int, error) {
	if limit <= 0 || limit > 100 {
		limit = 20 // Default limit
	}
	if page < 1 {
		page = 1
	}

	offset := (page - 1) * limit

	return s.userRepo.SearchUsers(ctx, query, limit, offset)
}
