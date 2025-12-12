---
name: Professional Profile System - Phase 1
overview: ""
todos:
  - id: 268fd6a2-c6fa-439c-a344-ab586f7b1472
    content: Create and run profile_phase1_migration.sql to add bio, location, gender, website, story, ambition, privacy settings, field visibility, stats, and constraints to users table
    status: pending
  - id: 7248f55e-8723-4340-b75a-44bb119b89f8
    content: Update User model and create request/response models (UpdateBasicProfileRequest, UpdatePrivacySettingsRequest, UpdateStoryRequest, UpdateAmbitionRequest, PublicProfileResponse)
    status: pending
  - id: 01177fca-9fd4-4b5b-90cb-e6c18527ad27
    content: "Update supabase_user_repository.go to parse new fields and add methods: UpdateBasicProfile, UpdatePrivacySettings, UpdateStory, UpdateAmbition, GetPublicProfile"
    status: pending
  - id: c161a012-d857-42aa-aa3d-763a8f0aeaad
    content: Create profile_service.go with privacy filtering logic (GetPublicProfile with access control, filterProfileFields)
    status: pending
  - id: 17f17ea7-136a-4f6b-a93f-114ab715bde8
    content: "Add account handlers for: UpdateBasicProfile, UpdatePrivacySettings, UpdateStory, UpdateAmbition, GetPublicProfile with validation"
    status: pending
  - id: d1c402f8-3804-4a42-815b-0cc22e6dd16d
    content: "Register new routes in main.go: PATCH /account/profile/basic, /privacy, /story, /ambition and GET /profile/:username"
    status: pending
  - id: d2e29f3a-7cb5-4a58-b173-082cb8b36ed2
    content: Add Basic Profile section to settings page with bio, location, gender dropdown, website fields and connect to backend
    status: pending
  - id: 6de95b88-2233-48e3-ae70-deaac4baa3ff
    content: Add Privacy Settings section to settings page with profile visibility radio and field visibility checkboxes
    status: pending
  - id: 48100e4a-6e82-4529-85aa-9d53e915e51f
    content: Create GenderSelect.tsx reusable component with dropdown and custom text input
    status: pending
  - id: f4cd6203-f8f3-4fa9-b2da-38f3def3413c
    content: Refactor profile page to fetch real data, display header with avatar/bio/metadata/stats, implement tabs (Feed/Communities/Projects/About)
    status: pending
  - id: d2efe1c1-a55a-45eb-a0db-b3497bae5bbd
    content: Create InlineEditor.tsx component for editing Story and Ambition sections with character counters
    status: pending
  - id: 5557db5b-3214-41ee-83cf-7979f00e990e
    content: Create ProfilePrivacyGuard.tsx component to handle loading, 404, 403, and private profile messages
    status: pending
  - id: b06f9881-aaa3-49fb-a984-8bbce308cd4d
    content: Test all endpoints, settings page updates, profile viewing with different privacy levels, field visibility toggling, and inline editing
    status: pending
  - id: f28c2482-3a5b-4ff2-8c22-d4f109e6350f
    content: "Polish UI/UX: proper spacing, iOS-inspired animations, glassmorphism effects, proper error states, loading skeletons"
    status: pending
---

# Professional Profile System - Phase 1

## Overview

Implement a professional, Wantedly-style profile system with essential fields, granular privacy controls, and a clean separation between Settings (basic info) and Profile (public-facing About sections).

---

## Database Schema Changes

### 1. Add New Columns to `users` Table

**Migration: `backend/scripts/profile_phase1_migration.sql`**

```sql
-- Add profile fields
ALTER TABLE users ADD COLUMN IF NOT EXISTS bio VARCHAR(300);
ALTER TABLE users ADD COLUMN IF NOT EXISTS location VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS gender VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS gender_custom VARCHAR(50);
ALTER TABLE users ADD COLUMN IF NOT EXISTS website VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE;

-- Add privacy settings
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_privacy VARCHAR(20) DEFAULT 'public';
-- Options: 'public', 'private', 'connections'

-- Add field visibility settings (JSON or separate columns)
ALTER TABLE users ADD COLUMN IF NOT EXISTS field_visibility JSONB DEFAULT '{
  "location": true,
  "gender": true,
  "age": true,
  "website": true,
  "joined_date": true,
  "email": false
}'::jsonb;

-- Add About section fields
ALTER TABLE users ADD COLUMN IF NOT EXISTS story TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS ambition VARCHAR(500);

-- Add stats (denormalized for performance)
ALTER TABLE users ADD COLUMN IF NOT EXISTS posts_count INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS followers_count INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS following_count INTEGER DEFAULT 0;

-- Constraints
ALTER TABLE users ADD CONSTRAINT check_bio_length CHECK (LENGTH(bio) <= 300);
ALTER TABLE users ADD CONSTRAINT check_ambition_length CHECK (LENGTH(ambition) <= 500);
ALTER TABLE users ADD CONSTRAINT check_profile_privacy CHECK (profile_privacy IN ('public', 'private', 'connections'));
ALTER TABLE users ADD CONSTRAINT check_gender CHECK (gender IN ('male', 'female', 'non-binary', 'prefer-not-to-say', 'custom') OR gender IS NULL);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_profile_privacy ON users(profile_privacy);
CREATE INDEX IF NOT EXISTS idx_users_is_verified ON users(is_verified);
```

---

## Backend Implementation

### 2. Update User Model

**File: `backend/internal/models/user.go`**

Add new fields to `User` struct:

```go
Bio               *string                `json:"bio,omitempty" db:"bio"`
Location          *string                `json:"location,omitempty" db:"location"`
Gender            *string                `json:"gender,omitempty" db:"gender"`
GenderCustom      *string                `json:"gender_custom,omitempty" db:"gender_custom"`
Website           *string                `json:"website,omitempty" db:"website"`
IsVerified        bool                   `json:"is_verified" db:"is_verified"`
ProfilePrivacy    string                 `json:"profile_privacy" db:"profile_privacy"`
FieldVisibility   map[string]bool        `json:"field_visibility" db:"field_visibility"`
Story             *string                `json:"story,omitempty" db:"story"`
Ambition          *string                `json:"ambition,omitempty" db:"ambition"`
PostsCount        int                    `json:"posts_count" db:"posts_count"`
FollowersCount    int                    `json:"followers_count" db:"followers_count"`
FollowingCount    int                    `json:"following_count" db:"following_count"`
```

Create new request/response models:

```go
type UpdateBasicProfileRequest struct {
    DisplayName *string `json:"display_name"`
    Bio         *string `json:"bio"`
    Location    *string `json:"location"`
    Gender      *string `json:"gender"`
    GenderCustom *string `json:"gender_custom"`
    Age         *int    `json:"age"`
    Website     *string `json:"website"`
}

type UpdatePrivacySettingsRequest struct {
    ProfilePrivacy  string          `json:"profile_privacy"`
    FieldVisibility map[string]bool `json:"field_visibility"`
}

type UpdateStoryRequest struct {
    Story *string `json:"story"`
}

type UpdateAmbitionRequest struct {
    Ambition *string `json:"ambition"`
}

type PublicProfileResponse struct {
    ID             uuid.UUID       `json:"id"`
    Username       string          `json:"username"`
    DisplayName    string          `json:"display_name"`
    ProfilePicture *string         `json:"profile_picture"`
    IsVerified     bool            `json:"is_verified"`
    Bio            *string         `json:"bio,omitempty"`
    Location       *string         `json:"location,omitempty"`
    Gender         *string         `json:"gender,omitempty"`
    GenderCustom   *string         `json:"gender_custom,omitempty"`
    Age            *int            `json:"age,omitempty"`
    Website        *string         `json:"website,omitempty"`
    JoinedAt       time.Time       `json:"joined_at"`
    Story          *string         `json:"story,omitempty"`
    Ambition       *string         `json:"ambition,omitempty"`
    PostsCount     int             `json:"posts_count"`
    FollowersCount int             `json:"followers_count"`
    FollowingCount int             `json:"following_count"`
    // Fields filtered based on privacy settings
}
```

### 3. Repository Layer Updates

**File: `backend/internal/repository/supabase_user_repository.go`**

Update `fetchOne` function to parse new fields from Supabase JSON.

Add new repository methods:

```go
UpdateBasicProfile(ctx context.Context, userID uuid.UUID, req *models.UpdateBasicProfileRequest) error
UpdatePrivacySettings(ctx context.Context, userID uuid.UUID, req *models.UpdatePrivacySettingsRequest) error
UpdateStory(ctx context.Context, userID uuid.UUID, story *string) error
UpdateAmbition(ctx context.Context, userID uuid.UUID, ambition *string) error
GetPublicProfile(ctx context.Context, username string, viewerID *uuid.UUID) (*models.PublicProfileResponse, error)
```

### 4. Service Layer

**File: `backend/internal/account/profile_service.go` (NEW)**

Create a dedicated profile service with privacy filtering logic:

```go
func (s *ProfileService) GetPublicProfile(username string, viewerID *uuid.UUID) (*models.PublicProfileResponse, error) {
    // 1. Fetch user by username
    // 2. Check profile privacy (public/private/connections)
    // 3. If private and viewer is not the owner, return 403
    // 4. If connections-only, check if viewer is connected (future: check connections table)
    // 5. Filter fields based on field_visibility settings
    // 6. Return filtered profile
}

func filterProfileFields(user *models.User, isOwner bool) *models.PublicProfileResponse {
    // Apply field visibility rules
    // Always hide sensitive fields (email, password, etc.)
    // Respect user's field_visibility preferences
}
```

### 5. API Handlers

**File: `backend/internal/account/handlers.go`**

Add new endpoints:

- `PATCH /api/v1/account/profile/basic` - Update basic profile info (bio, location, gender, website)
- `PATCH /api/v1/account/profile/privacy` - Update privacy settings
- `PATCH /api/v1/account/profile/story` - Update story section
- `PATCH /api/v1/account/profile/ambition` - Update ambition section
- `GET /api/v1/profile/:username` - Get public profile (with privacy filtering)

**File: `backend/main.go`**

Register new routes:

```go
account := api.Group("/account")
account.Use(authMiddleware.AuthMiddleware())
{
    account.PATCH("/profile/basic", accountHandlers.UpdateBasicProfile)
    account.PATCH("/profile/privacy", accountHandlers.UpdatePrivacySettings)
    account.PATCH("/profile/story", accountHandlers.UpdateStory)
    account.PATCH("/profile/ambition", accountHandlers.UpdateAmbition)
}

// Public profile endpoint (no auth required, but optional)
api.GET("/profile/:username", accountHandlers.GetPublicProfile)
```

### 6. Validation

Add validation in handlers:

- Bio max 300 chars
- Ambition max 500 chars
- Story max 2000 chars
- Website URL format validation
- Gender enum validation + custom text if "custom" selected
- Profile privacy must be: public/private/connections

---

## Frontend Implementation

### 7. Update Settings Page

**File: `frontend-web/app/(main)/settings/page.tsx`**

**Add New Section: "Basic Profile"** (before Account Settings)

Fields:

- Display Name (existing, moved here)
- Bio (textarea, 300 char limit, counter)
- Location (text input, optional)
- Gender (dropdown: Male/Female/Non-binary/Prefer not to say/Custom, if Custom → show text input)
- Age (existing, moved here)
- Website (URL input, optional)

**Add New Section: "Privacy Settings"**

- Profile Visibility: Radio buttons (Public/Private/Connections-only)
- Field Visibility: Checkboxes for each field (Location, Gender, Age, Website, Joined Date)

Connect to new backend endpoints:

- `PATCH /api/proxy/v1/account/profile/basic`
- `PATCH /api/proxy/v1/account/profile/privacy`

### 8. Update Profile Page Structure

**File: `frontend-web/app/(main)/profile/page.tsx`**

Currently uses mock data. Refactor to:

1. **Fetch profile data** from `GET /api/proxy/v1/profile/:username` (using `useUser` for own profile or `useParams` for other users)

2. **Profile Header Section:**

   - Avatar (large, centered)
   - Display Name (24px bold)
   - @username (16px, muted)
   - Verified badge (if `is_verified`) - custom purple checkmark icon
   - Bio (if present, 16px, 300 chars, centered)
   - Metadata row (conditionally shown based on `field_visibility`):
     - Location icon + text
     - Gender icon + text
     - Age icon + text
     - Joined date (always show)
     - Website link (external icon)

3. **Stats Row:**

   - Posts: {posts_count}
   - Followers: {followers_count}
   - Following: {following_count}
   - Clickable (future: navigate to lists)

4. **Tabs:**

   - Feed (default, empty for now - "No posts yet")
   - Communities (empty - "No communities joined")
   - Projects (empty - "No projects added")
   - About (active - shows Story and Ambition)

5. **About Tab Content:**

   - **Story Section:**
     - Heading: "Tell Your Story"
     - If empty and is own profile: "+ Add your story" button
     - If present: Story text (max 2000 chars)
     - If is own profile: Inline edit icon → opens editor

   - **Ambition Section:**
     - Heading: "Ambition"
     - If empty and is own profile: "+ Add your ambition" button
     - If present: Ambition text (max 500 chars)
     - If is own profile: Inline edit icon → opens editor

### 9. Create Inline Editor Component

**File: `frontend-web/components/profile/InlineEditor.tsx` (NEW)**

A reusable modal/drawer component for editing Story and Ambition:

- Modal with title
- Textarea with character counter
- Save/Cancel buttons
- Calls appropriate endpoint (`PATCH /api/proxy/v1/account/profile/story` or `/ambition`)
- Optimistic UI update

### 10. Create Profile Privacy Guard

**File: `frontend-web/components/profile/ProfilePrivacyGuard.tsx` (NEW)**

Wrapper component that handles:

- Loading state while fetching profile
- 404 if user not found
- 403 if profile is private and viewer is not owner
- "This profile is private" message for connections-only (when connections feature is not implemented)

### 11. Update useUser Hook

**File: `frontend-web/lib/hooks/useUser.ts`**

Add new fields to return type. No changes needed to logic (already fetches full profile).

### 12. Create Gender Dropdown Component

**File: `frontend-web/components/ui/GenderSelect.tsx` (NEW)**

Reusable component:

- Dropdown with options: Male, Female, Non-binary, Prefer not to say, Custom
- If "Custom" selected, shows text input below
- Returns both `gender` and `gender_custom` values

---

## Testing Plan

1. **Migration:** Run SQL migration in Supabase, verify all columns added
2. **Backend:** Test all new endpoints with Postman/curl
3. **Settings Page:** Update basic profile, verify data saves and displays
4. **Privacy Settings:** Change privacy, verify profile access control works
5. **Profile Page (Own):** View own profile, see all fields, edit Story/Ambition inline
6. **Profile Page (Other):** View another user's profile, verify privacy filtering works
7. **Field Visibility:** Toggle field visibility in settings, verify fields show/hide on profile

---

## Phase 2 Preview (Future)

After Phase 1 is tested and working:

- Experience entries (table: `user_experiences`, with public/recruiter-only toggle)
- Education entries (table: `user_education`)
- Achievements (table: `user_achievements`)
- Skills (table: `user_skills`)
- Timeline (derived from experiences/education)
- Projects tab (table: `user_projects`)
- Communities tab (query from `community_members` table - future)

---

## Implementation Order

1. Database migration
2. Backend models
3. Backend repository methods
4. Backend service + handlers
5. Backend route registration
6. Frontend Settings page updates
7. Frontend Profile page refactor
8. Frontend inline editor component
9. Testing and bug fixes
10. Polish UI/UX

---

**Attribution:** Designed and architected by Hamza Hafeez - Founder and CEO of Upvista