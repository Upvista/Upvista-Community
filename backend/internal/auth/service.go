package auth

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"time"

	"upvista-community-backend/internal/models"
	"upvista-community-backend/internal/repository"
	"upvista-community-backend/internal/utils"
	"upvista-community-backend/pkg/errors"

	"github.com/google/uuid"
)

// AuthService handles authentication business logic
type AuthService struct {
	userRepo repository.UserRepository
	emailSvc *utils.EmailService
	jwtSvc   *utils.JWTService
}

// NewAuthService creates a new authentication service
func NewAuthService(
	userRepo repository.UserRepository,
	emailSvc *utils.EmailService,
	jwtSvc *utils.JWTService,
) *AuthService {
	return &AuthService{
		userRepo: userRepo,
		emailSvc: emailSvc,
		jwtSvc:   jwtSvc,
	}
}

// RegisterUser handles user registration
func (s *AuthService) RegisterUser(ctx context.Context, req *models.RegisterRequest) (*models.AuthResponse, error) {
	// Validate input
	if err := utils.ValidateRegistration(req); err != nil {
		return nil, err
	}

	// Normalize inputs
	email := utils.NormalizeEmail(req.Email)
	username := utils.NormalizeUsername(req.Username)

	// Check if email already exists
	emailExists, err := s.userRepo.CheckEmailExists(ctx, email)
	if err != nil {
		return nil, errors.ErrDatabaseError
	}
	if emailExists {
		return nil, errors.ErrEmailAlreadyExists
	}

	// Check if username already exists
	usernameExists, err := s.userRepo.CheckUsernameExists(ctx, username)
	if err != nil {
		return nil, errors.ErrDatabaseError
	}
	if usernameExists {
		return nil, errors.ErrUsernameExists
	}

	// Hash password
	passwordHash, err := utils.HashPassword(req.Password)
	if err != nil {
		return nil, errors.ErrInternalServer
	}

	// Generate verification code
	verificationCode := s.emailSvc.GenerateVerificationCode()
	expiresAt := time.Now().Add(10 * time.Minute) // 10 minutes expiry

	// Create user
	user := &models.User{
		ID:                         uuid.New(),
		Email:                      email,
		Username:                   username,
		PasswordHash:               passwordHash,
		DisplayName:                req.DisplayName,
		Age:                        req.Age,
		IsEmailVerified:            false,
		EmailVerificationCode:      &verificationCode,
		EmailVerificationExpiresAt: &expiresAt,
		IsActive:                   true,
		CreatedAt:                  time.Now(),
		UpdatedAt:                  time.Now(),
	}

	// Save user to database
	if err := s.userRepo.CreateUser(ctx, user); err != nil {
		return nil, errors.ErrDatabaseError
	}

	// Send verification email
	if err := s.emailSvc.SendVerificationEmail(email, verificationCode); err != nil {
		// Log error but don't fail registration
		fmt.Printf("Failed to send verification email: %v\n", err)
	}

	return &models.AuthResponse{
		Success: true,
		Message: "Registration successful. Please check your email for verification code.",
		UserID:  user.ID.String(),
	}, nil
}

// VerifyEmail handles email verification
func (s *AuthService) VerifyEmail(ctx context.Context, req *models.VerifyEmailRequest) (*models.AuthResponse, error) {
	// Validate input
	if err := utils.ValidateEmailVerification(req); err != nil {
		return nil, err
	}

	// Normalize email
	email := utils.NormalizeEmail(req.Email)

	// Verify email with code
	if err := s.userRepo.VerifyEmail(ctx, email, req.VerificationCode); err != nil {
		return nil, err
	}

	// Get user
	user, err := s.userRepo.GetUserByEmail(ctx, email)
	if err != nil {
		return nil, err
	}

	// Generate JWT token
	token, err := s.jwtSvc.GenerateToken(user)
	if err != nil {
		return nil, errors.ErrInternalServer
	}

	// Update last login
	s.userRepo.UpdateLastLogin(ctx, user.ID)

	// Send welcome email
	go s.emailSvc.SendWelcomeEmail(user.Email, user.DisplayName)

	return &models.AuthResponse{
		Success:   true,
		Message:   "Email verified successfully",
		Token:     token,
		ExpiresAt: time.Now().Add(15 * time.Minute), // 15 minutes
		User:      user.ToSafeUser(),
	}, nil
}

// LoginUser handles user login
func (s *AuthService) LoginUser(ctx context.Context, req *models.LoginRequest) (*models.AuthResponse, error) {
	// Validate input
	if err := utils.ValidateLogin(req); err != nil {
		return nil, err
	}

	// Normalize input
	emailOrUsername := utils.NormalizeEmail(req.EmailOrUsername)

	// Get user by email or username
	user, err := s.userRepo.GetUserByEmailOrUsername(ctx, emailOrUsername)
	if err != nil {
		return nil, errors.ErrInvalidCredentials
	}

	// Check if user is active
	if !user.IsActive {
		return nil, errors.ErrUserInactive
	}

	// Verify password
	if !utils.CheckPasswordHash(req.Password, user.PasswordHash) {
		return nil, errors.ErrInvalidCredentials
	}

	// Check if email is verified
	if !user.IsEmailVerified {
		return nil, errors.ErrEmailNotVerified
	}

	// Generate JWT token
	token, err := s.jwtSvc.GenerateToken(user)
	if err != nil {
		return nil, errors.ErrInternalServer
	}

	// Update last login
	s.userRepo.UpdateLastLogin(ctx, user.ID)

	return &models.AuthResponse{
		Success:   true,
		Message:   "Login successful",
		Token:     token,
		ExpiresAt: time.Now().Add(15 * time.Minute), // 15 minutes
		User:      user.ToSafeUser(),
	}, nil
}

// ForgotPassword handles password reset request
func (s *AuthService) ForgotPassword(ctx context.Context, req *models.ForgotPasswordRequest) (*models.MessageResponse, error) {
	// Validate input
	if err := utils.ValidateForgotPassword(req); err != nil {
		return nil, err
	}

	// Normalize email
	email := utils.NormalizeEmail(req.Email)

	// Check if user exists
	_, err := s.userRepo.GetUserByEmail(ctx, email)
	if err != nil {
		// Don't reveal if user exists or not for security
		return &models.MessageResponse{
			Success: true,
			Message: "If the email exists, a password reset link has been sent.",
		}, nil
	}

	// Generate reset token
	resetToken, err := generateResetToken()
	if err != nil {
		return nil, errors.ErrInternalServer
	}

	// Set expiry (1 hour)
	expiresAt := time.Now().Add(1 * time.Hour)

	// Update user with reset token
	if err := s.userRepo.UpdatePasswordReset(ctx, email, resetToken, expiresAt); err != nil {
		return nil, errors.ErrInternalServer
	}

	// Send reset email
	if err := s.emailSvc.SendPasswordResetEmail(email, resetToken); err != nil {
		// Log error but don't fail the request
		fmt.Printf("Failed to send password reset email: %v\n", err)
	}

	return &models.MessageResponse{
		Success: true,
		Message: "If the email exists, a password reset link has been sent.",
	}, nil
}

// ResetPassword handles password reset
func (s *AuthService) ResetPassword(ctx context.Context, req *models.ResetPasswordRequest) (*models.MessageResponse, error) {
	// Validate input
	if err := utils.ValidateResetPassword(req); err != nil {
		return nil, err
	}

	// Hash new password
	newPasswordHash, err := utils.HashPassword(req.NewPassword)
	if err != nil {
		return nil, errors.ErrInternalServer
	}

	// Reset password
	if err := s.userRepo.ResetPassword(ctx, req.Token, newPasswordHash); err != nil {
		return nil, err
	}

	return &models.MessageResponse{
		Success: true,
		Message: "Password reset successfully",
	}, nil
}

// GetCurrentUser retrieves current user information
func (s *AuthService) GetCurrentUser(ctx context.Context, userID uuid.UUID) (*models.UserResponse, error) {
	user, err := s.userRepo.GetUserByID(ctx, userID)
	if err != nil {
		return nil, err
	}

	return &models.UserResponse{
		Success: true,
		User:    user.ToSafeUser(),
	}, nil
}

// RefreshToken handles token refresh
func (s *AuthService) RefreshToken(ctx context.Context, userID uuid.UUID) (*models.TokenResponse, error) {
	// Get user
	user, err := s.userRepo.GetUserByID(ctx, userID)
	if err != nil {
		return nil, err
	}

	// Check if user is active
	if !user.IsActive {
		return nil, errors.ErrUserInactive
	}

	// Generate new token
	token, err := s.jwtSvc.GenerateToken(user)
	if err != nil {
		return nil, errors.ErrInternalServer
	}

	return &models.TokenResponse{
		Success:   true,
		Message:   "Token refreshed successfully",
		Token:     token,
		ExpiresAt: time.Now().Add(15 * time.Minute), // 15 minutes
	}, nil
}

// LogoutUser handles user logout (optional implementation)
func (s *AuthService) LogoutUser(ctx context.Context, userID uuid.UUID) (*models.MessageResponse, error) {
	// For JWT-based auth, logout is typically handled client-side
	// by removing the token. Server-side logout would require
	// maintaining a blacklist of tokens, which we're not implementing
	// in this basic version.

	return &models.MessageResponse{
		Success: true,
		Message: "Logged out successfully",
	}, nil
}

// generateResetToken generates a secure random token for password reset
func generateResetToken() (string, error) {
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}
