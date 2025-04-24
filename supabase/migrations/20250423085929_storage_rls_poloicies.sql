ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy: Allow everyone to read files in the media bucket
CREATE POLICY "Allow public reads" ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'images'
  );

-- Policy: Allow everyone to upload files to the media bucket
CREATE POLICY "Allow public uploads" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'images'
  );

-- Policy: Allow everyone to update files in the media bucket
CREATE POLICY "Allow public updates" ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'images'
  );

-- Policy: Allow everyone to delete files in the media bucket
CREATE POLICY "Allow public deletes" ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'images'
  );