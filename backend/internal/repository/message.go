package repository

import (
	"context"
	"upvista-community-backend/internal/models"

	"github.com/google/uuid"
)

// MessageRepository defines the interface for message data access
type MessageRepository interface {
	// ============================================
	// CONVERSATIONS
	// ============================================

	// GetOrCreateConversation finds existing conversation or creates new one
	GetOrCreateConversation(ctx context.Context, user1ID, user2ID uuid.UUID) (*models.Conversation, error)

	// GetConversation retrieves a conversation by ID with participants loaded
	GetConversation(ctx context.Context, conversationID uuid.UUID) (*models.Conversation, error)

	// GetUserConversations retrieves all conversations for a user (paginated)
	GetUserConversations(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*models.Conversation, error)

	// UpdateConversationTyping updates typing indicator status
	UpdateConversationTyping(ctx context.Context, conversationID, userID uuid.UUID, isTyping bool) error

	// MarkConversationAsRead resets unread count for a user in conversation
	MarkConversationAsRead(ctx context.Context, conversationID, userID uuid.UUID) error

	// DeleteConversation soft-deletes a conversation for a user
	DeleteConversation(ctx context.Context, conversationID, userID uuid.UUID) error

	// GetUnreadCount returns total unread message count for a user
	GetUnreadCount(ctx context.Context, userID uuid.UUID) (int, error)

	// ============================================
	// MESSAGES
	// ============================================

	// CreateMessage creates a new message
	CreateMessage(ctx context.Context, message *models.Message) error

	// GetMessage retrieves a single message by ID
	GetMessage(ctx context.Context, messageID uuid.UUID) (*models.Message, error)

	// GetConversationMessages retrieves messages for a conversation (paginated)
	// Returns messages in descending order (newest first) but should be reversed by caller
	GetConversationMessages(ctx context.Context, conversationID uuid.UUID, limit, offset int) ([]*models.Message, error)

	// UpdateMessageStatus updates the delivery/read status of a message
	UpdateMessageStatus(ctx context.Context, messageID uuid.UUID, status models.MessageStatus) error

	// MarkMessagesAsRead marks all unread messages in a conversation as read
	MarkMessagesAsRead(ctx context.Context, conversationID, readerID uuid.UUID) error

	// DeleteMessage soft-deletes a message for a user
	DeleteMessage(ctx context.Context, messageID, userID uuid.UUID) error

	// SearchMessages searches messages by content for a user
	SearchMessages(ctx context.Context, userID uuid.UUID, query string, limit, offset int) ([]*models.Message, error)

	// ============================================
	// REACTIONS
	// ============================================

	// AddReaction adds an emoji reaction to a message
	AddReaction(ctx context.Context, messageID, userID uuid.UUID, emoji string) (*models.MessageReaction, error)

	// RemoveReaction removes a reaction by ID
	RemoveReaction(ctx context.Context, reactionID uuid.UUID) error

	// RemoveUserReaction removes a user's reaction from a message
	RemoveUserReaction(ctx context.Context, messageID, userID uuid.UUID) error

	// GetMessageReactions retrieves all reactions for a message
	GetMessageReactions(ctx context.Context, messageID uuid.UUID) ([]*models.MessageReaction, error)

	// ============================================
	// STARRED MESSAGES
	// ============================================

	// StarMessage stars/bookmarks a message for a user
	StarMessage(ctx context.Context, messageID, userID uuid.UUID) error

	// UnstarMessage removes star from a message
	UnstarMessage(ctx context.Context, messageID, userID uuid.UUID) error

	// GetStarredMessages retrieves all starred messages for a user
	GetStarredMessages(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*models.Message, error)

	// IsMessageStarred checks if a message is starred by a user
	IsMessageStarred(ctx context.Context, messageID, userID uuid.UUID) (bool, error)
}
