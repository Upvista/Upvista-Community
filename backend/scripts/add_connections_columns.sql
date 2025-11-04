-- =====================================================
-- ADD CONNECTIONS AND COLLABORATORS COUNT COLUMNS
-- Run this if you get errors about missing columns
-- =====================================================

-- Check if columns exist, add only if missing
DO $$ 
BEGIN
    -- Add connections_count column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'connections_count'
    ) THEN
        ALTER TABLE users ADD COLUMN connections_count INTEGER NOT NULL DEFAULT 0;
        RAISE NOTICE 'Added connections_count column';
    ELSE
        RAISE NOTICE 'connections_count column already exists';
    END IF;

    -- Add collaborators_count column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'collaborators_count'
    ) THEN
        ALTER TABLE users ADD COLUMN collaborators_count INTEGER NOT NULL DEFAULT 0;
        RAISE NOTICE 'Added collaborators_count column';
    ELSE
        RAISE NOTICE 'collaborators_count column already exists';
    END IF;
END $$;

-- Add comments
COMMENT ON COLUMN users.connections_count IS 'Denormalized count of mutual connections';
COMMENT ON COLUMN users.collaborators_count IS 'Denormalized count of active collaborators';

-- Create indexes for these columns (optional, for sorting)
CREATE INDEX IF NOT EXISTS idx_users_connections_count ON users(connections_count DESC);
CREATE INDEX IF NOT EXISTS idx_users_collaborators_count ON users(collaborators_count DESC);

