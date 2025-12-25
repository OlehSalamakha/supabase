-- Create subscriptions table for tracking RevenueCat subscriptions
-- This table stores active subscriptions and their renewal periods
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  revenuecat_subscriber_id text NOT NULL,
  product_id text NOT NULL,  -- 'monthly' or 'yearly'
  platform text NOT NULL,     -- 'ios' or 'android'
  status text NOT NULL,       -- 'active', 'cancelled', 'expired', 'paused'
  current_period_start timestamptz NOT NULL,  -- Subscription anniversary date
  current_period_end timestamptz NOT NULL,
  will_renew boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT subscriptions_user_id_unique UNIQUE(user_id)  -- One active subscription per user
);

-- Add notes table to realtime publication (skip if already added)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND schemaname = 'public'
    AND tablename = 'subscriptions'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.subscriptions;
  END IF;
END $$;


-- Create index on user_id for fast lookups
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON public.subscriptions(user_id);

-- Create index on current_period_end for finding expiring subscriptions
CREATE INDEX IF NOT EXISTS idx_subscriptions_period_end ON public.subscriptions(current_period_end);

-- Create index on status for filtering active subscriptions
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON public.subscriptions(status);

-- Enable Row Level Security on subscriptions table
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for subscriptions
DROP POLICY IF EXISTS "Users can read their own subscription" ON public.subscriptions;
CREATE POLICY "Users can read their own subscription"
ON public.subscriptions
FOR SELECT
USING (auth.uid() = user_id);

