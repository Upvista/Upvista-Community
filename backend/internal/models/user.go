package models

import (
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

// User represents a user in the system
type User struct {
	ID                         uuid.UUID  `json:"id" db:"id"`
	Email                      string     `json:"email" db:"email"`
	Username                   string     `json:"username" db:"username"`
	PasswordHash               string     `json:"-" db:"password_hash"`
	DisplayName                string     `json:"display_name" db:"display_name"`
	Age                        int        `json:"age" db:"age"`
	IsEmailVerified            bool       `json:"is_email_verified" db:"is_email_verified"`
	EmailVerificationCode      *string    `json:"-" db:"email_verification_code"`
	EmailVerificationExpiresAt *time.Time `json:"-" db:"email_verification_expires_at"`
	PasswordResetToken         *string    `json:"-" db:"password_reset_token"`
	PasswordResetExpiresAt     *time.Time `json:"-" db:"password_reset_expires_at"`
	IsActive                   bool       `json:"is_active" db:"is_active"`
	LastLoginAt                *time.Time `json:"last_login_at" db:"last_login_at"`
	CreatedAt                  time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt                  time.Time  `json:"updated_at" db:"updated_at"`
}

// UserSession represents a user session (optional for advanced session management)
type UserSession struct {
	ID         uuid.UUID `json:"id" db:"id"`
	UserID     uuid.UUID `json:"user_id" db:"user_id"`
	TokenHash  string    `json:"-" db:"token_hash"`
	DeviceInfo *string   `json:"device_info" db:"device_info"`
	IPAddress  *string   `json:"ip_address" db:"ip_address"`
	UserAgent  *string   `json:"user_agent" db:"user_agent"`
	ExpiresAt  time.Time `json:"expires_at" db:"expires_at"`
	CreatedAt  time.Time `json:"created_at" db:"created_at"`
}

// RegisterRequest represents the request payload for user registration
type RegisterRequest struct {
	Email       string `json:"email" validate:"required,email"`
	Password    string `json:"password" validate:"required,min=6"`
	DisplayName string `json:"display_name" validate:"required,min=2,max=50"`
	Username    string `json:"username" validate:"required,min=3,max=20,alphanum"`
	Age         int    `json:"age" validate:"required,min=13,max=120"`
}

// LoginRequest represents the request payload for user login
type LoginRequest struct {
	EmailOrUsername string `json:"email_or_username" validate:"required"`
	Password        string `json:"password" validate:"required"`
}

// VerifyEmailRequest represents the request payload for email verification
type VerifyEmailRequest struct {
	Email            string `json:"email" validate:"required,email"`
	VerificationCode string `json:"verification_code" validate:"required,len=6"`
}

// ForgotPasswordRequest represents the request payload for password reset request
type ForgotPasswordRequest struct {
	Email string `json:"email" validate:"required,email"`
}

// ResetPasswordRequest represents the request payload for password reset
type ResetPasswordRequest struct {
	Token       string `json:"token" validate:"required"`
	NewPassword string `json:"new_password" validate:"required,min=6"`
}

// RefreshTokenRequest represents the request payload for token refresh
type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required"`
}

// AuthResponse represents the response for authentication operations
type AuthResponse struct {
	Success   bool      `json:"success"`
	Message   string    `json:"message"`
	Token     string    `json:"token,omitempty"`
	ExpiresAt time.Time `json:"expires_at,omitempty"`
	User      *User     `json:"user,omitempty"`
	UserID    string    `json:"user_id,omitempty"`
}

// TokenResponse represents the response for token operations
type TokenResponse struct {
	Success   bool      `json:"success"`
	Message   string    `json:"message"`
	Token     string    `json:"token"`
	ExpiresAt time.Time `json:"expires_at"`
}

// UserResponse represents the response for user operations
type UserResponse struct {
	Success bool  `json:"success"`
	User    *User `json:"user"`
}

// MessageResponse represents a simple message response
type MessageResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
}

// JWTClaims represents the JWT token claims
type JWTClaims struct {
	UserID   string `json:"user_id"`
	Email    string `json:"email"`
	Username string `json:"username"`
	jwt.RegisteredClaims
}

// ToUser converts User model to a safe version without sensitive data
func (u *User) ToSafeUser() *User {
	return &User{
		ID:              u.ID,
		Email:           u.Email,
		Username:        u.Username,
		DisplayName:     u.DisplayName,
		Age:             u.Age,
		IsEmailVerified: u.IsEmailVerified,
		IsActive:        u.IsActive,
		LastLoginAt:     u.LastLoginAt,
		CreatedAt:       u.CreatedAt,
		UpdatedAt:       u.UpdatedAt,
	}
}
