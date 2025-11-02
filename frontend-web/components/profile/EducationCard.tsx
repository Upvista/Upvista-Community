'use client';

/**
 * Education Card Component
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * LinkedIn/Wantedly-style education display
 */

import { GraduationCap, Edit3, Trash2 } from 'lucide-react';

interface Education {
  id: string;
  school_name: string;
  degree?: string | null;
  field_of_study?: string | null;
  start_date: string;
  end_date?: string | null;
  is_current: boolean;
  description?: string | null;
}

interface EducationCardProps {
  education: Education;
  isOwnProfile: boolean;
  onEdit?: () => void;
  onDelete?: () => void;
}

export default function EducationCard({ education, isOwnProfile, onEdit, onDelete }: EducationCardProps) {
  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', { month: 'short', year: 'numeric' });
  };

  const getDuration = () => {
    const start = formatDate(education.start_date);
    const end = education.is_current ? 'Present' : education.end_date ? formatDate(education.end_date) : 'Present';
    return `${start} - ${end}`;
  };

  return (
    <div className="flex gap-4 group">
      {/* Icon */}
      <div className="flex-shrink-0">
        <div className="w-12 h-12 rounded-lg bg-neutral-100 dark:bg-neutral-800 flex items-center justify-center">
          <GraduationCap className="w-6 h-6 text-neutral-600 dark:text-neutral-400" />
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 min-w-0">
        <div className="flex items-start justify-between gap-2 mb-1">
          <div className="flex-1 min-w-0">
            <h4 className="text-base font-semibold text-neutral-900 dark:text-neutral-50">
              {education.school_name}
            </h4>
            <p className="text-sm text-neutral-700 dark:text-neutral-300">
              {education.degree && education.field_of_study ? (
                `${education.degree} in ${education.field_of_study}`
              ) : education.degree ? (
                education.degree
              ) : education.field_of_study ? (
                education.field_of_study
              ) : (
                'Student'
              )}
            </p>
          </div>

          {/* Action Buttons - Only for own profile */}
          {isOwnProfile && (
            <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
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

        {education.description && (
          <p className="text-sm text-neutral-700 dark:text-neutral-300 whitespace-pre-wrap">
            {education.description}
          </p>
        )}
      </div>
    </div>
  );
}

