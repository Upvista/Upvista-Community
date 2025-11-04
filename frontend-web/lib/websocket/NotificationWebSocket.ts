/**
 * WebSocket Client for Real-time Notifications
 * Singleton pattern with auto-reconnect
 */

import type { Notification } from '../api/notifications';

type MessageHandler = (data: any) => void;
type ConnectionStateHandler = (connected: boolean) => void;

interface WSMessage {
  type: string;
  data?: any;
  // Messaging envelope fields
  id?: string;
  channel?: string;
  conversation_id?: string;
  timestamp?: number;
}

interface NotificationMessage {
  type: 'notification';
  notification: Notification;
}

interface CountUpdateMessage {
  type: 'count_update';
  total: number;
  category_counts: Record<string, number>;
}

class NotificationWebSocket {
  private static instance: NotificationWebSocket;
  private ws: WebSocket | null = null;
  private url: string;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 10;
  private reconnectDelay = 1000;
  private messageHandlers: Map<string, Set<MessageHandler>> = new Map();
  private connectionStateHandlers: Set<ConnectionStateHandler> = new Set();
  private heartbeatInterval: NodeJS.Timeout | null = null;
  private isIntentionallyClosed = false;

  private constructor() {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const host = process.env.NEXT_PUBLIC_API_URL || 'localhost:8081';
    this.url = `${protocol}//${host.replace(/^https?:\/\//, '')}/api/v1/ws`;
  }

  public static getInstance(): NotificationWebSocket {
    if (!NotificationWebSocket.instance) {
      NotificationWebSocket.instance = new NotificationWebSocket();
    }
    return NotificationWebSocket.instance;
  }

  public connect(token: string): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      console.log('[WebSocket] Already connected');
      return;
    }

    if (!token) {
      console.error('[WebSocket] No token provided, skipping connection');
      return;
    }

    this.isIntentionallyClosed = false;
    const wsUrl = `${this.url}?token=${token}`;
    console.log('[WebSocket] Connecting to:', this.url);

    try {
      this.ws = new WebSocket(wsUrl);

      this.ws.onopen = () => {
        console.log('[WebSocket] Connected successfully');
        this.reconnectAttempts = 0;
        this.reconnectDelay = 1000;
        this.notifyConnectionState(true);
        this.startHeartbeat();
      };

      this.ws.onmessage = (event) => {
        try {
          const message: WSMessage = JSON.parse(event.data);
          this.handleMessage(message);
        } catch (error) {
          console.error('[WebSocket] Failed to parse message:', error);
        }
      };

      this.ws.onerror = (error) => {
        console.error('[WebSocket] Connection error. Make sure backend is running on port 8081');
        console.error('[WebSocket] Expected URL:', this.url);
      };

      this.ws.onclose = (event) => {
        console.log('[WebSocket] Disconnected. Code:', event.code, 'Reason:', event.reason || 'No reason provided');
        this.notifyConnectionState(false);
        this.stopHeartbeat();

        if (!this.isIntentionallyClosed) {
          this.attemptReconnect(token);
        }
      };
    } catch (error) {
      console.error('[WebSocket] Connection failed:', error);
      this.attemptReconnect(token);
    }
  }

  public disconnect(): void {
    this.isIntentionallyClosed = true;
    this.stopHeartbeat();
    
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
  }

  public on(eventType: string, handler: MessageHandler): void {
    if (!this.messageHandlers.has(eventType)) {
      this.messageHandlers.set(eventType, new Set());
    }
    this.messageHandlers.get(eventType)!.add(handler);
  }

  public off(eventType: string, handler: MessageHandler): void {
    const handlers = this.messageHandlers.get(eventType);
    if (handlers) {
      handlers.delete(handler);
    }
  }

  public onConnectionStateChange(handler: ConnectionStateHandler): void {
    this.connectionStateHandlers.add(handler);
  }

  public offConnectionStateChange(handler: ConnectionStateHandler): void {
    this.connectionStateHandlers.delete(handler);
  }

  public isConnected(): boolean {
    return this.ws?.readyState === WebSocket.OPEN;
  }

  private handleMessage(message: WSMessage): void {
    // Handle messaging channel (envelope format)
    if (message.channel === 'messaging') {
      console.log(`[WebSocket] ⚡ ${message.type}`, message.data);
      const handlers = this.messageHandlers.get(message.type);
      if (handlers) {
        // Execute ALL handlers synchronously for instant updates
        handlers.forEach(handler => {
          try {
            handler(message.data);
          } catch (error) {
            console.error(`[WebSocket] Handler error:`, error);
          }
        });
      }
      return;
    }

    // Handle notification channel (flat format)
    const handlers = this.messageHandlers.get(message.type);
    if (handlers) {
      handlers.forEach(handler => handler(message.data));
    }

    // Handle pong response (silent)
    if (message.type === 'pong') {
      // Silent
    }
  }

  private notifyConnectionState(connected: boolean): void {
    this.connectionStateHandlers.forEach(handler => handler(connected));
  }

  private attemptReconnect(token: string): void {
    if (this.isIntentionallyClosed) {
      return;
    }

    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.error('[WebSocket] Max reconnection attempts reached');
      return;
    }

    this.reconnectAttempts++;
    const delay = this.reconnectDelay * Math.pow(1.5, this.reconnectAttempts - 1);

    console.log(`[WebSocket] Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts}/${this.maxReconnectAttempts})`);

    setTimeout(() => {
      this.connect(token);
    }, delay);
  }

  private startHeartbeat(): void {
    this.stopHeartbeat();
    
    this.heartbeatInterval = setInterval(() => {
      if (this.ws?.readyState === WebSocket.OPEN) {
        this.ws.send(JSON.stringify({ type: 'ping' }));
      }
    }, 30000); // Ping every 30 seconds
  }

  private stopHeartbeat(): void {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval);
      this.heartbeatInterval = null;
    }
  }
}

export default NotificationWebSocket;

// Export singleton instance for direct use
export const notificationWS = NotificationWebSocket.getInstance();

