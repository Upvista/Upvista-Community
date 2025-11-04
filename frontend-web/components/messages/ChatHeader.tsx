'use client';

import { Conversation, formatLastSeen } from '@/lib/api/messages';
import { Avatar } from '../ui/Avatar';
import { ArrowLeft, Phone, Video, MoreVertical } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { toast } from '@/components/ui/Toast';

interface ChatHeaderProps {
  conversation: Conversation;
  onClose?: () => void;
}

export default function ChatHeader({ conversation, onClose }: ChatHeaderProps) {
  const router = useRouter();
  const otherUser = conversation.other_user;

  if (!otherUser) return null;

  const handleViewProfile = () => {
    router.push(`/profile/${otherUser.username}`);
  };

  return (
    <div className="flex items-center justify-between px-4 py-3 border-b border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900">
      {/* Left: Back + User Info */}
      <div className="flex items-center gap-3 flex-1 min-w-0">
        {/* Back Arrow (mobile) */}
        {onClose && (
          <button
            onClick={onClose}
            className="md:hidden p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-full"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
        )}

        {/* Avatar */}
        <div className="cursor-pointer" onClick={handleViewProfile}>
          <Avatar
            src={otherUser.profile_picture || otherUser.avatar_url}
            alt={otherUser.display_name || otherUser.username}
            fallback={otherUser.display_name || otherUser.username}
            size="sm"
            showOnline={true}
            isOnline={conversation.is_online}
          />
        </div>

        {/* User Info */}
        <div className="flex-1 min-w-0 cursor-pointer" onClick={handleViewProfile}>
          <h3 className="text-sm font-semibold text-gray-900 dark:text-white truncate">
            {otherUser.display_name || otherUser.username}
          </h3>
          <p className="text-xs text-gray-500 dark:text-gray-400">
            {conversation.is_online ? (
              <span className="text-green-600 dark:text-green-400">Online</span>
            ) : conversation.last_seen ? (
              `Last seen ${formatLastSeen(conversation.last_seen)}`
            ) : (
              'Offline'
            )}
          </p>
        </div>
      </div>

      {/* Right: Action Buttons */}
      <div className="flex items-center gap-2">
        {/* Voice Call - Placeholder for Phase 2 */}
        <button
          onClick={() => toast.info('Voice calls coming in Phase 2!')}
          className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-full transition-colors"
          title="Voice call (coming soon)"
        >
          <Phone className="w-5 h-5 text-gray-600 dark:text-gray-400" />
        </button>

        {/* Video Call - Placeholder for Phase 2 */}
        <button
          onClick={() => toast.info('Video calls coming in Phase 2!')}
          className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-full transition-colors"
          title="Video call (coming soon)"
        >
          <Video className="w-5 h-5 text-gray-600 dark:text-gray-400" />
        </button>

        {/* More Options */}
        <button
          onClick={() => toast.info('Chat settings coming soon!')}
          className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-full transition-colors"
          title="More options"
        >
          <MoreVertical className="w-5 h-5 text-gray-600 dark:text-gray-400" />
        </button>
      </div>
    </div>
  );
}

