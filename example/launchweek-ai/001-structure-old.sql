-- 001-structure.sql
-- 
-- This migration creates the core data structures for LaunchWeek.ai.
-- It defines utility functions, reference tables, and core business entities.
-- Relationships and security will be handled in subsequent migrations.

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

-- Timestamp management function
-- Automatically handles created_at and updated_at timestamps for tables
CREATE OR REPLACE FUNCTION public.handle_timestamps()
RETURNS TRIGGER AS $$
BEGIN
  -- Set created_at for new records
  IF TG_OP = 'INSERT' THEN
    NEW.created_at = NOW();
  END IF;
  
  -- Always update the updated_at timestamp
  NEW.updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;
COMMENT ON FUNCTION public.handle_timestamps() IS 'Automatically manages created_at and updated_at timestamps for tables';

-- Admin check utility function
-- Checks if the current user has admin privileges (via custom claim)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN (auth.jwt() ->> 'role') = 'admin';
EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;
COMMENT ON FUNCTION public.is_admin() IS 'Checks if the current user has admin role in their JWT claims';

-- Credit balance check utility function
-- Gets the current credit balance for a user
CREATE OR REPLACE FUNCTION internal.get_credit_balance(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  balance INTEGER;
BEGIN
  SELECT cb.balance INTO balance 
  FROM internal.credit_balances cb 
  WHERE cb.user_id = user_uuid;
  
  RETURN COALESCE(balance, 0);
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error retrieving credit balance: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = internal, public, pg_temp;
COMMENT ON FUNCTION internal.get_credit_balance(UUID) IS 'Retrieves the current credit balance for a user';

-- User-facing credit balance check
-- Wrapper function that restricts access to a user's own balance
CREATE OR REPLACE FUNCTION api.get_my_credit_balance()
RETURNS INTEGER AS $$
DECLARE
  user_id UUID;
BEGIN
  user_id := auth.uid();
  IF user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  RETURN internal.get_credit_balance(user_id);
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error retrieving credit balance: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, internal, public, pg_temp;
COMMENT ON FUNCTION api.get_my_credit_balance() IS 'Allows a user to check their own credit balance';

-- Credit addition function
-- Adds credits to a user's account and records the transaction
CREATE OR REPLACE FUNCTION internal.add_credits(
  user_uuid UUID,
  amount INTEGER,
  transaction_type reference.credit_transaction_type,
  description TEXT DEFAULT NULL,
  related_entity_type TEXT DEFAULT NULL,
  related_entity_id UUID DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
  new_balance INTEGER;
BEGIN
  -- Validate inputs
  IF amount <= 0 THEN
    RAISE EXCEPTION 'Credit amount must be positive';
  END IF;

  -- Update balance (create if doesn't exist)
  INSERT INTO internal.credit_balances (user_id, balance, lifetime_credits)
  VALUES (user_uuid, amount, amount)
  ON CONFLICT (user_id) DO UPDATE
  SET 
    balance = internal.credit_balances.balance + amount,
    lifetime_credits = internal.credit_balances.lifetime_credits + amount,
    updated_at = NOW()
  RETURNING balance INTO new_balance;
  
  -- Record transaction
  INSERT INTO internal.credit_transactions (
    user_id, 
    amount, 
    type, 
    description, 
    related_entity_type, 
    related_entity_id
  )
  VALUES (
    user_uuid, 
    amount, 
    transaction_type, 
    description, 
    related_entity_type, 
    related_entity_id
  );
  
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error adding credits: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = internal, public, pg_temp;
COMMENT ON FUNCTION internal.add_credits(UUID, INTEGER, reference.credit_transaction_type, TEXT, TEXT, UUID) 
IS 'Adds credits to a user account and records the transaction';

-- Credit deduction function
-- Deducts credits from a user's account if sufficient balance exists
CREATE OR REPLACE FUNCTION internal.deduct_credits(
  user_uuid UUID,
  amount INTEGER,
  description TEXT DEFAULT NULL,
  related_entity_type TEXT DEFAULT NULL,
  related_entity_id UUID DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
  current_balance INTEGER;
  new_balance INTEGER;
BEGIN
  -- Validate inputs
  IF amount <= 0 THEN
    RAISE EXCEPTION 'Deduction amount must be positive';
  END IF;
  
  -- Check if user has sufficient balance
  SELECT balance INTO current_balance 
  FROM internal.credit_balances 
  WHERE user_id = user_uuid;
  
  IF current_balance IS NULL OR current_balance < amount THEN
    RETURN FALSE; -- Insufficient balance
  END IF;
  
  -- Update balance
  UPDATE internal.credit_balances
  SET 
    balance = balance - amount,
    updated_at = NOW()
  WHERE user_id = user_uuid
  RETURNING balance INTO new_balance;
  
  -- Record transaction
  INSERT INTO internal.credit_transactions (
    user_id, 
    amount, 
    type, 
    description, 
    related_entity_type, 
    related_entity_id
  )
  VALUES (
    user_uuid, 
    -amount, 
    'usage', 
    description, 
    related_entity_type, 
    related_entity_id
  );
  
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error deducting credits: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = internal, public, pg_temp;
COMMENT ON FUNCTION internal.deduct_credits(UUID, INTEGER, TEXT, TEXT, UUID) 
IS 'Deducts credits from a user account if sufficient balance exists and records the transaction';

-- Safe credit usage function
-- API-exposed function to deduct credits for a specific purpose with permission checks
CREATE OR REPLACE FUNCTION api.use_credits_for_project(
  project_id UUID,
  amount INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
  user_id UUID;
  project_owner UUID;
BEGIN
  -- Get current user
  user_id := auth.uid();
  IF user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Verify project ownership
  SELECT p.user_id INTO project_owner
  FROM api.projects p
  WHERE p.id = project_id;
  
  IF project_owner IS NULL THEN
    RAISE EXCEPTION 'Project not found';
  END IF;
  
  IF project_owner != user_id THEN
    RAISE EXCEPTION 'Not authorized to use credits for this project';
  END IF;
  
  -- Attempt to deduct credits
  RETURN internal.deduct_credits(
    user_id, 
    amount, 
    'Project credit usage', 
    'project', 
    project_id
  );
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error using credits: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, internal, public, pg_temp;
COMMENT ON FUNCTION api.use_credits_for_project(UUID, INTEGER) 
IS 'Allows a user to use credits for their project with appropriate permission checks';

-- =============================================================================
-- REFERENCE TABLES
-- =============================================================================

-- Framework steps reference table
-- Defines the steps for each day in the 5-day framework
CREATE TABLE reference.framework_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  day reference.framework_day NOT NULL,
  step_number INTEGER NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  estimated_duration_minutes INTEGER,
  is_required BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Each step must have a unique number within its day
  CONSTRAINT unique_step_number_per_day UNIQUE (day, step_number)
);
COMMENT ON TABLE reference.framework_steps IS 'Defines the steps for each day in the 5-day framework';

-- Guide templates reference table
-- Stores templates for implementation guides
CREATE TABLE reference.guide_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL, -- 'vercel', 'supabase', 'v0dev'
  content_template JSONB NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_guide_templates_type ON reference.guide_templates (type) WHERE is_active = TRUE;
COMMENT ON TABLE reference.guide_templates IS 'Stores templates for implementation guides that can be customized by users';

-- Subscription tier benefits reference table
-- Maps subscription benefits to subscription tiers
CREATE TABLE config.subscription_benefits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stripe_product_id TEXT,
  name TEXT NOT NULL,
  description TEXT,
  monthly_credits INTEGER NOT NULL,
  max_monthly_credits INTEGER NOT NULL,
  max_projects INTEGER,
  has_priority_support BOOLEAN DEFAULT FALSE,
  has_advanced_features BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE config.subscription_benefits IS 'Defines the benefits associated with each subscription tier';

-- =============================================================================
-- CORE TABLES
-- =============================================================================

-- User profiles table
-- Extends auth.users with application-specific profile data
CREATE TABLE api.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  preferences JSONB DEFAULT '{}'::jsonb,
  onboarding_completed BOOLEAN DEFAULT FALSE,
  last_active_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_profiles_last_active ON api.profiles (last_active_at);
COMMENT ON TABLE api.profiles IS 'Extended user profile information linked to auth.users';

-- Projects table
-- Stores user SaaS projects
CREATE TABLE api.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  status reference.project_status NOT NULL DEFAULT 'draft',
  framework_day reference.framework_day NOT NULL DEFAULT 'create',
  credit_cost reference.positive_integer DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX idx_projects_user_id ON api.projects (user_id);
CREATE INDEX idx_projects_status ON api.projects (status) WHERE deleted_at IS NULL;
COMMENT ON TABLE api.projects IS 'Stores user SaaS project information and metadata';

-- Documents table
-- Stores AI-generated documents for projects
CREATE TABLE api.documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL,
  type reference.document_type NOT NULL,
  title TEXT NOT NULL,
  content JSONB NOT NULL,
  status reference.document_status NOT NULL DEFAULT 'draft',
  version INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  created_by UUID NOT NULL REFERENCES auth.users(id),
  updated_by UUID NOT NULL REFERENCES auth.users(id)
);
CREATE INDEX idx_documents_project_id ON api.documents (project_id);
CREATE INDEX idx_documents_type ON api.documents (type) WHERE deleted_at IS NULL;
COMMENT ON TABLE api.documents IS 'Stores AI-generated documents like PRDs, marketing content, and database schemas';

-- Document versions table
-- Tracks version history for documents
CREATE TABLE api.document_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL,
  version_number INTEGER NOT NULL,
  content JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES auth.users(id)
);
CREATE INDEX idx_document_versions_document_id ON api.document_versions (document_id, version_number);
COMMENT ON TABLE api.document_versions IS 'Stores version history for documents';

-- Implementation guides table
-- Stores user-customized implementation guides
CREATE TABLE api.implementation_guides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL,
  guide_template_id UUID NOT NULL,
  title TEXT NOT NULL,
  content JSONB NOT NULL,
  status reference.document_status NOT NULL DEFAULT 'draft',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  created_by UUID NOT NULL REFERENCES auth.users(id),
  updated_by UUID NOT NULL REFERENCES auth.users(id)
);
CREATE INDEX idx_implementation_guides_project_id ON api.implementation_guides (project_id);
COMMENT ON TABLE api.implementation_guides IS 'Stores user-customized implementation guides for technical implementation';

-- Project progress table
-- Tracks user progress through the framework steps
CREATE TABLE api.project_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL,
  framework_day reference.framework_day NOT NULL,
  step TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('not_started', 'in_progress', 'completed')),
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  user_id UUID NOT NULL REFERENCES auth.users(id)
);
CREATE INDEX idx_project_progress_project_id ON api.project_progress (project_id);
CREATE UNIQUE INDEX idx_unique_project_step ON api.project_progress (project_id, framework_day, step);
COMMENT ON TABLE api.project_progress IS 'Tracks user progress through the framework steps for each project';

-- Credit balances table
-- Tracks user credit balances
CREATE TABLE internal.credit_balances (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  balance reference.positive_integer NOT NULL DEFAULT 0,
  lifetime_credits reference.positive_integer NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE internal.credit_balances IS 'Tracks user credit balances for feature usage';

-- Credit transactions table
-- Records all credit transactions
CREATE TABLE internal.credit_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL,
  type reference.credit_transaction_type NOT NULL,
  description TEXT,
  related_entity_type TEXT,
  related_entity_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id)
);
CREATE INDEX idx_credit_transactions_user_id ON internal.credit_transactions (user_id);
CREATE INDEX idx_credit_transactions_created_at ON internal.credit_transactions (created_at);
COMMENT ON TABLE internal.credit_transactions IS 'Records all credit transactions including purchases, allocations, and usage';

-- =============================================================================
-- STRIPE TABLES
-- =============================================================================

-- Stripe customers table
-- Links Supabase users to Stripe customers
CREATE TABLE stripe.customers (
  id TEXT PRIMARY KEY, -- Stripe customer ID
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  name TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX idx_stripe_customers_user_id ON stripe.customers (user_id);
COMMENT ON TABLE stripe.customers IS 'Links Supabase users to Stripe customers';

-- Stripe products table
-- Stores Stripe products for subscriptions
CREATE TABLE stripe.products (
  id TEXT PRIMARY KEY, -- Stripe product ID
  name TEXT NOT NULL,
  description TEXT,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE stripe.products IS 'Stores Stripe products for subscriptions';

-- Stripe prices table
-- Stores Stripe prices for products
CREATE TABLE stripe.prices (
  id TEXT PRIMARY KEY, -- Stripe price ID
  product_id TEXT NOT NULL REFERENCES stripe.products(id),
  active BOOLEAN NOT NULL DEFAULT TRUE,
  currency TEXT NOT NULL,
  unit_amount INTEGER NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('one_time', 'recurring')),
  interval TEXT CHECK (type != 'recurring' OR interval IN ('day', 'week', 'month', 'year')),
  interval_count INTEGER,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_stripe_prices_product_id ON stripe.prices (product_id) WHERE active = TRUE;
COMMENT ON TABLE stripe.prices IS 'Stores Stripe prices for products';

-- Stripe subscriptions table
-- Stores active subscriptions
CREATE TABLE stripe.subscriptions (
  id TEXT PRIMARY KEY, -- Stripe subscription ID
  customer_id TEXT NOT NULL REFERENCES stripe.customers(id),
  status TEXT NOT NULL CHECK (status IN ('incomplete', 'incomplete_expired', 'trialing', 'active', 'past_due', 'canceled', 'unpaid')),
  price_id TEXT NOT NULL REFERENCES stripe.prices(id),
  quantity INTEGER NOT NULL DEFAULT 1,
  cancel_at_period_end BOOLEAN NOT NULL DEFAULT FALSE,
  current_period_start TIMESTAMPTZ NOT NULL,
  current_period_end TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ,
  cancel_at TIMESTAMPTZ,
  canceled_at TIMESTAMPTZ,
  trial_start TIMESTAMPTZ,
  trial_end TIMESTAMPTZ,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_stripe_subscriptions_customer_id ON stripe.subscriptions (customer_id);
CREATE INDEX idx_stripe_subscriptions_status ON stripe.subscriptions (status);
COMMENT ON TABLE stripe.subscriptions IS 'Stores Stripe subscription data';

-- Stripe invoices table
-- Tracks invoice data
CREATE TABLE stripe.invoices (
  id TEXT PRIMARY KEY, -- Stripe invoice ID
  customer_id TEXT NOT NULL REFERENCES stripe.customers(id),
  subscription_id TEXT REFERENCES stripe.subscriptions(id),
  status TEXT NOT NULL,
  currency TEXT NOT NULL,
  amount_due INTEGER NOT NULL,
  amount_paid INTEGER NOT NULL,
  amount_remaining INTEGER NOT NULL,
  invoice_pdf TEXT,
  hosted_invoice_url TEXT,
  period_start TIMESTAMPTZ,
  period_end TIMESTAMPTZ,
  created TIMESTAMPTZ NOT NULL,
  metadata JSONB,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_stripe_invoices_customer_id ON stripe.invoices (customer_id);
CREATE INDEX idx_stripe_invoices_subscription_id ON stripe.invoices (subscription_id);
COMMENT ON TABLE stripe.invoices IS 'Stores Stripe invoice data';

-- Stripe payment methods table
-- Stores customer payment methods
CREATE TABLE stripe.payment_methods (
  id TEXT PRIMARY KEY, -- Stripe payment method ID
  customer_id TEXT NOT NULL REFERENCES stripe.customers(id),
  type TEXT NOT NULL,
  card_brand TEXT,
  card_last4 TEXT,
  card_exp_month INTEGER,
  card_exp_year INTEGER,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_stripe_payment_methods_customer_id ON stripe.payment_methods (customer_id);
COMMENT ON TABLE stripe.payment_methods IS 'Stores Stripe payment method data';

-- Stripe charges table
-- Records charge data
CREATE TABLE stripe.charges (
  id TEXT PRIMARY KEY, -- Stripe charge ID
  customer_id TEXT NOT NULL REFERENCES stripe.customers(id),
  invoice_id TEXT REFERENCES stripe.invoices(id),
  payment_intent_id TEXT,
  amount INTEGER NOT NULL,
  currency TEXT NOT NULL,
  payment_method_id TEXT REFERENCES stripe.payment_methods(id),
  status TEXT NOT NULL,
  created TIMESTAMPTZ NOT NULL,
  metadata JSONB,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_stripe_charges_customer_id ON stripe.charges (customer_id);
CREATE INDEX idx_stripe_charges_invoice_id ON stripe.charges (invoice_id);
COMMENT ON TABLE stripe.charges IS 'Stores Stripe charge data';

-- Stripe webhook events table
-- Stores raw Stripe webhook events
CREATE TABLE stripe.webhook_events (
  id TEXT PRIMARY KEY, -- Stripe event ID
  type TEXT NOT NULL,
  api_version TEXT,
  created TIMESTAMPTZ NOT NULL,
  data JSONB NOT NULL,
  processing_status TEXT NOT NULL DEFAULT 'pending',
  processing_error TEXT,
  processing_attempts INTEGER NOT NULL DEFAULT 0,
  processed_at TIMESTAMPTZ,
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_stripe_webhook_events_type ON stripe.webhook_events (type);
CREATE INDEX idx_stripe_webhook_events_processing_status ON stripe.webhook_events (processing_status);
COMMENT ON TABLE stripe.webhook_events IS 'Stores Stripe webhook events for processing';

-- Add timestamp triggers to tables that need them
CREATE TRIGGER handle_timestamps_profiles
BEFORE INSERT OR UPDATE ON api.profiles
FOR EACH ROW EXECUTE FUNCTION public.handle_timestamps();

CREATE TRIGGER handle_timestamps_projects
BEFORE INSERT OR UPDATE ON api.projects
FOR EACH ROW EXECUTE FUNCTION public.handle_timestamps();

CREATE TRIGGER handle_timestamps_documents
BEFORE INSERT OR UPDATE ON api.documents
FOR EACH ROW EXECUTE FUNCTION public.handle_timestamps();

CREATE TRIGGER handle_timestamps_implementation_guides
BEFORE INSERT OR UPDATE ON api.implementation_guides
FOR EACH ROW EXECUTE FUNCTION public.handle_timestamps();

CREATE TRIGGER handle_timestamps_project_progress
BEFORE INSERT OR UPDATE ON api.project_progress
FOR EACH ROW EXECUTE FUNCTION public.handle_timestamps();

CREATE TRIGGER handle_timestamps_guide_templates
BEFORE INSERT OR UPDATE ON reference.guide_templates
FOR EACH ROW EXECUTE FUNCTION public.handle_timestamps();

CREATE TRIGGER handle_timestamps_framework_steps
BEFORE INSERT OR UPDATE ON reference.framework_steps
FOR EACH ROW EXECUTE FUNCTION public.handle_timestamps();

CREATE TRIGGER handle_timestamps_subscription_benefits
BEFORE INSERT OR UPDATE ON config.subscription_benefits
FOR EACH ROW EXECUTE FUNCTION public.handle_timestamps();