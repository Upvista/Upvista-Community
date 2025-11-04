-- UpVista Community - Relationships System Migration
-- Follow/Connect/Collaborate with Anti-Spam Protection
-- Designed and architected by Hamza Hafeez - Founder and CEO of Upvista

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Relationship Types Enum
DO $$ BEGIN
    CREATE TYPE relationship_type AS ENUM ('following', 'connected', 'collaborating');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Relationship Status Enum
DO $$ BEGIN
    CREATE TYPE relationship_status AS ENUM ('active', 'pending', 'rejected', 'blocked');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- User Relationships Table
CREATE TABLE IF NOT EXISTS user_relationships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    from_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    to_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Relationship tier
    relationship_type relationship_type NOT NULL,
    status relationship_status DEFAULT 'active',
    
    -- For pending requests
    request_message TEXT, -- Optional message when requesting connect/collab
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    accepted_at TIMESTAMP, -- When request was accepted
    
    -- Prevent duplicate relationships
    CONSTRAINT unique_relationship UNIQUE(from_user_id, to_user_id, relationship_type),
    
    -- Can't follow yourself
    CONSTRAINT no_self_relationship CHECK(from_user_id != to_user_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_relationships_from ON user_relationships(from_user_id);
CREATE INDEX IF NOT EXISTS idx_relationships_to ON user_relationships(to_user_id);
CREATE INDEX IF NOT EXISTS idx_relationships_type ON user_relationships(relationship_type);
CREATE INDEX IF NOT EXISTS idx_relationships_status ON user_relationships(status);
CREATE INDEX IF NOT EXISTS idx_relationships_from_to ON user_relationships(from_user_id, to_user_id);
CREATE INDEX IF NOT EXISTS idx_relationships_to_type_status ON user_relationships(to_user_id, relationship_type, status);

-- Relationship Rate Limits Table
CREATE TABLE IF NOT EXISTS relationship_rate_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action_type VARCHAR(20) NOT NULL, -- 'follow', 'connect', 'collaborate'
    action_count INT DEFAULT 0,
    window_start TIMESTAMP DEFAULT NOW(),
    cooldown_multiplier DECIMAL(3,1) DEFAULT 1.0, -- 1.0 = 24hrs, 2.0 = 48hrs
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- One record per user per action type
    CONSTRAINT unique_user_action UNIQUE(user_id, action_type)
);

CREATE INDEX IF NOT EXISTS idx_rate_limits_user ON relationship_rate_limits(user_id);
CREATE INDEX IF NOT EXISTS idx_rate_limits_window ON relationship_rate_limits(window_start);

-- Spam Flags Table
CREATE TABLE IF NOT EXISTS spam_flags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    detection_type VARCHAR(50) NOT NULL, -- 'rapid_follow_unfollow', 'excessive_requests', etc.
    flag_count INT DEFAULT 1,
    last_flagged_at TIMESTAMP DEFAULT NOW(),
    requires_review BOOLEAN DEFAULT FALSE,
    reviewed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT unique_user_detection UNIQUE(user_id, detection_type)
);

CREATE INDEX IF NOT EXISTS idx_spam_flags_user ON spam_flags(user_id);
CREATE INDEX IF NOT EXISTS idx_spam_flags_review ON spam_flags(requires_review);

-- Add trust level to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS account_trust_level INT DEFAULT 0;
CREATE INDEX IF NOT EXISTS idx_users_trust_level ON users(account_trust_level);

-- Update trigger function for relationships
CREATE OR REPLACE FUNCTION update_relationships_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Update trigger function for rate limits
CREATE OR REPLACE FUNCTION update_rate_limits_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS update_user_relationships_updated_at ON user_relationships;
DROP TRIGGER IF EXISTS update_relationship_rate_limits_updated_at ON relationship_rate_limits;

-- Create triggers
CREATE TRIGGER update_user_relationships_updated_at
    BEFORE UPDATE ON user_relationships
    FOR EACH ROW
    EXECUTE FUNCTION update_relationships_updated_at();

CREATE TRIGGER update_relationship_rate_limits_updated_at
    BEFORE UPDATE ON relationship_rate_limits
    FOR EACH ROW
    EXECUTE FUNCTION update_rate_limits_updated_at();

-- RLS Policies
ALTER TABLE user_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE relationship_rate_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE spam_flags ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view relationships they're part of" ON user_relationships;
DROP POLICY IF EXISTS "Users can create relationships" ON user_relationships;
DROP POLICY IF EXISTS "Users can update their own relationships" ON user_relationships;
DROP POLICY IF EXISTS "Users can delete their own relationships" ON user_relationships;

DROP POLICY IF EXISTS "Users can view own rate limits" ON relationship_rate_limits;
DROP POLICY IF EXISTS "Users can view own spam flags" ON spam_flags;

-- Relationships policies
CREATE POLICY "Users can view relationships they're part of" ON user_relationships
    FOR SELECT USING (auth.uid() = from_user_id OR auth.uid() = to_user_id);

CREATE POLICY "Users can create relationships" ON user_relationships
    FOR INSERT WITH CHECK (auth.uid() = from_user_id);

CREATE POLICY "Users can update their own relationships" ON user_relationships
    FOR UPDATE USING (auth.uid() = from_user_id OR auth.uid() = to_user_id);

CREATE POLICY "Users can delete their own relationships" ON user_relationships
    FOR DELETE USING (auth.uid() = from_user_id);

-- Rate limits policies
CREATE POLICY "Users can view own rate limits" ON relationship_rate_limits
    FOR SELECT USING (auth.uid() = user_id);

-- Spam flags policies
CREATE POLICY "Users can view own spam flags" ON spam_flags
    FOR SELECT USING (auth.uid() = user_id);

-- Helper function to calculate trust level
CREATE OR REPLACE FUNCTION calculate_trust_level(user_id_param UUID)
RETURNS INT AS $$
DECLARE
    account_age_days INT;
    is_verified_user BOOLEAN;
    is_email_verified_user BOOLEAN;
    follower_count_val INT;
    trust_level INT := 0;
BEGIN
    SELECT 
        EXTRACT(DAY FROM NOW() - created_at)::INT,
        is_verified,
        is_email_verified,
        followers_count
    INTO 
        account_age_days,
        is_verified_user,
        is_email_verified_user,
        follower_count_val
    FROM users
    WHERE id = user_id_param;
    
    -- Base level
    trust_level := 0;
    
    -- Level 1: Verified account
    IF is_verified_user THEN
        trust_level := 1;
    -- Level 1: Old account with verified email
    ELSIF account_age_days >= 30 AND is_email_verified_user THEN
        trust_level := 1;
    -- Level 1: Popular account
    ELSIF follower_count_val >= 100 THEN
        trust_level := 1;
    END IF;
    
    RETURN trust_level;
END;
$$ LANGUAGE plpgsql;

-- Comments for documentation
COMMENT ON TABLE user_relationships IS 'Stores all user relationships: following, connected, collaborating';
COMMENT ON TABLE relationship_rate_limits IS 'Tracks rate limits for relationship actions with forgiving cooldowns';
COMMENT ON TABLE spam_flags IS 'Records suspicious activity patterns for manual review';
COMMENT ON COLUMN users.account_trust_level IS 'Trust level: 0=new, 1=verified/established. Affects rate limits';



-- UpVista Community - Stats Visibility Migration
-- Add stat visibility controls to user profiles
-- Designed and architected by Hamza Hafeez - Founder and CEO of Upvista

-- Add stat visibility settings (JSONB for flexible control)
-- Default: all stats visible
ALTER TABLE users ADD COLUMN IF NOT EXISTS stat_visibility JSONB DEFAULT '{
  "posts": true,
  "projects": true,
  "followers": true,
  "following": true,
  "connections": true,
  "collaborators": true
}'::jsonb;

-- Add constraint to ensure at least 3 stats are visible
-- This will be enforced in the application layer
COMMENT ON COLUMN users.stat_visibility IS 'Controls which profile stats are visible. Minimum 3 stats must be enabled.';

-- Index for performance (in case we need to query by visibility)
CREATE INDEX IF NOT EXISTS idx_users_stat_visibility ON users USING GIN (stat_visibility);

