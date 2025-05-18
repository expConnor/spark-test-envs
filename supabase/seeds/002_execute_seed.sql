-- Section 1: Generate random name combinations and insert into creator_db
WITH first_names AS (
    SELECT DISTINCT name FROM unnest('{
        Alice, Amelia, Aria, Ava, Bella, Charlotte, Chloe, Claire, Diana, Ellie, Emma, Evelyn, Fiona, Grace, 
        Hannah, Harper, Hazel, Isabella, Jane, Jasmine, Julia, Laura, Layla, Lily, Luna, Mia, Mila, Nancy, 
        Nora, Olivia, Penelope, Rachel, Rose, Ruby, Sadie, Scarlett, Sophia, Tara, Victoria, Violet, Wendy, 
        Yvonne, Zoe, Sophia, Abigail, Madeline, Eleanor, Delilah
    }'::text[]) AS name
),
last_names AS (
    SELECT unnest('{
        Adams, Allen, Anderson, Bailey, Baker, Barnes, Bell, Bennett, Brooks, Brown, Campbell, Carter, Clark, 
        Collins, Cook, Cooper, Cox, Davis, Edwards, Evans, Garcia, Gonzalez, Gray, Green, Hall, Harris, Hernandez, 
        Hill, Howard, Jackson, James, Johnson, Jones, Kelly, King, Lee, Lewis, Lopez, Martin, Martinez, Miller, 
        Mitchell, Moore, Morgan, Nelson, Parker, Perez, Peterson, Phillips, Price
    }'::text[]) AS name
),
all_combinations AS (
    SELECT f.name || ' ' || l.name AS full_name FROM first_names f CROSS JOIN last_names l
),
name_combinations AS (
    SELECT full_name FROM all_combinations ORDER BY random() LIMIT 200
)
INSERT INTO creators.creator_db (full_name, image_url, image_url_cdn)
SELECT 
    full_name,
    'https://randomuser.me/api/portraits/women/' || FLOOR(random() * 99 + 1)::int || '.jpg' AS image_url,
    NULL
FROM name_combinations
ON CONFLICT (full_name) DO NOTHING;

-- Section 2: Insert Instagram accounts
WITH creator_data AS (
    SELECT 
        creator_id, 
        full_name,
        lower(replace(full_name, ' ', '_')) AS base_username
    FROM creators.creator_db
    ORDER BY creator_id
    LIMIT 200
)
INSERT INTO creators.instagram_account_db (account_id, creator_id, username, account_url, active)
SELECT 
    (1000000 + (row_number() OVER () * 1000)) AS account_id,
    c.creator_id, 
    c.base_username || '_ig' AS username,
    'https://www.instagram.com/instagram',
    true
FROM creator_data c;

-- Section 3: Insert TikTok accounts
WITH creator_data AS (
    SELECT 
        creator_id, 
        full_name,
        lower(replace(full_name, ' ', '_')) AS base_username
    FROM creators.creator_db
    ORDER BY creator_id
    LIMIT 200
)
INSERT INTO creators.tiktok_account_db (account_id, creator_id, username, account_url, active)
SELECT 
    (2000000 + (row_number() OVER () * 1000)) AS account_id,
    c.creator_id, 
    c.base_username || '_tt' AS username,
    'https://www.tiktok.com/@tiktok',
    true
FROM creator_data c;

-- Section 4: Insert Instagram posts
INSERT INTO creators.instagram_post_db (
    post_id, account_id, created_at, post_caption, media_type, image_url, image_url_cdn, video_duration, post_url, campaign_id, active
)
SELECT 
    (a.account_id + i) AS post_id,
    a.account_id,
    now() - (random() * interval '6 months') AS created_at,
    'Sample caption ' || i,
    CASE WHEN random() < 0.3 THEN 'video' ELSE 'image' END AS media_type,
    'https://picsum.photos/200/300',
    NULL,
    CASE WHEN random() < 0.3 THEN 30.0 ELSE NULL END AS video_duration,
    'https://www.instagram.com/instagram',
    NULL,
    true
FROM creators.instagram_account_db a
CROSS JOIN generate_series(1, 48) AS i;

-- Section 5: Insert TikTok posts
INSERT INTO creators.tiktok_post_db (
    post_id, account_id, created_at, post_caption, media_type, image_url, image_url_cdn, video_duration, post_url, campaign_id, active
)
SELECT 
    (a.account_id + i) AS post_id,
    a.account_id,
    now() - (random() * interval '6 months') AS created_at,
    'Sample caption ' || i,
    'video',
    '

https://picsum.photos/200/300',
    NULL,
    30.0,
    'https://www.tiktok.com/@tiktok',
    NULL,
    true
FROM creators.tiktok_account_db a
CROSS JOIN generate_series(1, 48) AS i;

-- Section 7: Insert Instagram account metrics
INSERT INTO creators.instagram_account_metrics (timestamp, account_id, follower_count, post_count)
SELECT 
    ts,
    a.account_id,
    GREATEST(
        0,
        150000 + SUM((
            10 * a.growth_rate + 
            (random() * (r.max_change - r.min_change) + r.min_change) +
            CASE WHEN random() < 0.005 THEN floor(random() * 40000) + 10000 ELSE 0 END
        )::integer) OVER (PARTITION BY a.account_id ORDER BY ts)
    ) AS follower_count,
    (SELECT COUNT(*) FROM creators.instagram_post_db p WHERE p.account_id = a.account_id AND p.created_at <= ts) AS post_count
FROM (SELECT account_id, -0.5 + random() * 5.5 AS growth_rate FROM creators.instagram_account_db) a
CROSS JOIN generate_series(now() - interval '6 months', now(), interval '1 day') AS ts
CROSS JOIN LATERAL (
    SELECT r.min_change, r.max_change
    FROM public.follower_change_ranges r
    WHERE r.range_id = (abs(hashtext(a.account_id::text || ts::text)) % 7) + 1
) r;

-- Section 8: Insert TikTok account metrics
INSERT INTO creators.tiktok_account_metrics (timestamp, account_id, follower_count, post_count)
SELECT 
    ts,
    a.account_id,
    GREATEST(
        0,
        150000 + SUM((
            10 * a.growth_rate + 
            (random() * (r.max_change - r.min_change) + r.min_change) +
            CASE WHEN random() < 0.005 THEN floor(random() * 40000) + 10000 ELSE 0 END
        )::integer) OVER (PARTITION BY a.account_id ORDER BY ts)
    ) AS follower_count,
    (SELECT COUNT(*) FROM creators.tiktok_post_db p WHERE p.account_id = a.account_id AND p.created_at <= ts) AS post_count
FROM (SELECT account_id, -0.5 + random() * 5.5 AS growth_rate FROM creators.tiktok_account_db) a
CROSS JOIN generate_series(now() - interval '6 months', now(), interval '1 day') AS ts
CROSS JOIN LATERAL (
    SELECT r.min_change, r.max_change
    FROM public.follower_change_ranges r
    WHERE r.range_id = (abs(hashtext(a.account_id::text || ts::text)) % 7) + 1
) r;

-- Section 9: Insert Instagram post metrics
INSERT INTO creators.instagram_post_metrics (post_id, like_count, comment_count, play_count, timestamp)
SELECT 
    p.post_id,
    FLOOR(p.like_base * a.growth_rate * LN(1 + EXTRACT(EPOCH FROM (ts - p.created_at))/86400)) AS like_count,
    FLOOR(p.comment_base * a.growth_rate * LN(1 + EXTRACT(EPOCH FROM (ts - p.created_at))/86400)) AS comment_count,
    CASE WHEN p.media_type = 'video' THEN 
        FLOOR(p.play_base * a.growth_rate * LN(1 + EXTRACT(EPOCH FROM (ts - p.created_at))/86400)) 
    ELSE NULL END AS play_count,
    ts
FROM (
    SELECT post_id, created_at, media_type, 100 + (random() * 900) AS like_base,
           5 + (random() * 25) AS comment_base, 5000 + (random() * 5000) AS play_base,
           random() < 0.02 AS is_viral
    FROM creators.instagram_post_db
) p
CROSS JOIN LATERAL (
    SELECT CASE WHEN p.is_viral THEN 10 + random() * 40 ELSE 0.5 + random() * 1.5 END AS growth_rate
) a
CROSS JOIN LATERAL public.generate_post_metric_timestamps(p.created_at, now()) AS ts
WHERE FLOOR(p.like_base * a.growth_rate * LN(1 + EXTRACT(EPOCH FROM (ts - p.created_at))/86400)) >= 0
  AND FLOOR(p.comment_base * a.growth_rate * LN(1 + EXTRACT(EPOCH FROM (ts - p.created_at))/86400)) >= 0
  AND (p.media_type != 'video' OR FLOOR(p.play_base * a.growth_rate * LN(1 + EXTRACT(EPOCH FROM (ts - p.created_at))/86400)) >= 0);

-- Section 10: Insert TikTok post metrics
INSERT INTO creators.tiktok_post_metrics (post_id, like_count, comment_count, play_count, share_count, bookmark_count, timestamp)
SELECT 
    p.post_id,
    FLOOR(p.like_base * a.growth_rate * LN(1 + EXTRACT(EPOCH FROM (ts - p.created_at))/86400)) AS like_count,
    FLOOR(p.comment_base * a.growth_rate * LN(1 + EXTRACT(EPOCH FROM (ts - p.created_at))/86400)) AS comment_count,
    FLOOR(p.play_base * a.growth_rate * LN(1 + EXTRACT(EPOCH FROM (ts - p.created_at))/86400)) AS play_count,
    FLOOR(p.share_base * a.growth_rate * LN(1 + EXTRACT(EPOCH FROM (ts - p.created_at))/86400)) AS share_count,
    FLOOR(p.bookmark_base * a.growth_rate * LN(1 + EXTRACT(EPOCH FROM (ts - p.created_at))/86400)) AS bookmark_count,
    ts
FROM (
    SELECT post_id, created_at, 100 + (random() * 900) AS like_base, 5 + (random() * 35) AS comment_base,
           5000 + (random() * 10000) AS play_base, 5 + (random() * 25) AS share_base, 5 + (random() * 25) AS bookmark_base,
           random() < 0.03 AS is_viral
    FROM creators.tiktok_post_db
) p
CROSS JOIN LATERAL (
    SELECT CASE WHEN p.is_viral THEN 10 + random() * 40 ELSE 0.5 + random() * 1.5 END AS growth_rate
) a
CROSS JOIN LATERAL public.generate_post_metric_timestamps(p.created_at, now()) AS ts
WHERE FLOOR(p.like_base * a.growth_rate * LN(1 + EXTRACT(EPOCH FROM (ts - p.created_at))/86400)) >= 0
  AND FLOOR(p.comment_base * a.growth_rate * LN(1 + EXTRACT(EPOCH FROM (ts - p.created_at))/86400)) >= 0
  AND FLOOR(p.play_base * a.growth_rate * LN(1 + EXTRACT(EPOCH FROM (ts - p.created_at))/86400)) >= 0
  AND FLOOR(p.share_base * a.growth_rate * LN(1 + EXTRACT(EPOCH FROM (ts - p.created_at))/86400)) >= 0
  AND FLOOR(p.bookmark_base * a.growth_rate * LN(1 + EXTRACT(EPOCH FROM (ts - p.created_at))/86400)) >= 0;