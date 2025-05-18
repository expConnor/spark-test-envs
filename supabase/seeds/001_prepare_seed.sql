-- Create helper function for generating post metric timestamps
CREATE OR REPLACE FUNCTION public.generate_post_metric_timestamps(start_time TIMESTAMPTZ, end_time TIMESTAMPTZ)
RETURNS TABLE (ts TIMESTAMPTZ) AS $$
DECLARE
    gap INT := 5;
BEGIN
    -- Generate timestamps at 12-hour intervals for the first 2.5 days
    FOR i IN 0..5 LOOP
        ts := start_time + (i * interval '12 hours');
        IF ts <= end_time THEN
            RETURN NEXT;
        END IF;
    END LOOP;
    -- Generate daily timestamps from day 4 to day 30
    FOR i IN 4..30 LOOP
        ts := start_time + (i * interval '1 day');
        IF ts <= end_time THEN
            RETURN NEXT;
        END IF;
    END LOOP;
    -- Generate timestamps with increasing gaps after 30 days
    ts := start_time + interval '30 days';
    WHILE ts <= end_time LOOP
        ts := ts + (gap * interval '1 day');
        RETURN NEXT;
        gap := gap + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Begin transaction for table creation and insertion
BEGIN;

-- Create table for follower change ranges if it doesn't exist
CREATE TABLE IF NOT EXISTS public.follower_change_ranges (
    range_id INT PRIMARY KEY,
    min_change INT NOT NULL,
    max_change INT NOT NULL
);

-- Insert follower change ranges only if the table is empty
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.follower_change_ranges) THEN
        INSERT INTO public.follower_change_ranges (range_id, min_change, max_change)
        VALUES
            (1, -200, -100),
            (2, -300, -100),
            (3, -100, 0),
            (4, -10, 10),
            (5, 200, 300),
            (6, 100, 400),
            (7, 500, 1000);
    END IF;
END $$;

COMMIT;