'use client';

/**
 * Theme Context Provider
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Manages dark/light theme switching across the application
 * Persists user preference in localStorage
 */

import { createContext, useContext, useEffect, useState, ReactNode } from 'react';

type Theme = 'light' | 'dark' | 'ios';

interface ThemeContextType {
  theme: Theme;
  setTheme: (theme: Theme) => void;
  toggleTheme: () => void;
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<Theme>('light');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    // Load theme from localStorage or system preference
    const stored = localStorage.getItem('upvista-theme') as Theme;
    if (stored && (stored === 'light' || stored === 'dark' || stored === 'ios')) {
      setTheme(stored);
      document.documentElement.classList.remove('dark', 'ios');
      if (stored === 'dark') {
        document.documentElement.classList.add('dark');
      } else if (stored === 'ios') {
        document.documentElement.classList.add('ios');
      }
    } else {
      // Check system preference
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      const systemTheme = prefersDark ? 'dark' : 'light';
      setTheme(systemTheme);
      document.documentElement.classList.toggle('dark', systemTheme === 'dark');
    }
  }, []);

  const handleSetTheme = (newTheme: Theme) => {
    setTheme(newTheme);
    localStorage.setItem('upvista-theme', newTheme);
    
    // Remove all theme classes first
    document.documentElement.classList.remove('dark', 'ios');
    
    // Add appropriate theme class
    if (newTheme === 'dark') {
      document.documentElement.classList.add('dark');
    } else if (newTheme === 'ios') {
      document.documentElement.classList.add('ios');
    }
  };

  const toggleTheme = () => {
    // Cycle through: light → ios → dark → light
    const themeOrder: Theme[] = ['light', 'ios', 'dark'];
    const currentIndex = themeOrder.indexOf(theme);
    const nextIndex = (currentIndex + 1) % themeOrder.length;
    handleSetTheme(themeOrder[nextIndex]);
  };

  // Prevent flash of wrong theme
  if (!mounted) {
    return <div className="min-h-screen bg-neutral-50" />;
  }

  return (
    <ThemeContext.Provider value={{ theme, setTheme: handleSetTheme, toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

export const useTheme = () => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider');
  }
  return context;
};

