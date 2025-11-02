-- UpVista Community - Experience & Education System Migration
-- Professional Profile Phase 2
-- Designed and architected by Hamza Hafeez - Founder and CEO of Upvista

-- User Experiences Table
CREATE TABLE IF NOT EXISTS user_experiences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Company and Role
    company_name VARCHAR(150) NOT NULL,
    title VARCHAR(150) NOT NULL,
    employment_type VARCHAR(30), -- Full-time, Part-time, Contract, Internship, Freelance
    
    -- Duration
    start_date DATE NOT NULL,
    end_date DATE,
    is_current BOOLEAN DEFAULT FALSE,
    
    -- Description (max 200 chars)
    description VARCHAR(200),
    
    -- Privacy
    is_public BOOLEAN DEFAULT TRUE, -- If false, only visible to recruiters
    
    -- Ordering
    display_order INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT check_dates CHECK (end_date IS NULL OR end_date >= start_date),
    CONSTRAINT check_employment_type CHECK (
        employment_type IS NULL OR 
        employment_type IN ('full-time', 'part-time', 'contract', 'internship', 'freelance', 'self-employed')
    )
);

-- Indexes for experiences
CREATE INDEX IF NOT EXISTS idx_experiences_user_id ON user_experiences(user_id);
CREATE INDEX IF NOT EXISTS idx_experiences_current ON user_experiences(is_current);
CREATE INDEX IF NOT EXISTS idx_experiences_public ON user_experiences(is_public);
CREATE INDEX IF NOT EXISTS idx_experiences_order ON user_experiences(user_id, display_order DESC);

-- User Education Table
CREATE TABLE IF NOT EXISTS user_education (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- School and Degree
    school_name VARCHAR(150) NOT NULL,
    degree VARCHAR(150), -- e.g., Bachelor's, Master's, PhD, Certificate
    field_of_study VARCHAR(150), -- e.g., Computer Science, Business Administration
    
    -- Duration
    start_date DATE NOT NULL,
    end_date DATE,
    is_current BOOLEAN DEFAULT FALSE,
    
    -- Description (max 200 chars)
    description VARCHAR(200),
    
    -- Ordering
    display_order INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT check_edu_dates CHECK (end_date IS NULL OR end_date >= start_date)
);

-- Indexes for education
CREATE INDEX IF NOT EXISTS idx_education_user_id ON user_education(user_id);
CREATE INDEX IF NOT EXISTS idx_education_current ON user_education(is_current);
CREATE INDEX IF NOT EXISTS idx_education_order ON user_education(user_id, display_order DESC);

-- Update trigger function for experiences
CREATE OR REPLACE FUNCTION update_experiences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Update trigger function for education
CREATE OR REPLACE FUNCTION update_education_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop existing triggers if they exist (for idempotency)
DROP TRIGGER IF EXISTS update_user_experiences_updated_at ON user_experiences;
DROP TRIGGER IF EXISTS update_user_education_updated_at ON user_education;

-- Create triggers
CREATE TRIGGER update_user_experiences_updated_at
    BEFORE UPDATE ON user_experiences
    FOR EACH ROW
    EXECUTE FUNCTION update_experiences_updated_at();

CREATE TRIGGER update_user_education_updated_at
    BEFORE UPDATE ON user_education
    FOR EACH ROW
    EXECUTE FUNCTION update_education_updated_at();

-- RLS Policies
ALTER TABLE user_experiences ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_education ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own experiences" ON user_experiences;
DROP POLICY IF EXISTS "Users can insert own experiences" ON user_experiences;
DROP POLICY IF EXISTS "Users can update own experiences" ON user_experiences;
DROP POLICY IF EXISTS "Users can delete own experiences" ON user_experiences;

DROP POLICY IF EXISTS "Users can view own education" ON user_education;
DROP POLICY IF EXISTS "Users can insert own education" ON user_education;
DROP POLICY IF EXISTS "Users can update own education" ON user_education;
DROP POLICY IF EXISTS "Users can delete own education" ON user_education;

-- Experiences policies
CREATE POLICY "Users can view own experiences" ON user_experiences
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own experiences" ON user_experiences
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own experiences" ON user_experiences
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own experiences" ON user_experiences
    FOR DELETE USING (auth.uid() = user_id);

-- Education policies
CREATE POLICY "Users can view own education" ON user_education
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own education" ON user_education
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own education" ON user_education
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own education" ON user_education
    FOR DELETE USING (auth.uid() = user_id);