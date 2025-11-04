/**
 * Main App Layout
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Layout wrapper for authenticated pages
 */

'use client';

import { ReactNode } from 'react';
import { NotificationProvider } from '@/lib/contexts/NotificationContext';
import { MessagesProvider } from '@/lib/contexts/MessagesContext';
import MobileMessagesOverlay from '@/components/messages/MobileMessagesOverlay';

export default function MainAppLayout({ children }: { children: ReactNode }) {
  return (
    <NotificationProvider>
      <MessagesProvider>
        {children}
        <MobileMessagesOverlay />
      </MessagesProvider>
    </NotificationProvider>
  );
}

