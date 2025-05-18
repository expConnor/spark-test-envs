-- Drop the helper function used during seeding
DROP FUNCTION IF EXISTS public.generate_post_metric_timestamps(TIMESTAMPTZ, TIMESTAMPTZ);

-- Drop the follower change ranges table used during seeding
DROP TABLE IF EXISTS public.follower_change_ranges;