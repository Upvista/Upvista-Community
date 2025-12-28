-- UpVista Community - Advanced Profile System Migration
-- Professional Profile Phase 3 - Advanced Features
-- Designed and architected by Hamza Hafeez - Founder and CEO of Upvista

-- Update Story field to 1000 characters
ALTER TABLE users ALTER COLUMN story TYPE VARCHAR(1000);

-- Companies Table (for company logos in experiences)
CREATE TABLE IF NOT EXISTS companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(150) NOT NULL UNIQUE,
    logo_url VARCHAR(500),
    website VARCHAR(255),
    industry VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_companies_name ON companies(name);

-- Add company_id to user_experiences
ALTER TABLE user_experiences 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_experiences_company_id ON user_experiences(company_id);

-- User Certifications Table
CREATE TABLE IF NOT EXISTS user_certifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    issuing_organization VARCHAR(150),
    issue_date DATE NOT NULL,
    expiration_date DATE,
    credential_id VARCHAR(100),
    credential_url VARCHAR(500),
    description VARCHAR(200),
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT check_cert_dates CHECK (expiration_date IS NULL OR expiration_date >= issue_date)
);

CREATE INDEX IF NOT EXISTS idx_certifications_user_id ON user_certifications(user_id);
CREATE INDEX IF NOT EXISTS idx_certifications_order ON user_certifications(user_id, display_order DESC);

-- User Skills Table (many-to-many with users)
CREATE TABLE IF NOT EXISTS user_skills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    skill_name VARCHAR(100) NOT NULL,
    proficiency_level VARCHAR(20), -- beginner, intermediate, advanced, expert
    category VARCHAR(50), -- technical, soft, language, etc.
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT check_proficiency CHECK (
        proficiency_level IS NULL OR 
        proficiency_level IN ('beginner', 'intermediate', 'advanced', 'expert')
    )
);

CREATE INDEX IF NOT EXISTS idx_skills_user_id ON user_skills(user_id);
CREATE INDEX IF NOT EXISTS idx_skills_order ON user_skills(user_id, display_order DESC);

-- User Languages Table
CREATE TABLE IF NOT EXISTS user_languages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    language_name VARCHAR(100) NOT NULL,
    proficiency_level VARCHAR(20), -- basic, conversational, fluent, native
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT check_lang_proficiency CHECK (
        proficiency_level IS NULL OR 
        proficiency_level IN ('basic', 'conversational', 'fluent', 'native')
    )
);

CREATE INDEX IF NOT EXISTS idx_languages_user_id ON user_languages(user_id);
CREATE INDEX IF NOT EXISTS idx_languages_order ON user_languages(user_id, display_order DESC);

-- User Volunteering Table
CREATE TABLE IF NOT EXISTS user_volunteering (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    organization_name VARCHAR(150) NOT NULL,
    role VARCHAR(150) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    is_current BOOLEAN DEFAULT FALSE,
    description VARCHAR(200),
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT check_volunteer_dates CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE INDEX IF NOT EXISTS idx_volunteering_user_id ON user_volunteering(user_id);
CREATE INDEX IF NOT EXISTS idx_volunteering_order ON user_volunteering(user_id, display_order DESC);

-- User Publications Table
CREATE TABLE IF NOT EXISTS user_publications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(300) NOT NULL,
    publication_type VARCHAR(50), -- article, book, paper, blog, etc.
    publisher VARCHAR(150),
    publication_date DATE,
    publication_url VARCHAR(500),
    description VARCHAR(200),
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_publications_user_id ON user_publications(user_id);
CREATE INDEX IF NOT EXISTS idx_publications_order ON user_publications(user_id, display_order DESC);

-- User Interests Table
CREATE TABLE IF NOT EXISTS user_interests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    interest_name VARCHAR(100) NOT NULL,
    category VARCHAR(50), -- hobby, professional, academic, etc.
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_interests_user_id ON user_interests(user_id);
CREATE INDEX IF NOT EXISTS idx_interests_order ON user_interests(user_id, display_order DESC);

-- User Achievements Table
CREATE TABLE IF NOT EXISTS user_achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    achievement_type VARCHAR(50), -- award, recognition, milestone, etc.
    issuing_organization VARCHAR(150),
    achievement_date DATE,
    description VARCHAR(200),
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_achievements_user_id ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_achievements_order ON user_achievements(user_id, display_order DESC);

-- Update triggers for new tables
CREATE OR REPLACE FUNCTION update_certifications_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION update_volunteering_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION update_publications_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION update_achievements_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION update_companies_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS update_user_certifications_updated_at ON user_certifications;
DROP TRIGGER IF EXISTS update_user_volunteering_updated_at ON user_volunteering;
DROP TRIGGER IF EXISTS update_user_publications_updated_at ON user_publications;
DROP TRIGGER IF EXISTS update_user_achievements_updated_at ON user_achievements;
DROP TRIGGER IF EXISTS update_companies_updated_at ON companies;

-- Create triggers
CREATE TRIGGER update_user_certifications_updated_at
    BEFORE UPDATE ON user_certifications
    FOR EACH ROW
    EXECUTE FUNCTION update_certifications_updated_at();

CREATE TRIGGER update_user_volunteering_updated_at
    BEFORE UPDATE ON user_volunteering
    FOR EACH ROW
    EXECUTE FUNCTION update_volunteering_updated_at();

CREATE TRIGGER update_user_publications_updated_at
    BEFORE UPDATE ON user_publications
    FOR EACH ROW
    EXECUTE FUNCTION update_publications_updated_at();

CREATE TRIGGER update_user_achievements_updated_at
    BEFORE UPDATE ON user_achievements
    FOR EACH ROW
    EXECUTE FUNCTION update_achievements_updated_at();

CREATE TRIGGER update_companies_updated_at
    BEFORE UPDATE ON companies
    FOR EACH ROW
    EXECUTE FUNCTION update_companies_updated_at();

-- RLS Policies
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_certifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_languages ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_volunteering ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_publications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- Companies policies (public read, authenticated write)
CREATE POLICY "Anyone can view companies" ON companies
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert companies" ON companies
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update companies" ON companies
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Certifications policies
CREATE POLICY "Users can view own certifications" ON user_certifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own certifications" ON user_certifications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own certifications" ON user_certifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own certifications" ON user_certifications
    FOR DELETE USING (auth.uid() = user_id);

-- Skills policies
CREATE POLICY "Users can view own skills" ON user_skills
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own skills" ON user_skills
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own skills" ON user_skills
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own skills" ON user_skills
    FOR DELETE USING (auth.uid() = user_id);

-- Languages policies
CREATE POLICY "Users can view own languages" ON user_languages
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own languages" ON user_languages
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own languages" ON user_languages
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own languages" ON user_languages
    FOR DELETE USING (auth.uid() = user_id);

-- Volunteering policies
CREATE POLICY "Users can view own volunteering" ON user_volunteering
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own volunteering" ON user_volunteering
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own volunteering" ON user_volunteering
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own volunteering" ON user_volunteering
    FOR DELETE USING (auth.uid() = user_id);

-- Publications policies
CREATE POLICY "Users can view own publications" ON user_publications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own publications" ON user_publications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own publications" ON user_publications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own publications" ON user_publications
    FOR DELETE USING (auth.uid() = user_id);

-- Interests policies
CREATE POLICY "Users can view own interests" ON user_interests
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own interests" ON user_interests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own interests" ON user_interests
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own interests" ON user_interests
    FOR DELETE USING (auth.uid() = user_id);

-- Achievements policies
CREATE POLICY "Users can view own achievements" ON user_achievements
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own achievements" ON user_achievements
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own achievements" ON user_achievements
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own achievements" ON user_achievements
    FOR DELETE USING (auth.uid() = user_id);
