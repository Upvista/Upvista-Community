'use client';

import { useState, useRef, useEffect } from 'react';
import { Send, Smile, X } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { Comment } from '@/lib/api/posts';
import EmojiPicker from './EmojiPicker';

interface CommentInputProps {
  onSubmit: (content: string) => void;
  onCancel?: () => void;
  editingComment?: Comment | null;
  onUpdate?: (content: string) => void;
  placeholder?: string;
}

export default function CommentInput({
  onSubmit,
  onCancel,
  editingComment,
  onUpdate,
  placeholder = 'Add a comment...',
}: CommentInputProps) {
  const [content, setContent] = useState('');
  const [showEmojiPicker, setShowEmojiPicker] = useState(false);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const emojiPickerRef = useRef<HTMLDivElement>(null);

  // Set content when editing
  useEffect(() => {
    if (editingComment) {
      setContent(editingComment.content);
      textareaRef.current?.focus();
    } else {
      setContent('');
    }
  }, [editingComment]);

  // Auto-resize textarea
  useEffect(() => {
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
      textareaRef.current.style.height = `${Math.min(textareaRef.current.scrollHeight, 120)}px`;
    }
  }, [content]);

  // Close emoji picker when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (
        emojiPickerRef.current &&
        !emojiPickerRef.current.contains(event.target as Node) &&
        !(event.target as HTMLElement).closest('[data-emoji-button]')
      ) {
        setShowEmojiPicker(false);
      }
    };

    if (showEmojiPicker) {
      document.addEventListener('mousedown', handleClickOutside);
      return () => document.removeEventListener('mousedown', handleClickOutside);
    }
  }, [showEmojiPicker]);

  const handleSubmit = () => {
    const trimmedContent = content.trim();
    if (!trimmedContent) return;

    if (editingComment && onUpdate) {
      onUpdate(trimmedContent);
    } else {
      onSubmit(trimmedContent);
    }
    setContent('');
    setShowEmojiPicker(false);
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSubmit();
    }
    if (e.key === 'Escape' && onCancel) {
      onCancel();
    }
  };

  const handleEmojiSelect = (emoji: string) => {
    setContent(prev => prev + emoji);
    textareaRef.current?.focus();
  };

  const isDisabled = !content.trim();

  return (
    <div className="relative">
      <div className="flex items-end gap-2 px-4 py-3">
        {/* Emoji Button */}
        <button
          data-emoji-button
          onClick={() => setShowEmojiPicker(!showEmojiPicker)}
          className="p-2 hover:bg-neutral-100 dark:hover:bg-neutral-800 rounded-full transition-colors flex-shrink-0"
          type="button"
        >
          <Smile className="w-5 h-5 text-neutral-500 dark:text-neutral-400" />
        </button>

        {/* Text Input */}
        <div className="flex-1 relative">
          <textarea
            ref={textareaRef}
            value={content}
            onChange={(e) => setContent(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder={placeholder}
            rows={1}
            className="w-full px-4 py-2 bg-neutral-50 dark:bg-neutral-800 border border-neutral-200 dark:border-neutral-700 rounded-full resize-none focus:outline-none focus:ring-2 focus:ring-purple-500 dark:focus:ring-purple-400 focus:border-transparent text-sm text-neutral-900 dark:text-neutral-50 placeholder:text-neutral-400 dark:placeholder:text-neutral-500 max-h-[120px] overflow-y-auto"
            style={{ minHeight: '40px' }}
          />
        </div>

        {/* Submit/Cancel Buttons */}
        <div className="flex items-center gap-2 flex-shrink-0">
          {editingComment && onCancel && (
            <button
              onClick={onCancel}
              className="p-2 hover:bg-neutral-100 dark:hover:bg-neutral-800 rounded-full transition-colors"
              type="button"
            >
              <X className="w-5 h-5 text-neutral-500 dark:text-neutral-400" />
            </button>
          )}
          <button
            onClick={handleSubmit}
            disabled={isDisabled}
            className={`p-2 rounded-full transition-colors ${
              isDisabled
                ? 'text-neutral-300 dark:text-neutral-600 cursor-not-allowed'
                : 'text-purple-600 dark:text-purple-400 hover:bg-purple-50 dark:hover:bg-purple-900/20'
            }`}
            type="button"
          >
            <Send className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Emoji Picker */}
      <AnimatePresence>
        {showEmojiPicker && (
          <motion.div
            ref={emojiPickerRef}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 10 }}
            transition={{ duration: 0.2 }}
            className="absolute bottom-full left-4 mb-2 z-10"
          >
            <EmojiPicker onSelect={handleEmojiSelect} />
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

