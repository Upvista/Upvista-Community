'use client';

/**
 * Create Event Page
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Form for creating new events
 */

import { useState, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { MainLayout } from '@/components/layout/MainLayout';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { ArrowLeft, Upload, MapPin, Video, Globe, Lock, Unlock, Calendar, X } from 'lucide-react';
import { eventsAPI, CreateEventRequest, EventCategory } from '@/lib/api/events';
import { toast } from '@/components/ui/Toast';
import { useUser } from '@/lib/hooks/useUser';

export default function CreateEventPage() {
  const router = useRouter();
  const { user, loading: userLoading } = useUser();
  const [loading, setLoading] = useState(false);
  const [categories, setCategories] = useState<EventCategory[]>([]);
  const [formData, setFormData] = useState<CreateEventRequest>({
    title: '',
    description: '',
    cover_image_url: '',
    start_date: '',
    end_date: '',
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    is_all_day: false,
    location_type: 'physical',
    location_name: '',
    location_address: '',
    online_platform: '',
    online_link: '',
    category: '',
    tags: [],
    max_attendees: undefined,
    is_public: true,
    password: '',
    is_free: true,
    price: undefined,
    currency: 'USD',
  });
  const [tagInput, setTagInput] = useState('');
  const [coverImageFile, setCoverImageFile] = useState<File | null>(null);
  const [coverImagePreview, setCoverImagePreview] = useState<string | null>(null);
  const [uploadingCover, setUploadingCover] = useState(false);
  const startDateInputRef = useRef<HTMLInputElement>(null);
  const endDateInputRef = useRef<HTMLInputElement>(null);
  const coverImageInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    // Wait for user loading to complete before checking
    if (!userLoading && !user) {
      router.push('/auth');
      return;
    }
    // Only load categories if user is authenticated
    if (!userLoading && user) {
      loadCategories();
    }
  }, [user, userLoading, router]);

  const loadCategories = async () => {
    try {
      const response = await eventsAPI.getCategories();
      if (response.success) {
        setCategories(response.categories);
      }
    } catch (err) {
      console.error('Failed to load categories:', err);
    }
  };

  // Handle cover image selection
  const handleCoverImageSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Validate file type
    if (!file.type.startsWith('image/')) {
      toast.error('Please select a valid image file');
      return;
    }

    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      toast.error('Image size must be less than 5MB');
      return;
    }

    // Show preview
    const previewUrl = URL.createObjectURL(file);
    setCoverImagePreview(previewUrl);
    setCoverImageFile(file);

    // Upload image
    setUploadingCover(true);
    try {
      const response = await eventsAPI.uploadCoverImage(file);
      if (response.success) {
        setFormData({ ...formData, cover_image_url: response.url });
        toast.success('Cover image uploaded successfully');
      } else {
        toast.error(response.error || 'Failed to upload cover image');
        setCoverImageFile(null);
        setCoverImagePreview(null);
      }
    } catch (err: any) {
      toast.error(err.message || 'Failed to upload cover image');
      setCoverImageFile(null);
      setCoverImagePreview(null);
    } finally {
      setUploadingCover(false);
    }
  };

  // Helper function to convert datetime-local to ISO 8601 format
  // datetime-local format: "YYYY-MM-DDTHH:mm"
  // ISO 8601 format needed: "YYYY-MM-DDTHH:mm:ssZ" or "YYYY-MM-DDTHH:mm:ss+HH:mm"
  const formatDateTimeForAPI = (dateTimeLocal: string): string => {
    if (!dateTimeLocal) return '';
    
    // datetime-local gives us "YYYY-MM-DDTHH:mm" in local time
    // Add seconds and convert to ISO string (UTC)
    // JavaScript Date will interpret the local time correctly
    const date = new Date(dateTimeLocal + ':00'); // Add seconds
    if (isNaN(date.getTime())) {
      // Fallback: if parsing fails, try without seconds
      const fallbackDate = new Date(dateTimeLocal);
      if (!isNaN(fallbackDate.getTime())) {
        return fallbackDate.toISOString();
      }
      // Last resort: manually format
      return `${dateTimeLocal}:00.000Z`;
    }
    
    return date.toISOString();
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      // Validate required fields
      if (!formData.title || !formData.start_date || !formData.location_type) {
        toast.error('Please fill in all required fields');
        setLoading(false);
        return;
      }

      // Validate location-specific fields
      if ((formData.location_type === 'online' || formData.location_type === 'hybrid') && !formData.online_link) {
        toast.error('Online link is required for online/hybrid events');
        setLoading(false);
        return;
      }

      // Validate pricing
      if (!formData.is_free && !formData.price) {
        toast.error('Price is required for paid events');
        setLoading(false);
        return;
      }

      // Format dates for API (convert datetime-local to ISO 8601)
      const formattedData = {
        ...formData,
        start_date: formatDateTimeForAPI(formData.start_date),
        end_date: formData.end_date ? formatDateTimeForAPI(formData.end_date) : undefined,
      };

      const response = await eventsAPI.createEvent(formattedData);

      if (response.success) {
        toast.success('Event created successfully! It will be reviewed for approval.');
        router.push(`/events/${response.event.id}`);
      } else {
        toast.error(response.error || 'Failed to create event');
      }
    } catch (err: any) {
      toast.error(err.message || 'Failed to create event');
    } finally {
      setLoading(false);
    }
  };

  const handleAddTag = () => {
    if (tagInput.trim() && !formData.tags?.includes(tagInput.trim())) {
      setFormData({
        ...formData,
        tags: [...(formData.tags || []), tagInput.trim()],
      });
      setTagInput('');
    }
  };

  const handleRemoveTag = (tag: string) => {
    setFormData({
      ...formData,
      tags: formData.tags?.filter((t) => t !== tag) || [],
    });
  };

  // Show loading state while checking authentication
  if (userLoading) {
    return (
      <MainLayout>
        <div className="min-h-screen bg-white dark:bg-neutral-950 flex items-center justify-center">
          <div className="inline-block w-6 h-6 border-2 border-neutral-300 dark:border-neutral-600 border-t-transparent rounded-full animate-spin" />
        </div>
      </MainLayout>
    );
  }

  // Redirect if not authenticated (handled by useEffect, but show nothing while redirecting)
  if (!user) {
    return null;
  }

  return (
    <MainLayout>
      <div className="min-h-screen bg-white dark:bg-neutral-950">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
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
                Create Event
              </h1>
              <p className="text-sm text-neutral-600 dark:text-neutral-400">
                Fill in the details to create your event
              </p>
            </div>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Basic Information */}
            <div className="space-y-4 border-b border-neutral-200 dark:border-neutral-800 pb-6">
              <h2 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50">
                Basic Information
              </h2>

              <Input
                label="Event Title *"
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                placeholder="Enter event title"
                required
                labelBg="bg-white dark:bg-neutral-950"
              />

              <div>
                <label className="block text-sm font-medium text-neutral-900 dark:text-neutral-50 mb-2">
                  Description
                </label>
                <textarea
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  placeholder="Describe your event..."
                  rows={5}
                  className="w-full px-4 py-3 text-sm rounded-lg border border-neutral-200 dark:border-neutral-800 bg-transparent text-neutral-900 dark:text-neutral-50 placeholder-neutral-400 dark:placeholder-neutral-500 focus:outline-none focus:ring-2 focus:ring-brand-purple-500 focus:border-brand-purple-500 resize-none"
                />
              </div>

              {/* Cover Image Upload */}
              <div>
                <label className="block text-sm font-medium text-neutral-900 dark:text-neutral-50 mb-2">
                  Cover Image (Optional)
                </label>
                <input
                  ref={coverImageInputRef}
                  type="file"
                  accept="image/*"
                  onChange={handleCoverImageSelect}
                  className="hidden"
                />
                <div className="space-y-3">
                  {coverImagePreview ? (
                    <div className="relative">
                      <img
                        src={coverImagePreview}
                        alt="Cover preview"
                        className="w-full h-48 object-cover rounded-lg border border-neutral-200 dark:border-neutral-800"
                      />
                      <button
                        type="button"
                        onClick={() => {
                          setCoverImageFile(null);
                          setCoverImagePreview(null);
                          setFormData({ ...formData, cover_image_url: '' });
                          if (coverImageInputRef.current) {
                            coverImageInputRef.current.value = '';
                          }
                        }}
                        className="absolute top-2 right-2 p-1.5 bg-black/50 hover:bg-black/70 text-white rounded-full transition-colors"
                        aria-label="Remove image"
                      >
                        <X className="w-4 h-4" />
                      </button>
                    </div>
                  ) : (
                    <button
                      type="button"
                      onClick={() => coverImageInputRef.current?.click()}
                      disabled={uploadingCover}
                      className="w-full h-32 border-2 border-dashed border-neutral-300 dark:border-neutral-700 rounded-lg flex flex-col items-center justify-center gap-2 text-neutral-600 dark:text-neutral-400 hover:border-brand-purple-500 hover:text-brand-purple-600 dark:hover:text-brand-purple-400 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      {uploadingCover ? (
                        <>
                          <div className="w-5 h-5 border-2 border-neutral-300 dark:border-neutral-600 border-t-transparent rounded-full animate-spin" />
                          <span className="text-sm">Uploading...</span>
                        </>
                      ) : (
                        <>
                          <Upload className="w-6 h-6" />
                          <span className="text-sm font-medium">Click to upload cover image</span>
                          <span className="text-xs">JPG, PNG, or WebP (max 5MB)</span>
                        </>
                      )}
                    </button>
                  )}
                </div>
              </div>
            </div>

            {/* Date & Time */}
            <div className="space-y-4 border-b border-neutral-200 dark:border-neutral-800 pb-6">
              <h2 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50">
                Date & Time
              </h2>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {/* Start Date & Time */}
                <div>
                  <label className="block text-sm font-medium text-neutral-900 dark:text-neutral-50 mb-2">
                    Start Date & Time *
                  </label>
                  <div className="relative">
                    <input
                      ref={startDateInputRef}
                      type="datetime-local"
                      value={formData.start_date}
                      onChange={(e) => setFormData({ ...formData, start_date: e.target.value })}
                      required
                      className="w-full px-4 py-3 pr-12 text-sm rounded-lg border border-neutral-200 dark:border-neutral-800 bg-transparent text-neutral-900 dark:text-neutral-50 placeholder-neutral-400 dark:placeholder-neutral-500 focus:outline-none focus:ring-2 focus:ring-brand-purple-500 focus:border-brand-purple-500"
                    />
                    <button
                      type="button"
                      onClick={() => {
                        if (startDateInputRef.current) {
                          // Try modern showPicker API first
                          if ('showPicker' in startDateInputRef.current && typeof startDateInputRef.current.showPicker === 'function') {
                            startDateInputRef.current.showPicker();
                          } else {
                            // Fallback: focus and click
                            startDateInputRef.current.focus();
                            startDateInputRef.current.click();
                          }
                        }
                      }}
                      className="absolute right-3 top-1/2 -translate-y-1/2 p-1.5 text-neutral-400 dark:text-neutral-500 hover:text-brand-purple-600 dark:hover:text-brand-purple-400 transition-colors cursor-pointer"
                      aria-label="Open calendar picker"
                      title="Open calendar"
                    >
                      <Calendar className="w-5 h-5" />
                    </button>
                  </div>
                </div>

                {/* End Date & Time */}
                <div>
                  <label className="block text-sm font-medium text-neutral-900 dark:text-neutral-50 mb-2">
                    End Date & Time (Optional)
                  </label>
                  <div className="relative">
                    <input
                      ref={endDateInputRef}
                      type="datetime-local"
                      value={formData.end_date || ''}
                      onChange={(e) => setFormData({ ...formData, end_date: e.target.value || undefined })}
                      className="w-full px-4 py-3 pr-12 text-sm rounded-lg border border-neutral-200 dark:border-neutral-800 bg-transparent text-neutral-900 dark:text-neutral-50 placeholder-neutral-400 dark:placeholder-neutral-500 focus:outline-none focus:ring-2 focus:ring-brand-purple-500 focus:border-brand-purple-500"
                    />
                    <button
                      type="button"
                      onClick={() => {
                        if (endDateInputRef.current) {
                          // Try modern showPicker API first
                          if ('showPicker' in endDateInputRef.current && typeof endDateInputRef.current.showPicker === 'function') {
                            endDateInputRef.current.showPicker();
                          } else {
                            // Fallback: focus and click
                            endDateInputRef.current.focus();
                            endDateInputRef.current.click();
                          }
                        }
                      }}
                      className="absolute right-3 top-1/2 -translate-y-1/2 p-1.5 text-neutral-400 dark:text-neutral-500 hover:text-brand-purple-600 dark:hover:text-brand-purple-400 transition-colors cursor-pointer"
                      aria-label="Open calendar picker"
                      title="Open calendar"
                    >
                      <Calendar className="w-5 h-5" />
                    </button>
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-3">
                <input
                  type="checkbox"
                  id="isAllDay"
                  checked={formData.is_all_day}
                  onChange={(e) => setFormData({ ...formData, is_all_day: e.target.checked })}
                  className="w-4 h-4 text-purple-600 border-neutral-300 rounded focus:ring-purple-500"
                />
                <label htmlFor="isAllDay" className="text-sm text-neutral-900 dark:text-neutral-50 cursor-pointer">
                  All-day event
                </label>
              </div>
            </div>

            {/* Location */}
            <div className="space-y-4 border-b border-neutral-200 dark:border-neutral-800 pb-6">
              <h2 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50">
                Location
              </h2>

              <div>
                <label className="block text-sm font-medium text-neutral-900 dark:text-neutral-50 mb-2">
                  Location Type *
                </label>
                <div className="grid grid-cols-3 gap-3">
                  {[
                    { value: 'physical', label: 'Physical', icon: MapPin },
                    { value: 'online', label: 'Online', icon: Video },
                    { value: 'hybrid', label: 'Hybrid', icon: Globe },
                  ].map(({ value, label, icon: Icon }) => (
                    <button
                      key={value}
                      type="button"
                      onClick={() => setFormData({ ...formData, location_type: value as any })}
                      className={`flex flex-col items-center gap-2 p-4 border-2 rounded-lg transition-all ${
                        formData.location_type === value
                          ? 'border-purple-600 bg-purple-50 dark:bg-purple-900/20'
                          : 'border-neutral-200 dark:border-neutral-800 hover:border-purple-300'
                      }`}
                    >
                      <Icon className="w-5 h-5 text-neutral-600 dark:text-neutral-400" />
                      <span className="text-sm font-medium text-neutral-900 dark:text-neutral-50">
                        {label}
                      </span>
                    </button>
                  ))}
                </div>
              </div>

              {(formData.location_type === 'physical' || formData.location_type === 'hybrid') && (
                <>
                  <Input
                    label="Location Name"
                    value={formData.location_name || ''}
                    onChange={(e) => setFormData({ ...formData, location_name: e.target.value })}
                    placeholder="e.g., Convention Center"
                    labelBg="bg-white dark:bg-neutral-950"
                  />
                  <Input
                    label="Address"
                    value={formData.location_address || ''}
                    onChange={(e) => setFormData({ ...formData, location_address: e.target.value })}
                    placeholder="Full address"
                    labelBg="bg-white dark:bg-neutral-950"
                  />
                </>
              )}

              {(formData.location_type === 'online' || formData.location_type === 'hybrid') && (
                <>
                  <Input
                    label="Online Platform"
                    value={formData.online_platform || ''}
                    onChange={(e) => setFormData({ ...formData, online_platform: e.target.value })}
                    placeholder="e.g., Zoom, Google Meet"
                    labelBg="bg-white dark:bg-neutral-950"
                  />
                  <Input
                    label="Online Link *"
                    type="url"
                    value={formData.online_link || ''}
                    onChange={(e) => setFormData({ ...formData, online_link: e.target.value })}
                    placeholder="https://zoom.us/j/..."
                    required={formData.location_type === 'online' || formData.location_type === 'hybrid'}
                    labelBg="bg-white dark:bg-neutral-950"
                  />
                </>
              )}
            </div>

            {/* Event Details */}
            <div className="space-y-4 border-b border-neutral-200 dark:border-neutral-800 pb-6">
              <h2 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50">
                Event Details
              </h2>

              <div>
                <label className="block text-sm font-medium text-neutral-900 dark:text-neutral-50 mb-2">
                  Category
                </label>
                <select
                  value={formData.category || ''}
                  onChange={(e) => setFormData({ ...formData, category: e.target.value || undefined })}
                  className="w-full px-4 py-3 text-sm rounded-lg border border-neutral-200 dark:border-neutral-800 bg-transparent text-neutral-900 dark:text-neutral-50 focus:outline-none focus:ring-2 focus:ring-brand-purple-500 focus:border-brand-purple-500"
                >
                  <option value="">Select category</option>
                  {categories.map((cat) => (
                    <option key={cat.id} value={cat.name}>
                      {cat.name}
                    </option>
                  ))}
                </select>
              </div>

              <Input
                label="Max Attendees (Optional)"
                type="number"
                value={formData.max_attendees?.toString() || ''}
                onChange={(e) => setFormData({ ...formData, max_attendees: e.target.value ? parseInt(e.target.value) : undefined })}
                placeholder="Leave empty for unlimited"
                min="1"
                labelBg="bg-white dark:bg-neutral-950"
              />

              {/* Tags */}
              <div>
                <label className="block text-sm font-medium text-neutral-900 dark:text-neutral-50 mb-2">
                  Tags
                </label>
                <div className="flex gap-2 mb-2">
                  <Input
                    value={tagInput}
                    onChange={(e) => setTagInput(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') {
                        e.preventDefault();
                        handleAddTag();
                      }
                    }}
                    placeholder="Add a tag and press Enter"
                    labelBg="bg-white dark:bg-neutral-950"
                  />
                  <Button
                    type="button"
                    variant="secondary"
                    size="md"
                    onClick={handleAddTag}
                  >
                    Add
                  </Button>
                </div>
                {formData.tags && formData.tags.length > 0 && (
                  <div className="flex flex-wrap gap-2">
                    {formData.tags.map((tag) => (
                      <span
                        key={tag}
                        className="inline-flex items-center gap-1 px-3 py-1 bg-neutral-100 dark:bg-neutral-800 border border-neutral-200 dark:border-neutral-800 rounded-full text-sm"
                      >
                        #{tag}
                        <button
                          type="button"
                          onClick={() => handleRemoveTag(tag)}
                          className="text-neutral-400 hover:text-neutral-600 dark:hover:text-neutral-300"
                        >
                          ×
                        </button>
                      </span>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* Privacy & Pricing */}
            <div className="space-y-4 border-b border-neutral-200 dark:border-neutral-800 pb-6">
              <h2 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50">
                Privacy & Pricing
              </h2>

              <div className="flex items-center gap-3">
                <button
                  type="button"
                  onClick={() => setFormData({ ...formData, is_public: !formData.is_public })}
                  className={`flex items-center gap-2 px-4 py-2 border-2 rounded-lg transition-all ${
                    formData.is_public
                      ? 'border-purple-600 bg-purple-50 dark:bg-purple-900/20'
                      : 'border-neutral-200 dark:border-neutral-800'
                  }`}
                >
                  {formData.is_public ? (
                    <Unlock className="w-5 h-5 text-purple-600" />
                  ) : (
                    <Lock className="w-5 h-5 text-neutral-400" />
                  )}
                  <span className="text-sm font-medium text-neutral-900 dark:text-neutral-50">
                    {formData.is_public ? 'Public Event' : 'Private Event'}
                  </span>
                </button>
              </div>

              {!formData.is_public && (
                <Input
                  label="Event Password *"
                  type="password"
                  value={formData.password || ''}
                  onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                  placeholder="Set a password for private event"
                  required={!formData.is_public}
                  labelBg="bg-white dark:bg-neutral-950"
                />
              )}

              <div className="flex items-center gap-3">
                <input
                  type="checkbox"
                  id="isFree"
                  checked={formData.is_free}
                  onChange={(e) => setFormData({ ...formData, is_free: e.target.checked })}
                  className="w-4 h-4 text-purple-600 border-neutral-300 rounded focus:ring-purple-500"
                />
                <label htmlFor="isFree" className="text-sm text-neutral-900 dark:text-neutral-50 cursor-pointer">
                  Free event
                </label>
              </div>

              {!formData.is_free && (
                <div className="grid grid-cols-2 gap-4">
                  <Input
                    label="Price *"
                    type="number"
                    step="0.01"
                    value={formData.price?.toString() || ''}
                    onChange={(e) => setFormData({ ...formData, price: e.target.value ? parseFloat(e.target.value) : undefined })}
                    placeholder="0.00"
                    required={!formData.is_free}
                    labelBg="bg-white dark:bg-neutral-950"
                  />
                  <div>
                    <label className="block text-sm font-medium text-neutral-900 dark:text-neutral-50 mb-2">
                      Currency
                    </label>
                    <select
                      value={formData.currency}
                      onChange={(e) => setFormData({ ...formData, currency: e.target.value })}
                      className="w-full px-4 py-3 text-sm rounded-lg border border-neutral-200 dark:border-neutral-800 bg-transparent text-neutral-900 dark:text-neutral-50 focus:outline-none focus:ring-2 focus:ring-brand-purple-500 focus:border-brand-purple-500"
                    >
                      <option value="USD">USD ($)</option>
                      <option value="EUR">EUR (€)</option>
                      <option value="GBP">GBP (£)</option>
                    </select>
                  </div>
                </div>
              )}
            </div>

            {/* Submit */}
            <div className="flex items-center gap-3 pt-4">
              <Button
                type="button"
                variant="secondary"
                size="md"
                onClick={() => router.push('/events')}
                className="flex-1"
              >
                Cancel
              </Button>
              <Button
                type="submit"
                variant="primary"
                size="md"
                disabled={loading}
                className="flex-1"
              >
                {loading ? 'Creating...' : 'Create Event'}
              </Button>
            </div>
          </form>
        </div>
      </div>
    </MainLayout>
  );
}
