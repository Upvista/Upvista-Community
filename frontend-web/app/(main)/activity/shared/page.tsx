'use client';

/**
 * Activity Shared Page
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Shows user's shared posts and articles
 */

import { useState, useEffect, useCallback } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { MainLayout } from '@/components/layout/MainLayout';
import { Loader2, Share2, ArrowLeft, Grid3x3, Newspaper, Video, Briefcase } from 'lucide-react';
import { Post, postsAPI } from '@/lib/api/posts';
import PostCard from '@/components/posts/PostCard';
import CommentModal from '@/components/posts/CommentModal';
import { toast } from '@/components/ui/Toast';

export default function SharedPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const filter = (searchParams.get('filter') || 'posts') as 'posts' | 'articles' | 'reels' | 'projects';
  
  const [posts, setPosts] = useState<Post[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const [page, setPage] = useState(0);
  const [hasMore, setHasMore] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedPostForComment, setSelectedPostForComment] = useState<Post | null>(null);

  // Load shared content when filter changes
  useEffect(() => {
    loadShared(true);
  }, [filter]);

  const loadShared = async (reset = false) => {
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
      const response = await postsAPI.getUserShared(filter, currentPage, 20);

      if (response.success) {
        if (reset) {
          setPosts(response.posts);
        } else {
          setPosts(prev => [...prev, ...response.posts]);
        }
        
        setHasMore(response.has_more);
        setPage(currentPage + 1);
      } else {
        throw new Error('Failed to load shared content');
      }
    } catch (error: any) {
      console.error('Failed to load shared content:', error);
      setError(error.message || 'Failed to load shared content');
      toast.error('Failed to load shared content');
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
      loadShared(false);
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
            <Share2 className="w-10 h-10 text-neutral-400" />
          </div>
          <h3 className="text-xl font-semibold text-neutral-900 dark:text-neutral-50 mb-2">
            Failed to load shared content
          </h3>
          <p className="text-neutral-600 dark:text-neutral-400 mb-4">{error}</p>
          <button
            onClick={() => loadShared(true)}
            className="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg transition-colors"
          >
            Try Again
          </button>
        </div>
      </MainLayout>
    );
  }

  const filterLabels: Record<string, { label: string; icon: typeof Grid3x3 }> = {
    posts: { label: 'Posts', icon: Grid3x3 },
    articles: { label: 'Articles', icon: Newspaper },
    reels: { label: 'Reels', icon: Video },
    projects: { label: 'Projects', icon: Briefcase },
  };

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
              Content you shared
            </h1>
            <p className="text-sm text-neutral-600 dark:text-neutral-400 mt-1">
              Posts and articles you've shared
            </p>
          </div>
        </div>

        {/* Filter Tabs */}
        <div className="flex gap-2 overflow-x-auto scrollbar-hide pb-1 -mx-4 px-4 md:mx-0 md:px-0">
          {Object.entries(filterLabels).map(([key, { label, icon: Icon }]) => {
            const isActive = filter === key;
            return (
              <button
                key={key}
                onClick={() => router.push(`/activity/shared?filter=${key}`)}
                className={`px-4 py-2 rounded-full text-sm font-semibold whitespace-nowrap transition-all duration-200 flex-shrink-0 flex items-center gap-2 ${
                  isActive
                    ? 'bg-purple-600 text-white shadow-md'
                    : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-700 dark:text-neutral-300 hover:bg-neutral-200 dark:hover:bg-neutral-700'
                }`}
              >
                <Icon className="w-4 h-4" />
                <span>{label}</span>
              </button>
            );
          })}
        </div>

        {/* Empty State */}
        {posts.length === 0 && (
          <div className="text-center py-20">
            <div className="w-20 h-20 mx-auto mb-4 bg-neutral-100 dark:bg-neutral-800 rounded-full flex items-center justify-center">
              <Share2 className="w-10 h-10 text-neutral-400" />
            </div>
            <h3 className="text-xl font-semibold text-neutral-900 dark:text-neutral-50 mb-2">
              No shared {filterLabels[filter]?.label.toLowerCase() || 'content'}
            </h3>
            <p className="text-neutral-600 dark:text-neutral-400 mb-6">
              {filter === 'posts' 
                ? 'Posts you share will appear here'
                : filter === 'articles'
                ? 'Articles you share will appear here'
                : 'Content you share will appear here'}
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
              <PostCard 
                key={post.id}
                post={post}
                onComment={(p) => setSelectedPostForComment(p)}
                onShare={handleShare}
                onSave={handleSave}
              />
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
              loadShared(true);
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

