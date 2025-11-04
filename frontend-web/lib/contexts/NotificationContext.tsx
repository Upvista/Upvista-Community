'use client';

/**
 * Notification Context
 * Manages notification state and WebSocket connection
 */

import React, { createContext, useContext, useState, useEffect, useCallback, useRef } from 'react';
import { notificationAPI } from '../api/notifications';
import type { Notification } from '../api/notifications';
import NotificationWebSocket from '../websocket/NotificationWebSocket';

interface NotificationContextType {
  notifications: Notification[];
  unreadCount: number;
  categoryCounts: Record<string, number>;
  isConnected: boolean;
  isLoading: boolean;
  
  // Actions
  fetchNotifications: (category?: string, unread?: boolean) => Promise<void>;
  loadMore: () => Promise<void>;
  markAsRead: (id: string) => Promise<void>;
  markAllAsRead: (category?: string) => Promise<void>;
  deleteNotification: (id: string) => Promise<void>;
  refreshCount: () => Promise<void>;
}

const NotificationContext = createContext<NotificationContextType | undefined>(undefined);

export function NotificationProvider({ children }: { children: React.ReactNode }) {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [categoryCounts, setCategoryCounts] = useState<Record<string, number>>({});
  const [isConnected, setIsConnected] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [currentCategory, setCurrentCategory] = useState<string | undefined>();
  const [currentUnreadFilter, setCurrentUnreadFilter] = useState<boolean | undefined>();
  
  const wsClient = useRef<NotificationWebSocket | null>(null);
  const limit = 20;
  const offsetRef = useRef(0);

  // Initialize WebSocket connection
  useEffect(() => {
    const token = localStorage.getItem('token');
    if (!token) {
      console.log('[NotificationContext] No token found, skipping WebSocket connection');
      return;
    }

    console.log('[NotificationContext] Initializing WebSocket connection');
    wsClient.current = NotificationWebSocket.getInstance();
    
    // Connect
    wsClient.current.connect(token);

    // Listen for new notifications
    wsClient.current.on('notification', (notification: Notification) => {
      console.log('[NotificationContext] New notification received:', notification);
      setNotifications(prev => [notification, ...prev]);
      refreshCount();
      
      // Play sound or show browser notification (optional)
      if ('Notification' in window && Notification.permission === 'granted') {
        new Notification(notification.title, {
          body: notification.message || undefined,
          icon: notification.actor?.profile_picture || '/icon.png',
        });
      }
    });

    // Listen for count updates
    wsClient.current.on('count_update', (data: { total: number; category_counts: Record<string, number> }) => {
      console.log('[NotificationContext] Count update received:', data);
      setUnreadCount(data.total);
      setCategoryCounts(data.category_counts);
    });

    // Listen for connection state changes
    wsClient.current.onConnectionStateChange((connected) => {
      setIsConnected(connected);
    });

    // Fetch initial notifications
    fetchNotifications();
    refreshCount();

    return () => {
      if (wsClient.current) {
        wsClient.current.disconnect();
      }
    };
  }, []);

  // Request browser notification permission
  useEffect(() => {
    if ('Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission();
    }
  }, []);

  const fetchNotifications = useCallback(async (category?: string, unread?: boolean) => {
    setIsLoading(true);
    setCurrentCategory(category);
    setCurrentUnreadFilter(unread);
    offsetRef.current = 0;

    try {
      const response = await notificationAPI.getNotifications({
        category,
        unread,
        limit,
        offset: 0,
      });

      setNotifications(response.notifications);
      setUnreadCount(response.unread);
      setHasMore(response.notifications.length >= limit);
    } catch (error) {
      console.error('[NotificationContext] Failed to fetch notifications:', error);
    } finally {
      setIsLoading(false);
    }
  }, []);

  const loadMore = useCallback(async () => {
    if (isLoading || !hasMore) return;

    setIsLoading(true);
    offsetRef.current += limit;

    try {
      const response = await notificationAPI.getNotifications({
        category: currentCategory,
        unread: currentUnreadFilter,
        limit,
        offset: offsetRef.current,
      });

      setNotifications(prev => [...prev, ...response.notifications]);
      setHasMore(response.notifications.length >= limit);
    } catch (error) {
      console.error('[NotificationContext] Failed to load more notifications:', error);
    } finally {
      setIsLoading(false);
    }
  }, [isLoading, hasMore, currentCategory, currentUnreadFilter]);

  const markAsRead = useCallback(async (id: string) => {
    try {
      await notificationAPI.markAsRead(id);
      
      setNotifications(prev =>
        prev.map(n => n.id === id ? { ...n, is_read: true } : n)
      );
      
      refreshCount();
    } catch (error) {
      console.error('[NotificationContext] Failed to mark as read:', error);
    }
  }, []);

  const markAllAsRead = useCallback(async (category?: string) => {
    try {
      await notificationAPI.markAllAsRead(category);
      
      setNotifications(prev =>
        prev.map(n => 
          (!category || n.category === category) ? { ...n, is_read: true } : n
        )
      );
      
      refreshCount();
    } catch (error) {
      console.error('[NotificationContext] Failed to mark all as read:', error);
    }
  }, []);

  const deleteNotification = useCallback(async (id: string) => {
    try {
      await notificationAPI.deleteNotification(id);
      
      setNotifications(prev => prev.filter(n => n.id !== id));
      
      refreshCount();
    } catch (error) {
      console.error('[NotificationContext] Failed to delete notification:', error);
    }
  }, []);

  const refreshCount = useCallback(async () => {
    try {
      const response = await notificationAPI.getUnreadCount();
      setUnreadCount(response.total);
      setCategoryCounts(response.category_counts);
    } catch (error) {
      console.error('[NotificationContext] Failed to refresh count:', error);
    }
  }, []);

  const value: NotificationContextType = {
    notifications,
    unreadCount,
    categoryCounts,
    isConnected,
    isLoading,
    fetchNotifications,
    loadMore,
    markAsRead,
    markAllAsRead,
    deleteNotification,
    refreshCount,
  };

  return (
    <NotificationContext.Provider value={value}>
      {children}
    </NotificationContext.Provider>
  );
}

export function useNotifications() {
  const context = useContext(NotificationContext);
  if (context === undefined) {
    throw new Error('useNotifications must be used within a NotificationProvider');
  }
  return context;
}

