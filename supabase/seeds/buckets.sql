-- Create the 'media' bucket if it doesn't exist
INSERT INTO storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
) VALUES (
  'images',
  'images',
  true,
  52428800, -- 50MB in bytes
  ARRAY['image/png', 'image/jpeg', 'video/mp4']::varchar[]
) ON CONFLICT (id) DO NOTHING;