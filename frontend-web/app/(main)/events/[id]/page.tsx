'use client';

/**
 * Event Details Page
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Shows complete event details and allows users to apply
 */

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { MainLayout } from '@/components/layout/MainLayout';
import { Button } from '@/components/ui/Button';
import { Avatar } from '@/components/ui/Avatar';
import VerifiedBadge from '@/components/ui/VerifiedBadge';
import { 
  Calendar, 
  MapPin, 
  Clock, 
  Users, 
  Lock, 
  Globe, 
  Video, 
  ArrowLeft,
  Share2,
  ExternalLink,
  DollarSign
} from 'lucide-react';
import { eventsAPI, Event } from '@/lib/api/events';
import { toast } from '@/components/ui/Toast';
import { useUser } from '@/lib/hooks/useUser';
import EventApplicationModal from '@/components/events/EventApplicationModal';
import EventTicketModal from '@/components/events/EventTicketModal';

export default function EventDetailsPage() {
  const router = useRouter();
  const params = useParams();
  const { user } = useUser();
  const eventId = params.id as string;

  const [event, setEvent] = useState<Event | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showApplicationModal, setShowApplicationModal] = useState(false);
  const [showTicketModal, setShowTicketModal] = useState(false);

  useEffect(() => {
    if (eventId) {
      loadEvent();
    }
  }, [eventId]);

  const loadEvent = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await eventsAPI.getEvent(eventId);
      if (response.success) {
        setEvent(response.event);
        if (response.event.has_applied && response.event.application) {
          // User has already applied, show ticket option
        }
      } else {
        setError(response.error || 'Failed to load event');
      }
    } catch (err: any) {
      setError(err.message || 'Failed to load event');
      toast.error(err.message || 'Failed to load event');
    } finally {
      setLoading(false);
    }
  };

  const handleApply = () => {
    if (!user) {
      router.push('/auth');
      return;
    }
    setShowApplicationModal(true);
  };

  const handleViewTicket = () => {
    setShowTicketModal(true);
  };

  const handleApplicationSuccess = () => {
    setShowApplicationModal(false);
    loadEvent(); // Reload to show updated status
    toast.success('Successfully applied to event!');
  };

  const handleShare = async () => {
    if (navigator.share && event) {
      try {
        await navigator.share({
          title: event.title,
          text: event.description || '',
          url: window.location.href,
        });
      } catch (err) {
        // User cancelled or error
      }
    } else {
      // Fallback: copy to clipboard
      navigator.clipboard.writeText(window.location.href);
      toast.success('Event link copied to clipboard');
    }
  };

  if (loading) {
    return (
      <MainLayout>
        <div className="min-h-screen bg-white dark:bg-neutral-950 flex items-center justify-center">
          <div className="w-5 h-5 sm:w-6 sm:h-6 border-2 border-neutral-300 dark:border-neutral-600 border-t-transparent rounded-full animate-spin" />
        </div>
      </MainLayout>
    );
  }

  if (error || !event) {
    return (
      <MainLayout>
        <div className="min-h-screen bg-white dark:bg-neutral-950">
          <div className="w-full max-w-4xl mx-auto px-4 py-8">
            <div className="text-center py-12 sm:py-20">
              <p className="text-sm sm:text-base text-neutral-600 dark:text-neutral-400 mb-4">{error || 'Event not found'}</p>
              <Button
                variant="secondary"
                size="sm"
                onClick={() => router.push('/events')}
              >
                Back to Events
              </Button>
            </div>
          </div>
        </div>
      </MainLayout>
    );
  }

  const isUpcoming = eventsAPI.isUpcoming(event);
  const isPast = eventsAPI.isPast(event);
  const isCreator = user?.id === event.creator_id;

  return (
    <MainLayout>
      <div className="min-h-screen bg-white dark:bg-neutral-950">
        <div className="w-full max-w-4xl mx-auto px-4 py-4 sm:py-6 md:py-8">
          {/* Back Button - Mobile First */}
          <button
            onClick={() => router.push('/events')}
            className="flex items-center gap-1.5 sm:gap-2 text-sm sm:text-base text-neutral-600 dark:text-neutral-400 hover:text-neutral-900 dark:hover:text-neutral-50 mb-4 sm:mb-6 transition-colors"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>Back</span>
          </button>

          {/* Event Cover Image - Mobile Optimized */}
          {event.cover_image_url && (
            <div className="w-full h-48 sm:h-64 md:h-80 rounded-lg sm:rounded-xl overflow-hidden mb-4 sm:mb-6">
              <img
                src={event.cover_image_url}
                alt={event.title}
                className="w-full h-full object-cover"
              />
            </div>
          )}

          {/* Event Header - Mobile First */}
          <div className="mb-4 sm:mb-6">
            <div className="flex items-start justify-between gap-3 mb-3 sm:mb-4">
              <div className="flex-1 min-w-0">
                <div className="flex items-start gap-2 mb-2">
                  <h1 className="text-xl sm:text-2xl md:text-3xl font-semibold text-neutral-900 dark:text-neutral-50 leading-tight">
                    {event.title}
                  </h1>
                  {!event.is_public && (
                    <Lock className="w-4 h-4 sm:w-5 sm:h-5 text-neutral-400 dark:text-neutral-500 flex-shrink-0 mt-1" />
                  )}
                </div>
                {event.category && (
                  <span className="inline-block px-2.5 sm:px-3 py-1 text-xs font-medium border border-neutral-200 dark:border-neutral-800 rounded-full text-neutral-600 dark:text-neutral-400">
                    {event.category}
                  </span>
                )}
              </div>
              <button
                onClick={handleShare}
                className="p-2 rounded-full hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors flex-shrink-0"
                aria-label="Share event"
              >
                <Share2 className="w-4 h-4 sm:w-5 sm:h-5 text-neutral-600 dark:text-neutral-400" />
              </button>
            </div>

            {/* Creator Info - Compact */}
            {event.creator && (
              <div className="flex items-center gap-2 sm:gap-3 mb-4 sm:mb-6">
                <Avatar
                  src={event.creator.profile_picture}
                  alt={event.creator.display_name || event.creator.username}
                  fallback={event.creator.display_name || event.creator.username || 'U'}
                  size="sm"
                  className="w-8 h-8 sm:w-10 sm:h-10"
                />
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-1.5">
                    <span className="text-sm sm:text-base font-semibold text-neutral-900 dark:text-neutral-50 truncate">
                      {event.creator.display_name || event.creator.username}
                    </span>
                    {event.creator.is_verified && (
                      <VerifiedBadge size="xs" variant="badge" showText={false} />
                    )}
                  </div>
                  <span className="text-xs text-neutral-500 dark:text-neutral-400 truncate">
                    @{event.creator.username}
                  </span>
                </div>
              </div>
            )}

            {/* Event Details Grid - Mobile First */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4 mb-4 sm:mb-6">
              {/* Date & Time */}
              <div className="flex items-start gap-2.5 sm:gap-3 p-3 sm:p-4 border border-neutral-200 dark:border-neutral-800 rounded-lg">
                <Calendar className="w-4 h-4 sm:w-5 sm:h-5 text-neutral-400 dark:text-neutral-500 flex-shrink-0 mt-0.5" />
                <div className="min-w-0 flex-1">
                  <p className="text-xs text-neutral-500 dark:text-neutral-400 mb-1">Date & Time</p>
                  <p className="text-sm sm:text-base font-medium text-neutral-900 dark:text-neutral-50">
                    {eventsAPI.formatEventDate(event.start_date, event.timezone)}
                  </p>
                  {!event.is_all_day && (
                    <p className="text-xs sm:text-sm text-neutral-600 dark:text-neutral-400 mt-0.5">
                      {eventsAPI.formatEventTime(event.start_date, event.timezone)}
                    </p>
                  )}
                  {event.end_date && (
                    <p className="text-xs text-neutral-500 dark:text-neutral-400 mt-1">
                      Ends: {eventsAPI.formatEventDate(event.end_date, event.timezone)}
                    </p>
                  )}
                </div>
              </div>

              {/* Location */}
              <div className="flex items-start gap-2.5 sm:gap-3 p-3 sm:p-4 border border-neutral-200 dark:border-neutral-800 rounded-lg">
                {event.location_type === 'online' ? (
                  <Video className="w-4 h-4 sm:w-5 sm:h-5 text-neutral-400 dark:text-neutral-500 flex-shrink-0 mt-0.5" />
                ) : event.location_type === 'hybrid' ? (
                  <Globe className="w-4 h-4 sm:w-5 sm:h-5 text-neutral-400 dark:text-neutral-500 flex-shrink-0 mt-0.5" />
                ) : (
                  <MapPin className="w-4 h-4 sm:w-5 sm:h-5 text-neutral-400 dark:text-neutral-500 flex-shrink-0 mt-0.5" />
                )}
                <div className="flex-1 min-w-0">
                  <p className="text-xs text-neutral-500 dark:text-neutral-400 mb-1">Location</p>
                  {event.location_type === 'online' && event.online_link ? (
                    <a
                      href={event.online_link}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-sm sm:text-base font-medium text-brand-purple-600 dark:text-brand-purple-400 hover:underline flex items-center gap-1"
                    >
                      <span className="truncate">{event.online_platform || 'Online Event'}</span>
                      <ExternalLink className="w-3 h-3 flex-shrink-0" />
                    </a>
                  ) : event.location_type === 'hybrid' ? (
                    <div>
                      <p className="text-sm sm:text-base font-medium text-neutral-900 dark:text-neutral-50">
                        {event.location_name || 'Hybrid Event'}
                      </p>
                      {event.online_link && (
                        <a
                          href={event.online_link}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-xs text-brand-purple-600 dark:text-brand-purple-400 hover:underline flex items-center gap-1 mt-1"
                        >
                          Online Link
                          <ExternalLink className="w-3 h-3" />
                        </a>
                      )}
                    </div>
                  ) : (
                    <div>
                      {event.location_name && (
                        <p className="text-sm sm:text-base font-medium text-neutral-900 dark:text-neutral-50">
                          {event.location_name}
                        </p>
                      )}
                      {event.location_address && (
                        <p className="text-xs sm:text-sm text-neutral-600 dark:text-neutral-400 mt-0.5 line-clamp-2">
                          {event.location_address}
                        </p>
                      )}
                    </div>
                  )}
                </div>
              </div>

              {/* Attendees */}
              <div className="flex items-start gap-2.5 sm:gap-3 p-3 sm:p-4 border border-neutral-200 dark:border-neutral-800 rounded-lg">
                <Users className="w-4 h-4 sm:w-5 sm:h-5 text-neutral-400 dark:text-neutral-500 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="text-xs text-neutral-500 dark:text-neutral-400 mb-1">Attendees</p>
                  <p className="text-sm sm:text-base font-medium text-neutral-900 dark:text-neutral-50">
                    {event.applications_count} {event.applications_count === 1 ? 'attendee' : 'attendees'}
                  </p>
                  {event.max_attendees && (
                    <p className="text-xs text-neutral-500 dark:text-neutral-400 mt-0.5">
                      Max: {event.max_attendees}
                    </p>
                  )}
                </div>
              </div>

              {/* Pricing */}
              <div className="flex items-start gap-2.5 sm:gap-3 p-3 sm:p-4 border border-neutral-200 dark:border-neutral-800 rounded-lg">
                <DollarSign className="w-4 h-4 sm:w-5 sm:h-5 text-neutral-400 dark:text-neutral-500 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="text-xs text-neutral-500 dark:text-neutral-400 mb-1">Price</p>
                  <p className="text-sm sm:text-base font-medium text-neutral-900 dark:text-neutral-50">
                    {event.is_free ? 'Free' : `$${event.price?.toFixed(2)} ${event.currency}`}
                  </p>
                </div>
              </div>
            </div>

            {/* Description */}
            {event.description && (
              <div className="mb-4 sm:mb-6">
                <h2 className="text-base sm:text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-2 sm:mb-3">
                  About this event
                </h2>
                <p className="text-sm sm:text-base text-neutral-700 dark:text-neutral-300 whitespace-pre-wrap leading-relaxed">
                  {event.description}
                </p>
              </div>
            )}

            {/* Tags */}
            {event.tags && event.tags.length > 0 && (
              <div className="mb-4 sm:mb-6">
                <div className="flex flex-wrap gap-2">
                  {event.tags.map((tag, index) => (
                    <span
                      key={index}
                      className="px-2.5 sm:px-3 py-1 text-xs font-medium border border-neutral-200 dark:border-neutral-800 rounded-full text-neutral-600 dark:text-neutral-400"
                    >
                      #{tag}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {/* Action Buttons - Mobile First */}
            <div className="flex items-center gap-2 sm:gap-3">
              {isCreator ? (
                <Button
                  variant="secondary"
                  size="sm"
                  className="flex-1 sm:flex-initial"
                  onClick={() => router.push(`/events/${event.id}/edit`)}
                >
                  Edit Event
                </Button>
              ) : event.has_applied ? (
                <Button
                  variant="primary"
                  size="sm"
                  onClick={handleViewTicket}
                  className="flex items-center justify-center gap-2 flex-1 sm:flex-initial"
                >
                  <Calendar className="w-4 h-4" />
                  View Ticket
                </Button>
              ) : isUpcoming ? (
                <Button
                  variant="primary"
                  size="sm"
                  onClick={handleApply}
                  className="flex items-center justify-center gap-2 flex-1 sm:flex-initial"
                  disabled={event.status !== 'approved'}
                >
                  Apply to Event
                </Button>
              ) : (
                <Button
                  variant="secondary"
                  size="sm"
                  disabled
                  className="flex-1 sm:flex-initial"
                >
                  Event Ended
                </Button>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Application Modal */}
      {showApplicationModal && event && (
        <EventApplicationModal
          event={event}
          isOpen={showApplicationModal}
          onClose={() => setShowApplicationModal(false)}
          onSuccess={handleApplicationSuccess}
        />
      )}

      {/* Ticket Modal */}
      {showTicketModal && event && event.application && (
        <EventTicketModal
          event={event}
          application={event.application}
          isOpen={showTicketModal}
          onClose={() => setShowTicketModal(false)}
        />
      )}
    </MainLayout>
  );
}
