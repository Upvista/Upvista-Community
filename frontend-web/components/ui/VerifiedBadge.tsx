'use client';

/**
 * Verified Badge Component
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Professional verified badge with brand purple styling
 * Executive and authoritative design
 */

import { CheckCircle2, Shield } from 'lucide-react';

interface VerifiedBadgeProps {
  size?: 'sm' | 'md' | 'lg';
  variant?: 'inline' | 'badge'; // inline = just icon, badge = full badge with text
  showText?: boolean;
  isVerified?: boolean; // Controls verified vs not verified state
}

export default function VerifiedBadge({ 
  size = 'md', 
  variant = 'badge',
  showText = true,
  isVerified = true 
}: VerifiedBadgeProps) {
  
  const sizeClasses = {
    sm: {
      icon: 'w-4 h-4',
      text: 'text-[10px]',
      padding: 'px-2 py-0.5',
      gap: 'gap-1',
    },
    md: {
      icon: 'w-4 h-4',
      text: 'text-xs',
      padding: 'px-2.5 py-1',
      gap: 'gap-1.5',
    },
    lg: {
      icon: 'w-5 h-5',
      text: 'text-sm',
      padding: 'px-3 py-1.5',
      gap: 'gap-2',
    },
  };

  const classes = sizeClasses[size];

  if (variant === 'inline') {
    return (
      <div className="relative inline-flex items-center justify-center">
        <CheckCircle2 
          className={`${classes.icon} ${
            isVerified 
              ? 'text-blue-500 dark:text-blue-400 fill-blue-500 dark:fill-blue-400'
              : 'text-neutral-400 dark:text-neutral-600 fill-neutral-400 dark:fill-neutral-600'
          }`}
        />
      </div>
    );
  }

  return (
    <div className={`
      inline-flex items-center ${classes.gap} ${classes.padding}
      ${isVerified 
        ? 'bg-gradient-to-r from-blue-600 to-blue-500 text-white shadow-sm shadow-blue-500/20'
        : 'bg-neutral-200 dark:bg-neutral-700 text-neutral-600 dark:text-neutral-400'
      }
      font-semibold rounded-full
      ${classes.text}
    `}>
      <Shield className={`${classes.icon} ${isVerified ? 'fill-white' : 'fill-neutral-500 dark:fill-neutral-400'}`} />
      {showText && <span>{isVerified ? 'Verified' : 'Not Verified'}</span>}
    </div>
  );
}

