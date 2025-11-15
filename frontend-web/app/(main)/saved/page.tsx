'use client';

/**
 * Saved Posts & Articles Page
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Displays all saved content with filters for Posts and Articles
 */

import { useState, useEffect, useCallback } from 'react';
import { MainLayout } from '@/components/layout/MainLayout';
import { Loader2, Bookmark, Grid3x3, Newspaper, RefreshCw } from 'lucide-react';
import { Post, postsAPI } from '@/lib/api/posts';
import PostCard from '@/components/posts/PostCard';
import CommentModal from '@/components/posts/CommentModal';
import { toast } from '@/components/ui/Toast';
import { useRouter } from 'next/navigation';

type FilterType = 'all' | 'posts' | 'articles';

export default function SavedPage() {
  const router = useRouter();
  const [posts, setPosts] = useState<Post[]>([]);
  const [filteredPosts, setFilteredPosts] = useState<Post[]>([]);
  const [activeFilter, setActiveFilter] = useState<FilterType>('all');
  const [isLoading, setIsLoading] = useState(true);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const [page, setPage] = useState(0);
  const [hasMore, setHasMore] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedPostForComment, setSelectedPostForComment] = useState<Post | null>(null);

  // Filter posts based on active filter
  useEffect(() => {
    if (activeFilter === 'all') {
      setFilteredPosts(posts);
    } else if (activeFilter === 'posts') {
      setFilteredPosts(posts.filter(p => p.post_type === 'post' || p.post_type === 'poll'));
    } else if (activeFilter === 'articles') {
      setFilteredPosts(posts.filter(p => p.post_type === 'article'));
    }
  }, [posts, activeFilter]);

  // Load initial feed
  useEffect(() => {
    loadFeed(true);
  }, []);

  const loadFeed = async (reset = false) => {
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
      const response = await postsAPI.getSavedPosts('Saved', currentPage, 20);

      if (response.success) {
        if (reset) {
          setPosts(response.posts);
        } else {
          setPosts(prev => [...prev, ...response.posts]);
        }
        
        setHasMore(response.has_more);
        setPage(currentPage + 1);
      } else {
        throw new Error('Failed to load saved posts');
      }
    } catch (error: any) {
      console.error('Failed to load saved posts:', error);
      setError(error.message || 'Failed to load saved posts');
      toast.error('Failed to load saved posts');
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
      loadFeed(false);
    }
  }, [isLoadingMore, hasMore, page]);

  useEffect(() => {
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, [handleScroll]);

  const handleRefresh = () => {
    loadFeed(true);
  };

  const handleSave = async (post: Post) => {
    try {
      if (post.is_saved) {
        await postsAPI.unsavePost(post.id);
        setPosts(prev => prev.filter(p => p.id !== post.id));
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

  const getFilterCount = (filter: FilterType) => {
    if (filter === 'all') return posts.length;
    if (filter === 'posts') return posts.filter(p => p.post_type === 'post' || p.post_type === 'poll').length;
    if (filter === 'articles') return posts.filter(p => p.post_type === 'article').length;
    return 0;
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
            <Bookmark className="w-10 h-10 text-neutral-400" />
          </div>
          <h3 className="text-xl font-semibold text-neutral-900 dark:text-neutral-50 mb-2">
            Failed to load saved posts
          </h3>
          <p className="text-neutral-600 dark:text-neutral-400 mb-4">{error}</p>
          <button
            onClick={handleRefresh}
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
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl md:text-3xl font-bold text-neutral-900 dark:text-neutral-50">
              Saved
            </h1>
            <p className="text-sm text-neutral-600 dark:text-neutral-400 mt-1">
              {posts.length} {posts.length === 1 ? 'item' : 'items'} saved
            </p>
          </div>
        </div>

        {/* Filter Tabs */}
        <div className="flex gap-2 overflow-x-auto scrollbar-hide pb-1 -mx-4 px-4 md:mx-0 md:px-0">
          {[
            { id: 'all' as FilterType, label: 'All', icon: Bookmark },
            { id: 'posts' as FilterType, label: 'Posts', icon: Grid3x3 },
            { id: 'articles' as FilterType, label: 'Articles', icon: Newspaper },
          ].map((filter) => {
            const Icon = filter.icon;
            const count = getFilterCount(filter.id);
            return (
              <button
                key={filter.id}
                onClick={() => setActiveFilter(filter.id)}
                className={`px-4 py-2 rounded-full text-sm font-semibold whitespace-nowrap transition-all duration-200 flex-shrink-0 flex items-center gap-2 ${
                  activeFilter === filter.id
                    ? 'bg-purple-600 text-white shadow-md'
                    : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-700 dark:text-neutral-300 hover:bg-neutral-200 dark:hover:bg-neutral-700'
                }`}
              >
                <Icon className="w-4 h-4" />
                <span>{filter.label}</span>
                {count > 0 && (
                  <span className={`px-2 py-0.5 rounded-full text-xs ${
                    activeFilter === filter.id
                      ? 'bg-white/20 text-white'
                      : 'bg-neutral-200 dark:bg-neutral-700 text-neutral-600 dark:text-neutral-400'
                  }`}>
                    {count}
                  </span>
                )}
              </button>
            );
          })}
        </div>

        {/* Refresh Button (Mobile) */}
        <div className="md:hidden flex justify-center">
          <button
            onClick={handleRefresh}
            disabled={isLoading}
            className="flex items-center gap-2 px-4 py-2 bg-neutral-100 dark:bg-neutral-800 hover:bg-neutral-200 dark:hover:bg-neutral-700 rounded-full transition-colors text-sm font-medium"
          >
            <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin' : ''}`} />
            Refresh
          </button>
        </div>

        {/* Empty State */}
        {filteredPosts.length === 0 && posts.length === 0 && (
          <div className="text-center py-20">
            <div className="w-20 h-20 mx-auto mb-4 bg-neutral-100 dark:bg-neutral-800 rounded-full flex items-center justify-center">
              <Bookmark className="w-10 h-10 text-neutral-400" />
            </div>
            <h3 className="text-xl font-semibold text-neutral-900 dark:text-neutral-50 mb-2">
              No saved items yet
            </h3>
            <p className="text-neutral-600 dark:text-neutral-400 mb-6">
              Save posts and articles you want to read later
            </p>
            <button
              onClick={() => router.push('/home')}
              className="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg transition-colors"
            >
              Explore Feed
            </button>
          </div>
        )}

        {/* Filtered Empty State */}
        {filteredPosts.length === 0 && posts.length > 0 && (
          <div className="text-center py-20">
            <div className="w-20 h-20 mx-auto mb-4 bg-neutral-100 dark:bg-neutral-800 rounded-full flex items-center justify-center">
              {activeFilter === 'posts' ? (
                <Grid3x3 className="w-10 h-10 text-neutral-400" />
              ) : (
                <Newspaper className="w-10 h-10 text-neutral-400" />
              )}
            </div>
            <h3 className="text-xl font-semibold text-neutral-900 dark:text-neutral-50 mb-2">
              No {activeFilter === 'posts' ? 'posts' : 'articles'} saved yet
            </h3>
            <p className="text-neutral-600 dark:text-neutral-400">
              Save {activeFilter === 'posts' ? 'posts' : 'articles'} to see them here
            </p>
          </div>
        )}

        {/* Posts/Articles List */}
        {filteredPosts.length > 0 && (
          <div className="space-y-6">
            {filteredPosts.map((post) => (
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
              loadFeed(true);
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
        {!hasMore && filteredPosts.length > 0 && (
          <div className="text-center py-6 text-neutral-500 dark:text-neutral-400 text-sm">
            You've reached the end
          </div>
        )}
      </div>
    </MainLayout>
  );
}

