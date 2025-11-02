'use client';

/**
 * Main Layout Component
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Main application layout with sidebar and navigation
 * Responsive: Desktop sidebar, mobile top/bottom nav
 */

import { ReactNode } from 'react';
import { Sidebar } from './Sidebar';
import { Topbar } from './Topbar';
import { BottomNav } from './BottomNav';

interface MainLayoutProps {
  children: ReactNode;
  showRightPanel?: boolean;
  rightPanel?: ReactNode;
}

export function MainLayout({ children, showRightPanel = false, rightPanel }: MainLayoutProps) {
  return (
    <div className="min-h-screen bg-neutral-50 dark:bg-neutral-950">
      {/* Desktop Sidebar */}
      <Sidebar />
      
      {/* Mobile Topbar */}
      <Topbar />
      
      {/* Main Content Area */}
      <div className="flex min-h-screen">
        {/* Sidebar spacer (desktop only) */}
        <div className="hidden lg:block w-60 flex-shrink-0" />
        
        {/* Main Content */}
        <main className="flex-1 pt-14 pb-16 md:pt-16 md:pb-16 lg:pt-0 lg:pb-0 overflow-x-hidden">
          <div className={cn(
            'mx-auto px-4 md:px-6 py-5 md:py-6 w-full',
            showRightPanel ? 'max-w-5xl' : 'max-w-4xl'
          )}>
            {children}
          </div>
        </main>
        
        {/* Right Panel (optional, desktop only) */}
        {showRightPanel && rightPanel && (
          <>
            <aside className="hidden xl:block w-80 flex-shrink-0 sticky top-0 h-screen overflow-y-auto scrollbar-hide py-6 px-4">
              {rightPanel}
            </aside>
          </>
        )}
      </div>
      
      {/* Mobile Bottom Nav */}
      <BottomNav />
    </div>
  );
}

function cn(...classes: (string | undefined | false)[]) {
  return classes.filter(Boolean).join(' ');
}

