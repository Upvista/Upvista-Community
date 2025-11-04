package repository

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"time"

	"upvista-community-backend/internal/models"

	"github.com/google/uuid"
)

// supabaseUser is a helper for unmarshaling Supabase User with string timestamps
type supabaseUser struct {
	ID             uuid.UUID `json:"id"`
	Email          string    `json:"email"`
	Username       string    `json:"username"`
	DisplayName    string    `json:"display_name"`
	ProfilePicture *string   `json:"profile_picture"`
	IsVerified     bool      `json:"is_verified"`
	IsActive       bool      `json:"is_active"`
	LastLoginAt    *string   `json:"last_login_at"`
	CreatedAt      string    `json:"created_at"`
	UpdatedAt      string    `json:"updated_at"`
}

func (su *supabaseUser) toUser() (*models.User, error) {
	if su == nil {
		return nil, nil
	}

	user := &models.User{
		ID:             su.ID,
		Email:          su.Email,
		Username:       su.Username,
		DisplayName:    su.DisplayName,
		ProfilePicture: su.ProfilePicture,
		IsVerified:     su.IsVerified,
		IsActive:       su.IsActive,
	}

	if su.LastLoginAt != nil && *su.LastLoginAt != "" {
		t, err := parseSupabaseTime(*su.LastLoginAt)
		if err != nil {
			return nil, fmt.Errorf("failed to parse last_login_at: %w", err)
		}
		user.LastLoginAt = &t
	}

	if su.CreatedAt != "" {
		t, err := parseSupabaseTime(su.CreatedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to parse created_at: %w", err)
		}
		user.CreatedAt = t
	}

	if su.UpdatedAt != "" {
		t, err := parseSupabaseTime(su.UpdatedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to parse updated_at: %w", err)
		}
		user.UpdatedAt = t
	}

	return user, nil
}

// supabaseMessage is a helper for unmarshaling Message with string timestamps
type supabaseMessage struct {
	ID             uuid.UUID            `json:"id"`
	ConversationID uuid.UUID            `json:"conversation_id"`
	SenderID       uuid.UUID            `json:"sender_id"`
	Content        string               `json:"content"`
	MessageType    models.MessageType   `json:"message_type"`
	AttachmentURL  *string              `json:"attachment_url"`
	AttachmentName *string              `json:"attachment_name"`
	AttachmentSize *int                 `json:"attachment_size"`
	AttachmentType *string              `json:"attachment_type"`
	Status         models.MessageStatus `json:"status"`
	DeliveredAt    *string              `json:"delivered_at"`
	ReadAt         *string              `json:"read_at"`
	DeletedBy      []string             `json:"deleted_by"`
	ReplyToID      *uuid.UUID           `json:"reply_to_id"`
	CreatedAt      string               `json:"created_at"`
	UpdatedAt      string               `json:"updated_at"`
	Sender         *supabaseUser        `json:"sender"`
	ReplyTo        *supabaseMessage     `json:"reply_to"`
}

func (sm *supabaseMessage) toMessage() (*models.Message, error) {
	if sm == nil {
		return nil, nil
	}

	msg := &models.Message{
		ID:             sm.ID,
		ConversationID: sm.ConversationID,
		SenderID:       sm.SenderID,
		Content:        sm.Content,
		MessageType:    sm.MessageType,
		AttachmentURL:  sm.AttachmentURL,
		AttachmentName: sm.AttachmentName,
		AttachmentSize: sm.AttachmentSize,
		AttachmentType: sm.AttachmentType,
		Status:         sm.Status,
		ReplyToID:      sm.ReplyToID,
	}

	// Convert sender
	if sm.Sender != nil {
		sender, err := sm.Sender.toUser()
		if err != nil {
			return nil, fmt.Errorf("failed to parse sender: %w", err)
		}
		msg.Sender = sender
	}

	// Convert reply-to message
	if sm.ReplyTo != nil {
		replyTo, err := sm.ReplyTo.toMessage()
		if err != nil {
			return nil, fmt.Errorf("failed to parse reply_to: %w", err)
		}
		msg.ReplyToMessage = replyTo
	}

	// Parse timestamps
	if sm.DeliveredAt != nil && *sm.DeliveredAt != "" {
		t, err := parseSupabaseTime(*sm.DeliveredAt)
		if err != nil {
			return nil, fmt.Errorf("failed to parse delivered_at: %w", err)
		}
		msg.DeliveredAt = &t
	}

	if sm.ReadAt != nil && *sm.ReadAt != "" {
		t, err := parseSupabaseTime(*sm.ReadAt)
		if err != nil {
			return nil, fmt.Errorf("failed to parse read_at: %w", err)
		}
		msg.ReadAt = &t
	}

	if sm.CreatedAt != "" {
		t, err := parseSupabaseTime(sm.CreatedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to parse created_at: %w", err)
		}
		msg.CreatedAt = t
	}

	if sm.UpdatedAt != "" {
		t, err := parseSupabaseTime(sm.UpdatedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to parse updated_at: %w", err)
		}
		msg.UpdatedAt = t
	}

	return msg, nil
}

// supabaseConversation is a helper struct for unmarshaling Supabase timestamps
type supabaseConversation struct {
	ID                  uuid.UUID     `json:"id"`
	Participant1ID      uuid.UUID     `json:"participant1_id"`
	Participant2ID      uuid.UUID     `json:"participant2_id"`
	LastMessageContent  *string       `json:"last_message_content"`
	LastMessageSenderID *uuid.UUID    `json:"last_message_sender_id"`
	LastMessageAt       *string       `json:"last_message_at"` // String to handle Supabase format
	UnreadCountP1       int           `json:"unread_count_p1"`
	UnreadCountP2       int           `json:"unread_count_p2"`
	P1Typing            bool          `json:"p1_typing"`
	P2Typing            bool          `json:"p2_typing"`
	P1TypingAt          *string       `json:"p1_typing_at"` // String to handle Supabase format
	P2TypingAt          *string       `json:"p2_typing_at"` // String to handle Supabase format
	CreatedAt           string        `json:"created_at"`   // String to handle Supabase format
	UpdatedAt           string        `json:"updated_at"`   // String to handle Supabase format
	Participant1        *supabaseUser `json:"participant1"`
	Participant2        *supabaseUser `json:"participant2"`
}

// parseSupabaseTime parses Supabase timestamp format (with or without timezone)
func parseSupabaseTime(s string) (time.Time, error) {
	if s == "" {
		return time.Time{}, nil
	}
	// Try RFC3339 first
	t, err := time.Parse(time.RFC3339, s)
	if err == nil {
		return t, nil
	}
	// Try without timezone (Supabase format)
	t, err = time.Parse("2006-01-02T15:04:05.999999", s)
	if err == nil {
		return t.UTC(), nil // Assume UTC
	}
	// Try without microseconds
	t, err = time.Parse("2006-01-02T15:04:05", s)
	if err == nil {
		return t.UTC(), nil
	}
	return time.Time{}, err
}

// toConversation converts supabaseConversation to models.Conversation
func (sc *supabaseConversation) toConversation() (*models.Conversation, error) {
	conv := &models.Conversation{
		ID:                  sc.ID,
		Participant1ID:      sc.Participant1ID,
		Participant2ID:      sc.Participant2ID,
		LastMessageContent:  sc.LastMessageContent,
		LastMessageSenderID: sc.LastMessageSenderID,
		UnreadCountP1:       sc.UnreadCountP1,
		UnreadCountP2:       sc.UnreadCountP2,
		P1Typing:            sc.P1Typing,
		P2Typing:            sc.P2Typing,
	}

	// Convert participant users
	if sc.Participant1 != nil {
		user1, err := sc.Participant1.toUser()
		if err != nil {
			return nil, fmt.Errorf("failed to parse participant1: %w", err)
		}
		conv.Participant1 = user1
	}

	if sc.Participant2 != nil {
		user2, err := sc.Participant2.toUser()
		if err != nil {
			return nil, fmt.Errorf("failed to parse participant2: %w", err)
		}
		conv.Participant2 = user2
	}

	// Parse timestamps
	if sc.LastMessageAt != nil && *sc.LastMessageAt != "" {
		t, err := parseSupabaseTime(*sc.LastMessageAt)
		if err != nil {
			return nil, fmt.Errorf("failed to parse last_message_at: %w", err)
		}
		conv.LastMessageAt = &t
	}

	if sc.P1TypingAt != nil && *sc.P1TypingAt != "" {
		t, err := parseSupabaseTime(*sc.P1TypingAt)
		if err != nil {
			return nil, fmt.Errorf("failed to parse p1_typing_at: %w", err)
		}
		conv.P1TypingAt = &t
	}

	if sc.P2TypingAt != nil && *sc.P2TypingAt != "" {
		t, err := parseSupabaseTime(*sc.P2TypingAt)
		if err != nil {
			return nil, fmt.Errorf("failed to parse p2_typing_at: %w", err)
		}
		conv.P2TypingAt = &t
	}

	if sc.CreatedAt != "" {
		t, err := parseSupabaseTime(sc.CreatedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to parse created_at: %w", err)
		}
		conv.CreatedAt = t
	}

	if sc.UpdatedAt != "" {
		t, err := parseSupabaseTime(sc.UpdatedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to parse updated_at: %w", err)
		}
		conv.UpdatedAt = t
	}

	return conv, nil
}

type supabaseMessageRepository struct {
	supabaseURL string
	apiKey      string
	httpClient  *http.Client
}

// NewSupabaseMessageRepository creates a new Supabase message repository using PostgREST
func NewSupabaseMessageRepository(supabaseURL, serviceKey string) (MessageRepository, error) {
	return &supabaseMessageRepository{
		supabaseURL: supabaseURL,
		apiKey:      serviceKey,
		httpClient:  &http.Client{Timeout: 30 * time.Second},
	}, nil
}

// Helper to build URLs
func (r *supabaseMessageRepository) conversationsURL(query url.Values) string {
	base := fmt.Sprintf("%s/rest/v1/conversations", r.supabaseURL)
	if len(query) > 0 {
		return fmt.Sprintf("%s?%s", base, query.Encode())
	}
	return base
}

func (r *supabaseMessageRepository) messagesURL(query url.Values) string {
	base := fmt.Sprintf("%s/rest/v1/messages", r.supabaseURL)
	if len(query) > 0 {
		return fmt.Sprintf("%s?%s", base, query.Encode())
	}
	return base
}

func (r *supabaseMessageRepository) reactionsURL(query url.Values) string {
	base := fmt.Sprintf("%s/rest/v1/message_reactions", r.supabaseURL)
	if len(query) > 0 {
		return fmt.Sprintf("%s?%s", base, query.Encode())
	}
	return base
}

func (r *supabaseMessageRepository) starredURL(query url.Values) string {
	base := fmt.Sprintf("%s/rest/v1/starred_messages", r.supabaseURL)
	if len(query) > 0 {
		return fmt.Sprintf("%s?%s", base, query.Encode())
	}
	return base
}

// Helper to set common headers
func (r *supabaseMessageRepository) setHeaders(req *http.Request, prefer string) {
	req.Header.Set("apikey", r.apiKey)
	req.Header.Set("Authorization", "Bearer "+r.apiKey)
	req.Header.Set("Content-Type", "application/json")
	if prefer != "" {
		req.Header.Set("Prefer", prefer)
	}
}

// ============================================
// CONVERSATIONS
// ============================================

// GetOrCreateConversation finds existing conversation or creates new one
func (r *supabaseMessageRepository) GetOrCreateConversation(ctx context.Context, user1ID, user2ID uuid.UUID) (*models.Conversation, error) {
	// Try to find existing conversation (check both directions)
	query := url.Values{}
	query.Set("or", fmt.Sprintf("(and(participant1_id.eq.%s,participant2_id.eq.%s),and(participant1_id.eq.%s,participant2_id.eq.%s))",
		user1ID, user2ID, user2ID, user1ID))
	query.Set("select", "*,participant1:participant1_id(*),participant2:participant2_id(*)")
	query.Set("limit", "1")

	req, _ := http.NewRequestWithContext(ctx, http.MethodGet, r.conversationsURL(query), nil)
	r.setHeaders(req, "")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var sbConversations []supabaseConversation
	if err := json.NewDecoder(resp.Body).Decode(&sbConversations); err != nil {
		return nil, err
	}

	if len(sbConversations) > 0 {
		// Convert and set other user
		conv, err := sbConversations[0].toConversation()
		if err != nil {
			return nil, err
		}
		if conv.Participant1ID == user1ID {
			conv.OtherUser = conv.Participant2
		} else {
			conv.OtherUser = conv.Participant1
		}
		return conv, nil
	}

	// Create new conversation
	newConv := map[string]interface{}{
		"participant1_id": user1ID.String(),
		"participant2_id": user2ID.String(),
	}

	payload, _ := json.Marshal(newConv)
	req, _ = http.NewRequestWithContext(ctx, http.MethodPost, r.conversationsURL(nil), bytes.NewReader(payload))
	r.setHeaders(req, "return=representation")

	resp, err = r.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var created []supabaseConversation
	if err := json.NewDecoder(resp.Body).Decode(&created); err != nil {
		return nil, err
	}

	if len(created) == 0 {
		return nil, fmt.Errorf("failed to create conversation")
	}

	return created[0].toConversation()
}

// GetConversation retrieves a conversation by ID
func (r *supabaseMessageRepository) GetConversation(ctx context.Context, conversationID uuid.UUID) (*models.Conversation, error) {
	query := url.Values{}
	query.Set("id", "eq."+conversationID.String())
	query.Set("select", "*,participant1:participant1_id(*),participant2:participant2_id(*)")

	req, _ := http.NewRequestWithContext(ctx, http.MethodGet, r.conversationsURL(query), nil)
	r.setHeaders(req, "")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var sbConversations []supabaseConversation
	if err := json.NewDecoder(resp.Body).Decode(&sbConversations); err != nil {
		return nil, err
	}

	if len(sbConversations) == 0 {
		return nil, fmt.Errorf("conversation not found")
	}

	return sbConversations[0].toConversation()
}

// GetUserConversations retrieves all conversations for a user
func (r *supabaseMessageRepository) GetUserConversations(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*models.Conversation, error) {
	query := url.Values{}
	// Filter: user is participant AND has at least one message (Instagram-style)
	query.Set("or", fmt.Sprintf("(participant1_id.eq.%s,participant2_id.eq.%s)", userID, userID))
	query.Set("last_message_at", "not.is.null") // Only conversations with messages
	query.Set("select", "*,participant1:participant1_id(*),participant2:participant2_id(*)")
	query.Set("order", "last_message_at.desc.nullslast,created_at.desc")
	query.Set("limit", fmt.Sprintf("%d", limit))
	query.Set("offset", fmt.Sprintf("%d", offset))

	req, _ := http.NewRequestWithContext(ctx, http.MethodGet, r.conversationsURL(query), nil)
	r.setHeaders(req, "")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var sbConversations []supabaseConversation
	if err := json.NewDecoder(resp.Body).Decode(&sbConversations); err != nil {
		return nil, err
	}

	// Convert and set OtherUser and UnreadCount for each conversation
	conversations := make([]*models.Conversation, 0, len(sbConversations))
	for _, sbConv := range sbConversations {
		conv, err := sbConv.toConversation()
		if err != nil {
			log.Printf("Failed to convert conversation: %v", err)
			continue
		}

		if conv.Participant1ID == userID {
			conv.OtherUser = conv.Participant2
			conv.UnreadCount = conv.UnreadCountP1
			conv.IsTyping = conv.P2Typing
		} else {
			conv.OtherUser = conv.Participant1
			conv.UnreadCount = conv.UnreadCountP2
			conv.IsTyping = conv.P1Typing
		}
		conversations = append(conversations, conv)
	}

	return conversations, nil
}

// UpdateConversationTyping updates typing indicator
func (r *supabaseMessageRepository) UpdateConversationTyping(ctx context.Context, conversationID, userID uuid.UUID, isTyping bool) error {
	// First get conversation to determine which participant
	conv, err := r.GetConversation(ctx, conversationID)
	if err != nil {
		return err
	}

	updates := make(map[string]interface{})
	now := time.Now().Format(time.RFC3339)

	if conv.Participant1ID == userID {
		updates["p1_typing"] = isTyping
		if isTyping {
			updates["p1_typing_at"] = now
		}
	} else {
		updates["p2_typing"] = isTyping
		if isTyping {
			updates["p2_typing_at"] = now
		}
	}

	payload, _ := json.Marshal(updates)
	query := url.Values{}
	query.Set("id", "eq."+conversationID.String())

	req, _ := http.NewRequestWithContext(ctx, http.MethodPatch, r.conversationsURL(query), bytes.NewReader(payload))
	r.setHeaders(req, "")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	return nil
}

// MarkConversationAsRead resets unread count for a user
func (r *supabaseMessageRepository) MarkConversationAsRead(ctx context.Context, conversationID, userID uuid.UUID) error {
	conv, err := r.GetConversation(ctx, conversationID)
	if err != nil {
		return err
	}

	updates := make(map[string]interface{})
	if conv.Participant1ID == userID {
		updates["unread_count_p1"] = 0
	} else {
		updates["unread_count_p2"] = 0
	}

	payload, _ := json.Marshal(updates)
	query := url.Values{}
	query.Set("id", "eq."+conversationID.String())

	req, _ := http.NewRequestWithContext(ctx, http.MethodPatch, r.conversationsURL(query), bytes.NewReader(payload))
	r.setHeaders(req, "")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	return nil
}

// DeleteConversation soft-deletes a conversation
func (r *supabaseMessageRepository) DeleteConversation(ctx context.Context, conversationID, userID uuid.UUID) error {
	// Note: Soft delete by adding user to deleted_by array would require RPC function
	// For now, just return nil (implement in Phase 2)
	log.Printf("[MessageRepo] DeleteConversation not yet implemented")
	return nil
}

// GetUnreadCount returns total unread count for a user
func (r *supabaseMessageRepository) GetUnreadCount(ctx context.Context, userID uuid.UUID) (int, error) {
	// Use RPC function from migration
	rpcURL := fmt.Sprintf("%s/rest/v1/rpc/get_user_total_unread_count", r.supabaseURL)

	payload := map[string]interface{}{
		"user_uuid": userID.String(),
	}

	body, _ := json.Marshal(payload)
	req, _ := http.NewRequestWithContext(ctx, http.MethodPost, rpcURL, bytes.NewReader(body))
	r.setHeaders(req, "")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()

	var count int
	if err := json.NewDecoder(resp.Body).Decode(&count); err != nil {
		return 0, err
	}

	return count, nil
}

// ============================================
// MESSAGES
// ============================================

// CreateMessage creates a new message
func (r *supabaseMessageRepository) CreateMessage(ctx context.Context, message *models.Message) error {
	payload := map[string]interface{}{
		"conversation_id": message.ConversationID.String(),
		"sender_id":       message.SenderID.String(),
		"content":         message.Content,
		"message_type":    string(message.MessageType),
		"status":          string(message.Status),
	}

	if message.AttachmentURL != nil {
		payload["attachment_url"] = *message.AttachmentURL
	}
	if message.AttachmentName != nil {
		payload["attachment_name"] = *message.AttachmentName
	}
	if message.AttachmentSize != nil {
		payload["attachment_size"] = *message.AttachmentSize
	}
	if message.AttachmentType != nil {
		payload["attachment_type"] = *message.AttachmentType
	}
	if message.ReplyToID != nil {
		payload["reply_to_id"] = message.ReplyToID.String()
	}

	body, _ := json.Marshal(payload)
	req, _ := http.NewRequestWithContext(ctx, http.MethodPost, r.messagesURL(nil), bytes.NewReader(body))
	r.setHeaders(req, "return=representation")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	var created []supabaseMessage
	if err := json.NewDecoder(resp.Body).Decode(&created); err != nil {
		return err
	}

	if len(created) > 0 {
		convertedMsg, err := created[0].toMessage()
		if err != nil {
			return fmt.Errorf("failed to convert created message: %w", err)
		}
		*message = *convertedMsg
	}

	return nil
}

// GetMessage retrieves a single message
func (r *supabaseMessageRepository) GetMessage(ctx context.Context, messageID uuid.UUID) (*models.Message, error) {
	query := url.Values{}
	query.Set("id", "eq."+messageID.String())
	query.Set("select", "*,sender:sender_id(*),reply_to:reply_to_id(*),reactions:message_reactions(*,user:user_id(*))")

	req, _ := http.NewRequestWithContext(ctx, http.MethodGet, r.messagesURL(query), nil)
	r.setHeaders(req, "")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var sbMessages []supabaseMessage
	if err := json.NewDecoder(resp.Body).Decode(&sbMessages); err != nil {
		return nil, err
	}

	if len(sbMessages) == 0 {
		return nil, fmt.Errorf("message not found")
	}

	return sbMessages[0].toMessage()
}

// GetConversationMessages retrieves messages for a conversation (paginated)
func (r *supabaseMessageRepository) GetConversationMessages(ctx context.Context, conversationID uuid.UUID, limit, offset int) ([]*models.Message, error) {
	query := url.Values{}
	query.Set("conversation_id", "eq."+conversationID.String())
	query.Set("select", "*,sender:sender_id(*),reply_to:reply_to_id(id,content,sender:sender_id(username,display_name)),reactions:message_reactions(*,user:user_id(*))")
	query.Set("order", "created_at.desc")
	query.Set("limit", fmt.Sprintf("%d", limit))
	query.Set("offset", fmt.Sprintf("%d", offset))

	req, _ := http.NewRequestWithContext(ctx, http.MethodGet, r.messagesURL(query), nil)
	r.setHeaders(req, "")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var sbMessages []*supabaseMessage
	if err := json.NewDecoder(resp.Body).Decode(&sbMessages); err != nil {
		return nil, err
	}

	// Convert messages
	messages := make([]*models.Message, 0, len(sbMessages))
	for _, sbMsg := range sbMessages {
		msg, err := sbMsg.toMessage()
		if err != nil {
			log.Printf("Failed to convert message: %v", err)
			continue
		}
		messages = append(messages, msg)
	}

	// Reverse to show oldest first
	for i, j := 0, len(messages)-1; i < j; i, j = i+1, j-1 {
		messages[i], messages[j] = messages[j], messages[i]
	}

	return messages, nil
}

// UpdateMessageStatus updates message status
func (r *supabaseMessageRepository) UpdateMessageStatus(ctx context.Context, messageID uuid.UUID, status models.MessageStatus) error {
	updates := map[string]interface{}{
		"status":     string(status),
		"updated_at": time.Now().Format(time.RFC3339),
	}

	if status == models.MessageStatusDelivered {
		updates["delivered_at"] = time.Now().Format(time.RFC3339)
	} else if status == models.MessageStatusRead {
		updates["read_at"] = time.Now().Format(time.RFC3339)
	}

	payload, _ := json.Marshal(updates)
	query := url.Values{}
	query.Set("id", "eq."+messageID.String())

	req, _ := http.NewRequestWithContext(ctx, http.MethodPatch, r.messagesURL(query), bytes.NewReader(payload))
	r.setHeaders(req, "")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	return nil
}

// MarkMessagesAsRead marks all unread messages in a conversation as read
func (r *supabaseMessageRepository) MarkMessagesAsRead(ctx context.Context, conversationID, readerID uuid.UUID) error {
	updates := map[string]interface{}{
		"status":     string(models.MessageStatusRead),
		"read_at":    time.Now().Format(time.RFC3339),
		"updated_at": time.Now().Format(time.RFC3339),
	}

	payload, _ := json.Marshal(updates)
	query := url.Values{}
	query.Set("conversation_id", "eq."+conversationID.String())
	query.Set("sender_id", "neq."+readerID.String())
	query.Set("status", "neq.read")

	req, _ := http.NewRequestWithContext(ctx, http.MethodPatch, r.messagesURL(query), bytes.NewReader(payload))
	r.setHeaders(req, "")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	return nil
}

// DeleteMessage soft-deletes a message for a user
func (r *supabaseMessageRepository) DeleteMessage(ctx context.Context, messageID, userID uuid.UUID) error {
	// Note: Soft delete requires RPC function or array manipulation
	// For Phase 1, mark implementation as TODO
	log.Printf("[MessageRepo] DeleteMessage not yet fully implemented")
	return nil
}

// SearchMessages searches messages by content
func (r *supabaseMessageRepository) SearchMessages(ctx context.Context, userID uuid.UUID, searchQuery string, limit, offset int) ([]*models.Message, error) {
	// Note: Full-text search requires RPC function or advanced PostgREST features
	// For Phase 1, return empty results
	log.Printf("[MessageRepo] SearchMessages not yet implemented")
	return []*models.Message{}, nil
}

// ============================================
// REACTIONS
// ============================================

// AddReaction adds an emoji reaction to a message
func (r *supabaseMessageRepository) AddReaction(ctx context.Context, messageID, userID uuid.UUID, emoji string) (*models.MessageReaction, error) {
	payload := map[string]interface{}{
		"message_id": messageID.String(),
		"user_id":    userID.String(),
		"emoji":      emoji,
	}

	body, _ := json.Marshal(payload)
	req, _ := http.NewRequestWithContext(ctx, http.MethodPost, r.reactionsURL(nil), bytes.NewReader(body))
	r.setHeaders(req, "return=representation,resolution=merge-duplicates")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var reactions []models.MessageReaction
	if err := json.NewDecoder(resp.Body).Decode(&reactions); err != nil {
		return nil, err
	}

	if len(reactions) == 0 {
		return nil, fmt.Errorf("failed to create reaction")
	}

	return &reactions[0], nil
}

// RemoveReaction removes a reaction by ID
func (r *supabaseMessageRepository) RemoveReaction(ctx context.Context, reactionID uuid.UUID) error {
	query := url.Values{}
	query.Set("id", "eq."+reactionID.String())

	req, _ := http.NewRequestWithContext(ctx, http.MethodDelete, r.reactionsURL(query), nil)
	r.setHeaders(req, "")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	return nil
}

// RemoveUserReaction removes a user's reaction from a message
func (r *supabaseMessageRepository) RemoveUserReaction(ctx context.Context, messageID, userID uuid.UUID) error {
	query := url.Values{}
	query.Set("message_id", "eq."+messageID.String())
	query.Set("user_id", "eq."+userID.String())

	req, _ := http.NewRequestWithContext(ctx, http.MethodDelete, r.reactionsURL(query), nil)
	r.setHeaders(req, "")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	return nil
}

// GetMessageReactions retrieves all reactions for a message
func (r *supabaseMessageRepository) GetMessageReactions(ctx context.Context, messageID uuid.UUID) ([]*models.MessageReaction, error) {
	query := url.Values{}
	query.Set("message_id", "eq."+messageID.String())
	query.Set("select", "*,user:user_id(*)")

	req, _ := http.NewRequestWithContext(ctx, http.MethodGet, r.reactionsURL(query), nil)
	r.setHeaders(req, "")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var reactions []*models.MessageReaction
	if err := json.NewDecoder(resp.Body).Decode(&reactions); err != nil {
		return nil, err
	}

	return reactions, nil
}

// ============================================
// STARRED MESSAGES
// ============================================

// StarMessage stars a message for a user
func (r *supabaseMessageRepository) StarMessage(ctx context.Context, messageID, userID uuid.UUID) error {
	payload := map[string]interface{}{
		"user_id":    userID.String(),
		"message_id": messageID.String(),
	}

	body, _ := json.Marshal(payload)
	req, _ := http.NewRequestWithContext(ctx, http.MethodPost, r.starredURL(nil), bytes.NewReader(body))
	r.setHeaders(req, "resolution=ignore-duplicates")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	return nil
}

// UnstarMessage removes star from a message
func (r *supabaseMessageRepository) UnstarMessage(ctx context.Context, messageID, userID uuid.UUID) error {
	query := url.Values{}
	query.Set("user_id", "eq."+userID.String())
	query.Set("message_id", "eq."+messageID.String())

	req, _ := http.NewRequestWithContext(ctx, http.MethodDelete, r.starredURL(query), nil)
	r.setHeaders(req, "")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	return nil
}

// GetStarredMessages retrieves all starred messages for a user
func (r *supabaseMessageRepository) GetStarredMessages(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*models.Message, error) {
	query := url.Values{}
	query.Set("user_id", "eq."+userID.String())
	query.Set("select", "message:message_id(*,sender:sender_id(*),reply_to:reply_to_id(*),reactions:message_reactions(*))")
	query.Set("order", "starred_at.desc")
	query.Set("limit", fmt.Sprintf("%d", limit))
	query.Set("offset", fmt.Sprintf("%d", offset))

	req, _ := http.NewRequestWithContext(ctx, http.MethodGet, r.starredURL(query), nil)
	r.setHeaders(req, "")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var starred []struct {
		Message *supabaseMessage `json:"message"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&starred); err != nil {
		return nil, err
	}

	messages := make([]*models.Message, 0, len(starred))
	for _, s := range starred {
		if s.Message != nil {
			msg, err := s.Message.toMessage()
			if err != nil {
				log.Printf("Failed to convert starred message: %v", err)
				continue
			}
			msg.IsStarred = true
			messages = append(messages, msg)
		}
	}

	return messages, nil
}

// IsMessageStarred checks if a message is starred by a user
func (r *supabaseMessageRepository) IsMessageStarred(ctx context.Context, messageID, userID uuid.UUID) (bool, error) {
	query := url.Values{}
	query.Set("user_id", "eq."+userID.String())
	query.Set("message_id", "eq."+messageID.String())
	query.Set("select", "id")

	req, _ := http.NewRequestWithContext(ctx, http.MethodGet, r.starredURL(query), nil)
	r.setHeaders(req, "")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return false, err
	}
	defer resp.Body.Close()

	var results []map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&results); err != nil {
		return false, err
	}

	return len(results) > 0, nil
}
