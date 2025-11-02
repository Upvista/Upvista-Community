'use client';

/**
 * Bottom Navigation Component
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Mobile bottom navigation bar
 * iOS-inspired tab bar design
 */

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { cn } from '@/lib/utils';
import { Home, Users, PlusSquare, Compass, User } from 'lucide-react';

const navigation = [
  { name: 'Home', href: '/home', icon: Home },
  { name: 'Communities', href: '/communities', icon: Users },
  { name: 'Create', href: '/create', icon: PlusSquare },
  { name: 'Explore', href: '/explore', icon: Compass },
  { name: 'Profile', href: '/profile', icon: User },
];

export function BottomNav() {
  const pathname = usePathname();

  const isActive = (href: string) => pathname === href;

  return (
    <nav className="lg:hidden fixed bottom-0 left-0 right-0 h-16 md:h-16 z-50 bg-white/80 dark:bg-gray-900/60 backdrop-blur-2xl border-t border-neutral-200/50 dark:border-neutral-800/50">
      <div className="h-full px-1 flex items-center justify-around">
        {navigation.map((item) => {
          const Icon = item.icon;
          const active = isActive(item.href);
          
          return (
            <Link
              key={item.name}
              href={item.href}
              className={cn(
                'flex flex-col items-center justify-center gap-1 px-2 py-2 rounded-xl transition-all duration-200 min-w-[64px] md:min-w-[60px] active:scale-95',
                active
                  ? 'text-brand-purple-600 dark:text-brand-purple-400'
                  : 'text-neutral-600 dark:text-neutral-400'
              )}
            >
              <Icon className={cn('w-7 h-7 md:w-6 md:h-6', active && 'scale-110')} />
              <span className="text-xs md:text-xs font-medium">{item.name}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}

