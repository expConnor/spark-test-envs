
-- Insert Fanfix and OnlyFans Data Scripts =========================================

INSERT INTO "utils"."fanfix_onlyfans_data_scripts" ("id", "script_name", "sql_code", "target_csv_file_name", "notes") VALUES 
('4', 'insert_ff_revenue', $$WITH validated_data AS (
  SELECT 
    item->>'CHARGE_DATE' AS charge_date,
    item->>'CREATOR_USERNAME' AS username,
    item->>'CREATOR_FANFIX_ID' AS fanfix_id,
    (item->>'TIP_NET_AMOUNT')::numeric(10,2) AS tips_revenue,
    (item->>'SUBSCRIPTION_NET_AMOUNT')::numeric(10,2) AS subs_revenue,
    (item->>'TOTAL_NET_AMOUNT')::numeric(10,2) AS total_revenue,
    -- Validation flags
    (item->>'CHARGE_DATE') IS NOT NULL AND (item->>'CHARGE_DATE')::date IS NOT NULL AS has_valid_date,
    (item->>'CREATOR_USERNAME') IS NOT NULL AS has_username,
    (item->>'CREATOR_FANFIX_ID') IS NOT NULL AS has_fanfix_id,
    (item->>'TIP_NET_AMOUNT') ~ '^\d+(\.\d{1,2})?$' AS has_valid_tips,
    (item->>'SUBSCRIPTION_NET_AMOUNT') ~ '^\d+(\.\d{1,2})?$' AS has_valid_subs,
    (item->>'TOTAL_NET_AMOUNT') ~ '^\d+(\.\d{1,2})?$' AS has_valid_total
  FROM jsonb_array_elements($1) AS item
),
account_mapping AS (
  SELECT 
    vd.*,
    fa.account_id
  FROM validated_data vd
  JOIN creators.fanfix_account_db fa ON vd.username = fa.username
  WHERE vd.has_valid_date 
    AND vd.has_username 
    AND vd.has_fanfix_id
    AND vd.has_valid_tips
    AND vd.has_valid_subs
    AND vd.has_valid_total
),
metrics_changes AS (
  INSERT INTO creators.fanfix_account_metrics (
    account_id,
    page_views,
    tips_revenue,
    subs_revenue,
    total_revenue,
    timestamp
  )
  SELECT 
    account_id,
    NULL, -- page_views not in CSV
    tips_revenue,
    subs_revenue,
    total_revenue,
    charge_date::timestamp with time zone
  FROM account_mapping
  ON CONFLICT (account_id, timestamp) DO UPDATE SET
    tips_revenue = EXCLUDED.tips_revenue,
    subs_revenue = EXCLUDED.subs_revenue,
    total_revenue = EXCLUDED.total_revenue
  RETURNING metric_id, 
    (xmax = 0) AS is_insert -- true if inserted, false if updated
)
SELECT jsonb_build_object(
  'total_rows', (SELECT COUNT(*) FROM jsonb_array_elements($1)),
  'valid_rows', (SELECT COUNT(*) FROM account_mapping),
  'new_rows_inserted', (SELECT COUNT(*) FROM metrics_changes WHERE is_insert),
  'existing_rows_updated', (SELECT COUNT(*) FROM metrics_changes WHERE NOT is_insert)
) AS result;$$, 'FF Revenue CSV', 'Inserts new data into the Database. Ignores already existing rows'), 

('7', 'insert_ff_pageviews', $$WITH validated_data AS (
  SELECT 
    item->>'DATE' AS timestamp,
    item->>'USERNAME' AS username,
    (item->>'PAGE_VISIT_COUNT')::integer AS page_views,
    -- Validation flags
    (item->>'DATE') IS NOT NULL AND (item->>'DATE')::date IS NOT NULL AS has_valid_date,
    (item->>'USERNAME') IS NOT NULL AS has_username,
    (item->>'PAGE_VISIT_COUNT') ~ '^\d+$' AS has_valid_page_views
  FROM jsonb_array_elements($1) AS item
),
account_mapping AS (
  SELECT 
    vd.*,
    fa.account_id
  FROM validated_data vd
  JOIN creators.fanfix_account_db fa ON vd.username = fa.username
  WHERE vd.has_valid_date 
    AND vd.has_username 
    AND vd.has_valid_page_views
),
metrics_changes AS (
  INSERT INTO creators.fanfix_account_metrics (
    account_id,
    page_views,
    timestamp
  )
  SELECT 
    account_id,
    page_views,
    timestamp::timestamp with time zone
  FROM account_mapping
  ON CONFLICT (account_id, timestamp) DO UPDATE SET
    page_views = EXCLUDED.page_views
  RETURNING metric_id, 
    (xmax = 0) AS is_insert -- true if inserted, false if updated
)
SELECT jsonb_build_object(
  'total_rows', (SELECT COUNT(*) FROM jsonb_array_elements($1)),
  'valid_rows', (SELECT COUNT(*) FROM account_mapping),
  'new_rows_inserted', (SELECT COUNT(*) FROM metrics_changes WHERE is_insert),
  'existing_rows_updated', (SELECT COUNT(*) FROM metrics_changes WHERE NOT is_insert)
) AS result;$$, 'FF Page Visit CSV', 'Adds Pageview stats to existing revenue stats '), 

('8', 'insert_of_data', $$WITH validated_data AS (
  SELECT 
    item->>'Creator' AS username,
    item->>'timestamp' AS timestamp_value,
    (item->>'New Subs')::integer AS new_subs,
    (item->>'Tips Revenue')::numeric(10,2) AS tips_revenue,
    (item->>'Message Revenue')::numeric(10,2) AS message_revenue,
    ((item->>'New Subs Revenue')::numeric(10,2) + (item->>'Rec. Subs Revenue')::numeric(10,2)) AS subs_revenue,
    (item->>'Total Revenue')::numeric(10,2) AS total_revenue,
    -- Validation flags
    (item->>'timestamp') IS NOT NULL AS has_valid_timestamp,
    (item->>'Creator') IS NOT NULL AS has_username,
    (item->>'New Subs') ~ '^\d+$' AS has_valid_new_subs,
    (item->>'Tips Revenue') ~ '^\d+(\.\d{1,2})?$' AS has_valid_tips,
    (item->>'Message Revenue') ~ '^\d+(\.\d{1,2})?$' AS has_valid_message_revenue,
    (item->>'New Subs Revenue') ~ '^\d+(\.\d{1,2})?$' AND 
    (item->>'Rec. Subs Revenue') ~ '^\d+(\.\d{1,2})?$' AS has_valid_subs,
    (item->>'Total Revenue') ~ '^\d+(\.\d{1,2})?$' AS has_valid_total
  FROM jsonb_array_elements($1) AS item
),
account_mapping AS (
  SELECT 
    vd.*,
    oa.account_id
  FROM validated_data vd
  JOIN creators.onlyfans_account_db oa ON vd.username = oa.username
  WHERE vd.has_valid_timestamp 
    AND vd.has_username 
    AND vd.has_valid_new_subs
    AND vd.has_valid_tips
    AND vd.has_valid_message_revenue
    AND vd.has_valid_subs
    AND vd.has_valid_total
),
metrics_changes AS (
  INSERT INTO creators.onlyfans_account_metrics (
    account_id,
    new_subs,
    tips_revenue,
    message_revenue,
    subs_revenue,
    total_revenue,
    timestamp
  )
  SELECT 
    account_id,
    new_subs,
    tips_revenue,
    message_revenue,
    subs_revenue,
    total_revenue,
    timestamp_value::timestamp with time zone
  FROM account_mapping
  ON CONFLICT (account_id, timestamp) DO UPDATE SET
    new_subs = EXCLUDED.new_subs,
    tips_revenue = EXCLUDED.tips_revenue,
    message_revenue = EXCLUDED.message_revenue,
    subs_revenue = EXCLUDED.subs_revenue,
    total_revenue = EXCLUDED.total_revenue
  RETURNING metric_id,
    (xmax = 0) AS is_insert -- true if inserted, false if updated
)
SELECT jsonb_build_object(
  'total_rows', (SELECT COUNT(*) FROM jsonb_array_elements($1)),
  'valid_rows', (SELECT COUNT(*) FROM account_mapping),
  'new_rows_inserted', (SELECT COUNT(*) FROM metrics_changes WHERE is_insert),
  'existing_rows_updated', (SELECT COUNT(*) FROM metrics_changes WHERE NOT is_insert)
) AS result;$$, 'Creatorhero daily CSV ', 'Inserts the new data from CH CSV');

