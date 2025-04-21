BEGIN;
-- Plans the number of tests 
SELECT plan(42);


-- Set up the test environment ================================================

INSERT INTO creators.creator_db (creator_id, full_name)
VALUES (1000002, 'Test TikTok Creator') ON CONFLICT DO NOTHING;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM creators.tiktok_account_db WHERE account_id = 1003001
  ) THEN
    INSERT INTO creators.tiktok_account_db (account_id, creator_id, username, account_url, active)
    VALUES (
      1003001,
      (SELECT creator_id FROM creators.creator_db WHERE full_name = 'Test TikTok Creator' LIMIT 1),
      'test_tiktok_user',
      'http://tiktok.com/@test_tiktok_user',
      true
    );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM creators.tiktok_post_db WHERE post_id = 2004001
  ) THEN
    INSERT INTO creators.tiktok_post_db (post_id, account_id, created_at, post_url, media_type)
    VALUES (2004001, 1003001, '2025-04-21T12:00:00Z', 'http://tiktok.com/v/123', 'video');
  END IF;
END $$;

-- === Test Account Images ====================================================

-- Test 1: Valid account image insertion
SELECT lives_ok($$
  SELECT creators.insert_tiktok_data(
    account_images := '[{"account_id": "1003001", "image_url": "http://example.com/tiktok_image.jpg"}]'
  );
$$, 'Valid account image insertion executes without error');

-- Test 2: Verify image_url_cdn updated in creator_db
SELECT results_eq(
  'SELECT image_url_cdn FROM creators.creator_db WHERE creator_id = (SELECT creator_id FROM creators.tiktok_account_db WHERE account_id = 1003001)',
  'VALUES (''http://example.com/tiktok_image.jpg''::text)',
  'Account image updates image_url_cdn in creator_db'
);

-- Test 3: Account image insertion with null image_url (should not update)
UPDATE creators.creator_db
SET image_url_cdn = NULL
WHERE creator_id = (SELECT creator_id FROM creators.tiktok_account_db WHERE account_id = 1003001);
SELECT lives_ok($$
  SELECT creators.insert_tiktok_data(
    account_images := '[{"account_id": "1003001", "image_url": null}]'
  );
$$, 'Null image_url insertion executes');
SELECT results_eq(
  'SELECT image_url_cdn FROM creators.creator_db WHERE creator_id = (SELECT creator_id FROM creators.tiktok_account_db WHERE account_id = 1003001)',
  'VALUES (NULL::text)',
  'Null image_url does not update image_url_cdn'
);

-- Test 4: Account image for non-existent account (should skip)
SELECT lives_ok($$
  SELECT creators.insert_tiktok_data(
    account_images := '[{"account_id": "9999999", "image_url": "http://example.com/invalid.jpg"}]'
  );
$$, 'Non-existent account_id for image is skipped');
SELECT results_eq(
  'SELECT image_url_cdn FROM creators.creator_db WHERE creator_id = (SELECT creator_id FROM creators.tiktok_account_db WHERE account_id = 1003001)',
  'VALUES (NULL::text)',
  'Non-existent account_id does not update image_url_cdn'
);

-- Test 5: Multiple account images (one valid, one invalid)
SELECT lives_ok($$
  SELECT creators.insert_tiktok_data(
    account_images := '[
      {"account_id": "1003001", "image_url": "http://example.com/new_tiktok_image.jpg"},
      {"account_id": "9999999", "image_url": "http://example.com/invalid.jpg"}
    ]'
  );
$$, 'Multiple account images with one invalid executes');
SELECT results_eq(
  'SELECT image_url_cdn FROM creators.creator_db WHERE creator_id = (SELECT creator_id FROM creators.tiktok_account_db WHERE account_id = 1003001)',
  'VALUES (''http://example.com/new_tiktok_image.jpg''::text)',
  'Valid account image updates, invalid is skipped'
);

-- === Test Account Stats ===

-- Test 6: Valid account stats insertion
SELECT lives_ok($$
  SELECT creators.insert_tiktok_data(
    account_stats := '[{"account_id": "1003001", "follower_count": 1000, "post_count": 20, "timestamp": "2025-04-21T12:00:00Z"}]'
  );
$$, 'Valid account stats insertion executes');

-- Test 7: Verify account stats inserted
SELECT results_eq(
  'SELECT follower_count, post_count FROM creators.tiktok_account_metrics WHERE account_id = 1003001 AND timestamp = ''2025-04-21T12:00:00Z''',
  'VALUES (1000, 20)',
  'Account stats inserted correctly'
);

-- Test 8: Duplicate account stats (same account_id and timestamp)
SELECT lives_ok($$
  SELECT creators.insert_tiktok_data(
    account_stats := '[{"account_id": "1003001", "follower_count": 1100, "post_count": 21, "timestamp": "2025-04-21T12:00:00Z"}]'
  );
$$, 'Duplicate account stats is ignored');
SELECT results_eq(
  'SELECT follower_count FROM creators.tiktok_account_metrics WHERE account_id = 1003001 AND timestamp = ''2025-04-21T12:00:00Z''',
  'VALUES (1000)',
  'Duplicate account stats does not overwrite'
);

-- Test 9: Account stats for non-existent account (should skip)
SELECT lives_ok($$
  SELECT creators.insert_tiktok_data(
    account_stats := '[{"account_id": "9999999", "follower_count": 100, "post_count": 5, "timestamp": "2025-04-21T13:00:00Z"}]'
  );
$$, 'Non-existent account_id for stats is skipped');
SELECT results_eq(
  'SELECT count(*) FROM creators.tiktok_account_metrics WHERE account_id = 9999999',
  'VALUES (0::bigint)',
  'No stats inserted for non-existent account'
);

-- Test 10: Null values in account stats
SELECT lives_ok($$
  SELECT creators.insert_tiktok_data(
    account_stats := '[{"account_id": "1003001", "follower_count": null, "post_count": null, "timestamp": "2025-04-21T14:00:00Z"}]'
  );
$$, 'Null values in account stats executes');
SELECT results_eq(
  'SELECT follower_count IS NULL, post_count IS NULL FROM creators.tiktok_account_metrics WHERE account_id = 1003001 AND timestamp = ''2025-04-21T14:00:00Z''',
  'VALUES (true, true)',
  'Null values in account stats are inserted'
);

-- === Test Post Details ===

-- Test 11: Valid post details insertion
SELECT lives_ok($$
  SELECT creators.insert_tiktok_data(
    post_details := '[{
      "post_id": "2004002",
      "account_id": "1003001",
      "created_at": "2025-04-21T15:00:00Z",
      "media_type": "video",
      "post_caption": "Test TikTok",
      "image_url": "http://example.com/tiktok_post.jpg",
      "video_duration": 15.0,
      "post_url": "http://tiktok.com/v/456"
    }]'
  );
$$, 'Valid post details insertion executes');

-- Test 12: Verify post details inserted
SELECT results_eq(
  'SELECT media_type, post_caption, video_duration FROM creators.tiktok_post_db WHERE post_id = 2004002',
  'VALUES (''video''::text, ''Test TikTok''::text, 15.0::real)',
  'Post details inserted correctly'
);

-- Test 13: Post details for non-existent account (should skip)
SELECT lives_ok($$
  SELECT creators.insert_tiktok_data(
    post_details := '[{
      "post_id": "2004003",
      "account_id": "9999999",
      "created_at": "2025-04-21T16:00:00Z",
      "media_type": "video",
      "post_caption": "Invalid",
      "image_url": "http://example.com/invalid.jpg",
      "video_duration": 10.0,
      "post_url": "http://tiktok.com/v/789"
    }]'
  );
$$, 'Non-existent account_id for post details is skipped');
SELECT results_eq(
  'SELECT count(*) FROM creators.tiktok_post_db WHERE post_id = 2004003',
  'VALUES (0::bigint)',
  'No post inserted for non-existent account'
);

-- Test 14: Duplicate post_id (should skip)
SELECT lives_ok($$
  SELECT creators.insert_tiktok_data(
    post_details := '[{
      "post_id": "2004002",
      "account_id": "1003001",
      "created_at": "2025-04-21T15:00:00Z",
      "media_type": "video",
      "post_caption": "Duplicate",
      "image_url": "http://example.com/duplicate.jpg",
      "video_duration": 20.0,
      "post_url": "http://tiktok.com/v/456"
    }]'
  );
$$, 'Duplicate post_id is skipped');
SELECT results_eq(
  'SELECT video_duration FROM creators.tiktok_post_db WHERE post_id = 2004002',
  'VALUES (15.0::real)',
  'Duplicate post_id does not overwrite'
);

-- Test 15: Null values in post details
SELECT lives_ok($$
  SELECT creators.insert_tiktok_data(
    post_details := '[{
      "post_id": "2004004",
      "account_id": "1003001",
      "created_at": "2025-04-21T17:00:00Z",
      "media_type": "video",
      "post_caption": null,
      "image_url": null,
      "video_duration": null,
      "post_url": "http://tiktok.com/v/101"
    }]'
  );
$$, 'Null values in post details executes');
SELECT results_eq(
  'SELECT post_caption IS NULL, image_url IS NULL FROM creators.tiktok_post_db WHERE post_id = 2004004',
  'VALUES (true, true)',
  'Null values in post details are inserted'
);

-- === Test Post Stats ===

-- Test 16: Valid post stats insertion
SELECT lives_ok($$
  SELECT creators.insert_tiktok_data(
    post_stats := '[{
      "post_id": "2004001",
      "like_count": 200,
      "comment_count": 30,
      "play_count": 1000,
      "share_count": 50,
      "bookmark_count": 10,
      "timestamp": "2025-04-21T18:00:00Z"
    }]'
  );
$$, 'Valid post stats insertion executes');

-- Test 17: Verify post stats inserted
SELECT results_eq(
  'SELECT like_count, comment_count, play_count, share_count, bookmark_count FROM creators.tiktok_post_metrics WHERE post_id = 2004001 AND timestamp = ''2025-04-21T18:00:00Z''',
  'VALUES (200, 30, 1000, 50, 10)',
  'Post stats inserted correctly'
);

-- Test 18: Duplicate post stats (same post_id and timestamp)
SELECT lives_ok($$
  SELECT creators.insert_tiktok_data(
    post_stats := '[{
      "post_id": "2004001",
      "like_count": 300,
      "comment_count": 40,
      "play_count": 1200,
      "share_count": 60,
      "bookmark_count": 15,
      "timestamp": "2025-04-21T18:00:00Z"
    }]'
  );
$$, 'Duplicate post stats is ignored');
SELECT results_eq(
  'SELECT like_count FROM creators.tiktok_post_metrics WHERE post_id = 2004001 AND timestamp = ''2025-04-21T18:00:00Z''',
  'VALUES (200)',
  'Duplicate post stats does not overwrite'
);

-- Test 19: Post stats for non-existent post (should skip)
SELECT lives_ok($$
  SELECT creators.insert_tiktok_data(
    post_stats := '[{
      "post_id": "9999999",
      "like_count": 50,
      "comment_count": 10,
      "play_count": 100,
      "share_count": 5,
      "bookmark_count": 2,
      "timestamp": "2025-04-21T19:00:00Z"
    }]'
  );
$$, 'Non-existent post_id for stats is skipped');
SELECT results_eq(
  'SELECT count(*) FROM creators.tiktok_post_metrics WHERE post_id = 9999999',
  'VALUES (0::bigint)',
  'No stats inserted for non-existent post'
);

-- Test 20: Null values in post stats
SELECT lives_ok($$
  SELECT creators.insert_tiktok_data(
    post_stats := '[{
      "post_id": "2004001",
      "like_count": null,
      "comment_count": null,
      "play_count": null,
      "share_count": null,
      "bookmark_count": null,
      "timestamp": "2025-04-21T20:00:00Z"
    }]'
  );
$$, 'Null values in post stats executes');
SELECT results_eq(
  'SELECT like_count IS NULL, share_count IS NULL FROM creators.tiktok_post_metrics WHERE post_id = 2004001 AND timestamp = ''2025-04-21T20:00:00Z''',
  'VALUES (true, true)',
  'Null values in post stats are inserted'
);

-- === Combined Tests ===

-- Reset image_url_cdn to ensure combined test sets the expected value
UPDATE creators.creator_db
SET image_url_cdn = NULL
WHERE creator_id = (SELECT creator_id FROM creators.tiktok_account_db WHERE account_id = 1003001);

-- Test 21: All parameters together
SELECT lives_ok($$
  SELECT creators.insert_tiktok_data(
    account_images := '[{"account_id": "1003001", "image_url": "http://example.com/combined_tiktok.jpg"}]',
    account_stats := '[{"account_id": "1003001", "follower_count": 1200, "post_count": 22, "timestamp": "2025-04-21T21:00:00Z"}]',
    post_details := '[{
      "post_id": "2004005",
      "account_id": "1003001",
      "created_at": "2025-04-21T21:00:00Z",
      "media_type": "video",
      "post_caption": "Combined TikTok",
      "image_url": "http://example.com/combined_tiktok_post.jpg",
      "video_duration": 25.0,
      "post_url": "http://tiktok.com/v/111"
    }]',
    post_stats := '[{
      "post_id": "2004001",
      "like_count": 250,
      "comment_count": 35,
      "play_count": 1100,
      "share_count": 55,
      "bookmark_count": 12,
      "timestamp": "2025-04-21T21:00:00Z"
    }]'
  );
$$, 'All parameters together execute');

-- Test 22: Combined: image_url_cdn updated
SELECT results_eq(
  'SELECT image_url_cdn FROM creators.creator_db WHERE creator_id = (SELECT creator_id FROM creators.tiktok_account_db WHERE account_id = 1003001)',
  'VALUES (''http://example.com/combined_tiktok.jpg''::text)',
  'Combined: image_url_cdn updated'
);

-- Test 23: Combined: account stats inserted
SELECT results_eq(
  'SELECT follower_count FROM creators.tiktok_account_metrics WHERE account_id = 1003001 AND timestamp = ''2025-04-21T21:00:00Z''',
  'VALUES (1200)',
  'Combined: account stats inserted'
);

-- Test 24: Combined: post details inserted
SELECT results_eq(
  'SELECT media_type FROM creators.tiktok_post_db WHERE post_id = 2004005',
  'VALUES (''video''::text)',
  'Combined: post details inserted'
);

-- Test 25: Combined: post stats inserted
SELECT results_eq(
  'SELECT like_count FROM creators.tiktok_post_metrics WHERE post_id = 2004001 AND timestamp = ''2025-04-21T21:00:00Z''',
  'VALUES (250)',
  'Combined: post stats inserted'
);

-- === Additional TikTok-Specific Tests ===

-- Test 26: TikTok-specific fields (share_count, bookmark_count)
SELECT lives_ok($$
  SELECT creators.insert_tiktok_data(
    post_stats := '[{
      "post_id": "2004001",
      "like_count": 300,
      "comment_count": 40,
      "play_count": 1200,
      "share_count": 60,
      "bookmark_count": 15,
      "timestamp": "2025-04-21T22:00:00Z"
    }]'
  );
$$, 'TikTok-specific fields in post stats execute');
SELECT results_eq(
  'SELECT share_count, bookmark_count FROM creators.tiktok_post_metrics WHERE post_id = 2004001 AND timestamp = ''2025-04-21T22:00:00Z''',
  'VALUES (60, 15)',
  'TikTok-specific fields inserted correctly'
);

-- Test 27: Invalid JSONB structure for post_stats
SELECT throws_ok($$
  SELECT creators.insert_tiktok_data(
    post_stats := '[{"post_id": "2004001", "invalid_field": 100}]'
  );
$$, 'null value in column "timestamp" of relation "tiktok_post_metrics" violates not-null constraint',
    'Invalid JSONB structure for post_stats throws not-null constraint error');

-- Test 28: Empty JSONB arrays
SELECT lives_ok($$
  SELECT creators.insert_tiktok_data(
    account_images := '[]',
    account_stats := '[]',
    post_details := '[]',
    post_stats := '[]'
  );
$$, 'Empty JSONB arrays execute without error');
SELECT results_eq(
  'SELECT count(*) FROM creators.tiktok_account_metrics WHERE account_id = 1003001 AND timestamp = ''2025-04-21T23:00:00Z''',
  'VALUES (0::bigint)',
  'Empty JSONB arrays insert nothing'
);

-- Finish and rollback
SELECT * FROM finish();
ROLLBACK;