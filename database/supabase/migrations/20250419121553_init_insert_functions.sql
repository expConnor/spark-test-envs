
-- Insert Instagram Data ============================================================

CREATE OR REPLACE FUNCTION creators.insert_instagram_data(
  account_images jsonb DEFAULT NULL,
  account_stats jsonb DEFAULT NULL,
  post_details jsonb DEFAULT NULL,
  post_stats jsonb DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = creators
AS $$
DECLARE
  account_image record;
  account_stat record;
  post_detail record;
  post_stat record;
  account_exists boolean;
  post_exists boolean;
BEGIN
  -- 1. Process account images (only update if image_url is null)
  IF account_images IS NOT NULL THEN
    FOR account_image IN SELECT * FROM jsonb_to_recordset(account_images)
      AS x(account_id text, image_url text)
    LOOP
      -- Check if account exists and get creator_id
      SELECT EXISTS (
        SELECT 1 FROM instagram_account_db
        WHERE account_id = account_image.account_id::bigint
      ) INTO account_exists;

      IF account_exists THEN
        -- Update creator_db image_url if it's null
        UPDATE creators.creator_db cd
        SET image_url_cdn = account_image.image_url
        FROM instagram_account_db iad
        WHERE iad.account_id = account_image.account_id::bigint
          AND cd.creator_id = iad.creator_id
          AND cd.image_url_cdn IS NULL;
      END IF;
    END LOOP;
  END IF;

  -- 2. Process account stats
  IF account_stats IS NOT NULL THEN
    FOR account_stat IN SELECT * FROM jsonb_to_recordset(account_stats)
      AS x(account_id text, follower_count int, post_count int, timestamp text)
    LOOP
      SELECT EXISTS (
        SELECT 1 FROM instagram_account_db
        WHERE account_id = account_stat.account_id::bigint
      ) INTO account_exists;

      IF account_exists THEN
        BEGIN
          INSERT INTO instagram_account_metrics (
            account_id, follower_count, post_count, timestamp
          ) VALUES (
            account_stat.account_id::bigint,
            account_stat.follower_count,
            account_stat.post_count,
            account_stat.timestamp::timestamp
          );
        EXCEPTION WHEN unique_violation THEN
          NULL; -- Ignore duplicates
        END;
      END IF;
    END LOOP;
  END IF;

  -- 3. Process post details
   IF post_details IS NOT NULL THEN
    FOR post_detail IN SELECT * FROM jsonb_to_recordset(post_details)
      AS x(post_id text, account_id text, created_at text, media_type text,
           post_caption text, image_url text, video_duration numeric, post_url text)
    LOOP
      -- Check if account exists
      SELECT EXISTS (
        SELECT 1 FROM instagram_account_db
        WHERE account_id = post_detail.account_id::bigint
      ) INTO account_exists;
      
      -- Check if post already exists
      SELECT EXISTS (
        SELECT 1 FROM instagram_post_db
        WHERE post_id = post_detail.post_id::bigint
      ) INTO post_exists;

      IF account_exists AND NOT post_exists THEN
        INSERT INTO instagram_post_db (
          post_id, account_id, created_at, media_type, post_caption,
          image_url_cdn, video_duration, post_url
        ) VALUES (
          post_detail.post_id::bigint,
          post_detail.account_id::bigint,
          post_detail.created_at::timestamp,
          post_detail.media_type,
          post_detail.post_caption,
          post_detail.image_url,
          post_detail.video_duration,
          post_detail.post_url
        );
      END IF;
    END LOOP;
  END IF;

  -- 4. Process post stats
  IF post_stats IS NOT NULL THEN
    FOR post_stat IN SELECT * FROM jsonb_to_recordset(post_stats)
      AS x(post_id text, like_count int, comment_count int, play_count int, timestamp text)
    LOOP
      SELECT EXISTS (
        SELECT 1 FROM instagram_post_db
        WHERE post_id = post_stat.post_id::bigint
      ) INTO post_exists;

      IF post_exists THEN
        BEGIN
          INSERT INTO instagram_post_metrics (
            post_id, like_count, comment_count, play_count, timestamp
          ) VALUES (
            post_stat.post_id::bigint,
            post_stat.like_count,
            post_stat.comment_count,
            post_stat.play_count,
            post_stat.timestamp::timestamp
          );
        EXCEPTION WHEN unique_violation THEN
          NULL; -- Ignore duplicates
        END;
      END IF;
    END LOOP;
  END IF;
END;
$$;

-- Insert Tiktok Data ============================================================


CREATE OR REPLACE FUNCTION creators.insert_tiktok_data(
  account_images jsonb DEFAULT NULL,
  account_stats jsonb DEFAULT NULL,
  post_details jsonb DEFAULT NULL,
  post_stats jsonb DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = creators
AS $$
DECLARE
  account_image record;
  account_stat record;
  post_detail record;
  post_stat record;
  account_exists boolean;
  post_exists boolean;
BEGIN
  -- 1. Process account images (only update if image_url is null)
  IF account_images IS NOT NULL THEN
    FOR account_image IN SELECT * FROM jsonb_to_recordset(account_images)
      AS x(account_id text, image_url text)
    LOOP
      -- Check if account exists and get creator_id
      SELECT EXISTS (
        SELECT 1 FROM tiktok_account_db
        WHERE account_id = account_image.account_id::bigint
      ) INTO account_exists;

      IF account_exists THEN
        -- Update creator_db image_url if it's null
        UPDATE creators.creator_db cd
        SET image_url_cdn = account_image.image_url
        FROM tiktok_account_db iad
        WHERE iad.account_id = account_image.account_id::bigint
          AND cd.creator_id = iad.creator_id
          AND cd.image_url_cdn IS NULL;
      END IF;
    END LOOP;
  END IF;

  -- 2. Process account stats
  IF account_stats IS NOT NULL THEN
    FOR account_stat IN SELECT * FROM jsonb_to_recordset(account_stats)
      AS x(account_id text, follower_count int, post_count int, timestamp text)
    LOOP
      SELECT EXISTS (
        SELECT 1 FROM tiktok_account_db
        WHERE account_id = account_stat.account_id::bigint
      ) INTO account_exists;

      IF account_exists THEN
        BEGIN
          INSERT INTO tiktok_account_metrics (
            account_id, follower_count, post_count, timestamp
          ) VALUES (
            account_stat.account_id::bigint,
            account_stat.follower_count,
            account_stat.post_count,
            account_stat.timestamp::timestamp
          );
        EXCEPTION WHEN unique_violation THEN
          NULL; -- Ignore duplicates
        END;
      END IF;
    END LOOP;
  END IF;

  -- 3. Process post details
   IF post_details IS NOT NULL THEN
    FOR post_detail IN SELECT * FROM jsonb_to_recordset(post_details)
      AS x(post_id text, account_id text, created_at text, media_type text,
           post_caption text, image_url text, video_duration numeric, post_url text)
    LOOP
      -- Check if account exists
      SELECT EXISTS (
        SELECT 1 FROM tiktok_account_db
        WHERE account_id = post_detail.account_id::bigint
      ) INTO account_exists;
      
      -- Check if post already exists
      SELECT EXISTS (
        SELECT 1 FROM tiktok_post_db
        WHERE post_id = post_detail.post_id::bigint
      ) INTO post_exists;

      IF account_exists AND NOT post_exists THEN
        INSERT INTO tiktok_post_db (
          post_id, account_id, created_at, media_type, post_caption,
          image_url_cdn, video_duration, post_url
        ) VALUES (
          post_detail.post_id::bigint,
          post_detail.account_id::bigint,
          post_detail.created_at::timestamp,
          post_detail.media_type,
          post_detail.post_caption,
          post_detail.image_url,
          post_detail.video_duration,
          post_detail.post_url
        );
      END IF;
    END LOOP;
  END IF;

  -- 4. Process post stats
  IF post_stats IS NOT NULL THEN
    FOR post_stat IN SELECT * FROM jsonb_to_recordset(post_stats)
      AS x(post_id text, like_count int, comment_count int, play_count int, 
          share_count int, bookmark_count int, timestamp text)
    LOOP
      SELECT EXISTS (
        SELECT 1 FROM tiktok_post_db
        WHERE post_id = post_stat.post_id::bigint
      ) INTO post_exists;

      IF post_exists THEN
        BEGIN
          INSERT INTO tiktok_post_metrics (
            post_id, like_count, comment_count, play_count,
            share_count, bookmark_count, timestamp
          ) VALUES (
            post_stat.post_id::bigint,
            post_stat.like_count,
            post_stat.comment_count,
            post_stat.play_count,
            post_stat.share_count,
            post_stat.bookmark_count,
            post_stat.timestamp::timestamp
          );
        EXCEPTION WHEN unique_violation THEN
          NULL; -- Ignore duplicates
        END;
      END IF;
    END LOOP;
  END IF;
END;
$$;


-- Insert Fanfix and OnlyFans Data ==================================================

-- Wrapper function to execute SQL scripts that are stored in the utils.fanfix_onlyfans_data_scripts table

CREATE OR REPLACE FUNCTION utils.insert_fanfix_onlyfans_data(
  p_sql_script text,
  p_data jsonb DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSONB;
BEGIN
  EXECUTE p_sql_script
  USING p_data
  INTO result;

  -- Return success + result
  RETURN jsonb_build_object(
    'success', TRUE,
    'message', 'Script executed successfully',
    'data', COALESCE(result, '{}'::JSONB)
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', FALSE,
      'message', SQLERRM,
      'data', NULL
    );
END;
$$;
