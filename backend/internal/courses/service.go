package courses

import (
	"context"
	"fmt"
	"log"
	"strings"
	"time"

	"upvista-community-backend/internal/models"
	"upvista-community-backend/internal/repository"

	"github.com/google/uuid"
)

// Service handles course business logic
type Service struct {
	courseRepo repository.CourseRepository
	userRepo   repository.UserRepository
}

// NewService creates a new course service
func NewService(
	courseRepo repository.CourseRepository,
	userRepo repository.UserRepository,
) *Service {
	return &Service{
		courseRepo: courseRepo,
		userRepo:   userRepo,
	}
}

// CreateCourse creates a new course
func (s *Service) CreateCourse(ctx context.Context, req *models.CreateCourseRequest, creatorID uuid.UUID) (*models.Course, error) {
	// Generate slug from title
	slug := generateSlug(req.Title)

	// Ensure slug is unique
	baseSlug := slug
	counter := 1
	for {
		_, err := s.courseRepo.GetCourseBySlug(ctx, slug)
		if err != nil {
			// Slug doesn't exist, we can use it
			break
		}
		slug = fmt.Sprintf("%s-%d", baseSlug, counter)
		counter++
	}

	now := time.Now()
	course := &models.Course{
		ID:                uuid.New(),
		CreatorID:         creatorID,
		Title:             req.Title,
		Slug:              slug,
		Description:       req.Description,
		ShortDescription:  req.ShortDescription,
		Category:          req.Category,
		Subcategory:       req.Subcategory,
		Tags:              req.Tags,
		DifficultyLevel:   getDifficultyOrDefault(req.DifficultyLevel),
		Language:          getLanguageOrDefault(req.Language),
		IsFree:            req.IsFree,
		Price:             req.Price,
		Currency:          getCurrencyOrDefault(req.Currency),
		IsPublic:          req.IsPublic,
		RequiresApproval:  req.RequiresApproval,
		EstimatedDuration: req.EstimatedDuration,
		MetaTitle:         req.MetaTitle,
		MetaDescription:   req.MetaDescription,
		Status:            "draft",
		CreatedAt:         now,
		LastUpdatedAt:     now,
	}

	if err := s.courseRepo.CreateCourse(ctx, course); err != nil {
		return nil, fmt.Errorf("failed to create course: %w", err)
	}

	return course, nil
}

// GetCourse retrieves a course by ID
func (s *Service) GetCourse(ctx context.Context, courseID uuid.UUID, userID *uuid.UUID) (*models.Course, error) {
	course, err := s.courseRepo.GetCourseByID(ctx, courseID)
	if err != nil {
		return nil, err
	}

	// Increment view count
	go func() {
		if err := s.courseRepo.IncrementViewCount(context.Background(), courseID); err != nil {
			log.Printf("[Courses] Failed to increment view count: %v", err)
		}
	}()

	// Check if user is enrolled
	if userID != nil {
		enrollment, _ := s.courseRepo.GetEnrollment(ctx, courseID, *userID)
		if enrollment != nil {
			course.IsEnrolled = true
			course.Enrollment = enrollment
		}

		// Check if user is collaborator
		collab, _ := s.courseRepo.GetCollaborator(ctx, courseID, *userID)
		if collab != nil && collab.Status == "accepted" {
			course.IsCollaborator = true
			collabRole := collab.Role
			course.CollaboratorRole = &collabRole
		}
	}

	return course, nil
}

// ListCourses lists courses with filters
func (s *Service) ListCourses(ctx context.Context, filter *models.CourseFilter, userID *uuid.UUID) ([]*models.Course, error) {
	if filter == nil {
		filter = &models.CourseFilter{
			SortBy: "popular",
			Limit:  20,
			Offset: 0,
		}
	}

	if filter.Limit == 0 {
		filter.Limit = 20
	}

	return s.courseRepo.ListCourses(ctx, filter, userID)
}

// EnrollInCourse enrolls a user in a course
func (s *Service) EnrollInCourse(ctx context.Context, courseID, userID uuid.UUID) (*models.CourseEnrollment, error) {
	// Check if already enrolled
	existing, _ := s.courseRepo.GetEnrollment(ctx, courseID, userID)
	if existing != nil {
		return existing, nil
	}

	// Get course to check pricing
	course, err := s.courseRepo.GetCourseByID(ctx, courseID)
	if err != nil {
		return nil, fmt.Errorf("course not found: %w", err)
	}

	// Check if course is published
	if course.Status != "published" {
		return nil, fmt.Errorf("course is not available for enrollment")
	}

	// Determine payment status
	paymentStatus := "free"
	if !course.IsFree {
		paymentStatus = "pending" // Payment integration would be handled here
	}

	enrollment := &models.CourseEnrollment{
		ID:                 uuid.New(),
		CourseID:           courseID,
		UserID:             userID,
		EnrolledAt:         time.Now(),
		ProgressPercentage: 0,
		PaymentStatus:      paymentStatus,
	}

	if !course.IsFree && course.Price != nil {
		enrollment.PaymentAmount = course.Price
		enrollment.PaymentCurrency = &course.Currency
	}

	if err := s.courseRepo.CreateEnrollment(ctx, enrollment); err != nil {
		return nil, fmt.Errorf("failed to enroll: %w", err)
	}

	return enrollment, nil
}

// Helper functions
func generateSlug(title string) string {
	slug := strings.ToLower(title)
	slug = strings.ReplaceAll(slug, " ", "-")
	slug = strings.ReplaceAll(slug, "_", "-")
	var result strings.Builder
	for _, char := range slug {
		if (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') || char == '-' {
			result.WriteRune(char)
		}
	}
	return result.String()
}

func getDifficultyOrDefault(level string) string {
	valid := map[string]bool{
		"beginner":     true,
		"intermediate": true,
		"advanced":     true,
		"expert":       true,
	}
	if valid[level] {
		return level
	}
	return "beginner"
}

func getLanguageOrDefault(lang string) string {
	if lang == "" {
		return "en"
	}
	return lang
}

func getCurrencyOrDefault(currency string) string {
	if currency == "" {
		return "USD"
	}
	return currency
}
