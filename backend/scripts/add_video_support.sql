-- Add video support to messages table
-- Run this migration to add video-specific fields

-- Add video columns to messages table
ALTER TABLE IF EXISTS messages 
ADD COLUMN IF NOT EXISTS thumbnail_url TEXT,
ADD COLUMN IF NOT EXISTS video_duration INTEGER,
ADD COLUMN IF NOT EXISTS video_width INTEGER,
ADD COLUMN IF NOT EXISTS video_height INTEGER;

-- Create index on message_type for better query performance
CREATE INDEX IF NOT EXISTS idx_messages_type ON messages(message_type);

-- Update any existing video messages (if any were uploaded before)
-- This is safe to run multiple times
UPDATE messages 
SET message_type = 'video' 
WHERE attachment_type LIKE 'video/%' 
AND message_type != 'video';

-- Comments for documentation
COMMENT ON COLUMN messages.thumbnail_url IS 'URL to video thumbnail/poster image';
COMMENT ON COLUMN messages.video_duration IS 'Video duration in seconds';
COMMENT ON COLUMN messages.video_width IS 'Video width in pixels';
COMMENT ON COLUMN messages.video_height IS 'Video height in pixels';

