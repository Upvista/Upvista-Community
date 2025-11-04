// ============================================
// TYPES
// ============================================

export interface Message {
  id: string;
  conversation_id: string;
  sender_id: string;
  content: string;
  message_type: 'text' | 'image' | 'file' | 'audio' | 'system';
  attachment_url?: string;
  attachment_name?: string;
  attachment_size?: number;
  attachment_type?: string;
  status: 'sent' | 'delivered' | 'read';
  delivered_at?: string;
  read_at?: string;
  reply_to_id?: string;
  created_at: string;
  updated_at: string;
  sender?: User;
  reply_to?: Message;
  reactions?: MessageReaction[];
  is_mine?: boolean;
  is_starred?: boolean;
}

export interface Conversation {
  id: string;
  participant1_id: string;
  participant2_id: string;
  last_message_content?: string;
  last_message_sender_id?: string;
  last_message_at?: string;
  unread_count_p1: number;
  unread_count_p2: number;
  created_at: string;
  updated_at: string;
  participant1?: User;
  participant2?: User;
  other_user?: User;
  unread_count?: number;
  is_typing?: boolean;
  is_online?: boolean;
  last_seen?: string;
}

export interface MessageReaction {
  id: string;
  message_id: string;
  user_id: string;
  emoji: string;
  created_at: string;
  user?: User;
}

export interface User {
  id: string;
  username: string;
  display_name?: string;
  avatar_url?: string;
  profile_picture?: string; // Backend field name
  is_verified?: boolean;
}

export interface PresenceInfo {
  user_id: string;
  is_online: boolean;
  last_seen?: string;
}

// ============================================
// API CLIENT
// ============================================

const API_BASE = '/api/proxy/v1';

async function fetchAPI(endpoint: string, options: RequestInit = {}) {
  const token = localStorage.getItem('token');
  
  const response = await fetch(`${API_BASE}${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token && { Authorization: `Bearer ${token}` }),
      ...options.headers,
    },
  });

  if (!response.ok) {
    throw new Error(`API Error: ${response.statusText}`);
  }

  return response.json();
}

export const messagesAPI = {
  // ==================== CONVERSATIONS ====================

  /**
   * Get list of user's conversations
   */
  async getConversations(limit = 20, offset = 0) {
    return fetchAPI(`/conversations?limit=${limit}&offset=${offset}`);
  },

  /**
   * Get single conversation by ID
   */
  async getConversation(conversationId: string) {
    return fetchAPI(`/conversations/${conversationId}`);
  },

  /**
   * Start or get existing conversation with a user
   */
  async startConversation(userId: string) {
    return fetchAPI(`/conversations/start/${userId}`, { method: 'POST' });
  },

  /**
   * Get total unread message count
   */
  async getUnreadCount() {
    return fetchAPI('/conversations/unread-count');
  },

  // ==================== MESSAGES ====================

  /**
   * Get messages in a conversation
   */
  async getMessages(conversationId: string, limit = 50, offset = 0) {
    return fetchAPI(`/conversations/${conversationId}/messages?limit=${limit}&offset=${offset}`);
  },

  /**
   * Send a text message
   */
  async sendMessage(
    conversationId: string,
    content: string,
    tempId?: string,
    replyToId?: string
  ) {
    return fetchAPI(`/conversations/${conversationId}/messages`, {
      method: 'POST',
      body: JSON.stringify({
        content,
        message_type: 'text',
        temp_id: tempId,
        reply_to_id: replyToId,
      }),
    });
  },

  /**
   * Send a message with attachment
   */
  async sendMessageWithAttachment(
    conversationId: string,
    content: string,
    attachmentUrl: string,
    attachmentName: string,
    attachmentSize: number,
    attachmentType: string,
    messageType: 'image' | 'audio' | 'file',
    replyToId?: string
  ) {
    return fetchAPI(`/conversations/${conversationId}/messages`, {
      method: 'POST',
      body: JSON.stringify({
        content,
        message_type: messageType,
        attachment_url: attachmentUrl,
        attachment_name: attachmentName,
        attachment_size: attachmentSize,
        attachment_type: attachmentType,
        reply_to_id: replyToId,
      }),
    });
  },

  /**
   * Mark all messages in a conversation as read
   */
  async markAsRead(conversationId: string) {
    return fetchAPI(`/conversations/${conversationId}/read`, { method: 'PATCH' });
  },

  /**
   * Delete a message (soft delete)
   */
  async deleteMessage(messageId: string) {
    return fetchAPI(`/messages/${messageId}`, { method: 'DELETE' });
  },

  /**
   * Search messages by content
   */
  async searchMessages(query: string, limit = 20, offset = 0) {
    return fetchAPI(`/messages/search?q=${encodeURIComponent(query)}&limit=${limit}&offset=${offset}`);
  },

  // ==================== MEDIA UPLOADS ====================

  /**
   * Upload an image attachment
   */
  async uploadImage(file: File, quality: 'standard' | 'hd' = 'standard') {
    const formData = new FormData();
    formData.append('image', file);

    const token = localStorage.getItem('token');
    const response = await fetch(`${API_BASE}/messages/upload-image?quality=${quality}`, {
      method: 'POST',
      headers: {
        ...(token && { Authorization: `Bearer ${token}` }),
      },
      body: formData,
    });

    if (!response.ok) throw new Error('Upload failed');
    return response.json();
  },

  /**
   * Upload an audio attachment (voice message)
   */
  async uploadAudio(blob: Blob, filename = 'voice-message.webm') {
    const formData = new FormData();
    formData.append('audio', blob, filename);

    const token = localStorage.getItem('token');
    const response = await fetch(`${API_BASE}/messages/upload-audio`, {
      method: 'POST',
      headers: {
        ...(token && { Authorization: `Bearer ${token}` }),
      },
      body: formData,
    });

    if (!response.ok) throw new Error('Upload failed');
    return response.json();
  },

  /**
   * Upload a generic file attachment
   */
  async uploadFile(file: File) {
    const formData = new FormData();
    formData.append('file', file);

    const token = localStorage.getItem('token');
    const response = await fetch(`${API_BASE}/messages/upload-file`, {
      method: 'POST',
      headers: {
        ...(token && { Authorization: `Bearer ${token}` }),
      },
      body: formData,
    });

    if (!response.ok) throw new Error('Upload failed');
    return response.json();
  },

  // ==================== REACTIONS ====================

  /**
   * Add emoji reaction to a message
   */
  async addReaction(messageId: string, emoji: string) {
    return fetchAPI(`/messages/${messageId}/reactions`, {
      method: 'POST',
      body: JSON.stringify({ emoji }),
    });
  },

  /**
   * Remove reaction from a message
   */
  async removeReaction(messageId: string) {
    return fetchAPI(`/messages/${messageId}/reactions`, { method: 'DELETE' });
  },

  // ==================== STARRED MESSAGES ====================

  /**
   * Star/bookmark a message
   */
  async starMessage(messageId: string) {
    return fetchAPI(`/messages/${messageId}/star`, { method: 'POST' });
  },

  /**
   * Unstar a message
   */
  async unstarMessage(messageId: string) {
    return fetchAPI(`/messages/${messageId}/star`, { method: 'DELETE' });
  },

  /**
   * Get all starred messages
   */
  async getStarredMessages(limit = 20, offset = 0) {
    return fetchAPI(`/messages/starred?limit=${limit}&offset=${offset}`);
  },

  // ==================== TYPING INDICATORS ====================

  /**
   * Start typing indicator
   */
  async startTyping(conversationId: string) {
    return fetchAPI(`/conversations/${conversationId}/typing/start`, { method: 'POST' });
  },

  /**
   * Stop typing indicator
   */
  async stopTyping(conversationId: string) {
    return fetchAPI(`/conversations/${conversationId}/typing/stop`, { method: 'POST' });
  },

  // ==================== PRESENCE ====================

  /**
   * Get user's online/offline status
   */
  async getUserPresence(userId: string) {
    return fetchAPI(`/users/${userId}/presence`);
  },

  /**
   * Get presence for multiple users
   */
  async getBulkPresence(userIds: string[]) {
    return fetchAPI(`/users/presence/bulk?user_ids=${userIds.join(',')}`);
  },
};

// ============================================
// HELPER FUNCTIONS
// ============================================

/**
 * Format time as relative (e.g., "2 minutes ago", "Yesterday")
 */
export function formatMessageTime(timestamp: string): string {
  const now = new Date();
  const date = new Date(timestamp);
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays < 7) return `${diffDays}d ago`;

  // Format as date
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

/**
 * Format full timestamp for message (e.g., "3:45 PM")
 */
export function formatMessageTimestamp(timestamp: string): string {
  const date = new Date(timestamp);
  return date.toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  });
}

/**
 * Format last seen timestamp (e.g., "last seen today at 3:45 PM", "last seen yesterday")
 */
export function formatLastSeen(timestamp: string): string {
  const now = new Date();
  const date = new Date(timestamp);
  const diffDays = Math.floor((now.getTime() - date.getTime()) / 86400000);

  const time = date.toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  });

  if (diffDays === 0) return `today at ${time}`;
  if (diffDays === 1) return `yesterday at ${time}`;
  if (diffDays < 7) return `${diffDays} days ago`;

  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

