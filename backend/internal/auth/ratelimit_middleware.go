package auth

import (
	"net/http"
	"strconv"
	"time"

	"upvista-community-backend/internal/utils"

	"github.com/gin-gonic/gin"
)

// RateLimitMiddleware creates a middleware that enforces rate limiting per IP address
// with forgiveness mechanism for legitimate errors
func RateLimitMiddleware(limit int, window time.Duration, rateLimiter *utils.RateLimiter) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Extract IP address from request
		forwardedFor := c.GetHeader("X-Forwarded-For")
		remoteAddr := c.RemoteIP()
		ip := utils.ExtractIP(remoteAddr, forwardedFor)

		// Check if request is allowed
		allowed, remaining, resetTime := rateLimiter.Allow(ip, limit, window)

		// Set rate limit headers (RFC 6585)
		c.Header("X-RateLimit-Limit", strconv.Itoa(limit))
		c.Header("X-RateLimit-Remaining", strconv.Itoa(remaining))
		c.Header("X-RateLimit-Reset", strconv.FormatInt(resetTime.Unix(), 10))

		if !allowed {
			// Calculate retry-after in seconds
			retryAfter := int(time.Until(resetTime).Seconds())
			if retryAfter < 0 {
				retryAfter = 0
			}

			c.Header("Retry-After", strconv.Itoa(retryAfter))
			c.JSON(http.StatusTooManyRequests, gin.H{
				"success":     false,
				"message":     "Too many requests. Please try again later.",
				"error":       "Rate limit exceeded",
				"retry_after": retryAfter,
			})
			c.Abort()
			return
		}

		// Request allowed, continue
		c.Next()
	}
}
