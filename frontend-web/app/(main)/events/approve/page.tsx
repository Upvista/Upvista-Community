'use client';

/**
 * Event Approval Page
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Admin page for approving/rejecting events via email token
 */

import { useState, useEffect, useCallback } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { MainLayout } from '@/components/layout/MainLayout';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { CheckCircle, XCircle, Loader2, Calendar, MapPin, Clock, Users, Lock, Globe, Video } from 'lucide-react';
import { toast } from '@/components/ui/Toast';

interface EventDetails {
  id: string;
  title: string;
  description?: string;
  start_date: string;
  location_name?: string;
  location_type: string;
  creator?: {
    display_name: string;
    email: string;
  };
  category?: string;
  is_public: boolean;
}

export default function EventApprovalPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const token = searchParams.get('token');
  const action = searchParams.get('action'); // 'approve' or 'reject'

  const [eventDetails, setEventDetails] = useState<EventDetails | null>(null);
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState(false);
  const [rejectionReason, setRejectionReason] = useState('');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!token) {
      setError('Invalid approval link. Token is missing.');
      setLoading(false);
      return;
    }

    // Load event details first
    loadEventDetails();
  }, [token]);

  // Handle immediate approval/rejection from email link
  useEffect(() => {
    if (token && action && (action === 'approve' || action === 'reject')) {
      handleApproval(action === 'approve' ? 'approved' : 'rejected');
    }
  }, [action]);

  const loadEventDetails = async () => {
    if (!token) return;

    try {
      // Fetch event details using token
      const response = await fetch(`/api/proxy/v1/events/approve/details?token=${token}`, {
        method: 'GET',
      });

      if (!response.ok) {
        const data = await response.json().catch(() => ({}));
        throw new Error(data.error || 'Failed to load event details');
      }

      const data = await response.json();
      if (data.success && data.event) {
        setEventDetails(data.event);
      } else {
        throw new Error('Event not found');
      }

      setLoading(false);
    } catch (err: any) {
      setError(err.message || 'Failed to load event details');
      setLoading(false);
    }
  };


  if (loading) {
    return (
      <MainLayout>
        <div className="min-h-screen bg-white dark:bg-neutral-950 flex items-center justify-center">
          <div className="text-center">
            <Loader2 className="w-8 h-8 animate-spin text-purple-600 mx-auto mb-4" />
            <p className="text-neutral-600 dark:text-neutral-400">Loading event details...</p>
          </div>
        </div>
      </MainLayout>
    );
  }

  if (error && !eventDetails) {
    return (
      <MainLayout>
        <div className="min-h-screen bg-white dark:bg-neutral-950 flex items-center justify-center">
          <div className="text-center max-w-md">
            <XCircle className="w-16 h-16 text-red-500 mx-auto mb-4" />
            <h1 className="text-2xl font-semibold text-neutral-900 dark:text-neutral-50 mb-2">
              Invalid Approval Link
            </h1>
            <p className="text-neutral-600 dark:text-neutral-400 mb-6">{error}</p>
            <Button
              variant="primary"
              size="md"
              onClick={() => router.push('/events')}
            >
              Go to Events
            </Button>
          </div>
        </div>
      </MainLayout>
    );
  }

  return (
    <MainLayout>
      <div className="min-h-screen bg-white dark:bg-neutral-950">
        <div className="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="mb-8">
            <h1 className="text-3xl font-semibold text-neutral-900 dark:text-neutral-50 mb-2">
              Event Approval
            </h1>
            <p className="text-sm text-neutral-600 dark:text-neutral-400">
              Review and approve or reject the event request
            </p>
          </div>

          {processing ? (
            <div className="text-center py-20">
              <Loader2 className="w-8 h-8 animate-spin text-purple-600 mx-auto mb-4" />
              <p className="text-neutral-600 dark:text-neutral-400">Processing your decision...</p>
            </div>
          ) : (
            <div className="space-y-6">
              {/* Event Information Card */}
              {eventDetails && (
                <div className="border border-neutral-200 dark:border-neutral-800 rounded-lg p-6">
                  <h2 className="text-xl font-semibold text-neutral-900 dark:text-neutral-50 mb-4">
                    Event Information
                  </h2>
                  <div className="space-y-4">
                    <div>
                      <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-2">
                        {eventDetails.title}
                      </h3>
                      {eventDetails.description && (
                        <p className="text-sm text-neutral-600 dark:text-neutral-400 mb-4">
                          {eventDetails.description}
                        </p>
                      )}
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm">
                      {eventDetails.creator && (
                        <div>
                          <p className="text-neutral-500 dark:text-neutral-400 mb-1">Creator</p>
                          <p className="text-neutral-900 dark:text-neutral-50 font-medium">
                            {eventDetails.creator.display_name || eventDetails.creator.email}
                          </p>
                        </div>
                      )}
                      <div>
                        <p className="text-neutral-500 dark:text-neutral-400 mb-1">Start Date</p>
                        <p className="text-neutral-900 dark:text-neutral-50 font-medium">
                          {new Date(eventDetails.start_date).toLocaleString()}
                        </p>
                      </div>
                      {eventDetails.category && (
                        <div>
                          <p className="text-neutral-500 dark:text-neutral-400 mb-1">Category</p>
                          <p className="text-neutral-900 dark:text-neutral-50 font-medium">
                            {eventDetails.category}
                          </p>
                        </div>
                      )}
                      <div>
                        <p className="text-neutral-500 dark:text-neutral-400 mb-1">Type</p>
                        <p className="text-neutral-900 dark:text-neutral-50 font-medium">
                          {eventDetails.is_public ? 'Public' : 'Private'}
                        </p>
                      </div>
                      {eventDetails.location_name && (
                        <div>
                          <p className="text-neutral-500 dark:text-neutral-400 mb-1">Location</p>
                          <p className="text-neutral-900 dark:text-neutral-50 font-medium">
                            {eventDetails.location_name}
                          </p>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              )}

              {/* Rejection Reason (if rejecting) */}
              <div className="border border-neutral-200 dark:border-neutral-800 rounded-lg p-6">
                <label className="block text-sm font-medium text-neutral-900 dark:text-neutral-50 mb-2">
                  Rejection Reason (Optional)
                </label>
                <textarea
                  value={rejectionReason}
                  onChange={(e) => setRejectionReason(e.target.value)}
                  placeholder="Provide a reason for rejection (optional)..."
                  rows={4}
                  className="w-full px-4 py-3 text-sm rounded-lg border border-neutral-200 dark:border-neutral-800 bg-transparent text-neutral-900 dark:text-neutral-50 placeholder-neutral-400 dark:placeholder-neutral-500 focus:outline-none focus:ring-2 focus:ring-brand-purple-500 focus:border-brand-purple-500 resize-none"
                />
              </div>

              {/* Action Buttons */}
              <div className="flex flex-col sm:flex-row gap-3">
                <Button
                  variant="primary"
                  size="lg"
                  className="flex-1 bg-green-600 hover:bg-green-700"
                  onClick={() => handleApproval('approved')}
                  disabled={processing}
                >
                  <CheckCircle className="w-5 h-5 mr-2" />
                  Approve Event
                </Button>
                <Button
                  variant="secondary"
                  size="lg"
                  className="flex-1 border-red-500 text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20"
                  onClick={() => handleApproval('rejected')}
                  disabled={processing}
                >
                  <XCircle className="w-5 h-5 mr-2" />
                  Reject Event
                </Button>
              </div>

              {error && (
                <div className="p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
                  <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </MainLayout>
  );
}
