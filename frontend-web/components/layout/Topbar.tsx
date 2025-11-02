'use client';

/**
 * Topbar Component
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Mobile top bar with logo and action icons
 * Glassmorphic styling
 */

import Link from 'next/link';
import { Bell, Briefcase, MessageCircle } from 'lucide-react';
import { IconButton } from '@/components/ui/IconButton';

export function Topbar() {
  return (
    <header className="lg:hidden fixed top-0 left-0 right-0 h-14 md:h-16 z-50 bg-white/80 dark:bg-gray-900/60 backdrop-blur-2xl border-b border-neutral-200/50 dark:border-neutral-800/50">
      <div className="h-full px-4 flex items-center justify-between">
        {/* Logo */}
        <Link href="/home" className="flex items-center gap-2.5">
          <img src="/assets/u.png" alt="Upvista" className="w-9 h-9 md:w-8 md:h-8" />
          <span className="text-xl md:text-lg font-bold bg-gradient-to-r from-brand-purple-600 to-brand-purple-400 bg-clip-text text-transparent">
            Upvista
          </span>
        </Link>

        {/* Action Icons */}
        <div className="flex items-center gap-0.5">
          <IconButton badge={12} className="w-11 h-11 md:w-10 md:h-10">
            <Bell className="w-6 h-6 md:w-5 md:h-5" />
          </IconButton>
          <IconButton className="w-11 h-11 md:w-10 md:h-10">
            <Briefcase className="w-6 h-6 md:w-5 md:h-5" />
          </IconButton>
          <IconButton badge={3} className="w-11 h-11 md:w-10 md:h-10">
            <MessageCircle className="w-6 h-6 md:w-5 md:h-5" />
          </IconButton>
        </div>
      </div>
    </header>
  );
}

