'use client';

/**
 * Topbar Component
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Mobile top bar with logo, burger menu, and action icons
 * Glassmorphic styling with slide-out menu drawer
 */

import Link from 'next/link';
import { useState } from 'react';
import { 
  Bell, 
  Briefcase, 
  MessageCircle, 
  Menu, 
  X,
  Settings,
  Activity,
  Bookmark,
  DollarSign,
  BarChart,
  Users2,
  Languages,
  AlertCircle,
  SunMoon,
  Info,
  LogOut,
} from 'lucide-react';
import { IconButton } from '@/components/ui/IconButton';
import { useTheme } from '@/lib/contexts/ThemeContext';
import { motion, AnimatePresence } from 'framer-motion';

const moreMenu = [
  { name: 'Settings', href: '/settings', icon: Settings },
  { name: 'Your Activity', href: '/activity', icon: Activity },
  { name: 'Saved', href: '/saved', icon: Bookmark },
  { name: 'Your Earnings', href: '/earnings', icon: DollarSign },
  { name: 'Account Summary', href: '/account', icon: BarChart },
  { name: 'Switch Profiles', href: '/switch-profile', icon: Users2 },
  { name: 'Switch Language', href: '/language', icon: Languages },
  { name: 'Report a Problem', href: '/report', icon: AlertCircle },
  { name: 'About', href: '/about', icon: Info },
];

export function Topbar() {
  const [showMenu, setShowMenu] = useState(false);
  const { theme, toggleTheme } = useTheme();

  return (
    <>
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
            <IconButton onClick={() => setShowMenu(true)} className="w-11 h-11 md:w-10 md:h-10">
              <Menu className="w-6 h-6 md:w-5 md:h-5" />
            </IconButton>
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

      {/* Mobile Menu Drawer */}
      <AnimatePresence>
        {showMenu && (
          <>
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.2 }}
              className="lg:hidden fixed inset-0 bg-black/50 backdrop-blur-sm z-[60]"
              onClick={() => setShowMenu(false)}
            />

            {/* Menu Drawer */}
            <motion.div
              initial={{ x: '-100%' }}
              animate={{ x: 0 }}
              exit={{ x: '-100%' }}
              transition={{ type: 'spring', damping: 25, stiffness: 300 }}
              className="lg:hidden fixed top-0 left-0 bottom-0 w-[85%] max-w-sm bg-white/95 dark:bg-gray-900/95 backdrop-blur-2xl z-[70] shadow-2xl"
            >
              <div className="flex flex-col h-full">
                {/* Header */}
                <div className="flex items-center justify-between p-4 border-b border-neutral-200 dark:border-neutral-800">
                  <div className="flex items-center gap-2.5">
                    <img src="/assets/u.png" alt="Upvista" className="w-8 h-8" />
                    <span className="text-lg font-bold bg-gradient-to-r from-brand-purple-600 to-brand-purple-400 bg-clip-text text-transparent">
                      Menu
                    </span>
                  </div>
                  <button
                    onClick={() => setShowMenu(false)}
                    className="w-10 h-10 flex items-center justify-center rounded-full hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors"
                  >
                    <X className="w-6 h-6 text-neutral-600 dark:text-neutral-400" />
                  </button>
                </div>

                {/* Menu Items */}
                <div className="flex-1 overflow-y-auto p-2">
                  <nav className="space-y-1">
                    {moreMenu.map((item) => {
                      const Icon = item.icon;
                      return (
                        <Link
                          key={item.name}
                          href={item.href}
                          onClick={() => setShowMenu(false)}
                          className="flex items-center gap-3 px-4 py-3.5 rounded-xl text-neutral-700 dark:text-neutral-300 hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors active:scale-98"
                        >
                          <Icon className="w-5 h-5 flex-shrink-0" />
                          <span className="text-base font-medium">{item.name}</span>
                        </Link>
                      );
                    })}

                    {/* Theme Toggle */}
                    <button
                      onClick={() => {
                        toggleTheme();
                        setShowMenu(false);
                      }}
                      className="w-full flex items-center gap-3 px-4 py-3.5 rounded-xl text-neutral-700 dark:text-neutral-300 hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors active:scale-98"
                    >
                      <SunMoon className="w-5 h-5 flex-shrink-0" />
                      <span className="text-base font-medium">
                        Switch Theme ({theme === 'light' ? 'Dark' : 'Light'})
                      </span>
                    </button>
                  </nav>
                </div>

                {/* Footer */}
                <div className="p-4 border-t border-neutral-200 dark:border-neutral-800">
                  <button
                    onClick={() => {
                      localStorage.removeItem('token');
                      window.location.href = '/auth';
                    }}
                    className="w-full flex items-center gap-3 px-4 py-3.5 rounded-xl text-error hover:bg-red-50 dark:hover:bg-red-950/30 transition-colors active:scale-98"
                  >
                    <LogOut className="w-5 h-5 flex-shrink-0" />
                    <span className="text-base font-semibold">Logout</span>
                  </button>
                </div>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </>
  );
}


