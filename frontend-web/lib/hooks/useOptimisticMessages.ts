/**
 * useOptimisticMessages - Hook for instant message sending with optimistic UI
 * Messages appear immediately, then sync with server in background
 */

import { useState, useCallback, useMemo, useEffect } from 'react';
import { v4 as uuidv4 } from 'uuid';
import { messagesAPI, Message } from '../api/messages';
import { messageWS } from '../websocket/MessageWebSocket';

interface OptimisticMessage extends Message {
  tempId?: string;
  isSending?: boolean;
  sendError?: string;
}

interface UseOptimisticMessagesOptions {
  conversationId: string;
  initialMessages?: Message[];
}

export function useOptimisticMessages({
  conversationId,
  initialMessages = [],
}: UseOptimisticMessagesOptions) {
  // Real messages from server
  const [realMessages, setRealMessages] = useState<Message[]>(initialMessages);

  // Optimistic messages (not yet confirmed by server)
  const [optimisticMessages, setOptimisticMessages] = useState<Map<string, OptimisticMessage>>(
    new Map()
  );

  // ==================== SEND MESSAGE ====================

  /**
   * Send a text message with optimistic UI
   */
  const sendMessage = useCallback(
    async (content: string, replyToId?: string) => {
      const tempId = uuidv4();

      // Create optimistic message
      const optimisticMsg: OptimisticMessage = {
        id: tempId,
        conversation_id: conversationId,
        sender_id: '', // Will be populated by server
        content,
        message_type: 'text',
        status: 'sent',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        is_mine: true,
        isSending: true,
        tempId,
        reply_to_id: replyToId,
      };

      // 1. Add to UI immediately (INSTANT FEEDBACK)
      setOptimisticMessages((prev) => new Map(prev).set(tempId, optimisticMsg));

      try {
        // 2. Send to server in background
        const response = await messagesAPI.sendMessage(
          conversationId,
          content,
          tempId,
          replyToId
        );

        // 3. Replace optimistic with real message from server
        setOptimisticMessages((prev) => {
          const next = new Map(prev);
          next.delete(tempId);
          return next;
        });

        setRealMessages((prev) => [...prev, response.message]);

        console.log('[OptimisticUI] Message confirmed by server:', response.message.id);
      } catch (error) {
        // 4. Mark as failed
        console.error('[OptimisticUI] Failed to send message:', error);

        setOptimisticMessages((prev) => {
          const next = new Map(prev);
          const msg = next.get(tempId);
          if (msg) {
            msg.isSending = false;
            msg.sendError = 'Failed to send';
            msg.status = 'sent'; // Keep as sent, show error icon
            next.set(tempId, msg);
          }
          return next;
        });
      }
    },
    [conversationId]
  );

  /**
   * Send a message with attachment
   */
  const sendMessageWithAttachment = useCallback(
    async (
      content: string,
      attachmentUrl: string,
      attachmentName: string,
      attachmentSize: number,
      attachmentType: string,
      messageType: 'image' | 'audio' | 'file',
      replyToId?: string
    ) => {
      const tempId = uuidv4();

      const optimisticMsg: OptimisticMessage = {
        id: tempId,
        conversation_id: conversationId,
        sender_id: '',
        content,
        message_type: messageType,
        attachment_url: attachmentUrl,
        attachment_name: attachmentName,
        attachment_size: attachmentSize,
        attachment_type: attachmentType,
        status: 'sent',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        is_mine: true,
        isSending: true,
        tempId,
        reply_to_id: replyToId,
      };

      setOptimisticMessages((prev) => new Map(prev).set(tempId, optimisticMsg));

      try {
        // CRITICAL FIX: Actually send to server to persist in database!
        const response = await messagesAPI.sendMessageWithAttachment(
          conversationId,
          content,
          attachmentUrl,
          attachmentName,
          attachmentSize,
          attachmentType,
          messageType,
          replyToId
        );

        // Replace optimistic with real message from server
        setOptimisticMessages((prev) => {
          const next = new Map(prev);
          next.delete(tempId);
          return next;
        });

        setRealMessages((prev) => [...prev, response.message]);

        console.log('[OptimisticUI] ✅ Attachment message confirmed by server:', response.message.id);
      } catch (error) {
        console.error('[OptimisticUI] ❌ Failed to send attachment message:', error);
        
        // Mark as failed
        setOptimisticMessages((prev) => {
          const next = new Map(prev);
          const msg = next.get(tempId);
          if (msg) {
            msg.isSending = false;
            msg.sendError = 'Failed to send';
            next.set(tempId, msg);
          }
          return next;
        });
      }
    },
    [conversationId]
  );

  /**
   * Retry failed message
   */
  const retryMessage = useCallback(
    async (tempId: string) => {
      const msg = optimisticMessages.get(tempId);
      if (!msg) return;

      // Reset error state
      setOptimisticMessages((prev) => {
        const next = new Map(prev);
        const message = next.get(tempId);
        if (message) {
          message.isSending = true;
          message.sendError = undefined;
          next.set(tempId, message);
        }
        return next;
      });

      // Retry sending
      try {
        const response = await messagesAPI.sendMessage(
          conversationId,
          msg.content,
          tempId,
          msg.reply_to_id
        );

        setOptimisticMessages((prev) => {
          const next = new Map(prev);
          next.delete(tempId);
          return next;
        });

        setRealMessages((prev) => [...prev, response.message]);
      } catch (error) {
        setOptimisticMessages((prev) => {
          const next = new Map(prev);
          const message = next.get(tempId);
          if (message) {
            message.isSending = false;
            message.sendError = 'Failed to send';
            next.set(tempId, message);
          }
          return next;
        });
      }
    },
    [conversationId, optimisticMessages]
  );

  // ==================== WEBSOCKET LISTENERS ====================

  useEffect(() => {
    // Listen for new messages from WebSocket (INSTANT delivery)
    const unsubscribeNewMessage = messageWS.on('new_message', (message: Message) => {
      console.log('[OptimisticUI] ⚡ Received via WebSocket:', message.id, 'is_mine:', message.is_mine, 'timestamp:', message.created_at);
      if (message.conversation_id === conversationId && !message.is_mine) {
        // Add IMMEDIATELY to UI
        setRealMessages((prev) => {
          // Check if message already exists (CRITICAL for deduplication)
          if (prev.some((m) => m.id === message.id)) {
            console.log('[OptimisticUI] ⚠️ Duplicate message detected, ignoring:', message.id);
            return prev;
          }
          
          console.log('[OptimisticUI] ✅ Adding new message to chat, prev count:', prev.length);
          
          // Add to the END (newest messages at bottom)
          const updated = [...prev, message];
          console.log('[OptimisticUI] New messages array length:', updated.length);
          
          // Trigger scroll after React updates DOM
          requestAnimationFrame(() => {
            const scrollContainer = document.querySelector('[data-message-scroll]');
            if (scrollContainer) {
              scrollContainer.scrollTop = scrollContainer.scrollHeight;
            }
          });
          
          return updated;
        });

        // Trigger badge update immediately after adding message to chat
        console.log('[OptimisticUI] 📬 New message added, will be marked as read');
      }
    });

    // Listen for delivery status updates (INSTANT)
    const unsubscribeDelivered = messageWS.on('message_delivered', (data: any) => {
      console.log('[OptimisticUI] 📬 Received message_delivered event:', data);
      if (data.conversation_id === conversationId) {
        console.log('[OptimisticUI] ✅ Updating message', data.message_id, 'to delivered');
        setRealMessages((prev) =>
          prev.map((msg) =>
            msg.id === data.message_id
              ? { ...msg, status: 'delivered' as const, delivered_at: data.delivered_at }
              : msg
          )
        );
      } else {
        console.log('[OptimisticUI] ⏭️ Ignoring delivery (different conversation)');
      }
    });

    // Listen for read receipts (INSTANT)
    const unsubscribeRead = messageWS.on('message_read', (data: any) => {
      console.log('[OptimisticUI] 💙 Received message_read event:', data);
      if (data.conversation_id === conversationId) {
        console.log('[OptimisticUI] ✅ Marking all MY messages as read in conversation', conversationId);
        setRealMessages((prev) => {
          const updated = prev.map((msg) =>
            msg.is_mine && msg.status !== 'read'
              ? { ...msg, status: 'read' as const, read_at: data.read_at }
              : msg
          );
          const changedCount = updated.filter((msg, i) => msg.status !== prev[i].status).length;
          console.log('[OptimisticUI] 💙 Marked', changedCount, 'messages as read');
          return updated;
        });
      } else {
        console.log('[OptimisticUI] ⏭️ Ignoring read receipt (different conversation)');
      }
    });

    // Listen for reactions
    const unsubscribeReaction = messageWS.on('reaction', (data: any) => {
      if (data.message_id) {
        setRealMessages((prev) =>
          prev.map((msg) => {
            if (msg.id === data.message_id) {
              const reactions = msg.reactions || [];
              // Check if user already reacted
              const existingIndex = reactions.findIndex((r) => r.user_id === data.reaction.user_id);

              if (existingIndex > -1) {
                // Update existing reaction
                reactions[existingIndex] = data.reaction;
              } else {
                // Add new reaction
                reactions.push(data.reaction);
              }

              return { ...msg, reactions: [...reactions] };
            }
            return msg;
          })
        );
      }
    });

    // Listen for reaction removals (toggle off)
    const unsubscribeReactionRemoved = messageWS.on('reaction_removed', (data: any) => {
      console.log('[OptimisticUI] 🔄 Received reaction_removed event:', data);
      if (data.message_id && data.emoji) {
        setRealMessages((prev) =>
          prev.map((msg) => {
            if (msg.id === data.message_id) {
              return {
                ...msg,
                reactions: (msg.reactions || []).filter((r) => r.emoji !== data.emoji),
              };
            }
            return msg;
          })
        );
        console.log('[OptimisticUI] ✅ Removed reaction:', data.emoji, 'from message:', data.message_id);
      }
    });

    // Listen for message deletions
    const unsubscribeDeleted = messageWS.on('message_deleted', (data: any) => {
      console.log('[OptimisticUI] 🗑️ Received message_deleted event:', data);
      if (data.conversation_id === conversationId) {
        // Remove message from UI
        setRealMessages((prev) => prev.filter((msg) => msg.id !== data.message_id));
        console.log('[OptimisticUI] ✅ Removed deleted message:', data.message_id);
      }
    });

    return () => {
      unsubscribeNewMessage();
      unsubscribeDelivered();
      unsubscribeRead();
      unsubscribeReaction();
      unsubscribeReactionRemoved();
      unsubscribeDeleted();
    };
  }, [conversationId]);

  // ==================== COMBINED MESSAGES ====================

  /**
   * Merge real and optimistic messages, sorted by timestamp
   * ALWAYS sorted chronologically: oldest first, newest last
   */
  const allMessages = useMemo(() => {
    // Combine real and optimistic messages
    const combined = [
      ...realMessages,
      ...Array.from(optimisticMessages.values()),
    ];

    // Remove duplicates (same ID)
    const uniqueMap = new Map<string, Message>();
    combined.forEach(msg => {
      uniqueMap.set(msg.id, msg);
    });

    // Convert back to array and sort chronologically
    const uniqueMessages = Array.from(uniqueMap.values());
    
    const sorted = uniqueMessages.sort((a, b) => {
      const timeA = new Date(a.created_at).getTime();
      const timeB = new Date(b.created_at).getTime();
      return timeA - timeB; // Ascending order (oldest first)
    });
    
    console.log('[OptimisticUI] 📊 Total messages:', sorted.length, 'Oldest:', sorted[0]?.created_at, 'Newest:', sorted[sorted.length - 1]?.created_at);
    return sorted;
  }, [realMessages, optimisticMessages]);

  // ==================== ACTIONS ====================

  /**
   * Add a message received from WebSocket
   */
  const addMessage = useCallback((message: Message) => {
    setRealMessages((prev) => {
      if (prev.some((m) => m.id === message.id)) {
        return prev;
      }
      return [...prev, message];
    });
  }, []);

  /**
   * Update message status
   */
  const updateMessageStatus = useCallback((messageId: string, status: 'sent' | 'delivered' | 'read') => {
    setRealMessages((prev) =>
      prev.map((msg) =>
        msg.id === messageId ? { ...msg, status } : msg
      )
    );
  }, []);

  /**
   * Set initial messages (from API)
   */
  const setMessages = useCallback((messages: Message[]) => {
    setRealMessages(messages);
    setOptimisticMessages(new Map()); // Clear optimistic messages
  }, []);

  /**
   * Remove a message (for delete)
   */
  const removeMessage = useCallback((messageId: string) => {
    setRealMessages((prev) => prev.filter((m) => m.id !== messageId));
    setOptimisticMessages((prev) => {
      const next = new Map(prev);
      next.delete(messageId);
      return next;
    });
  }, []);

  return {
    messages: allMessages,
    realMessages,
    optimisticMessages: Array.from(optimisticMessages.values()),
    sendMessage,
    sendMessageWithAttachment,
    retryMessage,
    addMessage,
    updateMessageStatus,
    setMessages,
    removeMessage,
  };
}

