'use client';

/**
 * Event Approvals Admin Page
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Admin interface for approving/rejecting pending events
 */

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { MainLayout } from '@/components/layout/MainLayout';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { ArrowLeft, Check, X, Calendar, MapPin, Clock, Users, Lock, Globe, Video, User } from 'lucide-react';
import { eventsAPI, EventApprovalRequest } from '@/lib/api/events';
import { Avatar } from '@/components/ui/Avatar';
import { toast } from '@/components/ui/Toast';
import VerifiedBadge from '@/components/ui/VerifiedBadge';

export default function EventApprovalsPage() {
  const router = useRouter();
  const [requests, setRequests] = useState<EventApprovalRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [processingId, setProcessingId] = useState<string | null>(null);
  const [showRejectModal, setShowRejectModal] = useState<string | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');

  useEffect(() => {
    loadPendingApprovals();
  }, []);

  const loadPendingApprovals = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await eventsAPI.getPendingApprovals({ limit: 50, offset: 0 });
      if (response.success && response.requests) {
        setRequests(response.requests);
      } else {
        setError(response.error || 'Failed to load pending approvals');
      }
    } catch (err: any) {
      setError(err.message || 'Failed to load pending approvals');
      toast.error(err.message || 'Failed to load pending approvals');
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async (request: EventApprovalRequest) => {
    if (!request.event) {
      toast.error('Event details not available');
      return;
    }

    setProcessingId(request.id);
    try {
      const response = await eventsAPI.approveEvent(request.approval_token, {
        status: 'approved',
      });

      if (response.success) {
        toast.success('Event approved successfully');
        // Remove from list
        setRequests(requests.filter(r => r.id !== request.id));
      } else {
        toast.error(response.error || 'Failed to approve event');
      }
    } catch (err: any) {
      toast.error(err.message || 'Failed to approve event');
    } finally {
      setProcessingId(null);
    }
  };

  const handleReject = async (request: EventApprovalRequest) => {
    if (!request.event) {
      toast.error('Event details not available');
      return;
    }

    if (!rejectionReason.trim()) {
      toast.error('Please provide a rejection reason');
      return;
    }

    setProcessingId(request.id);
    try {
      const response = await eventsAPI.approveEvent(request.approval_token, {
        status: 'rejected',
        rejection_reason: rejectionReason,
      });

      if (response.success) {
        toast.success('Event rejected');
        setShowRejectModal(null);
        setRejectionReason('');
        // Remove from list
        setRequests(requests.filter(r => r.id !== request.id));
      } else {
        toast.error(response.error || 'Failed to reject event');
      }
    } catch (err: any) {
      toast.error(err.message || 'Failed to reject event');
    } finally {
      setProcessingId(null);
    }
  };

  if (loading) {
    return (
      <MainLayout>
        <div className="min-h-screen bg-white dark:bg-neutral-950 flex items-center justify-center">
          <div className="inline-block w-6 h-6 border-2 border-neutral-300 dark:border-neutral-600 border-t-transparent rounded-full animate-spin" />
        </div>
      </MainLayout>
    );
  }

  return (
    <MainLayout>
      <div className="min-h-screen bg-white dark:bg-neutral-950">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          {/* Header */}
          <div className="flex items-center gap-4 mb-8">
            <button
              onClick={() => router.push('/events')}
              className="p-1 rounded-full transition-colors"
            >
              <ArrowLeft className="w-6 h-6 text-neutral-900 dark:text-neutral-50" />
            </button>
            <div>
              <h1 className="text-2xl font-semibold text-neutral-900 dark:text-neutral-50">
                Event Approvals
              </h1>
              <p className="text-sm text-neutral-600 dark:text-neutral-400">
                Review and approve pending event requests
              </p>
            </div>
          </div>

          {/* Error State */}
          {error && (
            <div className="mb-6 p-4 border border-red-200 dark:border-red-800 rounded-lg bg-red-50 dark:bg-red-900/20">
              <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
              <Button
                variant="secondary"
                size="sm"
                className="mt-2"
                onClick={loadPendingApprovals}
              >
                Try Again
              </Button>
            </div>
          )}

          {/* Empty State */}
          {!error && requests.length === 0 && (
            <div className="text-center py-20">
              <div className="w-20 h-20 mx-auto mb-4 border border-neutral-200 dark:border-neutral-800 rounded-full flex items-center justify-center">
                <Check className="w-10 h-10 text-neutral-400 dark:text-neutral-500" />
              </div>
              <h3 className="text-xl font-semibold text-neutral-900 dark:text-neutral-50 mb-2">
                No pending approvals
              </h3>
              <p className="text-neutral-600 dark:text-neutral-400">
                All events have been reviewed!
              </p>
            </div>
          )}

          {/* Approval Requests List */}
          {requests.length > 0 && (
            <div className="space-y-4">
              {requests.map((request) => {
                const event = request.event;
                if (!event) return null;

                return (
                  <div
                    key={request.id}
                    className="border border-neutral-200 dark:border-neutral-800 rounded-lg p-6"
                  >
                    {/* Event Header */}
                    <div className="flex items-start justify-between mb-4">
                      <div className="flex-1">
                        <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-1">
                          {event.title}
                        </h3>
                        {event.creator && (
                          <div className="flex items-center gap-2 mb-2">
                            <Avatar
                              src={event.creator.profile_picture}
                              alt={event.creator.display_name || event.creator.username}
                              fallback={event.creator.display_name || event.creator.username || 'U'}
                              size="xs"
                            />
                            <span className="text-sm text-neutral-600 dark:text-neutral-400">
                              {event.creator.display_name || event.creator.username}
                            </span>
                            {event.creator.is_verified && (
                              <VerifiedBadge size="xs" variant="badge" showText={false} />
                            )}
                          </div>
                        )}
                      </div>
                      <div className="flex items-center gap-2">
                        {!event.is_public && (
                          <Lock className="w-4 h-4 text-neutral-400" />
                        )}
                        <span className="px-2 py-1 text-xs border border-neutral-200 dark:border-neutral-800 rounded-full">
                          {request.category || 'Other'}
                        </span>
                      </div>
                    </div>

                    {/* Event Details */}
                    <div className="space-y-2 mb-4">
                      {event.description && (
                        <p className="text-sm text-neutral-600 dark:text-neutral-400">
                          {event.description}
                        </p>
                      )}

                      <div className="flex flex-wrap items-center gap-4 text-sm text-neutral-600 dark:text-neutral-400">
                        <div className="flex items-center gap-1.5">
                          <Calendar className="w-4 h-4" />
                          <span>{eventsAPI.formatEventDate(event.start_date, event.timezone)}</span>
                        </div>
                        {!event.is_all_day && (
                          <div className="flex items-center gap-1.5">
                            <Clock className="w-4 h-4" />
                            <span>{eventsAPI.formatEventTime(event.start_date, event.timezone)}</span>
                          </div>
                        )}
                        {event.location_type === 'physical' && event.location_name && (
                          <div className="flex items-center gap-1.5">
                            <MapPin className="w-4 h-4" />
                            <span>{event.location_name}</span>
                          </div>
                        )}
                        {event.location_type === 'online' && (
                          <div className="flex items-center gap-1.5">
                            <Video className="w-4 h-4" />
                            <span>Online</span>
                          </div>
                        )}
                        {event.location_type === 'hybrid' && (
                          <div className="flex items-center gap-1.5">
                            <Globe className="w-4 h-4" />
                            <span>Hybrid</span>
                          </div>
                        )}
                        {event.max_attendees && (
                          <div className="flex items-center gap-1.5">
                            <Users className="w-4 h-4" />
                            <span>Max {event.max_attendees} attendees</span>
                          </div>
                        )}
                      </div>

                      {request.request_reason && (
                        <div className="mt-2 p-3 bg-neutral-50 dark:bg-neutral-900/50 rounded-lg">
                          <p className="text-xs font-medium text-neutral-700 dark:text-neutral-300 mb-1">
                            Request Reason:
                          </p>
                          <p className="text-sm text-neutral-600 dark:text-neutral-400">
                            {request.request_reason}
                          </p>
                        </div>
                      )}
                    </div>

                    {/* Action Buttons */}
                    <div className="flex items-center gap-3 pt-4 border-t border-neutral-200 dark:border-neutral-800">
                      <Button
                        variant="primary"
                        size="md"
                        className="flex items-center gap-2 flex-1"
                        onClick={() => handleApprove(request)}
                        disabled={processingId === request.id}
                      >
                        <Check className="w-4 h-4" />
                        {processingId === request.id ? 'Processing...' : 'Approve'}
                      </Button>
                      <Button
                        variant="secondary"
                        size="md"
                        className="flex items-center gap-2 flex-1"
                        onClick={() => setShowRejectModal(request.id)}
                        disabled={processingId === request.id}
                      >
                        <X className="w-4 h-4" />
                        Reject
                      </Button>
                    </div>
                  </div>
                );
              })}
            </div>
          )}

          {/* Reject Modal */}
          {showRejectModal && (
            <div className="fixed inset-0 z-[300] flex items-center justify-center bg-black/60 p-4">
              <div className="bg-white dark:bg-neutral-950 rounded-2xl w-full max-w-md p-6">
                <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-4">
                  Reject Event
                </h3>
                <div className="mb-4">
                  <label className="block text-sm font-medium text-neutral-900 dark:text-neutral-50 mb-2">
                    Rejection Reason *
                  </label>
                  <textarea
                    value={rejectionReason}
                    onChange={(e) => setRejectionReason(e.target.value)}
                    placeholder="Please provide a reason for rejection..."
                    rows={4}
                    className="w-full px-4 py-3 text-sm rounded-lg border border-neutral-200 dark:border-neutral-800 bg-transparent text-neutral-900 dark:text-neutral-50 placeholder-neutral-400 dark:placeholder-neutral-500 focus:outline-none focus:ring-2 focus:ring-brand-purple-500 focus:border-brand-purple-500 resize-none"
                  />
                </div>
                <div className="flex items-center gap-3">
                  <Button
                    variant="secondary"
                    size="md"
                    className="flex-1"
                    onClick={() => {
                      setShowRejectModal(null);
                      setRejectionReason('');
                    }}
                  >
                    Cancel
                  </Button>
                  <Button
                    variant="primary"
                    size="md"
                    className="flex-1"
                    onClick={() => {
                      const request = requests.find(r => r.id === showRejectModal);
                      if (request) handleReject(request);
                    }}
                    disabled={!rejectionReason.trim() || processingId === showRejectModal}
                  >
                    {processingId === showRejectModal ? 'Processing...' : 'Reject Event'}
                  </Button>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </MainLayout>
  );
}
