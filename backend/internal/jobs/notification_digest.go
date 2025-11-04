package jobs

import (
	"context"
	"log"
	"time"

	"upvista-community-backend/internal/models"
	"upvista-community-backend/internal/notifications"
	"upvista-community-backend/internal/repository"
)

// NotificationDigestJob handles sending digest emails
type NotificationDigestJob struct {
	notificationRepo repository.NotificationRepository
	userRepo         repository.UserRepository
	emailSvc         *notifications.EmailService
}

// NewNotificationDigestJob creates a new digest job
func NewNotificationDigestJob(
	notificationRepo repository.NotificationRepository,
	userRepo repository.UserRepository,
	emailSvc *notifications.EmailService,
) *NotificationDigestJob {
	return &NotificationDigestJob{
		notificationRepo: notificationRepo,
		userRepo:         userRepo,
		emailSvc:         emailSvc,
	}
}

// RunDaily executes the daily digest job
func (j *NotificationDigestJob) RunDaily(ctx context.Context) error {
	log.Println("[DigestJob] Starting daily digest...")
	return j.sendDigests(ctx, models.EmailFrequencyDaily)
}

// RunWeekly executes the weekly digest job
func (j *NotificationDigestJob) RunWeekly(ctx context.Context) error {
	log.Println("[DigestJob] Starting weekly digest...")
	return j.sendDigests(ctx, models.EmailFrequencyWeekly)
}

// sendDigests sends digest emails to all users with the specified frequency
func (j *NotificationDigestJob) sendDigests(ctx context.Context, frequency models.EmailFrequency) error {
	// Get all users who want this frequency
	// For now, we'll fetch unread notifications and group by user
	// In a production system, you'd query the preferences table to get users with this frequency

	log.Printf("[DigestJob] Processing %s digests...", frequency)

	// This is a simplified implementation
	// In production, you'd:
	// 1. Query notification_preferences for users with this frequency
	// 2. For each user, get their unread notifications since last digest
	// 3. Send email with grouped notifications
	// 4. Mark digest as sent (add digest_sent_at to preferences or metadata)

	log.Printf("[DigestJob] %s digest processing complete (implementation simplified for MVP)", frequency)
	return nil
}

// StartDaily begins the daily digest job (runs at 9:00 AM daily)
func (j *NotificationDigestJob) StartDaily(ctx context.Context) {
	log.Println("[DigestJob] Daily digest job started (runs daily at 9:00 AM)")

	// Calculate time until next 9 AM
	now := time.Now()
	next9AM := time.Date(now.Year(), now.Month(), now.Day(), 9, 0, 0, 0, now.Location())
	if now.After(next9AM) {
		next9AM = next9AM.Add(24 * time.Hour)
	}

	// Wait until first run
	time.Sleep(time.Until(next9AM))

	// Run immediately
	if err := j.RunDaily(ctx); err != nil {
		log.Printf("[DigestJob] Daily initial run failed: %v", err)
	}

	// Then run every 24 hours
	ticker := time.NewTicker(24 * time.Hour)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			if err := j.RunDaily(ctx); err != nil {
				log.Printf("[DigestJob] Daily scheduled run failed: %v", err)
			}
		case <-ctx.Done():
			log.Println("[DigestJob] Daily digest job stopped")
			return
		}
	}
}

// StartWeekly begins the weekly digest job (runs Monday 9:00 AM)
func (j *NotificationDigestJob) StartWeekly(ctx context.Context) {
	log.Println("[DigestJob] Weekly digest job started (runs Monday at 9:00 AM)")

	// Calculate time until next Monday 9 AM
	now := time.Now()
	daysUntilMonday := (int(time.Monday) - int(now.Weekday()) + 7) % 7
	if daysUntilMonday == 0 && now.Hour() >= 9 {
		daysUntilMonday = 7 // Next Monday if already past 9 AM today
	}

	nextMonday9AM := time.Date(
		now.Year(), now.Month(), now.Day()+daysUntilMonday,
		9, 0, 0, 0, now.Location(),
	)

	// Wait until first run
	time.Sleep(time.Until(nextMonday9AM))

	// Run immediately
	if err := j.RunWeekly(ctx); err != nil {
		log.Printf("[DigestJob] Weekly initial run failed: %v", err)
	}

	// Then run every 7 days
	ticker := time.NewTicker(7 * 24 * time.Hour)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			if err := j.RunWeekly(ctx); err != nil {
				log.Printf("[DigestJob] Weekly scheduled run failed: %v", err)
			}
		case <-ctx.Done():
			log.Println("[DigestJob] Weekly digest job stopped")
			return
		}
	}
}
