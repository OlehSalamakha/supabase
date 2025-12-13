-- MemoZen Database Initialization
-- This migration creates the core schema if it doesn't exist
-- Safe to run multiple times (idempotent)

-- Enable vector extension for embeddings
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;

-- Create notes table
CREATE TABLE IF NOT EXISTS public.notes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid(),
  input_tokens integer,
  output_tokens integer,
  reasoning_tokens integer,
  audio_duration integer,
  summary text,
  keywords jsonb,
  language_code text,
  transcript text,
  audio_path text,
  status smallint NOT NULL DEFAULT '0'::smallint,
  createdat timestamp with time zone NOT NULL DEFAULT (now() AT TIME ZONE 'utc'::text),
  title text NOT NULL DEFAULT ''::text,
  claimed_at timestamp with time zone,
  claimed_by text,
  CONSTRAINT notes_pkey PRIMARY KEY (id),
  CONSTRAINT notes_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- Add notes table to realtime publication (skip if already added)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND schemaname = 'public'
    AND tablename = 'notes'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notes;
  END IF;
END $$;

-- Create note_embeddings table
CREATE TABLE IF NOT EXISTS public.note_embeddings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  note_id uuid NOT NULL UNIQUE,
  user_id uuid NOT NULL,
  content text,
  embedding vector,
  CONSTRAINT note_embeddings_pkey PRIMARY KEY (id),
  CONSTRAINT note_embeddings_note_id_fkey FOREIGN KEY (note_id) REFERENCES public.notes(id)
);

-- Enable Row Level Security on notes table
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for notes (DROP IF EXISTS to avoid conflicts)
DROP POLICY IF EXISTS "Users can read their own notes" ON public.notes;
CREATE POLICY "Users can read their own notes"
ON public.notes
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own notes" ON public.notes;
CREATE POLICY "Users can insert their own notes"
ON public.notes
FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own notes" ON public.notes;
CREATE POLICY "Users can update their own notes"
ON public.notes
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own notes" ON public.notes;
CREATE POLICY "Users can delete their own notes"
ON public.notes
FOR DELETE
USING (auth.uid() = user_id);

-- Create storage bucket
INSERT INTO storage.buckets (id, name)
VALUES ('memozen', 'memozen')
ON CONFLICT (id) DO NOTHING;

-- helper: first path segment from object name
-- split_part('user1/foo/bar.jpg', '/', 1) = 'user1'

DROP POLICY IF EXISTS "memozen_select_own" ON storage.objects;
CREATE POLICY "memozen_select_own"
ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id = 'memozen'
  AND auth.uid()::text = split_part(name, '/', 1)
);

DROP POLICY IF EXISTS "memozen_insert_own" ON storage.objects;
CREATE POLICY "memozen_insert_own"
ON storage.objects
FOR INSERT
TO public
WITH CHECK (
  bucket_id = 'memozen'
  AND auth.uid()::text = split_part(name, '/', 1)
);

DROP POLICY IF EXISTS "memozen_update_own" ON storage.objects;
CREATE POLICY "memozen_update_own"
ON storage.objects
FOR UPDATE
TO public
USING (
  bucket_id = 'memozen'
  AND auth.uid()::text = split_part(name, '/', 1)
);

DROP POLICY IF EXISTS "memozen_delete_own" ON storage.objects;
CREATE POLICY "memozen_delete_own"
ON storage.objects
FOR DELETE
TO public
USING (
  bucket_id = 'memozen'
  AND auth.uid()::text = split_part(name, '/', 1)
);