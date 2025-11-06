/**
 * useOptimisticMessages - Hook for instant message sending with optimistic UI
 * Messages appear immediately, then sync with server in background
 */

import { useState, useCallback, useMemo, useEffect } from 'react';
import { v4 as uuidv4 } from 'uuid';
import { messagesAPI, Message } from '../api/messages';
import { messageWS } from '../websocket/MessageWebSocket';
import { offlineQueue, QueuedMessage } from '../utils/offlineQueue';
import { messageCache } from '../utils/messageCache';

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
   * Send a text message with optimistic UI + offline queue
   */
  const sendMessage = useCallback(
    async (content: string, replyToId?: string) => {
      const tempId = uuidv4();
      const isOnline = navigator.onLine;

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
        temp_id: tempId,
        send_state: isOnline ? 'sending' : 'queued',
        retry_count: 0,
        reply_to_id: replyToId,
      };

      // 1. Add to UI immediately (INSTANT FEEDBACK)
      setOptimisticMessages((prev) => new Map(prev).set(tempId, optimisticMsg));

      // 2. If offline, add to queue and return
      if (!isOnline) {
        console.log('[OptimisticUI] 📴 Offline - queuing message:', tempId);
        try {
          await offlineQueue.addToQueue({
            id: tempId,
            conversationId,
            content,
            messageType: 'text',
            replyToId,
            timestamp: Date.now(),
            retryCount: 0,
          });

          // Update to queued state
          setOptimisticMessages((prev) => {
            const next = new Map(prev);
            const msg = next.get(tempId);
            if (msg) {
              msg.send_state = 'queued';
              msg.isSending = false;
              next.set(tempId, msg);
            }
            return next;
          });
        } catch (error) {
          console.error('[OptimisticUI] Failed to queue message:', error);
        }
        return;
      }

      try {
        // 3. Send to server in background
        const response = await messagesAPI.sendMessage(
          conversationId,
          content,
          tempId,
          replyToId
        );

        // 4. Replace optimistic with real message from server
        setOptimisticMessages((prev) => {
          const next = new Map(prev);
          next.delete(tempId);
          return next;
        });

        setRealMessages((prev) => [...prev, response.message]);

        console.log('[OptimisticUI] ✅ Message confirmed by server:', response.message.id);
      } catch (error) {
        // 5. Mark as failed - can be retried
        console.error('[OptimisticUI] ❌ Failed to send message:', error);

        setOptimisticMessages((prev) => {
          const next = new Map(prev);
          const msg = next.get(tempId);
          if (msg) {
            msg.isSending = false;
            msg.send_state = 'failed';
            msg.sendError = error instanceof Error ? error.message : 'Failed to send';
            msg.send_error = msg.sendError;
            msg.retry_count = (msg.retry_count || 0);
            next.set(tempId, msg);
          }
          return next;
        });

        // Add to offline queue for retry
        try {
          await offlineQueue.addToQueue({
            id: tempId,
            conversationId,
            content,
            messageType: 'text',
            replyToId,
            timestamp: Date.now(),
            retryCount: 0,
            lastError: error instanceof Error ? error.message : 'Failed to send',
          });
        } catch (queueError) {
          console.error('[OptimisticUI] Failed to queue failed message:', queueError);
        }
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
      messageType: 'image' | 'audio' | 'file' | 'video',
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
      if (!msg) {
        console.warn('[OptimisticUI] Message not found for retry:', tempId);
        return;
      }

      console.log('[OptimisticUI] 🔄 Retrying message:', tempId);

      // Reset error state and mark as sending
      setOptimisticMessages((prev) => {
        const next = new Map(prev);
        const message = next.get(tempId);
        if (message) {
          message.isSending = true;
          message.send_state = 'sending';
          message.sendError = undefined;
          message.send_error = undefined;
          message.retry_count = (message.retry_count || 0) + 1;
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

        // Success - remove from optimistic and add to real
        setOptimisticMessages((prev) => {
          const next = new Map(prev);
          next.delete(tempId);
          return next;
        });

        setRealMessages((prev) => [...prev, response.message]);

        // Remove from offline queue on success
        try {
          await offlineQueue.removeFromQueue(tempId);
          console.log('[OptimisticUI] ✅ Removed message from offline queue:', tempId);
        } catch (error) {
          console.warn('[OptimisticUI] Failed to remove from queue:', error);
        }
      } catch (error) {
        console.error('[OptimisticUI] ❌ Retry failed:', error);
        
        setOptimisticMessages((prev) => {
          const next = new Map(prev);
          const message = next.get(tempId);
          if (message) {
            message.isSending = false;
            message.send_state = 'failed';
            message.sendError = error instanceof Error ? error.message : 'Failed to send';
            message.send_error = message.sendError;
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
          
          // Update cache in background
          messageCache.addMessage(conversationId, message).catch(err => 
            console.error('[OptimisticUI] Failed to cache new message:', err)
          );
          
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
        
        // Remove from cache
        messageCache.removeMessage(conversationId, data.message_id).catch(err =>
          console.error('[OptimisticUI] Failed to remove from cache:', err)
        );
        
        console.log('[OptimisticUI] ✅ Removed deleted message:', data.message_id);
      }
    });

    // Listen for message edits
    const unsubscribeEdited = messageWS.on('message_edited', (data: any) => {
      console.log('[OptimisticUI] ✏️ Received message_edited event:', data);
      if (data.message && data.message.conversation_id === conversationId) {
        const editedMessage = data.message;
        setRealMessages((prev) =>
          prev.map((msg) => {
            if (msg.id === editedMessage.id) {
              return {
                ...msg,
                content: editedMessage.content,
                edited_at: editedMessage.edited_at,
                edit_count: editedMessage.edit_count,
                original_content: editedMessage.original_content,
              };
            }
            return msg;
          })
        );
        console.log('[OptimisticUI] ✅ Updated edited message:', editedMessage.id);
      }
    });

    // Listen for message pins
    const unsubscribePinned = messageWS.on('message_pinned', (data: any) => {
      console.log('[OptimisticUI] 📌 Received message_pinned event:', data);
      if (data.message_id) {
        setRealMessages((prev) =>
          prev.map((msg) => {
            if (msg.id === data.message_id) {
              return {
                ...msg,
                is_pinned: true,
                pinned_at: new Date().toISOString(),
              };
            }
            return msg;
          })
        );
      }
    });

    // Listen for message unpins
    const unsubscribeUnpinned = messageWS.on('message_unpinned', (data: any) => {
      console.log('[OptimisticUI] 📌 Received message_unpinned event:', data);
      if (data.message_id) {
        setRealMessages((prev) =>
          prev.map((msg) => {
            if (msg.id === data.message_id) {
              return {
                ...msg,
                is_pinned: false,
                pinned_at: undefined,
              };
            }
            return msg;
          })
        );
      }
    });

    return () => {
      unsubscribeNewMessage();
      unsubscribeDelivered();
      unsubscribeRead();
      unsubscribeReaction();
      unsubscribeReactionRemoved();
      unsubscribeDeleted();
      unsubscribeEdited();
      unsubscribePinned();
      unsubscribeUnpinned();
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

  // ==================== OFFLINE QUEUE SYNC ====================

  /**
   * Process offline queue - send all queued messages
   */
  const processOfflineQueue = useCallback(async () => {
    try {
      const queuedMessages = await offlineQueue.getQueuedMessages(conversationId);
      
      if (queuedMessages.length === 0) {
        console.log('[OptimisticUI] No queued messages to process');
        return;
      }

      console.log('[OptimisticUI] 📤 Processing', queuedMessages.length, 'queued messages');

      for (const queued of queuedMessages) {
        // Update optimistic message to "sending"
        setOptimisticMessages((prev) => {
          const next = new Map(prev);
          const msg = next.get(queued.id);
          if (msg) {
            msg.send_state = 'sending';
            msg.isSending = true;
            next.set(queued.id, msg);
          }
          return next;
        });

        // Try to send
        try {
          const response = await messagesAPI.sendMessage(
            conversationId,
            queued.content,
            queued.id,
            queued.replyToId
          );

          // Success - remove from queue and optimistic, add to real
          await offlineQueue.removeFromQueue(queued.id);
          
          setOptimisticMessages((prev) => {
            const next = new Map(prev);
            next.delete(queued.id);
            return next;
          });

          setRealMessages((prev) => [...prev, response.message]);
          console.log('[OptimisticUI] ✅ Queued message sent:', queued.id);
        } catch (error) {
          console.error('[OptimisticUI] ❌ Failed to send queued message:', error);
          
          // Mark as failed
          setOptimisticMessages((prev) => {
            const next = new Map(prev);
            const msg = next.get(queued.id);
            if (msg) {
              msg.isSending = false;
              msg.send_state = 'failed';
              msg.sendError = error instanceof Error ? error.message : 'Failed to send';
              msg.send_error = msg.sendError;
              next.set(queued.id, msg);
            }
            return next;
          });

          // Update retry count in queue
          await offlineQueue.updateMessage({
            ...queued,
            retryCount: queued.retryCount + 1,
            lastError: error instanceof Error ? error.message : 'Failed to send',
          });
        }
      }
    } catch (error) {
      console.error('[OptimisticUI] Error processing offline queue:', error);
    }
  }, [conversationId]);

  // Listen for network coming back online
  useEffect(() => {
    const handleOnline = () => {
      console.log('[OptimisticUI] 🌐 Network restored - processing queue');
      processOfflineQueue();
    };

    window.addEventListener('network_online', handleOnline);
    
    // Also check on mount if there are queued messages
    if (navigator.onLine) {
      processOfflineQueue();
    }

    return () => {
      window.removeEventListener('network_online', handleOnline);
    };
  }, [processOfflineQueue]);

  return {
    messages: allMessages,
    realMessages,
    optimisticMessages: Array.from(optimisticMessages.values()),
    sendMessage,
    sendMessageWithAttachment,
    retryMessage,
    processOfflineQueue,
    addMessage,
    updateMessageStatus,
    setMessages,
    removeMessage,
  };
}

