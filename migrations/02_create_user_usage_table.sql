-- Create user_usage table for tracking audio processing seconds
-- This table stores available and used seconds for each user
CREATE TABLE IF NOT EXISTS public.user_usage (
  user_id uuid NOT NULL DEFAULT auth.uid(),
  available_seconds integer NOT NULL DEFAULT 0,
  used_seconds integer NOT NULL DEFAULT 0,
  CONSTRAINT user_usage_pkey PRIMARY KEY (user_id),
  CONSTRAINT user_usage_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Enable Row Level Security on user_usage table
ALTER TABLE public.user_usage ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for user_usage
DROP POLICY IF EXISTS "Users can read their own usage" ON public.user_usage;
CREATE POLICY "Users can read their own usage"
ON public.user_usage
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own usage" ON public.user_usage;
CREATE POLICY "Users can insert their own usage"
ON public.user_usage
FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own usage" ON public.user_usage;
CREATE POLICY "Users can update their own usage"
ON public.user_usage
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own usage" ON public.user_usage;
CREATE POLICY "Users can delete their own usage"
ON public.user_usage
FOR DELETE
USING (auth.uid() = user_id);
