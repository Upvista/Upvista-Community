'use client';

/**
 * useUser Hook
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Centralized user profile data fetching and state management
 */

import { useState, useEffect } from 'react';

export interface UserProfile {
  id: string;
  email: string;
  username: string;
  display_name: string;
  age: number;
  profile_picture: string | null;
  created_at: string;
  updated_at: string;
}

export function useUser() {
  const [user, setUser] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchProfile = async () => {
    try {
      setLoading(true);
      const token = localStorage.getItem('token');
      
      if (!token) {
        setError('Not authenticated');
        setLoading(false);
        return;
      }

      const response = await fetch('/api/proxy/v1/account/profile', {
        headers: { 
          'Authorization': `Bearer ${token}`,
        },
      });

      if (response.ok) {
        const data = await response.json();
        setUser(data.user);
        setError(null);
      } else {
        const data = await response.json();
        setError(data.message || 'Failed to fetch profile');
      }
    } catch (err) {
      setError('Network error occurred');
      console.error('Error fetching profile:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProfile();
  }, []);

  return { user, loading, error, refetch: fetchProfile, setUser };
}

