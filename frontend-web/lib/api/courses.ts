/**
 * Courses API Client
 * Handles all course and learning material related API calls
 */

const API_BASE_URL = '/api/proxy/v1';

// ============================================
// TYPES
// ============================================

export interface Course {
  id: string;
  creator_id: string;
  title: string;
  slug: string;
  description?: string;
  short_description?: string;
  cover_image_url?: string;
  thumbnail_url?: string;
  category?: string;
  subcategory?: string;
  tags?: string[];
  difficulty_level: 'beginner' | 'intermediate' | 'advanced' | 'expert';
  language: string;
  is_free: boolean;
  price?: number;
  currency: string;
  is_public: boolean;
  requires_approval: boolean;
  estimated_duration?: number;
  total_lessons: number;
  total_modules: number;
  status: 'draft' | 'published' | 'archived' | 'pending_review';
  published_at?: string;
  last_updated_at: string;
  created_at: string;
  enrollment_count: number;
  completion_count: number;
  average_rating: number;
  review_count: number;
  view_count: number;
  creator?: User;
  is_enrolled?: boolean;
  enrollment?: CourseEnrollment;
  is_collaborator?: boolean;
  collaborator_role?: string;
}

export interface CourseModule {
  id: string;
  course_id: string;
  title: string;
  description?: string;
  order_index: number;
  is_preview: boolean;
  created_at: string;
  updated_at: string;
  lessons?: CourseLesson[];
}

export interface CourseLesson {
  id: string;
  module_id: string;
  course_id: string;
  title: string;
  description?: string;
  content?: string;
  video_url?: string;
  video_duration?: number;
  order_index: number;
  lesson_type: 'video' | 'text' | 'quiz' | 'assignment' | 'live' | 'download';
  is_preview: boolean;
  resources?: Record<string, any>;
  attachments?: string[];
  created_at: string;
  updated_at: string;
  progress?: LessonProgress;
}

export interface CourseEnrollment {
  id: string;
  course_id: string;
  user_id: string;
  enrolled_at: string;
  completed_at?: string;
  progress_percentage: number;
  payment_status: 'free' | 'pending' | 'paid' | 'refunded';
  payment_amount?: number;
  payment_currency?: string;
  payment_transaction_id?: string;
  last_accessed_at?: string;
  last_accessed_lesson_id?: string;
  user?: User;
}

export interface CourseReview {
  id: string;
  course_id: string;
  user_id: string;
  rating: number;
  title?: string;
  review_text?: string;
  is_verified_enrollment: boolean;
  is_helpful_count: number;
  created_at: string;
  updated_at: string;
  user?: User;
}

export interface LearningMaterial {
  id: string;
  creator_id: string;
  title: string;
  slug: string;
  description?: string;
  cover_image_url?: string;
  material_type: 'article' | 'video' | 'ebook' | 'template' | 'tool' | 'worksheet' | 'cheatsheet' | 'infographic';
  category?: string;
  tags?: string[];
  content?: string;
  file_url?: string;
  external_url?: string;
  is_free: boolean;
  price?: number;
  currency: string;
  is_public: boolean;
  view_count: number;
  download_count: number;
  like_count: number;
  status: 'draft' | 'published' | 'archived';
  published_at?: string;
  created_at: string;
  updated_at: string;
  creator?: User;
}

export interface LessonProgress {
  id: string;
  enrollment_id: string;
  lesson_id: string;
  user_id: string;
  course_id: string;
  is_completed: boolean;
  completion_percentage: number;
  time_spent: number;
  last_position: number;
  started_at?: string;
  completed_at?: string;
  last_accessed_at: string;
}

export interface User {
  id: string;
  username: string;
  display_name?: string;
  profile_picture?: string;
  is_verified?: boolean;
}

// Request types
export interface CreateCourseRequest {
  title: string;
  description?: string;
  short_description?: string;
  category?: string;
  subcategory?: string;
  tags?: string[];
  difficulty_level: 'beginner' | 'intermediate' | 'advanced' | 'expert';
  language?: string;
  is_free: boolean;
  price?: number;
  currency?: string;
  is_public: boolean;
  requires_approval?: boolean;
  estimated_duration?: number;
  meta_title?: string;
  meta_description?: string;
}

export interface CourseFilter {
  category?: string;
  difficulty_level?: string;
  is_free?: boolean;
  language?: string;
  search?: string;
  tags?: string[];
  sort_by?: 'newest' | 'popular' | 'rating' | 'price_asc' | 'price_desc';
  limit?: number;
  offset?: number;
}

export interface GetCoursesResponse {
  success: boolean;
  courses: Course[];
  total?: number;
  error?: string;
}

export interface GetCourseResponse {
  success: boolean;
  course: Course;
  error?: string;
}

export interface CreateCourseResponse {
  success: boolean;
  course: Course;
  error?: string;
}

export interface GetMaterialsResponse {
  success: boolean;
  materials: LearningMaterial[];
  total?: number;
  error?: string;
}

// ============================================
// API FUNCTIONS
// ============================================

export const coursesAPI = {
  // ==================== COURSES ====================

  /**
   * Get list of courses
   */
  async getCourses(filter?: CourseFilter): Promise<GetCoursesResponse> {
    const token = localStorage.getItem('token');
    const params = new URLSearchParams();
    
    if (filter) {
      if (filter.category) params.append('category', filter.category);
      if (filter.difficulty_level) params.append('difficulty_level', filter.difficulty_level);
      if (filter.is_free !== undefined) params.append('is_free', String(filter.is_free));
      if (filter.language) params.append('language', filter.language);
      if (filter.search) params.append('search', filter.search);
      if (filter.tags) params.append('tags', filter.tags.join(','));
      if (filter.sort_by) params.append('sort_by', filter.sort_by);
      if (filter.limit) params.append('limit', String(filter.limit));
      if (filter.offset) params.append('offset', String(filter.offset));
    }

    const response = await fetch(`${API_BASE_URL}/courses?${params.toString()}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        ...(token && { Authorization: `Bearer ${token}` }),
      },
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: response.statusText }));
      throw new Error(error.error || error.message || `Failed to fetch courses: ${response.statusText}`);
    }

    return response.json();
  },

  /**
   * Get course by ID
   */
  async getCourseById(id: string): Promise<GetCourseResponse> {
    const token = localStorage.getItem('token');
    const response = await fetch(`${API_BASE_URL}/courses/${id}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        ...(token && { Authorization: `Bearer ${token}` }),
      },
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: response.statusText }));
      throw new Error(error.error || error.message || `Failed to fetch course: ${response.statusText}`);
    }

    return response.json();
  },

  /**
   * Get course by slug
   */
  async getCourseBySlug(slug: string): Promise<GetCourseResponse> {
    const token = localStorage.getItem('token');
    const response = await fetch(`${API_BASE_URL}/courses/slug/${slug}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        ...(token && { Authorization: `Bearer ${token}` }),
      },
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: response.statusText }));
      throw new Error(error.error || error.message || `Failed to fetch course: ${response.statusText}`);
    }

    return response.json();
  },

  /**
   * Create a new course
   */
  async createCourse(data: CreateCourseRequest): Promise<CreateCourseResponse> {
    const token = localStorage.getItem('token');
    if (!token) {
      throw new Error('Authentication required');
    }

    const response = await fetch(`${API_BASE_URL}/courses`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: response.statusText }));
      throw new Error(error.error || error.message || `Failed to create course: ${response.statusText}`);
    }

    return response.json();
  },

  /**
   * Enroll in a course
   */
  async enrollInCourse(courseId: string): Promise<{ success: boolean; enrollment: CourseEnrollment; error?: string }> {
    const token = localStorage.getItem('token');
    if (!token) {
      throw new Error('Authentication required');
    }

    const response = await fetch(`${API_BASE_URL}/courses/${courseId}/enroll`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: response.statusText }));
      throw new Error(error.error || error.message || `Failed to enroll: ${response.statusText}`);
    }

    return response.json();
  },

  // ==================== LEARNING MATERIALS ====================

  /**
   * Get list of learning materials
   */
  async getMaterials(filter?: CourseFilter): Promise<GetMaterialsResponse> {
    const token = localStorage.getItem('token');
    const params = new URLSearchParams();
    
    if (filter) {
      if (filter.category) params.append('category', filter.category);
      if (filter.search) params.append('search', filter.search);
      if (filter.tags) params.append('tags', filter.tags.join(','));
      if (filter.sort_by) params.append('sort_by', filter.sort_by);
      if (filter.limit) params.append('limit', String(filter.limit));
      if (filter.offset) params.append('offset', String(filter.offset));
    }

    const response = await fetch(`${API_BASE_URL}/learning-materials?${params.toString()}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        ...(token && { Authorization: `Bearer ${token}` }),
      },
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: response.statusText }));
      throw new Error(error.error || error.message || `Failed to fetch materials: ${response.statusText}`);
    }

    return response.json();
  },
};
