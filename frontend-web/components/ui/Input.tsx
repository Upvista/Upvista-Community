/**
 * Input Component
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Floating label input with iOS-inspired styling
 * Reuses the pattern from auth pages
 */

import { InputHTMLAttributes, forwardRef } from 'react';
import { cn } from '@/lib/utils';

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label: string;
  error?: string;
  labelBg?: string; // Custom background for label
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, className, labelBg, ...props }, ref) => {
    return (
      <div className="relative">
        <input
          ref={ref}
          placeholder=" "
          className={cn(
            'peer w-full rounded-2xl border-2 bg-transparent px-4 py-3 md:px-5 md:py-4 text-sm md:text-base text-neutral-900 dark:text-neutral-50 transition-all duration-200 placeholder-transparent focus:outline-none',
            error
              ? 'border-error focus:border-error'
              : 'border-neutral-300 dark:border-neutral-700 focus:border-brand-purple-600',
            className
          )}
          {...props}
        />
        <label
          className={cn(
            'absolute -top-2.5 left-4 px-2 text-xs md:text-sm font-medium transition-all duration-200 pointer-events-none',
            'peer-placeholder-shown:top-3 md:peer-placeholder-shown:top-4 peer-placeholder-shown:text-sm md:peer-placeholder-shown:text-base peer-placeholder-shown:text-neutral-400',
            'peer-focus:-top-2.5 peer-focus:text-xs md:peer-focus:text-sm',
            labelBg || 'bg-white dark:bg-neutral-900',
            error
              ? 'text-error peer-focus:text-error'
              : 'text-brand-purple-600 dark:text-brand-purple-400 peer-focus:text-brand-purple-600 dark:peer-focus:text-brand-purple-400'
          )}
        >
          {label}
        </label>
        {error && (
          <p className="mt-2 text-sm text-error">{error}</p>
        )}
      </div>
    );
  }
);

Input.displayName = 'Input';

