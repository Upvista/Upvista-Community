package repository

import (
	"context"
	"time"

	"upvista-community-backend/internal/models"

	"github.com/google/uuid"
)

// UserRepository defines the data-access contract for users.
//
// Business logic must depend only on this interface, never on concrete providers
// (Supabase, Postgres, etc.). This enables easy swapping of persistence backends
// without changing service/handler code.
type UserRepository interface {
	CreateUser(ctx context.Context, user *models.User) error
	GetUserByID(ctx context.Context, id uuid.UUID) (*models.User, error)
	GetUserByEmail(ctx context.Context, email string) (*models.User, error)
	GetUserByUsername(ctx context.Context, username string) (*models.User, error)
	GetUserByEmailOrUsername(ctx context.Context, emailOrUsername string) (*models.User, error)
	GetUserByGoogleID(ctx context.Context, googleID string) (*models.User, error)
	GetUserByGitHubID(ctx context.Context, githubID string) (*models.User, error)
	GetUserByLinkedInID(ctx context.Context, linkedinID string) (*models.User, error)
	UpdateUser(ctx context.Context, user *models.User) error
	UpdateEmailVerification(ctx context.Context, email, code string, expiresAt time.Time) error
	VerifyEmail(ctx context.Context, email, code string) error
	UpdatePasswordReset(ctx context.Context, email, token string, expiresAt time.Time) error
	ResetPassword(ctx context.Context, token, newPasswordHash string) error
	UpdateLastLogin(ctx context.Context, userID uuid.UUID) error
	CheckEmailExists(ctx context.Context, email string) (bool, error)
	CheckUsernameExists(ctx context.Context, username string) (bool, error)
	UpdateProfile(ctx context.Context, userID uuid.UUID, updates map[string]interface{}) error
	UpdatePassword(ctx context.Context, userID uuid.UUID, newPasswordHash string) error
	DeleteUser(ctx context.Context, userID uuid.UUID) error
	InitiateEmailChange(ctx context.Context, userID uuid.UUID, newEmail, code string, expiresAt time.Time) error
	VerifyEmailChange(ctx context.Context, userID uuid.UUID, code string) error
	ChangeUsername(ctx context.Context, userID uuid.UUID, newUsername string) error
	DeactivateAccount(ctx context.Context, userID uuid.UUID) error

	// Profile System Phase 1 methods
	UpdateBasicProfile(ctx context.Context, userID uuid.UUID, req *models.UpdateBasicProfileRequest) error
	UpdatePrivacySettings(ctx context.Context, userID uuid.UUID, req *models.UpdatePrivacySettingsRequest) error
	UpdateStory(ctx context.Context, userID uuid.UUID, story *string) error
	UpdateAmbition(ctx context.Context, userID uuid.UUID, ambition *string) error
	UpdateSocialLinks(ctx context.Context, userID uuid.UUID, socialLinks map[string]*string) error
}
