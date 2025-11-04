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
      // Ask for quality preference
      const useHD = confirm('Send in HD quality? (larger file size)\n\nClick OK for HD, Cancel for Standard');
      onSendImage(file, useHD ? 'hd' : 'standard');
    } else {
      // Handle other file types in Phase 2
      alert('Only images are supported for now');
    }

    // Reset input
    e.target.value = '';
  };

  // ==================== VOICE RECORDING ====================

  const handleVoiceClick = () => {
    if (isRecording) {
      // Send voice message
      handleSend();
    } else {
      // Start recording
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
      {/* Reply Preview */}
      {replyingTo && (
        <div className="px-4 py-2 bg-gray-50 dark:bg-gray-800 flex items-center justify-between">
          <div className="flex-1 min-w-0">
            <p className="text-xs text-gray-500 dark:text-gray-400">
              Replying to {replyingTo.sender?.display_name || 'User'}
            </p>
            <p className="text-sm text-gray-900 dark:text-white truncate">
              {replyingTo.content}
            </p>
          </div>
          <button
            onClick={onCancelReply}
            className="p-1 hover:bg-gray-200 dark:hover:bg-gray-700 rounded"
          >
            <X className="w-4 h-4" />
          </button>
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
          onClick={() => alert('Emoji picker coming soon!')}
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
          >
            <Send className="w-5 h-5" />
          </button>
        ) : (
          <button
            onClick={handleVoiceClick}
            onMouseDown={isRecording ? undefined : onStartVoiceRecording}
            className={`p-3 rounded-full transition-colors flex-shrink-0 ${
              isRecording
                ? 'bg-red-600 hover:bg-red-700 text-white animate-pulse'
                : 'bg-purple-600 hover:bg-purple-700 text-white'
            }`}
          >
            <Mic className="w-5 h-5" />
          </button>
        )}
      </div>
    </div>
  );
}

