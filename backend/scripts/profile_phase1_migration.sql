-- UpVista Community - Profile System Phase 1 Migration
-- Run this script in your Supabase SQL editor
-- Designed and architected by Hamza Hafeez - Founder and CEO of Upvista

-- Add profile fields
ALTER TABLE users ADD COLUMN IF NOT EXISTS bio VARCHAR(150);
ALTER TABLE users ADD COLUMN IF NOT EXISTS location VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS gender VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS gender_custom VARCHAR(50);
ALTER TABLE users ADD COLUMN IF NOT EXISTS website VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE;

-- Add privacy settings
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_privacy VARCHAR(20) DEFAULT 'public';
-- Options: 'public', 'private', 'connections'

-- Add field visibility settings (JSONB for flexible field-level control)
ALTER TABLE users ADD COLUMN IF NOT EXISTS field_visibility JSONB DEFAULT '{
  "location": true,
  "gender": true,
  "age": true,
  "website": true,
  "joined_date": true,
  "email": false
}'::jsonb;

-- Add About section fields
ALTER TABLE users ADD COLUMN IF NOT EXISTS story VARCHAR(800);
ALTER TABLE users ADD COLUMN IF NOT EXISTS ambition VARCHAR(200);

-- Add stats (denormalized for performance)
ALTER TABLE users ADD COLUMN IF NOT EXISTS posts_count INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS projects_count INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS followers_count INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS following_count INTEGER DEFAULT 0;

-- Add constraints (use DO blocks to handle existing constraints)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_bio_length') THEN
        ALTER TABLE users ADD CONSTRAINT check_bio_length CHECK (LENGTH(bio) <= 150);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_story_length') THEN
        ALTER TABLE users ADD CONSTRAINT check_story_length CHECK (LENGTH(story) <= 800);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_ambition_length') THEN
        ALTER TABLE users ADD CONSTRAINT check_ambition_length CHECK (LENGTH(ambition) <= 200);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_profile_privacy') THEN
        ALTER TABLE users ADD CONSTRAINT check_profile_privacy CHECK (profile_privacy IN ('public', 'private', 'connections'));
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_gender') THEN
        ALTER TABLE users ADD CONSTRAINT check_gender CHECK (gender IN ('male', 'female', 'non-binary', 'prefer-not-to-say', 'custom') OR gender IS NULL);
    END IF;
END $$;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_profile_privacy ON users(profile_privacy);
CREATE INDEX IF NOT EXISTS idx_users_is_verified ON users(is_verified);