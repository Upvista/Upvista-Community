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
	UpdateUser(ctx context.Context, user *models.User) error
	UpdateEmailVerification(ctx context.Context, email, code string, expiresAt time.Time) error
	VerifyEmail(ctx context.Context, email, code string) error
	UpdatePasswordReset(ctx context.Context, email, token string, expiresAt time.Time) error
	ResetPassword(ctx context.Context, token, newPasswordHash string) error
	UpdateLastLogin(ctx context.Context, userID uuid.UUID) error
	CheckEmailExists(ctx context.Context, email string) (bool, error)
	CheckUsernameExists(ctx context.Context, username string) (bool, error)
}
