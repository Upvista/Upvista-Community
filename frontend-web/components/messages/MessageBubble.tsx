'use client';

import { useState } from 'react';
import { Message, formatMessageTimestamp } from '@/lib/api/messages';
import { Check, CheckCheck, Star, Reply, Forward, Trash2, Info, Smile } from 'lucide-react';
import ImageMessage from './ImageMessage';
import AudioPlayer from './AudioPlayer';

interface MessageBubbleProps {
  message: Message;
  onReact: (messageId: string, emoji: string) => void;
  onReply: (message: Message) => void;
  onStar: (messageId: string, isStarred: boolean) => void;
  onDelete: (messageId: string) => void;
}

export default function MessageBubble({
  message,
  onReact,
  onReply,
  onStar,
  onDelete,
}: MessageBubbleProps) {
  const [showActions, setShowActions] = useState(false);
  const [showReactions, setShowReactions] = useState(false);

  const isMine = message.is_mine;

  // ==================== STATUS ICONS ====================

  const StatusIcon = () => {
    if (!isMine) return null;

    switch (message.status) {
      case 'sent':
        return <Check className="w-3.5 h-3.5 text-gray-400" />;
      case 'delivered':
        return <CheckCheck className="w-3.5 h-3.5 text-gray-400" />;
      case 'read':
        return <CheckCheck className="w-3.5 h-3.5 text-blue-500" />;
      default:
        return null;
    }
  };

  // ==================== QUICK REACTIONS ====================

  const quickReactions = ['❤️', '👍', '😂', '😮', '😢', '🙏'];

  const handleQuickReaction = (emoji: string) => {
    onReact(message.id, emoji);
    setShowReactions(false);
  };

  // ==================== RENDER ====================

  return (
    <div
      className={`flex ${isMine ? 'justify-end' : 'justify-start'} group`}
      onMouseEnter={() => setShowActions(true)}
      onMouseLeave={() => {
        setShowActions(false);
        setShowReactions(false);
      }}
    >
      <div className="relative max-w-[70%] md:max-w-[500px]">
        {/* Action Menu (on hover) */}
        {showActions && !showReactions && (
          <div
            className={`absolute -top-8 ${
              isMine ? 'right-0' : 'left-0'
            } flex items-center gap-1 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 p-1`}
          >
            <button
              onClick={() => setShowReactions(true)}
              className="p-1.5 hover:bg-gray-100 dark:hover:bg-gray-700 rounded transition-colors"
              title="React"
            >
              <Smile className="w-4 h-4" />
            </button>
            <button
              onClick={() => onReply(message)}
              className="p-1.5 hover:bg-gray-100 dark:hover:bg-gray-700 rounded transition-colors"
              title="Reply"
            >
              <Reply className="w-4 h-4" />
            </button>
            <button
              onClick={() => onStar(message.id, message.is_starred || false)}
              className="p-1.5 hover:bg-gray-100 dark:hover:bg-gray-700 rounded transition-colors"
              title={message.is_starred ? 'Unstar' : 'Star'}
            >
              <Star
                className={`w-4 h-4 ${
                  message.is_starred ? 'fill-yellow-400 text-yellow-400' : ''
                }`}
              />
            </button>
            {isMine && (
              <button
                onClick={() => onDelete(message.id)}
                className="p-1.5 hover:bg-gray-100 dark:hover:bg-gray-700 rounded transition-colors text-red-600"
                title="Delete"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            )}
          </div>
        )}

        {/* Reaction Picker */}
        {showReactions && (
          <div
            className={`absolute -top-12 ${
              isMine ? 'right-0' : 'left-0'
            } flex items-center gap-1 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 p-2`}
          >
            {quickReactions.map((emoji) => (
              <button
                key={emoji}
                onClick={() => handleQuickReaction(emoji)}
                className="text-xl hover:scale-125 transition-transform p-1"
              >
                {emoji}
              </button>
            ))}
          </div>
        )}

        {/* Message Bubble */}
        <div
          className={`rounded-2xl px-3 py-2 break-words ${
            isMine
              ? 'bg-purple-600 text-white'
              : 'bg-gray-200 dark:bg-gray-800 text-gray-900 dark:text-white'
          }`}
          style={{ wordBreak: 'break-word', overflowWrap: 'anywhere', maxWidth: '100%' }}
        >
          {/* Reply Preview */}
          {message.reply_to && (
            <div
              className={`mb-2 pb-2 border-l-2 pl-2 text-xs opacity-75 ${
                isMine ? 'border-purple-300' : 'border-gray-400 dark:border-gray-600'
              }`}
            >
              <div className="font-medium">
                {message.reply_to.sender?.display_name || 'User'}
              </div>
              <div className="truncate">{message.reply_to.content}</div>
            </div>
          )}

          {/* Content */}
          {message.message_type === 'text' && (
            <p className="text-sm whitespace-pre-wrap break-words">{message.content}</p>
          )}

          {message.message_type === 'image' && (
            <ImageMessage url={message.attachment_url || ''} alt="Image" />
          )}

          {message.message_type === 'audio' && (
            <AudioPlayer url={message.attachment_url || ''} duration={0} />
          )}

          {/* Reactions */}
          {message.reactions && message.reactions.length > 0 && (
            <div className="flex flex-wrap gap-1 mt-2 -mb-1">
              {message.reactions.map((reaction) => (
                <span
                  key={reaction.id}
                  className="text-sm bg-white/20 dark:bg-black/20 px-1.5 py-0.5 rounded-full"
                  title={reaction.user?.display_name || 'Someone'}
                >
                  {reaction.emoji}
                </span>
              ))}
            </div>
          )}

          {/* Timestamp + Status */}
          <div className="flex items-center justify-end gap-1 mt-1">
            <span className={`text-[10px] ${isMine ? 'text-purple-200' : 'text-gray-500 dark:text-gray-400'}`}>
              {formatMessageTimestamp(message.created_at)}
            </span>
            <StatusIcon />
            {message.is_starred && (
              <Star className="w-3 h-3 fill-yellow-400 text-yellow-400" />
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

