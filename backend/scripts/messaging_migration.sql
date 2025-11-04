-- ============================================
-- MESSAGING SYSTEM MIGRATION
-- WhatsApp-style 1-on-1 messaging with real-time features
-- ============================================

-- Drop existing tables if they exist (for clean migration)
DROP TABLE IF EXISTS starred_messages CASCADE;
DROP TABLE IF EXISTS message_reactions CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;

-- ============================================
-- CONVERSATIONS TABLE
-- Represents a 1-on-1 conversation between two users
-- ============================================
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    participant1_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    participant2_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Last message info for conversation list (cached for performance)
    last_message_content TEXT,
    last_message_sender_id UUID REFERENCES users(id),
    last_message_at TIMESTAMP,
    
    -- Unread counts per participant (for badge display)
    unread_count_p1 INT DEFAULT 0,
    unread_count_p2 INT DEFAULT 0,
    
    -- Typing indicators (real-time feature)
    p1_typing BOOLEAN DEFAULT FALSE,
    p2_typing BOOLEAN DEFAULT FALSE,
    p1_typing_at TIMESTAMP,
    p2_typing_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Ensure no duplicate conversations (unique pair)
    CONSTRAINT unique_participants UNIQUE (participant1_id, participant2_id),
    -- Ensure users can't message themselves
    CONSTRAINT no_self_conversation CHECK (participant1_id != participant2_id)
);

-- Performance indexes for conversations
CREATE INDEX idx_conversations_p1 ON conversations(participant1_id);
CREATE INDEX idx_conversations_p2 ON conversations(participant2_id);
CREATE INDEX idx_conversations_last_message ON conversations(last_message_at DESC NULLS LAST);
CREATE INDEX idx_conversations_participants_composite ON conversations(participant1_id, participant2_id, last_message_at DESC);

-- ============================================
-- MESSAGES TABLE
-- Individual messages in conversations
-- ============================================
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Message content
    content TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text', -- 'text', 'image', 'file', 'audio', 'system'
    
    -- Attachments (images/files/audio)
    attachment_url TEXT,
    attachment_name TEXT,
    attachment_size INT, -- in bytes
    attachment_type VARCHAR(50), -- MIME type: 'image/png', 'audio/mp3', 'application/pdf', etc.
    
    -- Message status (WhatsApp-style delivery tracking)
    status VARCHAR(20) DEFAULT 'sent', -- 'sent', 'delivered', 'read'
    delivered_at TIMESTAMP,
    read_at TIMESTAMP,
    
    -- Soft delete (for "delete for me" feature)
    deleted_by UUID[], -- Array of user IDs who deleted this message
    
    -- Reply/thread support
    reply_to_id UUID REFERENCES messages(id),
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Performance indexes for messages
CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC);
CREATE INDEX idx_messages_conversation_time ON messages(conversation_id, created_at DESC);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_status ON messages(status);
CREATE INDEX idx_messages_created ON messages(created_at DESC);
-- Partial index for unread messages (faster queries)
CREATE INDEX idx_messages_unread ON messages(conversation_id, created_at DESC) WHERE status != 'read';
-- Index for status updates
CREATE INDEX idx_messages_status_update ON messages(id, status, conversation_id);

-- ============================================
-- MESSAGE REACTIONS TABLE
-- Emoji reactions on messages (Instagram/WhatsApp-style)
-- ============================================
CREATE TABLE message_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    emoji VARCHAR(10) NOT NULL, -- Unicode emoji character
    created_at TIMESTAMP DEFAULT NOW(),
    
    -- One reaction per user per message
    CONSTRAINT unique_user_message_reaction UNIQUE (message_id, user_id)
);

-- Performance index for reactions
CREATE INDEX idx_message_reactions_message ON message_reactions(message_id);
CREATE INDEX idx_message_reactions_user ON message_reactions(user_id);

-- ============================================
-- STARRED MESSAGES TABLE
-- User-specific starred messages (like WhatsApp starred)
-- ============================================
CREATE TABLE starred_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    starred_at TIMESTAMP DEFAULT NOW(),
    
    -- One star per user per message
    CONSTRAINT unique_user_starred_message UNIQUE (user_id, message_id)
);

-- Performance index for starred messages
CREATE INDEX idx_starred_messages_user ON starred_messages(user_id, starred_at DESC);
CREATE INDEX idx_starred_messages_message ON starred_messages(message_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- Security policies to ensure users only see their own data
-- ============================================

-- Enable RLS on all tables
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE starred_messages ENABLE ROW LEVEL SECURITY;

-- Conversations: Users can only see conversations they participate in
CREATE POLICY conversations_select_policy ON conversations
    FOR SELECT
    USING (
        auth.uid() = participant1_id OR 
        auth.uid() = participant2_id
    );

CREATE POLICY conversations_insert_policy ON conversations
    FOR INSERT
    WITH CHECK (
        auth.uid() = participant1_id OR 
        auth.uid() = participant2_id
    );

CREATE POLICY conversations_update_policy ON conversations
    FOR UPDATE
    USING (
        auth.uid() = participant1_id OR 
        auth.uid() = participant2_id
    );

CREATE POLICY conversations_delete_policy ON conversations
    FOR DELETE
    USING (
        auth.uid() = participant1_id OR 
        auth.uid() = participant2_id
    );

-- Messages: Users can only see messages from their conversations
CREATE POLICY messages_select_policy ON messages
    FOR SELECT
    USING (
        conversation_id IN (
            SELECT id FROM conversations 
            WHERE participant1_id = auth.uid() 
               OR participant2_id = auth.uid()
        )
    );

CREATE POLICY messages_insert_policy ON messages
    FOR INSERT
    WITH CHECK (
        sender_id = auth.uid() AND
        conversation_id IN (
            SELECT id FROM conversations 
            WHERE participant1_id = auth.uid() 
               OR participant2_id = auth.uid()
        )
    );

CREATE POLICY messages_update_policy ON messages
    FOR UPDATE
    USING (
        conversation_id IN (
            SELECT id FROM conversations 
            WHERE participant1_id = auth.uid() 
               OR participant2_id = auth.uid()
        )
    );

CREATE POLICY messages_delete_policy ON messages
    FOR DELETE
    USING (
        sender_id = auth.uid() OR
        conversation_id IN (
            SELECT id FROM conversations 
            WHERE participant1_id = auth.uid() 
               OR participant2_id = auth.uid()
        )
    );

-- Message Reactions: Users can see reactions on messages they can access
CREATE POLICY reactions_select_policy ON message_reactions
    FOR SELECT
    USING (
        message_id IN (
            SELECT m.id FROM messages m
            JOIN conversations c ON m.conversation_id = c.id
            WHERE c.participant1_id = auth.uid() 
               OR c.participant2_id = auth.uid()
        )
    );

CREATE POLICY reactions_insert_policy ON message_reactions
    FOR INSERT
    WITH CHECK (
        user_id = auth.uid() AND
        message_id IN (
            SELECT m.id FROM messages m
            JOIN conversations c ON m.conversation_id = c.id
            WHERE c.participant1_id = auth.uid() 
               OR c.participant2_id = auth.uid()
        )
    );

CREATE POLICY reactions_delete_policy ON message_reactions
    FOR DELETE
    USING (
        user_id = auth.uid()
    );

-- Starred Messages: Users can only see their own starred messages
CREATE POLICY starred_select_policy ON starred_messages
    FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY starred_insert_policy ON starred_messages
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY starred_delete_policy ON starred_messages
    FOR DELETE
    USING (user_id = auth.uid());

-- ============================================
-- FUNCTIONS AND TRIGGERS
-- Automatic updates for performance and consistency
-- ============================================

-- Function to update conversation's last message info
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
    -- Update conversation with new message info
    UPDATE conversations
    SET 
        last_message_content = CASE 
            WHEN NEW.message_type = 'text' THEN NEW.content
            WHEN NEW.message_type = 'image' THEN '📷 Photo'
            WHEN NEW.message_type = 'audio' THEN '🎤 Voice message'
            WHEN NEW.message_type = 'file' THEN '📎 ' || COALESCE(NEW.attachment_name, 'File')
            ELSE NEW.content
        END,
        last_message_sender_id = NEW.sender_id,
        last_message_at = NEW.created_at,
        updated_at = NOW()
    WHERE id = NEW.conversation_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update conversation on new message
CREATE TRIGGER trigger_update_conversation_last_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_last_message();

-- Function to increment unread count for recipient
CREATE OR REPLACE FUNCTION increment_unread_count()
RETURNS TRIGGER AS $$
DECLARE
    conv RECORD;
BEGIN
    -- Get conversation details
    SELECT participant1_id, participant2_id INTO conv
    FROM conversations WHERE id = NEW.conversation_id;
    
    -- Increment unread count for recipient (not sender)
    IF conv.participant1_id = NEW.sender_id THEN
        -- Sender is P1, so increment P2's unread count
        UPDATE conversations
        SET unread_count_p2 = unread_count_p2 + 1
        WHERE id = NEW.conversation_id;
    ELSE
        -- Sender is P2, so increment P1's unread count
        UPDATE conversations
        SET unread_count_p1 = unread_count_p1 + 1
        WHERE id = NEW.conversation_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-increment unread count on new message
CREATE TRIGGER trigger_increment_unread_count
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION increment_unread_count();

-- Function to update message read_at timestamp
CREATE OR REPLACE FUNCTION update_message_read_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'read' AND OLD.status != 'read' AND NEW.read_at IS NULL THEN
        NEW.read_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update read_at when status changes to 'read'
CREATE TRIGGER trigger_update_message_read_at
    BEFORE UPDATE ON messages
    FOR EACH ROW
    WHEN (NEW.status = 'read' AND OLD.status != 'read')
    EXECUTE FUNCTION update_message_read_at();

-- ============================================
-- HELPER FUNCTIONS
-- Utility functions for common operations
-- ============================================

-- Function to get unread message count for a user across all conversations
CREATE OR REPLACE FUNCTION get_user_total_unread_count(user_uuid UUID)
RETURNS INT AS $$
DECLARE
    total INT;
BEGIN
    SELECT 
        COALESCE(SUM(
            CASE 
                WHEN participant1_id = user_uuid THEN unread_count_p1
                WHEN participant2_id = user_uuid THEN unread_count_p2
                ELSE 0
            END
        ), 0) INTO total
    FROM conversations
    WHERE participant1_id = user_uuid OR participant2_id = user_uuid;
    
    RETURN total;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON TABLE conversations IS 'Stores 1-on-1 conversations between users with caching for performance';
COMMENT ON TABLE messages IS 'Individual messages within conversations with WhatsApp-style delivery tracking';
COMMENT ON TABLE message_reactions IS 'Emoji reactions on messages (Instagram/WhatsApp-style)';
COMMENT ON TABLE starred_messages IS 'User-specific starred/bookmarked messages';

COMMENT ON COLUMN conversations.last_message_content IS 'Cached last message for quick conversation list display';
COMMENT ON COLUMN conversations.unread_count_p1 IS 'Unread message count for participant 1';
COMMENT ON COLUMN conversations.unread_count_p2 IS 'Unread message count for participant 2';
COMMENT ON COLUMN messages.status IS 'Message delivery status: sent (✓), delivered (✓✓), read (✓✓ blue)';
COMMENT ON COLUMN messages.deleted_by IS 'Array of user IDs who soft-deleted this message';

-- ============================================
-- MIGRATION COMPLETE
-- ============================================

-- Grant necessary permissions (adjust based on your auth setup)
-- GRANT ALL ON conversations TO authenticated;
-- GRANT ALL ON messages TO authenticated;
-- GRANT ALL ON message_reactions TO authenticated;
-- GRANT ALL ON starred_messages TO authenticated;

SELECT 'Messaging system migration completed successfully!' AS status;

