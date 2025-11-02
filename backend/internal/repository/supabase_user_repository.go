package repository

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"strings"
	"time"

	"upvista-community-backend/internal/models"
	apperr "upvista-community-backend/pkg/errors"

	"github.com/google/uuid"
)

// min helper function
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// parseFlexibleTime parses timestamps in various formats (with or without timezone)
func parseFlexibleTime(timeStr string) time.Time {
	if timeStr == "" {
		return time.Time{}
	}

	// Try common timestamp formats (order matters - most specific first)
	formats := []string{
		time.RFC3339Nano,                 // "2006-01-02T15:04:05.999999999Z07:00"
		time.RFC3339,                     // "2006-01-02T15:04:05Z07:00"
		"2006-01-02T15:04:05.999999999Z", // "2006-01-02T15:04:05.999999999Z"
		"2006-01-02T15:04:05Z",           // "2006-01-02T15:04:05Z"
		"2006-01-02T15:04:05.999999999",  // "2006-01-02T15:04:05.999999999" (no timezone)
		"2006-01-02T15:04:05.999999",     // "2006-01-02T15:04:05.999999" (no timezone) - matches "2025-10-31T23:05:13.638454"
		"2006-01-02T15:04:05.999",        // "2006-01-02T15:04:05.999" (no timezone)
		"2006-01-02T15:04:05",            // "2006-01-02T15:04:05" (no timezone, no fractional seconds)
	}

	for _, format := range formats {
		if t, err := time.Parse(format, timeStr); err == nil {
			return t
		}
	}

	// Last resort: try parsing without fractional seconds if it contains a dot
	if strings.Contains(timeStr, ".") {
		parts := strings.Split(timeStr, ".")
		if len(parts) == 2 {
			basePart := parts[0] // "2025-10-31T23:05:13"
			if t, err := time.Parse("2006-01-02T15:04:05", basePart); err == nil {
				return t
			}
		}
	}

	// If all fail, return zero time
	log.Printf("[Supabase] parseFlexibleTime - Failed to parse timestamp: %s", timeStr)
	return time.Time{}
}

// SupabaseUserRepository implements UserRepository using Supabase PostgREST.
type SupabaseUserRepository struct {
	baseURL string // e.g. https://<project>.supabase.co/rest/v1
	apiKey  string // service role key
	http    *http.Client
}

func NewSupabaseUserRepository(baseURL, serviceRoleKey string) *SupabaseUserRepository {
	return &SupabaseUserRepository{
		baseURL: strings.TrimRight(baseURL, "/") + "/rest/v1",
		apiKey:  serviceRoleKey,
		http:    &http.Client{Timeout: 10 * time.Second},
	}
}

func (r *SupabaseUserRepository) setHeaders(req *http.Request, prefer string) {
	req.Header.Set("apikey", r.apiKey)
	req.Header.Set("Authorization", "Bearer "+r.apiKey)
	req.Header.Set("Content-Type", "application/json")
	if prefer != "" {
		req.Header.Set("Prefer", prefer)
	}
}

func (r *SupabaseUserRepository) usersURL(q url.Values) string {
	u := r.baseURL + "/users"
	if q != nil {
		return u + "?" + q.Encode()
	}
	return u
}

func (r *SupabaseUserRepository) CreateUser(ctx context.Context, user *models.User) error {
	// Create a map with all fields including password_hash (which is excluded from JSON by default)
	userData := map[string]interface{}{
		"id":                user.ID.String(),
		"email":             user.Email,
		"username":          user.Username,
		"password_hash":     user.PasswordHash, // Include password_hash explicitly
		"display_name":      user.DisplayName,
		"age":               user.Age,
		"is_email_verified": user.IsEmailVerified,
		"is_active":         user.IsActive,
		"created_at":        user.CreatedAt.Format("2006-01-02T15:04:05.999999999Z07:00"),
		"updated_at":        user.UpdatedAt.Format("2006-01-02T15:04:05.999999999Z07:00"),
	}

	// Add optional fields if they exist
	if user.EmailVerificationCode != nil {
		userData["email_verification_code"] = *user.EmailVerificationCode
	}
	if user.EmailVerificationExpiresAt != nil {
		userData["email_verification_expires_at"] = user.EmailVerificationExpiresAt.Format("2006-01-02T15:04:05.999999999Z07:00")
	}
	if user.LastLoginAt != nil {
		userData["last_login_at"] = user.LastLoginAt.Format("2006-01-02T15:04:05.999999999Z07:00")
	}

	// Add OAuth fields if they exist
	if user.GoogleID != nil {
		userData["google_id"] = *user.GoogleID
	}
	if user.GitHubID != nil {
		userData["github_id"] = *user.GitHubID
	}
	if user.LinkedInID != nil {
		userData["linkedin_id"] = *user.LinkedInID
	}
	if user.OAuthProvider != nil {
		userData["oauth_provider"] = *user.OAuthProvider
	}
	if user.ProfilePicture != nil {
		userData["profile_picture"] = *user.ProfilePicture
	}

	body, err := json.Marshal(userData)
	if err != nil {
		log.Printf("[Supabase] CreateUser marshal error: %v", err)
		return fmt.Errorf("%w: marshal error: %v", apperr.ErrDatabaseError, err)
	}

	q := url.Values{}
	q.Set("select", "*")
	req, _ := http.NewRequestWithContext(ctx, http.MethodPost, r.usersURL(q), bytes.NewReader(body))
	r.setHeaders(req, "return=representation")
	resp, err := r.http.Do(req)
	if err != nil {
		log.Printf("[Supabase] CreateUser request failed: %v", err)
		return fmt.Errorf("%w: request failed: %v", apperr.ErrDatabaseError, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 300 {
		bodyBytes, _ := io.ReadAll(resp.Body)
		log.Printf("[Supabase] CreateUser failed: HTTP %d - %s", resp.StatusCode, string(bodyBytes))
		return fmt.Errorf("%w: HTTP %d - %s", apperr.ErrDatabaseError, resp.StatusCode, string(bodyBytes))
	}
	return nil
}

func (r *SupabaseUserRepository) fetchOne(ctx context.Context, q url.Values) (*models.User, error) {
	// Only set select and limit if not already set
	if q.Get("select") == "" {
		q.Set("select", "*")
	}
	if q.Get("limit") == "" {
		q.Set("limit", "1")
	}
	url := r.usersURL(q)
	req, _ := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	r.setHeaders(req, "")
	resp, err := r.http.Do(req)
	if err != nil {
		log.Printf("[Supabase] fetchOne request failed: %v", err)
		return nil, fmt.Errorf("%w: request failed: %v", apperr.ErrDatabaseError, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusNotFound {
		return nil, apperr.ErrUserNotFound
	}
	if resp.StatusCode >= 300 {
		bodyBytes, _ := io.ReadAll(resp.Body)
		log.Printf("[Supabase] fetchOne failed: HTTP %d - %s", resp.StatusCode, string(bodyBytes))
		log.Printf("[Supabase] fetchOne - URL: %s", req.URL.String())
		return nil, fmt.Errorf("%w: HTTP %d - %s", apperr.ErrDatabaseError, resp.StatusCode, string(bodyBytes))
	}
	// Read response body first
	bodyBytes, _ := io.ReadAll(resp.Body)

	// Parse JSON into a flexible structure that handles timestamps
	var rawUsers []map[string]interface{}
	if err := json.Unmarshal(bodyBytes, &rawUsers); err != nil {
		log.Printf("[Supabase] fetchOne decode error: %v", err)
		return nil, fmt.Errorf("%w: decode error: %v", apperr.ErrDatabaseError, err)
	}

	if len(rawUsers) == 0 {
		return nil, apperr.ErrUserNotFound
	}

	// Manually convert to User model, handling timestamps
	user := &models.User{}
	rawUser := rawUsers[0]

	if idStr, ok := rawUser["id"].(string); ok {
		if id, err := uuid.Parse(idStr); err == nil {
			user.ID = id
		}
	}
	if email, ok := rawUser["email"].(string); ok {
		user.Email = email
	}
	if username, ok := rawUser["username"].(string); ok {
		user.Username = username
	}
	if passwordHash, ok := rawUser["password_hash"].(string); ok {
		user.PasswordHash = passwordHash
	}
	if displayName, ok := rawUser["display_name"].(string); ok {
		user.DisplayName = displayName
	}
	if age, ok := rawUser["age"].(float64); ok {
		user.Age = int(age)
	}
	if isEmailVerified, ok := rawUser["is_email_verified"].(bool); ok {
		user.IsEmailVerified = isEmailVerified
	}
	if isActive, ok := rawUser["is_active"].(bool); ok {
		user.IsActive = isActive
	}

	// Parse OAuth fields
	if googleID, ok := rawUser["google_id"].(string); ok && googleID != "" {
		user.GoogleID = &googleID
	}
	if githubID, ok := rawUser["github_id"].(string); ok && githubID != "" {
		user.GitHubID = &githubID
	}
	if linkedinID, ok := rawUser["linkedin_id"].(string); ok && linkedinID != "" {
		user.LinkedInID = &linkedinID
	}

	// Parse pending email change fields
	if pendingEmail, ok := rawUser["pending_email"].(string); ok && pendingEmail != "" {
		user.PendingEmail = &pendingEmail
	}
	if pendingEmailCode, ok := rawUser["pending_email_code"].(string); ok && pendingEmailCode != "" {
		user.PendingEmailCode = &pendingEmailCode
	}
	if pendingEmailExpiresAtStr, ok := rawUser["pending_email_expires_at"].(string); ok && pendingEmailExpiresAtStr != "" {
		t := parseFlexibleTime(pendingEmailExpiresAtStr)
		if !t.IsZero() {
			user.PendingEmailExpiresAt = &t
		}
	}
	if oauthProvider, ok := rawUser["oauth_provider"].(string); ok && oauthProvider != "" {
		user.OAuthProvider = &oauthProvider
	}
	if profilePicture, ok := rawUser["profile_picture"].(string); ok && profilePicture != "" {
		user.ProfilePicture = &profilePicture
	}

	// Parse timestamps with flexible format
	if createdAtStr, ok := rawUser["created_at"].(string); ok {
		if t := parseFlexibleTime(createdAtStr); !t.IsZero() {
			user.CreatedAt = t
		}
	}
	if updatedAtStr, ok := rawUser["updated_at"].(string); ok {
		if t := parseFlexibleTime(updatedAtStr); !t.IsZero() {
			user.UpdatedAt = t
		}
	}
	if lastLoginAtStr, ok := rawUser["last_login_at"].(string); ok && lastLoginAtStr != "" {
		t := parseFlexibleTime(lastLoginAtStr)
		if !t.IsZero() {
			user.LastLoginAt = &t
		}
	}

	var users []models.User
	users = append(users, *user)
	if len(users) == 0 {
		return nil, apperr.ErrUserNotFound
	}
	return &users[0], nil
}

func (r *SupabaseUserRepository) GetUserByID(ctx context.Context, id uuid.UUID) (*models.User, error) {
	q := url.Values{}
	q.Set("id", "eq."+id.String())
	return r.fetchOne(ctx, q)
}

func (r *SupabaseUserRepository) GetUserByEmail(ctx context.Context, email string) (*models.User, error) {
	q := url.Values{}
	q.Set("email", "eq."+email)
	return r.fetchOne(ctx, q)
}

func (r *SupabaseUserRepository) GetUserByUsername(ctx context.Context, username string) (*models.User, error) {
	q := url.Values{}
	q.Set("username", "eq."+username)
	return r.fetchOne(ctx, q)
}

func (r *SupabaseUserRepository) GetUserByEmailOrUsername(ctx context.Context, emailOrUsername string) (*models.User, error) {
	q := url.Values{}
	q.Set("or", fmt.Sprintf("(email.eq.%s,username.eq.%s)", emailOrUsername, emailOrUsername))
	return r.fetchOne(ctx, q)
}

func (r *SupabaseUserRepository) GetUserByGoogleID(ctx context.Context, googleID string) (*models.User, error) {
	q := url.Values{}
	q.Set("google_id", "eq."+googleID)
	return r.fetchOne(ctx, q)
}

func (r *SupabaseUserRepository) GetUserByGitHubID(ctx context.Context, githubID string) (*models.User, error) {
	q := url.Values{}
	q.Set("github_id", "eq."+githubID)
	return r.fetchOne(ctx, q)
}

func (r *SupabaseUserRepository) GetUserByLinkedInID(ctx context.Context, linkedinID string) (*models.User, error) {
	q := url.Values{}
	q.Set("linkedin_id", "eq."+linkedinID)
	return r.fetchOne(ctx, q)
}

func (r *SupabaseUserRepository) UpdateUser(ctx context.Context, user *models.User) error {
	body, _ := json.Marshal(user)
	q := url.Values{}
	q.Set("id", "eq."+user.ID.String())
	req, _ := http.NewRequestWithContext(ctx, http.MethodPatch, r.usersURL(q), bytes.NewReader(body))
	r.setHeaders(req, "return=minimal")
	resp, err := r.http.Do(req)
	if err != nil {
		return apperr.ErrDatabaseError
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 300 {
		return apperr.ErrDatabaseError
	}
	return nil
}

func (r *SupabaseUserRepository) UpdateEmailVerification(ctx context.Context, email, code string, expiresAt time.Time) error {
	update := map[string]interface{}{
		"email_verification_code":       code,
		"email_verification_expires_at": expiresAt,
		"updated_at":                    time.Now(),
	}
	body, _ := json.Marshal(update)
	q := url.Values{}
	q.Set("email", "eq."+email)
	req, _ := http.NewRequestWithContext(ctx, http.MethodPatch, r.usersURL(q), bytes.NewReader(body))
	r.setHeaders(req, "return=minimal")
	resp, err := r.http.Do(req)
	if err != nil {
		return apperr.ErrDatabaseError
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 300 {
		return apperr.ErrDatabaseError
	}
	return nil
}

func (r *SupabaseUserRepository) VerifyEmail(ctx context.Context, email, code string) error {
	// Fetch user directly with only needed fields to avoid RLS issues
	q := url.Values{}
	q.Set("email", "eq."+email)
	q.Set("select", "id,email,email_verification_code,email_verification_expires_at,is_email_verified")
	q.Set("limit", "1")

	fetchReq, _ := http.NewRequestWithContext(ctx, http.MethodGet, r.usersURL(q), nil)
	r.setHeaders(fetchReq, "")
	fetchResp, err := r.http.Do(fetchReq)
	if err != nil {
		log.Printf("[Supabase] VerifyEmail - Failed to fetch user: %v", err)
		return fmt.Errorf("%w: failed to fetch user: %v", apperr.ErrInvalidVerificationCode, err)
	}
	defer fetchResp.Body.Close()

	if fetchResp.StatusCode >= 300 {
		bodyBytes, _ := io.ReadAll(fetchResp.Body)
		log.Printf("[Supabase] VerifyEmail - Fetch user failed: HTTP %d - %s", fetchResp.StatusCode, string(bodyBytes))
		return fmt.Errorf("%w: user fetch failed: HTTP %d", apperr.ErrInvalidVerificationCode, fetchResp.StatusCode)
	}

	// Read raw response
	bodyBytes, _ := io.ReadAll(fetchResp.Body)

	// First, decode to a temporary struct to get the verification code
	// (since EmailVerificationCode has json:"-" tag)
	type tempUser struct {
		ID                         string  `json:"id"`
		Email                      string  `json:"email"`
		EmailVerificationCode      *string `json:"email_verification_code"`
		EmailVerificationExpiresAt *string `json:"email_verification_expires_at"` // Parse as string first
		IsEmailVerified            bool    `json:"is_email_verified"`
	}

	var tempUsers []tempUser
	if err := json.Unmarshal(bodyBytes, &tempUsers); err != nil {
		log.Printf("[Supabase] VerifyEmail - Failed to decode temp user: %v", err)
		return fmt.Errorf("%w: failed to decode user", apperr.ErrInvalidVerificationCode)
	}

	if len(tempUsers) == 0 {
		return apperr.ErrUserNotFound
	}

	tempUserData := tempUsers[0]

	// Check if code matches
	if tempUserData.EmailVerificationCode == nil {
		return apperr.ErrInvalidVerificationCode
	}

	// Parse expiry time if it exists
	var expiresAt *time.Time
	if tempUserData.EmailVerificationExpiresAt != nil && *tempUserData.EmailVerificationExpiresAt != "" {
		parsed, err := time.Parse(time.RFC3339, *tempUserData.EmailVerificationExpiresAt)
		if err == nil {
			expiresAt = &parsed
		}
	}

	// Check if code matches
	if *tempUserData.EmailVerificationCode != code {
		return apperr.ErrInvalidVerificationCode
	}

	// Check if code has expired
	if expiresAt != nil && time.Now().After(*expiresAt) {
		return apperr.ErrInvalidVerificationCode
	}

	// Now get the user ID as UUID
	userID, err := uuid.Parse(tempUserData.ID)
	if err != nil {
		return fmt.Errorf("%w: invalid user ID", apperr.ErrInvalidVerificationCode)
	}

	// Code is valid, update the user by ID (more reliable than filtering)
	update := map[string]interface{}{
		"is_email_verified":             true,
		"email_verification_code":       nil,
		"email_verification_expires_at": nil,
		"updated_at":                    time.Now().Format("2006-01-02T15:04:05.999999999Z07:00"),
	}

	body, err := json.Marshal(update)
	if err != nil {
		log.Printf("[Supabase] VerifyEmail marshal error: %v", err)
		return fmt.Errorf("%w: marshal error: %v", apperr.ErrInvalidVerificationCode, err)
	}

	// Update by ID instead of filtering
	q2 := url.Values{}
	q2.Set("id", "eq."+userID.String())

	req, _ := http.NewRequestWithContext(ctx, http.MethodPatch, r.usersURL(q2), bytes.NewReader(body))
	r.setHeaders(req, "return=representation")
	resp, err := r.http.Do(req)
	if err != nil {
		log.Printf("[Supabase] VerifyEmail request failed: %v", err)
		return fmt.Errorf("%w: request failed: %v", apperr.ErrInvalidVerificationCode, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		errorBodyBytes, _ := io.ReadAll(resp.Body)
		log.Printf("[Supabase] VerifyEmail failed: HTTP %d - %s", resp.StatusCode, string(errorBodyBytes))
		return fmt.Errorf("%w: HTTP %d - %s", apperr.ErrInvalidVerificationCode, resp.StatusCode, string(errorBodyBytes))
	}

	// Update succeeded (HTTP 200)
	// Response body can be ignored since update was successful

	return nil
}

func (r *SupabaseUserRepository) UpdatePasswordReset(ctx context.Context, email, token string, expiresAt time.Time) error {
	update := map[string]interface{}{
		"password_reset_token":      token,
		"password_reset_expires_at": expiresAt,
		"updated_at":                time.Now(),
	}
	body, _ := json.Marshal(update)
	q := url.Values{}
	q.Set("email", "eq."+email)
	req, _ := http.NewRequestWithContext(ctx, http.MethodPatch, r.usersURL(q), bytes.NewReader(body))
	r.setHeaders(req, "return=minimal")
	resp, err := r.http.Do(req)
	if err != nil {
		return apperr.ErrDatabaseError
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 300 {
		return apperr.ErrDatabaseError
	}
	return nil
}

func (r *SupabaseUserRepository) ResetPassword(ctx context.Context, token, newPasswordHash string) error {
	update := map[string]interface{}{
		"password_hash":             newPasswordHash,
		"password_reset_token":      nil,
		"password_reset_expires_at": nil,
		"updated_at":                time.Now(),
	}
	body, _ := json.Marshal(update)
	q := url.Values{}
	q.Set("password_reset_token", "eq."+token)
	req, _ := http.NewRequestWithContext(ctx, http.MethodPatch, r.usersURL(q), bytes.NewReader(body))
	r.setHeaders(req, "return=minimal")
	resp, err := r.http.Do(req)
	if err != nil {
		return apperr.ErrInvalidResetToken
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 300 {
		return apperr.ErrInvalidResetToken
	}
	return nil
}

func (r *SupabaseUserRepository) UpdateLastLogin(ctx context.Context, userID uuid.UUID) error {
	update := map[string]interface{}{
		"last_login_at": time.Now(),
		"updated_at":    time.Now(),
	}
	body, _ := json.Marshal(update)
	q := url.Values{}
	q.Set("id", "eq."+userID.String())
	req, _ := http.NewRequestWithContext(ctx, http.MethodPatch, r.usersURL(q), bytes.NewReader(body))
	r.setHeaders(req, "return=minimal")
	resp, err := r.http.Do(req)
	if err != nil {
		return apperr.ErrDatabaseError
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 300 {
		return apperr.ErrDatabaseError
	}
	return nil
}

func (r *SupabaseUserRepository) CheckEmailExists(ctx context.Context, email string) (bool, error) {
	q := url.Values{}
	q.Set("select", "id")
	q.Set("email", "eq."+email)
	q.Set("limit", "1")
	req, _ := http.NewRequestWithContext(ctx, http.MethodGet, r.usersURL(q), nil)
	r.setHeaders(req, "")
	resp, err := r.http.Do(req)
	if err != nil {
		log.Printf("[Supabase] CheckEmailExists request failed: %v", err)
		return false, fmt.Errorf("%w: request failed: %v", apperr.ErrDatabaseError, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 300 {
		bodyBytes, _ := io.ReadAll(resp.Body)
		log.Printf("[Supabase] CheckEmailExists failed: HTTP %d - %s", resp.StatusCode, string(bodyBytes))
		return false, fmt.Errorf("%w: HTTP %d - %s", apperr.ErrDatabaseError, resp.StatusCode, string(bodyBytes))
	}
	var users []models.User
	if err := json.NewDecoder(resp.Body).Decode(&users); err != nil {
		return false, apperr.ErrDatabaseError
	}
	return len(users) > 0, nil
}

func (r *SupabaseUserRepository) CheckUsernameExists(ctx context.Context, username string) (bool, error) {
	q := url.Values{}
	q.Set("select", "id")
	q.Set("username", "eq."+username)
	q.Set("limit", "1")
	req, _ := http.NewRequestWithContext(ctx, http.MethodGet, r.usersURL(q), nil)
	r.setHeaders(req, "")
	resp, err := r.http.Do(req)
	if err != nil {
		log.Printf("[Supabase] CheckUsernameExists request failed: %v", err)
		return false, fmt.Errorf("%w: request failed: %v", apperr.ErrDatabaseError, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 300 {
		bodyBytes, _ := io.ReadAll(resp.Body)
		log.Printf("[Supabase] CheckUsernameExists failed: HTTP %d - %s", resp.StatusCode, string(bodyBytes))
		return false, fmt.Errorf("%w: HTTP %d - %s", apperr.ErrDatabaseError, resp.StatusCode, string(bodyBytes))
	}
	var users []models.User
	if err := json.NewDecoder(resp.Body).Decode(&users); err != nil {
		return false, apperr.ErrDatabaseError
	}
	return len(users) > 0, nil
}

// UpdateProfile updates user profile fields
func (r *SupabaseUserRepository) UpdateProfile(ctx context.Context, userID uuid.UUID, updates map[string]interface{}) error {
	// Always update the updated_at timestamp
	updates["updated_at"] = time.Now()

	body, err := json.Marshal(updates)
	if err != nil {
		return apperr.ErrInternalServer
	}

	q := url.Values{}
	q.Set("id", "eq."+userID.String())

	req, err := http.NewRequestWithContext(ctx, http.MethodPatch, r.usersURL(q), bytes.NewReader(body))
	if err != nil {
		return apperr.ErrInternalServer
	}

	r.setHeaders(req, "return=minimal")

	resp, err := r.http.Do(req)
	if err != nil {
		return apperr.ErrDatabaseError
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		bodyBytes, _ := io.ReadAll(resp.Body)
		log.Printf("[Supabase] UpdateProfile failed: HTTP %d - %s", resp.StatusCode, string(bodyBytes))
		return apperr.ErrDatabaseError
	}

	return nil
}

// UpdatePassword updates user's password hash
func (r *SupabaseUserRepository) UpdatePassword(ctx context.Context, userID uuid.UUID, newPasswordHash string) error {
	update := map[string]interface{}{
		"password_hash": newPasswordHash,
		"updated_at":    time.Now(),
	}

	body, err := json.Marshal(update)
	if err != nil {
		return apperr.ErrInternalServer
	}

	q := url.Values{}
	q.Set("id", "eq."+userID.String())

	req, err := http.NewRequestWithContext(ctx, http.MethodPatch, r.usersURL(q), bytes.NewReader(body))
	if err != nil {
		return apperr.ErrInternalServer
	}

	r.setHeaders(req, "return=minimal")

	resp, err := r.http.Do(req)
	if err != nil {
		return apperr.ErrDatabaseError
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		bodyBytes, _ := io.ReadAll(resp.Body)
		log.Printf("[Supabase] UpdatePassword failed: HTTP %d - %s", resp.StatusCode, string(bodyBytes))
		return apperr.ErrDatabaseError
	}

	return nil
}

// DeleteUser permanently deletes a user account
func (r *SupabaseUserRepository) DeleteUser(ctx context.Context, userID uuid.UUID) error {
	q := url.Values{}
	q.Set("id", "eq."+userID.String())

	req, err := http.NewRequestWithContext(ctx, http.MethodDelete, r.usersURL(q), nil)
	if err != nil {
		return apperr.ErrInternalServer
	}

	r.setHeaders(req, "return=minimal")

	resp, err := r.http.Do(req)
	if err != nil {
		return apperr.ErrDatabaseError
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		bodyBytes, _ := io.ReadAll(resp.Body)
		log.Printf("[Supabase] DeleteUser failed: HTTP %d - %s", resp.StatusCode, string(bodyBytes))
		return apperr.ErrDatabaseError
	}

	return nil
}

// InitiateEmailChange stores pending email change request
func (r *SupabaseUserRepository) InitiateEmailChange(ctx context.Context, userID uuid.UUID, newEmail, code string, expiresAt time.Time) error {
	update := map[string]interface{}{
		"pending_email":            newEmail,
		"pending_email_code":       code,
		"pending_email_expires_at": expiresAt,
		"updated_at":               time.Now(),
	}

	body, err := json.Marshal(update)
	if err != nil {
		return apperr.ErrInternalServer
	}

	q := url.Values{}
	q.Set("id", "eq."+userID.String())

	req, err := http.NewRequestWithContext(ctx, http.MethodPatch, r.usersURL(q), bytes.NewReader(body))
	if err != nil {
		return apperr.ErrInternalServer
	}

	r.setHeaders(req, "return=minimal")

	resp, err := r.http.Do(req)
	if err != nil {
		return apperr.ErrDatabaseError
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		bodyBytes, _ := io.ReadAll(resp.Body)
		log.Printf("[Supabase] InitiateEmailChange failed: HTTP %d - %s", resp.StatusCode, string(bodyBytes))
		return apperr.ErrDatabaseError
	}

	return nil
}

// VerifyEmailChange completes the email change process
func (r *SupabaseUserRepository) VerifyEmailChange(ctx context.Context, userID uuid.UUID, code string) error {
	// First, fetch user to validate code
	user, err := r.GetUserByID(ctx, userID)
	if err != nil {
		return err
	}

	// Validate pending email exists
	if user.PendingEmail == nil || *user.PendingEmail == "" {
		return apperr.NewAppError(400, "No pending email change request found")
	}

	// Validate code
	if user.PendingEmailCode == nil || *user.PendingEmailCode != code {
		return apperr.NewAppError(400, "Invalid verification code")
	}

	// Check expiration
	if user.PendingEmailExpiresAt == nil || time.Now().After(*user.PendingEmailExpiresAt) {
		return apperr.NewAppError(400, "Verification code has expired")
	}

	// Update email and clear pending fields
	update := map[string]interface{}{
		"email":                    *user.PendingEmail,
		"pending_email":            nil,
		"pending_email_code":       nil,
		"pending_email_expires_at": nil,
		"updated_at":               time.Now(),
	}

	body, err := json.Marshal(update)
	if err != nil {
		return apperr.ErrInternalServer
	}

	q := url.Values{}
	q.Set("id", "eq."+userID.String())

	req, err := http.NewRequestWithContext(ctx, http.MethodPatch, r.usersURL(q), bytes.NewReader(body))
	if err != nil {
		return apperr.ErrInternalServer
	}

	r.setHeaders(req, "return=minimal")

	resp, err := r.http.Do(req)
	if err != nil {
		return apperr.ErrDatabaseError
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		bodyBytes, _ := io.ReadAll(resp.Body)
		log.Printf("[Supabase] VerifyEmailChange failed: HTTP %d - %s", resp.StatusCode, string(bodyBytes))
		return apperr.ErrDatabaseError
	}

	return nil
}

// ChangeUsername updates the username with tracking
func (r *SupabaseUserRepository) ChangeUsername(ctx context.Context, userID uuid.UUID, newUsername string) error {
	update := map[string]interface{}{
		"username":            newUsername,
		"username_changed_at": time.Now(),
		"updated_at":          time.Now(),
	}

	body, err := json.Marshal(update)
	if err != nil {
		return apperr.ErrInternalServer
	}

	q := url.Values{}
	q.Set("id", "eq."+userID.String())

	req, err := http.NewRequestWithContext(ctx, http.MethodPatch, r.usersURL(q), bytes.NewReader(body))
	if err != nil {
		return apperr.ErrInternalServer
	}

	r.setHeaders(req, "return=minimal")

	resp, err := r.http.Do(req)
	if err != nil {
		return apperr.ErrDatabaseError
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		bodyBytes, _ := io.ReadAll(resp.Body)
		log.Printf("[Supabase] ChangeUsername failed: HTTP %d - %s", resp.StatusCode, string(bodyBytes))
		return apperr.ErrDatabaseError
	}

	return nil
}

// DeactivateAccount soft deletes the account
func (r *SupabaseUserRepository) DeactivateAccount(ctx context.Context, userID uuid.UUID) error {
	update := map[string]interface{}{
		"is_active":  false,
		"updated_at": time.Now(),
	}

	body, err := json.Marshal(update)
	if err != nil {
		return apperr.ErrInternalServer
	}

	q := url.Values{}
	q.Set("id", "eq."+userID.String())

	req, err := http.NewRequestWithContext(ctx, http.MethodPatch, r.usersURL(q), bytes.NewReader(body))
	if err != nil {
		return apperr.ErrInternalServer
	}

	r.setHeaders(req, "return=minimal")

	resp, err := r.http.Do(req)
	if err != nil {
		return apperr.ErrDatabaseError
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		bodyBytes, _ := io.ReadAll(resp.Body)
		log.Printf("[Supabase] DeactivateAccount failed: HTTP %d - %s", resp.StatusCode, string(bodyBytes))
		return apperr.ErrDatabaseError
	}

	return nil
}
