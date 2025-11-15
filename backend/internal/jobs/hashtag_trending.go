package jobs

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"time"
)

// HashtagTrendingJob updates hashtag trending scores daily
type HashtagTrendingJob struct {
	supabaseURL string
	serviceKey  string
}

// NewHashtagTrendingJob creates a new hashtag trending job
func NewHashtagTrendingJob(supabaseURL, serviceKey string) *HashtagTrendingJob {
	return &HashtagTrendingJob{
		supabaseURL: supabaseURL,
		serviceKey:  serviceKey,
	}
}

// Start runs the job daily at 3:00 AM
func (j *HashtagTrendingJob) Start(ctx context.Context) {
	log.Println("[HashtagTrending] Starting daily hashtag trending score calculation job (3:00 AM)")

	// Run immediately on startup
	j.calculateTrendingScores()

	// Then run daily
	ticker := time.NewTicker(24 * time.Hour)
	defer ticker.Stop()

	// Calculate time until next 3:00 AM
	now := time.Now()
	next3AM := time.Date(now.Year(), now.Month(), now.Day(), 3, 0, 0, 0, now.Location())
	if now.After(next3AM) {
		next3AM = next3AM.Add(24 * time.Hour)
	}

	// Wait until 3:00 AM
	timer := time.NewTimer(time.Until(next3AM))
	defer timer.Stop()

	for {
		select {
		case <-timer.C:
			j.calculateTrendingScores()
			timer.Reset(24 * time.Hour)

		case <-ticker.C:
			// Fallback ticker (in case timer fails)
			if time.Now().Hour() == 3 {
				j.calculateTrendingScores()
			}

		case <-ctx.Done():
			log.Println("[HashtagTrending] Stopping job")
			return
		}
	}
}

// calculateTrendingScores calls the PostgreSQL function to update trending scores
func (j *HashtagTrendingJob) calculateTrendingScores() {
	log.Println("[HashtagTrending] Calculating trending scores...")

	// Call via Supabase RPC
	url := fmt.Sprintf("%s/rest/v1/rpc/calculate_hashtag_trending_scores", j.supabaseURL)

	req, err := http.NewRequest("POST", url, nil)
	if err != nil {
		log.Printf("[HashtagTrending] Failed to create request: %v", err)
		return
	}

	req.Header.Set("apikey", j.serviceKey)
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", j.serviceKey))
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		log.Printf("[HashtagTrending] Failed to call function: %v", err)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		log.Printf("[HashtagTrending] Function call failed with status %d", resp.StatusCode)
		return
	}

	log.Println("[HashtagTrending] Trending scores updated successfully")
}
