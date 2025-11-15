'use client';

/**
 * Activity Archived Page
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Shows user's archived/deleted posts (deleted posts kept for 30 days)
 */

import { useState, useEffect, useCallback } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { MainLayout } from '@/components/layout/MainLayout';
import { Loader2, Trash2, Archive, ArrowLeft, RotateCcw, Clock } from 'lucide-react';
import { Post, postsAPI } from '@/lib/api/posts';
import PostCard from '@/components/posts/PostCard';
import CommentModal from '@/components/posts/CommentModal';
import { toast } from '@/components/ui/Toast';
import { formatPostTimestamp } from '@/lib/api/posts';

export default function ArchivedPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const filter = (searchParams.get('filter') || 'deleted') as 'deleted' | 'archived';
  
  const [posts, setPosts] = useState<Post[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const [page, setPage] = useState(0);
  const [hasMore, setHasMore] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedPostForComment, setSelectedPostForComment] = useState<Post | null>(null);

  // Load archived posts when filter changes
  useEffect(() => {
    loadArchived(true);
  }, [filter]);

  const loadArchived = async (reset = false) => {
    if (reset) {
      setIsLoading(true);
      setPage(0);
      setPosts([]);
    } else {
      setIsLoadingMore(true);
    }

    setError(null);

    try {
      const currentPage = reset ? 0 : page;
      const response = await postsAPI.getUserArchived(filter, currentPage, 20);

      if (response.success) {
        if (reset) {
          setPosts(response.posts);
        } else {
          setPosts(prev => [...prev, ...response.posts]);
        }
        
        setHasMore(response.has_more);
        setPage(currentPage + 1);
      } else {
        throw new Error('Failed to load archived posts');
      }
    } catch (error: any) {
      console.error('Failed to load archived posts:', error);
      setError(error.message || 'Failed to load archived posts');
      toast.error('Failed to load archived posts');
    } finally {
      setIsLoading(false);
      setIsLoadingMore(false);
    }
  };

  const handleScroll = useCallback(() => {
    if (isLoadingMore || !hasMore) return;

    const scrollPosition = window.innerHeight + window.scrollY;
    const threshold = document.documentElement.scrollHeight - 500;

    if (scrollPosition >= threshold) {
      loadArchived(false);
    }
  }, [isLoadingMore, hasMore, page, filter]);

  useEffect(() => {
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, [handleScroll]);

  const handleSave = async (post: Post) => {
    try {
      if (post.is_saved) {
        await postsAPI.unsavePost(post.id);
        setPosts(prev => prev.map(p => 
          p.id === post.id ? { ...p, is_saved: false } : p
        ));
        toast.success('Removed from saved');
      } else {
        await postsAPI.savePost(post.id);
        setPosts(prev => prev.map(p => 
          p.id === post.id ? { ...p, is_saved: true } : p
        ));
        toast.success('Saved');
      }
    } catch (error: any) {
      toast.error(error.message || 'Failed to update save status');
    }
  };

  const handleShare = (post: Post) => {
    if (post.post_type === 'article' && post.article?.slug) {
      const url = `${window.location.origin}/articles/${post.article.slug}`;
      if (navigator.share) {
        navigator.share({
          title: post.article.title,
          text: post.article.subtitle || post.article.meta_description || '',
          url: url,
        }).catch(() => {});
      } else {
        navigator.clipboard.writeText(url);
        toast.success('Link copied to clipboard');
      }
    } else {
      const url = `${window.location.origin}/posts/${post.id}`;
      if (navigator.share) {
        navigator.share({
          title: 'Check out this post',
          text: post.content.substring(0, 100),
          url: url,
        }).catch(() => {});
      } else {
        navigator.clipboard.writeText(url);
        toast.success('Link copied to clipboard');
      }
    }
  };

  const handleRestore = async (post: Post) => {
    // TODO: Implement restore functionality
    toast.info('Restore functionality coming soon');
  };

  if (isLoading) {
    return (
      <MainLayout>
        <div className="flex items-center justify-center py-20">
          <Loader2 className="w-8 h-8 animate-spin text-purple-600" />
        </div>
      </MainLayout>
    );
  }

  if (error && posts.length === 0) {
    return (
      <MainLayout>
        <div className="text-center py-20">
          <div className="w-20 h-20 mx-auto mb-4 bg-neutral-100 dark:bg-neutral-800 rounded-full flex items-center justify-center">
            {filter === 'deleted' ? (
              <Trash2 className="w-10 h-10 text-neutral-400" />
            ) : (
              <Archive className="w-10 h-10 text-neutral-400" />
            )}
          </div>
          <h3 className="text-xl font-semibold text-neutral-900 dark:text-neutral-50 mb-2">
            Failed to load {filter === 'deleted' ? 'deleted' : 'archived'} posts
          </h3>
          <p className="text-neutral-600 dark:text-neutral-400 mb-4">{error}</p>
          <button
            onClick={() => loadArchived(true)}
            className="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg transition-colors"
          >
            Try Again
          </button>
        </div>
      </MainLayout>
    );
  }

  return (
    <MainLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.back()}
            className="p-2 hover:bg-neutral-100 dark:hover:bg-neutral-800 rounded-full transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div>
            <h1 className="text-2xl md:text-3xl font-bold text-neutral-900 dark:text-neutral-50">
              {filter === 'deleted' ? 'Recently deleted' : 'Archived'}
            </h1>
            <p className="text-sm text-neutral-600 dark:text-neutral-400 mt-1">
              {filter === 'deleted' 
                ? 'Posts deleted in the last 30 days'
                : 'Posts you\'ve archived'}
            </p>
          </div>
        </div>

        {/* Filter Tabs */}
        <div className="flex gap-2 overflow-x-auto scrollbar-hide pb-1 -mx-4 px-4 md:mx-0 md:px-0">
          {[
            { id: 'deleted' as const, label: 'Recently deleted', icon: Trash2 },
            { id: 'archived' as const, label: 'Archived', icon: Archive },
          ].map((tab) => {
            const Icon = tab.icon;
            const isActive = filter === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => router.push(`/activity/archived?filter=${tab.id}`)}
                className={`px-4 py-2 rounded-full text-sm font-semibold whitespace-nowrap transition-all duration-200 flex-shrink-0 flex items-center gap-2 ${
                  isActive
                    ? 'bg-purple-600 text-white shadow-md'
                    : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-700 dark:text-neutral-300 hover:bg-neutral-200 dark:hover:bg-neutral-700'
                }`}
              >
                <Icon className="w-4 h-4" />
                <span>{tab.label}</span>
              </button>
            );
          })}
        </div>

        {/* Empty State */}
        {posts.length === 0 && (
          <div className="text-center py-20">
            <div className="w-20 h-20 mx-auto mb-4 bg-neutral-100 dark:bg-neutral-800 rounded-full flex items-center justify-center">
              {filter === 'deleted' ? (
                <Trash2 className="w-10 h-10 text-neutral-400" />
              ) : (
                <Archive className="w-10 h-10 text-neutral-400" />
              )}
            </div>
            <h3 className="text-xl font-semibold text-neutral-900 dark:text-neutral-50 mb-2">
              No {filter === 'deleted' ? 'deleted' : 'archived'} posts
            </h3>
            <p className="text-neutral-600 dark:text-neutral-400 mb-6">
              {filter === 'deleted' 
                ? 'Posts you delete will appear here for 30 days'
                : 'Posts you archive will appear here'}
            </p>
            <button
              onClick={() => router.push('/home')}
              className="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg transition-colors"
            >
              Go to Feed
            </button>
          </div>
        )}

        {/* Posts List */}
        {posts.length > 0 && (
          <div className="space-y-6">
            {posts.map((post) => (
              <div key={post.id} className="relative">
                {/* Deleted Badge */}
                {filter === 'deleted' && post.deleted_at && (
                  <div className="mb-2 flex items-center gap-2 text-xs text-neutral-500 dark:text-neutral-400">
                    <Clock className="w-3 h-3" />
                    <span>Deleted {formatPostTimestamp(post.deleted_at)}</span>
                    {(() => {
                      const deletedDate = new Date(post.deleted_at);
                      const daysSinceDeleted = Math.floor((Date.now() - deletedDate.getTime()) / (1000 * 60 * 60 * 24));
                      const daysRemaining = 30 - daysSinceDeleted;
                      return daysRemaining > 0 ? (
                        <span className="text-orange-500">• {daysRemaining} days until permanent deletion</span>
                      ) : null;
                    })()}
                  </div>
                )}
                
                <PostCard 
                  post={post}
                  onComment={(p) => setSelectedPostForComment(p)}
                  onShare={handleShare}
                  onSave={handleSave}
                />
                
                {/* Restore Button (for deleted posts) */}
                {filter === 'deleted' && (
                  <div className="mt-2 flex justify-end">
                    <button
                      onClick={() => handleRestore(post)}
                      className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-purple-600 dark:text-purple-400 hover:bg-purple-50 dark:hover:bg-purple-900/20 rounded-lg transition-colors"
                    >
                      <RotateCcw className="w-4 h-4" />
                      Restore
                    </button>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}

        {/* Comment Modal */}
        {selectedPostForComment && (
          <CommentModal
            post={selectedPostForComment}
            isOpen={!!selectedPostForComment}
            onClose={() => {
              setSelectedPostForComment(null);
              // Refresh to show updated comment counts
              loadArchived(true);
            }}
          />
        )}

        {/* Load More Indicator */}
        {isLoadingMore && (
          <div className="flex justify-center py-6">
            <Loader2 className="w-6 h-6 animate-spin text-purple-600" />
          </div>
        )}

        {/* End of Feed */}
        {!hasMore && posts.length > 0 && (
          <div className="text-center py-6 text-neutral-500 dark:text-neutral-400 text-sm">
            You've reached the end
          </div>
        )}
      </div>
    </MainLayout>
  );
}

