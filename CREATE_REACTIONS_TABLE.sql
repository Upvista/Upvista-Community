-- ============================================
-- CREATE MESSAGE_REACTIONS TABLE
-- Simple, error-free version
-- ============================================

-- Create table
CREATE TABLE IF NOT EXISTS message_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL,
    user_id UUID NOT NULL,
    emoji VARCHAR(10) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (message_id, user_id)
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_message_reactions_message ON message_reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_message_reactions_user ON message_reactions(user_id);

-- Enable RLS
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS reactions_select_policy ON message_reactions;
DROP POLICY IF EXISTS reactions_insert_policy ON message_reactions;
DROP POLICY IF EXISTS reactions_delete_policy ON message_reactions;

-- Allow users to see all reactions in their conversations
CREATE POLICY reactions_select_policy ON message_reactions
FOR SELECT
TO authenticated
USING (true);

-- Allow authenticated users to add reactions
CREATE POLICY reactions_insert_policy ON message_reactions
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Allow users to delete only their own reactions
CREATE POLICY reactions_delete_policy ON message_reactions
FOR DELETE
TO authenticated
USING (user_id = auth.uid());

