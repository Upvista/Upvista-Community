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
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, className, ...props }, ref) => {
    return (
      <div className="relative">
        <input
          ref={ref}
          placeholder=" "
          className={cn(
            'peer w-full rounded-2xl border-2 bg-transparent px-5 py-4 text-base text-neutral-900 dark:text-neutral-50 transition-all duration-200 placeholder-transparent focus:outline-none',
            error
              ? 'border-error focus:border-error'
              : 'border-neutral-300 dark:border-neutral-700 focus:border-brand-purple-600',
            className
          )}
          {...props}
        />
        <label
          className={cn(
            'absolute -top-3 left-4 bg-white dark:bg-neutral-950 px-2 text-sm font-medium transition-all duration-200',
            'peer-placeholder-shown:top-4 peer-placeholder-shown:text-base peer-placeholder-shown:text-neutral-400',
            'peer-focus:-top-3 peer-focus:text-sm',
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

