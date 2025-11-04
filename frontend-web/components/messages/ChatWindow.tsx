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

interface ChatWindowProps {
  conversationId: string;
  onClose?: () => void;
}

export default function ChatWindow({ conversationId, onClose }: ChatWindowProps) {
  const [conversation, setConversation] = useState<Conversation | null>(null);
  const [isTyping, setIsTyping] = useState(false);
  const [replyingTo, setReplyingTo] = useState<Message | null>(null);
  const [isChatVisible, setIsChatVisible] = useState(false);

  // Hooks
  const {
    messages,
    sendMessage,
    sendMessageWithAttachment,
    setMessages,
  } = useOptimisticMessages({ conversationId });

  const {
    messages: _loadedMessages,
    isLoading,
    isLoadingMore,
    hasMore,
    scrollRef,
    handleScroll,
    scrollToBottom,
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
      // Trigger UI update FIRST (optimistic)
      window.dispatchEvent(new CustomEvent('messages_marked_read', { 
        detail: { conversationId } 
      }));
      
      // Then update server in background
      await messagesAPI.markAsRead(conversationId);
      console.log('[ChatWindow]  Marked as read');
    } catch (err) {
      console.error('Failed to mark as read:', err);
    }
  };

  // Sync loaded messages with optimistic messages
  useEffect(() => {
    if (_loadedMessages.length > 0) {
      setMessages(_loadedMessages);
    }
  }, [_loadedMessages, setMessages]);

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
    if (!text.trim() && !isRecording) return;

    if (isRecording) {
      // Stop recording and send voice message
      const audioBlob = await stopRecording();
      if (audioBlob) {
        await handleSendVoice(audioBlob);
      }
    } else {
      // Send text message
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
      alert('Failed to send voice message');
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
      alert('Failed to send image');
    }
  };

  // ==================== MESSAGE ACTIONS ====================

  const handleReact = async (messageId: string, emoji: string) => {
    try {
      await messagesAPI.addReaction(messageId, emoji);
    } catch (error) {
      console.error('Failed to add reaction:', error);
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
    if (confirm('Delete this message?')) {
      try {
        await messagesAPI.deleteMessage(messageId);
      } catch (error) {
        console.error('Failed to delete message:', error);
      }
    }
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
                onClick={() => {}}
                className="text-sm text-purple-600 hover:text-purple-700"
              >
                Scroll up to load more
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
    </div>
  );
}

