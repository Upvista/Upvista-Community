/**
 * useInfiniteMessages - Infinite scroll for message history with IndexedDB caching
 * Provides fast initial load and smooth pagination
 */

import { useState, useEffect, useCallback, useRef } from 'react';
import { messagesAPI, Message } from '../api/messages';

// ============================================
// INDEXEDDB CACHE
// ============================================

const DB_NAME = 'upvista-messages';
const DB_VERSION = 1;
const STORE_NAME = 'messages';

/**
 * Open IndexedDB database
 */
function openDB(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);

    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);

    request.onupgradeneeded = (event) => {
      const db = (event.target as IDBOpenDBRequest).result;

      // Create object store if it doesn't exist
      if (!db.objectStoreNames.contains(STORE_NAME)) {
        db.createObjectStore(STORE_NAME);
      }
    };
  });
}

/**
 * Get cached messages from IndexedDB
 */
async function getCachedMessages(conversationId: string): Promise<Message[] | null> {
  try {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const transaction = db.transaction([STORE_NAME], 'readonly');
      const store = transaction.objectStore(STORE_NAME);
      const request = store.get(`conv_${conversationId}`);

      request.onsuccess = () => resolve(request.result || null);
      request.onerror = () => reject(request.error);
    });
  } catch (error) {
    console.error('[IndexedDB] Error getting cached messages:', error);
    return null;
  }
}

/**
 * Save messages to IndexedDB cache
 */
async function saveCachedMessages(conversationId: string, messages: Message[]): Promise<void> {
  try {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const transaction = db.transaction([STORE_NAME], 'readwrite');
      const store = transaction.objectStore(STORE_NAME);
      const request = store.put(messages, `conv_${conversationId}`);

      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  } catch (error) {
    console.error('[IndexedDB] Error saving cached messages:', error);
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
          const existingIds = new Set(prev.map(m => m.id));
          const uniqueNew = newMessages.filter(m => !existingIds.has(m.id));
          
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
  };
}

