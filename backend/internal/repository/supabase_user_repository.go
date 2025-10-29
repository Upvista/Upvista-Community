package repository

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"

	"upvista-community-backend/internal/models"
	apperr "upvista-community-backend/pkg/errors"

	"github.com/google/uuid"
)

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
	body, _ := json.Marshal(user)
	q := url.Values{}
	q.Set("select", "*")
	req, _ := http.NewRequestWithContext(ctx, http.MethodPost, r.usersURL(q), bytes.NewReader(body))
	r.setHeaders(req, "return=representation")
	resp, err := r.http.Do(req)
	if err != nil {
		return apperr.ErrDatabaseError
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 300 {
		return apperr.ErrDatabaseError
	}
	// Optionally decode returned user array
	return nil
}

func (r *SupabaseUserRepository) fetchOne(ctx context.Context, q url.Values) (*models.User, error) {
	q.Set("select", "*")
	q.Set("limit", "1")
	req, _ := http.NewRequestWithContext(ctx, http.MethodGet, r.usersURL(q), nil)
	r.setHeaders(req, "")
	resp, err := r.http.Do(req)
	if err != nil {
		return nil, apperr.ErrDatabaseError
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusNotFound {
		return nil, apperr.ErrUserNotFound
	}
	if resp.StatusCode >= 300 {
		return nil, apperr.ErrDatabaseError
	}
	var users []models.User
	if err := json.NewDecoder(resp.Body).Decode(&users); err != nil {
		return nil, apperr.ErrDatabaseError
	}
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
	update := map[string]interface{}{
		"is_email_verified":             true,
		"email_verification_code":       nil,
		"email_verification_expires_at": nil,
		"updated_at":                    time.Now(),
	}
	body, _ := json.Marshal(update)
	q := url.Values{}
	// PostgREST allows and=() via query params using or+filters; here we use both filters
	q.Set("email", "eq."+email)
	q.Set("email_verification_code", "eq."+code)
	req, _ := http.NewRequestWithContext(ctx, http.MethodPatch, r.usersURL(q), bytes.NewReader(body))
	r.setHeaders(req, "return=minimal")
	resp, err := r.http.Do(req)
	if err != nil {
		return apperr.ErrInvalidVerificationCode
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 300 {
		return apperr.ErrInvalidVerificationCode
	}
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
		return false, apperr.ErrDatabaseError
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 300 {
		return false, apperr.ErrDatabaseError
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
		return false, apperr.ErrDatabaseError
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 300 {
		return false, apperr.ErrDatabaseError
	}
	var users []models.User
	if err := json.NewDecoder(resp.Body).Decode(&users); err != nil {
		return false, apperr.ErrDatabaseError
	}
	return len(users) > 0, nil
}
