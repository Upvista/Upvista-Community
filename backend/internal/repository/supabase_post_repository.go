package repository

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"regexp"
	"strings"
	"sync"
	"time"

	"upvista-community-backend/internal/models"

	"github.com/google/uuid"
)

// SupabasePostRepository implements PostRepository using Supabase REST API
type SupabasePostRepository struct {
	supabaseURL string
	serviceKey  string
	client      *http.Client
}

// NewSupabasePostRepository creates a new Supabase post repository
func NewSupabasePostRepository(supabaseURL, serviceKey string) *SupabasePostRepository {
	return &SupabasePostRepository{
		supabaseURL: supabaseURL,
		serviceKey:  serviceKey,
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// Helper to make Supabase requests
func (r *SupabasePostRepository) makeRequest(method, table, query string, body interface{}) ([]byte, error) {
	url := fmt.Sprintf("%s/rest/v1/%s%s", r.supabaseURL, table, query)

	var reqBody io.Reader
	if body != nil {
		jsonData, err := json.Marshal(body)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal request body: %w", err)
		}
		reqBody = bytes.NewBuffer(jsonData)
	}

	req, err := http.NewRequest(method, url, reqBody)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("apikey", r.serviceKey)
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", r.serviceKey))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Prefer", "return=representation")

	resp, err := r.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("supabase error (status %d): %s", resp.StatusCode, string(data))
	}

	return data, nil
}

// CreatePost creates a new post
func (r *SupabasePostRepository) CreatePost(ctx context.Context, post *models.Post) error {
	// Set defaults
	if post.ID == uuid.Nil {
		post.ID = uuid.New()
	}
	if post.PublishedAt == nil && post.IsPublished {
		now := time.Now()
		post.PublishedAt = &now
	}

	payload := map[string]interface{}{
		"id":              post.ID,
		"user_id":         post.UserID,
		"post_type":       post.PostType,
		"content":         post.Content,
		"media_urls":      post.MediaURLs,
		"media_types":     post.MediaTypes,
		"visibility":      post.Visibility,
		"allows_comments": post.AllowsComments,
		"allows_sharing":  post.AllowsSharing,
		"is_published":    post.IsPublished,
		"is_draft":        post.IsDraft,
		"is_nsfw":         post.IsNSFW,
		"published_at":    post.PublishedAt,
	}

	data, err := r.makeRequest("POST", "posts", "", payload)
	if err != nil {
		return fmt.Errorf("failed to create post: %w", err)
	}

	// Unmarshal with custom timestamp handling
	var created []map[string]interface{}
	if err := json.Unmarshal(data, &created); err != nil {
		return fmt.Errorf("failed to unmarshal created post: %w", err)
	}

	if len(created) > 0 {
		// Manually parse the post to handle timestamp formats
		postData := created[0]

		// Parse timestamps that might not have timezone
		// Supabase returns timestamps without timezone, we'll treat them as UTC
		parseTime := func(val interface{}) *time.Time {
			if val == nil {
				return nil
			}
			str, ok := val.(string)
			if !ok {
				return nil
			}

			// Try RFC3339 first (with timezone)
			if t, err := time.Parse(time.RFC3339, str); err == nil {
				return &t
			}
			// Try RFC3339Nano (with nanoseconds and timezone)
			if t, err := time.Parse(time.RFC3339Nano, str); err == nil {
				return &t
			}

			// Handle Supabase format without timezone: 2025-11-15T00:00:45.060234
			// Parse as UTC since Supabase stores timestamps in UTC
			utc, _ := time.LoadLocation("UTC")

			// If no timezone, parse directly as UTC
			if !strings.Contains(str, "Z") && !strings.Contains(str, "+") && len(str) > 10 {
				// Check if it has fractional seconds
				parts := strings.Split(str, ".")
				if len(parts) == 2 {
					// Has fractional seconds: 2025-11-15T00:00:45.060234
					// Normalize to 6 digits for parsing
					fractional := parts[1]
					if len(fractional) > 6 {
						fractional = fractional[:6]
					} else if len(fractional) < 6 {
						fractional = fractional + strings.Repeat("0", 6-len(fractional))
					}
					normalized := parts[0] + "." + fractional
					if t, err := time.ParseInLocation("2006-01-02T15:04:05.999999", normalized, utc); err == nil {
						return &t
					}
				} else {
					// No fractional seconds: 2025-11-15T00:00:45
					if t, err := time.ParseInLocation("2006-01-02T15:04:05", str, utc); err == nil {
						return &t
					}
				}
			}

			return nil
		}

		parseRequiredTime := func(val interface{}) time.Time {
			if t := parseTime(val); t != nil {
				return *t
			}
			return time.Now()
		}

		// Set basic fields
		if id, ok := postData["id"].(string); ok {
			if uuid, err := uuid.Parse(id); err == nil {
				post.ID = uuid
			}
		}
		if userId, ok := postData["user_id"].(string); ok {
			if uuid, err := uuid.Parse(userId); err == nil {
				post.UserID = uuid
			}
		}
		if postType, ok := postData["post_type"].(string); ok {
			post.PostType = postType
		}
		if content, ok := postData["content"].(string); ok {
			post.Content = content
		}
		if visibility, ok := postData["visibility"].(string); ok {
			post.Visibility = visibility
		}
		if allowsComments, ok := postData["allows_comments"].(bool); ok {
			post.AllowsComments = allowsComments
		}
		if allowsSharing, ok := postData["allows_sharing"].(bool); ok {
			post.AllowsSharing = allowsSharing
		}
		if isPublished, ok := postData["is_published"].(bool); ok {
			post.IsPublished = isPublished
		}
		if isDraft, ok := postData["is_draft"].(bool); ok {
			post.IsDraft = isDraft
		}
		if isNSFW, ok := postData["is_nsfw"].(bool); ok {
			post.IsNSFW = isNSFW
		}

		// Parse numeric fields
		if likesCount, ok := postData["likes_count"].(float64); ok {
			post.LikesCount = int(likesCount)
		}
		if commentsCount, ok := postData["comments_count"].(float64); ok {
			post.CommentsCount = int(commentsCount)
		}
		if sharesCount, ok := postData["shares_count"].(float64); ok {
			post.SharesCount = int(sharesCount)
		}
		if viewsCount, ok := postData["views_count"].(float64); ok {
			post.ViewsCount = int(viewsCount)
		}
		if savesCount, ok := postData["saves_count"].(float64); ok {
			post.SavesCount = int(savesCount)
		}
		if isPinned, ok := postData["is_pinned"].(bool); ok {
			post.IsPinned = isPinned
		}
		if isFeatured, ok := postData["is_featured"].(bool); ok {
			post.IsFeatured = isFeatured
		}

		// Parse timestamps
		post.CreatedAt = parseRequiredTime(postData["created_at"])
		post.UpdatedAt = parseRequiredTime(postData["updated_at"])
		post.PublishedAt = parseTime(postData["published_at"])
		if deletedAt := parseTime(postData["deleted_at"]); deletedAt != nil {
			post.DeletedAt = deletedAt
		}

		// Parse arrays
		if mediaURLs, ok := postData["media_urls"].([]interface{}); ok {
			post.MediaURLs = make([]string, len(mediaURLs))
			for i, v := range mediaURLs {
				if str, ok := v.(string); ok {
					post.MediaURLs[i] = str
				}
			}
		}
		if mediaTypes, ok := postData["media_types"].([]interface{}); ok {
			post.MediaTypes = make([]string, len(mediaTypes))
			for i, v := range mediaTypes {
				if str, ok := v.(string); ok {
					post.MediaTypes[i] = str
				}
			}
		}
	}

	return nil
}

// parsePostFromMap parses a post from a map[string]interface{} (from JSON)
// This handles timestamp parsing issues with Supabase
func (r *SupabasePostRepository) parsePostFromMap(postData map[string]interface{}) (*models.Post, error) {
	post := &models.Post{}

	// Parse timestamps that might not have timezone
	// Supabase returns timestamps without timezone, we'll treat them as UTC
	parseTime := func(val interface{}) *time.Time {
		if val == nil {
			return nil
		}
		str, ok := val.(string)
		if !ok {
			return nil
		}

		// Try RFC3339 first (with timezone)
		if t, err := time.Parse(time.RFC3339, str); err == nil {
			return &t
		}
		// Try RFC3339Nano (with nanoseconds and timezone)
		if t, err := time.Parse(time.RFC3339Nano, str); err == nil {
			return &t
		}

		// Handle Supabase format without timezone: 2025-11-15T00:00:45.060234
		// Parse as UTC since Supabase stores timestamps in UTC
		utc, _ := time.LoadLocation("UTC")

		// If no timezone, parse directly as UTC
		if !strings.Contains(str, "Z") && !strings.Contains(str, "+") && len(str) > 10 {
			// Check if it has fractional seconds
			parts := strings.Split(str, ".")
			if len(parts) == 2 {
				// Has fractional seconds: 2025-11-15T00:00:45.060234
				// Normalize to 6 digits for parsing
				fractional := parts[1]
				if len(fractional) > 6 {
					fractional = fractional[:6]
				} else if len(fractional) < 6 {
					fractional = fractional + strings.Repeat("0", 6-len(fractional))
				}
				normalized := parts[0] + "." + fractional
				if t, err := time.ParseInLocation("2006-01-02T15:04:05.999999", normalized, utc); err == nil {
					return &t
				}
			} else {
				// No fractional seconds: 2025-11-15T00:00:45
				if t, err := time.ParseInLocation("2006-01-02T15:04:05", str, utc); err == nil {
					return &t
				}
			}
		}

		return nil
	}

	parseRequiredTime := func(val interface{}) time.Time {
		if t := parseTime(val); t != nil {
			return *t
		}
		return time.Now()
	}

	// Set basic fields
	if id, ok := postData["id"].(string); ok {
		if uuid, err := uuid.Parse(id); err == nil {
			post.ID = uuid
		}
	}
	if userId, ok := postData["user_id"].(string); ok {
		if uuid, err := uuid.Parse(userId); err == nil {
			post.UserID = uuid
		}
	}
	if postType, ok := postData["post_type"].(string); ok {
		post.PostType = postType
	}
	if content, ok := postData["content"].(string); ok {
		post.Content = content
	}
	if visibility, ok := postData["visibility"].(string); ok {
		post.Visibility = visibility
	}
	if allowsComments, ok := postData["allows_comments"].(bool); ok {
		post.AllowsComments = allowsComments
	}
	if allowsSharing, ok := postData["allows_sharing"].(bool); ok {
		post.AllowsSharing = allowsSharing
	}
	if isPublished, ok := postData["is_published"].(bool); ok {
		post.IsPublished = isPublished
	}
	if isDraft, ok := postData["is_draft"].(bool); ok {
		post.IsDraft = isDraft
	}
	if isNSFW, ok := postData["is_nsfw"].(bool); ok {
		post.IsNSFW = isNSFW
	}

	// Parse numeric fields
	if likesCount, ok := postData["likes_count"].(float64); ok {
		post.LikesCount = int(likesCount)
	}
	if commentsCount, ok := postData["comments_count"].(float64); ok {
		post.CommentsCount = int(commentsCount)
	}
	if sharesCount, ok := postData["shares_count"].(float64); ok {
		post.SharesCount = int(sharesCount)
	}
	if viewsCount, ok := postData["views_count"].(float64); ok {
		post.ViewsCount = int(viewsCount)
	}
	if savesCount, ok := postData["saves_count"].(float64); ok {
		post.SavesCount = int(savesCount)
	}
	if isPinned, ok := postData["is_pinned"].(bool); ok {
		post.IsPinned = isPinned
	}
	if isFeatured, ok := postData["is_featured"].(bool); ok {
		post.IsFeatured = isFeatured
	}

	// Parse timestamps
	post.CreatedAt = parseRequiredTime(postData["created_at"])
	post.UpdatedAt = parseRequiredTime(postData["updated_at"])
	post.PublishedAt = parseTime(postData["published_at"])
	if deletedAt := parseTime(postData["deleted_at"]); deletedAt != nil {
		post.DeletedAt = deletedAt
	}

	// Parse arrays
	if mediaURLs, ok := postData["media_urls"].([]interface{}); ok {
		post.MediaURLs = make([]string, len(mediaURLs))
		for i, v := range mediaURLs {
			if str, ok := v.(string); ok {
				post.MediaURLs[i] = str
			}
		}
	}
	if mediaTypes, ok := postData["media_types"].([]interface{}); ok {
		post.MediaTypes = make([]string, len(mediaTypes))
		for i, v := range mediaTypes {
			if str, ok := v.(string); ok {
				post.MediaTypes[i] = str
			}
		}
	}

	return post, nil
}

// parsePostsFromJSON parses multiple posts from JSON data
func (r *SupabasePostRepository) parsePostsFromJSON(data []byte) ([]models.Post, error) {
	var postsData []map[string]interface{}
	if err := json.Unmarshal(data, &postsData); err != nil {
		return nil, fmt.Errorf("failed to unmarshal posts JSON: %w", err)
	}

	posts := make([]models.Post, len(postsData))
	for i, postData := range postsData {
		post, err := r.parsePostFromMap(postData)
		if err != nil {
			return nil, fmt.Errorf("failed to parse post %d: %w", i, err)
		}
		posts[i] = *post
	}

	return posts, nil
}

// parsePostsFromJSONWithAuthors parses posts with embedded author data from Supabase joins
func (r *SupabasePostRepository) parsePostsFromJSONWithAuthors(data []byte) ([]models.Post, error) {
	var postsData []map[string]interface{}
	if err := json.Unmarshal(data, &postsData); err != nil {
		return nil, fmt.Errorf("failed to unmarshal posts JSON: %w", err)
	}

	posts := make([]models.Post, len(postsData))
	for i, postData := range postsData {
		post, err := r.parsePostFromMap(postData)
		if err != nil {
			return nil, fmt.Errorf("failed to parse post %d: %w", i, err)
		}

		// Parse embedded author data if present (from Supabase join)
		if authorData, ok := postData["author"].(map[string]interface{}); ok {
			author := &models.User{}
			if id, ok := authorData["id"].(string); ok {
				if uuid, err := uuid.Parse(id); err == nil {
					author.ID = uuid
				}
			}
			if username, ok := authorData["username"].(string); ok {
				author.Username = username
			}
			if displayName, ok := authorData["display_name"].(string); ok {
				author.DisplayName = displayName
			}
			if profilePicture, ok := authorData["profile_picture"].(string); ok && profilePicture != "" {
				author.ProfilePicture = &profilePicture
			}
			if isVerified, ok := authorData["is_verified"].(bool); ok {
				author.IsVerified = isVerified
			}
			post.Author = author
		}

		posts[i] = *post
	}

	return posts, nil
}

// GetPost retrieves a single post with all relations
func (r *SupabasePostRepository) GetPost(ctx context.Context, postID, viewerID uuid.UUID) (*models.Post, error) {
	query := fmt.Sprintf("?id=eq.%s&select=*", postID.String())

	data, err := r.makeRequest("GET", "posts", query, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get post: %w", err)
	}

	posts, err := r.parsePostsFromJSON(data)
	if err != nil {
		return nil, fmt.Errorf("failed to parse post: %w", err)
	}

	if len(posts) == 0 {
		return nil, models.ErrPostNotFound
	}

	post := &posts[0]

	// Load author
	if err := r.loadPostAuthor(ctx, post); err != nil {
		// Log but don't fail
		fmt.Printf("Warning: failed to load author for post %s: %v\n", postID, err)
	}

	// Check if viewer liked/saved
	if viewerID != uuid.Nil {
		post.IsLiked, _ = r.IsPostLikedByUser(ctx, postID, viewerID)
		post.IsSaved, _ = r.IsPostSavedByUser(ctx, postID, viewerID)
	}

	// Load type-specific data
	switch post.PostType {
	case "poll":
		// Load poll data
		if err := r.loadPollData(ctx, post); err != nil {
			fmt.Printf("Warning: failed to load poll data: %v\n", err)
		}
	case "article":
		// Load article data
		if err := r.loadArticleData(ctx, post); err != nil {
			fmt.Printf("Warning: failed to load article data: %v\n", err)
		}
	}

	return post, nil
}

// GetPostByID retrieves a post without viewer-specific data
func (r *SupabasePostRepository) GetPostByID(ctx context.Context, postID uuid.UUID) (*models.Post, error) {
	return r.GetPost(ctx, postID, uuid.Nil)
}

// GetUserPosts retrieves posts by a specific user
func (r *SupabasePostRepository) GetUserPosts(ctx context.Context, userID uuid.UUID, limit, offset int) ([]models.Post, int, error) {
	query := fmt.Sprintf(
		"?user_id=eq.%s&is_published=eq.true&deleted_at=is.null&order=published_at.desc&limit=%d&offset=%d",
		userID.String(), limit, offset,
	)

	data, err := r.makeRequest("GET", "posts", query, nil)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get user posts: %w", err)
	}

	posts, err := r.parsePostsFromJSON(data)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to parse user posts: %w", err)
	}

	// Get total count
	countQuery := fmt.Sprintf("?user_id=eq.%s&is_published=eq.true&deleted_at=is.null&select=count", userID.String())
	countData, _ := r.makeRequest("GET", "posts", countQuery, nil)
	total := len(posts) // Fallback

	if countData != nil {
		var countResult []map[string]int
		if err := json.Unmarshal(countData, &countResult); err == nil && len(countResult) > 0 {
			total = countResult[0]["count"]
		}
	}

	// If no posts, return early
	if len(posts) == 0 {
		return posts, total, nil
	}

	// Batch load authors
	userIDs := make([]uuid.UUID, len(posts))
	for i := range posts {
		userIDs[i] = posts[i].UserID
	}
	authorMap, _ := r.batchLoadAuthors(ctx, userIDs)
	for i := range posts {
		if author, ok := authorMap[posts[i].UserID]; ok {
			posts[i].Author = author
		}
	}

	// Load type-specific data (polls, articles) in batch
	if err := r.batchLoadPostTypeData(ctx, posts, userID); err != nil {
		// Log but don't fail - posts will still show without type-specific data
		fmt.Printf("Warning: failed to load type-specific data: %v\n", err)
	}

	return posts, total, nil
}

// GetHomeFeed retrieves the home feed for a user (chronological)
// OPTIMIZED: Uses batch loading and parallel execution
func (r *SupabasePostRepository) GetHomeFeed(ctx context.Context, userID uuid.UUID, limit, offset int) ([]models.Post, int, error) {
	// Use Supabase join to get posts with authors in one query
	// This reduces N+1 queries from N+1 to just 1 query for posts + authors
	query := fmt.Sprintf(
		"?is_published=eq.true&deleted_at=is.null&visibility=eq.public&order=published_at.desc&limit=%d&offset=%d&select=*,author:user_id(id,username,display_name,profile_picture,is_verified)",
		limit, offset,
	)

	data, err := r.makeRequest("GET", "posts", query, nil)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get home feed: %w", err)
	}

	// Parse posts with embedded author data
	posts, err := r.parsePostsFromJSONWithAuthors(data)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to parse feed: %w", err)
	}

	// If no posts, return early
	if len(posts) == 0 {
		return posts, 0, nil
	}

	// Batch load engagement data (likes and saves) in parallel
	if userID != uuid.Nil {
		// Collect post IDs
		postIDs := make([]uuid.UUID, len(posts))
		for i := range posts {
			postIDs[i] = posts[i].ID
		}

		// Use goroutines for parallel batch loading
		var likedMap, savedMap map[uuid.UUID]bool
		var likedErr, savedErr error
		var wg sync.WaitGroup

		wg.Add(2)

		// Batch check likes in parallel
		go func() {
			defer wg.Done()
			likedMap, likedErr = r.batchCheckLikes(ctx, postIDs, userID)
		}()

		// Batch check saves in parallel
		go func() {
			defer wg.Done()
			savedMap, savedErr = r.batchCheckSaves(ctx, postIDs, userID)
		}()

		wg.Wait()

		// Apply engagement data to posts
		for i := range posts {
			if likedErr == nil {
				posts[i].IsLiked = likedMap[posts[i].ID]
			}
			if savedErr == nil {
				posts[i].IsSaved = savedMap[posts[i].ID]
			}
		}
	}

	// Load type-specific data (polls, articles) in batch
	if err := r.batchLoadPostTypeData(ctx, posts, userID); err != nil {
		// Log but don't fail - posts will still show without type-specific data
		fmt.Printf("Warning: failed to load type-specific data: %v\n", err)
	}

	total := len(posts)
	return posts, total, nil
}

// GetFollowingFeed retrieves posts only from users the viewer follows
func (r *SupabasePostRepository) GetFollowingFeed(ctx context.Context, userID uuid.UUID, limit, offset int) ([]models.Post, int, error) {
	// For now, return same as home feed
	// TODO: Implement with relationship filtering
	return r.GetHomeFeed(ctx, userID, limit, offset)
}

// GetExploreFeed retrieves trending/popular posts for discovery
// OPTIMIZED: Uses batch loading and parallel execution
func (r *SupabasePostRepository) GetExploreFeed(ctx context.Context, userID uuid.UUID, limit, offset int) ([]models.Post, int, error) {
	// Use Supabase join to get posts with authors in one query
	query := fmt.Sprintf(
		"?is_published=eq.true&deleted_at=is.null&visibility=eq.public&order=likes_count.desc,published_at.desc&limit=%d&offset=%d&select=*,author:user_id(id,username,display_name,profile_picture,is_verified)",
		limit, offset,
	)

	data, err := r.makeRequest("GET", "posts", query, nil)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get explore feed: %w", err)
	}

	// Parse posts with embedded author data
	posts, err := r.parsePostsFromJSONWithAuthors(data)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to parse explore feed: %w", err)
	}

	// If no posts, return early
	if len(posts) == 0 {
		return posts, 0, nil
	}

	// Batch load engagement data (likes and saves) in parallel
	if userID != uuid.Nil {
		// Collect post IDs
		postIDs := make([]uuid.UUID, len(posts))
		for i := range posts {
			postIDs[i] = posts[i].ID
		}

		// Use goroutines for parallel batch loading
		var likedMap, savedMap map[uuid.UUID]bool
		var likedErr, savedErr error
		var wg sync.WaitGroup

		wg.Add(2)

		// Batch check likes in parallel
		go func() {
			defer wg.Done()
			likedMap, likedErr = r.batchCheckLikes(ctx, postIDs, userID)
		}()

		// Batch check saves in parallel
		go func() {
			defer wg.Done()
			savedMap, savedErr = r.batchCheckSaves(ctx, postIDs, userID)
		}()

		wg.Wait()

		// Apply engagement data to posts
		for i := range posts {
			if likedErr == nil {
				posts[i].IsLiked = likedMap[posts[i].ID]
			}
			if savedErr == nil {
				posts[i].IsSaved = savedMap[posts[i].ID]
			}
		}
	}

	// Load type-specific data (polls, articles) in batch
	if err := r.batchLoadPostTypeData(ctx, posts, userID); err != nil {
		// Log but don't fail - posts will still show without type-specific data
		fmt.Printf("Warning: failed to load type-specific data: %v\n", err)
	}

	return posts, len(posts), nil
}

// UpdatePost updates a post
func (r *SupabasePostRepository) UpdatePost(ctx context.Context, postID uuid.UUID, updates map[string]interface{}) error {
	updates["updated_at"] = time.Now()

	query := fmt.Sprintf("?id=eq.%s", postID.String())

	_, err := r.makeRequest("PATCH", "posts", query, updates)
	if err != nil {
		return fmt.Errorf("failed to update post: %w", err)
	}

	return nil
}

// DeletePost soft deletes a post
func (r *SupabasePostRepository) DeletePost(ctx context.Context, postID, userID uuid.UUID) error {
	// Verify ownership
	post, err := r.GetPostByID(ctx, postID)
	if err != nil {
		return err
	}

	if post.UserID != userID {
		return models.ErrUnauthorized
	}

	// Soft delete
	updates := map[string]interface{}{
		"deleted_at": time.Now(),
	}

	return r.UpdatePost(ctx, postID, updates)
}

// LikePost adds a like to a post
func (r *SupabasePostRepository) LikePost(ctx context.Context, postID, userID uuid.UUID) error {
	payload := map[string]interface{}{
		"post_id": postID,
		"user_id": userID,
	}

	_, err := r.makeRequest("POST", "post_likes", "", payload)
	if err != nil {
		if strings.Contains(err.Error(), "duplicate") || strings.Contains(err.Error(), "unique") {
			return nil // Already liked
		}
		return fmt.Errorf("failed to like post: %w", err)
	}

	return nil
}

// UnlikePost removes a like from a post
func (r *SupabasePostRepository) UnlikePost(ctx context.Context, postID, userID uuid.UUID) error {
	query := fmt.Sprintf("?post_id=eq.%s&user_id=eq.%s", postID.String(), userID.String())

	_, err := r.makeRequest("DELETE", "post_likes", query, nil)
	if err != nil {
		return fmt.Errorf("failed to unlike post: %w", err)
	}

	return nil
}

// IsPostLikedByUser checks if a user has liked a post
func (r *SupabasePostRepository) IsPostLikedByUser(ctx context.Context, postID, userID uuid.UUID) (bool, error) {
	query := fmt.Sprintf("?post_id=eq.%s&user_id=eq.%s&select=id", postID.String(), userID.String())

	data, err := r.makeRequest("GET", "post_likes", query, nil)
	if err != nil {
		return false, nil // Assume not liked on error
	}

	var likes []map[string]interface{}
	if err := json.Unmarshal(data, &likes); err != nil {
		return false, nil
	}

	return len(likes) > 0, nil
}

// batchCheckLikes checks which posts a user has liked (batch operation)
func (r *SupabasePostRepository) batchCheckLikes(ctx context.Context, postIDs []uuid.UUID, userID uuid.UUID) (map[uuid.UUID]bool, error) {
	if len(postIDs) == 0 {
		return make(map[uuid.UUID]bool), nil
	}

	// Build query: post_id=in.(id1,id2,id3,...)&user_id=eq.{userID}
	postIDStrings := make([]string, len(postIDs))
	for i, id := range postIDs {
		postIDStrings[i] = id.String()
	}
	query := fmt.Sprintf("?post_id=in.(%s)&user_id=eq.%s&select=post_id", strings.Join(postIDStrings, ","), userID.String())

	data, err := r.makeRequest("GET", "post_likes", query, nil)
	if err != nil {
		return make(map[uuid.UUID]bool), nil // Return empty map on error
	}

	var likes []map[string]interface{}
	if err := json.Unmarshal(data, &likes); err != nil {
		return make(map[uuid.UUID]bool), nil
	}

	// Build map of liked post IDs
	likedMap := make(map[uuid.UUID]bool)
	for _, like := range likes {
		if postIDStr, ok := like["post_id"].(string); ok {
			if postID, err := uuid.Parse(postIDStr); err == nil {
				likedMap[postID] = true
			}
		}
	}

	return likedMap, nil
}

// GetPostLikes retrieves users who liked a post
func (r *SupabasePostRepository) GetPostLikes(ctx context.Context, postID uuid.UUID, limit, offset int) ([]models.User, int, error) {
	// This would require a join or RPC function
	// For now, return empty list
	return []models.User{}, 0, nil
}

// SharePost creates a share/repost
func (r *SupabasePostRepository) SharePost(ctx context.Context, postID, userID uuid.UUID, comment string) error {
	payload := map[string]interface{}{
		"post_id":        postID,
		"user_id":        userID,
		"repost_comment": comment,
	}

	_, err := r.makeRequest("POST", "post_shares", "", payload)
	if err != nil {
		if strings.Contains(err.Error(), "duplicate") {
			return nil // Already shared
		}
		return fmt.Errorf("failed to share post: %w", err)
	}

	return nil
}

// UnsharePost removes a share
func (r *SupabasePostRepository) UnsharePost(ctx context.Context, postID, userID uuid.UUID) error {
	query := fmt.Sprintf("?post_id=eq.%s&user_id=eq.%s", postID.String(), userID.String())

	_, err := r.makeRequest("DELETE", "post_shares", query, nil)
	return err
}

// SavePost bookmarks a post
func (r *SupabasePostRepository) SavePost(ctx context.Context, postID, userID uuid.UUID, collection string) error {
	if collection == "" {
		collection = "Saved"
	}

	payload := map[string]interface{}{
		"post_id":         postID,
		"user_id":         userID,
		"collection_name": collection,
	}

	_, err := r.makeRequest("POST", "saved_posts", "", payload)
	if err != nil {
		if strings.Contains(err.Error(), "duplicate") {
			return nil // Already saved
		}
		return fmt.Errorf("failed to save post: %w", err)
	}

	return nil
}

// UnsavePost removes a bookmark
func (r *SupabasePostRepository) UnsavePost(ctx context.Context, postID, userID uuid.UUID) error {
	query := fmt.Sprintf("?post_id=eq.%s&user_id=eq.%s", postID.String(), userID.String())

	_, err := r.makeRequest("DELETE", "saved_posts", query, nil)
	return err
}

// IsPostSavedByUser checks if a user has saved a post
func (r *SupabasePostRepository) IsPostSavedByUser(ctx context.Context, postID, userID uuid.UUID) (bool, error) {
	query := fmt.Sprintf("?post_id=eq.%s&user_id=eq.%s&select=id", postID.String(), userID.String())

	data, err := r.makeRequest("GET", "saved_posts", query, nil)
	if err != nil {
		return false, nil
	}

	var saved []map[string]interface{}
	if err := json.Unmarshal(data, &saved); err != nil {
		return false, nil
	}

	return len(saved) > 0, nil
}

// batchCheckSaves checks which posts a user has saved (batch operation)
func (r *SupabasePostRepository) batchCheckSaves(ctx context.Context, postIDs []uuid.UUID, userID uuid.UUID) (map[uuid.UUID]bool, error) {
	if len(postIDs) == 0 {
		return make(map[uuid.UUID]bool), nil
	}

	// Build query: post_id=in.(id1,id2,id3,...)&user_id=eq.{userID}
	postIDStrings := make([]string, len(postIDs))
	for i, id := range postIDs {
		postIDStrings[i] = id.String()
	}
	query := fmt.Sprintf("?post_id=in.(%s)&user_id=eq.%s&select=post_id", strings.Join(postIDStrings, ","), userID.String())

	data, err := r.makeRequest("GET", "saved_posts", query, nil)
	if err != nil {
		return make(map[uuid.UUID]bool), nil // Return empty map on error
	}

	var saved []map[string]interface{}
	if err := json.Unmarshal(data, &saved); err != nil {
		return make(map[uuid.UUID]bool), nil
	}

	// Build map of saved post IDs
	savedMap := make(map[uuid.UUID]bool)
	for _, save := range saved {
		if postIDStr, ok := save["post_id"].(string); ok {
			if postID, err := uuid.Parse(postIDStr); err == nil {
				savedMap[postID] = true
			}
		}
	}

	return savedMap, nil
}

// batchLoadAuthors loads multiple authors in one query
func (r *SupabasePostRepository) batchLoadAuthors(ctx context.Context, userIDs []uuid.UUID) (map[uuid.UUID]*models.User, error) {
	if len(userIDs) == 0 {
		return make(map[uuid.UUID]*models.User), nil
	}

	// Build query: id=in.(id1,id2,id3,...)
	userIDStrings := make([]string, len(userIDs))
	for i, id := range userIDs {
		userIDStrings[i] = id.String()
	}
	query := fmt.Sprintf("?id=in.(%s)&select=id,username,display_name,profile_picture,is_verified", strings.Join(userIDStrings, ","))

	data, err := r.makeRequest("GET", "users", query, nil)
	if err != nil {
		return make(map[uuid.UUID]*models.User), err
	}

	var users []models.User
	if err := json.Unmarshal(data, &users); err != nil {
		return make(map[uuid.UUID]*models.User), err
	}

	// Build map of users by ID
	userMap := make(map[uuid.UUID]*models.User)
	for i := range users {
		userMap[users[i].ID] = &users[i]
	}

	return userMap, nil
}

// GetSavedPosts retrieves user's saved posts
func (r *SupabasePostRepository) GetSavedPosts(ctx context.Context, userID uuid.UUID, collection string, limit, offset int) ([]models.Post, int, error) {
	// Get saved post IDs
	query := fmt.Sprintf("?user_id=eq.%s&select=post_id&order=saved_at.desc&limit=%d&offset=%d", userID.String(), limit, offset)
	if collection != "" {
		query = fmt.Sprintf("?user_id=eq.%s&collection_name=eq.%s&select=post_id&order=saved_at.desc&limit=%d&offset=%d",
			userID.String(), collection, limit, offset)
	}

	data, err := r.makeRequest("GET", "saved_posts", query, nil)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get saved posts: %w", err)
	}

	var savedRecords []struct {
		PostID uuid.UUID `json:"post_id"`
	}
	if err := json.Unmarshal(data, &savedRecords); err != nil {
		return nil, 0, fmt.Errorf("failed to unmarshal saved posts: %w", err)
	}

	if len(savedRecords) == 0 {
		return []models.Post{}, 0, nil
	}

	// Get the actual posts
	postIDs := make([]string, len(savedRecords))
	for i, record := range savedRecords {
		postIDs[i] = record.PostID.String()
	}

	postsQuery := fmt.Sprintf("?id=in.(%s)&select=*", strings.Join(postIDs, ","))
	postsData, err := r.makeRequest("GET", "posts", postsQuery, nil)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get posts: %w", err)
	}

	posts, err := r.parsePostsFromJSON(postsData)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to parse posts: %w", err)
	}

	// Load authors
	for i := range posts {
		r.loadPostAuthor(ctx, &posts[i])
		posts[i].IsSaved = true // All these are saved
	}

	return posts, len(savedRecords), nil
}

// IncrementViews increments the view count for a post
func (r *SupabasePostRepository) IncrementViews(ctx context.Context, postID uuid.UUID) error {
	// Use RPC to increment atomically
	// For now, skip (would need custom function)
	return nil
}

// GetHashtagFeed retrieves posts with a specific hashtag
func (r *SupabasePostRepository) GetHashtagFeed(ctx context.Context, hashtag string, limit, offset int) ([]models.Post, int, error) {
	// First, get the hashtag ID
	hashtagQuery := fmt.Sprintf("?tag=eq.%s&select=id", hashtag)
	hashtagData, err := r.makeRequest("GET", "hashtags", hashtagQuery, nil)
	if err != nil {
		return []models.Post{}, 0, nil
	}

	var hashtags []struct {
		ID uuid.UUID `json:"id"`
	}
	if err := json.Unmarshal(hashtagData, &hashtags); err != nil || len(hashtags) == 0 {
		return []models.Post{}, 0, nil
	}

	hashtagID := hashtags[0].ID

	// Get post IDs with this hashtag
	postHashtagQuery := fmt.Sprintf("?hashtag_id=eq.%s&select=post_id", hashtagID.String())
	postHashtagData, err := r.makeRequest("GET", "post_hashtags", postHashtagQuery, nil)
	if err != nil {
		return []models.Post{}, 0, nil
	}

	var postHashtags []struct {
		PostID uuid.UUID `json:"post_id"`
	}
	if err := json.Unmarshal(postHashtagData, &postHashtags); err != nil {
		return []models.Post{}, 0, nil
	}

	if len(postHashtags) == 0 {
		return []models.Post{}, 0, nil
	}

	// Get the posts
	postIDs := make([]string, len(postHashtags))
	for i, ph := range postHashtags {
		postIDs[i] = ph.PostID.String()
	}

	postsQuery := fmt.Sprintf("?id=in.(%s)&is_published=eq.true&deleted_at=is.null&order=published_at.desc&limit=%d&offset=%d",
		strings.Join(postIDs, ","), limit, offset)

	postsData, err := r.makeRequest("GET", "posts", postsQuery, nil)
	if err != nil {
		return []models.Post{}, 0, fmt.Errorf("failed to get posts: %w", err)
	}

	posts, err := r.parsePostsFromJSON(postsData)
	if err != nil {
		return []models.Post{}, 0, nil
	}

	// Load authors
	for i := range posts {
		r.loadPostAuthor(ctx, &posts[i])
	}

	return posts, len(posts), nil
}

// SearchPosts searches posts by content
func (r *SupabasePostRepository) SearchPosts(ctx context.Context, query string, userID uuid.UUID, limit, offset int) ([]models.Post, int, error) {
	// Use full-text search
	// For now, simple LIKE search
	searchQuery := fmt.Sprintf(
		"?content=ilike.*%s*&is_published=eq.true&deleted_at=is.null&order=published_at.desc&limit=%d&offset=%d",
		query, limit, offset,
	)

	data, err := r.makeRequest("GET", "posts", searchQuery, nil)
	if err != nil {
		return []models.Post{}, 0, fmt.Errorf("failed to search posts: %w", err)
	}

	posts, err := r.parsePostsFromJSON(data)
	if err != nil {
		return []models.Post{}, 0, nil
	}

	// Load authors
	for i := range posts {
		r.loadPostAuthor(ctx, &posts[i])
	}

	return posts, len(posts), nil
}

// ExtractAndCreateHashtags extracts hashtags from content and creates associations
func (r *SupabasePostRepository) ExtractAndCreateHashtags(ctx context.Context, postID uuid.UUID, content string) error {
	hashtags := extractHashtags(content)

	for _, tag := range hashtags {
		// Get or create hashtag
		hashtagID, err := r.getOrCreateHashtag(ctx, tag)
		if err != nil {
			continue // Skip on error
		}

		// Create association
		payload := map[string]interface{}{
			"post_id":    postID,
			"hashtag_id": hashtagID,
		}

		r.makeRequest("POST", "post_hashtags", "", payload)
	}

	return nil
}

// ExtractAndCreateMentions extracts @mentions and creates associations
func (r *SupabasePostRepository) ExtractAndCreateMentions(ctx context.Context, postID uuid.UUID, content string) error {
	mentions := extractMentions(content)

	for _, username := range mentions {
		// Get user ID by username
		userQuery := fmt.Sprintf("?username=eq.%s&select=id", username)
		userData, err := r.makeRequest("GET", "users", userQuery, nil)
		if err != nil {
			continue
		}

		var users []struct {
			ID uuid.UUID `json:"id"`
		}
		if err := json.Unmarshal(userData, &users); err != nil || len(users) == 0 {
			continue
		}

		// Create mention
		payload := map[string]interface{}{
			"post_id":           postID,
			"mentioned_user_id": users[0].ID,
		}

		r.makeRequest("POST", "post_mentions", "", payload)
	}

	return nil
}

// GetHashtagByTag retrieves a hashtag by its tag
func (r *SupabasePostRepository) GetHashtagByTag(ctx context.Context, tag string) (*HashtagInfo, error) {
	query := fmt.Sprintf("?tag=eq.%s&select=*", tag)

	data, err := r.makeRequest("GET", "hashtags", query, nil)
	if err != nil {
		return nil, err
	}

	var hashtags []HashtagInfo
	if err := json.Unmarshal(data, &hashtags); err != nil {
		return nil, err
	}

	if len(hashtags) == 0 {
		return nil, fmt.Errorf("hashtag not found")
	}

	return &hashtags[0], nil
}

// GetTrendingHashtags retrieves trending hashtags
func (r *SupabasePostRepository) GetTrendingHashtags(ctx context.Context, limit int) ([]HashtagInfo, error) {
	query := fmt.Sprintf("?order=trending_score.desc,posts_count.desc&limit=%d", limit)

	data, err := r.makeRequest("GET", "hashtags", query, nil)
	if err != nil {
		return []HashtagInfo{}, nil
	}

	var hashtags []HashtagInfo
	if err := json.Unmarshal(data, &hashtags); err != nil {
		return []HashtagInfo{}, nil
	}

	return hashtags, nil
}

// FollowHashtag allows a user to follow a hashtag
func (r *SupabasePostRepository) FollowHashtag(ctx context.Context, hashtagID, userID uuid.UUID) error {
	payload := map[string]interface{}{
		"hashtag_id": hashtagID,
		"user_id":    userID,
	}

	_, err := r.makeRequest("POST", "hashtag_followers", "", payload)
	if err != nil {
		if strings.Contains(err.Error(), "duplicate") {
			return nil
		}
		return err
	}

	return nil
}

// UnfollowHashtag unfollows a hashtag
func (r *SupabasePostRepository) UnfollowHashtag(ctx context.Context, hashtagID, userID uuid.UUID) error {
	query := fmt.Sprintf("?hashtag_id=eq.%s&user_id=eq.%s", hashtagID.String(), userID.String())

	_, err := r.makeRequest("DELETE", "hashtag_followers", query, nil)
	return err
}

// ============================================
// HELPER FUNCTIONS
// ============================================

// loadPostAuthor loads the author user data for a post
func (r *SupabasePostRepository) loadPostAuthor(ctx context.Context, post *models.Post) error {
	query := fmt.Sprintf("?id=eq.%s&select=id,username,display_name,profile_picture,is_verified", post.UserID.String())

	data, err := r.makeRequest("GET", "users", query, nil)
	if err != nil {
		return err
	}

	var users []models.User
	if err := json.Unmarshal(data, &users); err != nil {
		return err
	}

	if len(users) > 0 {
		post.Author = &users[0]
	}

	return nil
}

// loadPollData loads poll and options for a post
func (r *SupabasePostRepository) loadPollData(ctx context.Context, post *models.Post) error {
	// Get poll
	pollQuery := fmt.Sprintf("?post_id=eq.%s&select=*", post.ID.String())
	pollData, err := r.makeRequest("GET", "polls", pollQuery, nil)
	if err != nil {
		return err
	}

	var polls []models.Poll
	if err := json.Unmarshal(pollData, &polls); err != nil {
		return err
	}

	if len(polls) == 0 {
		return fmt.Errorf("poll not found for post")
	}

	poll := &polls[0]

	// Get poll options
	optionsQuery := fmt.Sprintf("?poll_id=eq.%s&select=*&order=option_index.asc", poll.ID.String())
	optionsData, err := r.makeRequest("GET", "poll_options", optionsQuery, nil)
	if err != nil {
		return err
	}

	var options []models.PollOption
	if err := json.Unmarshal(optionsData, &options); err != nil {
		return err
	}

	poll.Options = options
	post.Poll = poll

	return nil
}

// batchLoadPostTypeData loads poll and article data for multiple posts in batch
func (r *SupabasePostRepository) batchLoadPostTypeData(ctx context.Context, posts []models.Post, userID uuid.UUID) error {
	if len(posts) == 0 {
		return nil
	}

	// Separate posts by type
	var pollPostIDs, articlePostIDs []uuid.UUID
	for i := range posts {
		if posts[i].PostType == "poll" {
			pollPostIDs = append(pollPostIDs, posts[i].ID)
		} else if posts[i].PostType == "article" {
			articlePostIDs = append(articlePostIDs, posts[i].ID)
		}
	}

	// Load polls in batch
	if len(pollPostIDs) > 0 {
		fmt.Printf("[DEBUG] Loading %d polls for posts\n", len(pollPostIDs))
		if err := r.batchLoadPolls(ctx, posts, pollPostIDs, userID); err != nil {
			fmt.Printf("Warning: failed to batch load polls: %v\n", err)
		} else {
			fmt.Printf("[DEBUG] Successfully loaded polls\n")
		}
	}

	// Load articles in batch
	if len(articlePostIDs) > 0 {
		if err := r.batchLoadArticles(ctx, posts, articlePostIDs); err != nil {
			fmt.Printf("Warning: failed to batch load articles: %v\n", err)
		}
	}

	return nil
}

// batchLoadPolls loads poll data for multiple posts
func (r *SupabasePostRepository) batchLoadPolls(ctx context.Context, posts []models.Post, pollPostIDs []uuid.UUID, userID uuid.UUID) error {
	// Build query: post_id=in.(id1,id2,id3,...)
	postIDStrings := make([]string, len(pollPostIDs))
	for i, id := range pollPostIDs {
		postIDStrings[i] = id.String()
	}
	pollQuery := fmt.Sprintf("?post_id=in.(%s)&select=*", strings.Join(postIDStrings, ","))

	pollData, err := r.makeRequest("GET", "polls", pollQuery, nil)
	if err != nil {
		return fmt.Errorf("failed to get polls: %w", err)
	}

	// Parse polls with custom timestamp handling
	var pollsData []map[string]interface{}
	if err := json.Unmarshal(pollData, &pollsData); err != nil {
		return fmt.Errorf("failed to unmarshal polls: %w", err)
	}

	// Parse timestamps that might not have timezone
	parseTime := func(val interface{}) *time.Time {
		if val == nil {
			return nil
		}
		str, ok := val.(string)
		if !ok {
			return nil
		}

		// Try RFC3339 first (with timezone)
		if t, err := time.Parse(time.RFC3339, str); err == nil {
			return &t
		}
		// Try RFC3339Nano (with nanoseconds and timezone)
		if t, err := time.Parse(time.RFC3339Nano, str); err == nil {
			return &t
		}

		// Handle Supabase format without timezone
		utc, _ := time.LoadLocation("UTC")
		if !strings.Contains(str, "Z") && !strings.Contains(str, "+") && len(str) > 10 {
			parts := strings.Split(str, ".")
			if len(parts) == 2 {
				fractional := parts[1]
				if len(fractional) > 6 {
					fractional = fractional[:6]
				} else if len(fractional) < 6 {
					fractional = fractional + strings.Repeat("0", 6-len(fractional))
				}
				normalized := parts[0] + "." + fractional
				if t, err := time.ParseInLocation("2006-01-02T15:04:05.999999", normalized, utc); err == nil {
					return &t
				}
			} else {
				if t, err := time.ParseInLocation("2006-01-02T15:04:05", str, utc); err == nil {
					return &t
				}
			}
		}

		return nil
	}

	parseRequiredTime := func(val interface{}) time.Time {
		if t := parseTime(val); t != nil {
			return *t
		}
		return time.Now()
	}

	// Convert to Poll models
	polls := make([]models.Poll, len(pollsData))
	for i, pollData := range pollsData {
		poll := &polls[i]

		// Parse IDs
		if id, ok := pollData["id"].(string); ok {
			if uuid, err := uuid.Parse(id); err == nil {
				poll.ID = uuid
			}
		}
		if postID, ok := pollData["post_id"].(string); ok {
			if uuid, err := uuid.Parse(postID); err == nil {
				poll.PostID = uuid
			}
		}

		// Parse strings
		if question, ok := pollData["question"].(string); ok {
			poll.Question = question
		}

		// Parse integers
		if durationHours, ok := pollData["duration_hours"].(float64); ok {
			poll.DurationHours = int(durationHours)
		}
		if totalVotes, ok := pollData["total_votes"].(float64); ok {
			poll.TotalVotes = int(totalVotes)
		}

		// Parse booleans
		if allowMultiple, ok := pollData["allow_multiple_votes"].(bool); ok {
			poll.AllowMultipleVotes = allowMultiple
		}
		if showResults, ok := pollData["show_results_before_vote"].(bool); ok {
			poll.ShowResultsBeforeVote = showResults
		}
		if allowChanges, ok := pollData["allow_vote_changes"].(bool); ok {
			poll.AllowVoteChanges = allowChanges
		}
		if anonymous, ok := pollData["anonymous_votes"].(bool); ok {
			poll.AnonymousVotes = anonymous
		}
		if isClosed, ok := pollData["is_closed"].(bool); ok {
			poll.IsClosed = isClosed
		}

		// Parse timestamps
		poll.CreatedAt = parseRequiredTime(pollData["created_at"])
		poll.EndsAt = parseRequiredTime(pollData["ends_at"])
		poll.ClosedAt = parseTime(pollData["closed_at"])
	}

	// Create map of polls by post_id (for assigning to posts)
	pollMapByPostID := make(map[uuid.UUID]*models.Poll)
	// Also create map by poll ID (for assigning options)
	pollMapByPollID := make(map[uuid.UUID]*models.Poll)
	for i := range polls {
		pollMapByPostID[polls[i].PostID] = &polls[i]
		pollMapByPollID[polls[i].ID] = &polls[i]
	}

	// Get all poll IDs to fetch options
	pollIDs := make([]uuid.UUID, len(polls))
	for i := range polls {
		pollIDs[i] = polls[i].ID
	}

	// Initialize Options as empty slice for all polls (to prevent nil errors)
	for i := range polls {
		if polls[i].Options == nil {
			polls[i].Options = []models.PollOption{}
		}
	}

	// Batch load poll options
	if len(pollIDs) > 0 {
		pollIDStrings := make([]string, len(pollIDs))
		for i, id := range pollIDs {
			pollIDStrings[i] = id.String()
		}
		optionsQuery := fmt.Sprintf("?poll_id=in.(%s)&select=*&order=poll_id.asc,option_index.asc", strings.Join(pollIDStrings, ","))
		fmt.Printf("[DEBUG] Querying poll options with: %s\n", optionsQuery)

		optionsData, err := r.makeRequest("GET", "poll_options", optionsQuery, nil)
		if err != nil {
			fmt.Printf("[DEBUG] ERROR: failed to load poll options: %v\n", err)
		} else {
			responsePreview := string(optionsData)
			if len(responsePreview) > 500 {
				responsePreview = responsePreview[:500] + "..."
			}
			fmt.Printf("[DEBUG] Received poll options response: %s\n", responsePreview)

			// Try parsing as array of maps first to debug
			var rawOptions []map[string]interface{}
			if err := json.Unmarshal(optionsData, &rawOptions); err == nil {
				fmt.Printf("[DEBUG] Parsed %d raw poll options\n", len(rawOptions))
				for i, opt := range rawOptions {
					if i < 3 { // Print first 3 for debugging
						fmt.Printf("[DEBUG] Option %d: poll_id=%v, option_text=%v, option_index=%v\n",
							i, opt["poll_id"], opt["option_text"], opt["option_index"])
					}
				}
			}

			var options []models.PollOption
			if err := json.Unmarshal(optionsData, &options); err != nil {
				fmt.Printf("[DEBUG] ERROR: failed to unmarshal poll options: %v\n", err)
				fmt.Printf("[DEBUG] Raw JSON: %s\n", string(optionsData))
			} else {
				fmt.Printf("[DEBUG] Successfully unmarshaled %d poll options\n", len(options))
				// Group options by poll_id
				optionsMap := make(map[uuid.UUID][]models.PollOption)
				for i := range options {
					optionsMap[options[i].PollID] = append(optionsMap[options[i].PollID], options[i])
					fmt.Printf("[DEBUG] Option %d: poll_id=%s, text=%s, index=%d\n",
						i, options[i].PollID.String(), options[i].OptionText, options[i].OptionIndex)
				}

				// Assign options to polls (using poll ID, not post ID)
				for pollID, opts := range optionsMap {
					if poll, ok := pollMapByPollID[pollID]; ok {
						poll.Options = opts
						fmt.Printf("[DEBUG] Assigned %d options to poll %s (post_id: %s)\n", len(opts), pollID.String(), poll.PostID.String())
					} else {
						fmt.Printf("[DEBUG] WARNING: Poll %s not found in pollMapByPollID\n", pollID.String())
					}
				}
			}
		}
	}

	// Load user votes for polls (if userID is provided)
	if len(pollIDs) > 0 && userID != uuid.Nil {
		pollIDStrings := make([]string, len(pollIDs))
		for i, id := range pollIDs {
			pollIDStrings[i] = id.String()
		}
		votesQuery := fmt.Sprintf("?poll_id=in.(%s)&user_id=eq.%s&select=poll_id,option_id", strings.Join(pollIDStrings, ","), userID.String())

		votesData, err := r.makeRequest("GET", "poll_votes", votesQuery, nil)
		if err == nil {
			var votes []struct {
				PollID   uuid.UUID `json:"poll_id"`
				OptionID uuid.UUID `json:"option_id"`
			}
			if err := json.Unmarshal(votesData, &votes); err == nil {
				// Create map of votes by poll_id
				votesMap := make(map[uuid.UUID]uuid.UUID)
				for _, vote := range votes {
					votesMap[vote.PollID] = vote.OptionID
				}

				// Assign user votes to polls
				for pollID, optionID := range votesMap {
					if poll, ok := pollMapByPollID[pollID]; ok {
						poll.UserVote = &optionID
						fmt.Printf("[DEBUG] Assigned user vote %s to poll %s\n", optionID.String(), pollID.String())
					}
				}
			}
		}
	}

	// Assign polls to posts (using post ID)
	assignedCount := 0
	for i := range posts {
		if poll, ok := pollMapByPostID[posts[i].ID]; ok {
			// Ensure Options is always initialized (even if empty)
			if poll.Options == nil {
				poll.Options = []models.PollOption{}
			}
			posts[i].Poll = poll
			assignedCount++
			fmt.Printf("[DEBUG] Assigned poll %s to post %s with %d options\n", poll.ID.String(), posts[i].ID.String(), len(poll.Options))
		}
	}
	fmt.Printf("[DEBUG] Assigned %d polls to posts (out of %d poll posts)\n", assignedCount, len(pollPostIDs))

	return nil
}

// batchLoadArticles loads article data for multiple posts
func (r *SupabasePostRepository) batchLoadArticles(ctx context.Context, posts []models.Post, articlePostIDs []uuid.UUID) error {
	// Build query: post_id=in.(id1,id2,id3,...)
	postIDStrings := make([]string, len(articlePostIDs))
	for i, id := range articlePostIDs {
		postIDStrings[i] = id.String()
	}
	articleQuery := fmt.Sprintf("?post_id=in.(%s)&select=*", strings.Join(postIDStrings, ","))

	articleData, err := r.makeRequest("GET", "articles", articleQuery, nil)
	if err != nil {
		return fmt.Errorf("failed to get articles: %w", err)
	}

	// Parse as map first to handle timestamps
	var articlesData []map[string]interface{}
	if err := json.Unmarshal(articleData, &articlesData); err != nil {
		return fmt.Errorf("failed to unmarshal articles: %w", err)
	}

	// Parse timestamps
	parseTime := func(val interface{}) *time.Time {
		if val == nil {
			return nil
		}
		str, ok := val.(string)
		if !ok {
			return nil
		}

		if t, err := time.Parse(time.RFC3339, str); err == nil {
			return &t
		}
		if t, err := time.Parse(time.RFC3339Nano, str); err == nil {
			return &t
		}

		utc, _ := time.LoadLocation("UTC")
		if !strings.Contains(str, "Z") && !strings.Contains(str, "+") && len(str) > 10 {
			parts := strings.Split(str, ".")
			if len(parts) == 2 {
				fractional := parts[1]
				if len(fractional) > 6 {
					fractional = fractional[:6]
				} else if len(fractional) < 6 {
					fractional = fractional + strings.Repeat("0", 6-len(fractional))
				}
				normalized := parts[0] + "." + fractional
				if t, err := time.ParseInLocation("2006-01-02T15:04:05.999999", normalized, utc); err == nil {
					return &t
				}
			} else {
				if t, err := time.ParseInLocation("2006-01-02T15:04:05", str, utc); err == nil {
					return &t
				}
			}
		}

		return nil
	}

	parseRequiredTime := func(val interface{}) time.Time {
		if t := parseTime(val); t != nil {
			return *t
		}
		return time.Now()
	}

	// Convert to Article models
	articles := make([]models.Article, len(articlesData))
	for i, articleData := range articlesData {
		article := &articles[i]

		// Parse IDs
		if id, ok := articleData["id"].(string); ok {
			if uuid, err := uuid.Parse(id); err == nil {
				article.ID = uuid
			}
		}
		if postIDVal, ok := articleData["post_id"].(string); ok {
			if uuid, err := uuid.Parse(postIDVal); err == nil {
				article.PostID = uuid
			}
		}

		// Parse strings
		if title, ok := articleData["title"].(string); ok {
			article.Title = title
		}
		if subtitle, ok := articleData["subtitle"].(string); ok && subtitle != "" {
			article.Subtitle = subtitle
		}
		if contentHTML, ok := articleData["content_html"].(string); ok {
			article.ContentHTML = contentHTML
		}
		if coverImageURL, ok := articleData["cover_image_url"].(string); ok && coverImageURL != "" {
			article.CoverImageURL = coverImageURL
		}
		if metaTitle, ok := articleData["meta_title"].(string); ok && metaTitle != "" {
			article.MetaTitle = metaTitle
		}
		if metaDescription, ok := articleData["meta_description"].(string); ok && metaDescription != "" {
			article.MetaDescription = metaDescription
		}
		if slug, ok := articleData["slug"].(string); ok {
			article.Slug = slug
		}
		if category, ok := articleData["category"].(string); ok && category != "" {
			article.Category = category
		}

		// Parse integers
		if readTime, ok := articleData["read_time_minutes"].(float64); ok {
			article.ReadTimeMinutes = int(readTime)
		}
		if viewsCount, ok := articleData["views_count"].(float64); ok {
			article.ViewsCount = int(viewsCount)
		}
		if readsCount, ok := articleData["reads_count"].(float64); ok {
			article.ReadsCount = int(readsCount)
		}

		// Parse timestamps
		article.CreatedAt = parseRequiredTime(articleData["created_at"])
		article.UpdatedAt = parseRequiredTime(articleData["updated_at"])
	}

	// Create map of articles by post_id
	articleMap := make(map[uuid.UUID]*models.Article)
	for i := range articles {
		articleMap[articles[i].PostID] = &articles[i]
	}

	// Assign articles to posts
	for i := range posts {
		if article, ok := articleMap[posts[i].ID]; ok {
			posts[i].Article = article
		}
	}

	return nil
}

// loadArticleData loads article metadata for a post
func (r *SupabasePostRepository) loadArticleData(ctx context.Context, post *models.Post) error {
	articleQuery := fmt.Sprintf("?post_id=eq.%s&select=*", post.ID.String())
	articleData, err := r.makeRequest("GET", "articles", articleQuery, nil)
	if err != nil {
		return err
	}

	// Parse as map first to handle timestamps
	var articlesData []map[string]interface{}
	if err := json.Unmarshal(articleData, &articlesData); err != nil {
		return err
	}

	if len(articlesData) > 0 {
		// Use the same parsing logic as batchLoadArticles
		articleData := articlesData[0]

		// Parse timestamps
		parseTime := func(val interface{}) *time.Time {
			if val == nil {
				return nil
			}
			str, ok := val.(string)
			if !ok {
				return nil
			}

			if t, err := time.Parse(time.RFC3339, str); err == nil {
				return &t
			}
			if t, err := time.Parse(time.RFC3339Nano, str); err == nil {
				return &t
			}

			utc, _ := time.LoadLocation("UTC")
			if !strings.Contains(str, "Z") && !strings.Contains(str, "+") && len(str) > 10 {
				parts := strings.Split(str, ".")
				if len(parts) == 2 {
					fractional := parts[1]
					if len(fractional) > 6 {
						fractional = fractional[:6]
					} else if len(fractional) < 6 {
						fractional = fractional + strings.Repeat("0", 6-len(fractional))
					}
					normalized := parts[0] + "." + fractional
					if t, err := time.ParseInLocation("2006-01-02T15:04:05.999999", normalized, utc); err == nil {
						return &t
					}
				} else {
					if t, err := time.ParseInLocation("2006-01-02T15:04:05", str, utc); err == nil {
						return &t
					}
				}
			}

			return nil
		}

		parseRequiredTime := func(val interface{}) time.Time {
			if t := parseTime(val); t != nil {
				return *t
			}
			return time.Now()
		}

		// Create article from parsed data
		article := &models.Article{}

		// Parse IDs
		if id, ok := articleData["id"].(string); ok {
			if uuid, err := uuid.Parse(id); err == nil {
				article.ID = uuid
			}
		}
		if postIDVal, ok := articleData["post_id"].(string); ok {
			if uuid, err := uuid.Parse(postIDVal); err == nil {
				article.PostID = uuid
			}
		}

		// Parse strings
		if title, ok := articleData["title"].(string); ok {
			article.Title = title
		}
		if subtitle, ok := articleData["subtitle"].(string); ok && subtitle != "" {
			article.Subtitle = subtitle
		}
		if contentHTML, ok := articleData["content_html"].(string); ok {
			article.ContentHTML = contentHTML
		}
		if coverImageURL, ok := articleData["cover_image_url"].(string); ok && coverImageURL != "" {
			article.CoverImageURL = coverImageURL
		}
		if metaTitle, ok := articleData["meta_title"].(string); ok && metaTitle != "" {
			article.MetaTitle = metaTitle
		}
		if metaDescription, ok := articleData["meta_description"].(string); ok && metaDescription != "" {
			article.MetaDescription = metaDescription
		}
		if slug, ok := articleData["slug"].(string); ok {
			article.Slug = slug
		}
		if category, ok := articleData["category"].(string); ok && category != "" {
			article.Category = category
		}

		// Parse integers
		if readTime, ok := articleData["read_time_minutes"].(float64); ok {
			article.ReadTimeMinutes = int(readTime)
		}
		if viewsCount, ok := articleData["views_count"].(float64); ok {
			article.ViewsCount = int(viewsCount)
		}
		if readsCount, ok := articleData["reads_count"].(float64); ok {
			article.ReadsCount = int(readsCount)
		}

		// Parse timestamps
		article.CreatedAt = parseRequiredTime(articleData["created_at"])
		article.UpdatedAt = parseRequiredTime(articleData["updated_at"])

		post.Article = article
	}

	return nil
}

// getOrCreateHashtag gets or creates a hashtag and returns its ID
func (r *SupabasePostRepository) getOrCreateHashtag(ctx context.Context, tag string) (uuid.UUID, error) {
	// Normalize tag (lowercase, remove #)
	tag = strings.ToLower(strings.TrimPrefix(tag, "#"))

	// Try to get existing
	query := fmt.Sprintf("?tag=eq.%s&select=id", tag)
	data, err := r.makeRequest("GET", "hashtags", query, nil)
	if err == nil {
		var hashtags []struct {
			ID uuid.UUID `json:"id"`
		}
		if err := json.Unmarshal(data, &hashtags); err == nil && len(hashtags) > 0 {
			return hashtags[0].ID, nil
		}
	}

	// Create new hashtag
	newID := uuid.New()
	payload := map[string]interface{}{
		"id":  newID,
		"tag": tag,
	}

	_, err = r.makeRequest("POST", "hashtags", "", payload)
	if err != nil {
		// May have been created by another request (race condition)
		// Try to get again
		data, err := r.makeRequest("GET", "hashtags", query, nil)
		if err == nil {
			var hashtags []struct {
				ID uuid.UUID `json:"id"`
			}
			if err := json.Unmarshal(data, &hashtags); err == nil && len(hashtags) > 0 {
				return hashtags[0].ID, nil
			}
		}
		return uuid.Nil, err
	}

	return newID, nil
}

// extractHashtags extracts hashtags from text
func extractHashtags(text string) []string {
	re := regexp.MustCompile(`#([a-zA-Z0-9_]+)`)
	matches := re.FindAllStringSubmatch(text, -1)

	hashtags := make([]string, 0, len(matches))
	seen := make(map[string]bool)

	for _, match := range matches {
		if len(match) > 1 {
			tag := strings.ToLower(match[1])
			if !seen[tag] {
				hashtags = append(hashtags, tag)
				seen[tag] = true
			}
		}
	}

	return hashtags
}

// extractMentions extracts @mentions from text
func extractMentions(text string) []string {
	re := regexp.MustCompile(`@([a-zA-Z0-9_]+)`)
	matches := re.FindAllStringSubmatch(text, -1)

	mentions := make([]string, 0, len(matches))
	seen := make(map[string]bool)

	for _, match := range matches {
		if len(match) > 1 {
			username := strings.ToLower(match[1])
			if !seen[username] {
				mentions = append(mentions, username)
				seen[username] = true
			}
		}
	}

	return mentions
}
