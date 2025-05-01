-- 001-structure.sql
-- LaunchWeek.ai Structure Migration

-- This migration establishes the core data structure of the LaunchWeek.ai database:
-- - Creates reference tables for lookup and template data
-- - Defines core business entity tables for the application
-- - Establishes utility functions for database operations
-- - Sets up integration with Stripe for subscription management

------------------------------------------------------------------------------
-- PART 1: REFERENCE TABLES
------------------------------------------------------------------------------
-- These tables store template and reference data that rarely changes

-- Day templates for the 5-day framework
CREATE TABLE reference.day_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  framework_day reference.framework_day NOT NULL,
  title reference.non_empty_text NOT NULL,
  description TEXT NOT NULL,
  estimated_duration INTERVAL NOT NULL,
  order_number INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE reference.day_templates IS 'Templates for each day in the 5-day framework';

-- Step templates for each day in the framework
CREATE TABLE reference.step_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  day_template_id UUID NOT NULL,
  title reference.non_empty_text NOT NULL,
  description TEXT NOT NULL,
  step_type reference.step_type NOT NULL,
  instructions TEXT NOT NULL,
  order_number INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE reference.step_templates IS 'Templates for individual steps within each day of the framework';

-- AI prompt templates for guided AI interactions
CREATE TABLE reference.prompt_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  step_template_id UUID NOT NULL,
  title reference.non_empty_text NOT NULL,
  description TEXT NOT NULL,
  prompt_text TEXT NOT NULL,
  model TEXT NOT NULL,
  purpose TEXT NOT NULL,
  version INTEGER NOT NULL DEFAULT 1,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE reference.prompt_templates IS 'Templates for AI prompts used throughout the framework process';

------------------------------------------------------------------------------
-- PART 2: CORE TABLES
------------------------------------------------------------------------------
-- These tables store the main business entities of the application

-- User profiles extending the default auth.users table
CREATE TABLE api.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  technical_expertise INTEGER CHECK (technical_expertise BETWEEN 1 AND 5),
  industry TEXT,
  company_size TEXT,
  onboarding_completed BOOLEAN NOT NULL DEFAULT false,
  current_project_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX profiles_user_id_idx ON api.profiles(id);
COMMENT ON TABLE api.profiles IS 'Extended user profile information beyond what is stored in auth.users';

-- Projects table - central entity for each user project
CREATE TABLE api.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name reference.non_empty_text NOT NULL,
  description TEXT,
  industry TEXT,
  status reference.project_status NOT NULL DEFAULT 'draft',
  current_framework_day reference.framework_day,
  completion_percentage INTEGER DEFAULT 0 CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX projects_user_id_idx ON api.projects(user_id);
COMMENT ON TABLE api.projects IS 'Main projects created by users to track their SaaS development process';

-- Framework progress tracking
CREATE TABLE api.framework_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL,
  framework_day reference.framework_day NOT NULL,
  status reference.task_status NOT NULL DEFAULT 'pending',
  completion_percentage INTEGER DEFAULT 0 CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE api.framework_progress IS 'Tracks progress through each day of the 5-day framework';

-- Individual steps within each framework day
CREATE TABLE api.framework_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL,
  framework_day reference.framework_day NOT NULL,
  step_number INTEGER NOT NULL,
  title reference.non_empty_text NOT NULL,
  description TEXT NOT NULL,
  step_type reference.step_type NOT NULL,
  status reference.task_status NOT NULL DEFAULT 'pending',
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE api.framework_steps IS 'Individual steps that users complete within each day of the framework';

-- Documents created throughout the process
CREATE TABLE api.documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL,
  step_id UUID,
  type reference.document_type NOT NULL,
  title reference.non_empty_text NOT NULL,
  content TEXT,
  content_json JSONB,
  version INTEGER NOT NULL DEFAULT 1,
  is_finalized BOOLEAN NOT NULL DEFAULT false,
  created_by UUID,
  updated_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE api.documents IS 'Documents created during the SaaS building process, such as PRDs and marketing materials';

-- Implementation plans for project execution
CREATE TABLE api.implementation_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL,
  title reference.non_empty_text NOT NULL,
  description TEXT,
  content JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE api.implementation_plans IS 'Structured implementation plans for executing project development';

-- Individual implementation tasks
CREATE TABLE api.implementation_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL,
  task_number TEXT NOT NULL,
  title reference.non_empty_text NOT NULL,
  description TEXT NOT NULL,
  priority reference.priority_level NOT NULL DEFAULT 'medium',
  complexity INTEGER NOT NULL DEFAULT 5 CHECK (complexity >= 1 AND complexity <= 10),
  dependencies TEXT[],
  test_strategy TEXT,
  status reference.task_status NOT NULL DEFAULT 'pending',
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE api.implementation_tasks IS 'Individual tasks within implementation plans for project execution';

-- AI conversations throughout the process
CREATE TABLE api.ai_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL,
  step_id UUID,
  task_id UUID,
  title TEXT NOT NULL,
  model TEXT NOT NULL,
  is_complete BOOLEAN NOT NULL DEFAULT false,
  token_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE api.ai_conversations IS 'AI-assisted conversations that guide users through the framework process';

-- Individual messages within AI conversations
CREATE TABLE api.ai_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL,
  role reference.message_role NOT NULL,
  content TEXT NOT NULL,
  tokens INTEGER,
  sequence_number INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE api.ai_messages IS 'Individual messages within AI conversations (user inputs and AI responses)';

------------------------------------------------------------------------------
-- PART 3: INTERNAL TABLES
------------------------------------------------------------------------------
-- Tables for internal system operations and sensitive data

-- Asynchronous AI task processing queue
CREATE TABLE internal.ai_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  project_id UUID NOT NULL,
  conversation_id UUID,
  input_data JSONB NOT NULL,
  output_data JSONB,
  status reference.task_status NOT NULL DEFAULT 'pending',
  error_message TEXT,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ai_tasks_user_id_idx ON internal.ai_tasks(user_id);
CREATE INDEX ai_tasks_project_id_idx ON internal.ai_tasks(project_id);
CREATE INDEX ai_tasks_status_idx ON internal.ai_tasks(status);
COMMENT ON TABLE internal.ai_tasks IS 'Queue for asynchronous AI task processing with status tracking';

-- User credits for premium features
CREATE TABLE internal.user_credits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  balance INTEGER NOT NULL DEFAULT 1, -- Start with 1 free credit on account creation
  last_updated TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX user_credits_user_id_idx ON internal.user_credits(user_id);
COMMENT ON TABLE internal.user_credits IS 'Tracks available credits for premium features on user accounts, starting with 1 free credit';

-- Credit transaction history
CREATE TABLE internal.credit_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL,
  balance_after INTEGER NOT NULL,
  transaction_type reference.credit_transaction_type NOT NULL,
  stripe_payment_id TEXT,
  price_cents INTEGER,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX credit_transactions_user_id_idx ON internal.credit_transactions(user_id);
CREATE INDEX credit_transactions_created_at_idx ON internal.credit_transactions(created_at);
CREATE INDEX credit_transactions_type_idx ON internal.credit_transactions(transaction_type);
COMMENT ON TABLE internal.credit_transactions IS 'Audit log of all credit additions and deductions with pricing information';

-- Credit packages configuration
CREATE TABLE config.credit_packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  credits INTEGER NOT NULL,
  price_cents INTEGER NOT NULL,
  stripe_price_id TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE config.credit_packages IS 'Configuration for available credit purchase packages';

-- Initialize default credit packages
INSERT INTO config.credit_packages (name, credits, price_cents, is_active)
VALUES 
  ('3-Pack', 3, 5000, true),
  ('10-Pack', 10, 12500, true);

------------------------------------------------------------------------------
-- PART 4: CONFIG TABLES
------------------------------------------------------------------------------
-- Configuration tables for application settings

-- Subscription tier benefits configuration
CREATE TABLE config.subscription_benefits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tier_name TEXT NOT NULL UNIQUE,
  monthly_price INTEGER,
  yearly_price INTEGER,
  max_projects INTEGER NOT NULL,
  max_ai_conversations INTEGER NOT NULL,
  has_priority_support BOOLEAN NOT NULL DEFAULT false,
  has_advanced_features BOOLEAN NOT NULL DEFAULT false,
  features JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE config.subscription_benefits IS 'Configuration of features and limits for different subscription tiers';

------------------------------------------------------------------------------
-- PART 5: UTILITY FUNCTIONS
------------------------------------------------------------------------------
-- Reusable utility functions for database operations

-- Function to handle timestamp updates
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;
COMMENT ON FUNCTION public.handle_updated_at() IS 'Updates the updated_at timestamp when a record is modified';

-- Function to handle new user creation and profile setup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO api.profiles (id, display_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'name', NEW.email));
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;
COMMENT ON FUNCTION public.handle_new_user() IS 'Creates a profile record when a new user signs up';

-- Function to check if user owns a project
CREATE OR REPLACE FUNCTION api.user_owns_project(project_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  is_owner BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM api.projects
    WHERE id = project_id
    AND user_id = auth.uid()
  ) INTO is_owner;
  
  RETURN is_owner;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = api, public, pg_temp;
COMMENT ON FUNCTION api.user_owns_project(UUID) IS 'Checks if the current user owns a specific project';

-- Function to get user credit balance
CREATE OR REPLACE FUNCTION internal.get_user_credit_balance(user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  balance INTEGER;
BEGIN
  SELECT uc.balance INTO balance
  FROM internal.user_credits uc
  WHERE uc.user_id = get_user_credit_balance.user_id;
  
  RETURN COALESCE(balance, 0);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = internal, public, pg_temp;
COMMENT ON FUNCTION internal.get_user_credit_balance(UUID) IS 'Gets the current credit balance for a user';

-- Wrapper function for user credit balance that checks permissions
CREATE OR REPLACE FUNCTION api.get_my_credit_balance()
RETURNS INTEGER AS $$
BEGIN
  RETURN internal.get_user_credit_balance(auth.uid());
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = api, internal, public, pg_temp;
COMMENT ON FUNCTION api.get_my_credit_balance() IS 'Secure wrapper to get current user''s credit balance';

------------------------------------------------------------------------------
-- PART 6: STRIPE INTEGRATION TABLES
------------------------------------------------------------------------------
-- Tables for Stripe payment processing integration

-- Stripe customers table linking to Supabase users
CREATE TABLE stripe.customers (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  name TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX customers_user_id_idx ON stripe.customers(user_id);
COMMENT ON TABLE stripe.customers IS 'Maps Stripe customers to application users';

-- Stripe products table
CREATE TABLE stripe.products (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  active BOOLEAN NOT NULL DEFAULT true,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE stripe.products IS 'Stores Stripe product definitions';

-- Stripe prices table
CREATE TABLE stripe.prices (
  id TEXT PRIMARY KEY,
  product_id TEXT NOT NULL REFERENCES stripe.products(id),
  active BOOLEAN NOT NULL DEFAULT true,
  currency TEXT NOT NULL,
  unit_amount INTEGER,
  type TEXT NOT NULL,
  interval TEXT,
  interval_count INTEGER,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX prices_product_id_idx ON stripe.prices(product_id);
COMMENT ON TABLE stripe.prices IS 'Stores Stripe pricing information';

-- Stripe subscriptions table
CREATE TABLE stripe.subscriptions (
  id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL REFERENCES stripe.customers(id),
  status TEXT NOT NULL,
  price_id TEXT REFERENCES stripe.prices(id),
  cancel_at_period_end BOOLEAN NOT NULL DEFAULT false,
  current_period_start TIMESTAMPTZ NOT NULL,
  current_period_end TIMESTAMPTZ NOT NULL,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX subscriptions_customer_id_idx ON stripe.subscriptions(customer_id);
COMMENT ON TABLE stripe.subscriptions IS 'Tracks active subscriptions';

-- Stripe webhook events table
CREATE TABLE stripe.webhook_events (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  api_version TEXT NOT NULL,
  created TIMESTAMPTZ NOT NULL,
  data JSONB NOT NULL,
  processing_status TEXT NOT NULL DEFAULT 'pending',
  processing_error TEXT,
  processing_attempts INTEGER NOT NULL DEFAULT 0,
  processed_at TIMESTAMPTZ,
  received_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX webhook_events_type_idx ON stripe.webhook_events(type);
CREATE INDEX webhook_events_processing_status_idx ON stripe.webhook_events(processing_status);
COMMENT ON TABLE stripe.webhook_events IS 'Records Stripe webhook events';

-- Stripe invoices table
CREATE TABLE stripe.invoices (
  id TEXT PRIMARY KEY,
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
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX invoices_customer_id_idx ON stripe.invoices(customer_id);
CREATE INDEX invoices_subscription_id_idx ON stripe.invoices(subscription_id);
COMMENT ON TABLE stripe.invoices IS 'Tracks invoice data';

-- Stripe payment methods table
CREATE TABLE stripe.payment_methods (
  id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL REFERENCES stripe.customers(id),
  type TEXT NOT NULL,
  card_brand TEXT,
  card_last4 TEXT,
  card_exp_month INTEGER,
  card_exp_year INTEGER,
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX payment_methods_customer_id_idx ON stripe.payment_methods(customer_id);
COMMENT ON TABLE stripe.payment_methods IS 'Stores customer payment methods';

-- Stripe charges table
CREATE TABLE stripe.charges (
  id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL REFERENCES stripe.customers(id),
  invoice_id TEXT REFERENCES stripe.invoices(id),
  payment_intent_id TEXT,
  amount INTEGER NOT NULL,
  currency TEXT NOT NULL,
  payment_method_id TEXT REFERENCES stripe.payment_methods(id),
  status TEXT NOT NULL,
  created TIMESTAMPTZ NOT NULL,
  metadata JSONB,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX charges_customer_id_idx ON stripe.charges(customer_id);
CREATE INDEX charges_invoice_id_idx ON stripe.charges(invoice_id);
COMMENT ON TABLE stripe.charges IS 'Records charge data';

------------------------------------------------------------------------------
-- PART 7: TRIGGERS
------------------------------------------------------------------------------
-- Create triggers for updating timestamps on all tables with updated_at

-- api schema tables
CREATE TRIGGER set_updated_at BEFORE UPDATE ON api.profiles
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON api.projects
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON api.framework_progress
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON api.framework_steps
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON api.documents
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON api.implementation_plans
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON api.implementation_tasks
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON api.ai_conversations
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- reference schema tables
CREATE TRIGGER set_updated_at BEFORE UPDATE ON reference.day_templates
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON reference.step_templates
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON reference.prompt_templates
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- config schema tables
CREATE TRIGGER set_updated_at BEFORE UPDATE ON config.subscription_benefits
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- stripe schema tables
CREATE TRIGGER set_updated_at BEFORE UPDATE ON stripe.customers
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON stripe.products
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON stripe.prices
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON stripe.subscriptions
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON stripe.payment_methods
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Create trigger for new user creation to set up profile
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();