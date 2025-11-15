-- ============================================
-- POSTS & FEED SYSTEM MIGRATION
-- Complete social feed with Posts, Polls, and Articles
-- Designed by: Hamza Hafeez - Founder & CEO of Upvista
-- ============================================

-- Drop existing tables if they exist (for clean migration)
DROP TABLE IF EXISTS hashtag_followers CASCADE;
DROP TABLE IF EXISTS post_mentions CASCADE;
DROP TABLE IF EXISTS post_hashtags CASCADE;
DROP TABLE IF EXISTS hashtags CASCADE;
DROP TABLE IF EXISTS saved_posts CASCADE;
DROP TABLE IF EXISTS post_shares CASCADE;
DROP TABLE IF EXISTS comment_likes CASCADE;
DROP TABLE IF EXISTS post_comments CASCADE;
DROP TABLE IF EXISTS post_likes CASCADE;
DROP TABLE IF EXISTS article_tags CASCADE;
DROP TABLE IF EXISTS articles CASCADE;
DROP TABLE IF EXISTS poll_votes CASCADE;
DROP TABLE IF EXISTS poll_options CASCADE;
DROP TABLE IF EXISTS polls CASCADE;
DROP TABLE IF EXISTS posts CASCADE;

-- ============================================
-- CORE POSTS TABLE
-- Unified table for all content types (posts, polls, articles)
-- ============================================
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Type discriminator
    post_type VARCHAR(20) NOT NULL, -- 'post', 'poll', 'article'
    
    -- Content (common to all types)
    content TEXT NOT NULL CHECK (LENGTH(content) <= 125000),
    
    -- Media (for posts - array of URLs)
    media_urls TEXT[],
    media_types TEXT[], -- ['image', 'image', 'video']
    
    -- Metadata
    visibility VARCHAR(20) DEFAULT 'public', -- 'public', 'connections', 'private'
    allows_comments BOOLEAN DEFAULT TRUE,
    allows_sharing BOOLEAN DEFAULT TRUE,
    
    -- Engagement stats (denormalized for performance)
    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    shares_count INT DEFAULT 0,
    views_count INT DEFAULT 0,
    saves_count INT DEFAULT 0,
    
    -- Features
    is_pinned BOOLEAN DEFAULT FALSE, -- Pin to profile
    is_featured BOOLEAN DEFAULT FALSE, -- Featured by admin
    is_nsfw BOOLEAN DEFAULT FALSE, -- Sensitive content warning
    
    -- Status
    is_published BOOLEAN DEFAULT TRUE,
    is_draft BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMP,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP, -- Soft delete
    
    -- Full-text search
    search_vector tsvector,
    
    -- Constraints
    CONSTRAINT valid_post_type CHECK (post_type IN ('post', 'poll', 'article')),
    CONSTRAINT valid_visibility CHECK (visibility IN ('public', 'connections', 'private'))
);

-- Indexes for posts (critical for feed performance)
CREATE INDEX idx_posts_user_time ON posts(user_id, published_at DESC);
CREATE INDEX idx_posts_type ON posts(post_type);
CREATE INDEX idx_posts_feed ON posts(is_published, deleted_at, published_at DESC) 
    WHERE is_published = TRUE AND deleted_at IS NULL;
CREATE INDEX idx_posts_visibility ON posts(visibility);
CREATE INDEX idx_posts_search ON posts USING gin(search_vector);
CREATE INDEX idx_posts_created ON posts(created_at DESC);
CREATE INDEX idx_posts_pinned ON posts(user_id, is_pinned) WHERE is_pinned = TRUE;

-- ============================================
-- POLLS
-- Interactive polls with voting system
-- ============================================
CREATE TABLE polls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    
    -- Poll content
    question TEXT NOT NULL CHECK (LENGTH(question) <= 280),
    
    -- Settings
    duration_hours INT NOT NULL DEFAULT 168, -- Default 1 week (168 hours)
    allow_multiple_votes BOOLEAN DEFAULT FALSE,
    show_results_before_vote BOOLEAN DEFAULT TRUE,
    allow_vote_changes BOOLEAN DEFAULT TRUE,
    anonymous_votes BOOLEAN DEFAULT FALSE,
    
    -- Status
    is_closed BOOLEAN DEFAULT FALSE,
    closed_at TIMESTAMP,
    ends_at TIMESTAMP NOT NULL,
    
    -- Stats
    total_votes INT DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT unique_poll_per_post UNIQUE (post_id)
);

CREATE TABLE poll_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    
    option_text VARCHAR(100) NOT NULL,
    option_index INT NOT NULL, -- 0, 1, 2, 3
    votes_count INT DEFAULT 0,
    
    CONSTRAINT unique_poll_option UNIQUE (poll_id, option_index),
    CONSTRAINT option_index_range CHECK (option_index >= 0 AND option_index <= 3)
);

CREATE TABLE poll_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    option_id UUID NOT NULL REFERENCES poll_options(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    voted_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT unique_user_poll_vote UNIQUE (poll_id, user_id)
);

-- Indexes for polls
CREATE INDEX idx_polls_post ON polls(post_id);
CREATE INDEX idx_polls_ends ON polls(ends_at) WHERE is_closed = FALSE;
CREATE INDEX idx_poll_options_poll ON poll_options(poll_id, option_index);
CREATE INDEX idx_poll_votes_poll ON poll_votes(poll_id);
CREATE INDEX idx_poll_votes_user ON poll_votes(user_id);

-- ============================================
-- ARTICLES
-- Long-form rich text content
-- ============================================
CREATE TABLE articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    
    -- Content
    title VARCHAR(100) NOT NULL,
    subtitle VARCHAR(150),
    content_html TEXT NOT NULL, -- Rendered HTML from TipTap
    cover_image_url TEXT,
    
    -- SEO
    meta_title VARCHAR(60),
    meta_description VARCHAR(160),
    slug VARCHAR(150) UNIQUE NOT NULL, -- URL-friendly: /articles/my-article-title
    
    -- Metadata
    read_time_minutes INT, -- Auto-calculated: ~200 words/minute
    category VARCHAR(50), -- 'Technology', 'Business', 'Design', etc.
    
    -- Stats
    views_count INT DEFAULT 0,
    reads_count INT DEFAULT 0, -- Users who scrolled to end
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT unique_article_per_post UNIQUE (post_id)
);

CREATE TABLE article_tags (
    article_id UUID REFERENCES articles(id) ON DELETE CASCADE,
    tag VARCHAR(50) NOT NULL,
    PRIMARY KEY (article_id, tag)
);

-- Indexes for articles
CREATE INDEX idx_articles_post ON articles(post_id);
CREATE INDEX idx_articles_slug ON articles(slug);
CREATE INDEX idx_articles_category ON articles(category);
CREATE INDEX idx_articles_tags ON article_tags(tag);

-- ============================================
-- ENGAGEMENT: LIKES
-- ============================================
CREATE TABLE post_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    created_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT unique_post_like UNIQUE (post_id, user_id)
);

-- Indexes for likes
CREATE INDEX idx_post_likes_post ON post_likes(post_id, created_at DESC);
CREATE INDEX idx_post_likes_user ON post_likes(user_id, created_at DESC);

-- ============================================
-- ENGAGEMENT: COMMENTS
-- Nested comment system with threading
-- ============================================
CREATE TABLE post_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parent_comment_id UUID REFERENCES post_comments(id) ON DELETE CASCADE,
    
    -- Content
    content TEXT NOT NULL CHECK (LENGTH(content) >= 1 AND LENGTH(content) <= 1000),
    
    -- Media (GIFs allowed in comments)
    media_url TEXT,
    media_type VARCHAR(20), -- 'gif', 'image'
    
    -- Stats
    likes_count INT DEFAULT 0,
    replies_count INT DEFAULT 0,
    
    -- Status
    is_edited BOOLEAN DEFAULT FALSE,
    edited_at TIMESTAMP,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP -- Soft delete
    
    -- Note: Nesting depth constraint enforced by trigger (see below)
);

CREATE TABLE comment_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    comment_id UUID NOT NULL REFERENCES post_comments(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    created_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT unique_comment_like UNIQUE (comment_id, user_id)
);

-- Indexes for comments
CREATE INDEX idx_comments_post ON post_comments(post_id, created_at DESC);
CREATE INDEX idx_comments_parent ON post_comments(parent_comment_id, created_at DESC);
CREATE INDEX idx_comments_user ON post_comments(user_id, created_at DESC);
CREATE INDEX idx_comment_likes_comment ON comment_likes(comment_id);
CREATE INDEX idx_comment_likes_user ON comment_likes(user_id);

-- ============================================
-- ENGAGEMENT: SHARES/REPOSTS
-- ============================================
CREATE TABLE post_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Repost with comment (like Twitter quote tweet)
    repost_comment TEXT CHECK (LENGTH(repost_comment) <= 280),
    
    created_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT unique_user_share UNIQUE (post_id, user_id)
);

CREATE INDEX idx_post_shares_post ON post_shares(post_id, created_at DESC);
CREATE INDEX idx_post_shares_user ON post_shares(user_id, created_at DESC);

-- ============================================
-- ENGAGEMENT: SAVED/BOOKMARKED POSTS
-- ============================================
CREATE TABLE saved_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Collections (like Pinterest boards)
    collection_name VARCHAR(50) DEFAULT 'Saved',
    
    saved_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT unique_user_saved_post UNIQUE (post_id, user_id)
);

CREATE INDEX idx_saved_posts_user ON saved_posts(user_id, saved_at DESC);
CREATE INDEX idx_saved_posts_collection ON saved_posts(user_id, collection_name);

-- ============================================
-- DISCOVERY: HASHTAGS
-- ============================================
CREATE TABLE hashtags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tag VARCHAR(100) UNIQUE NOT NULL,
    
    -- Stats
    posts_count INT DEFAULT 0,
    followers_count INT DEFAULT 0,
    
    -- Trending score (calculated by background job)
    trending_score DECIMAL(10,2) DEFAULT 0,
    last_trending_update TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE post_hashtags (
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    hashtag_id UUID REFERENCES hashtags(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, hashtag_id)
);

CREATE TABLE hashtag_followers (
    hashtag_id UUID REFERENCES hashtags(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    followed_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (hashtag_id, user_id)
);

-- Indexes for hashtags
CREATE INDEX idx_hashtags_tag_lower ON hashtags(LOWER(tag));
CREATE INDEX idx_hashtags_trending ON hashtags(trending_score DESC);
CREATE INDEX idx_post_hashtags_post ON post_hashtags(post_id);
CREATE INDEX idx_post_hashtags_hashtag ON post_hashtags(hashtag_id);

-- ============================================
-- DISCOVERY: MENTIONS
-- ============================================
CREATE TABLE post_mentions (
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    mentioned_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, mentioned_user_id)
);

CREATE INDEX idx_post_mentions_user ON post_mentions(mentioned_user_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- Security policies to ensure proper access control
-- ============================================

-- Enable RLS on all tables
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE poll_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE poll_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE article_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE comment_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE hashtags ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_hashtags ENABLE ROW LEVEL SECURITY;
ALTER TABLE hashtag_followers ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_mentions ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES: POSTS
-- ============================================

-- View posts based on visibility
CREATE POLICY posts_select_policy ON posts
    FOR SELECT
    USING (
        deleted_at IS NULL AND (
            -- Public posts visible to all
            visibility = 'public' OR
            -- Own posts always visible
            user_id = auth.uid()
            -- Note: Connection-based visibility will be enforced by application layer
            -- until relationships table is available
        )
    );

-- Create posts
CREATE POLICY posts_insert_policy ON posts
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Update own posts only
CREATE POLICY posts_update_policy ON posts
    FOR UPDATE
    USING (user_id = auth.uid());

-- Delete own posts only
CREATE POLICY posts_delete_policy ON posts
    FOR DELETE
    USING (user_id = auth.uid());

-- ============================================
-- RLS POLICIES: POLLS
-- ============================================

CREATE POLICY polls_select_policy ON polls
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM posts 
            WHERE posts.id = polls.post_id 
            AND posts.deleted_at IS NULL
        )
    );

CREATE POLICY polls_insert_policy ON polls
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM posts 
            WHERE posts.id = polls.post_id 
            AND posts.user_id = auth.uid()
        )
    );

-- Poll options inherit post visibility
CREATE POLICY poll_options_select_policy ON poll_options
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM polls p
            JOIN posts po ON p.post_id = po.id
            WHERE p.id = poll_options.poll_id 
            AND po.deleted_at IS NULL
        )
    );

-- Poll votes
CREATE POLICY poll_votes_select_policy ON poll_votes
    FOR SELECT
    USING (
        user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM polls p
            WHERE p.id = poll_votes.poll_id 
            AND p.anonymous_votes = FALSE
        )
    );

CREATE POLICY poll_votes_insert_policy ON poll_votes
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY poll_votes_update_policy ON poll_votes
    FOR UPDATE
    USING (user_id = auth.uid());

-- ============================================
-- RLS POLICIES: ARTICLES
-- ============================================

CREATE POLICY articles_select_policy ON articles
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM posts 
            WHERE posts.id = articles.post_id 
            AND posts.deleted_at IS NULL
        )
    );

CREATE POLICY articles_insert_policy ON articles
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM posts 
            WHERE posts.id = articles.post_id 
            AND posts.user_id = auth.uid()
        )
    );

-- ============================================
-- RLS POLICIES: ENGAGEMENT
-- ============================================

-- Likes: Anyone can like visible posts
CREATE POLICY post_likes_select_policy ON post_likes
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM posts 
            WHERE posts.id = post_likes.post_id 
            AND posts.deleted_at IS NULL
        )
    );

CREATE POLICY post_likes_insert_policy ON post_likes
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY post_likes_delete_policy ON post_likes
    FOR DELETE
    USING (user_id = auth.uid());

-- Comments: Anyone can comment on posts that allow it
CREATE POLICY comments_select_policy ON post_comments
    FOR SELECT
    USING (
        deleted_at IS NULL AND
        EXISTS (
            SELECT 1 FROM posts 
            WHERE posts.id = post_comments.post_id 
            AND posts.deleted_at IS NULL
        )
    );

CREATE POLICY comments_insert_policy ON post_comments
    FOR INSERT
    WITH CHECK (
        user_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM posts 
            WHERE posts.id = post_comments.post_id 
            AND posts.allows_comments = TRUE
        )
    );

CREATE POLICY comments_update_policy ON post_comments
    FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY comments_delete_policy ON post_comments
    FOR DELETE
    USING (user_id = auth.uid());

-- Comment likes
CREATE POLICY comment_likes_select_policy ON comment_likes
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM post_comments 
            WHERE post_comments.id = comment_likes.comment_id 
            AND post_comments.deleted_at IS NULL
        )
    );

CREATE POLICY comment_likes_insert_policy ON comment_likes
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY comment_likes_delete_policy ON comment_likes
    FOR DELETE
    USING (user_id = auth.uid());

-- Shares
CREATE POLICY post_shares_select_policy ON post_shares
    FOR SELECT
    USING (TRUE); -- Shares are public

CREATE POLICY post_shares_insert_policy ON post_shares
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Saved posts (private to user)
CREATE POLICY saved_posts_select_policy ON saved_posts
    FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY saved_posts_insert_policy ON saved_posts
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY saved_posts_delete_policy ON saved_posts
    FOR DELETE
    USING (user_id = auth.uid());

-- Hashtags (public)
CREATE POLICY hashtags_select_policy ON hashtags FOR SELECT USING (TRUE);
CREATE POLICY post_hashtags_select_policy ON post_hashtags FOR SELECT USING (TRUE);

CREATE POLICY hashtag_followers_select_policy ON hashtag_followers
    FOR SELECT
    USING (TRUE);

CREATE POLICY hashtag_followers_insert_policy ON hashtag_followers
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY hashtag_followers_delete_policy ON hashtag_followers
    FOR DELETE
    USING (user_id = auth.uid());

-- Mentions
CREATE POLICY post_mentions_select_policy ON post_mentions FOR SELECT USING (TRUE);

-- ============================================
-- TRIGGERS: AUTO-UPDATE STATS
-- ============================================

-- Enforce comment nesting depth (max 2 levels)
CREATE OR REPLACE FUNCTION check_comment_nesting_depth()
RETURNS TRIGGER AS $$
DECLARE
    parent_has_parent BOOLEAN;
BEGIN
    -- If this comment has a parent
    IF NEW.parent_comment_id IS NOT NULL THEN
        -- Check if the parent comment itself has a parent
        SELECT parent_comment_id IS NOT NULL INTO parent_has_parent
        FROM post_comments
        WHERE id = NEW.parent_comment_id;
        
        -- If parent has a parent, we're at depth 3 which is not allowed
        IF parent_has_parent THEN
            RAISE EXCEPTION 'Comments can only be nested 2 levels deep';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_comment_nesting_depth
    BEFORE INSERT ON post_comments
    FOR EACH ROW
    EXECUTE FUNCTION check_comment_nesting_depth();

-- Update post likes_count
CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET likes_count = likes_count + 1, updated_at = NOW() WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET likes_count = GREATEST(0, likes_count - 1), updated_at = NOW() WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_post_likes_count
    AFTER INSERT OR DELETE ON post_likes
    FOR EACH ROW EXECUTE FUNCTION update_post_likes_count();

-- Update post comments_count
CREATE OR REPLACE FUNCTION update_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET comments_count = comments_count + 1, updated_at = NOW() WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET comments_count = GREATEST(0, comments_count - 1), updated_at = NOW() WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_post_comments_count
    AFTER INSERT OR DELETE ON post_comments
    FOR EACH ROW
    EXECUTE FUNCTION update_post_comments_count();

-- Update comment likes_count
CREATE OR REPLACE FUNCTION update_comment_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE post_comments SET likes_count = likes_count + 1 WHERE id = NEW.comment_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE post_comments SET likes_count = GREATEST(0, likes_count - 1) WHERE id = OLD.comment_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_comment_likes_count
    AFTER INSERT OR DELETE ON comment_likes
    FOR EACH ROW EXECUTE FUNCTION update_comment_likes_count();

-- Update comment replies_count
CREATE OR REPLACE FUNCTION update_comment_replies_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.parent_comment_id IS NOT NULL THEN
        UPDATE post_comments SET replies_count = replies_count + 1 WHERE id = NEW.parent_comment_id;
    ELSIF TG_OP = 'DELETE' AND OLD.parent_comment_id IS NOT NULL THEN
        UPDATE post_comments SET replies_count = GREATEST(0, replies_count - 1) WHERE id = OLD.parent_comment_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_comment_replies_count
    AFTER INSERT OR DELETE ON post_comments
    FOR EACH ROW EXECUTE FUNCTION update_comment_replies_count();

-- Update post shares_count
CREATE OR REPLACE FUNCTION update_post_shares_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET shares_count = shares_count + 1, updated_at = NOW() WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET shares_count = GREATEST(0, shares_count - 1), updated_at = NOW() WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_post_shares_count
    AFTER INSERT OR DELETE ON post_shares
    FOR EACH ROW EXECUTE FUNCTION update_post_shares_count();

-- Update post saves_count
CREATE OR REPLACE FUNCTION update_post_saves_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET saves_count = saves_count + 1, updated_at = NOW() WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET saves_count = GREATEST(0, saves_count - 1), updated_at = NOW() WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_post_saves_count
    AFTER INSERT OR DELETE ON saved_posts
    FOR EACH ROW EXECUTE FUNCTION update_post_saves_count();

-- Update hashtag posts_count
CREATE OR REPLACE FUNCTION update_hashtag_posts_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE hashtags SET posts_count = posts_count + 1 WHERE id = NEW.hashtag_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE hashtags SET posts_count = GREATEST(0, posts_count - 1) WHERE id = OLD.hashtag_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_hashtag_posts_count
    AFTER INSERT OR DELETE ON post_hashtags
    FOR EACH ROW EXECUTE FUNCTION update_hashtag_posts_count();

-- Update hashtag followers_count
CREATE OR REPLACE FUNCTION update_hashtag_followers_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE hashtags SET followers_count = followers_count + 1 WHERE id = NEW.hashtag_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE hashtags SET followers_count = GREATEST(0, followers_count - 1) WHERE id = OLD.hashtag_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_hashtag_followers_count
    AFTER INSERT OR DELETE ON hashtag_followers
    FOR EACH ROW EXECUTE FUNCTION update_hashtag_followers_count();

-- Update user posts_count
CREATE OR REPLACE FUNCTION update_user_posts_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.is_published = TRUE THEN
        UPDATE users SET posts_count = posts_count + 1 WHERE id = NEW.user_id;
    ELSIF TG_OP = 'DELETE' AND OLD.is_published = TRUE THEN
        UPDATE users SET posts_count = GREATEST(0, posts_count - 1) WHERE id = OLD.user_id;
    ELSIF TG_OP = 'UPDATE' AND OLD.is_published != NEW.is_published THEN
        IF NEW.is_published = TRUE THEN
            UPDATE users SET posts_count = posts_count + 1 WHERE id = NEW.user_id;
        ELSE
            UPDATE users SET posts_count = GREATEST(0, posts_count - 1) WHERE id = NEW.user_id;
        END IF;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_user_posts_count
    AFTER INSERT OR DELETE OR UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_user_posts_count();

-- Update poll votes_count
CREATE OR REPLACE FUNCTION update_poll_votes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE polls SET total_votes = total_votes + 1 WHERE id = NEW.poll_id;
        UPDATE poll_options SET votes_count = votes_count + 1 WHERE id = NEW.option_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE polls SET total_votes = GREATEST(0, total_votes - 1) WHERE id = OLD.poll_id;
        UPDATE poll_options SET votes_count = GREATEST(0, votes_count - 1) WHERE id = OLD.option_id;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Vote changed
        UPDATE poll_options SET votes_count = GREATEST(0, votes_count - 1) WHERE id = OLD.option_id;
        UPDATE poll_options SET votes_count = votes_count + 1 WHERE id = NEW.option_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_poll_votes_count
    AFTER INSERT OR DELETE OR UPDATE ON poll_votes
    FOR EACH ROW EXECUTE FUNCTION update_poll_votes_count();

-- ============================================
-- FUNCTIONS: FULL-TEXT SEARCH
-- ============================================

-- Update search vector for posts
CREATE OR REPLACE FUNCTION update_post_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('english', COALESCE(NEW.content, '')), 'A');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_post_search_vector
    BEFORE INSERT OR UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_post_search_vector();

-- ============================================
-- FUNCTIONS: HELPER UTILITIES
-- ============================================

-- Get user's feed (posts from following + own posts)
CREATE OR REPLACE FUNCTION get_user_feed(user_uuid UUID, page_limit INT, page_offset INT)
RETURNS TABLE (
    post_id UUID,
    post_type VARCHAR(20),
    content TEXT,
    user_id UUID,
    published_at TIMESTAMP,
    likes_count INT,
    comments_count INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.post_type,
        p.content,
        p.user_id,
        p.published_at,
        p.likes_count,
        p.comments_count
    FROM posts p
    WHERE 
        p.is_published = TRUE 
        AND p.deleted_at IS NULL
        AND (
            -- Show public posts + own posts
            -- Note: Following filter will be added when relationships table exists
            p.visibility = 'public' OR
            p.user_id = user_uuid
        )
    ORDER BY p.published_at DESC
    LIMIT page_limit OFFSET page_offset;
END;
$$ LANGUAGE plpgsql;

-- Get trending hashtags (top 10 by posts in last 7 days)
CREATE OR REPLACE FUNCTION get_trending_hashtags(limit_count INT)
RETURNS TABLE (
    tag VARCHAR(100),
    posts_count INT,
    trending_score DECIMAL(10,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        h.tag,
        h.posts_count,
        h.trending_score
    FROM hashtags h
    ORDER BY h.trending_score DESC, h.posts_count DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Calculate trending score for hashtags (run daily via cron)
CREATE OR REPLACE FUNCTION calculate_hashtag_trending_scores()
RETURNS VOID AS $$
BEGIN
    UPDATE hashtags h
    SET 
        trending_score = (
            SELECT COUNT(*) * 10 + COALESCE(SUM(p.likes_count + p.comments_count), 0)
            FROM post_hashtags ph
            JOIN posts p ON ph.post_id = p.id
            WHERE ph.hashtag_id = h.id
            AND p.published_at >= NOW() - INTERVAL '7 days'
            AND p.deleted_at IS NULL
        ),
        last_trending_update = NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON TABLE posts IS 'Unified table for all content types: posts, polls, and articles';
COMMENT ON TABLE polls IS 'Interactive polls with multiple choice voting';
COMMENT ON TABLE articles IS 'Long-form rich text articles with SEO optimization';
COMMENT ON TABLE post_comments IS 'Nested comments system with 2-level threading';
COMMENT ON TABLE hashtags IS 'Hashtag discovery system with trending scores';

COMMENT ON COLUMN posts.post_type IS 'Content type: post (short), poll (interactive), article (long-form)';
COMMENT ON COLUMN posts.visibility IS 'Who can see: public (all), connections (followers), private (author only)';
COMMENT ON COLUMN posts.search_vector IS 'Full-text search vector for content';
COMMENT ON COLUMN polls.anonymous_votes IS 'Hide voter identities from results';
COMMENT ON COLUMN articles.slug IS 'URL-friendly identifier: /articles/my-article-title';
COMMENT ON COLUMN articles.read_time_minutes IS 'Estimated reading time (~200 words/minute)';

-- ============================================
-- MIGRATION COMPLETE
-- ============================================

SELECT 'Posts & Feed System migration completed successfully!' AS status;
SELECT 'Created tables: posts, polls, articles, comments, likes, shares, saved_posts, hashtags' AS info;
SELECT 'Run calculate_hashtag_trending_scores() daily via cron job' AS reminder;

