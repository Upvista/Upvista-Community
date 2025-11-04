-- Fix RLS Policies for Relationships Tables
-- Allow service role to bypass RLS completely

-- Disable RLS on relationships tables (service role will handle auth)
ALTER TABLE user_relationships DISABLE ROW LEVEL SECURITY;
ALTER TABLE relationship_rate_limits DISABLE ROW LEVEL SECURITY;
ALTER TABLE spam_flags DISABLE ROW LEVEL SECURITY;

-- Or if you want to keep RLS but allow service role to bypass:
-- DROP all existing policies first
DROP POLICY IF EXISTS "Users can view relationships they're part of" ON user_relationships;
DROP POLICY IF EXISTS "Users can create relationships" ON user_relationships;
DROP POLICY IF EXISTS "Users can update their own relationships" ON user_relationships;
DROP POLICY IF EXISTS "Users can delete their own relationships" ON user_relationships;

DROP POLICY IF EXISTS "Users can view own rate limits" ON relationship_rate_limits;
DROP POLICY IF EXISTS "Users can view own spam flags" ON spam_flags;

-- Enable RLS
ALTER TABLE user_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE relationship_rate_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE spam_flags ENABLE ROW LEVEL SECURITY;

-- Create permissive policies for service role (which we're using)
CREATE POLICY "Service role full access" ON user_relationships
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Service role full access" ON relationship_rate_limits
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Service role full access" ON spam_flags
    FOR ALL USING (true) WITH CHECK (true);

