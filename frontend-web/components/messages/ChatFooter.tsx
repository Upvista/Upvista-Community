'use client';

import { useState, useRef, KeyboardEvent } from 'react';
import { Smile, Paperclip, Mic, X, Send } from 'lucide-react';
import { Message } from '@/lib/api/messages';

interface ChatFooterProps {
  onSendMessage: (text: string) => void;
  onSendImage: (file: File, quality: 'standard' | 'hd') => void;
  onStartVoiceRecording: () => void;
  onCancelVoiceRecording: () => void;
  isRecording: boolean;
  recordingDuration: number;
  replyingTo: Message | null;
  onCancelReply: () => void;
}

export default function ChatFooter({
  onSendMessage,
  onSendImage,
  onStartVoiceRecording,
  onCancelVoiceRecording,
  isRecording,
  recordingDuration,
  replyingTo,
  onCancelReply,
}: ChatFooterProps) {
  const [text, setText] = useState('');
  const fileInputRef = useRef<HTMLInputElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  // ==================== SEND ====================

  const handleSend = () => {
    if (text.trim() || isRecording) {
      onSendMessage(text);
      setText('');

      // Reset textarea height
      if (textareaRef.current) {
        textareaRef.current.style.height = 'auto';
      }
    }
  };

  const handleKeyPress = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  // ==================== AUTO-RESIZE TEXTAREA ====================

  const handleTextChange = (value: string) => {
    setText(value);

    // Auto-resize textarea
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
      textareaRef.current.style.height = textareaRef.current.scrollHeight + 'px';
    }
  };

  // ==================== ATTACHMENT ====================

  const handleAttachment = () => {
    fileInputRef.current?.click();
  };

  const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Check if it's an image
    if (file.type.startsWith('image/')) {
      // Always send in standard quality by default (HD can be added as feature later)
      onSendImage(file, 'standard');
    } else {
      // Handle other file types in Phase 2
      const { toast } = await import('@/components/ui/Toast');
      toast.info('Only images are supported for now');
    }

    // Reset input
    e.target.value = '';
  };

  // ==================== VOICE RECORDING ====================

  const handleVoiceClick = () => {
    if (isRecording) {
      // Already recording - stop and send
      console.log('[ChatFooter] Stopping recording and sending...');
      handleSend();
    } else {
      // Not recording - start recording
      console.log('[ChatFooter] Starting voice recording...');
      onStartVoiceRecording();
    }
  };

  const formatDuration = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  // ==================== RENDER ====================

  return (
    <div className="border-t border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900">
      {/* Reply Preview - WhatsApp Style */}
      {replyingTo && (
        <div className="px-4 py-3 bg-gradient-to-r from-purple-50 to-transparent dark:from-purple-900/20 dark:to-transparent border-b border-gray-200 dark:border-gray-700">
          <div className="flex items-start gap-3">
            {/* Left Border Accent */}
            <div className="w-1 h-12 bg-purple-600 rounded-full flex-shrink-0"></div>
            
            {/* Reply Content */}
            <div className="flex-1 min-w-0">
              <div className="text-xs font-semibold text-purple-600 dark:text-purple-400 mb-1">
                Replying to {replyingTo.sender?.display_name || 'User'}
              </div>
              <div className="text-sm text-gray-700 dark:text-gray-300 line-clamp-2 flex items-center gap-2">
                {replyingTo.message_type === 'image' && (
                  <>
                    <span className="flex items-center gap-1.5">
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
                        <circle cx="8.5" cy="8.5" r="1.5"/>
                        <polyline points="21 15 16 10 5 21"/>
                      </svg>
                      Photo
                    </span>
                  </>
                )}
                {replyingTo.message_type === 'audio' && (
                  <>
                    <span className="flex items-center gap-1.5">
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"/>
                        <path d="M19 10v2a7 7 0 0 1-14 0v-2"/>
                        <line x1="12" y1="19" x2="12" y2="23"/>
                        <line x1="8" y1="23" x2="16" y2="23"/>
                      </svg>
                      Voice message
                    </span>
                  </>
                )}
                {replyingTo.message_type === 'file' && (
                  <>
                    <span className="flex items-center gap-1.5">
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path d="M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48"/>
                      </svg>
                      File
                    </span>
                  </>
                )}
                {replyingTo.message_type === 'text' && replyingTo.content}
              </div>
            </div>
            
            {/* Close Button */}
            <button
              onClick={onCancelReply}
              className="p-1.5 hover:bg-purple-100 dark:hover:bg-purple-900/30 rounded-full transition-colors flex-shrink-0"
              title="Cancel reply"
            >
              <X className="w-4 h-4 text-gray-500 dark:text-gray-400" />
            </button>
          </div>
        </div>
      )}

      {/* Recording Indicator */}
      {isRecording && (
        <div className="px-4 py-2 bg-red-50 dark:bg-red-900/20 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 bg-red-500 rounded-full animate-pulse"></div>
            <span className="text-sm font-medium text-red-600 dark:text-red-400">
              Recording... {formatDuration(recordingDuration)}
            </span>
          </div>
          <button
            onClick={onCancelVoiceRecording}
            className="text-sm text-red-600 hover:text-red-700 dark:text-red-400 dark:hover:text-red-300"
          >
            Cancel
          </button>
        </div>
      )}

      {/* Input Area */}
      <div className="p-4 flex items-end gap-2">
        {/* Emoji Button */}
        <button
          onClick={async () => {
            const { toast } = await import('@/components/ui/Toast');
            toast.info('Emoji picker coming soon!');
          }}
          className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-full transition-colors flex-shrink-0"
        >
          <Smile className="w-5 h-5 text-gray-600 dark:text-gray-400" />
        </button>

        {/* Text Input */}
        <div className="flex-1 relative">
          <textarea
            ref={textareaRef}
            value={text}
            onChange={(e) => handleTextChange(e.target.value)}
            onKeyPress={handleKeyPress}
            placeholder={isRecording ? 'Recording audio...' : 'Type a message...'}
            disabled={isRecording}
            className="w-full px-4 py-2 pr-10 rounded-full border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-white resize-none focus:outline-none focus:ring-2 focus:ring-purple-500 max-h-32"
            rows={1}
          />

          {/* Attachment Button (inside input) */}
          <button
            onClick={handleAttachment}
            className="absolute right-2 bottom-2 p-1.5 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-full transition-colors"
          >
            <Paperclip className="w-4 h-4 text-gray-600 dark:text-gray-400" />
          </button>

          {/* Hidden file input */}
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            onChange={handleFileSelect}
            className="hidden"
          />
        </div>

        {/* Send / Voice Button */}
        {text.trim() ? (
          <button
            onClick={handleSend}
            className="p-3 bg-purple-600 hover:bg-purple-700 text-white rounded-full transition-colors flex-shrink-0"
            title="Send message"
          >
            <Send className="w-5 h-5" />
          </button>
        ) : (
          <button
            onClick={handleVoiceClick}
            className={`p-3 rounded-full transition-colors flex-shrink-0 ${
              isRecording
                ? 'bg-red-600 hover:bg-red-700 text-white animate-pulse'
                : 'bg-purple-600 hover:bg-purple-700 text-white'
            }`}
            title={isRecording ? 'Click to send voice message' : 'Click to start recording'}
          >
            {isRecording ? <Send className="w-5 h-5" /> : <Mic className="w-5 h-5" />}
          </button>
        )}
      </div>
    </div>
  );
}

