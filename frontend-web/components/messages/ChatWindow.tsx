'use client';

import { useState, useEffect } from 'react';
import { messagesAPI, Conversation, Message } from '@/lib/api/messages';
import { useOptimisticMessages } from '@/lib/hooks/useOptimisticMessages';
import { useInfiniteMessages } from '@/lib/hooks/useInfiniteMessages';
import { useVoiceRecorder } from '@/lib/hooks/useVoiceRecorder';
import { compressImage } from '@/lib/utils/imageCompression';
import ChatHeader from './ChatHeader';
import ChatFooter from './ChatFooter';
import MessageBubble from './MessageBubble';
import TypingIndicator from './TypingIndicator';
import { messageWS } from '@/lib/websocket/MessageWebSocket';
import { toast } from '@/components/ui/Toast';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';

interface ChatWindowProps {
  conversationId: string;
  onClose?: () => void;
}

export default function ChatWindow({ conversationId, onClose }: ChatWindowProps) {
  const [conversation, setConversation] = useState<Conversation | null>(null);
  const [isTyping, setIsTyping] = useState(false);
  const [replyingTo, setReplyingTo] = useState<Message | null>(null);
  const [isChatVisible, setIsChatVisible] = useState(false);
  const [deleteConfirm, setDeleteConfirm] = useState<{ messageId: string; isMine: boolean; type: 'unsend' | 'delete_for_me' } | null>(null);

  // Hooks
  const {
    messages,
    sendMessage,
    sendMessageWithAttachment,
    setMessages,
    removeMessage,
  } = useOptimisticMessages({ conversationId });

  const {
    messages: _loadedMessages,
    isLoading,
    isLoadingMore,
    hasMore,
    scrollRef,
    handleScroll,
    scrollToBottom,
    loadMore,
  } = useInfiniteMessages({ conversationId });

  const { isRecording, duration, startRecording, stopRecording, cancelRecording } =
    useVoiceRecorder();

  // ==================== LOAD CONVERSATION ====================

  useEffect(() => {
    loadConversation();
    // Note: WebSocket connection is already handled by NotificationContext
    // Messages use the same WebSocket connection (shared endpoint)
    
    // Test WebSocket connection
    console.log('[ChatWindow] Is WebSocket connected?', messageWS.isConnected());
    console.log('[ChatWindow] Registering message listeners for conversation:', conversationId);
    
    // Check if this ChatWindow is actually visible on screen (not hidden in responsive layout)
    const checkVisibility = () => {
      const isVisible = window.innerWidth >= 768 || onClose !== undefined;
      setIsChatVisible(isVisible);
      console.log('[ChatWindow] Visibility check - is visible:', isVisible, 'width:', window.innerWidth);
    };
    
    checkVisibility();
    window.addEventListener('resize', checkVisibility);
    
    // Mark as visible immediately on mobile (when onClose exists)
    if (onClose) {
      setIsChatVisible(true);
    }
    
    return () => window.removeEventListener('resize', checkVisibility);
  }, [conversationId, onClose]);

  const loadConversation = async () => {
    try {
      const response = await messagesAPI.getConversation(conversationId);
      if (response.success) {
        setConversation(response.conversation);
        console.log('[ChatWindow] Conversation loaded, unread_count:', response.conversation.unread_count);
      }
    } catch (error) {
      console.error('Failed to load conversation:', error);
    }
  };

  // Instant mark as read (no delays)
  const markAsReadImmediately = async () => {
    try {
      // Update server FIRST
      await messagesAPI.markAsRead(conversationId);
      console.log('[ChatWindow] ✅ Marked as read on server');
      
      // Then trigger badge update (AFTER server confirms)
      window.dispatchEvent(new CustomEvent('messages_marked_read', { 
        detail: { conversationId } 
      }));
      console.log('[ChatWindow] 📤 Dispatched messages_marked_read event');
    } catch (err) {
      console.error('[ChatWindow] Failed to mark as read:', err);
    }
  };

  // Sync loaded messages with optimistic messages (ONLY on initial load to prevent overwriting)
  const [hasInitialLoad, setHasInitialLoad] = useState(false);
  
  useEffect(() => {
    if (_loadedMessages.length > 0 && !hasInitialLoad) {
      console.log('[ChatWindow] 📥 Initial load:', _loadedMessages.length, 'messages');
      setMessages(_loadedMessages);
      setHasInitialLoad(true);
    } else if (_loadedMessages.length > 0 && hasInitialLoad) {
      // For infinite scroll: merge new loaded messages without replacing existing
      console.log('[ChatWindow] 📥 Infinite scroll loaded more messages');
    }
  }, [_loadedMessages, setMessages, hasInitialLoad]);

  // Reset initial load flag when conversation changes
  useEffect(() => {
    setHasInitialLoad(false);
    console.log('[ChatWindow] 🔄 Conversation changed to:', conversationId);
  }, [conversationId]);

  // Mark as read ONLY when user scrolls (proves they're viewing)
  const [hasScrolled, setHasScrolled] = useState(false);

  useEffect(() => {
    setHasScrolled(false);
  }, [conversationId]);

  // Only mark as read when user SCROLLS (proves they're reading)
  const handleChatInteraction = () => {
    if (!hasScrolled && isChatVisible && !document.hidden) {
      console.log('[ChatWindow] 👆 User scrolled - marking as read');
      setHasScrolled(true);
      
      // Mark as read after scroll
      setTimeout(() => {
        markAsReadImmediately();
      }, 200);
    }
  };

  // Auto-mark as read when new messages arrive in active chat
  useEffect(() => {
    if (messages.length > 0 && isChatVisible && !document.hidden && hasScrolled) {
      // User is actively viewing, mark new messages as read
      const hasUnreadMessages = messages.some(m => !m.is_mine && m.status !== 'read');
      if (hasUnreadMessages) {
        console.log('[ChatWindow] 📖 New messages arrived in active chat, marking as read');
        setTimeout(() => {
          markAsReadImmediately();
        }, 500);
      }
    }
  }, [messages.length, isChatVisible, hasScrolled]);

  // ==================== WEBSOCKET LISTENERS ====================
  // Note: useOptimisticMessages already handles new_message, message_delivered, message_read
  // We only need to handle typing indicators here

  useEffect(() => {
    // Listen for typing indicators (instant)
    const unsubscribeTyping = messageWS.on('typing', (data: any) => {
      if (data.conversation_id === conversationId) {
        setIsTyping(true);
      }
    });

    const unsubscribeStopTyping = messageWS.on('stop_typing', (data: any) => {
      if (data.conversation_id === conversationId) {
        setIsTyping(false);
      }
    });

    return () => {
      unsubscribeTyping();
      unsubscribeStopTyping();
    };
  }, [conversationId]);

  // ==================== SEND MESSAGE ====================

  const handleSendMessage = async (text: string) => {
    console.log('[ChatWindow] handleSendMessage called - text:', text, 'isRecording:', isRecording);
    
    if (!text.trim() && !isRecording) {
      console.log('[ChatWindow] ⚠️ No text and not recording, skipping send');
      return;
    }

    if (isRecording) {
      // Stop recording and send voice message
      console.log('[ChatWindow] 🎤 Stopping recording and sending voice message...');
      const audioBlob = await stopRecording();
      if (audioBlob) {
        console.log('[ChatWindow] ✅ Audio blob received, size:', audioBlob.size);
        await handleSendVoice(audioBlob);
      } else {
        console.log('[ChatWindow] ❌ No audio blob received');
      }
    } else {
      // Send text message
      console.log('[ChatWindow] 📝 Sending text message');
      await sendMessage(text, replyingTo?.id);
      setReplyingTo(null);
      scrollToBottom(true);
    }
  };

  // ==================== SEND VOICE MESSAGE ====================

  const handleSendVoice = async (audioBlob: Blob) => {
    try {
      // Upload audio
      const uploadResponse = await messagesAPI.uploadAudio(audioBlob);

      if (uploadResponse.success) {
        // Send as audio message
        await sendMessageWithAttachment(
          'Voice message',
          uploadResponse.url,
          uploadResponse.name,
          uploadResponse.size,
          uploadResponse.type,
          'audio'
        );

        scrollToBottom(true);
      }
    } catch (error) {
      console.error('Failed to send voice message:', error);
      toast.error('Failed to send voice message');
    }
  };

  // ==================== SEND IMAGE ====================

  const handleSendImage = async (file: File, quality: 'standard' | 'hd' = 'standard') => {
    try {
      // Compress image on client side
      const compressed = await compressImage(file, quality);

      // Upload image
      const uploadResponse = await messagesAPI.uploadImage(compressed, quality);

      if (uploadResponse.success) {
        // Send as image message
        await sendMessageWithAttachment(
          'Photo',
          uploadResponse.url,
          uploadResponse.name,
          uploadResponse.size,
          uploadResponse.type,
          'image'
        );

        scrollToBottom(true);
      }
    } catch (error) {
      console.error('Failed to send image:', error);
      toast.error('Failed to send image');
    }
  };

  // ==================== MESSAGE ACTIONS ====================

  const handleReact = async (messageId: string, emoji: string) => {
    try {
      console.log('[ChatWindow] Adding reaction:', emoji, 'to message:', messageId);
      const response = await messagesAPI.addReaction(messageId, emoji);
      
      if (response.removed) {
        console.log('[ChatWindow] ✅ Reaction removed (toggled off)');
        toast.info(`Removed ${emoji} reaction`);
        
        // Remove reaction from local state
        const updatedMessages = messages.map((msg: Message) =>
          msg.id === messageId
            ? {
                ...msg,
                reactions: msg.reactions?.filter((r: any) => r.emoji !== emoji) || [],
              }
            : msg
        );
        setMessages(updatedMessages);
      } else {
        console.log('[ChatWindow] ✅ Reaction added successfully');
        toast.success(`Reacted with ${emoji}`);
        
        // Add reaction to local state (optimistic UI)
        const newReaction = response.reaction;
        const updatedMessages = messages.map((msg: Message) =>
          msg.id === messageId
            ? {
                ...msg,
                reactions: [...(msg.reactions || []), newReaction],
              }
            : msg
        );
        setMessages(updatedMessages);
      }
    } catch (error) {
      console.error('[ChatWindow] ❌ Failed to add reaction:', error);
      toast.error('Failed to add reaction');
    }
  };

  const handleReply = (message: Message) => {
    setReplyingTo(message);
  };

  const handleStar = async (messageId: string, isStarred: boolean) => {
    try {
      if (isStarred) {
        await messagesAPI.unstarMessage(messageId);
      } else {
        await messagesAPI.starMessage(messageId);
      }
    } catch (error) {
      console.error('Failed to star message:', error);
    }
  };

  const handleDelete = async (messageId: string) => {
    const message = messages.find(m => m.id === messageId);
    if (!message) return;

    // Show confirmation dialog
    setDeleteConfirm({
      messageId,
      isMine: message.is_mine || false,
      type: message.is_mine ? 'unsend' : 'delete_for_me',
    });
  };

  const confirmDelete = async () => {
    if (!deleteConfirm) return;

    try {
      // Optimistic UI - remove message immediately
      removeMessage(deleteConfirm.messageId);
      console.log('[ChatWindow] 🗑️ Optimistically removed message:', deleteConfirm.messageId);

      // Delete on server
      await messagesAPI.deleteMessage(deleteConfirm.messageId);
      console.log('[ChatWindow] ✅ Message deleted on server:', deleteConfirm.messageId);

      // Show success toast
      if (deleteConfirm.type === 'unsend') {
        toast.success('Message deleted for everyone');
      } else {
        toast.success('Message deleted');
      }
    } catch (error) {
      console.error('[ChatWindow] ❌ Failed to delete message:', error);
      toast.error('Failed to delete message');
      // Reload messages to restore the message
      window.location.reload();
    } finally {
      setDeleteConfirm(null);
    }
  };

  const handleForward = (message: Message) => {
    // TODO: Implement forward dialog
    console.log('Forward message:', message.id);
    toast.info('Forward feature coming soon!');
  };

  const handleCopy = (message: Message) => {
    if (message.message_type === 'text') {
      navigator.clipboard.writeText(message.content);
      toast.success('Message copied to clipboard');
      console.log('Message copied to clipboard');
    } else {
      toast.info('Cannot copy this message type');
    }
  };

  const handlePin = async (messageId: string, isPinned: boolean) => {
    // TODO: Implement pin/unpin API
    console.log(isPinned ? 'Unpin' : 'Pin', 'message:', messageId);
    toast.info('Pin feature coming soon!');
  };

  const handleShare = (message: Message) => {
    // TODO: Implement share dialog
    console.log('Share message:', message.id);
    toast.info('Share feature coming soon!');
  };

  const handleInfo = (message: Message) => {
    // Build formatted info message
    const sentTime = new Date(message.created_at).toLocaleString();
    const deliveredTime = message.delivered_at ? new Date(message.delivered_at).toLocaleString() : 'Not yet';
    const readTime = message.read_at ? new Date(message.read_at).toLocaleString() : 'Not yet';
    
    const info = `Sent: ${sentTime}\nDelivered: ${deliveredTime}\nRead: ${readTime}`;
    
    toast.info(info, 5000);
  };

  // ==================== RENDER ====================

  if (!conversation) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-600"></div>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full min-h-screen md:min-h-0">
      {/* Header */}
      <ChatHeader conversation={conversation} onClose={onClose} />

      {/* Messages Body */}
      <div
        ref={scrollRef}
        data-message-scroll
        onScroll={() => {
          handleScroll();
          handleChatInteraction(); // Only mark as read when user SCROLLS
        }}
        className="flex-1 overflow-y-auto p-4 space-y-2 bg-gray-50 dark:bg-gray-900"
      >
        {/* Load more indicator */}
        {hasMore && (
          <div className="text-center py-2">
            {isLoadingMore ? (
              <div className="inline-block animate-spin rounded-full h-5 w-5 border-b-2 border-purple-600"></div>
            ) : (
              <button
                onClick={loadMore}
                className="text-sm text-purple-600 hover:text-purple-700 font-medium px-4 py-2 rounded-lg hover:bg-purple-50 dark:hover:bg-purple-900/20 transition-colors"
              >
                Load older messages
              </button>
            )}
          </div>
        )}

        {/* Messages */}
        {messages.map((message) => (
          <MessageBubble
            key={message.id}
            message={message}
            onReact={handleReact}
            onReply={handleReply}
            onStar={handleStar}
            onDelete={handleDelete}
            onForward={handleForward}
            onCopy={handleCopy}
            onPin={handlePin}
            onShare={handleShare}
            onInfo={handleInfo}
          />
        ))}

        {/* Typing Indicator */}
        {isTyping && <TypingIndicator />}
      </div>

      {/* Footer */}
      <ChatFooter
        onSendMessage={handleSendMessage}
        onSendImage={handleSendImage}
        onStartVoiceRecording={startRecording}
        onCancelVoiceRecording={cancelRecording}
        isRecording={isRecording}
        recordingDuration={duration}
        replyingTo={replyingTo}
        onCancelReply={() => setReplyingTo(null)}
      />

      {/* Delete Confirmation Dialog */}
      {deleteConfirm && (
        <ConfirmDialog
          isOpen={true}
          title={deleteConfirm.type === 'unsend' ? 'Delete for everyone?' : 'Delete for you?'}
          message={
            deleteConfirm.type === 'unsend'
              ? 'This message will be deleted for everyone in the chat. This cannot be undone.'
              : 'This message will be deleted for you. The sender will still see it.'
          }
          confirmText="Delete"
          cancelText="Cancel"
          variant="danger"
          onConfirm={confirmDelete}
          onCancel={() => setDeleteConfirm(null)}
        />
      )}
    </div>
  );
}

