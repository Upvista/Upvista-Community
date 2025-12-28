# Edit Profile System - Implementation Guide

## ✅ Completed

### 1. Database Migration
- ✅ Created `advanced_profile_migration.sql` with all new tables:
  - `companies` - For company logos in experiences
  - `user_certifications` - Certifications with issue/expiration dates
  - `user_skills` - Skills with proficiency levels
  - `user_languages` - Languages with proficiency
  - `user_volunteering` - Volunteer experience
  - `user_publications` - Publications with URLs
  - `user_interests` - User interests
  - `user_achievements` - Achievements and awards
- ✅ Updated `story` field to 1000 characters
- ✅ Added `company_id` to `user_experiences` table
- ✅ All tables have proper indexes, RLS policies, and triggers

### 2. Backend Models
- ✅ Added all new models to `backend/internal/models/user.go`:
  - `Company`
  - `UserCertification`
  - `UserSkill`
  - `UserLanguage`
  - `UserVolunteering`
  - `UserPublication`
  - `UserInterest`
  - `UserAchievement`
- ✅ Added request/response models for all CRUD operations
- ✅ Updated `UserExperience` to include `CompanyID`

### 3. Flutter Edit Profile Screen
- ✅ Created comprehensive `edit_profile_screen.dart`
- ✅ Shows all profile sections with edit buttons:
  - Profile Picture (with camera icon)
  - Basic Information (name, username, bio, age, gender, location, website)
  - Story (1000 characters)
  - Experience (list with add/edit)
  - Education (list with add/edit)
  - Skills (list with add/edit)
  - Certifications (list with add/edit)
  - Languages (list with add/edit)
  - Volunteering (list with add/edit)
  - Publications (list with add/edit)
  - Interests (list with add/edit)
  - Achievements (list with add/edit)
  - Social Links
- ✅ Only visible to profile owner (uses AuthProvider)
- ✅ Beautiful UI with sections, icons, and edit buttons
- ✅ Navigation integrated to `/edit-profile`

## ✅ Backend Implementation - Completed

### 1. Repository Interfaces ✅
- ✅ Created `backend/internal/repository/advanced_profile.go` with all interfaces
- ✅ All repository interfaces defined for Company, Certification, Skill, Language, Volunteering, Publication, Interest, Achievement

### 2. Supabase Repository Implementations ✅
- ✅ Created `backend/internal/repository/supabase_advanced_profile.go`
- ✅ Created `backend/internal/repository/supabase_advanced_profile_part2.go`
- ✅ All CRUD operations implemented using Supabase PostgREST
- ✅ Proper error handling and JSON parsing

### 3. Service Layer ✅
- ✅ Created `backend/internal/account/advanced_profile_service.go`
- ✅ Business logic for all CRUD operations
- ✅ Validation and ordering (newest first)
- ✅ Company lookup/creation logic
- ✅ Ownership checks for security

### 4. Handlers ✅
- ✅ Created `backend/internal/account/advanced_profile_handlers.go`
- ✅ All HTTP handlers for CRUD operations
- ✅ Updated `handlers.go` to include new routes
- ✅ Updated Story handler to accept 1000 characters
- ✅ All endpoints protected with JWT middleware

### 5. Main.go Integration ✅
- ✅ Initialized all new repositories
- ✅ Initialized advanced profile service
- ✅ Updated AccountHandlers constructor

## 🔨 TODO - Backend Implementation (All Complete!)

### 1. Repository Interfaces
Create `backend/internal/repository/advanced_profile.go`:
```go
type CompanyRepository interface {
    CreateOrGetCompany(ctx context.Context, name string) (*models.Company, error)
    GetCompanyByID(ctx context.Context, id uuid.UUID) (*models.Company, error)
    SearchCompanies(ctx context.Context, query string) ([]*models.Company, error)
}

type CertificationRepository interface {
    CreateCertification(ctx context.Context, cert *models.UserCertification) error
    GetCertificationByID(ctx context.Context, id uuid.UUID) (*models.UserCertification, error)
    GetUserCertifications(ctx context.Context, userID uuid.UUID) ([]*models.UserCertification, error)
    UpdateCertification(ctx context.Context, cert *models.UserCertification) error
    DeleteCertification(ctx context.Context, id uuid.UUID) error
}

// Similar interfaces for Skills, Languages, Volunteering, Publications, Interests, Achievements
```

### 2. Supabase Repository Implementations
Create `backend/internal/repository/supabase_advanced_profile.go`:
- Implement all repository interfaces using Supabase PostgREST
- Follow the same pattern as `supabase_experience_education.go`

### 3. Service Layer
Create `backend/internal/account/advanced_profile_service.go`:
- Business logic for all CRUD operations
- Validation
- Ordering (newest first for experiences)
- Company lookup/creation

### 4. Handlers
Add to `backend/internal/account/handlers.go`:
```go
// Certifications
account.POST("/certifications", h.CreateCertification)
account.GET("/certifications", h.GetMyCertifications)
account.PATCH("/certifications/:id", h.UpdateCertification)
account.DELETE("/certifications/:id", h.DeleteCertification)

// Skills
account.POST("/skills", h.CreateSkill)
account.GET("/skills", h.GetMySkills)
account.PATCH("/skills/:id", h.UpdateSkill)
account.DELETE("/skills/:id", h.DeleteSkill)

// Languages
account.POST("/languages", h.CreateLanguage)
account.GET("/languages", h.GetMyLanguages)
account.PATCH("/languages/:id", h.UpdateLanguage)
account.DELETE("/languages/:id", h.DeleteLanguage)

// Volunteering
account.POST("/volunteering", h.CreateVolunteering)
account.GET("/volunteering", h.GetMyVolunteering)
account.PATCH("/volunteering/:id", h.UpdateVolunteering)
account.DELETE("/volunteering/:id", h.DeleteVolunteering)

// Publications
account.POST("/publications", h.CreatePublication)
account.GET("/publications", h.GetMyPublications)
account.PATCH("/publications/:id", h.UpdatePublication)
account.DELETE("/publications/:id", h.DeletePublication)

// Interests
account.POST("/interests", h.CreateInterest)
account.GET("/interests", h.GetMyInterests)
account.PATCH("/interests/:id", h.UpdateInterest)
account.DELETE("/interests/:id", h.DeleteInterest)

// Achievements
account.POST("/achievements", h.CreateAchievement)
account.GET("/achievements", h.GetMyAchievements)
account.PATCH("/achievements/:id", h.UpdateAchievement)
account.DELETE("/achievements/:id", h.DeleteAchievement)

// Companies
account.GET("/companies/search", h.SearchCompanies)
account.POST("/companies", h.CreateCompany)
```

### 5. Update Story Endpoint
Update `UpdateStory` handler to accept 1000 characters instead of 800.

## ✅ Flutter Implementation - Completed

### 1. Models
- ✅ Created all models in `mobile-app/lib/features/profile/data/models/`:
  - `certification.dart` - With JSON serialization
  - `skill.dart` - With proficiency levels
  - `language.dart` - With proficiency levels
  - `volunteering.dart` - With date handling
  - `publication.dart` - With URL support
  - `interest.dart` - With categories
  - `achievement.dart` - With achievement types
  - `company.dart` - With logo URL support
- ✅ All models use `@JsonSerializable` with proper snake_case to camelCase mapping
- ✅ Generated `.g.dart` files via build_runner

### 2. Service
- ✅ Created `mobile-app/lib/features/profile/data/services/profile_service.dart`
- ✅ Methods to fetch/update all profile entities
- ✅ Company search functionality
- ✅ Complete CRUD operations for all entities
- ✅ Properly integrated with `ApiClient`

### 3. Edit Screens (TODO)
Create individual edit screens for each entity:
- `/edit-profile/story` - Story editor (1000 chars)
- `/edit-profile/experience/add` - Add experience
- `/edit-profile/experience/:id` - Edit experience
- `/edit-profile/education/add` - Add education
- `/edit-profile/education/:id` - Edit education
- Similar for all other entities (certifications, skills, languages, etc.)

### 4. Company Selector (TODO)
Create `company_selector_widget.dart`:
- Search companies
- Show company logo if exists
- Fallback to icon if not found
- Create new company option

### 5. Connect Edit Profile Screen to Real Data (TODO)
- Load certifications, skills, languages, etc. from API
- Display real data in `edit_profile_screen.dart`
- Handle loading states
- Handle errors gracefully

## 📋 Database Migration Steps

1. Run the migration in Supabase SQL Editor:
   ```sql
   -- Copy contents of backend/scripts/advanced_profile_migration.sql
   -- Paste and run in Supabase SQL Editor
   ```

2. Verify tables created:
   ```sql
   SELECT table_name 
   FROM information_schema.tables 
   WHERE table_schema = 'public' 
     AND table_name IN (
       'companies', 'user_certifications', 'user_skills', 
       'user_languages', 'user_volunteering', 'user_publications',
       'user_interests', 'user_achievements'
     );
   ```

## 🎯 Next Steps Priority

1. **High Priority:**
   - Run database migration
   - Create Flutter models
   - Create Flutter service with API calls
   - Connect edit profile screen to real data

2. **Medium Priority:**
   - Create backend repositories
   - Create backend services
   - Create backend handlers
   - Implement company search

3. **Low Priority:**
   - Individual edit screens for each entity
   - Company logo upload
   - Advanced validation

## 🔒 Security Notes

- All endpoints require authentication (JWT middleware)
- RLS policies ensure users can only edit their own data
- Company creation is open to authenticated users (for shared company database)
- All validations on both frontend and backend
