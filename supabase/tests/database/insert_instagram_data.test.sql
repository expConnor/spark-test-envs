BEGIN;
-- Plan the number of tests (37 tests covering all scenarios)
SELECT plan(37);

-- Setup: Insert prerequisite data for foreign key constraints, avoiding conflicts
-- Use ON CONFLICT DO NOTHING to skip if creator_id exists
INSERT INTO creators.creator_db (creator_id, full_name)
VALUES (1000001, 'Test Instagram Creator') ON CONFLICT DO NOTHING;

-- Get or insert an Instagram account, using a high account_id to avoid conflicts
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM creators.instagram_account_db WHERE account_id = 1001001
  ) THEN
    INSERT INTO creators.instagram_account_db (account_id, creator_id, username, account_url, active)
    VALUES (
      1001001,
      (SELECT creator_id FROM creators.creator_db WHERE full_name = 'Test Instagram Creator' LIMIT 1),
      'test_instagram_user',
      'http://instagram.com/test_instagram_user',
      true
    );
  END IF;
END $$;

-- Insert a post for post-related tests, if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM creators.instagram_post_db WHERE post_id = 2001001
  ) THEN
    INSERT INTO creators.instagram_post_db (post_id, account_id, created_at, post_url, media_type)
    VALUES (2001001, 1001001, '2025-04-21T12:00:00Z', 'http://instagram.com/p/123', 'image');
  END IF;
END $$;

-- === Test Account Images ===

-- Test 1: Valid account image insertion
SELECT lives_ok($$
  SELECT creators.insert_instagram_data(
    account_images := '[{"account_id": "1001001", "image_url": "http://example.com/image.jpg"}]'
  );
$$, 'Valid account image insertion executes without error');

-- Test 2: Verify image_url_cdn updated in creator_db
SELECT results_eq(
  'SELECT image_url_cdn FROM creators.creator_db WHERE creator_id = (SELECT creator_id FROM creators.instagram_account_db WHERE account_id = 1001001)',
  'VALUES (''http://example.com/image.jpg''::text)',
  'Account image updates image_url_cdn in creator_db'
);

-- Test 3: Account image insertion with null image_url (should not update)
UPDATE creators.creator_db
SET image_url_cdn = NULL
WHERE creator_id = (SELECT creator_id FROM creators.instagram_account_db WHERE account_id = 1001001);
SELECT lives_ok($$
  SELECT creators.insert_instagram_data(
    account_images := '[{"account_id": "1001001", "image_url": null}]'
  );
$$, 'Null image_url insertion executes');
SELECT results_eq(
  'SELECT image_url_cdn FROM creators.creator_db WHERE creator_id = (SELECT creator_id FROM creators.instagram_account_db WHERE account_id = 1001001)',
  'VALUES (NULL::text)',
  'Null image_url does not update image_url_cdn'
);

-- Test 4: Account image for non-existent account (should skip)
SELECT lives_ok($$
  SELECT creators.insert_instagram_data(
    account_images := '[{"account_id": "9999999", "image_url": "http://example.com/invalid.jpg"}]'
  );
$$, 'Non-existent account_id for image is skipped');
SELECT results_eq(
  'SELECT image_url_cdn FROM creators.creator_db WHERE creator_id = (SELECT creator_id FROM creators.instagram_account_db WHERE account_id = 1001001)',
  'VALUES (NULL::text)',
  'Non-existent account_id does not update image_url_cdn'
);

-- Test 5: Multiple account images (one valid, one invalid)
SELECT lives_ok($$
  SELECT creators.insert_instagram_data(
    account_images := '[
      {"account_id": "1001001", "image_url": "http://example.com/new_image.jpg"},
      {"account_id": "9999999", "image_url": "http://example.com/invalid.jpg"}
    ]'
  );
$$, 'Multiple account images with one invalid executes');
SELECT results_eq(
  'SELECT image_url_cdn FROM creators.creator_db WHERE creator_id = (SELECT creator_id FROM creators.instagram_account_db WHERE account_id = 1001001)',
  'VALUES (''http://example.com/new_image.jpg''::text)',
  'Valid account image updates, invalid is skipped'
);

-- === Test Account Stats ===

-- Test 6: Valid account stats insertion
SELECT lives_ok($$
  SELECT creators.insert_instagram_data(
    account_stats := '[{"account_id": "1001001", "follower_count": 500, "post_count": 10, "timestamp": "2025-04-21T12:00:00Z"}]'
  );
$$, 'Valid account stats insertion executes');

-- Test 7: Verify account stats inserted
SELECT results_eq(
  'SELECT follower_count, post_count FROM creators.instagram_account_metrics WHERE account_id = 1001001 AND timestamp = ''2025-04-21T12:00:00Z''',
  'VALUES (500, 10)',
  'Account stats inserted correctly'
);

-- Test 8: Duplicate account stats (same account_id and timestamp)
SELECT lives_ok($$
  SELECT creators.insert_instagram_data(
    account_stats := '[{"account_id": "1001001", "follower_count": 600, "post_count": 11, "timestamp": "2025-04-21T12:00:00Z"}]'
  );
$$, 'Duplicate account stats is ignored');
SELECT results_eq(
  'SELECT follower_count FROM creators.instagram_account_metrics WHERE account_id = 1001001 AND timestamp = ''2025-04-21T12:00:00Z''',
  'VALUES (500)',
  'Duplicate account stats does not overwrite'
);

-- Test 9: Account stats for non-existent account (should skip)
SELECT lives_ok($$
  SELECT creators.insert_instagram_data(
    account_stats := '[{"account_id": "9999999", "follower_count": 100, "post_count": 5, "timestamp": "2025-04-21T13:00:00Z"}]'
  );
$$, 'Non-existent account_id for stats is skipped');
SELECT results_eq(
  'SELECT count(*) FROM creators.instagram_account_metrics WHERE account_id = 9999999',
  'VALUES (0::bigint)',
  'No stats inserted for non-existent account'
);

-- Test 10: Null values in account stats
SELECT lives_ok($$
  SELECT creators.insert_instagram_data(
    account_stats := '[{"account_id": "1001001", "follower_count": null, "post_count": null, "timestamp": "2025-04-21T14:00:00Z"}]'
  );
$$, 'Null values in account stats executes');
SELECT results_eq(
  'SELECT follower_count IS NULL, post_count IS NULL FROM creators.instagram_account_metrics WHERE account_id = 1001001 AND timestamp = ''2025-04-21T14:00:00Z''',
  'VALUES (true, true)',
  'Null values in account stats are inserted'
);

-- === Test Post Details ===

-- Test 11: Valid post details insertion
SELECT lives_ok($$
  SELECT creators.insert_instagram_data(
    post_details := '[{
      "post_id": "2001002",
      "account_id": "1001001",
      "created_at": "2025-04-21T15:00:00Z",
      "media_type": "video",
      "post_caption": "Test post",
      "image_url": "http://example.com/post.jpg",
      "video_duration": 30.5,
      "post_url": "http://instagram.com/p/456"
    }]'
  );
$$, 'Valid post details insertion executes');

-- Test 12: Verify post details inserted
SELECT results_eq(
  'SELECT media_type, post_caption, video_duration FROM creators.instagram_post_db WHERE post_id = 2001002',
  'VALUES (''video''::text, ''Test post''::text, 30.5::real)',
  'Post details inserted correctly'
);

-- Test 13: Post details for non-existent account (should skip)
SELECT lives_ok($$
  SELECT creators.insert_instagram_data(
    post_details := '[{
      "post_id": "2001003",
      "account_id": "9999999",
      "created_at": "2025-04-21T16:00:00Z",
      "media_type": "image",
      "post_caption": "Invalid",
      "image_url": "http://example.com/invalid.jpg",
      "video_duration": null,
      "post_url": "http://instagram.com/p/789"
    }]'
  );
$$, 'Non-existent account_id for post details is skipped');
SELECT results_eq(
  'SELECT count(*) FROM creators.instagram_post_db WHERE post_id = 2001003',
  'VALUES (0::bigint)',
  'No post inserted for non-existent account'
);

-- Test 14: Duplicate post_id (should skip)
SELECT lives_ok($$
  SELECT creators.insert_instagram_data(
    post_details := '[{
      "post_id": "2001002",
      "account_id": "1001001",
      "created_at": "2025-04-21T15:00:00Z",
      "media_type": "image",
      "post_caption": "Duplicate",
      "image_url": "http://example.com/duplicate.jpg",
      "video_duration": null,
      "post_url": "http://instagram.com/p/456"
    }]'
  );
$$, 'Duplicate post_id is skipped');
SELECT results_eq(
  'SELECT media_type FROM creators.instagram_post_db WHERE post_id = 2001002',
  'VALUES (''video''::text)',
  'Duplicate post_id does not overwrite'
);

-- Test 15: Null values in post details
SELECT lives_ok($$
  SELECT creators.insert_instagram_data(
    post_details := '[{
      "post_id": "2001004",
      "account_id": "1001001",
      "created_at": "2025-04-21T17:00:00Z",
      "media_type": null,
      "post_caption": null,
      "image_url": null,
      "video_duration": null,
      "post_url": "http://instagram.com/p/101"
    }]'
  );
$$, 'Null values in post details executes');
SELECT results_eq(
  'SELECT media_type IS NULL, post_caption IS NULL FROM creators.instagram_post_db WHERE post_id = 2001004',
  'VALUES (true, true)',
  'Null values in post details are inserted'
);

-- === Test Post Stats ===

-- Test 16: Valid post stats insertion
SELECT lives_ok($$
  SELECT creators.insert_instagram_data(
    post_stats := '[{"post_id": "2001001", "like_count": 100, "comment_count": 20, "play_count": 500, "timestamp": "2025-04-21T18:00:00Z"}]'
  );
$$, 'Valid post stats insertion executes');

-- Test 17: Verify post stats inserted
SELECT results_eq(
  'SELECT like_count, comment_count, play_count FROM creators.instagram_post_metrics WHERE post_id = 2001001 AND timestamp = ''2025-04-21T18:00:00Z''',
  'VALUES (100, 20, 500)',
  'Post stats inserted correctly'
);

-- Test 18: Duplicate post stats (same post_id and timestamp)
SELECT lives_ok($$
  SELECT creators.insert_instagram_data(
    post_stats := '[{"post_id": "2001001", "like_count": 200, "comment_count": 30, "play_count": 600, "timestamp": "2025-04-21T18:00:00Z"}]'
  );
$$, 'Duplicate post stats is ignored');
SELECT results_eq(
  'SELECT like_count FROM creators.instagram_post_metrics WHERE post_id = 2001001 AND timestamp = ''2025-04-21T18:00:00Z''',
  'VALUES (100)',
  'Duplicate post stats does not overwrite'
);

-- Test 19: Post stats for non-existent post (should skip)
SELECT lives_ok($$
  SELECT creators.insert_instagram_data(
    post_stats := '[{"post_id": "9999999", "like_count": 50, "comment_count": 10, "play_count": 100, "timestamp": "2025-04-21T19:00:00Z"}]'
  );
$$, 'Non-existent post_id for stats is skipped');
SELECT results_eq(
  'SELECT count(*) FROM creators.instagram_post_metrics WHERE post_id = 9999999',
  'VALUES (0::bigint)',
  'No stats inserted for non-existent post'
);

-- Test 20: Null values in post stats
SELECT lives_ok($$
  SELECT creators.insert_instagram_data(
    post_stats := '[{"post_id": "2001001", "like_count": null, "comment_count": null, "play_count": null, "timestamp": "2025-04-21T20:00:00Z"}]'
  );
$$, 'Null values in post stats executes');
SELECT results_eq(
  'SELECT like_count IS NULL, comment_count IS NULL FROM creators.instagram_post_metrics WHERE post_id = 2001001 AND timestamp = ''2025-04-21T20:00:00Z''',
  'VALUES (true, true)',
  'Null values in post stats are inserted'
);

-- === Combined Tests ===

-- Reset image_url_cdn to ensure combined test sets the expected value
UPDATE creators.creator_db
SET image_url_cdn = NULL
WHERE creator_id = (SELECT creator_id FROM creators.instagram_account_db WHERE account_id = 1001001);

-- Test 21: All parameters together
SELECT lives_ok($$
  SELECT creators.insert_instagram_data(
    account_images := '[{"account_id": "1001001", "image_url": "http://example.com/combined.jpg"}]',
    account_stats := '[{"account_id": "1001001", "follower_count": 600, "post_count": 12, "timestamp": "2025-04-21T21:00:00Z"}]',
    post_details := '[{
      "post_id": "2001005",
      "account_id": "1001001",
      "created_at": "2025-04-21T21:00:00Z",
      "media_type": "image",
      "post_caption": "Combined",
      "image_url": "http://example.com/combined_post.jpg",
      "video_duration": null,
      "post_url": "http://instagram.com/p/111"
    }]',
    post_stats := '[{"post_id": "2001001", "like_count": 150, "comment_count": 25, "play_count": 700, "timestamp": "2025-04-21T21:00:00Z"}]'
  );
$$, 'All parameters together execute');

-- Test 22: Combined: image_url_cdn updated
SELECT results_eq(
  'SELECT image_url_cdn FROM creators.creator_db WHERE creator_id = (SELECT creator_id FROM creators.instagram_account_db WHERE account_id = 1001001)',
  'VALUES (''http://example.com/combined.jpg''::text)',
  'Combined: image_url_cdn updated'
);

-- Test 23: Combined: account stats inserted
SELECT results_eq(
  'SELECT follower_count FROM creators.instagram_account_metrics WHERE account_id = 1001001 AND timestamp = ''2025-04-21T21:00:00Z''',
  'VALUES (600)',
  'Combined: account stats inserted'
);

-- Test 24: Combined: post details inserted
SELECT results_eq(
  'SELECT media_type FROM creators.instagram_post_db WHERE post_id = 2001005',
  'VALUES (''image''::text)',
  'Combined: post details inserted'
);

-- Test 25: Combined: post stats inserted
SELECT results_eq(
  'SELECT like_count FROM creators.instagram_post_metrics WHERE post_id = 2001001 AND timestamp = ''2025-04-21T21:00:00Z''',
  'VALUES (150)',
  'Combined: post stats inserted'
);

-- Finish and rollback
SELECT * FROM finish();
ROLLBACK;
