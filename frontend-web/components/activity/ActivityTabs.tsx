'use client';

import { motion } from 'framer-motion';
import { Heart, Archive, Share2, Lightbulb, DollarSign, BarChart } from 'lucide-react';
import { ActivityTab } from '@/app/(main)/activity/page';

interface ActivityTabsProps {
  activeTab: ActivityTab;
  onTabChange: (tab: ActivityTab) => void;
}

const tabs: { id: ActivityTab; label: string; icon: typeof Heart }[] = [
  { id: 'interactions', label: 'Interactions', icon: Heart },
  { id: 'archived', label: 'Removed & Archived', icon: Archive },
  { id: 'shared', label: 'Content You Share', icon: Share2 },
  { id: 'suggested', label: 'Suggested Content', icon: Lightbulb },
  { id: 'finances', label: 'Your Finances', icon: DollarSign },
  { id: 'usage', label: 'How You Use This App', icon: BarChart },
];

export default function ActivityTabs({ activeTab, onTabChange }: ActivityTabsProps) {
  return (
    <div className="flex gap-2 overflow-x-auto scrollbar-hide pb-2">
      {tabs.map((tab) => {
        const Icon = tab.icon;
        const isActive = activeTab === tab.id;
        
        return (
          <motion.button
            key={tab.id}
            whileTap={{ scale: 0.95 }}
            onClick={() => onTabChange(tab.id)}
            className={`
              flex items-center gap-2 px-4 py-2.5 rounded-full text-sm font-semibold whitespace-nowrap
              transition-all duration-200
              ${isActive
                ? 'bg-purple-600 text-white shadow-md'
                : 'bg-white dark:bg-neutral-800 text-neutral-700 dark:text-neutral-300 hover:bg-neutral-100 dark:hover:bg-neutral-700'
              }
            `}
          >
            <Icon className="w-4 h-4" />
            <span>{tab.label}</span>
          </motion.button>
        );
      })}
    </div>
  );
}

