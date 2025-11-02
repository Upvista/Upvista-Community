'use client';

/**
 * Experience Card Component
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * LinkedIn/Wantedly-style experience display
 */

import { Briefcase, Edit3, Trash2, Lock } from 'lucide-react';

interface Experience {
  id: string;
  company_name: string;
  title: string;
  employment_type?: string | null;
  start_date: string;
  end_date?: string | null;
  is_current: boolean;
  description?: string | null;
  is_public: boolean;
}

interface ExperienceCardProps {
  experience: Experience;
  isOwnProfile: boolean;
  onEdit?: () => void;
  onDelete?: () => void;
}

export default function ExperienceCard({ experience, isOwnProfile, onEdit, onDelete }: ExperienceCardProps) {
  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', { month: 'short', year: 'numeric' });
  };

  const getDuration = () => {
    const start = formatDate(experience.start_date);
    const end = experience.is_current ? 'Present' : experience.end_date ? formatDate(experience.end_date) : 'Present';
    return `${start} - ${end}`;
  };

  const formatEmploymentType = (type: string | null | undefined) => {
    if (!type) return null;
    const types: {[key: string]: string} = {
      'full-time': 'Full-time',
      'part-time': 'Part-time',
      'contract': 'Contract',
      'internship': 'Internship',
      'freelance': 'Freelance',
      'self-employed': 'Self-employed',
    };
    return types[type] || type;
  };

  return (
    <div className="flex gap-4 group">
      {/* Icon */}
      <div className="flex-shrink-0">
        <div className="w-12 h-12 rounded-lg bg-neutral-100 dark:bg-neutral-800 flex items-center justify-center">
          <Briefcase className="w-6 h-6 text-neutral-600 dark:text-neutral-400" />
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 min-w-0">
        <div className="flex items-start justify-between gap-2 mb-1">
          <div className="flex-1 min-w-0">
            <h4 className="text-base font-semibold text-neutral-900 dark:text-neutral-50">
              {experience.title}
            </h4>
            <p className="text-sm text-neutral-700 dark:text-neutral-300">
              {experience.company_name}
              {experience.employment_type && (
                <span className="text-neutral-500 dark:text-neutral-400">
                  {' · '}{formatEmploymentType(experience.employment_type)}
                </span>
              )}
            </p>
          </div>

          {/* Action Buttons - Only for own profile */}
          {isOwnProfile && (
            <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
              {!experience.is_public && (
                <div className="p-1.5 text-neutral-400" title="Recruiter Only">
                  <Lock className="w-4 h-4" />
                </div>
              )}
              <button
                onClick={onEdit}
                className="p-1.5 hover:bg-neutral-100 dark:hover:bg-neutral-800 rounded-lg transition-colors text-neutral-600 dark:text-neutral-400 hover:text-brand-purple-600"
              >
                <Edit3 className="w-4 h-4" />
              </button>
              <button
                onClick={onDelete}
                className="p-1.5 hover:bg-neutral-100 dark:hover:bg-neutral-800 rounded-lg transition-colors text-neutral-600 dark:text-neutral-400 hover:text-red-600"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          )}
        </div>

        <p className="text-sm text-neutral-500 dark:text-neutral-400 mb-2">
          {getDuration()}
        </p>

        {experience.description && (
          <p className="text-sm text-neutral-700 dark:text-neutral-300 whitespace-pre-wrap">
            {experience.description}
          </p>
        )}
      </div>
    </div>
  );
}

