'use client';

/**
 * Home Page
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Main feed page with category filters
 * iOS-inspired design with glassmorphic cards
 */

import { useState } from 'react';
import { MainLayout } from '@/components/layout/MainLayout';
import { Card } from '@/components/ui/Card';
import { Avatar } from '@/components/ui/Avatar';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Heart, MessageCircle, Share2, Bookmark, MoreVertical, TrendingUp, Users as UsersIcon } from 'lucide-react';
import { formatRelativeTime, formatNumber } from '@/lib/utils';
import { motion } from 'framer-motion';

const categories = ['All', 'Communities', 'Research', 'Posts', 'Projects', 'Blogs', 'Reels'];

// Demo feed data
const demoFeed = [
  {
    id: '1',
    author: {
      name: 'Hamza Hafeez',
      username: 'hamzahafeez',
      avatar: null,
      verified: true,
    },
    type: 'Research Article',
    title: 'The Future of AI in Healthcare: A Comprehensive Study',
    content: 'After months of research, I\'m excited to share our findings on how artificial intelligence is revolutionizing healthcare. From early disease detection to personalized treatment plans, AI is transforming patient care in unprecedented ways...',
    image: null,
    category: 'Research',
    stats: {
      likes: 245,
      comments: 32,
      shares: 18,
    },
    timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours ago
  },
  {
    id: '2',
    author: {
      name: 'Sarah Chen',
      username: 'sarahchen',
      avatar: null,
      verified: false,
    },
    type: 'Blog Post',
    title: 'My Journey Building a Startup from Scratch',
    content: 'When I started my journey as a founder, I had no idea what I was getting into. Here are 10 lessons I learned in my first year that I wish someone had told me...',
    image: null,
    category: 'Posts',
    stats: {
      likes: 892,
      comments: 156,
      shares: 73,
    },
    timestamp: new Date(Date.now() - 5 * 60 * 60 * 1000), // 5 hours ago
  },
  {
    id: '3',
    author: {
      name: 'Tech Innovators',
      username: 'techinnovators',
      avatar: null,
      verified: true,
    },
    type: 'Community Post',
    title: 'Weekly Tech Discussion: Web3 and Blockchain',
    content: 'Join us this Friday for an engaging discussion on the future of Web3 and blockchain technology. Experts from leading companies will share insights and answer your questions!',
    image: null,
    category: 'Communities',
    stats: {
      likes: 1240,
      comments: 89,
      shares: 45,
    },
    timestamp: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000), // 1 day ago
  },
];

export default function HomePage() {
  const [activeCategory, setActiveCategory] = useState('All');
  const [feed, setFeed] = useState(demoFeed);
  const [showEmptyState, setShowEmptyState] = useState(false);

  // Filter feed based on category
  const filteredFeed = activeCategory === 'All' 
    ? feed 
    : feed.filter(post => post.category === activeCategory);

  return (
    <MainLayout showRightPanel={true} rightPanel={<RightPanel />}>
      <div className="space-y-4 md:space-y-6">
        {/* Category Tabs */}
        <div className="flex gap-2 md:gap-2 overflow-x-auto scrollbar-hide pb-1">
          {categories.map((category) => (
            <button
              key={category}
              onClick={() => setActiveCategory(category)}
              className={`
                px-5 py-2.5 md:px-4 md:py-2 rounded-full text-base md:text-sm font-semibold whitespace-nowrap transition-all duration-200
                ${activeCategory === category
                  ? 'bg-brand-purple-600 text-white shadow-lg shadow-brand-purple-500/30'
                  : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-700 dark:text-neutral-300 hover:bg-neutral-200 dark:hover:bg-neutral-700'
                }
              `}
            >
              {category}
            </button>
          ))}
        </div>

        {/* Feed or Empty State */}
        {filteredFeed.length === 0 || showEmptyState ? (
          <EmptyFeed />
        ) : (
          <div className="space-y-5 md:space-y-6">
            {filteredFeed.map((post) => (
              <FeedCard key={post.id} post={post} />
            ))}
            
            {/* Load More */}
            <div className="flex justify-center py-6 md:py-4">
              <Button variant="secondary" size="md">
                Load More Posts
              </Button>
            </div>
          </div>
        )}
      </div>
    </MainLayout>
  );
}

function FeedCard({ post }: { post: typeof demoFeed[0] }) {
  const [liked, setLiked] = useState(false);
  const [saved, setSaved] = useState(false);

  return (
    <motion.div
      whileHover={{ y: -2 }}
      transition={{ duration: 0.2 }}
    >
      <Card variant="glass" hoverable={false} className="p-5 md:p-6">
      {/* Header */}
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center gap-3">
          <Avatar 
            src={post.author.avatar} 
            alt={post.author.name} 
            fallback={post.author.name}
            size="lg"
            className="md:w-10 md:h-10"
          />
          <div>
            <div className="flex items-center gap-2">
              <h3 className="text-base md:text-base font-semibold text-neutral-900 dark:text-neutral-50">
                {post.author.name}
              </h3>
              {post.author.verified && (
                <Badge variant="info" size="sm">✓</Badge>
              )}
            </div>
            <p className="text-sm md:text-sm text-neutral-500 dark:text-neutral-400">
              @{post.author.username} · {formatRelativeTime(post.timestamp)}
            </p>
          </div>
        </div>
        <button className="text-neutral-400 hover:text-neutral-600 dark:hover:text-neutral-300 p-1">
          <MoreVertical className="w-6 h-6 md:w-5 md:h-5" />
        </button>
      </div>

      {/* Category Badge */}
      <div className="mb-3">
        <Badge variant="purple" size="md" className="md:text-xs md:px-2.5 md:py-0.5">{post.type}</Badge>
      </div>

      {/* Content */}
      <div className="mb-5">
        <h2 className="text-xl md:text-xl font-semibold text-neutral-900 dark:text-neutral-50 mb-2.5 leading-tight">
          {post.title}
        </h2>
        <p className="text-base md:text-base text-neutral-700 dark:text-neutral-300 line-clamp-3 leading-relaxed">
          {post.content}
        </p>
        <button className="text-brand-purple-600 dark:text-brand-purple-400 text-base md:text-sm font-medium mt-2.5 hover:underline">
          Read more
        </button>
      </div>

      {/* Media (if exists) */}
      {post.image && (
        <img src={post.image} alt="" className="rounded-xl mb-4 w-full object-cover max-h-96" />
      )}

      {/* Actions */}
      <div className="flex items-center gap-6 md:gap-6 text-neutral-600 dark:text-neutral-400 pt-5 md:pt-4 border-t border-neutral-200/50 dark:border-neutral-700/50">
        <button 
          onClick={() => setLiked(!liked)}
          className={`flex items-center gap-2 transition-colors active:scale-95 ${liked ? 'text-red-500' : 'hover:text-brand-purple-600'}`}
        >
          <Heart className={`w-6 h-6 md:w-5 md:h-5 ${liked ? 'fill-current' : ''}`} />
          <span className="text-base md:text-sm font-medium">{formatNumber(post.stats.likes + (liked ? 1 : 0))}</span>
        </button>
        <button className="flex items-center gap-2 hover:text-brand-purple-600 transition-colors active:scale-95">
          <MessageCircle className="w-6 h-6 md:w-5 md:h-5" />
          <span className="text-base md:text-sm font-medium">{formatNumber(post.stats.comments)}</span>
        </button>
        <button className="flex items-center gap-2 hover:text-brand-purple-600 transition-colors active:scale-95">
          <Share2 className="w-6 h-6 md:w-5 md:h-5" />
          <span className="text-base md:text-sm font-medium">{formatNumber(post.stats.shares)}</span>
        </button>
        <button 
          onClick={() => setSaved(!saved)}
          className={`ml-auto flex items-center gap-2 transition-colors active:scale-95 ${saved ? 'text-brand-purple-600' : 'hover:text-brand-purple-600'}`}
        >
          <Bookmark className={`w-6 h-6 md:w-5 md:h-5 ${saved ? 'fill-current' : ''}`} />
        </button>
      </div>
    </Card>
    </motion.div>
  );
}

function EmptyFeed() {
  return (
    <Card variant="glass" hoverable={false} className="p-8 md:p-6">
      <div className="text-center py-12 md:py-16">
        <div className="w-24 h-24 md:w-20 md:h-20 mx-auto mb-6 bg-brand-purple-100 dark:bg-brand-purple-900/30 rounded-full flex items-center justify-center">
          <span className="text-5xl md:text-4xl">🌟</span>
        </div>
        <h2 className="text-2xl md:text-2xl font-semibold text-neutral-900 dark:text-neutral-50 mb-3">
          Welcome to Upvista Community!
        </h2>
        <p className="text-base md:text-base text-neutral-600 dark:text-neutral-400 mb-8 max-w-md mx-auto leading-relaxed">
          No posts yet in this category. Start exploring communities or create your first post to get the conversation started!
        </p>
        <div className="flex flex-col md:flex-row gap-3 md:gap-4 justify-center">
          <Button variant="primary" size="md">
            Explore Communities
          </Button>
          <Button variant="secondary" size="md">
            Create Post
          </Button>
        </div>
      </div>
    </Card>
  );
}

function RightPanel() {
  const trendingTopics = [
    { tag: 'AI2025', posts: 12500 },
    { tag: 'WebDevelopment', posts: 8900 },
    { tag: 'Blockchain', posts: 6700 },
    { tag: 'Startups', posts: 5400 },
  ];

  const suggestedCommunities = [
    { name: 'Tech Hub', members: 24000, avatar: null },
    { name: 'Designers United', members: 8500, avatar: null },
    { name: 'Startup Founders', members: 12000, avatar: null },
  ];

  return (
    <div className="space-y-6">
      {/* Trending Topics */}
      <Card variant="solid" hoverable={false}>
        <div className="flex items-center gap-2 mb-4">
          <TrendingUp className="w-5 h-5 text-brand-purple-600" />
          <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50">
            Trending Topics
          </h3>
        </div>
        <div className="space-y-3">
          {trendingTopics.map((topic, index) => (
            <button
              key={topic.tag}
              className="w-full text-left p-3 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors"
            >
              <div className="flex items-start justify-between">
                <div>
                  <p className="text-xs text-neutral-500 dark:text-neutral-400">
                    #{index + 1} Trending
                  </p>
                  <p className="text-sm font-semibold text-neutral-900 dark:text-neutral-50">
                    #{topic.tag}
                  </p>
                  <p className="text-xs text-neutral-500 dark:text-neutral-400">
                    {formatNumber(topic.posts)} posts
                  </p>
                </div>
              </div>
            </button>
          ))}
        </div>
      </Card>

      {/* Suggested Communities */}
      <Card variant="solid" hoverable={false}>
        <div className="flex items-center gap-2 mb-4">
          <UsersIcon className="w-5 h-5 text-brand-purple-600" />
          <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50">
            Suggested Communities
          </h3>
        </div>
        <div className="space-y-3">
          {suggestedCommunities.map((community) => (
            <div
              key={community.name}
              className="flex items-center gap-3 p-3 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors"
            >
              <Avatar 
                src={community.avatar} 
                alt={community.name} 
                fallback={community.name}
                size="md" 
              />
              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold text-neutral-900 dark:text-neutral-50 truncate">
                  {community.name}
                </p>
                <p className="text-xs text-neutral-500 dark:text-neutral-400">
                  {formatNumber(community.members)} members
                </p>
              </div>
              <Button variant="secondary" size="sm">
                Join
              </Button>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}

