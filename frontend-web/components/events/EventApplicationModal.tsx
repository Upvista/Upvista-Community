'use client';

/**
 * Event Application Modal
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Modal for applying to events with profile data auto-fill option
 */

import { useState } from 'react';
import { X, Lock } from 'lucide-react';
import { Event, ApplyToEventRequest, eventsAPI } from '@/lib/api/events';
import { useUser } from '@/lib/hooks/useUser';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import { toast } from '@/components/ui/Toast';

interface EventApplicationModalProps {
  event: Event;
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export default function EventApplicationModal({
  event,
  isOpen,
  onClose,
  onSuccess,
}: EventApplicationModalProps) {
  const { user } = useUser();
  const [useProfileData, setUseProfileData] = useState(true);
  const [formData, setFormData] = useState<ApplyToEventRequest>({
    full_name: user?.display_name || '',
    email: user?.email || '',
    phone: '',
    organization: '',
    additional_info: '',
    use_profile_data: true,
  });
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const requestData: ApplyToEventRequest = {
        ...formData,
        use_profile_data: useProfileData,
      };

      if (!event.is_public && event.is_password_protected) {
        requestData.password = password;
      }

      const response = await eventsAPI.applyToEvent(event.id, requestData);

      if (response.success) {
        onSuccess();
        onClose();
      } else {
        setError(response.error || 'Failed to apply to event');
      }
    } catch (err: any) {
      setError(err.message || 'Failed to apply to event');
      toast.error(err.message || 'Failed to apply to event');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-[300] flex items-center justify-center bg-black/60 p-4">
      <div className="bg-white dark:bg-neutral-950 rounded-2xl w-full max-w-md max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-neutral-200 dark:border-neutral-800">
          <h2 className="text-xl font-semibold text-neutral-900 dark:text-neutral-50">
            Apply to Event
          </h2>
          <button
            onClick={onClose}
            className="p-1 rounded-full hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors"
          >
            <X className="w-5 h-5 text-neutral-600 dark:text-neutral-400" />
          </button>
        </div>

        {/* Content */}
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {/* Event Info */}
          <div className="p-4 bg-neutral-50 dark:bg-neutral-900/50 rounded-lg mb-4">
            <h3 className="text-sm font-semibold text-neutral-900 dark:text-neutral-50 mb-1">
              {event.title}
            </h3>
            <p className="text-xs text-neutral-600 dark:text-neutral-400">
              {eventsAPI.formatEventDate(event.start_date, event.timezone)}
            </p>
          </div>

          {/* Use Profile Data Toggle */}
          <div className="flex items-center gap-3 p-4 border border-neutral-200 dark:border-neutral-800 rounded-lg">
            <input
              type="checkbox"
              id="useProfileData"
              checked={useProfileData}
              onChange={(e) => {
                setUseProfileData(e.target.checked);
                if (e.target.checked && user) {
                  setFormData({
                    ...formData,
                    full_name: user.display_name || '',
                    email: user.email || '',
                  });
                }
              }}
              className="w-4 h-4 text-purple-600 border-neutral-300 rounded focus:ring-purple-500"
            />
            <label
              htmlFor="useProfileData"
              className="text-sm text-neutral-900 dark:text-neutral-50 cursor-pointer"
            >
              Use my profile information
            </label>
          </div>

          {/* Password for Private Events */}
          {!event.is_public && event.is_password_protected && (
            <div>
              <Input
                label="Event Password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter event password"
                required
                labelBg="bg-white dark:bg-neutral-950"
              />
            </div>
          )}

          {/* Form Fields */}
          <Input
            label="Full Name"
            value={formData.full_name || ''}
            onChange={(e) => setFormData({ ...formData, full_name: e.target.value })}
            placeholder="Your full name"
            required={!useProfileData}
            disabled={useProfileData}
            labelBg="bg-white dark:bg-neutral-950"
          />

          <Input
            label="Email"
            type="email"
            value={formData.email || ''}
            onChange={(e) => setFormData({ ...formData, email: e.target.value })}
            placeholder="your.email@example.com"
            required={!useProfileData}
            disabled={useProfileData}
            labelBg="bg-white dark:bg-neutral-950"
          />

          <Input
            label="Phone (Optional)"
            type="tel"
            value={formData.phone || ''}
            onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
            placeholder="+1 234 567 8900"
            labelBg="bg-white dark:bg-neutral-950"
          />

          <Input
            label="Organization (Optional)"
            value={formData.organization || ''}
            onChange={(e) => setFormData({ ...formData, organization: e.target.value })}
            placeholder="Company or organization"
            labelBg="bg-white dark:bg-neutral-950"
          />

          <div>
            <label className="block text-sm font-medium text-neutral-900 dark:text-neutral-50 mb-2">
              Additional Information (Optional)
            </label>
            <textarea
              value={formData.additional_info || ''}
              onChange={(e) => setFormData({ ...formData, additional_info: e.target.value })}
              placeholder="Any additional information you'd like to share..."
              rows={4}
              className="w-full px-4 py-3 text-sm rounded-lg border border-neutral-200 dark:border-neutral-800 bg-transparent text-neutral-900 dark:text-neutral-50 placeholder-neutral-400 dark:placeholder-neutral-500 focus:outline-none focus:ring-2 focus:ring-brand-purple-500 focus:border-brand-purple-500 resize-none"
            />
          </div>

          {/* Error Message */}
          {error && (
            <div className="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
              <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
            </div>
          )}

          {/* Actions */}
          <div className="flex items-center gap-3 pt-4">
            <Button
              type="button"
              variant="secondary"
              size="md"
              onClick={onClose}
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
              {loading ? 'Applying...' : 'Apply'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
