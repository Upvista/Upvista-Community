/**
 * API Utility Functions
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Centralized API calling with automatic token refresh
 * Implements sliding window authentication
 */

interface FetchOptions extends RequestInit {
  skipTokenUpdate?: boolean;
}

/**
 * Enhanced fetch that automatically updates tokens
 * Backend sends X-New-Token header when token needs refresh
 */
export async function apiFetch(url: string, options: FetchOptions = {}) {
  const token = localStorage.getItem('token');
  
  // Add Authorization header if token exists
  const headers = {
    ...options.headers,
    ...(token && { 'Authorization': `Bearer ${token}` }),
  };

  const response = await fetch(url, {
    ...options,
    headers,
  });

  // Check for token refresh (sliding window)
  if (!options.skipTokenUpdate) {
    const newToken = response.headers.get('X-New-Token');
    if (newToken) {
      localStorage.setItem('token', newToken);
      console.log('[Auth] Token auto-refreshed - staying logged in');
    }
  }

  return response;
}

/**
 * API call wrapper with automatic token refresh
 */
export const api = {
  get: (url: string, options?: FetchOptions) => 
    apiFetch(url, { ...options, method: 'GET' }),
  
  post: (url: string, data?: any, options?: FetchOptions) =>
    apiFetch(url, {
      ...options,
      method: 'POST',
      headers: { 'Content-Type': 'application/json', ...options?.headers },
      body: data ? JSON.stringify(data) : undefined,
    }),
  
  patch: (url: string, data?: any, options?: FetchOptions) =>
    apiFetch(url, {
      ...options,
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', ...options?.headers },
      body: data ? JSON.stringify(data) : undefined,
    }),
  
  delete: (url: string, data?: any, options?: FetchOptions) =>
    apiFetch(url, {
      ...options,
      method: 'DELETE',
      headers: { 'Content-Type': 'application/json', ...options?.headers },
      body: data ? JSON.stringify(data) : undefined,
    }),
  
  upload: (url: string, formData: FormData, options?: FetchOptions) =>
    apiFetch(url, {
      ...options,
      method: 'POST',
      body: formData,
    }),
};

