-- Create subscription_events table for audit logging
-- This table tracks all subscription lifecycle events
CREATE TABLE IF NOT EXISTS public.subscription_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  event_type text NOT NULL,  -- 'initial_purchase', 'renewal', 'cancellation', 'expiration', 'reactivation'
  product_id text,           -- 'monthly', 'yearly', or 'free'
  seconds_granted integer,   -- Number of seconds granted with this event
  revenuecat_event_id text,  -- For deduplication of webhook events
  metadata jsonb,            -- Additional event data from RevenueCat
  created_at timestamptz DEFAULT now()
);

-- Add notes table to realtime publication (skip if already added)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND schemaname = 'public'
    AND tablename = 'subscription_events'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.subscription_events;
  END IF;
END $$;


-- Create index on user_id for user event history
CREATE INDEX IF NOT EXISTS idx_subscription_events_user_id ON public.subscription_events(user_id);

-- Create index on event_type for analytics
CREATE INDEX IF NOT EXISTS idx_subscription_events_type ON public.subscription_events(event_type);

-- Create index on created_at for time-series queries
CREATE INDEX IF NOT EXISTS idx_subscription_events_created_at ON public.subscription_events(created_at);

-- Create unique index on revenuecat_event_id for deduplication
CREATE UNIQUE INDEX IF NOT EXISTS idx_subscription_events_revenuecat_id
ON public.subscription_events(revenuecat_event_id)
WHERE revenuecat_event_id IS NOT NULL;

-- Enable Row Level Security on subscription_events table
ALTER TABLE public.subscription_events ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for subscription_events
DROP POLICY IF EXISTS "Users can read their own events" ON public.subscription_events;
CREATE POLICY "Users can read their own events"
ON public.subscription_events
FOR SELECT
USING (auth.uid() = user_id);
