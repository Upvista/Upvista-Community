-- Learning Platform Migration
-- Created by: Hamza Hafeez - Founder & CEO of Asteria
-- Complete learning platform with courses, materials, collaborations, and enrollments

-- ============================================
-- 1. COURSES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Basic Information
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL, -- URL-friendly identifier
    description TEXT,
    short_description VARCHAR(500), -- Brief summary for cards
    cover_image_url TEXT,
    thumbnail_url TEXT,
    
    -- Course Details
    category VARCHAR(50), -- 'programming', 'design', 'business', 'marketing', 'data-science', 'language', 'music', 'photography', etc.
    subcategory VARCHAR(50),
    tags TEXT[], -- Array of tags
    difficulty_level VARCHAR(20) DEFAULT 'beginner' CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced', 'expert')),
    language VARCHAR(10) DEFAULT 'en', -- Course language
    
    -- Pricing & Access
    is_free BOOLEAN DEFAULT TRUE,
    price DECIMAL(10, 2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'USD',
    is_public BOOLEAN DEFAULT TRUE,
    requires_approval BOOLEAN DEFAULT FALSE, -- For premium/featured courses
    
    -- Course Structure
    estimated_duration INTEGER, -- Total minutes
    total_lessons INTEGER DEFAULT 0,
    total_modules INTEGER DEFAULT 0,
    
    -- Metadata
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived', 'pending_review')),
    published_at TIMESTAMP,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Statistics (denormalized for performance)
    enrollment_count INTEGER DEFAULT 0,
    completion_count INTEGER DEFAULT 0,
    average_rating DECIMAL(3, 2) DEFAULT 0, -- 0.00 to 5.00
    review_count INTEGER DEFAULT 0,
    view_count INTEGER DEFAULT 0,
    
    -- SEO & Discovery
    meta_title VARCHAR(255),
    meta_description TEXT,
    
    CONSTRAINT courses_title_length CHECK (char_length(title) >= 3 AND char_length(title) <= 255),
    CONSTRAINT courses_slug_format CHECK (slug ~ '^[a-z0-9-]+$')
);

-- ============================================
-- 2. COURSE MODULES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS course_modules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    
    title VARCHAR(255) NOT NULL,
    description TEXT,
    order_index INTEGER NOT NULL, -- Order within course
    is_preview BOOLEAN DEFAULT FALSE, -- Free preview module
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT course_modules_order_unique UNIQUE (course_id, order_index)
);

-- ============================================
-- 3. COURSE LESSONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS course_lessons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID NOT NULL REFERENCES course_modules(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE, -- Denormalized for easier queries
    
    title VARCHAR(255) NOT NULL,
    description TEXT,
    content TEXT, -- Main lesson content (markdown/HTML)
    video_url TEXT, -- Video lesson URL
    video_duration INTEGER, -- Duration in seconds
    order_index INTEGER NOT NULL, -- Order within module
    
    lesson_type VARCHAR(20) DEFAULT 'video' CHECK (lesson_type IN ('video', 'text', 'quiz', 'assignment', 'live', 'download')),
    is_preview BOOLEAN DEFAULT FALSE, -- Free preview lesson
    
    resources JSONB, -- Additional resources (files, links, etc.)
    attachments TEXT[], -- Array of attachment URLs
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT course_lessons_order_unique UNIQUE (module_id, order_index)
);

-- ============================================
-- 4. COURSE ENROLLMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS course_enrollments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    progress_percentage DECIMAL(5, 2) DEFAULT 0, -- 0.00 to 100.00
    
    -- Payment info (if paid course)
    payment_status VARCHAR(20) DEFAULT 'free' CHECK (payment_status IN ('free', 'pending', 'paid', 'refunded')),
    payment_amount DECIMAL(10, 2),
    payment_currency VARCHAR(3),
    payment_transaction_id VARCHAR(255),
    
    last_accessed_at TIMESTAMP,
    last_accessed_lesson_id UUID REFERENCES course_lessons(id),
    
    CONSTRAINT course_enrollments_unique UNIQUE (course_id, user_id)
);

-- ============================================
-- 5. COURSE COLLABORATORS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS course_collaborators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    role VARCHAR(20) DEFAULT 'instructor' CHECK (role IN ('instructor', 'co-instructor', 'contributor', 'reviewer', 'moderator')),
    permissions TEXT[], -- Array of permissions: ['edit', 'publish', 'manage_students', 'view_analytics']
    
    invited_by UUID REFERENCES users(id),
    invited_at TIMESTAMP,
    accepted_at TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'removed')),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT course_collaborators_unique UNIQUE (course_id, user_id)
);

-- ============================================
-- 6. COURSE REVIEWS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS course_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(255),
    review_text TEXT,
    
    is_verified_enrollment BOOLEAN DEFAULT FALSE, -- User actually enrolled
    is_helpful_count INTEGER DEFAULT 0, -- Number of "helpful" votes
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT course_reviews_unique UNIQUE (course_id, user_id)
);

-- ============================================
-- 7. LEARNING MATERIALS TABLE (Standalone resources)
-- ============================================
CREATE TABLE IF NOT EXISTS learning_materials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    cover_image_url TEXT,
    
    material_type VARCHAR(20) DEFAULT 'article' CHECK (material_type IN ('article', 'video', 'ebook', 'template', 'tool', 'worksheet', 'cheatsheet', 'infographic')),
    category VARCHAR(50),
    tags TEXT[],
    
    content TEXT, -- Main content
    file_url TEXT, -- For downloadable materials
    external_url TEXT, -- For external resources
    
    is_free BOOLEAN DEFAULT TRUE,
    price DECIMAL(10, 2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'USD',
    is_public BOOLEAN DEFAULT TRUE,
    
    view_count INTEGER DEFAULT 0,
    download_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    published_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 8. LESSON PROGRESS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS lesson_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enrollment_id UUID NOT NULL REFERENCES course_enrollments(id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES course_lessons(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    
    is_completed BOOLEAN DEFAULT FALSE,
    completion_percentage DECIMAL(5, 2) DEFAULT 0, -- For video lessons, track watch percentage
    time_spent INTEGER DEFAULT 0, -- Time spent in seconds
    last_position INTEGER DEFAULT 0, -- Last video position in seconds
    
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    last_accessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT lesson_progress_unique UNIQUE (enrollment_id, lesson_id)
);

-- ============================================
-- 9. COURSE CERTIFICATES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS course_certificates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enrollment_id UUID NOT NULL REFERENCES course_enrollments(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    certificate_number VARCHAR(100) UNIQUE NOT NULL,
    certificate_url TEXT, -- URL to generated certificate PDF/image
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT course_certificates_unique UNIQUE (enrollment_id)
);

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_courses_creator ON courses(creator_id);
CREATE INDEX IF NOT EXISTS idx_courses_status ON courses(status);
CREATE INDEX IF NOT EXISTS idx_courses_category ON courses(category);
CREATE INDEX IF NOT EXISTS idx_courses_published ON courses(published_at) WHERE status = 'published';
CREATE INDEX IF NOT EXISTS idx_courses_slug ON courses(slug);
CREATE INDEX IF NOT EXISTS idx_courses_search ON courses USING gin(to_tsvector('english', title || ' ' || COALESCE(description, '')));

CREATE INDEX IF NOT EXISTS idx_course_modules_course ON course_modules(course_id);
CREATE INDEX IF NOT EXISTS idx_course_lessons_module ON course_lessons(module_id);
CREATE INDEX IF NOT EXISTS idx_course_lessons_course ON course_lessons(course_id);

CREATE INDEX IF NOT EXISTS idx_enrollments_course ON course_enrollments(course_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_user ON course_enrollments(user_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_progress ON course_enrollments(course_id, user_id, progress_percentage);

CREATE INDEX IF NOT EXISTS idx_collaborators_course ON course_collaborators(course_id);
CREATE INDEX IF NOT EXISTS idx_collaborators_user ON course_collaborators(user_id);
CREATE INDEX IF NOT EXISTS idx_collaborators_status ON course_collaborators(status);

CREATE INDEX IF NOT EXISTS idx_reviews_course ON course_reviews(course_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user ON course_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON course_reviews(course_id, rating);

CREATE INDEX IF NOT EXISTS idx_materials_creator ON learning_materials(creator_id);
CREATE INDEX IF NOT EXISTS idx_materials_type ON learning_materials(material_type);
CREATE INDEX IF NOT EXISTS idx_materials_category ON learning_materials(category);
CREATE INDEX IF NOT EXISTS idx_materials_status ON learning_materials(status);

CREATE INDEX IF NOT EXISTS idx_progress_enrollment ON lesson_progress(enrollment_id);
CREATE INDEX IF NOT EXISTS idx_progress_lesson ON lesson_progress(lesson_id);
CREATE INDEX IF NOT EXISTS idx_progress_user ON lesson_progress(user_id);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Function to update course statistics
CREATE OR REPLACE FUNCTION update_course_statistics()
RETURNS TRIGGER AS $$
BEGIN
    -- Update enrollment count
    UPDATE courses
    SET enrollment_count = (
        SELECT COUNT(*) FROM course_enrollments WHERE course_id = NEW.course_id
    )
    WHERE id = NEW.course_id;
    
    -- Update completion count
    UPDATE courses
    SET completion_count = (
        SELECT COUNT(*) FROM course_enrollments 
        WHERE course_id = NEW.course_id AND completed_at IS NOT NULL
    )
    WHERE id = NEW.course_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_course_statistics
AFTER INSERT OR UPDATE OR DELETE ON course_enrollments
FOR EACH ROW EXECUTE FUNCTION update_course_statistics();

-- Function to update course rating
CREATE OR REPLACE FUNCTION update_course_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE courses
    SET 
        average_rating = (
            SELECT COALESCE(AVG(rating), 0)::DECIMAL(3, 2)
            FROM course_reviews
            WHERE course_id = NEW.course_id
        ),
        review_count = (
            SELECT COUNT(*) FROM course_reviews WHERE course_id = NEW.course_id
        )
    WHERE id = NEW.course_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_course_rating
AFTER INSERT OR UPDATE OR DELETE ON course_reviews
FOR EACH ROW EXECUTE FUNCTION update_course_rating();

-- Function to update course lesson/module counts
CREATE OR REPLACE FUNCTION update_course_structure_counts()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE courses
    SET 
        total_modules = (
            SELECT COUNT(*) FROM course_modules WHERE course_id = NEW.course_id
        ),
        total_lessons = (
            SELECT COUNT(*) FROM course_lessons WHERE course_id = NEW.course_id
        )
    WHERE id = NEW.course_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_course_structure_counts_modules
AFTER INSERT OR UPDATE OR DELETE ON course_modules
FOR EACH ROW EXECUTE FUNCTION update_course_structure_counts();

CREATE TRIGGER trigger_update_course_structure_counts_lessons
AFTER INSERT OR UPDATE OR DELETE ON course_lessons
FOR EACH ROW EXECUTE FUNCTION update_course_structure_counts();

-- Function to update enrollment progress
CREATE OR REPLACE FUNCTION update_enrollment_progress()
RETURNS TRIGGER AS $$
DECLARE
    total_lessons INTEGER;
    completed_lessons INTEGER;
    progress_pct DECIMAL(5, 2);
BEGIN
    SELECT COUNT(*) INTO total_lessons
    FROM course_lessons
    WHERE course_id = NEW.course_id;
    
    SELECT COUNT(*) INTO completed_lessons
    FROM lesson_progress
    WHERE enrollment_id = NEW.enrollment_id AND is_completed = TRUE;
    
    IF total_lessons > 0 THEN
        progress_pct := (completed_lessons::DECIMAL / total_lessons::DECIMAL) * 100;
    ELSE
        progress_pct := 0;
    END IF;
    
    UPDATE course_enrollments
    SET progress_percentage = progress_pct
    WHERE id = NEW.enrollment_id;
    
    -- Mark enrollment as completed if all lessons are done
    IF completed_lessons = total_lessons AND total_lessons > 0 THEN
        UPDATE course_enrollments
        SET completed_at = CURRENT_TIMESTAMP
        WHERE id = NEW.enrollment_id AND completed_at IS NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_enrollment_progress
AFTER INSERT OR UPDATE ON lesson_progress
FOR EACH ROW EXECUTE FUNCTION update_enrollment_progress();

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_collaborators ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE learning_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_certificates ENABLE ROW LEVEL SECURITY;

-- Courses: Public can view published courses, creators can manage their own
CREATE POLICY courses_select_public ON courses
    FOR SELECT
    USING (status = 'published' AND is_public = TRUE);

CREATE POLICY courses_select_own ON courses
    FOR SELECT
    USING (creator_id = auth.uid());

CREATE POLICY courses_insert_own ON courses
    FOR INSERT
    WITH CHECK (creator_id = auth.uid());

CREATE POLICY courses_update_own ON courses
    FOR UPDATE
    USING (creator_id = auth.uid());

CREATE POLICY courses_delete_own ON courses
    FOR DELETE
    USING (creator_id = auth.uid());

-- Course Modules: Public can view for published courses, creators can manage
CREATE POLICY course_modules_select_public ON course_modules
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM courses
            WHERE courses.id = course_modules.course_id
            AND courses.status = 'published'
            AND courses.is_public = TRUE
        )
    );

CREATE POLICY course_modules_select_own ON course_modules
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM courses
            WHERE courses.id = course_modules.course_id
            AND courses.creator_id = auth.uid()
        )
    );

CREATE POLICY course_modules_manage_own ON course_modules
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM courses
            WHERE courses.id = course_modules.course_id
            AND courses.creator_id = auth.uid()
        )
    );

-- Course Lessons: Similar to modules
CREATE POLICY course_lessons_select_public ON course_lessons
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM courses
            WHERE courses.id = course_lessons.course_id
            AND courses.status = 'published'
            AND courses.is_public = TRUE
        )
    );

CREATE POLICY course_lessons_select_own ON course_lessons
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM courses
            WHERE courses.id = course_lessons.course_id
            AND courses.creator_id = auth.uid()
        )
    );

CREATE POLICY course_lessons_manage_own ON course_lessons
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM courses
            WHERE courses.id = course_lessons.course_id
            AND courses.creator_id = auth.uid()
        )
    );

-- Enrollments: Users can view their own enrollments
CREATE POLICY enrollments_select_own ON course_enrollments
    FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY enrollments_insert_own ON course_enrollments
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY enrollments_update_own ON course_enrollments
    FOR UPDATE
    USING (user_id = auth.uid());

-- Collaborators: Can view/manage if they're collaborators or course creator
CREATE POLICY collaborators_select_own ON course_collaborators
    FOR SELECT
    USING (
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM courses
            WHERE courses.id = course_collaborators.course_id
            AND courses.creator_id = auth.uid()
        )
    );

CREATE POLICY collaborators_manage_own ON course_collaborators
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM courses
            WHERE courses.id = course_collaborators.course_id
            AND courses.creator_id = auth.uid()
        )
    );

-- Reviews: Public can view, users can create/update their own
CREATE POLICY reviews_select_public ON course_reviews
    FOR SELECT
    USING (TRUE);

CREATE POLICY reviews_insert_own ON course_reviews
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY reviews_update_own ON course_reviews
    FOR UPDATE
    USING (user_id = auth.uid());

-- Learning Materials: Similar to courses
CREATE POLICY materials_select_public ON learning_materials
    FOR SELECT
    USING (status = 'published' AND is_public = TRUE);

CREATE POLICY materials_select_own ON learning_materials
    FOR SELECT
    USING (creator_id = auth.uid());

CREATE POLICY materials_manage_own ON learning_materials
    FOR ALL
    USING (creator_id = auth.uid());

-- Lesson Progress: Users can view/manage their own progress
CREATE POLICY progress_select_own ON lesson_progress
    FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY progress_manage_own ON lesson_progress
    FOR ALL
    USING (user_id = auth.uid());

-- Certificates: Users can view their own certificates
CREATE POLICY certificates_select_own ON course_certificates
    FOR SELECT
    USING (user_id = auth.uid());
