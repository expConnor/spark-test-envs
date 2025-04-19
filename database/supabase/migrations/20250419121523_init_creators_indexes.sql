
-- Indexes for Instagram ----------------------------------------------------------

CREATE INDEX idx_instagram_account_metrics_time_range 
ON creators.instagram_account_metrics (account_id, timestamp DESC);

CREATE INDEX idx_instagram_post_db_account_time 
ON creators.instagram_post_db (account_id, created_at DESC);

CREATE INDEX idx_instagram_post_metrics_time_range 
ON creators.instagram_post_metrics (post_id, timestamp DESC);

-- Indexes for TikTok ----------------------------------------------------------------

CREATE INDEX idx_tiktok_account_metrics_time_range 
ON creators.tiktok_account_metrics (account_id, timestamp DESC);

CREATE INDEX idx_tiktok_post_db_account_time 
ON creators.tiktok_post_db (account_id, created_at DESC);

CREATE INDEX idx_tiktok_post_metrics_time_range 
ON creators.tiktok_post_metrics (post_id, timestamp DESC);

-- Indexes for Fanfix ----------------------------------------------------------------

CREATE INDEX idx_fanfix_account_metrics_time_range 
ON creators.fanfix_account_metrics (account_id, timestamp DESC);

-- Indexes for OnlyFans ------------------------------------------------------------

CREATE INDEX idx_onlyfans_account_metrics_time_range 
ON creators.onlyfans_account_metrics (account_id, timestamp DESC);