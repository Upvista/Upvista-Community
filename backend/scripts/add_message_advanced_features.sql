-- ============================================
-- ADD ADVANCED MESSAGE FEATURES
-- Pin, Edit, Forward, Share capabilities
-- ============================================

-- Add columns for PIN feature
ALTER TABLE messages
ADD COLUMN IF NOT EXISTS pinned_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS pinned_by UUID REFERENCES users(id);

-- Add columns for EDIT feature
ALTER TABLE messages
ADD COLUMN IF NOT EXISTS edited_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS edit_count INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS original_content TEXT; -- Store original for history

-- Add columns for FORWARD feature
ALTER TABLE messages
ADD COLUMN IF NOT EXISTS forwarded_from_id UUID REFERENCES messages(id),
ADD COLUMN IF NOT EXISTS is_forwarded BOOLEAN DEFAULT FALSE;

-- Create index for pinned messages (fast retrieval)
CREATE INDEX IF NOT EXISTS idx_messages_pinned ON messages(conversation_id, pinned_at DESC NULLS LAST) WHERE pinned_at IS NOT NULL;

-- Create index for edited messages
CREATE INDEX IF NOT EXISTS idx_messages_edited ON messages(edited_at DESC) WHERE edited_at IS NOT NULL;

-- Create index for forwarded messages
CREATE INDEX IF NOT EXISTS idx_messages_forwarded ON messages(forwarded_from_id) WHERE is_forwarded = TRUE;

-- ============================================
-- SHARED MESSAGES TABLE (for sharing outside app)
-- Track when messages are shared externally
-- ============================================
CREATE TABLE IF NOT EXISTS shared_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    shared_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    share_method VARCHAR(50), -- 'link', 'email', 'social', 'clipboard'
    share_url TEXT, -- If applicable
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_shared_messages_message ON shared_messages(message_id);
CREATE INDEX IF NOT EXISTS idx_shared_messages_user ON shared_messages(shared_by);

-- ============================================
-- MESSAGE EDIT HISTORY TABLE
-- Track edit history for transparency
-- ============================================
CREATE TABLE IF NOT EXISTS message_edit_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    previous_content TEXT NOT NULL,
    edited_by UUID NOT NULL REFERENCES users(id),
    edited_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_message_edit_history ON message_edit_history(message_id, edited_at DESC);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on new tables
ALTER TABLE shared_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_edit_history ENABLE ROW LEVEL SECURITY;

-- Shared messages policies
DROP POLICY IF EXISTS shared_messages_select ON shared_messages;
CREATE POLICY shared_messages_select ON shared_messages
    FOR SELECT
    TO authenticated
    USING (
        shared_by = auth.uid()
        OR
        message_id IN (
            SELECT id FROM messages WHERE sender_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS shared_messages_insert ON shared_messages;
CREATE POLICY shared_messages_insert ON shared_messages
    FOR INSERT
    TO authenticated
    WITH CHECK (shared_by = auth.uid());

-- Message edit history policies
DROP POLICY IF EXISTS message_edit_history_select ON message_edit_history;
CREATE POLICY message_edit_history_select ON message_edit_history
    FOR SELECT
    TO authenticated
    USING (
        -- Can view edit history if you're part of the conversation
        message_id IN (
            SELECT m.id FROM messages m
            JOIN conversations c ON m.conversation_id = c.id
            WHERE c.participant1_id = auth.uid() OR c.participant2_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS message_edit_history_insert ON message_edit_history;
CREATE POLICY message_edit_history_insert ON message_edit_history
    FOR INSERT
    TO authenticated
    WITH CHECK (edited_by = auth.uid());

-- ============================================
-- COMMENTS
-- ============================================
COMMENT ON COLUMN messages.pinned_at IS 'When this message was pinned (NULL if not pinned)';
COMMENT ON COLUMN messages.pinned_by IS 'User who pinned this message';
COMMENT ON COLUMN messages.edited_at IS 'Last edit timestamp';
COMMENT ON COLUMN messages.edit_count IS 'Number of times this message was edited';
COMMENT ON COLUMN messages.original_content IS 'Original message content before any edits';
COMMENT ON COLUMN messages.forwarded_from_id IS 'Reference to original message if this is a forward';
COMMENT ON COLUMN messages.is_forwarded IS 'TRUE if this message was forwarded from another conversation';

COMMENT ON TABLE shared_messages IS 'Tracks when messages are shared outside the app';
COMMENT ON TABLE message_edit_history IS 'History of all message edits for transparency';


