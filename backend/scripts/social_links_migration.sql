-- UpVista Community - Social Links Migration
-- Adds social media account linking to user profiles
-- Created by: Hamza Hafeez - Founder and CEO of Upvista

-- Add social_links column (JSONB for flexible storage)
ALTER TABLE users ADD COLUMN IF NOT EXISTS social_links JSONB DEFAULT '{
  "twitter": null,
  "instagram": null,
  "facebook": null,
  "linkedin": null,
  "github": null,
  "youtube": null
}'::jsonb;

-- Add constraint to validate social link URLs
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_social_links_structure') THEN
        ALTER TABLE users ADD CONSTRAINT check_social_links_structure 
        CHECK (
            social_links ? 'twitter' AND
            social_links ? 'instagram' AND
            social_links ? 'facebook' AND
            social_links ? 'linkedin'
        );
    END IF;
END $$;

-- Migration complete
-- Run this in Supabase SQL Editor, then restart your backend

