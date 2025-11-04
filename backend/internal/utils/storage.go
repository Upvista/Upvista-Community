package utils

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"path/filepath"
	"strings"
	"time"

	"upvista-community-backend/internal/config"
	apperr "upvista-community-backend/pkg/errors"

	"github.com/google/uuid"
)

// StorageService handles file storage operations with Supabase Storage
type StorageService struct {
	config      *config.StorageConfig
	supabaseURL string
	apiKey      string
	http        *http.Client
}

// NewStorageService creates a new storage service
func NewStorageService(storageConfig *config.StorageConfig, supabaseURL, apiKey string) *StorageService {
	return &StorageService{
		config:      storageConfig,
		supabaseURL: supabaseURL,
		apiKey:      apiKey,
		http:        &http.Client{Timeout: 30 * time.Second},
	}
}

// UploadProfilePicture uploads a profile picture to Supabase Storage
func (s *StorageService) UploadProfilePicture(ctx context.Context, userID uuid.UUID, file multipart.File, header *multipart.FileHeader) (string, error) {
	// Validate file size
	if header.Size > s.config.MaxFileSize {
		return "", apperr.NewAppError(400, fmt.Sprintf("File size exceeds maximum allowed size of %d bytes", s.config.MaxFileSize))
	}

	// Validate file type
	contentType := header.Header.Get("Content-Type")
	if !s.isAllowedFileType(contentType) {
		return "", apperr.NewAppError(400, fmt.Sprintf("File type %s is not allowed. Allowed types: %s", contentType, s.config.AllowedFileTypes))
	}

	// Generate unique filename
	ext := filepath.Ext(header.Filename)
	filename := fmt.Sprintf("%s/%s%s", userID.String(), uuid.New().String(), ext)

	// Read file content
	fileBytes, err := io.ReadAll(file)
	if err != nil {
		return "", apperr.ErrInternalServer
	}

	// Upload to Supabase Storage
	uploadURL := fmt.Sprintf("%s/storage/v1/object/%s/%s", s.supabaseURL, s.config.BucketName, filename)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, uploadURL, bytes.NewReader(fileBytes))
	if err != nil {
		return "", apperr.ErrInternalServer
	}

	req.Header.Set("apikey", s.apiKey)
	req.Header.Set("Authorization", "Bearer "+s.apiKey)
	req.Header.Set("Content-Type", contentType)

	resp, err := s.http.Do(req)
	if err != nil {
		return "", apperr.ErrInternalServer
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return "", apperr.NewAppError(resp.StatusCode, fmt.Sprintf("Failed to upload file: %s", string(bodyBytes)))
	}

	// Get public URL
	publicURL := fmt.Sprintf("%s/storage/v1/object/public/%s/%s", s.supabaseURL, s.config.BucketName, filename)

	return publicURL, nil
}

// UploadFile uploads a file to Supabase Storage with custom bucket and path
func (s *StorageService) UploadFile(ctx context.Context, bucketName, filePath string, file io.Reader, contentType string) (string, error) {
	// Read file content
	fileBytes, err := io.ReadAll(file)
	if err != nil {
		return "", fmt.Errorf("failed to read file: %w", err)
	}

	// Upload to Supabase Storage
	uploadURL := fmt.Sprintf("%s/storage/v1/object/%s/%s", s.supabaseURL, bucketName, filePath)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, uploadURL, bytes.NewReader(fileBytes))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("apikey", s.apiKey)
	req.Header.Set("Authorization", "Bearer "+s.apiKey)
	req.Header.Set("Content-Type", contentType)

	resp, err := s.http.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to upload file: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("upload failed with status %d: %s", resp.StatusCode, string(bodyBytes))
	}

	// Get public URL
	publicURL := fmt.Sprintf("%s/storage/v1/object/public/%s/%s", s.supabaseURL, bucketName, filePath)

	return publicURL, nil
}

// DeleteProfilePicture deletes a profile picture from Supabase Storage
func (s *StorageService) DeleteProfilePicture(ctx context.Context, pictureURL string) error {
	// Extract filename from URL
	// URL format: https://xxx.supabase.co/storage/v1/object/public/bucket/filename
	parts := strings.Split(pictureURL, "/"+s.config.BucketName+"/")
	if len(parts) < 2 {
		return apperr.NewAppError(400, "Invalid picture URL")
	}
	filename := parts[1]

	deleteURL := fmt.Sprintf("%s/storage/v1/object/%s/%s", s.supabaseURL, s.config.BucketName, filename)

	req, err := http.NewRequestWithContext(ctx, http.MethodDelete, deleteURL, nil)
	if err != nil {
		return apperr.ErrInternalServer
	}

	req.Header.Set("apikey", s.apiKey)
	req.Header.Set("Authorization", "Bearer "+s.apiKey)

	resp, err := s.http.Do(req)
	if err != nil {
		return apperr.ErrInternalServer
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		// Ignore 404 errors (file might already be deleted)
		if resp.StatusCode != 404 {
			bodyBytes, _ := io.ReadAll(resp.Body)
			return apperr.NewAppError(resp.StatusCode, fmt.Sprintf("Failed to delete file: %s", string(bodyBytes)))
		}
	}

	return nil
}

// isAllowedFileType checks if the file type is allowed
func (s *StorageService) isAllowedFileType(contentType string) bool {
	allowedTypes := strings.Split(s.config.AllowedFileTypes, ",")
	for _, allowedType := range allowedTypes {
		if strings.TrimSpace(allowedType) == contentType {
			return true
		}
	}
	return false
}

// CreateBucket creates a storage bucket in Supabase (one-time setup)
func (s *StorageService) CreateBucket(ctx context.Context) error {
	createURL := fmt.Sprintf("%s/storage/v1/bucket", s.supabaseURL)

	bucketData := map[string]interface{}{
		"id":                 s.config.BucketName,
		"name":               s.config.BucketName,
		"public":             true,
		"file_size_limit":    s.config.MaxFileSize,
		"allowed_mime_types": strings.Split(s.config.AllowedFileTypes, ","),
	}

	body, err := json.Marshal(bucketData)
	if err != nil {
		return apperr.ErrInternalServer
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, createURL, bytes.NewReader(body))
	if err != nil {
		return apperr.ErrInternalServer
	}

	req.Header.Set("apikey", s.apiKey)
	req.Header.Set("Authorization", "Bearer "+s.apiKey)
	req.Header.Set("Content-Type", "application/json")

	resp, err := s.http.Do(req)
	if err != nil {
		return apperr.ErrInternalServer
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 300 {
		// Bucket might already exist, which is fine
		if resp.StatusCode != 409 {
			bodyBytes, _ := io.ReadAll(resp.Body)
			return apperr.NewAppError(resp.StatusCode, fmt.Sprintf("Failed to create bucket: %s", string(bodyBytes)))
		}
	}

	return nil
}
