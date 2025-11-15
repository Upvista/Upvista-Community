'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { MoreVertical, Pin, ArrowRight, Clock, BookOpen } from 'lucide-react';
import { motion } from 'framer-motion';
import { Post, formatPostTimestamp, highlightHashtagsAndMentions } from '@/lib/api/posts';
import { Avatar } from '../ui/Avatar';
import { Badge } from '../ui/Badge';
import { Card } from '../ui/Card';
import VerifiedBadge from '../ui/VerifiedBadge';
import PostActions from './PostActions';
import PollCard from './PollCard';
import { Modal } from '../ui/Modal';
import ArticleView from './ArticleView';
import CommentModal from './CommentModal';

interface PostCardProps {
  post: Post;
  onPostClick?: (post: Post) => void;
  onComment?: (post: Post) => void;
  onShare?: (post: Post) => void;
  onSave?: (post: Post) => void;
}

export default function PostCard({ 
  post, 
  onPostClick,
  onComment,
  onShare,
  onSave 
}: PostCardProps) {
  const router = useRouter();
  const [showMenu, setShowMenu] = useState(false);
  const [showArticleModal, setShowArticleModal] = useState(false);
  const [showCommentModal, setShowCommentModal] = useState(false);

  const handleProfileClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (post.author?.username) {
      router.push(`/profile?u=${post.author.username}`);
    }
  };

  // If it's a poll, use PollCard
  if (post.post_type === 'poll' && post.poll) {
    return <PollCard post={post} poll={post.poll} />;
  }

  // If it's an article, render professional article card
  const isArticle = post.post_type === 'article' || (post.article !== undefined && post.article !== null);
  
  if (isArticle && post.article) {
    return (
      <>
        <motion.div
          whileHover={{ y: -2 }}
          transition={{ duration: 0.2 }}
        >
          <Card variant="glass" hoverable={false} className="p-0 overflow-hidden">
            {/* Cover Image - Full Width */}
            {post.article.cover_image_url && (
              <div className="w-full h-56 md:h-64 -mt-6 -mx-6 mb-6 relative overflow-hidden">
                <img
                  src={post.article.cover_image_url}
                  alt={post.article.title}
                  className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent" />
              </div>
            )}

            <div className="px-6 pt-6 pb-6">
              {/* Header */}
              <div className="flex items-start justify-between mb-5 pt-2">
                <div className="flex items-center gap-3 flex-1 min-w-0">
                  <button
                    onClick={handleProfileClick}
                    className="flex-shrink-0 cursor-pointer hover:opacity-80 transition-opacity"
                  >
                    <Avatar 
                      src={post.author?.profile_picture} 
                      alt={post.author?.display_name || post.author?.username || 'User'} 
                      fallback={post.author?.display_name || post.author?.username || 'U'}
                      size="md"
                    />
                  </button>
                  <div className="flex-1 min-w-0">
                    <button
                      onClick={handleProfileClick}
                      className="flex items-center gap-1.5 hover:opacity-80 transition-opacity w-full"
                    >
                      <h3 className="text-sm font-semibold text-neutral-900 dark:text-neutral-50 truncate">
                        {post.author?.display_name || post.author?.username}
                      </h3>
                      {post.author?.is_verified && (
                        <>
                          <span className="text-xs text-neutral-400 dark:text-neutral-600">·</span>
                          <VerifiedBadge size="sm" variant="badge" showText={false} />
                        </>
                      )}
                      <span className="text-xs text-neutral-400 dark:text-neutral-600">·</span>
                      <span className="text-xs text-neutral-500 dark:text-neutral-400 whitespace-nowrap">
                        {formatPostTimestamp(post.created_at)}
                      </span>
                    </button>
                    <button
                      onClick={handleProfileClick}
                      className="text-xs text-neutral-500 dark:text-neutral-400 hover:text-neutral-700 dark:hover:text-neutral-300 transition-colors"
                    >
                      @{post.author?.username}
                    </button>
                  </div>
                </div>
                <button 
                  onClick={(e) => {
                    e.stopPropagation();
                    setShowMenu(!showMenu);
                  }}
                  className="text-neutral-400 hover:text-neutral-600 dark:hover:text-neutral-300 p-1 rounded-full hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors"
                >
                  <MoreVertical className="w-5 h-5" />
                </button>
              </div>

              {/* Article Content */}
              <div className="mb-5">
                {/* Article Type Badge */}
                <div className="inline-flex items-center gap-1.5 px-2.5 py-1 bg-neutral-100 dark:bg-neutral-800 rounded-md mb-4">
                  <BookOpen className="w-3.5 h-3.5 text-neutral-600 dark:text-neutral-400" />
                  <span className="text-xs font-medium text-neutral-700 dark:text-neutral-300 uppercase tracking-wide">
                    Article
                  </span>
                </div>

                {/* Title */}
                <h2 className="text-2xl font-bold text-neutral-900 dark:text-neutral-50 mb-3 leading-tight">
                  {post.article.title}
                </h2>

                {/* Subtitle - Justified */}
                {post.article.subtitle && (
                  <p className="text-base text-neutral-600 dark:text-neutral-400 mb-4 line-clamp-3 leading-relaxed text-justify" style={{ textAlignLast: 'left' }}>
                    {post.article.subtitle}
                  </p>
                )}

                {/* Meta Information with Read More Link */}
                <div className="flex items-center gap-4 text-sm text-neutral-500 dark:text-neutral-400 mb-5 flex-wrap">
                  <div className="flex items-center gap-1.5">
                    <Clock className="w-4 h-4" />
                    <span>{post.article.read_time_minutes} min read</span>
                  </div>
                  {post.article.category && (
                    <>
                      <span className="text-neutral-300 dark:text-neutral-600">·</span>
                      <span className="font-medium">{post.article.category}</span>
                    </>
                  )}
                  {post.article.views_count > 0 && (
                    <>
                      <span className="text-neutral-300 dark:text-neutral-600">·</span>
                      <span>{post.article.views_count.toLocaleString()} views</span>
                    </>
                  )}
                  <span className="text-neutral-300 dark:text-neutral-600">·</span>
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      e.preventDefault();
                      setShowArticleModal(true);
                    }}
                    className="flex items-center gap-1.5 text-purple-600 dark:text-purple-400 hover:text-purple-700 dark:hover:text-purple-300 font-medium transition-colors group"
                  >
                    <span>Read Full Article</span>
                    <ArrowRight className="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
                  </button>
                </div>
              </div>

              {/* Actions */}
              <PostActions
                postId={post.id}
                isLiked={post.is_liked}
                isSaved={post.is_saved}
                likesCount={post.likes_count}
                commentsCount={post.comments_count}
                sharesCount={post.shares_count}
                onComment={() => setShowCommentModal(true)}
                onShare={() => onShare?.(post)}
                onSave={() => onSave?.(post)}
              />
            </div>
          </Card>
        </motion.div>

        {/* Article Modal */}
        <Modal
          isOpen={showArticleModal}
          onClose={() => setShowArticleModal(false)}
          size="full"
        >
          <ArticleView
            post={post}
            onComment={() => {
              setShowArticleModal(false);
              setShowCommentModal(true);
            }}
            onShare={onShare}
            onSave={onSave}
          />
        </Modal>

        {/* Comment Modal */}
        <CommentModal
          post={post}
          isOpen={showCommentModal}
          onClose={() => setShowCommentModal(false)}
        />
      </>
    );
  }

  // Standard text/image post
  return (
    <motion.div
      whileHover={{ y: -2 }}
      transition={{ duration: 0.2 }}
      onClick={() => onPostClick?.(post)}
      className="cursor-pointer"
    >
      <Card variant="glass" hoverable={false} className="p-6 overflow-hidden">
        {/* Header */}
        <div className="flex items-start justify-between mb-4 pt-2">
          <div className="flex items-center gap-3 flex-1 min-w-0">
            <button
              onClick={handleProfileClick}
              className="flex-shrink-0 cursor-pointer hover:opacity-80 transition-opacity"
            >
              <Avatar 
                src={post.author?.profile_picture} 
                alt={post.author?.display_name || post.author?.username || 'User'} 
                fallback={post.author?.display_name || post.author?.username || 'U'}
                size="lg"
              />
            </button>
            <div className="flex-1 min-w-0">
              <div className="flex items-center justify-between gap-2">
                <button
                  onClick={handleProfileClick}
                  className="flex items-center gap-1.5 hover:opacity-80 transition-opacity flex-1 min-w-0"
                >
                  <h3 className="text-base font-semibold text-neutral-900 dark:text-neutral-50 truncate">
                    {post.author?.display_name || post.author?.username}
                  </h3>
                  {post.author?.is_verified && (
                    <>
                      <span className="text-sm text-neutral-400 dark:text-neutral-600">·</span>
                      <VerifiedBadge size="sm" variant="badge" showText={false} />
                    </>
                  )}
                  <span className="text-sm text-neutral-400 dark:text-neutral-600">·</span>
                  <span className="text-sm text-neutral-500 dark:text-neutral-400 whitespace-nowrap">
                    {formatPostTimestamp(post.created_at)}
                  </span>
                </button>
                {post.is_pinned && (
                  <Pin className="w-4 h-4 text-purple-600 fill-current flex-shrink-0" />
                )}
              </div>
              <button
                onClick={handleProfileClick}
                className="text-sm text-neutral-500 dark:text-neutral-400 hover:text-neutral-700 dark:hover:text-neutral-300 transition-colors"
              >
                @{post.author?.username}
              </button>
            </div>
          </div>
          <button 
            onClick={(e) => {
              e.stopPropagation();
              setShowMenu(!showMenu);
            }}
            className="text-neutral-400 hover:text-neutral-600 dark:hover:text-neutral-300 p-1"
          >
            <MoreVertical className="w-5 h-5" />
          </button>
        </div>

        {/* Content - Justified */}
        <div className="mb-4">
          <p className="text-base text-neutral-700 dark:text-neutral-300 whitespace-pre-wrap break-words text-justify" style={{ textAlignLast: 'left' }}>
            {highlightHashtagsAndMentions(post.content)}
          </p>
        </div>

        {/* Media (if exists) */}
        {post.media_urls && post.media_urls.length > 0 && (
          <div className="mb-4">
            {post.media_types?.[0] === 'video' ? (
              <video
                src={post.media_urls[0]}
                controls
                className="w-full rounded-xl max-h-96 object-cover"
              />
            ) : post.media_urls.length === 1 ? (
              <img
                src={post.media_urls[0]}
                alt="Post media"
                className="w-full rounded-xl max-h-96 object-cover"
              />
            ) : (
              <div className={`grid ${
                post.media_urls.length === 2 ? 'grid-cols-2' :
                post.media_urls.length === 3 ? 'grid-cols-3' :
                'grid-cols-2'
              } gap-2`}>
                {post.media_urls.slice(0, 4).map((url, index) => (
                  <div key={index} className="relative">
                    <img
                      src={url}
                      alt={`Media ${index + 1}`}
                      className="w-full h-48 object-cover rounded-lg"
                    />
                    {index === 3 && post.media_urls!.length > 4 && (
                      <div className="absolute inset-0 bg-black/60 rounded-lg flex items-center justify-center">
                        <span className="text-white text-2xl font-bold">
                          +{post.media_urls!.length - 4}
                        </span>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Actions */}
        <PostActions
          postId={post.id}
          isLiked={post.is_liked}
          isSaved={post.is_saved}
          likesCount={post.likes_count}
          commentsCount={post.comments_count}
          sharesCount={post.shares_count}
          onComment={() => setShowCommentModal(true)}
          onShare={() => onShare?.(post)}
          onSave={() => onSave?.(post)}
        />
      </Card>

      {/* Comment Modal */}
      <CommentModal
        post={post}
        isOpen={showCommentModal}
        onClose={() => setShowCommentModal(false)}
      />
    </motion.div>
  );
}

