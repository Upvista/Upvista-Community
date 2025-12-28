-- Events System Migration
-- Created by: Hamza Hafeez - Founder & CEO of Upvista
-- Complete events system with approval workflow and ticket generation

-- ============================================
-- 1. EVENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Basic Information
    title VARCHAR(255) NOT NULL,
    description TEXT,
    cover_image_url TEXT,
    
    -- Date & Time
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP,
    timezone VARCHAR(50) DEFAULT 'UTC',
    is_all_day BOOLEAN DEFAULT FALSE,
    
    -- Location
    location_type VARCHAR(20) DEFAULT 'physical' CHECK (location_type IN ('physical', 'online', 'hybrid')),
    location_name VARCHAR(255),
    location_address TEXT,
    online_platform VARCHAR(50), -- 'zoom', 'google_meet', 'teams', 'custom', etc.
    online_link TEXT, -- For online/hybrid events
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    
    -- Event Details
    category VARCHAR(50), -- 'networking', 'workshop', 'conference', 'social', 'webinar', etc.
    tags TEXT[], -- Array of tags
    max_attendees INTEGER,
    is_public BOOLEAN DEFAULT TRUE,
    password_hash TEXT, -- For private events (hashed password)
    
    -- Pricing
    is_free BOOLEAN DEFAULT TRUE,
    price DECIMAL(10, 2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Approval System
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('draft', 'pending', 'approved', 'rejected', 'cancelled', 'completed')),
    approval_token VARCHAR(255) UNIQUE, -- Token for approval email
    approval_requested_at TIMESTAMP,
    approved_at TIMESTAMP,
    approved_by UUID REFERENCES users(id), -- Admin who approved
    rejection_reason TEXT,
    auto_approved BOOLEAN DEFAULT FALSE, -- Whether event was auto-approved based on category
    
    -- Metadata
    views_count INTEGER DEFAULT 0,
    applications_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for events
CREATE INDEX idx_events_creator_id ON events(creator_id);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_start_date ON events(start_date);
CREATE INDEX idx_events_category ON events(category);
CREATE INDEX idx_events_is_public ON events(is_public);
CREATE INDEX idx_events_approval_token ON events(approval_token);
CREATE INDEX idx_events_location_type ON events(location_type);

-- ============================================
-- 2. EVENT APPLICATIONS (RSVP/Attendees)
-- ============================================
CREATE TABLE IF NOT EXISTS event_applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Application Status
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled', 'attended', 'no_show')),
    
    -- Application Information (can be auto-filled from profile or manually entered)
    full_name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    organization VARCHAR(255),
    additional_info TEXT, -- Any additional information user wants to provide
    
    -- Ticket Information
    ticket_token VARCHAR(255) UNIQUE NOT NULL, -- Unique ticket token/QR code
    ticket_number VARCHAR(50) UNIQUE NOT NULL, -- Human-readable ticket number (e.g., EVT-2024-001234)
    ticket_generated_at TIMESTAMP DEFAULT NOW(),
    
    -- Payment (if event is paid)
    payment_status VARCHAR(20) DEFAULT 'not_required' CHECK (payment_status IN ('not_required', 'pending', 'completed', 'refunded')),
    payment_amount DECIMAL(10, 2),
    payment_transaction_id VARCHAR(255),
    
    -- Metadata
    applied_at TIMESTAMP DEFAULT NOW(),
    approved_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    
    UNIQUE(event_id, user_id)
);

-- Indexes for event applications
CREATE INDEX idx_event_applications_event_id ON event_applications(event_id);
CREATE INDEX idx_event_applications_user_id ON event_applications(user_id);
CREATE INDEX idx_event_applications_status ON event_applications(status);
CREATE INDEX idx_event_applications_ticket_token ON event_applications(ticket_token);
CREATE INDEX idx_event_applications_ticket_number ON event_applications(ticket_number);

-- ============================================
-- 3. EVENT APPROVAL REQUESTS
-- ============================================
CREATE TABLE IF NOT EXISTS event_approval_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Approval Token
    approval_token VARCHAR(255) UNIQUE NOT NULL, -- Token sent via email
    token_expires_at TIMESTAMP NOT NULL,
    
    -- Request Details
    request_reason TEXT, -- Why approval is needed
    category VARCHAR(50), -- Event category
    is_private BOOLEAN DEFAULT FALSE,
    
    -- Status
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'expired')),
    
    -- Admin Response
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMP,
    admin_notes TEXT,
    
    -- Metadata
    requested_at TIMESTAMP DEFAULT NOW(),
    email_sent_at TIMESTAMP
);

-- Indexes for approval requests
CREATE INDEX idx_event_approval_requests_event_id ON event_approval_requests(event_id);
CREATE INDEX idx_event_approval_requests_creator_id ON event_approval_requests(creator_id);
CREATE INDEX idx_event_approval_requests_approval_token ON event_approval_requests(approval_token);
CREATE INDEX idx_event_approval_requests_status ON event_approval_requests(status);

-- ============================================
-- 4. EVENT CATEGORIES (Auto-approval rules)
-- ============================================
CREATE TABLE IF NOT EXISTS event_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) UNIQUE NOT NULL,
    requires_approval BOOLEAN DEFAULT TRUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insert default categories
INSERT INTO event_categories (name, requires_approval, description) VALUES
    ('networking', FALSE, 'Professional networking events'),
    ('workshop', TRUE, 'Educational workshops'),
    ('conference', TRUE, 'Conferences and summits'),
    ('webinar', FALSE, 'Online webinars'),
    ('social', FALSE, 'Social gatherings'),
    ('meetup', FALSE, 'Community meetups'),
    ('hackathon', TRUE, 'Hackathons and coding events'),
    ('seminar', TRUE, 'Educational seminars'),
    ('exhibition', TRUE, 'Exhibitions and showcases'),
    ('other', TRUE, 'Other types of events')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- 5. EVENT COMMENTS (Reuse comments table with event_id)
-- ============================================
-- We can extend the existing comments table or create event-specific comments
-- For now, we'll create a separate table for event discussions

CREATE TABLE IF NOT EXISTS event_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    parent_comment_id UUID REFERENCES event_comments(id) ON DELETE CASCADE,
    likes_count INTEGER DEFAULT 0,
    is_edited BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_event_comments_event_id ON event_comments(event_id);
CREATE INDEX idx_event_comments_user_id ON event_comments(user_id);
CREATE INDEX idx_event_comments_parent_comment_id ON event_comments(parent_comment_id);

-- ============================================
-- 6. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on events table
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- Events: Public events visible to all, private events visible to creator and attendees
CREATE POLICY "Public events are viewable by everyone"
    ON events FOR SELECT
    USING (is_public = TRUE AND status = 'approved');

CREATE POLICY "Users can view their own events"
    ON events FOR SELECT
    USING (auth.uid() = creator_id);

CREATE POLICY "Users can view events they applied to"
    ON events FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM event_applications
            WHERE event_applications.event_id = events.id
            AND event_applications.user_id = auth.uid()
        )
    );

-- Events: Only creators can insert/update their events
CREATE POLICY "Users can create events"
    ON events FOR INSERT
    WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Users can update their own events"
    ON events FOR UPDATE
    USING (auth.uid() = creator_id);

-- Event Applications: Users can view their own applications
ALTER TABLE event_applications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own applications"
    ON event_applications FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Event creators can view applications to their events"
    ON event_applications FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = event_applications.event_id
            AND events.creator_id = auth.uid()
        )
    );

CREATE POLICY "Users can create applications"
    ON event_applications FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own applications"
    ON event_applications FOR UPDATE
    USING (auth.uid() = user_id);

-- Event Comments: Similar to post comments
ALTER TABLE event_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view comments on public events"
    ON event_comments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = event_comments.event_id
            AND events.is_public = TRUE
        )
    );

CREATE POLICY "Users can create comments"
    ON event_comments FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own comments"
    ON event_comments FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments"
    ON event_comments FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- 7. FUNCTIONS & TRIGGERS
-- ============================================

-- Function to update event applications count
CREATE OR REPLACE FUNCTION update_event_applications_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE events
    SET applications_count = (
        SELECT COUNT(*) FROM event_applications
        WHERE event_applications.event_id = NEW.event_id
        AND event_applications.status IN ('pending', 'approved')
    )
    WHERE id = NEW.event_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update applications count
CREATE TRIGGER trigger_update_event_applications_count
    AFTER INSERT OR UPDATE OR DELETE ON event_applications
    FOR EACH ROW
    EXECUTE FUNCTION update_event_applications_count();

-- Function to generate ticket number
CREATE OR REPLACE FUNCTION generate_ticket_number()
RETURNS TEXT AS $$
DECLARE
    ticket_num TEXT;
    year_part TEXT;
    seq_num INTEGER;
BEGIN
    year_part := TO_CHAR(NOW(), 'YYYY');
    
    -- Get next sequence number for this year
    SELECT COALESCE(MAX(CAST(SUBSTRING(ticket_number FROM 'EVT-\d{4}-(\d+)') AS INTEGER)), 0) + 1
    INTO seq_num
    FROM event_applications
    WHERE ticket_number LIKE 'EVT-' || year_part || '-%';
    
    ticket_num := 'EVT-' || year_part || '-' || LPAD(seq_num::TEXT, 6, '0');
    RETURN ticket_num;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 8. COMMENTS
-- ============================================
COMMENT ON TABLE events IS 'Main events table storing all event information';
COMMENT ON TABLE event_applications IS 'Event RSVP/application records with ticket information';
COMMENT ON TABLE event_approval_requests IS 'Event approval requests requiring admin review';
COMMENT ON TABLE event_categories IS 'Event categories with auto-approval rules';
COMMENT ON TABLE event_comments IS 'Comments and discussions on events';
