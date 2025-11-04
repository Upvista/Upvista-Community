-- =====================================================
-- NOTIFICATIONS SYSTEM MIGRATION
-- Created: 2025-11-03
-- Purpose: Complete notification system with preferences
-- =====================================================

-- Drop existing tables if they exist
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS notification_preferences CASCADE;

-- Drop existing types if they exist
DROP TYPE IF EXISTS notification_type CASCADE;
DROP TYPE IF EXISTS notification_category CASCADE;
DROP TYPE IF EXISTS email_frequency CASCADE;

-- =====================================================
-- ENUMS
-- =====================================================

-- Notification types (extensible for future features)
CREATE TYPE notification_type AS ENUM (
    'follow',
    'follow_back',
    'connection_request',
    'connection_accepted',
    'connection_rejected',
    'collaboration_request',
    'collaboration_accepted',
    'collaboration_rejected',
    -- Future types
    'message',
    'post_like',
    'post_comment',
    'post_mention',
    'project_invite',
    'project_update',
    'community_invite',
    'community_post',
    'payment_received',
    'payment_sent',
    'system_announcement'
);

-- Notification categories for filtering
CREATE TYPE notification_category AS ENUM (
    'social',
    'messages',
    'projects',
    'communities',
    'payments',
    'system'
);

-- Email digest frequency
CREATE TYPE email_frequency AS ENUM (
    'instant',
    'daily',
    'weekly',
    'never'
);

-- =====================================================
-- NOTIFICATIONS TABLE
-- =====================================================

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type notification_type NOT NULL,
    category notification_category NOT NULL,
    title TEXT NOT NULL,
    message TEXT,
    actor_id UUID REFERENCES users(id) ON DELETE SET NULL,
    target_id UUID,
    target_type TEXT,
    action_url TEXT,
    is_read BOOLEAN NOT NULL DEFAULT false,
    is_actionable BOOLEAN NOT NULL DEFAULT false,
    action_type TEXT,
    action_taken BOOLEAN NOT NULL DEFAULT false,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (NOW() + INTERVAL '30 days')
);

-- =====================================================
-- NOTIFICATION PREFERENCES TABLE
-- =====================================================

CREATE TABLE notification_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    email_enabled BOOLEAN NOT NULL DEFAULT true,
    email_types JSONB NOT NULL DEFAULT '{
        "follow": false,
        "follow_back": false,
        "connection_request": true,
        "connection_accepted": true,
        "collaboration_request": true,
        "collaboration_accepted": true,
        "message": false,
        "post_like": false,
        "post_comment": true,
        "project_invite": true,
        "community_invite": true,
        "payment_received": true
    }',
    email_frequency email_frequency NOT NULL DEFAULT 'instant',
    in_app_enabled BOOLEAN NOT NULL DEFAULT true,
    push_enabled BOOLEAN NOT NULL DEFAULT false,
    inline_actions_enabled BOOLEAN NOT NULL DEFAULT true,
    categories_enabled JSONB NOT NULL DEFAULT '{
        "social": true,
        "messages": true,
        "projects": true,
        "communities": true,
        "payments": true,
        "system": true
    }',
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Primary lookup: get user's notifications sorted by date
CREATE INDEX idx_notifications_user_created 
    ON notifications(user_id, created_at DESC);

-- Unread notifications lookup (frequently accessed)
CREATE INDEX idx_notifications_user_unread 
    ON notifications(user_id, is_read) 
    WHERE is_read = false;

-- Category filtering
CREATE INDEX idx_notifications_category 
    ON notifications(user_id, category, created_at DESC);

-- Cleanup job lookup (no WHERE clause since NOW() is not immutable)
CREATE INDEX idx_notifications_expires 
    ON notifications(expires_at);

-- Actor lookup for joins
CREATE INDEX idx_notifications_actor 
    ON notifications(actor_id) 
    WHERE actor_id IS NOT NULL;

-- Actionable notifications
CREATE INDEX idx_notifications_actionable 
    ON notifications(user_id, is_actionable, action_taken) 
    WHERE is_actionable = true AND action_taken = false;

-- =====================================================
-- FUNCTIONS & TRIGGERS
-- =====================================================

-- Function to automatically set updated_at
CREATE OR REPLACE FUNCTION update_notification_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for notification_preferences
CREATE TRIGGER trg_notification_preferences_updated_at
    BEFORE UPDATE ON notification_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_notification_preferences_updated_at();

-- Function to create default preferences for new users
CREATE OR REPLACE FUNCTION create_default_notification_preferences()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO notification_preferences (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-create preferences for new users
CREATE TRIGGER trg_create_notification_preferences
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION create_default_notification_preferences();

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

-- Users can only see their own notifications
CREATE POLICY notifications_select_own 
    ON notifications FOR SELECT 
    USING (user_id = auth.uid());

-- Users can only update their own notifications (mark as read, delete)
CREATE POLICY notifications_update_own 
    ON notifications FOR UPDATE 
    USING (user_id = auth.uid());

-- Users can only delete their own notifications
CREATE POLICY notifications_delete_own 
    ON notifications FOR DELETE 
    USING (user_id = auth.uid());

-- Service role can insert notifications (backend only)
CREATE POLICY notifications_insert_service 
    ON notifications FOR INSERT 
    WITH CHECK (true);

-- Users can select and update their own preferences
CREATE POLICY notification_preferences_select_own 
    ON notification_preferences FOR SELECT 
    USING (user_id = auth.uid());

CREATE POLICY notification_preferences_update_own 
    ON notification_preferences FOR UPDATE 
    USING (user_id = auth.uid());

-- Service role can insert preferences (for new users)
CREATE POLICY notification_preferences_insert_service 
    ON notification_preferences FOR INSERT 
    WITH CHECK (true);

-- =====================================================
-- INITIAL DATA
-- =====================================================

-- Create preferences for existing users
INSERT INTO notification_preferences (user_id)
SELECT id FROM users
ON CONFLICT (user_id) DO NOTHING;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE notifications IS 'Stores all user notifications with support for real-time delivery, inline actions, and 30-day auto-expiry';
COMMENT ON TABLE notification_preferences IS 'User preferences for notification delivery (in-app, email, push) and filtering';
COMMENT ON COLUMN notifications.metadata IS 'Flexible JSONB column for feature-specific data (message preview, post content, etc.)';
COMMENT ON COLUMN notifications.expires_at IS 'Notifications auto-delete after 30 days via cleanup job';
COMMENT ON COLUMN notification_preferences.email_types IS 'Per-type email toggle: which notification types trigger emails';
COMMENT ON COLUMN notification_preferences.categories_enabled IS 'Which categories to show in the UI';

