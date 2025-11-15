'use client';

import { useState } from 'react';
import { Heart, MoreVertical, Reply, Trash2, Edit2 } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { Comment, formatPostTimestamp } from '@/lib/api/posts';
import { Avatar } from '../ui/Avatar';
import VerifiedBadge from '../ui/VerifiedBadge';

interface CommentItemProps {
  comment: Comment;
  currentUserId?: string;
  onLike: () => void;
  onReply: () => void;
  onEdit: () => void;
  onDelete: () => void;
  onLoadReplies: () => void;
  showMenu: string | null;
  onToggleMenu: (commentId: string) => void;
  depth?: number;
}

export default function CommentItem({
  comment,
  currentUserId,
  onLike,
  onReply,
  onEdit,
  onDelete,
  onLoadReplies,
  showMenu,
  onToggleMenu,
  depth = 0,
}: CommentItemProps) {
  const isOwnComment = comment.user_id === currentUserId;
  const hasReplies = comment.replies_count > 0;
  const showReplies = comment.replies && comment.replies.length > 0;
  const [isLiking, setIsLiking] = useState(false);

  const handleLike = async () => {
    if (isLiking) return;
    setIsLiking(true);
    await onLike();
    // Simulate haptic feedback
    if (navigator.vibrate) {
      navigator.vibrate(10);
    }
    setTimeout(() => setIsLiking(false), 300);
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.2, ease: 'easeOut' }}
      className="flex gap-3 group"
    >
      <Avatar
        src={comment.author?.profile_picture}
        alt={comment.author?.display_name || comment.author?.username || 'User'}
        fallback={comment.author?.display_name || comment.author?.username || 'U'}
        size="sm"
        className="flex-shrink-0"
      />
      <div className="flex-1 min-w-0">
        {/* Comment Content - Glassmorphism Card */}
        <motion.div
          whileHover={{ scale: 1.01 }}
          transition={{ duration: 0.2 }}
          className="relative mb-2"
        >
          <div className="
            rounded-2xl px-4 py-3
            bg-white/70 dark:bg-neutral-800/70
            backdrop-blur-xl
            border border-white/30 dark:border-neutral-700/30
            shadow-lg shadow-neutral-200/50 dark:shadow-black/20
            transition-all duration-300
            hover:shadow-xl hover:shadow-neutral-300/50 dark:hover:shadow-black/30
            hover:border-white/40 dark:hover:border-neutral-600/40
          ">
            {/* Glossy highlight overlay */}
            <div className="absolute inset-0 rounded-2xl bg-gradient-to-b from-white/20 to-transparent pointer-events-none" />
            
            <div className="relative">
              <div className="flex items-start justify-between gap-2 mb-2">
                <div className="flex items-center gap-1.5 flex-1 min-w-0">
                  <span className="text-sm font-semibold text-neutral-900 dark:text-neutral-50 truncate">
                    {comment.author?.display_name || comment.author?.username}
                  </span>
                  {comment.author?.is_verified && (
                    <VerifiedBadge size="sm" variant="badge" showText={false} />
                  )}
                </div>
                {isOwnComment && (
                  <div className="relative flex-shrink-0">
                    <button
                      onClick={() => onToggleMenu(comment.id)}
                      className="p-1.5 hover:bg-white/50 dark:hover:bg-neutral-700/50 rounded-full transition-all duration-200 opacity-0 group-hover:opacity-100"
                    >
                      <MoreVertical className="w-4 h-4 text-neutral-500 dark:text-neutral-400" />
                    </button>
                    <AnimatePresence>
                      {showMenu === comment.id && (
                        <motion.div
                          initial={{ opacity: 0, scale: 0.95, y: -10 }}
                          animate={{ opacity: 1, scale: 1, y: 0 }}
                          exit={{ opacity: 0, scale: 0.95, y: -10 }}
                          transition={{ duration: 0.15 }}
                          className="absolute right-0 top-10 z-20
                            bg-white/90 dark:bg-neutral-800/90
                            backdrop-blur-xl
                            border border-white/30 dark:border-neutral-700/30
                            rounded-xl shadow-2xl
                            py-1.5 min-w-[140px]
                          "
                        >
                          <button
                            onClick={onEdit}
                            className="w-full px-4 py-2.5 text-left text-sm text-neutral-700 dark:text-neutral-300 hover:bg-white/50 dark:hover:bg-neutral-700/50 flex items-center gap-2.5 transition-colors"
                          >
                            <Edit2 className="w-4 h-4" />
                            Edit
                          </button>
                          <button
                            onClick={onDelete}
                            className="w-full px-4 py-2.5 text-left text-sm text-red-600 dark:text-red-400 hover:bg-red-50/50 dark:hover:bg-red-900/20 flex items-center gap-2.5 transition-colors"
                          >
                            <Trash2 className="w-4 h-4" />
                            Delete
                          </button>
                        </motion.div>
                      )}
                    </AnimatePresence>
                  </div>
                )}
              </div>
              <p className="text-sm text-neutral-900 dark:text-neutral-50 whitespace-pre-wrap break-words leading-relaxed">
                {comment.content}
              </p>
              {comment.is_edited && (
                <p className="text-xs text-neutral-400 dark:text-neutral-500 mt-1.5 italic">
                  (edited)
                </p>
              )}
            </div>
          </div>
        </motion.div>

        {/* Comment Actions */}
        <div className="flex items-center gap-4 px-1 mb-3">
          <span className="text-xs text-neutral-500 dark:text-neutral-400">
            {formatPostTimestamp(comment.created_at)}
          </span>
          <motion.button
            whileTap={{ scale: 0.95 }}
            onClick={handleLike}
            disabled={isLiking}
            className={`
              text-xs font-semibold transition-all duration-200
              ${comment.is_liked
                ? 'text-red-600 dark:text-red-400'
                : 'text-neutral-500 dark:text-neutral-400 hover:text-red-600 dark:hover:text-red-400'
              }
              ${isLiking ? 'opacity-50' : ''}
            `}
          >
            Like
          </motion.button>
          {depth < 2 && (
            <motion.button
              whileTap={{ scale: 0.95 }}
              onClick={onReply}
              className="text-xs font-semibold text-neutral-500 dark:text-neutral-400 hover:text-purple-600 dark:hover:text-purple-400 transition-colors"
            >
              Reply
            </motion.button>
          )}
          {comment.likes_count > 0 && (
            <motion.button
              whileTap={{ scale: 0.95 }}
              onClick={handleLike}
              className="text-xs text-neutral-500 dark:text-neutral-400 flex items-center gap-1.5 transition-colors hover:text-red-600 dark:hover:text-red-400"
            >
              <motion.div
                animate={comment.is_liked ? { scale: [1, 1.2, 1] } : {}}
                transition={{ duration: 0.3 }}
              >
                <Heart className={`w-3.5 h-3.5 ${comment.is_liked ? 'fill-current text-red-600 dark:text-red-400' : ''}`} />
              </motion.div>
              {comment.likes_count}
            </motion.button>
          )}
        </div>

        {/* Replies */}
        {showReplies && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            transition={{ duration: 0.3 }}
            className="ml-4 mt-2 space-y-3 border-l-2 border-neutral-200/50 dark:border-neutral-700/50 pl-4"
          >
            {comment.replies?.map((reply) => (
              <CommentItem
                key={reply.id}
                comment={reply}
                currentUserId={currentUserId}
                onLike={onLike}
                onReply={onReply}
                onEdit={onEdit}
                onDelete={onDelete}
                onLoadReplies={onLoadReplies}
                showMenu={showMenu}
                onToggleMenu={onToggleMenu}
                depth={depth + 1}
              />
            ))}
            {comment.replies_count > (comment.replies?.length || 0) && (
              <button
                onClick={onLoadReplies}
                className="text-xs text-purple-600 dark:text-purple-400 font-semibold hover:underline transition-colors"
              >
                View {comment.replies_count - (comment.replies?.length || 0)} more replies
              </button>
            )}
          </motion.div>
        )}
        {hasReplies && !showReplies && (
          <button
            onClick={onLoadReplies}
            className="text-xs text-purple-600 dark:text-purple-400 font-semibold hover:underline mt-2 transition-colors"
          >
            View {comment.replies_count} {comment.replies_count === 1 ? 'reply' : 'replies'}
          </button>
        )}
      </div>
    </motion.div>
  );
}

