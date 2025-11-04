import { useState, useEffect } from 'react';
import { messagesAPI } from '../api/messages';
import { messageWS } from '../websocket/MessageWebSocket';

export function useUnreadMessages() {
  const [unreadCount, setUnreadCount] = useState(0);

  useEffect(() => {
    // Load initial count
    loadUnreadCount();

    // Listen for new messages
    const unsubscribe = messageWS.on('new_message', (message: any) => {
      // Increment count INSTANTLY if message is not from me
      if (!message.is_mine) {
        setUnreadCount(prev => prev + 1);
      }
    });

    // Listen for messages being read via WebSocket
    const unsubscribeRead = messageWS.on('message_read', (data: any) => {
      // INSTANT update - verify with server in background
      loadUnreadCount();
    });

    // Listen for custom event from ChatWindow (optimistic update)
    const handleMarkedRead = (e: any) => {
      // INSTANT update - fetch actual count immediately
      loadUnreadCount();
    };
    window.addEventListener('messages_marked_read', handleMarkedRead);

    return () => {
      unsubscribe();
      unsubscribeRead();
      window.removeEventListener('messages_marked_read', handleMarkedRead);
    };
  }, []);

  const loadUnreadCount = async () => {
    try {
      const response = await messagesAPI.getUnreadCount();
      if (response.success) {
        setUnreadCount(response.total || 0);
      }
    } catch (error) {
      console.error('Failed to load unread count:', error);
    }
  };

  return { unreadCount, refreshCount: loadUnreadCount };
}

