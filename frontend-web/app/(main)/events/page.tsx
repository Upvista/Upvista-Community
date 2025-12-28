'use client';

/**
 * Events Page
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Dedicated page for upcoming events
 * Users can view and create events
 * 
 * Last updated: Force recompilation fix
 */

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { MainLayout } from '@/components/layout/MainLayout';
import { Button } from '@/components/ui/Button';
import { Calendar, Plus, MapPin, Clock, Users, Lock, Globe, Video } from 'lucide-react';
import { eventsAPI, Event } from '@/lib/api/events';
import { Avatar } from '@/components/ui/Avatar';
import { toast } from '@/components/ui/Toast';
import VerifiedBadge from '@/components/ui/VerifiedBadge';

export default function EventsPage() {
  const router = useRouter();
  const [activeFilter, setActiveFilter] = useState<'upcoming' | 'past' | 'all'>('upcoming');
  const [events, setEvents] = useState<Event[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Event handlers
  const handleCreateEvent = () => {
    router.push('/events/create');
  };

  const handleEventClick = (eventId: string) => {
    router.push(`/events/${eventId}`);
  };

  // Load events function
  const loadEvents = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await eventsAPI.getEvents({
        status: activeFilter === 'all' ? undefined : activeFilter,
        limit: 20,
        offset: 0,
      });
      
      if (response.success) {
        setEvents(response.events);
      } else {
        setError(response.error || 'Failed to load events');
      }
    } catch (err: any) {
      setError(err.message || 'Failed to load events');
      toast.error(err.message || 'Failed to load events');
    } finally {
      setLoading(false);
    }
  };

  // Load events on mount and when filter changes
  useEffect(() => {
    loadEvents();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeFilter]);

  return (
    <MainLayout>
      <div className="min-h-screen bg-white dark:bg-neutral-950">
        <div className="w-full max-w-4xl mx-auto px-4 py-4 sm:py-6 md:py-8">
          {/* Header - Mobile First */}
          <div className="mb-6 sm:mb-8">
            <div className="flex items-start justify-between gap-3 mb-4">
              <div className="flex-1 min-w-0">
                <h1 className="text-2xl sm:text-3xl font-semibold text-neutral-900 dark:text-neutral-50 mb-1">
                  Events
                </h1>
                <p className="text-xs sm:text-sm text-neutral-600 dark:text-neutral-400">
                  Discover and create upcoming events
                </p>
              </div>
              <Button
                variant="primary"
                size="sm"
                className="flex items-center gap-1.5 sm:gap-2 flex-shrink-0"
                onClick={handleCreateEvent}
              >
                <Plus className="w-4 h-4" />
                <span className="hidden sm:inline">Create Event</span>
                <span className="sm:hidden">Create</span>
              </Button>
            </div>

            {/* Filters - Mobile Optimized */}
            <div className="flex items-center gap-2 overflow-x-auto scrollbar-hide pb-1 -mx-4 px-4 sm:mx-0 sm:px-0">
              <button
                onClick={() => setActiveFilter('upcoming')}
                className={`px-3 sm:px-4 py-1.5 sm:py-2 rounded-full text-xs sm:text-sm font-medium whitespace-nowrap transition-all duration-200 flex-shrink-0 ${
                  activeFilter === 'upcoming'
                    ? 'bg-brand-purple-600 text-white'
                    : 'bg-transparent border border-neutral-200 dark:border-neutral-800 text-neutral-700 dark:text-neutral-300'
                }`}
              >
                Upcoming
              </button>
              <button
                onClick={() => setActiveFilter('past')}
                className={`px-3 sm:px-4 py-1.5 sm:py-2 rounded-full text-xs sm:text-sm font-medium whitespace-nowrap transition-all duration-200 flex-shrink-0 ${
                  activeFilter === 'past'
                    ? 'bg-brand-purple-600 text-white'
                    : 'bg-transparent border border-neutral-200 dark:border-neutral-800 text-neutral-700 dark:text-neutral-300'
                }`}
              >
                Past
              </button>
              <button
                onClick={() => setActiveFilter('all')}
                className={`px-3 sm:px-4 py-1.5 sm:py-2 rounded-full text-xs sm:text-sm font-medium whitespace-nowrap transition-all duration-200 flex-shrink-0 ${
                  activeFilter === 'all'
                    ? 'bg-brand-purple-600 text-white'
                    : 'bg-transparent border border-neutral-200 dark:border-neutral-800 text-neutral-700 dark:text-neutral-300'
                }`}
              >
                All
              </button>
            </div>
          </div>

          {/* Events List - Mobile First Card Design */}
          <div className="space-y-0">
            {loading ? (
              <div className="flex items-center justify-center py-16 sm:py-20">
                <div className="w-5 h-5 sm:w-6 sm:h-6 border-2 border-neutral-300 dark:border-neutral-600 border-t-transparent rounded-full animate-spin" />
              </div>
            ) : error ? (
              <div className="text-center py-16 sm:py-20">
                <p className="text-sm sm:text-base text-neutral-600 dark:text-neutral-400 mb-4">{error}</p>
                <Button
                  variant="secondary"
                  size="sm"
                  onClick={loadEvents}
                >
                  Try Again
                </Button>
              </div>
            ) : events.length === 0 ? (
              <div className="text-center py-16 sm:py-20">
                <div className="w-16 h-16 sm:w-20 sm:h-20 mx-auto mb-4 border border-neutral-200 dark:border-neutral-800 rounded-full flex items-center justify-center">
                  <Calendar className="w-8 h-8 sm:w-10 sm:h-10 text-neutral-400 dark:text-neutral-500" />
                </div>
                <h3 className="text-lg sm:text-xl font-semibold text-neutral-900 dark:text-neutral-50 mb-2">
                  No events yet
                </h3>
                <p className="text-sm sm:text-base text-neutral-600 dark:text-neutral-400 mb-6 px-4">
                  Be the first to create an event or check back later for upcoming events!
                </p>
                <Button
                  variant="primary"
                  size="sm"
                  className="flex items-center gap-2 mx-auto"
                  onClick={handleCreateEvent}
                >
                  <Plus className="w-4 h-4" />
                  Create Your First Event
                </Button>
              </div>
            ) : (
              events.map((event) => (
                <div
                  key={event.id}
                  onClick={() => handleEventClick(event.id)}
                  className="border-b border-neutral-200 dark:border-neutral-800 py-4 sm:py-6 cursor-pointer active:opacity-70 transition-opacity"
                >
                  {/* Mobile: Vertical Layout, Desktop: Horizontal Layout */}
                  <div className="flex flex-col sm:flex-row gap-3 sm:gap-4">
                    {/* Event Cover - Full Width on Mobile, Fixed on Desktop */}
                    <div className="w-full sm:w-32 sm:h-32 sm:flex-shrink-0 rounded-lg overflow-hidden bg-neutral-100 dark:bg-neutral-800 aspect-video sm:aspect-square">
                      {event.cover_image_url ? (
                        <img
                          src={event.cover_image_url}
                          alt={event.title}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center">
                          <Calendar className="w-8 h-8 sm:w-10 sm:h-10 text-neutral-400 dark:text-neutral-500" />
                        </div>
                      )}
                    </div>

                    {/* Event Details */}
                    <div className="flex-1 min-w-0 space-y-2 sm:space-y-2.5">
                      {/* Title and Privacy */}
                      <div className="flex items-start justify-between gap-2">
                        <h3 className="text-base sm:text-lg font-semibold text-neutral-900 dark:text-neutral-50 line-clamp-2 flex-1">
                          {event.title}
                        </h3>
                        {!event.is_public && (
                          <Lock className="w-4 h-4 text-neutral-400 dark:text-neutral-500 flex-shrink-0 mt-0.5" />
                        )}
                      </div>

                      {/* Creator - Compact */}
                      {event.creator && (
                        <div className="flex items-center gap-1.5">
                          <Avatar
                            src={event.creator.profile_picture}
                            alt={event.creator.display_name || event.creator.username}
                            fallback={event.creator.display_name || event.creator.username || 'U'}
                            size="xs"
                            className="w-3.5 h-3.5 sm:w-4 sm:h-4"
                          />
                          <span className="text-xs text-neutral-600 dark:text-neutral-400">
                            {event.creator.display_name || event.creator.username}
                          </span>
                          {event.creator.is_verified && (
                            <VerifiedBadge size="xs" variant="badge" showText={false} />
                          )}
                        </div>
                      )}

                      {/* Event Info - Compact Grid on Mobile */}
                      <div className="flex flex-wrap items-center gap-x-3 gap-y-1.5 text-xs sm:text-sm text-neutral-600 dark:text-neutral-400">
                        <div className="flex items-center gap-1">
                          <Calendar className="w-3.5 h-3.5 sm:w-4 sm:h-4 flex-shrink-0" />
                          <span className="line-clamp-1">{eventsAPI.formatEventDate(event.start_date, event.timezone)}</span>
                        </div>
                        {!event.is_all_day && (
                          <div className="flex items-center gap-1">
                            <Clock className="w-3.5 h-3.5 sm:w-4 sm:h-4 flex-shrink-0" />
                            <span>{eventsAPI.formatEventTime(event.start_date, event.timezone)}</span>
                          </div>
                        )}
                        {event.location_type === 'physical' && event.location_name && (
                          <div className="flex items-center gap-1 min-w-0">
                            <MapPin className="w-3.5 h-3.5 sm:w-4 sm:h-4 flex-shrink-0" />
                            <span className="line-clamp-1">{event.location_name}</span>
                          </div>
                        )}
                        {event.location_type === 'online' && (
                          <div className="flex items-center gap-1">
                            <Video className="w-3.5 h-3.5 sm:w-4 sm:h-4 flex-shrink-0" />
                            <span>Online</span>
                          </div>
                        )}
                        {event.location_type === 'hybrid' && (
                          <div className="flex items-center gap-1">
                            <Globe className="w-3.5 h-3.5 sm:w-4 sm:h-4 flex-shrink-0" />
                            <span>Hybrid</span>
                          </div>
                        )}
                        <div className="flex items-center gap-1">
                          <Users className="w-3.5 h-3.5 sm:w-4 sm:h-4 flex-shrink-0" />
                          <span>{event.applications_count}</span>
                        </div>
                        {event.category && (
                          <span className="px-2 py-0.5 text-xs border border-neutral-200 dark:border-neutral-800 rounded-full">
                            {event.category}
                          </span>
                        )}
                      </div>

                      {/* Description - Mobile Optimized */}
                      {event.description && (
                        <p className="text-xs sm:text-sm text-neutral-600 dark:text-neutral-400 line-clamp-2">
                          {event.description}
                        </p>
                      )}

                      {/* Applied Badge */}
                      {event.has_applied && (
                        <div className="inline-flex items-center gap-1.5 px-2 py-1 bg-brand-purple-100 dark:bg-brand-purple-900/30 text-brand-purple-600 dark:text-brand-purple-400 rounded-full text-xs font-medium">
                          <Calendar className="w-3 h-3" />
                          Applied
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </MainLayout>
  );
}
