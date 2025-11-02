package repository

import (
	"fmt"
	"strings"

	"upvista-community-backend/internal/config"
)

// NewUserRepository creates a concrete UserRepository based on config.
// provider values: "supabase" (default), "postgres" (future), etc.
func NewUserRepository(cfg *config.Config) (UserRepository, error) {
	provider := strings.ToLower(strings.TrimSpace(cfg.Server.DataProvider))
	if provider == "" {
		provider = "supabase" // default
	}

	// Supabase via PostgREST
	if provider == "supabase" {
		return NewSupabaseUserRepository(cfg.Database.SupabaseURL, cfg.Database.SupabaseServiceKey), nil
	}

	return nil, fmt.Errorf("unsupported data provider: %s", provider)
}

// NewSessionRepository creates a concrete SessionRepository based on config
func NewSessionRepository(cfg *config.Config) (SessionRepository, error) {
	provider := strings.ToLower(strings.TrimSpace(cfg.Server.DataProvider))
	if provider == "" {
		provider = "supabase" // default
	}

	// Supabase via PostgREST
	if provider == "supabase" {
		return NewSupabaseSessionRepository(cfg.Database.SupabaseURL, cfg.Database.SupabaseServiceKey), nil
	}

	return nil, fmt.Errorf("unsupported data provider: %s", provider)
}
