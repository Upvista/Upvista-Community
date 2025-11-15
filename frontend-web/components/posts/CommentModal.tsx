'use client';

import { useState, useEffect, useRef } from 'react';
import { X, Heart, MoreVertical, Reply, Trash2, Edit2, Smile } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { Post, Comment, postsAPI, formatPostTimestamp } from '@/lib/api/posts';
import { Avatar } from '../ui/Avatar';
import VerifiedBadge from '../ui/VerifiedBadge';
import { toast } from '../ui/Toast';
import CommentInput from './CommentInput';
import { useUser } from '@/lib/hooks/useUser';
import NotificationWebSocket from '@/lib/websocket/NotificationWebSocket';

interface CommentModalProps {
  post: Post;
  isOpen: boolean;
  onClose: () => void;
}

export default function CommentModal({ post, isOpen, onClose }: CommentModalProps) {
  const { user } = useUser();
  const [comments, setComments] = useState<Comment[]>([]);
  const [loading, setLoading] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [page, setPage] = useState(0);
  const [replyingTo, setReplyingTo] = useState<Comment | null>(null);
  const [editingComment, setEditingComment] = useState<Comment | null>(null);
  const [showMenu, setShowMenu] = useState<string | null>(null);
  const commentsEndRef = useRef<HTMLDivElement>(null);
  const scrollContainerRef = useRef<HTMLDivElement>(null);

  const limit = 20;

  // Load comments
  const loadComments = async (reset = false) => {
    if (loading) return;
    
    setLoading(true);
    try {
      const currentPage = reset ? 0 : page;
      const response = await postsAPI.getComments(post.id, currentPage, limit);
      
      if (response.success) {
        if (reset) {
          setComments(response.comments);
        } else {
          setComments(prev => [...prev, ...response.comments]);
        }
        setHasMore(response.has_more);
        setPage(currentPage + 1);
      }
    } catch (error: any) {
      console.error('Failed to load comments:', error);
      toast.error('Failed to load comments');
    } finally {
      setLoading(false);
    }
  };

  // Load comments when modal opens
  useEffect(() => {
    if (isOpen) {
      setPage(0);
      setHasMore(true);
      loadComments(true);
      // Prevent body scroll
      document.body.style.overflow = 'hidden';
    } else {
      // Restore body scroll
      document.body.style.overflow = '';
    }
    return () => {
      document.body.style.overflow = '';
    };
  }, [isOpen, post.id]);

  // Scroll to bottom when new comment is added
  useEffect(() => {
    if (commentsEndRef.current && comments.length > 0) {
      commentsEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [comments.length]);

  // WebSocket real-time comment updates
  useEffect(() => {
    if (!isOpen) return;

    const ws = NotificationWebSocket.getInstance();
    
    // Listen for new comments
    const handleNewComment = (data: any) => {
      if (data.type === 'new_comment' && data.comment && data.comment.post_id === post.id) {
        // Add new comment to the list
        setComments(prev => {
          // Check if comment already exists
          const exists = prev.some(c => c.id === data.comment.id);
          if (exists) return prev;
          
          // If it's a reply, add to parent's replies
          if (data.comment.parent_comment_id) {
            return prev.map(comment => {
              if (comment.id === data.comment.parent_comment_id) {
                return {
                  ...comment,
                  replies_count: comment.replies_count + 1,
                  replies: [...(comment.replies || []), data.comment],
                };
              }
              return comment;
            });
          }
          // Otherwise, add as top-level comment
          return [data.comment, ...prev];
        });
      }
    };

    // Listen for comment updates
    const handleCommentUpdate = (data: any) => {
      if (data.type === 'comment_updated' && data.comment && data.post_id === post.id) {
        setComments(prev => updateCommentInList(prev, data.comment));
      }
    };

    ws.on('new_comment', handleNewComment);
    ws.on('comment_updated', handleCommentUpdate);
    ws.on('comment_reply', handleNewComment);

    return () => {
      ws.off('new_comment', handleNewComment);
      ws.off('comment_updated', handleCommentUpdate);
      ws.off('comment_reply', handleNewComment);
    };
  }, [isOpen, post.id]);

  // Handle scroll for infinite loading
  const handleScroll = () => {
    if (!scrollContainerRef.current || loading || !hasMore) return;
    
    const { scrollTop, scrollHeight, clientHeight } = scrollContainerRef.current;
    if (scrollHeight - scrollTop - clientHeight < 100) {
      loadComments(false);
    }
  };

  // Create comment
  const handleCreateComment = async (content: string) => {
    try {
      const requestData: any = {
        post_id: post.id, // Backend requires post_id in body even though it's in URL
        content,
      };
      
      // Only include parent_comment_id if replying
      if (replyingTo?.id) {
        requestData.parent_comment_id = replyingTo.id;
      }
      
      const response = await postsAPI.createComment(post.id, requestData);

      if (response.success && response.comment) {
        if (replyingTo) {
          // Add reply to parent comment
          setComments(prev => prev.map(comment => {
            if (comment.id === replyingTo.id) {
              return {
                ...comment,
                replies_count: comment.replies_count + 1,
                replies: [...(comment.replies || []), response.comment!],
              };
            }
            return comment;
          }));
        } else {
          // Add new top-level comment
          setComments(prev => [response.comment!, ...prev]);
        }
        setReplyingTo(null);
        toast.success('Comment posted');
      }
    } catch (error: any) {
      console.error('Failed to create comment:', error);
      toast.error('Failed to post comment');
    }
  };

  // Like comment
  const handleLikeComment = async (comment: Comment) => {
    try {
      await postsAPI.likeComment(comment.id);
      setComments(prev => updateCommentLikes(prev, comment.id, !comment.is_liked));
    } catch (error: any) {
      console.error('Failed to like comment:', error);
      toast.error('Failed to like comment');
    }
  };

  // Update comment likes in nested structure
  const updateCommentLikes = (commentsList: Comment[], commentId: string, isLiked: boolean): Comment[] => {
    return commentsList.map(comment => {
      if (comment.id === commentId) {
        return {
          ...comment,
          is_liked: isLiked,
          likes_count: isLiked ? comment.likes_count + 1 : comment.likes_count - 1,
        };
      }
      if (comment.replies) {
        return {
          ...comment,
          replies: updateCommentLikes(comment.replies, commentId, isLiked),
        };
      }
      return comment;
    });
  };

  // Delete comment
  const handleDeleteComment = async (comment: Comment) => {
    try {
      await postsAPI.deleteComment(comment.id);
      setComments(prev => removeComment(prev, comment.id));
      setShowMenu(null);
      toast.success('Comment deleted');
    } catch (error: any) {
      console.error('Failed to delete comment:', error);
      toast.error('Failed to delete comment');
    }
  };

  // Remove comment from nested structure
  const removeComment = (commentsList: Comment[], commentId: string): Comment[] => {
    return commentsList
      .filter(comment => comment.id !== commentId)
      .map(comment => {
        if (comment.replies) {
          return {
            ...comment,
            replies: removeComment(comment.replies, commentId),
            replies_count: comment.replies.filter(r => r.id !== commentId).length,
          };
        }
        return comment;
      });
  };

  // Update comment
  const handleUpdateComment = async (comment: Comment, newContent: string) => {
    try {
      const response = await postsAPI.updateComment(comment.id, newContent);
      if (response.success && response.comment) {
        // Use the updated comment from the server response
        setComments(prev => updateCommentInList(prev, response.comment!));
        setEditingComment(null);
        toast.success('Comment updated');
      } else {
        toast.error(response.message || 'Failed to update comment');
      }
    } catch (error: any) {
      console.error('Failed to update comment:', error);
      toast.error('Failed to update comment');
    }
  };

  // Update comment in nested structure using server response
  const updateCommentInList = (commentsList: Comment[], updatedComment: Comment): Comment[] => {
    return commentsList.map(comment => {
      if (comment.id === updatedComment.id) {
        return updatedComment;
      }
      if (comment.replies) {
        return {
          ...comment,
          replies: updateCommentInList(comment.replies, updatedComment),
        };
      }
      return comment;
    });
  };

  // Load replies for a comment
  const loadReplies = async (comment: Comment) => {
    if (comment.replies && comment.replies.length > 0) return; // Already loaded
    
    try {
      const response = await postsAPI.getComments(post.id, 0, 50);
      if (response.success) {
        const replies = response.comments.filter(c => c.parent_comment_id === comment.id);
        setComments(prev => prev.map(c => {
          if (c.id === comment.id) {
            return { ...c, replies };
          }
          return c;
        }));
      }
    } catch (error) {
      console.error('Failed to load replies:', error);
    }
  };

  if (!isOpen) return null;

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-[300] flex items-end md:items-center justify-center">
        {/* Backdrop */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.2 }}
          className="absolute inset-0 bg-black/60 backdrop-blur-sm"
          onClick={onClose}
        />

        {/* Modal Content */}
        <motion.div
          initial={{ opacity: 0, y: '100%' }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: '100%' }}
          transition={{ duration: 0.3, ease: 'easeOut' }}
          className="relative bg-white dark:bg-gray-900 w-full h-[90vh] md:h-[80vh] md:max-w-2xl md:rounded-xl shadow-2xl flex flex-col overflow-hidden"
          onClick={(e) => e.stopPropagation()}
        >
          {/* Header */}
          <div className="flex items-center justify-between px-4 py-3 border-b border-neutral-200 dark:border-neutral-800 flex-shrink-0">
            <h2 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50">
              Comments
            </h2>
            <button
              onClick={onClose}
              className="p-2 hover:bg-neutral-100 dark:hover:bg-neutral-800 rounded-full transition-colors"
            >
              <X className="w-5 h-5 text-neutral-600 dark:text-neutral-400" />
            </button>
          </div>

          {/* Post Preview (Mobile) */}
          <div className="md:hidden px-4 py-3 border-b border-neutral-200 dark:border-neutral-800 flex items-center gap-3 flex-shrink-0">
            <Avatar
              src={post.author?.profile_picture}
              alt={post.author?.display_name || post.author?.username || 'User'}
              fallback={post.author?.display_name || post.author?.username || 'U'}
              size="sm"
            />
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-1.5">
                <span className="text-sm font-semibold text-neutral-900 dark:text-neutral-50 truncate">
                  {post.author?.display_name || post.author?.username}
                </span>
                {post.author?.is_verified && (
                  <VerifiedBadge size="sm" variant="badge" showText={false} />
                )}
              </div>
              <p className="text-xs text-neutral-500 dark:text-neutral-400 line-clamp-1">
                {post.content}
              </p>
            </div>
          </div>

          {/* Comments List */}
          <div
            ref={scrollContainerRef}
            onScroll={handleScroll}
            className="flex-1 overflow-y-auto px-4 py-4 space-y-4"
          >
            {comments.length === 0 && !loading ? (
              <div className="flex flex-col items-center justify-center h-full text-center py-12">
                <p className="text-neutral-500 dark:text-neutral-400 mb-2">No comments yet</p>
                <p className="text-sm text-neutral-400 dark:text-neutral-500">
                  Be the first to comment!
                </p>
              </div>
            ) : (
              <>
                {comments
                  .filter(c => !c.parent_comment_id) // Only show top-level comments
                  .map((comment) => (
                    <CommentItem
                      key={comment.id}
                      comment={comment}
                      currentUserId={user?.id}
                      onLike={() => handleLikeComment(comment)}
                      onReply={() => setReplyingTo(comment)}
                      onEdit={() => setEditingComment(comment)}
                      onDelete={() => handleDeleteComment(comment)}
                      onLoadReplies={() => loadReplies(comment)}
                    showMenu={showMenu}
                    onToggleMenu={(commentId) => setShowMenu(showMenu === commentId ? null : commentId)}
                    depth={0}
                    />
                  ))}
                {loading && (
                  <div className="text-center py-4">
                    <p className="text-sm text-neutral-500 dark:text-neutral-400">Loading...</p>
                  </div>
                )}
                <div ref={commentsEndRef} />
              </>
            )}
          </div>

          {/* Comment Input */}
          <div className="border-t border-neutral-200 dark:border-neutral-800 flex-shrink-0">
            {replyingTo && (
              <div className="px-4 py-2 bg-neutral-50 dark:bg-neutral-900 flex items-center justify-between">
                <div className="flex items-center gap-2 flex-1 min-w-0">
                  <Reply className="w-4 h-4 text-purple-600 dark:text-purple-400 flex-shrink-0" />
                  <span className="text-sm text-neutral-600 dark:text-neutral-400 truncate">
                    Replying to <span className="font-semibold">{replyingTo.author?.display_name || replyingTo.author?.username}</span>
                  </span>
                </div>
                <button
                  onClick={() => setReplyingTo(null)}
                  className="text-neutral-400 hover:text-neutral-600 dark:hover:text-neutral-300"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            )}
            <CommentInput
              onSubmit={handleCreateComment}
              onCancel={() => {
                setReplyingTo(null);
                setEditingComment(null);
              }}
              editingComment={editingComment}
              onUpdate={(newContent) => editingComment && handleUpdateComment(editingComment, newContent)}
              placeholder={replyingTo ? `Reply to ${replyingTo.author?.display_name || replyingTo.author?.username}...` : 'Add a comment...'}
            />
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}

// Comment Item Component
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

function CommentItem({
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

  return (
    <div className="flex gap-3">
      <Avatar
        src={comment.author?.profile_picture}
        alt={comment.author?.display_name || comment.author?.username || 'User'}
        fallback={comment.author?.display_name || comment.author?.username || 'U'}
        size="sm"
      />
      <div className="flex-1 min-w-0">
        {/* Comment Content */}
        <div className="bg-neutral-50 dark:bg-neutral-800 rounded-2xl px-3 py-2 mb-1">
          <div className="flex items-start justify-between gap-2 mb-1">
            <div className="flex items-center gap-1.5 flex-1 min-w-0">
              <span className="text-sm font-semibold text-neutral-900 dark:text-neutral-50 truncate">
                {comment.author?.display_name || comment.author?.username}
              </span>
              {comment.author?.is_verified && (
                <VerifiedBadge size="sm" variant="badge" showText={false} />
              )}
            </div>
            {isOwnComment && (
              <div className="relative">
                <button
                  onClick={() => onToggleMenu(comment.id)}
                  className="p-1 hover:bg-neutral-200 dark:hover:bg-neutral-700 rounded-full transition-colors"
                >
                  <MoreVertical className="w-4 h-4 text-neutral-500 dark:text-neutral-400" />
                </button>
                {showMenu === comment.id && (
                  <div className="absolute right-0 top-8 bg-white dark:bg-neutral-800 rounded-lg shadow-lg border border-neutral-200 dark:border-neutral-700 py-1 z-10 min-w-[120px]">
                    <button
                      onClick={onEdit}
                      className="w-full px-4 py-2 text-left text-sm text-neutral-700 dark:text-neutral-300 hover:bg-neutral-100 dark:hover:bg-neutral-700 flex items-center gap-2"
                    >
                      <Edit2 className="w-4 h-4" />
                      Edit
                    </button>
                    <button
                      onClick={onDelete}
                      className="w-full px-4 py-2 text-left text-sm text-red-600 dark:text-red-400 hover:bg-neutral-100 dark:hover:bg-neutral-700 flex items-center gap-2"
                    >
                      <Trash2 className="w-4 h-4" />
                      Delete
                    </button>
                  </div>
                )}
              </div>
            )}
          </div>
          <p className="text-sm text-neutral-900 dark:text-neutral-50 whitespace-pre-wrap break-words">
            {comment.content}
          </p>
          {comment.is_edited && (
            <p className="text-xs text-neutral-400 dark:text-neutral-500 mt-1">(edited)</p>
          )}
        </div>

        {/* Comment Actions */}
        <div className="flex items-center gap-4 px-1 mb-2">
          <span className="text-xs text-neutral-500 dark:text-neutral-400">
            {formatPostTimestamp(comment.created_at)}
          </span>
          <button
            onClick={onLike}
            className={`text-xs font-semibold transition-colors ${
              comment.is_liked
                ? 'text-red-600 dark:text-red-400'
                : 'text-neutral-500 dark:text-neutral-400 hover:text-red-600 dark:hover:text-red-400'
            }`}
          >
            Like
          </button>
          {depth < 2 && (
            <button
              onClick={onReply}
              className="text-xs font-semibold text-neutral-500 dark:text-neutral-400 hover:text-purple-600 dark:hover:text-purple-400 transition-colors"
            >
              Reply
            </button>
          )}
          {comment.likes_count > 0 && (
            <button
              onClick={onLike}
              className="text-xs text-neutral-500 dark:text-neutral-400 flex items-center gap-1"
            >
              <Heart className={`w-3 h-3 ${comment.is_liked ? 'fill-current text-red-600 dark:text-red-400' : ''}`} />
              {comment.likes_count}
            </button>
          )}
        </div>

        {/* Replies */}
        {showReplies && (
          <div className="ml-4 mt-2 space-y-3 border-l-2 border-neutral-200 dark:border-neutral-700 pl-4">
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
                className="text-xs text-purple-600 dark:text-purple-400 font-semibold hover:underline"
              >
                View {comment.replies_count - (comment.replies?.length || 0)} more replies
              </button>
            )}
          </div>
        )}
        {hasReplies && !showReplies && (
          <button
            onClick={onLoadReplies}
            className="text-xs text-purple-600 dark:text-purple-400 font-semibold hover:underline mt-2"
          >
            View {comment.replies_count} {comment.replies_count === 1 ? 'reply' : 'replies'}
          </button>
        )}
      </div>
    </div>
  );
}

