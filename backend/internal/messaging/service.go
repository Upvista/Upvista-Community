package messaging

import (
	"context"
	"fmt"
	"log"
	"time"

	"upvista-community-backend/internal/cache"
	"upvista-community-backend/internal/models"
	"upvista-community-backend/internal/repository"
	"upvista-community-backend/internal/websocket"

	"github.com/google/uuid"
)

// NotificationService interface for creating notifications
type NotificationService interface {
	CreateNotification(ctx context.Context, notification *models.Notification) error
}

// MessagingService handles all messaging business logic
type MessagingService struct {
	repo         repository.MessageRepository
	cache        *cache.MessageCacheService
	wsManager    *websocket.Manager
	userRepo     repository.UserRepository
	notifService NotificationService
}

// NewMessagingService creates a new messaging service
func NewMessagingService(
	repo repository.MessageRepository,
	cache *cache.MessageCacheService,
	wsManager *websocket.Manager,
	userRepo repository.UserRepository,
	notifService NotificationService,
) *MessagingService {
	return &MessagingService{
		repo:         repo,
		cache:        cache,
		wsManager:    wsManager,
		userRepo:     userRepo,
		notifService: notifService,
	}
}

// ============================================
// CONVERSATIONS
// ============================================

// GetConversations retrieves user's conversations with caching
func (s *MessagingService) GetConversations(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*models.Conversation, error) {
	// Try cache first (for initial load)
	if offset == 0 {
		cached, err := s.cache.GetCachedConversations(ctx, userID)
		if err == nil && cached != nil {
			log.Printf("[Messaging] Returning %d cached conversations for user %s", len(cached), userID)
			return cached, nil
		}
	}

	// Fetch from database
	conversations, err := s.repo.GetUserConversations(ctx, userID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to get conversations: %w", err)
	}

	// Enrich with presence information from Redis
	for _, conv := range conversations {
		if conv.OtherUser != nil {
			isOnline, lastSeen, _ := s.cache.GetUserPresence(ctx, conv.OtherUser.ID)
			conv.IsOnline = isOnline
			conv.LastSeen = &lastSeen
		}
	}

	// Cache for next time (only first page)
	if offset == 0 {
		s.cache.CacheConversations(ctx, userID, conversations)
	}

	return conversations, nil
}

// GetConversation retrieves a single conversation
func (s *MessagingService) GetConversation(ctx context.Context, conversationID, userID uuid.UUID) (*models.Conversation, error) {
	conversation, err := s.repo.GetConversation(ctx, conversationID)
	if err != nil {
		return nil, err
	}

	// Verify user is participant
	if conversation.Participant1ID != userID && conversation.Participant2ID != userID {
		return nil, fmt.Errorf("user is not a participant in this conversation")
	}

	// Set other user
	if conversation.Participant1ID == userID {
		conversation.OtherUser = conversation.Participant2
		conversation.UnreadCount = conversation.UnreadCountP1
	} else {
		conversation.OtherUser = conversation.Participant1
		conversation.UnreadCount = conversation.UnreadCountP2
	}

	// Get presence
	if conversation.OtherUser != nil {
		isOnline, lastSeen, _ := s.cache.GetUserPresence(ctx, conversation.OtherUser.ID)
		conversation.IsOnline = isOnline
		conversation.LastSeen = &lastSeen
	}

	return conversation, nil
}

// StartConversation creates or retrieves a conversation with another user
func (s *MessagingService) StartConversation(ctx context.Context, user1ID, user2ID uuid.UUID) (*models.Conversation, error) {
	conversation, err := s.repo.GetOrCreateConversation(ctx, user1ID, user2ID)
	if err != nil {
		return nil, err
	}

	// Set other user
	if conversation.Participant1ID == user1ID {
		conversation.OtherUser = conversation.Participant2
		conversation.UnreadCount = conversation.UnreadCountP1
	} else {
		conversation.OtherUser = conversation.Participant1
		conversation.UnreadCount = conversation.UnreadCountP2
	}

	// Invalidate cache
	s.cache.InvalidateUserConversations(ctx, user1ID)
	s.cache.InvalidateUserConversations(ctx, user2ID)

	return conversation, nil
}

// GetUnreadCount returns total unread message count
func (s *MessagingService) GetUnreadCount(ctx context.Context, userID uuid.UUID) (int, error) {
	// Try cache first
	total, err := s.cache.GetTotalUnread(ctx, userID)
	if err == nil && total > 0 {
		return total, nil
	}

	// Fall back to database
	return s.repo.GetUnreadCount(ctx, userID)
}

// ============================================
// MESSAGES
// ============================================

// SendMessage sends a new message in a conversation
func (s *MessagingService) SendMessage(ctx context.Context, conversationID, senderID uuid.UUID, req *models.MessageRequest) (*models.Message, error) {
	// Get conversation to find recipient
	conversation, err := s.repo.GetConversation(ctx, conversationID)
	if err != nil {
		return nil, fmt.Errorf("conversation not found: %w", err)
	}

	// Verify sender is participant
	if conversation.Participant1ID != senderID && conversation.Participant2ID != senderID {
		return nil, fmt.Errorf("sender is not a participant in this conversation")
	}

	// Determine recipient
	var recipientID uuid.UUID
	if conversation.Participant1ID == senderID {
		recipientID = conversation.Participant2ID
	} else {
		recipientID = conversation.Participant1ID
	}

	// Create message
	message := &models.Message{
		ConversationID: conversationID,
		SenderID:       senderID,
		Content:        req.Content,
		MessageType:    req.MessageType,
		AttachmentURL:  req.AttachmentURL,
		AttachmentName: req.AttachmentName,
		AttachmentSize: req.AttachmentSize,
		AttachmentType: req.AttachmentType,
		ReplyToID:      req.ReplyToID,
		Status:         models.MessageStatusSent,
		CreatedAt:      time.Now(),
	}

	// Save to database
	if err := s.repo.CreateMessage(ctx, message); err != nil {
		return nil, fmt.Errorf("failed to create message: %w", err)
	}

	// Update cache
	s.cache.PrependMessage(ctx, message)
	s.cache.IncrementUnread(ctx, conversationID, recipientID)

	// Invalidate conversation list cache
	s.cache.InvalidateUserConversations(ctx, senderID)
	s.cache.InvalidateUserConversations(ctx, recipientID)

	// Send via WebSocket to recipient
	go s.broadcastNewMessage(recipientID, message)

	// Mark as delivered if recipient is online
	if s.wsManager.IsUserConnected(recipientID) {
		go s.markAsDelivered(ctx, message.ID)
	}

	// Create notification for recipient (async to not block)
	if s.notifService != nil {
		go s.createMessageNotification(recipientID, senderID, message)
	}

	log.Printf("[Messaging] Message %s sent from %s to %s in conversation %s",
		message.ID, senderID, recipientID, conversationID)

	return message, nil
}

// GetMessages retrieves messages for a conversation with caching
func (s *MessagingService) GetMessages(ctx context.Context, conversationID, userID uuid.UUID, limit, offset int) ([]*models.Message, error) {
	// Verify user is participant
	conversation, err := s.repo.GetConversation(ctx, conversationID)
	if err != nil {
		return nil, err
	}

	if conversation.Participant1ID != userID && conversation.Participant2ID != userID {
		return nil, fmt.Errorf("user is not a participant in this conversation")
	}

	// Try cache for recent messages (offset = 0)
	if offset == 0 {
		cached, err := s.cache.GetCachedMessages(ctx, conversationID, limit)
		if err == nil && cached != nil && len(cached) > 0 {
			log.Printf("[Messaging] Returning %d cached messages for conversation %s", len(cached), conversationID)

			// Mark as read in background
			go s.markConversationAsRead(ctx, conversationID, userID)

			return cached, nil
		}
	}

	// Fetch from database
	messages, err := s.repo.GetConversationMessages(ctx, conversationID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to get messages: %w", err)
	}

	// Set IsMine field
	for _, msg := range messages {
		msg.IsMine = msg.SenderID == userID
	}

	// Cache if first page
	if offset == 0 {
		s.cache.CacheMessages(ctx, conversationID, messages)
	}

	// Mark as read in background
	go s.markConversationAsRead(ctx, conversationID, userID)

	return messages, nil
}

// MarkAsRead marks messages in a conversation as read
func (s *MessagingService) MarkAsRead(ctx context.Context, conversationID, userID uuid.UUID) error {
	// Update database
	if err := s.repo.MarkConversationAsRead(ctx, conversationID, userID); err != nil {
		return err
	}

	if err := s.repo.MarkMessagesAsRead(ctx, conversationID, userID); err != nil {
		return err
	}

	// Update cache
	s.cache.ResetUnread(ctx, conversationID, userID)

	// Broadcast read receipt to sender
	conversation, _ := s.repo.GetConversation(ctx, conversationID)
	if conversation != nil {
		var otherUserID uuid.UUID
		if conversation.Participant1ID == userID {
			otherUserID = conversation.Participant2ID
		} else {
			otherUserID = conversation.Participant1ID
		}

		go s.broadcastReadReceipt(otherUserID, conversationID)
	}

	log.Printf("[Messaging] Messages marked as read for user %s in conversation %s", userID, conversationID)
	return nil
}

// DeleteMessage soft-deletes a message for a user
func (s *MessagingService) DeleteMessage(ctx context.Context, messageID, userID uuid.UUID) error {
	// Get message first
	message, err := s.repo.GetMessage(ctx, messageID)
	if err != nil {
		return err
	}

	// Delete in database
	if err := s.repo.DeleteMessage(ctx, messageID, userID); err != nil {
		return err
	}

	// Invalidate cache
	s.cache.InvalidateConversationCache(ctx, message.ConversationID)

	log.Printf("[Messaging] Message %s deleted for user %s", messageID, userID)
	return nil
}

// SearchMessages searches messages by content
func (s *MessagingService) SearchMessages(ctx context.Context, userID uuid.UUID, query string, limit, offset int) ([]*models.Message, error) {
	return s.repo.SearchMessages(ctx, userID, query, limit, offset)
}

// ============================================
// TYPING INDICATORS
// ============================================

// StartTyping sets typing indicator for a user in a conversation
func (s *MessagingService) StartTyping(ctx context.Context, conversationID, userID uuid.UUID) error {
	// Update database
	if err := s.repo.UpdateConversationTyping(ctx, conversationID, userID, true); err != nil {
		return err
	}

	// Update cache
	s.cache.SetTyping(ctx, conversationID, userID)

	// Get other user
	conversation, err := s.repo.GetConversation(ctx, conversationID)
	if err != nil {
		return err
	}

	var otherUserID uuid.UUID
	if conversation.Participant1ID == userID {
		otherUserID = conversation.Participant2ID
	} else {
		otherUserID = conversation.Participant1ID
	}

	// Broadcast typing indicator
	go s.broadcastTyping(otherUserID, conversationID, userID, true)

	return nil
}

// StopTyping removes typing indicator
func (s *MessagingService) StopTyping(ctx context.Context, conversationID, userID uuid.UUID) error {
	// Update database
	if err := s.repo.UpdateConversationTyping(ctx, conversationID, userID, false); err != nil {
		return err
	}

	// Update cache
	s.cache.ClearTyping(ctx, conversationID, userID)

	// Get other user
	conversation, err := s.repo.GetConversation(ctx, conversationID)
	if err != nil {
		return err
	}

	var otherUserID uuid.UUID
	if conversation.Participant1ID == userID {
		otherUserID = conversation.Participant2ID
	} else {
		otherUserID = conversation.Participant1ID
	}

	// Broadcast stop typing
	go s.broadcastTyping(otherUserID, conversationID, userID, false)

	return nil
}

// ============================================
// REACTIONS
// ============================================

// AddReaction adds an emoji reaction to a message
func (s *MessagingService) AddReaction(ctx context.Context, messageID, userID uuid.UUID, emoji string) (*models.MessageReaction, error) {
	reaction, err := s.repo.AddReaction(ctx, messageID, userID, emoji)
	if err != nil {
		return nil, err
	}

	// Get message to find conversation
	message, _ := s.repo.GetMessage(ctx, messageID)
	if message != nil {
		// Invalidate cache
		s.cache.InvalidateConversationCache(ctx, message.ConversationID)

		// Broadcast reaction to other user
		conversation, _ := s.repo.GetConversation(ctx, message.ConversationID)
		if conversation != nil {
			var otherUserID uuid.UUID
			if conversation.Participant1ID == userID {
				otherUserID = conversation.Participant2ID
			} else {
				otherUserID = conversation.Participant1ID
			}

			go s.broadcastReaction(otherUserID, message.ConversationID, messageID, reaction)
		}
	}

	log.Printf("[Messaging] Reaction %s added to message %s by user %s", emoji, messageID, userID)
	return reaction, nil
}

// RemoveReaction removes a reaction from a message
func (s *MessagingService) RemoveReaction(ctx context.Context, messageID, userID uuid.UUID) error {
	// Get message first
	message, err := s.repo.GetMessage(ctx, messageID)
	if err != nil {
		return err
	}

	// Remove reaction
	if err := s.repo.RemoveUserReaction(ctx, messageID, userID); err != nil {
		return err
	}

	// Invalidate cache
	s.cache.InvalidateConversationCache(ctx, message.ConversationID)

	log.Printf("[Messaging] Reaction removed from message %s by user %s", messageID, userID)
	return nil
}

// ============================================
// STARRED MESSAGES
// ============================================

// StarMessage stars a message for a user
func (s *MessagingService) StarMessage(ctx context.Context, messageID, userID uuid.UUID) error {
	return s.repo.StarMessage(ctx, messageID, userID)
}

// UnstarMessage unstars a message
func (s *MessagingService) UnstarMessage(ctx context.Context, messageID, userID uuid.UUID) error {
	return s.repo.UnstarMessage(ctx, messageID, userID)
}

// GetStarredMessages retrieves starred messages
func (s *MessagingService) GetStarredMessages(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*models.Message, error) {
	return s.repo.GetStarredMessages(ctx, userID, limit, offset)
}

// ============================================
// PRESENCE
// ============================================

// SetUserOnline marks a user as online
func (s *MessagingService) SetUserOnline(ctx context.Context, userID uuid.UUID) error {
	return s.cache.SetUserOnline(ctx, userID)
}

// SetUserOffline marks a user as offline
func (s *MessagingService) SetUserOffline(ctx context.Context, userID uuid.UUID) error {
	return s.cache.SetUserOffline(ctx, userID)
}

// GetUserPresence retrieves a user's presence status
func (s *MessagingService) GetUserPresence(ctx context.Context, userID uuid.UUID) (bool, time.Time, error) {
	return s.cache.GetUserPresence(ctx, userID)
}

// GetMultiplePresence retrieves presence for multiple users
func (s *MessagingService) GetMultiplePresence(ctx context.Context, userIDs []uuid.UUID) (map[uuid.UUID]*models.PresenceInfo, error) {
	return s.cache.GetMultiplePresence(ctx, userIDs)
}

// ============================================
// WEBSOCKET HELPERS
// ============================================

func (s *MessagingService) broadcastNewMessage(recipientID uuid.UUID, message *models.Message) {
	envelope := models.WSMessageEnvelope{
		ID:             message.ID.String(),
		Type:           models.WSMessageTypeNewMessage,
		Channel:        "messaging",
		ConversationID: &message.ConversationID,
		Data:           message,
		Timestamp:      time.Now().Unix(),
	}

	s.wsManager.BroadcastToUserWithData(recipientID, envelope)
}

func (s *MessagingService) createMessageNotification(recipientID, senderID uuid.UUID, message *models.Message) {
	ctx := context.Background()

	// Don't send notification if recipient is online (they see it via WebSocket)
	if s.wsManager.IsUserConnected(recipientID) {
		log.Printf("[Messaging] Skipping notification - recipient %s is online", recipientID)
		return
	}

	// Get sender info
	sender, err := s.userRepo.GetUserByID(ctx, senderID)
	if err != nil {
		log.Printf("[Messaging] Failed to get sender info for notification: %v", err)
		return
	}

	// Truncate message content for notification
	content := message.Content
	if len(content) > 50 {
		content = content[:50] + "..."
	}
	if content == "" {
		content = "[Media]" // For audio/image without text
	}

	messageStr := fmt.Sprintf("%s: %s", sender.DisplayName, content)
	actionURL := fmt.Sprintf("/messages?conversationId=%s", message.ConversationID)

	notification := &models.Notification{
		UserID:     recipientID,
		Type:       models.NotificationMessage,
		Category:   models.CategoryMessages,
		Title:      "New Message",
		Message:    &messageStr,
		ActorID:    &senderID,
		TargetID:   &message.ID,
		TargetType: stringPtr("message"),
		ActionURL:  &actionURL,
		Metadata: map[string]interface{}{
			"conversation_id": message.ConversationID.String(),
			"message_id":      message.ID.String(),
		},
		CreatedAt: time.Now(),
		ExpiresAt: time.Now().AddDate(0, 0, 30), // Expire in 30 days
	}

	if err := s.notifService.CreateNotification(ctx, notification); err != nil {
		log.Printf("[Messaging] Failed to create message notification: %v", err)
	}
}

func stringPtr(s string) *string {
	return &s
}

func (s *MessagingService) broadcastTyping(recipientID, conversationID, typerID uuid.UUID, isTyping bool) {
	msgType := models.WSMessageTypeTyping
	if !isTyping {
		msgType = models.WSMessageTypeStopTyping
	}

	envelope := models.WSMessageEnvelope{
		ID:             uuid.New().String(),
		Type:           msgType,
		Channel:        "messaging",
		ConversationID: &conversationID,
		Data: models.TypingInfo{
			ConversationID: conversationID,
			UserID:         typerID,
			IsTyping:       isTyping,
		},
		Timestamp: time.Now().Unix(),
	}

	s.wsManager.BroadcastToUserWithData(recipientID, envelope)
}

func (s *MessagingService) broadcastReadReceipt(recipientID, conversationID uuid.UUID) {
	envelope := models.WSMessageEnvelope{
		ID:             uuid.New().String(),
		Type:           models.WSMessageTypeMessageRead,
		Channel:        "messaging",
		ConversationID: &conversationID,
		Data: map[string]interface{}{
			"conversation_id": conversationID,
			"read_at":         time.Now(),
		},
		Timestamp: time.Now().Unix(),
	}

	s.wsManager.BroadcastToUserWithData(recipientID, envelope)
}

func (s *MessagingService) broadcastReaction(recipientID, conversationID, messageID uuid.UUID, reaction *models.MessageReaction) {
	envelope := models.WSMessageEnvelope{
		ID:             uuid.New().String(),
		Type:           models.WSMessageTypeReaction,
		Channel:        "messaging",
		ConversationID: &conversationID,
		Data: map[string]interface{}{
			"message_id": messageID,
			"reaction":   reaction,
		},
		Timestamp: time.Now().Unix(),
	}

	s.wsManager.BroadcastToUserWithData(recipientID, envelope)
}

func (s *MessagingService) markAsDelivered(ctx context.Context, messageID uuid.UUID) {
	time.Sleep(100 * time.Millisecond) // Small delay to ensure message is received
	s.repo.UpdateMessageStatus(ctx, messageID, models.MessageStatusDelivered)
}

func (s *MessagingService) markConversationAsRead(ctx context.Context, conversationID, userID uuid.UUID) {
	s.MarkAsRead(ctx, conversationID, userID)
}
