'use client';

/**
 * Profile Page
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * User profile page with cover, avatar, stats, and tabs
 * iOS-inspired design with glassmorphism
 */

import { useState } from 'react';
import { MainLayout } from '@/components/layout/MainLayout';
import { Card } from '@/components/ui/Card';
import { Avatar } from '@/components/ui/Avatar';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { MapPin, Link as LinkIcon, Calendar, Share2, MoreVertical } from 'lucide-react';
import { formatNumber } from '@/lib/utils';

const tabs = ['Posts', 'Research', 'Communities', 'Projects', 'About'];

// Demo user data
const demoUser = {
  name: 'Hamza Hafeez',
  username: 'hamzahafeez',
  bio: 'Founder & CEO of Upvista | Building the future of professional social networking | AI enthusiast | Investor',
  location: 'San Francisco, CA',
  website: 'https://upvista.com',
  joinedDate: 'January 2024',
  verified: true,
  avatar: null,
  coverImage: null,
  stats: {
    posts: 250,
    followers: 1200,
    following: 340,
  },
};

export default function ProfilePage() {
  const [activeTab, setActiveTab] = useState('Posts');
  const [isFollowing, setIsFollowing] = useState(false);

  return (
    <MainLayout>
      <div className="space-y-6">
        {/* Cover & Profile Header */}
        <Card variant="glass" hoverable={false} className="p-0 overflow-hidden">
          {/* Cover Image */}
          <div className="h-48 md:h-64 bg-gradient-to-r from-brand-purple-600 via-brand-purple-500 to-brand-purple-400 relative">
            {/* Glassmorphic overlay pattern */}
            <div className="absolute inset-0 bg-white/10 backdrop-blur-sm" />
          </div>

          {/* Profile Info */}
          <div className="px-6 pb-6">
            {/* Avatar */}
            <div className="relative -mt-16 mb-4">
              <div className="inline-block rounded-full p-1 bg-white dark:bg-neutral-900">
                <Avatar
                  src={demoUser.avatar}
                  alt={demoUser.name}
                  fallback={demoUser.name}
                  size="3xl"
                />
              </div>
            </div>

            {/* Name & Actions */}
            <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4 mb-4">
              <div>
                <div className="flex items-center gap-2 mb-1">
                  <h1 className="text-2xl md:text-3xl font-bold text-neutral-900 dark:text-neutral-50">
                    {demoUser.name}
                  </h1>
                  {demoUser.verified && (
                    <Badge variant="info">✓ Verified</Badge>
                  )}
                </div>
                <p className="text-base text-neutral-500 dark:text-neutral-400">
                  @{demoUser.username}
                </p>
              </div>

              <div className="flex gap-2">
                <Button variant="secondary" size="sm">
                  <Share2 className="w-4 h-4" />
                  Share
                </Button>
                <Button variant="ghost" size="sm">
                  <MoreVertical className="w-4 h-4" />
                </Button>
                <Button variant="primary" size="sm">
                  Edit Profile
                </Button>
              </div>
            </div>

            {/* Bio */}
            <p className="text-base text-neutral-700 dark:text-neutral-300 mb-4">
              {demoUser.bio}
            </p>

            {/* Meta Info */}
            <div className="flex flex-wrap gap-4 text-sm text-neutral-600 dark:text-neutral-400 mb-4">
              {demoUser.location && (
                <div className="flex items-center gap-1">
                  <MapPin className="w-4 h-4" />
                  <span>{demoUser.location}</span>
                </div>
              )}
              {demoUser.website && (
                <a 
                  href={demoUser.website} 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="flex items-center gap-1 text-brand-purple-600 dark:text-brand-purple-400 hover:underline"
                >
                  <LinkIcon className="w-4 h-4" />
                  <span>upvista.com</span>
                </a>
              )}
              <div className="flex items-center gap-1">
                <Calendar className="w-4 h-4" />
                <span>Joined {demoUser.joinedDate}</span>
              </div>
            </div>

            {/* Stats */}
            <div className="flex gap-6 pt-4 border-t border-neutral-200/50 dark:border-neutral-700/50">
              <button className="hover:underline">
                <span className="font-semibold text-neutral-900 dark:text-neutral-50">
                  {formatNumber(demoUser.stats.posts)}
                </span>
                <span className="text-neutral-600 dark:text-neutral-400 ml-1">
                  Posts
                </span>
              </button>
              <button className="hover:underline">
                <span className="font-semibold text-neutral-900 dark:text-neutral-50">
                  {formatNumber(demoUser.stats.followers)}
                </span>
                <span className="text-neutral-600 dark:text-neutral-400 ml-1">
                  Followers
                </span>
              </button>
              <button className="hover:underline">
                <span className="font-semibold text-neutral-900 dark:text-neutral-50">
                  {formatNumber(demoUser.stats.following)}
                </span>
                <span className="text-neutral-600 dark:text-neutral-400 ml-1">
                  Following
                </span>
              </button>
            </div>
          </div>
        </Card>

        {/* Tabs */}
        <Card variant="glass" hoverable={false} className="p-4">
          <div className="flex gap-2 overflow-x-auto scrollbar-hide">
            {tabs.map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`
                  px-4 py-2 rounded-lg text-sm font-semibold whitespace-nowrap transition-all duration-200
                  ${activeTab === tab
                    ? 'bg-brand-purple-600 text-white shadow-md'
                    : 'text-neutral-700 dark:text-neutral-300 hover:bg-neutral-100 dark:hover:bg-neutral-800'
                  }
                `}
              >
                {tab}
              </button>
            ))}
          </div>
        </Card>

        {/* Tab Content */}
        <Card variant="glass" hoverable={false}>
          <div className="text-center py-16">
            <div className="w-20 h-20 mx-auto mb-6 bg-neutral-100 dark:bg-neutral-800 rounded-full flex items-center justify-center">
              <span className="text-4xl">📝</span>
            </div>
            <h3 className="text-xl font-semibold text-neutral-900 dark:text-neutral-50 mb-2">
              No {activeTab} Yet
            </h3>
            <p className="text-base text-neutral-600 dark:text-neutral-400">
              Start sharing your ideas and connect with the community!
            </p>
          </div>
        </Card>
      </div>
    </MainLayout>
  );
}

