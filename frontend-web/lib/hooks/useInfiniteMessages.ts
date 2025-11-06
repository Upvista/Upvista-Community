/**
 * useInfiniteMessages - Infinite scroll for message history with IndexedDB caching
 * Provides fast initial load and smooth pagination
 */

import { useState, useEffect, useCallback, useRef } from 'react';
import { messagesAPI, Message } from '../api/messages';
import { messageCache } from '../utils/messageCache';

// ============================================
// ENHANCED MESSAGE CACHING
// ============================================

/**
 * Get cached messages from new robust cache
 */
async function getCachedMessages(conversationId: string): Promise<Message[] | null> {
  try {
    return await messageCache.getMessages(conversationId);
  } catch (error) {
    console.error('[MessageCache] Error getting cached messages:', error);
    return null;
  }
}

/**
 * Save messages to new robust cache
 */
async function saveCachedMessages(conversationId: string, messages: Message[]): Promise<void> {
  try {
    await messageCache.saveMessages(conversationId, messages);
  } catch (error) {
    console.error('[MessageCache] Error saving cached messages:', error);
  }
}

// ============================================
// HOOK
// ============================================

interface UseInfiniteMessagesOptions {
  conversationId: string;
  pageSize?: number;
  enableCache?: boolean;
}

export function useInfiniteMessages({
  conversationId,
  pageSize = 50,
  enableCache = true,
}: UseInfiniteMessagesOptions) {
  const [messages, setMessages] = useState<Message[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [offset, setOffset] = useState(0);
  const [cacheLoaded, setCacheLoaded] = useState(false);

  // Refs for scroll management
  const scrollRef = useRef<HTMLDivElement>(null);
  const previousScrollHeight = useRef(0);
  const shouldScrollToBottom = useRef(true);

  // ==================== INITIAL LOAD ====================

  const loadInitialMessages = async () => {
    setIsLoading(true);

    try {
      // 1. Try cache first (instant load)
      if (enableCache && !cacheLoaded) {
        const cached = await getCachedMessages(conversationId);
        if (cached && cached.length > 0) {
          console.log(`[InfiniteScroll] 📦 Loaded ${cached.length} messages from cache`);
          setMessages(cached);
          setCacheLoaded(true);
          shouldScrollToBottom.current = true;
        }
      }

      // 2. Fetch from server (refresh cache)
      const response = await messagesAPI.getMessages(conversationId, pageSize, 0);

      if (response.success) {
        const loadedMessages = response.messages || [];
        
        // Ensure messages are in chronological order (oldest first)
        const sorted = [...loadedMessages].sort((a, b) => 
          new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
        );
        
        console.log(`[InfiniteScroll] 📥 Loaded ${sorted.length} messages from server`);
        console.log(`[InfiniteScroll] Oldest: ${sorted[0]?.created_at}, Newest: ${sorted[sorted.length - 1]?.created_at}`);
        console.log(`[InfiniteScroll] hasMore: ${response.has_more}`);
        
        setMessages(sorted);
        setHasMore(response.has_more || false);
        setOffset(sorted.length);

        // Update cache
        if (enableCache) {
          await saveCachedMessages(conversationId, sorted);
        }

        // Scroll to bottom only if cache wasn't loaded
        if (!cacheLoaded) {
          shouldScrollToBottom.current = true;
        }
      }
    } catch (error) {
      console.error('[InfiniteScroll] ❌ Error loading initial messages:', error);
    } finally {
      setIsLoading(false);
    }
  };

  // ==================== LOAD MORE ====================

  const loadMore = useCallback(async () => {
    if (isLoadingMore || !hasMore || isLoading) {
      console.log('[InfiniteScroll] Skip loadMore - isLoadingMore:', isLoadingMore, 'hasMore:', hasMore, 'isLoading:', isLoading);
      return;
    }

    console.log('[InfiniteScroll] 🔄 Loading more messages from offset:', offset);
    setIsLoadingMore(true);

    // Save current scroll height to maintain position
    if (scrollRef.current) {
      previousScrollHeight.current = scrollRef.current.scrollHeight;
    }

    try {
      const response = await messagesAPI.getMessages(conversationId, pageSize, offset);
      console.log('[InfiniteScroll] API response:', response);

      if (response.success) {
        // Prepend older messages (they come in ascending order, so prepend to beginning)
        setMessages((prev) => {
          const newMessages = response.messages || [];
          
          // Deduplicate: remove any messages that already exist
          const existingIds = new Set(prev.map((m: Message) => m.id));
          const uniqueNew = newMessages.filter((m: Message) => !existingIds.has(m.id));
          
          console.log(`[InfiniteScroll] ✅ Loaded ${newMessages.length} messages, ${uniqueNew.length} unique, total now: ${prev.length + uniqueNew.length}`);
          
          // Prepend to beginning (older messages go on top)
          return [...uniqueNew, ...prev];
        });
        
        const loadedCount = response.messages?.length || 0;
        setHasMore(response.has_more || false);
        setOffset((prev) => prev + loadedCount);

        console.log('[InfiniteScroll] New offset:', offset + loadedCount, 'hasMore:', response.has_more);

        // Maintain scroll position
        shouldScrollToBottom.current = false;
      }
    } catch (error) {
      console.error('[InfiniteScroll] ❌ Error loading more messages:', error);
    } finally {
      setIsLoadingMore(false);
    }
  }, [conversationId, pageSize, offset, hasMore, isLoading, isLoadingMore]);

  // ==================== SCROLL HANDLING ====================

  /**
   * Handle scroll event - detect when to load more
   */
  const handleScroll = useCallback(() => {
    if (!scrollRef.current) return;

    const { scrollTop } = scrollRef.current;

    // If scrolled to top (within 100px), load more
    if (scrollTop < 100 && hasMore && !isLoadingMore && !isLoading) {
      console.log('[InfiniteScroll] Scroll near top, loading more messages...');
      loadMore();
    }
  }, [hasMore, isLoadingMore, isLoading, loadMore]);

  /**
   * Scroll to bottom of messages
   */
  const scrollToBottom = useCallback((smooth = false) => {
    if (scrollRef.current) {
      scrollRef.current.scrollTo({
        top: scrollRef.current.scrollHeight,
        behavior: smooth ? 'smooth' : 'auto',
      });
    }
  }, []);

  /**
   * Maintain scroll position after loading more messages
   */
  useEffect(() => {
    if (shouldScrollToBottom.current && scrollRef.current) {
      // Scroll to bottom for new messages
      scrollToBottom(false);
      shouldScrollToBottom.current = false;
    } else if (scrollRef.current && previousScrollHeight.current > 0) {
      // Maintain position after loading older messages
      const newScrollHeight = scrollRef.current.scrollHeight;
      const scrollDiff = newScrollHeight - previousScrollHeight.current;

      if (scrollDiff > 0) {
        scrollRef.current.scrollTop += scrollDiff;
      }

      previousScrollHeight.current = 0;
    }
  }, [messages, scrollToBottom]);

  // ==================== INITIALIZATION ====================

  useEffect(() => {
    if (conversationId) {
      // Reset state for new conversation
      setMessages([]);
      setOffset(0);
      setHasMore(true);
      setCacheLoaded(false);
      
      // Load messages
      loadInitialMessages();
    }
  }, [conversationId]);

  // ==================== BACKGROUND SYNC ====================

  /**
   * Refresh messages from server (for cache invalidation)
   */
  const refreshMessages = useCallback(async () => {
    if (!conversationId) return;

    console.log('[InfiniteScroll] 🔄 Background sync - refreshing messages');

    try {
      const response = await messagesAPI.getMessages(conversationId, pageSize, 0);

      if (response.success) {
        const loadedMessages = response.messages || [];
        
        // Sort chronologically
        const sorted = [...loadedMessages].sort((a, b) => 
          new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
        );
        
        // Update messages - merge with existing to avoid losing optimistic messages
        setMessages((prev) => {
          // Keep any optimistic messages (have temp_id)
          const optimistic = prev.filter(m => m.temp_id);
          
          // Deduplicate server messages
          const serverMessages = sorted.filter(
            sm => !prev.some(pm => pm.id === sm.id)
          );

          // Merge: existing + new server messages
          const merged = [...prev, ...serverMessages].sort((a, b) => 
            new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
          );

          console.log('[InfiniteScroll] ✅ Merged messages:', merged.length, '(added', serverMessages.length, 'new)');
          return merged;
        });

        // Update cache
        await messageCache.saveMessages(conversationId, sorted);
        console.log('[InfiniteScroll] ✅ Background sync complete');
      }
    } catch (error) {
      console.error('[InfiniteScroll] ❌ Background sync failed:', error);
    }
  }, [conversationId, pageSize]);

  /**
   * Auto-sync when app becomes visible (user returns to tab)
   */
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (!document.hidden && conversationId) {
        console.log('[InfiniteScroll] 👁️ App visible - triggering background sync');
        refreshMessages();
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  }, [conversationId, refreshMessages]);

  /**
   * Auto-sync when network is restored
   */
  useEffect(() => {
    const handleNetworkOnline = () => {
      console.log('[InfiniteScroll] 🌐 Network restored - triggering background sync');
      refreshMessages();
    };

    window.addEventListener('network_online', handleNetworkOnline);

    return () => {
      window.removeEventListener('network_online', handleNetworkOnline);
    };
  }, [refreshMessages]);

  // ==================== RETURN ====================

  return {
    messages,
    isLoading,
    isLoadingMore,
    hasMore,
    scrollRef,
    handleScroll,
    scrollToBottom,
    loadMore,
    setMessages,
    refreshMessages,
    invalidateCache: () => messageCache.invalidateConversation(conversationId),
  };
}

