package jobs

import (
	"context"
	"log"
	"time"

	"upvista-community-backend/internal/repository"
)

// NotificationCleanupJob handles automatic deletion of expired notifications
type NotificationCleanupJob struct {
	repo repository.NotificationRepository
}

// NewNotificationCleanupJob creates a new cleanup job
func NewNotificationCleanupJob(repo repository.NotificationRepository) *NotificationCleanupJob {
	return &NotificationCleanupJob{
		repo: repo,
	}
}

// Run executes the cleanup job
func (j *NotificationCleanupJob) Run(ctx context.Context) error {
	log.Println("[CleanupJob] Starting notification cleanup...")

	count, err := j.repo.DeleteExpired(ctx)
	if err != nil {
		log.Printf("[CleanupJob] Cleanup failed: %v", err)
		return err
	}

	if count > 0 {
		log.Printf("[CleanupJob] Cleanup complete: deleted %d expired notifications", count)
	} else {
		log.Println("[CleanupJob] Cleanup complete: no expired notifications found")
	}

	return nil
}

// Start begins the cleanup job on a schedule (runs daily at 2 AM)
func (j *NotificationCleanupJob) Start(ctx context.Context) {
	log.Println("[CleanupJob] Cleanup job started (runs daily at 2:00 AM)")

	// Calculate time until next 2 AM
	now := time.Now()
	next2AM := time.Date(now.Year(), now.Month(), now.Day(), 2, 0, 0, 0, now.Location())
	if now.After(next2AM) {
		next2AM = next2AM.Add(24 * time.Hour)
	}

	// Wait until first run
	time.Sleep(time.Until(next2AM))

	// Run immediately
	if err := j.Run(ctx); err != nil {
		log.Printf("[CleanupJob] Initial run failed: %v", err)
	}

	// Then run every 24 hours
	ticker := time.NewTicker(24 * time.Hour)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			if err := j.Run(ctx); err != nil {
				log.Printf("[CleanupJob] Scheduled run failed: %v", err)
			}
		case <-ctx.Done():
			log.Println("[CleanupJob] Cleanup job stopped")
			return
		}
	}
}
