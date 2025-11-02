'use client';

/**
 * Sidebar Component
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Desktop left sidebar with navigation
 * Glassmorphic styling with iOS-inspired design
 */

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useState } from 'react';
import { cn } from '@/lib/utils';
import {
  Home,
  Search,
  Users,
  Compass,
  MessageCircle,
  Bell,
  PlusSquare,
  Briefcase,
  User,
  Menu,
  Settings,
  Activity,
  Bookmark,
  DollarSign,
  BarChart,
  Users2,
  SunMoon,
  Languages,
  AlertCircle,
  LogOut,
} from 'lucide-react';
import { useTheme } from '@/lib/contexts/ThemeContext';
import { Avatar } from '@/components/ui/Avatar';
import { Badge } from '@/components/ui/Badge';

const navigation = [
  { name: 'Home', href: '/home', icon: Home },
  { name: 'Search', href: '/search', icon: Search },
  { name: 'Communities', href: '/communities', icon: Users },
  { name: 'Explore', href: '/explore', icon: Compass },
  { name: 'Messages', href: '/messages', icon: MessageCircle, badge: 3 },
  { name: 'Notifications', href: '/notifications', icon: Bell, badge: 12 },
  { name: 'Create', href: '/create', icon: PlusSquare },
  { name: 'Collaborate', href: '/collaborate', icon: Users },
  { name: 'Jobs', href: '/jobs', icon: Briefcase },
  { name: 'Profile', href: '/profile', icon: User },
];

const moreMenu = [
  { name: 'Settings', href: '/settings', icon: Settings },
  { name: 'Your Activity', href: '/activity', icon: Activity },
  { name: 'Saved', href: '/saved', icon: Bookmark },
  { name: 'Your Earnings', href: '/earnings', icon: DollarSign },
  { name: 'Account Summary', href: '/account', icon: BarChart },
  { name: 'Switch Profiles', href: '/switch-profile', icon: Users2 },
  { name: 'Switch Language', href: '/language', icon: Languages },
  { name: 'Report a Problem', href: '/report', icon: AlertCircle },
];

export function Sidebar() {
  const pathname = usePathname();
  const { theme, toggleTheme } = useTheme();
  const [showMore, setShowMore] = useState(false);
  
  // Mock user data - replace with actual user data
  const user = {
    name: 'Hamza Hafeez',
    username: 'hamza',
    avatar: null,
  };

  const isActive = (href: string) => pathname === href;

  return (
    <aside className="hidden lg:flex w-60 h-screen fixed top-0 left-0 z-40">
      <nav className="w-full h-full bg-white/80 dark:bg-gray-900/60 backdrop-blur-2xl border-r border-neutral-200/50 dark:border-neutral-800/50 flex flex-col py-6 px-4">
        {/* Logo */}
        <Link href="/home" className="flex items-center gap-3 px-4 mb-8 group">
          <img 
            src="/assets/u.png" 
            alt="Upvista" 
            className="w-10 h-10 transition-transform group-hover:scale-110" 
          />
          <h1 className="text-xl font-bold">
            <span className="bg-gradient-to-r from-brand-purple-600 to-brand-purple-400 bg-clip-text text-transparent">
              Upvista
            </span>
            {' '}
            <span className="text-neutral-900 dark:text-neutral-100">
              Community
            </span>
          </h1>
        </Link>

        {/* Navigation Items */}
        <div className="flex-1 space-y-1 overflow-y-auto scrollbar-hide">
          {navigation.map((item) => {
            const Icon = item.icon;
            const active = isActive(item.href);
            
            return (
              <Link
                key={item.name}
                href={item.href}
                className={cn(
                  'flex items-center gap-4 px-4 py-3 rounded-xl font-medium transition-all duration-200',
                  active
                    ? 'bg-brand-purple-100 dark:bg-brand-purple-900/30 text-brand-purple-600 dark:text-brand-purple-400 border-l-4 border-brand-purple-600'
                    : 'text-neutral-700 dark:text-neutral-300 hover:bg-neutral-100 dark:hover:bg-neutral-800'
                )}
              >
                <Icon className="w-6 h-6 flex-shrink-0" />
                <span className="flex-1">{item.name}</span>
                {item.badge !== undefined && (
                  <Badge variant="error" size="sm">
                    {item.badge > 99 ? '99+' : item.badge}
                  </Badge>
                )}
              </Link>
            );
          })}
        </div>

        {/* More Menu */}
        <div className="relative mt-4">
          <button
            onClick={() => setShowMore(!showMore)}
            className="w-full flex items-center gap-4 px-4 py-3 rounded-xl font-medium text-neutral-700 dark:text-neutral-300 hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors duration-200"
          >
            <Menu className="w-6 h-6" />
            <span>More</span>
          </button>

          {showMore && (
            <div className="absolute bottom-full left-0 right-0 mb-2 bg-white/90 dark:bg-gray-900/90 backdrop-blur-xl border border-neutral-200/50 dark:border-neutral-800/50 rounded-2xl shadow-2xl p-2 space-y-1">
              {moreMenu.map((item) => {
                const Icon = item.icon;
                return (
                  <Link
                    key={item.name}
                    href={item.href}
                    className="flex items-center gap-3 px-4 py-2.5 rounded-lg text-sm font-medium text-neutral-700 dark:text-neutral-300 hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors duration-200"
                  >
                    <Icon className="w-5 h-5" />
                    <span>{item.name}</span>
                  </Link>
                );
              })}
              
              {/* Theme Toggle */}
              <button
                onClick={toggleTheme}
                className="w-full flex items-center gap-3 px-4 py-2.5 rounded-lg text-sm font-medium text-neutral-700 dark:text-neutral-300 hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors duration-200"
              >
                <SunMoon className="w-5 h-5" />
                <span>Switch Theme ({theme})</span>
              </button>
              
              {/* Logout */}
              <button
                onClick={() => {
                  localStorage.removeItem('token');
                  window.location.href = '/auth';
                }}
                className="w-full flex items-center gap-3 px-4 py-2.5 rounded-lg text-sm font-medium text-error hover:bg-red-50 dark:hover:bg-red-950/30 transition-colors duration-200"
              >
                <LogOut className="w-5 h-5" />
                <span>Logout</span>
              </button>
            </div>
          )}
        </div>
      </nav>
    </aside>
  );
}

