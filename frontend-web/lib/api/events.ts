/**
 * Events API Client
 * Handles all event-related API calls
 */

const API_BASE_URL = '/api/proxy/v1';

// ============================================
// TYPES
// ============================================

export interface Event {
  id: string;
  creator_id: string;
  title: string;
  description?: string;
  cover_image_url?: string;
  start_date: string;
  end_date?: string;
  timezone: string;
  is_all_day: boolean;
  location_type: 'physical' | 'online' | 'hybrid';
  location_name?: string;
  location_address?: string;
  online_platform?: string;
  online_link?: string;
  latitude?: number;
  longitude?: number;
  category?: string;
  tags?: string[];
  max_attendees?: number;
  is_public: boolean;
  is_password_protected: boolean;
  is_free: boolean;
  price?: number;
  currency: string;
  status: 'draft' | 'pending' | 'approved' | 'rejected' | 'cancelled' | 'completed';
  auto_approved: boolean;
  views_count: number;
  applications_count: number;
  created_at: string;
  updated_at: string;
  creator?: User;
  has_applied?: boolean;
  application?: EventApplication;
}

export interface EventApplication {
  id: string;
  event_id: string;
  user_id: string;
  status: 'pending' | 'approved' | 'rejected' | 'cancelled' | 'attended' | 'no_show';
  full_name?: string;
  email?: string;
  phone?: string;
  organization?: string;
  additional_info?: string;
  ticket_token: string;
  ticket_number: string;
  ticket_generated_at: string;
  payment_status: 'not_required' | 'pending' | 'completed' | 'refunded';
  payment_amount?: number;
  payment_transaction_id?: string;
  applied_at: string;
  approved_at?: string;
  cancelled_at?: string;
  event?: Event;
  user?: User;
}

export interface EventCategory {
  id: string;
  name: string;
  requires_approval: boolean;
  description?: string;
  created_at: string;
}

export interface User {
  id: string;
  username: string;
  display_name?: string;
  profile_picture?: string;
  is_verified?: boolean;
}

// Request types
export interface CreateEventRequest {
  title: string;
  description?: string;
  cover_image_url?: string;
  start_date: string;
  end_date?: string;
  timezone?: string;
  is_all_day?: boolean;
  location_type: 'physical' | 'online' | 'hybrid';
  location_name?: string;
  location_address?: string;
  online_platform?: string;
  online_link?: string;
  latitude?: number;
  longitude?: number;
  category?: string;
  tags?: string[];
  max_attendees?: number;
  is_public?: boolean;
  password?: string;
  is_free?: boolean;
  price?: number;
  currency?: string;
}

export interface ApplyToEventRequest {
  full_name?: string;
  email?: string;
  phone?: string;
  organization?: string;
  additional_info?: string;
  use_profile_data?: boolean;
  password?: string;
}

// Response types
export interface EventsListResponse {
  success: boolean;
  events: Event[];
  count: number;
  error?: string;
}

export interface EventResponse {
  success: boolean;
  event: Event;
  error?: string;
}

export interface ApplicationResponse {
  success: boolean;
  application: EventApplication;
  message?: string;
  error?: string;
}

export interface CategoriesResponse {
  success: boolean;
  categories: EventCategory[];
  error?: string;
}

// ============================================
// API CLIENT
// ============================================

async function fetchAPI(endpoint: string, options: RequestInit = {}) {
  const token = localStorage.getItem('token');
  
  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token && { Authorization: `Bearer ${token}` }),
      ...options.headers,
    },
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: response.statusText }));
    throw new Error(error.error || error.message || `API Error: ${response.statusText}`);
  }

  return response.json();
}

// Upload response
export interface UploadCoverImageResponse {
  success: boolean;
  url: string;
  message?: string;
  error?: string;
}

export const eventsAPI = {
  // ==================== EVENTS ====================

  /**
   * Get list of events
   */
  async getEvents(params?: {
    status?: 'upcoming' | 'past' | 'all';
    category?: string;
    search?: string;
    location_type?: 'physical' | 'online' | 'hybrid';
    is_free?: boolean;
    limit?: number;
    offset?: number;
  }): Promise<EventsListResponse> {
    const queryParams = new URLSearchParams();
    if (params?.status) queryParams.set('status', params.status);
    if (params?.category) queryParams.set('category', params.category);
    if (params?.search) queryParams.set('search', params.search);
    if (params?.location_type) queryParams.set('location_type', params.location_type);
    if (params?.is_free !== undefined) queryParams.set('is_free', params.is_free.toString());
    if (params?.limit) queryParams.set('limit', params.limit.toString());
    if (params?.offset) queryParams.set('offset', params.offset.toString());

    return fetchAPI(`/events?${queryParams.toString()}`);
  },

  /**
   * Get single event by ID
   */
  async getEvent(id: string): Promise<EventResponse> {
    return fetchAPI(`/events/${id}`);
  },

  /**
   * Create a new event
   */
  async createEvent(data: CreateEventRequest): Promise<EventResponse> {
    return fetchAPI('/events', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  /**
   * Update an event
   */
  async updateEvent(id: string, data: Partial<CreateEventRequest>): Promise<EventResponse> {
    return fetchAPI(`/events/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  },

  /**
   * Delete an event
   */
  async deleteEvent(id: string): Promise<{ success: boolean; message?: string; error?: string }> {
    return fetchAPI(`/events/${id}`, {
      method: 'DELETE',
    });
  },

  // ==================== APPLICATIONS ====================

  /**
   * Apply to an event
   */
  async applyToEvent(eventId: string, data: ApplyToEventRequest): Promise<ApplicationResponse> {
    return fetchAPI(`/events/${eventId}/apply`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  /**
   * Get user's application to an event
   */
  async getApplication(eventId: string): Promise<ApplicationResponse> {
    return fetchAPI(`/events/${eventId}/application`);
  },

  /**
   * Get user's ticket for an event
   */
  async getTicket(eventId: string): Promise<ApplicationResponse> {
    return fetchAPI(`/events/${eventId}/ticket`);
  },

  // ==================== CATEGORIES ====================

  /**
   * Get all event categories
   */
  async getCategories(): Promise<CategoriesResponse> {
    return fetchAPI('/events/categories');
  },

  // ==================== UTILITIES ====================

  /**
   * Format event date
   */
  formatEventDate(dateString: string, timezone?: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      timeZone: timezone || 'UTC',
    });
  },

  /**
   * Format event time
   */
  formatEventTime(dateString: string, timezone?: string): string {
    const date = new Date(dateString);
    return date.toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
      timeZone: timezone || 'UTC',
    });
  },

  /**
   * Check if event is upcoming
   */
  isUpcoming(event: Event): boolean {
    return new Date(event.start_date) > new Date();
  },

  /**
   * Check if event is past
   */
  isPast(event: Event): boolean {
    return new Date(event.start_date) < new Date();
  },

  // ==================== UPLOADS ====================

  /**
   * Upload event cover image
   */
  async uploadCoverImage(file: File): Promise<UploadCoverImageResponse> {
    const token = localStorage.getItem('token');
    const formData = new FormData();
    formData.append('cover_image', file);

    const response = await fetch(`${API_BASE_URL}/events/upload-cover-image`, {
      method: 'POST',
      headers: {
        ...(token && { Authorization: `Bearer ${token}` }),
      },
      body: formData,
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: response.statusText }));
      throw new Error(error.error || error.message || `Upload failed: ${response.statusText}`);
    }

    return response.json();
  },
};
