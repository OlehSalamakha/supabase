-- Alter user_usage table to add subscription tracking fields
-- Add last_reset_at to track when quota was last renewed
ALTER TABLE public.user_usage
  ADD COLUMN IF NOT EXISTS last_reset_at timestamptz DEFAULT now();

-- Add subscription_tier to track user's subscription level
ALTER TABLE public.user_usage
  ADD COLUMN IF NOT EXISTS subscription_tier text DEFAULT 'free';

-- Create index on subscription_tier for analytics
CREATE INDEX IF NOT EXISTS idx_user_usage_subscription_tier ON public.user_usage(subscription_tier);

-- Create index on last_reset_at for finding users needing renewal
CREATE INDEX IF NOT EXISTS idx_user_usage_last_reset_at ON public.user_usage(last_reset_at);

-- Add check constraint for subscription_tier values
ALTER TABLE public.user_usage
  DROP CONSTRAINT IF EXISTS user_usage_subscription_tier_check;
ALTER TABLE public.user_usage
  ADD CONSTRAINT user_usage_subscription_tier_check
  CHECK (subscription_tier IN ('free', 'monthly', 'yearly'));
