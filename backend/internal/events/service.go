package events

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"log"
	"time"

	"upvista-community-backend/internal/models"
	"upvista-community-backend/internal/repository"
	"upvista-community-backend/internal/utils"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

// Service handles event business logic
type Service struct {
	eventRepo repository.EventRepository
	userRepo  repository.UserRepository
	emailSvc  *utils.EmailService
}

// NewService creates a new event service
func NewService(
	eventRepo repository.EventRepository,
	userRepo repository.UserRepository,
	emailSvc *utils.EmailService,
) *Service {
	return &Service{
		eventRepo: eventRepo,
		userRepo:  userRepo,
		emailSvc:  emailSvc,
	}
}

// ============================================
// EVENT CREATION & APPROVAL
// ============================================

// CreateEvent creates a new event and handles approval workflow
func (s *Service) CreateEvent(ctx context.Context, req *models.CreateEventRequest, creatorID uuid.UUID) (*models.Event, error) {
	// Validate request
	if err := s.validateCreateEventRequest(req); err != nil {
		return nil, err
	}

	// Determine if approval is required based on event properties
	// Auto-approved: Free + Online + Public
	// Requires approval: Paid OR Private OR Physical OR Hybrid
	requiresApproval := false
	if !req.IsFree || !req.IsPublic || req.LocationType == "physical" || req.LocationType == "hybrid" {
		requiresApproval = true
	}

	log.Printf("[Events] Approval required: %v (IsFree: %v, IsPublic: %v, LocationType: %s)",
		requiresApproval, req.IsFree, req.IsPublic, req.LocationType)

	// Hash password if provided
	var passwordHash *string
	if req.Password != nil && *req.Password != "" {
		hashed, err := bcrypt.GenerateFromPassword([]byte(*req.Password), bcrypt.DefaultCost)
		if err != nil {
			return nil, fmt.Errorf("failed to hash password: %w", err)
		}
		hashedStr := string(hashed)
		passwordHash = &hashedStr
	}

	// Determine status
	status := "draft"
	if requiresApproval {
		status = "pending"
	} else {
		status = "approved"
	}

	now := time.Now()
	event := &models.Event{
		ID:            uuid.New(),
		CreatorID:     creatorID,
		Title:         req.Title,
		Description:   req.Description,
		CoverImageURL: req.CoverImageURL,
		StartDate:     req.StartDate.Time,
		EndDate: func() *time.Time {
			if req.EndDate == nil {
				return nil
			}
			t := req.EndDate.Time
			return &t
		}(),
		Timezone:        getTimezoneOrDefault(req.Timezone),
		IsAllDay:        req.IsAllDay,
		LocationType:    req.LocationType,
		LocationName:    req.LocationName,
		LocationAddress: req.LocationAddress,
		OnlinePlatform:  req.OnlinePlatform,
		OnlineLink:      req.OnlineLink,
		Latitude:        req.Latitude,
		Longitude:       req.Longitude,
		Category:        req.Category,
		Tags:            req.Tags,
		MaxAttendees:    req.MaxAttendees,
		IsPublic:        req.IsPublic,
		PasswordHash:    passwordHash,
		IsFree:          req.IsFree,
		Price:           req.Price,
		Currency:        getCurrencyOrDefault(req.Currency),
		Status:          status,
		AutoApproved:    !requiresApproval,
		CreatedAt:       now,
		UpdatedAt:       now,
	}

	// Create event FIRST (approval request needs event to exist due to foreign key)
	log.Printf("[Events] Attempting to create event in database: ID=%s, Title=%s", event.ID, event.Title)
	if err := s.eventRepo.CreateEvent(ctx, event); err != nil {
		log.Printf("[Events] Failed to create event in database: %v", err)
		return nil, fmt.Errorf("failed to create event: %w", err)
	}
	log.Printf("[Events] Event created successfully: ID=%s", event.ID)

	// If approval required, create approval request AFTER event is created
	if requiresApproval {
		approvalToken, err := generateApprovalToken()
		if err != nil {
			return nil, fmt.Errorf("failed to generate approval token: %w", err)
		}

		// Update event with approval token and requested timestamp
		event.ApprovalToken = &approvalToken
		event.ApprovalRequestedAt = &now
		if err := s.eventRepo.UpdateEvent(ctx, event); err != nil {
			log.Printf("Warning: failed to update event with approval token: %v", err)
		}

		// Create approval request (now that event exists)
		approvalRequest := &models.EventApprovalRequest{
			ID:             uuid.New(),
			EventID:        event.ID,
			CreatorID:      creatorID,
			ApprovalToken:  approvalToken,
			TokenExpiresAt: now.Add(7 * 24 * time.Hour), // 7 days
			RequestReason:  stringPtr(fmt.Sprintf("Event creation: %s", event.Title)),
			Category:       req.Category,
			IsPrivate:      !req.IsPublic,
			Status:         "pending",
			RequestedAt:    now,
		}

		if err := s.eventRepo.CreateApprovalRequest(ctx, approvalRequest); err != nil {
			log.Printf("Warning: failed to create approval request: %v", err)
			// Don't fail the entire operation if approval request creation fails
		} else {
			// Send approval email to admin
			if err := s.sendApprovalRequestEmail(ctx, event, approvalRequest); err != nil {
				log.Printf("Warning: failed to send approval email: %v", err)
			}
		}
	} else {
		// Auto-approved - update event status
		event.ApprovedAt = &now
		event.Status = "approved"
		if err := s.eventRepo.UpdateEvent(ctx, event); err != nil {
			log.Printf("Warning: failed to update event status to approved: %v", err)
		}
	}

	return event, nil
}

// ApproveEvent approves an event using approval token
func (s *Service) ApproveEvent(ctx context.Context, token string, adminID uuid.UUID, req *models.ApproveEventRequest) error {
	// Get approval request
	approvalRequest, err := s.eventRepo.GetApprovalRequestByToken(ctx, token)
	if err != nil {
		return fmt.Errorf("approval request not found: %w", err)
	}

	// Check if token is expired
	if time.Now().After(approvalRequest.TokenExpiresAt) {
		approvalRequest.Status = "expired"
		s.eventRepo.UpdateApprovalRequest(ctx, approvalRequest)
		return fmt.Errorf("approval token has expired")
	}

	// Get event
	event, err := s.eventRepo.GetEventByID(ctx, approvalRequest.EventID, nil)
	if err != nil {
		return fmt.Errorf("event not found: %w", err)
	}

	// Update approval request
	now := time.Now()
	approvalRequest.Status = req.Status
	approvalRequest.ReviewedBy = &adminID
	approvalRequest.ReviewedAt = &now
	approvalRequest.AdminNotes = req.AdminNotes

	if err := s.eventRepo.UpdateApprovalRequest(ctx, approvalRequest); err != nil {
		return fmt.Errorf("failed to update approval request: %w", err)
	}

	// Update event status
	if req.Status == "approved" {
		event.Status = "approved"
		event.ApprovedAt = &now
		event.ApprovedBy = &adminID
	} else {
		event.Status = "rejected"
		event.RejectionReason = req.RejectionReason
	}

	if err := s.eventRepo.UpdateEvent(ctx, event); err != nil {
		return fmt.Errorf("failed to update event: %w", err)
	}

	// Send notification email to creator
	statusPtr := &req.Status
	if err := s.sendApprovalDecisionEmail(ctx, event, statusPtr, req.RejectionReason); err != nil {
		log.Printf("Warning: failed to send approval decision email: %v", err)
	}

	return nil
}

// ============================================
// EVENT APPLICATION & TICKET GENERATION
// ============================================

// ApplyToEvent handles event application with ticket generation
func (s *Service) ApplyToEvent(ctx context.Context, eventID uuid.UUID, userID uuid.UUID, req *models.ApplyToEventRequest) (*models.EventApplication, error) {
	// Get event
	event, err := s.eventRepo.GetEventByID(ctx, eventID, &userID)
	if err != nil {
		return nil, fmt.Errorf("event not found: %w", err)
	}

	// Check if event is approved
	if event.Status != "approved" {
		return nil, fmt.Errorf("event is not available for applications")
	}

	// Check if event has started
	if time.Now().After(event.StartDate) {
		return nil, fmt.Errorf("event has already started")
	}

	// Check if user already applied
	existingApp, _ := s.eventRepo.GetApplicationByEventAndUser(ctx, eventID, userID)
	if existingApp != nil {
		return nil, fmt.Errorf("you have already applied to this event")
	}

	// Check if event is full
	if event.MaxAttendees != nil {
		stats, _ := s.eventRepo.GetEventStats(ctx, eventID)
		if stats != nil && stats.ApprovedApplications >= *event.MaxAttendees {
			return nil, fmt.Errorf("event is full")
		}
	}

	// Verify password for private events
	if !event.IsPublic && event.PasswordHash != nil {
		if req.Password == nil {
			return nil, fmt.Errorf("password required for private event")
		}
		if err := bcrypt.CompareHashAndPassword([]byte(*event.PasswordHash), []byte(*req.Password)); err != nil {
			return nil, fmt.Errorf("invalid password")
		}
	}

	// Get user for auto-fill
	var fullName, email, phone, organization *string
	if req.UseProfileData {
		user, err := s.userRepo.GetUserByID(ctx, userID)
		if err == nil {
			fullName = &user.DisplayName
			email = &user.Email
			// Note: phone and organization would need to be added to user model
		}
	}

	// Use provided data or fallback to profile data
	if req.FullName != nil {
		fullName = req.FullName
	}
	if req.Email != nil {
		email = req.Email
	}
	if req.Phone != nil {
		phone = req.Phone
	}
	if req.Organization != nil {
		organization = req.Organization
	}

	// Generate ticket
	ticketToken, err := generateTicketToken()
	if err != nil {
		return nil, fmt.Errorf("failed to generate ticket token: %w", err)
	}

	ticketNumber := generateTicketNumber()

	// Create application
	now := time.Now()
	application := &models.EventApplication{
		ID:                uuid.New(),
		EventID:           eventID,
		UserID:            userID,
		Status:            "approved", // Auto-approve for now, can be changed to pending if needed
		FullName:          fullName,
		Email:             email,
		Phone:             phone,
		Organization:      organization,
		AdditionalInfo:    req.AdditionalInfo,
		TicketToken:       ticketToken,
		TicketNumber:      ticketNumber,
		TicketGeneratedAt: now,
		PaymentStatus:     "not_required",
		AppliedAt:         now,
	}

	if !event.IsFree && event.Price != nil {
		application.PaymentStatus = "pending"
		application.PaymentAmount = event.Price
		// Payment integration would go here
	}

	// Auto-approve if event doesn't require approval
	application.Status = "approved"
	application.ApprovedAt = &now

	if err := s.eventRepo.CreateApplication(ctx, application); err != nil {
		return nil, fmt.Errorf("failed to create application: %w", err)
	}

	// Send ticket email
	if email != nil {
		if err := s.sendTicketEmail(ctx, event, application, *email); err != nil {
			log.Printf("Warning: failed to send ticket email: %v", err)
		}
	}

	return application, nil
}

// ============================================
// HELPER FUNCTIONS
// ============================================

func (s *Service) validateCreateEventRequest(req *models.CreateEventRequest) error {
	if req.Title == "" {
		return fmt.Errorf("title is required")
	}
	if req.StartDate.Time.IsZero() {
		return fmt.Errorf("start date is required")
	}
	if req.StartDate.Time.Before(time.Now()) {
		return fmt.Errorf("start date must be in the future")
	}
	if req.EndDate != nil && req.EndDate.Time.Before(req.StartDate.Time) {
		return fmt.Errorf("end date must be after start date")
	}
	if req.LocationType == "" {
		return fmt.Errorf("location type is required")
	}
	if req.LocationType == "online" || req.LocationType == "hybrid" {
		if req.OnlineLink == nil || *req.OnlineLink == "" {
			return fmt.Errorf("online link is required for online/hybrid events")
		}
	}
	if !req.IsFree && req.Price == nil {
		return fmt.Errorf("price is required for paid events")
	}
	return nil
}

func generateApprovalToken() (string, error) {
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}

func generateTicketToken() (string, error) {
	bytes := make([]byte, 24)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}

func generateTicketNumber() string {
	year := time.Now().Year()
	random := uuid.New().String()[:8]
	return fmt.Sprintf("EVT-%d-%s", year, random)
}

func getCategoryOrDefault(category *string) string {
	if category != nil {
		return *category
	}
	return "other"
}

func getTimezoneOrDefault(timezone string) string {
	if timezone == "" {
		return "UTC"
	}
	return timezone
}

func getCurrencyOrDefault(currency string) string {
	if currency == "" {
		return "USD"
	}
	return currency
}

func stringPtr(s string) *string {
	return &s
}

// ============================================
// EMAIL NOTIFICATIONS
// ============================================

func (s *Service) sendApprovalRequestEmail(ctx context.Context, event *models.Event, request *models.EventApprovalRequest) error {
	// Get creator
	creator, err := s.userRepo.GetUserByID(ctx, event.CreatorID)
	if err != nil {
		return err
	}

	// Email to admin
	adminEmail := "hamza@upvistadigital.com"

	// Format event details
	locationInfo := "Online"
	if event.LocationType == "physical" {
		locationInfo = fmt.Sprintf("Physical: %s", getStringValue(event.LocationName))
		if event.LocationAddress != nil {
			locationInfo += fmt.Sprintf(" - %s", *event.LocationAddress)
		}
	} else if event.LocationType == "hybrid" {
		locationInfo = fmt.Sprintf("Hybrid: %s", getStringValue(event.LocationName))
		if event.OnlineLink != nil {
			locationInfo += fmt.Sprintf(" | Online: %s", *event.OnlineLink)
		}
	} else if event.OnlineLink != nil {
		locationInfo = fmt.Sprintf("Online: %s", *event.OnlineLink)
	}

	pricingInfo := "Free"
	if !event.IsFree && event.Price != nil {
		pricingInfo = fmt.Sprintf("%s %.2f", event.Currency, *event.Price)
	}

	subject := fmt.Sprintf("Event Approval Request: %s", event.Title)
	body := fmt.Sprintf(`
		<h2>Event Approval Request</h2>
		<p>An event approval request has been submitted and requires your review.</p>
		
		<h3>Event Details</h3>
		<p><strong>Event ID:</strong> %s</p>
		<p><strong>Title:</strong> %s</p>
		<p><strong>Description:</strong> %s</p>
		<p><strong>Category:</strong> %s</p>
		<p><strong>Type:</strong> %s</p>
		<p><strong>Pricing:</strong> %s</p>
		
		<h3>Date & Time</h3>
		<p><strong>Start Date:</strong> %s</p>
		%s
		<p><strong>Timezone:</strong> %s</p>
		<p><strong>All Day:</strong> %s</p>
		
		<h3>Location</h3>
		<p>%s</p>
		
		<h3>Creator Information</h3>
		<p><strong>Name:</strong> %s</p>
		<p><strong>Email:</strong> %s</p>
		<p><strong>Username:</strong> %s</p>
		
		<h3>Approval Instructions</h3>
		<p>To approve this event, go to Supabase and update the event status:</p>
		<ol>
			<li>Open Supabase Dashboard</li>
			<li>Navigate to the <code>events</code> table</li>
			<li>Find event with ID: <code>%s</code></li>
			<li>Change <code>status</code> from <code>pending</code> to <code>approved</code></li>
		</ol>
		
		<p><strong>Event ID:</strong> <code>%s</code></p>
		<p><strong>Approval Token:</strong> <code>%s</code></p>
	`,
		event.ID.String(),
		event.Title,
		getStringValue(event.Description),
		getCategoryOrDefault(event.Category),
		map[bool]string{true: "Private", false: "Public"}[!event.IsPublic],
		pricingInfo,
		event.StartDate.Format("January 2, 2006 3:04 PM"),
		func() string {
			if event.EndDate != nil {
				return fmt.Sprintf("<p><strong>End Date:</strong> %s</p>", event.EndDate.Format("January 2, 2006 3:04 PM"))
			}
			return ""
		}(),
		event.Timezone,
		map[bool]string{true: "Yes", false: "No"}[event.IsAllDay],
		locationInfo,
		creator.DisplayName,
		creator.Email,
		creator.Username,
		event.ID.String(),
		event.ID.String(),
		request.ApprovalToken,
	)

	// Send email to admin
	if err := s.emailSvc.SendEmail(adminEmail, subject, body, ""); err != nil {
		return err
	}

	// Also send confirmation email to creator
	creatorSubject := fmt.Sprintf("Event Submitted: %s", event.Title)
	creatorBody := fmt.Sprintf(`
		<h2>Event Submitted Successfully</h2>
		<p>Your event "<strong>%s</strong>" has been submitted and is pending approval.</p>
		
		<h3>Event Details</h3>
		<p><strong>Event ID:</strong> %s</p>
		<p><strong>Title:</strong> %s</p>
		<p><strong>Start Date:</strong> %s</p>
		<p><strong>Status:</strong> Pending Approval</p>
		
		<p>You will receive an email notification once your event has been reviewed and approved.</p>
	`,
		event.Title,
		event.ID.String(),
		event.Title,
		event.StartDate.Format("January 2, 2006 3:04 PM"),
	)

	// Send confirmation to creator
	return s.emailSvc.SendEmail(creator.Email, creatorSubject, creatorBody, "")
}

// Helper function to safely get string value
func getStringValue(s *string) string {
	if s == nil {
		return "Not provided"
	}
	return *s
}

func (s *Service) sendApprovalDecisionEmail(ctx context.Context, event *models.Event, status, rejectionReason *string) error {
	creator, err := s.userRepo.GetUserByID(ctx, event.CreatorID)
	if err != nil {
		return err
	}

	statusStr := "processed"
	if status != nil {
		statusStr = *status
	}

	subject := fmt.Sprintf("Event %s: %s", statusStr, event.Title)
	body := fmt.Sprintf(`
		<p>Your event "<strong>%s</strong>" has been %s.</p>
	`,
		event.Title,
		statusStr,
	)

	if status != nil && *status == "rejected" && rejectionReason != nil {
		body += fmt.Sprintf(`<p><strong>Reason:</strong> %s</p>`, *rejectionReason)
	}

	return s.emailSvc.SendEmail(creator.Email, subject, body, "")
}

func (s *Service) sendTicketEmail(ctx context.Context, event *models.Event, application *models.EventApplication, email string) error {
	subject := fmt.Sprintf("Your Ticket for: %s", event.Title)
	body := fmt.Sprintf(`
		<h2>Your Event Ticket</h2>
		<p><strong>Event:</strong> %s</p>
		<p><strong>Date:</strong> %s</p>
		<p><strong>Ticket Number:</strong> %s</p>
		<p><strong>Ticket Token:</strong> %s</p>
		<p>Please save this ticket for entry to the event.</p>
	`,
		event.Title,
		event.StartDate.Format("January 2, 2006 3:04 PM"),
		application.TicketNumber,
		application.TicketToken,
	)

	return s.emailSvc.SendEmail(email, subject, body, "")
}

// ============================================
// ADDITIONAL SERVICE METHODS
// ============================================

// GetEvent retrieves an event by ID
func (s *Service) GetEvent(ctx context.Context, eventID uuid.UUID, userID *uuid.UUID) (*models.Event, error) {
	return s.eventRepo.GetEventByID(ctx, eventID, userID)
}

// ListEvents lists events with filters
func (s *Service) ListEvents(ctx context.Context, filter *models.EventFilter, userID *uuid.UUID) ([]*models.Event, error) {
	return s.eventRepo.ListEvents(ctx, filter, userID)
}

// UpdateEvent updates an event
func (s *Service) UpdateEvent(ctx context.Context, eventID uuid.UUID, userID uuid.UUID, req *models.CreateEventRequest) (*models.Event, error) {
	// Get existing event
	event, err := s.eventRepo.GetEventByID(ctx, eventID, &userID)
	if err != nil {
		return nil, err
	}

	// Check ownership
	if event.CreatorID != userID {
		return nil, fmt.Errorf("unauthorized: you can only update your own events")
	}

	// Update fields
	event.Title = req.Title
	event.Description = req.Description
	event.CoverImageURL = req.CoverImageURL
	event.StartDate = req.StartDate.Time
	if req.EndDate != nil {
		event.EndDate = &req.EndDate.Time
	} else {
		event.EndDate = nil
	}
	event.Timezone = getTimezoneOrDefault(req.Timezone)
	event.IsAllDay = req.IsAllDay
	event.LocationType = req.LocationType
	event.LocationName = req.LocationName
	event.LocationAddress = req.LocationAddress
	event.OnlinePlatform = req.OnlinePlatform
	event.OnlineLink = req.OnlineLink
	event.Latitude = req.Latitude
	event.Longitude = req.Longitude
	event.Category = req.Category
	event.Tags = req.Tags
	event.MaxAttendees = req.MaxAttendees
	event.IsPublic = req.IsPublic
	event.IsFree = req.IsFree
	event.Price = req.Price
	event.Currency = getCurrencyOrDefault(req.Currency)
	event.UpdatedAt = time.Now()

	// Hash password if provided
	if req.Password != nil && *req.Password != "" {
		hashed, err := bcrypt.GenerateFromPassword([]byte(*req.Password), bcrypt.DefaultCost)
		if err != nil {
			return nil, fmt.Errorf("failed to hash password: %w", err)
		}
		hashedStr := string(hashed)
		event.PasswordHash = &hashedStr
	}

	if err := s.eventRepo.UpdateEvent(ctx, event); err != nil {
		return nil, fmt.Errorf("failed to update event: %w", err)
	}

	return event, nil
}

// DeleteEvent deletes an event
func (s *Service) DeleteEvent(ctx context.Context, eventID uuid.UUID, userID uuid.UUID) error {
	// Get existing event
	event, err := s.eventRepo.GetEventByID(ctx, eventID, &userID)
	if err != nil {
		return err
	}

	// Check ownership
	if event.CreatorID != userID {
		return fmt.Errorf("unauthorized: you can only delete your own events")
	}

	return s.eventRepo.DeleteEvent(ctx, eventID)
}

// GetApplication gets user's application to an event
func (s *Service) GetApplication(ctx context.Context, eventID uuid.UUID, userID uuid.UUID) (*models.EventApplication, error) {
	return s.eventRepo.GetApplicationByEventAndUser(ctx, eventID, userID)
}

// GetTicket gets user's ticket for an event
func (s *Service) GetTicket(ctx context.Context, eventID uuid.UUID, userID uuid.UUID) (*models.EventApplication, error) {
	application, err := s.eventRepo.GetApplicationByEventAndUser(ctx, eventID, userID)
	if err != nil {
		return nil, err
	}

	// Load event details
	event, err := s.eventRepo.GetEventByID(ctx, eventID, &userID)
	if err != nil {
		return nil, err
	}
	application.Event = event

	return application, nil
}

// GetPendingApprovals gets pending approval requests
func (s *Service) GetPendingApprovals(ctx context.Context, limit, offset int) ([]*models.EventApprovalRequest, error) {
	return s.eventRepo.GetPendingApprovalRequests(ctx, limit, offset)
}

// GetCategories gets all event categories
func (s *Service) GetCategories(ctx context.Context) ([]*models.EventCategory, error) {
	return s.eventRepo.GetAllCategories(ctx)
}

// IncrementEventViews increments event views count
func (s *Service) IncrementEventViews(ctx context.Context, eventID uuid.UUID) error {
	return s.eventRepo.IncrementEventViews(ctx, eventID)
}
