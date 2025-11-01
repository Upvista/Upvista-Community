<!-- e1d7acd3-dfdb-4e3a-8cd0-20cce3e5f784 f2c80b12-ad94-4345-b5cc-0ccea1e8a76c -->
# Production-Ready Authentication System Implementation Plan

## Phase 1: Critical Infrastructure (Rate Limiting & Token Blacklist)

### 1.1 Redis Setup & Configuration

- Add Redis configuration to `internal/config/config.go` (host, port, password, db)
- Create `internal/database/redis.go` with Redis connection pool
- Add Redis client dependency (`github.com/redis/go-redis/v9`)

### 1.2 Rate Limiting Middleware

- Create `internal/middleware/ratelimit.go` with Redis-backed rate limiter
- Implement sliding window or token bucket algorithm
- Apply middleware to: `/api/v1/auth/login`, `/api/v1/auth/register`, `/api/v1/auth/forgot-password`, `/api/v1/auth/reset-password`
- Support per-IP and per-email rate limiting
- Return 429 with retry-after header

### 1.3 Token Blacklist System

- Create `internal/utils/token_blacklist.go` using Redis
- Store blacklisted tokens with expiry matching JWT expiry
- Modify `JWTAuthMiddleware` in `internal/auth/middleware.go` to check blacklist
- Update logout handler to blacklist tokens
- Add token revocation endpoint

## Phase 2: Account Management Endpoints

### 2.1 Database Schema Updates

- Update `scripts/migrate.sql` to add:
  - `bio`, `avatar_url`, `profile_visibility` fields to users table
  - `account_deleted_at` for soft deletes
  - `failed_login_attempts`, `locked_until` for account lockout

### 2.2 Repository Methods

- Extend `internal/repository/user.go` interface:
  - `UpdateProfile()`, `ChangePassword()`, `UpdateEmail()`, `UpdateUsername()`, `DeactivateAccount()`, `DeleteAccount()`
- Implement in `internal/repository/supabase_user_repository.go`

### 2.3 Service Layer

- Add methods to `internal/auth/service.go`:
  - `UpdateProfile()`, `ChangePassword()`, `UpdateEmail()`, `UpdateUsername()`, `DeactivateAccount()`, `DeleteAccount()`
- Add email change verification flow

### 2.4 HTTP Handlers

- Add to `internal/auth/handlers.go`:
  - `PUT /api/v1/users/me` - Update profile
  - `PUT /api/v1/users/me/password` - Change password
  - `PUT /api/v1/users/me/email` - Change email
  - `PUT /api/v1/users/me/username` - Change username
  - `POST /api/v1/users/me/deactivate` - Deactivate account
  - `DELETE /api/v1/users/me` - Delete account

### 2.5 Request/Response Models

- Add to `internal/models/user.go`:
  - `UpdateProfileRequest`, `ChangePasswordRequest`, `UpdateEmailRequest`, `UpdateUsernameRequest`

## Phase 3: OAuth Integration (Google, Apple, Facebook/Instagram)

### 3.1 OAuth Configuration

- Add OAuth config to `internal/config/config.go`:
  - Google: Client ID, Client Secret, Redirect URI
  - Apple: Client ID, Team ID, Key ID, Private Key, Redirect URI
  - Facebook: App ID, App Secret, Redirect URI
  - Instagram: Client ID, Client Secret, Redirect URI

### 3.2 Database Schema

- Add `oauth_providers` table: `id`, `user_id`, `provider` (google/apple/facebook/instagram), `provider_user_id`, `access_token`, `refresh_token`, `expires_at`
- Add `external_id` field to users table for OAuth users

### 3.3 OAuth Service

- Create `internal/auth/oauth.go`:
  - `InitiateOAuth()`, `HandleOAuthCallback()`, `LinkOAuthAccount()`, `UnlinkOAuthAccount()`
- Implement OAuth flows for each provider using `golang.org/x/oauth2`

### 3.4 OAuth Handlers

- Add to `internal/auth/handlers.go`:
  - `GET /api/v1/auth/oauth/:provider` - Initiate OAuth
  - `GET /api/v1/auth/oauth/:provider/callback` - Handle callback
  - `POST /api/v1/auth/oauth/:provider/link` - Link account (authenticated)
  - `DELETE /api/v1/auth/oauth/:provider/unlink` - Unlink account

### 3.5 Repository Methods

- Add `LinkOAuthProvider()`, `GetOAuthProvider()`, `UnlinkOAuthProvider()` to repository interface

## Phase 4: Two-Factor Authentication (TOTP)

### 4.1 Database Schema

- Add `user_2fa` table: `id`, `user_id`, `secret`, `backup_codes` (JSON array), `is_enabled`, `created_at`
- Add `is_2fa_enabled` field to users table

### 4.2 TOTP Service

- Create `internal/utils/totp.go`:
  - Generate secret, QR code, validate TOTP code
  - Generate backup codes
  - Use `github.com/pquerna/otp` library

### 4.3 2FA Service

- Add to `internal/auth/service.go`:
  - `Enable2FA()`, `Verify2FA()`, `Disable2FA()`, `GenerateBackupCodes()`, `VerifyBackupCode()`

### 4.4 2FA Handlers

- Add to `internal/auth/handlers.go`:
  - `POST /api/v1/auth/2fa/enable` - Enable 2FA
  - `POST /api/v1/auth/2fa/verify` - Verify setup code
  - `POST /api/v1/auth/2fa/disable` - Disable 2FA
  - `POST /api/v1/auth/2fa/backup-codes` - Generate backup codes
  - Modify login handler to require 2FA code if enabled

### 4.5 Repository Methods

- Add `Enable2FA()`, `Disable2FA()`, `Get2FA()`, `SaveBackupCodes()` to repository interface

## Phase 5: Advanced Session Management

### 5.1 Database Schema

- Enhance `user_sessions` table with device tracking
- Add indexes for efficient queries

### 5.2 Session Service

- Create `internal/auth/session.go`:
  - `CreateSession()`, `GetSessions()`, `RevokeSession()`, `RevokeAllSessions()`
  - Track device info, IP, user agent

### 5.3 Session Handlers

- Add to `internal/auth/handlers.go`:
  - `GET /api/v1/auth/sessions` - List all sessions
  - `DELETE /api/v1/auth/sessions/:id` - Revoke specific session
  - `DELETE /api/v1/auth/sessions` - Revoke all sessions

### 5.4 Update Login Flow

- Modify login handler to create session record
- Update logout to revoke session

## Phase 6: User Features (Search, Follow, Block)

### 6.1 Database Schema

- Create `user_follows` table: `id`, `follower_id`, `following_id`, `created_at`
- Create `user_blocks` table: `id`, `blocker_id`, `blocked_id`, `created_at`
- Create `user_privacy_settings` table: `user_id`, `profile_visibility`, `show_email`, `allow_follow_requests`

### 6.2 Repository Methods

- Add `FollowUser()`, `UnfollowUser()`, `BlockUser()`, `UnblockUser()`, `SearchUsers()`, `GetFollowers()`, `GetFollowing()`, `GetPrivacySettings()`, `UpdatePrivacySettings()`

### 6.3 Service Layer

- Create `internal/user/service.go`:
  - `FollowUser()`, `UnfollowUser()`, `BlockUser()`, `UnblockUser()`, `SearchUsers()`, `GetUserProfile()`, `UpdatePrivacySettings()`

### 6.4 User Handlers

- Create `internal/user/handlers.go`:
  - `GET /api/v1/users/:id` - Get user profile
  - `GET /api/v1/users/search` - Search users
  - `POST /api/v1/users/:id/follow` - Follow user
  - `DELETE /api/v1/users/:id/follow` - Unfollow user
  - `POST /api/v1/users/:id/block` - Block user
  - `DELETE /api/v1/users/:id/block` - Unblock user
  - `GET /api/v1/users/:id/followers` - Get followers
  - `GET /api/v1/users/:id/following` - Get following
  - `PUT /api/v1/users/me/privacy` - Update privacy settings

## Phase 7: Admin/Moderation

### 7.1 Database Schema

- Add `user_roles` table: `id`, `user_id`, `role` (admin/moderator/user), `granted_at`, `granted_by`
- Add `admin_actions` table for audit logs: `id`, `admin_id`, `target_user_id`, `action`, `details`, `created_at`

### 7.2 Admin Middleware

- Create `internal/middleware/admin.go`:
  - `AdminMiddleware()` - Check if user has admin role
  - `ModeratorMiddleware()` - Check if user has moderator or admin role

### 7.3 Admin Service

- Create `internal/admin/service.go`:
  - `SuspendUser()`, `BanUser()`, `UnbanUser()`, `ViewUserActivity()`, `GetAuditLogs()`

### 7.4 Admin Handlers

- Create `internal/admin/handlers.go`:
  - `POST /api/v1/admin/users/:id/suspend` - Suspend user
  - `POST /api/v1/admin/users/:id/ban` - Ban user
  - `DELETE /api/v1/admin/users/:id/ban` - Unban user
  - `GET /api/v1/admin/users/:id/activity` - View user activity
  - `GET /api/v1/admin/audit-logs` - Get audit logs

## Phase 8: Analytics/Telemetry

### 8.1 Metrics Service

- Create `internal/analytics/service.go`:
  - Track registration, login, logout events
  - Store in Redis or database

### 8.2 Analytics Handlers

- Add to `internal/admin/handlers.go`:
  - `GET /api/v1/admin/analytics/registrations` - Registration metrics
  - `GET /api/v1/admin/analytics/logins` - Login metrics
  - `GET /api/v1/admin/analytics/active-users` - Active users count

### 8.3 Error Tracking

- Integrate error tracking (Sentry or custom)
- Add middleware for error logging

## Phase 9: Email Management Enhancements

### 9.1 Email Service Updates

- Add to `internal/utils/email.go`:
  - `ResendVerificationEmail()`, `SendEmailChangeConfirmation()`, `SendEmailChangeNotification()`

### 9.2 Email Handlers

- Add to `internal/auth/handlers.go`:
  - `POST /api/v1/auth/resend-verification` - Resend verification email
  - `POST /api/v1/auth/verify-email-change` - Verify email change

### 9.3 Email Preferences

- Add `email_preferences` table: `user_id`, `newsletter`, `notifications`, `marketing`
- Add handler: `PUT /api/v1/users/me/email-preferences`

## Phase 10: Notification Settings

### 10.1 Database Schema

- Create `notification_settings` table: `user_id`, `push_enabled`, `email_enabled`, `push_follow`, `push_likes`, `push_comments`, `email_follow`, `email_likes`, `email_comments`

### 10.2 Notification Service

- Create `internal/notifications/service.go`:
  - `UpdateNotificationSettings()`, `GetNotificationSettings()`

### 10.3 Notification Handlers

- Add to `internal/user/handlers.go`:
  - `GET /api/v1/users/me/notifications/settings` - Get settings
  - `PUT /api/v1/users/me/notifications/settings` - Update settings

## Implementation Order & Dependencies

**Must be done in order:**

1. Phase 1 (Redis + Rate Limiting + Token Blacklist) - Foundation
2. Phase 2 (Account Management) - Core features
3. Phase 3 (OAuth) - Can be parallel with Phase 4
4. Phase 4 (2FA) - Can be parallel with Phase 3
5. Phase 5 (Session Management) - Builds on Phase 1
6. Phase 6 (User Features) - Requires Phase 2
7. Phase 7 (Admin) - Requires Phase 6
8. Phase 8 (Analytics) - Can be implemented anytime
9. Phase 9 (Email Enhancements) - Requires Phase 2
10. Phase 10 (Notifications) - Requires Phase 6

## Key Files to Create/Modify

**New Files:**

- `internal/database/redis.go`
- `internal/middleware/ratelimit.go`
- `internal/utils/token_blacklist.go`
- `internal/auth/oauth.go`
- `internal/utils/totp.go`
- `internal/auth/session.go`
- `internal/user/service.go`
- `internal/user/handlers.go`
- `internal/middleware/admin.go`
- `internal/admin/service.go`
- `internal/admin/handlers.go`
- `internal/analytics/service.go`
- `internal/notifications/service.go`

**Modified Files:**

- `internal/config/config.go` - Add Redis, OAuth, 2FA configs
- `internal/models/user.go` - Add new models
- `internal/repository/user.go` - Extend interface
- `internal/repository/supabase_user_repository.go` - Implement new methods
- `internal/auth/service.go` - Add new service methods
- `internal/auth/handlers.go` - Add new endpoints
- `internal/auth/middleware.go` - Add blacklist check
- `main.go` - Wire up new routes and middleware
- `scripts/migrate.sql` - Add new tables

## Dependencies to Add

```go
github.com/redis/go-redis/v9
golang.org/x/oauth2
golang.org/x/oauth2/google
golang.org/x/oauth2/apple
github.com/pquerna/otp
github.com/pquerna/otp/totp
github.com/skip2/go-qrcode
```

## Testing Strategy

- Unit tests for each service method
- Integration tests for API endpoints
- Load testing for rate limiting
- Security testing for OAuth and 2FA flows
- End-to-end authentication flow tests

### To-dos

- [ ] Phase 1.1: Setup Redis connection and configuration
- [ ] Phase 1.2: Implement Redis-backed rate limiting middleware
- [ ] Phase 1.3: Implement token blacklist system with Redis
- [ ] Phase 2.1: Update database schema for account management
- [ ] Phase 2.2: Extend repository interface and implementation
- [ ] Phase 2.3: Add account management service methods
- [ ] Phase 2.4: Create account management HTTP handlers
- [ ] Phase 3.1: Add OAuth configuration (Google, Apple, Facebook, Instagram)
- [ ] Phase 3.2: Create oauth_providers table schema
- [ ] Phase 3.3: Implement OAuth service with all providers
- [ ] Phase 3.4: Create OAuth handlers and routes
- [ ] Phase 4.1: Create user_2fa table schema
- [ ] Phase 4.2: Implement TOTP utility functions
- [ ] Phase 4.3: Add 2FA service methods (enable, disable, verify)
- [ ] Phase 4.4: Create 2FA HTTP handlers and update login flow
- [ ] Phase 5.1: Enhance user_sessions table schema
- [ ] Phase 5.2: Implement session management service
- [ ] Phase 5.3: Create session management handlers
- [ ] Phase 6.1: Create user_follows, user_blocks, user_privacy_settings tables
- [ ] Phase 6.2: Add repository methods for follows, blocks, search
- [ ] Phase 6.3: Create user service for social features
- [ ] Phase 6.4: Create user feature handlers (follow, block, search, privacy)
- [ ] Phase 7.1: Create user_roles and admin_actions tables
- [ ] Phase 7.2: Create admin and moderator middleware
- [ ] Phase 7.3: Implement admin service (suspend, ban, audit logs)
- [ ] Phase 7.4: Create admin HTTP handlers
- [ ] Phase 8: Implement analytics service and handlers
- [ ] Phase 9: Enhance email service with resend verification and email change
- [ ] Phase 10: Implement notification settings service and handlers
- [ ] Wire all new routes and middleware in main.go
- [ ] Add all required Go dependencies (Redis, OAuth, TOTP libraries)
- [ ] Update migrate.sql with all new tables and schema changes