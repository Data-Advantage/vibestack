-- 000-initial-migration.sql
-- Initial migration script for LaunchWeek.ai (Vibestack)

-- =========================================================
-- Extensions
-- =========================================================

-- Enable necessary PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;      -- For UUID generation
CREATE EXTENSION IF NOT EXISTS pg_trgm;        -- For text search indexes
CREATE EXTENSION IF NOT EXISTS btree_gin;      -- For GIN indexes on non-jsonb columns

-- =========================================================
-- Schema Creation
-- =========================================================

-- Create custom schemas
CREATE SCHEMA IF NOT EXISTS api;              -- Primary application data
CREATE SCHEMA IF NOT EXISTS reference;        -- Lookup tables and enum types
CREATE SCHEMA IF NOT EXISTS stripe;           -- Payment/subscription data
CREATE SCHEMA IF NOT EXISTS analytics;        -- Usage tracking and reporting
CREATE SCHEMA IF NOT EXISTS audit;            -- Change tracking for important entities

-- Comment schemas for better documentation
COMMENT ON SCHEMA api IS 'Core business objects for LaunchWeek.ai';
COMMENT ON SCHEMA reference IS 'Reference data and enums';
COMMENT ON SCHEMA stripe IS 'Payment and subscription related data';
COMMENT ON SCHEMA analytics IS 'Analytics and reporting data';
COMMENT ON SCHEMA audit IS 'Change tracking and history';

-- =========================================================
-- Enum Types in Reference Schema
-- =========================================================

-- Project Status Enum
CREATE TYPE reference.project_status AS ENUM (
  'draft',
  'in_progress', 
  'completed',
  'archived'
);

COMMENT ON TYPE reference.project_status IS 'Status values for projects';

-- Document Type Enum
CREATE TYPE reference.document_type AS ENUM (
  'product_requirements',
  'marketing_content',
  'database_schema',
  'implementation_guide'
);

COMMENT ON TYPE reference.document_type IS 'Types of documents that can be generated';

-- Framework Day Enum
CREATE TYPE reference.framework_day AS ENUM (
  'day_1_create',
  'day_2_refine',
  'day_3_build',
  'day_4_position',
  'day_5_launch'
);

COMMENT ON TYPE reference.framework_day IS 'Stages in the 5-day framework journey';

-- Credit Operation Type Enum
CREATE TYPE reference.credit_operation_type AS ENUM (
  'project_creation',
  'document_generation',
  'deployment_assistance',
  'purchase',
  'subscription_renewal'
);

COMMENT ON TYPE reference.credit_operation_type IS 'Types of credit operations for tracking credit usage';

-- =========================================================
-- Utility Functions (Created before referenced by triggers)
-- =========================================================

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

COMMENT ON FUNCTION public.update_updated_at() IS 'Trigger function to update the updated_at timestamp';

-- Function to set both created_at and updated_at timestamps
CREATE OR REPLACE FUNCTION public.set_timestamps()
RETURNS TRIGGER AS $$
BEGIN
  NEW.created_at = NOW();
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

COMMENT ON FUNCTION public.set_timestamps() IS 'Trigger function to set both created_at and updated_at timestamps';

-- Trigger function to manage updated_at field on any update
CREATE OR REPLACE FUNCTION public.trigger_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

COMMENT ON FUNCTION public.trigger_updated_at() IS 'Trigger function to update updated_at field on row update';

-- Function to check if a user is an admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN COALESCE(auth.jwt() ->> 'role', '') = 'admin';
EXCEPTION
  WHEN others THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

COMMENT ON FUNCTION public.is_admin() IS 'Helper function to check if the current user is an admin';

-- Function to set the created_by and updated_by fields
CREATE OR REPLACE FUNCTION public.set_user_ids()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.created_by = auth.uid();
    NEW.updated_by = auth.uid();
  ELSIF TG_OP = 'UPDATE' THEN
    NEW.updated_by = auth.uid();
  END IF;
  RETURN NEW;
EXCEPTION
  WHEN others THEN
    RAISE WARNING 'Error setting user IDs: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

COMMENT ON FUNCTION public.set_user_ids() IS 'Trigger function to automatically set user IDs for audit fields';

-- =========================================================
-- API Schema Tables
-- =========================================================

-- Profiles Table - Extension for auth.users
CREATE TABLE api.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  credit_balance INTEGER NOT NULL DEFAULT 2 CHECK (credit_balance >= 0),
  subscription_tier TEXT,
  notification_preferences JSONB DEFAULT '{}',
  last_login TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Check constraint to ensure credit balance is non-negative
  CONSTRAINT positive_credit_balance CHECK (credit_balance >= 0)
);

COMMENT ON TABLE api.profiles IS 'Extended profile information for application users';
COMMENT ON COLUMN api.profiles.id IS 'Primary key, references auth.users.id';
COMMENT ON COLUMN api.profiles.credit_balance IS 'Current credit balance for the user, default 2 free credits';
COMMENT ON COLUMN api.profiles.subscription_tier IS 'References stripe product ID for subscription tier';

-- Projects Table
CREATE TABLE api.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL CHECK (char_length(name) > 0 AND char_length(name) <= 100),
  description TEXT,
  status reference.project_status NOT NULL DEFAULT 'draft',
  metadata JSONB DEFAULT '{}',
  framework_stage reference.framework_day NOT NULL DEFAULT 'day_1_create',
  progress_percentage INTEGER NOT NULL DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  created_by UUID NOT NULL REFERENCES auth.users(id),
  updated_by UUID NOT NULL REFERENCES auth.users(id),
  
  -- Constraint to ensure deleted_at is only set when status is 'archived'
  CONSTRAINT valid_deleted_status CHECK (
    (deleted_at IS NULL) OR 
    (deleted_at IS NOT NULL AND status = 'archived')
  )
);

COMMENT ON TABLE api.projects IS 'User projects for SaaS ideas';
COMMENT ON COLUMN api.projects.id IS 'Project unique identifier';
COMMENT ON COLUMN api.projects.user_id IS 'Owner of the project, references auth.users.id';
COMMENT ON COLUMN api.projects.framework_stage IS 'Current stage in the 5-day framework';
COMMENT ON COLUMN api.projects.deleted_at IS 'Timestamp for soft deletion, NULL if not deleted';

-- Documents Table
CREATE TABLE api.documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES api.projects(id) ON DELETE CASCADE,
  type reference.document_type NOT NULL,
  title TEXT NOT NULL CHECK (char_length(title) > 0 AND char_length(title) <= 200),
  content TEXT, -- Markdown content
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'in_progress', 'completed')),
  current_version UUID, -- Will be set after first version is created
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES auth.users(id),
  updated_by UUID NOT NULL REFERENCES auth.users(id),
  
  -- Each project can have only one document of each type
  CONSTRAINT unique_document_type_per_project UNIQUE (project_id, type)
);

COMMENT ON TABLE api.documents IS 'Generated documents for projects';
COMMENT ON COLUMN api.documents.project_id IS 'Project this document belongs to';
COMMENT ON COLUMN api.documents.type IS 'Type of document (PRD, marketing, etc.)';
COMMENT ON COLUMN api.documents.content IS 'Document content in markdown format';
COMMENT ON COLUMN api.documents.current_version IS 'Points to current version in document_versions table';

-- Document Versions Table
CREATE TABLE api.document_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL REFERENCES api.documents(id) ON DELETE CASCADE,
  version_number INTEGER NOT NULL,
  content TEXT NOT NULL, -- Snapshot of document content
  metadata JSONB DEFAULT '{}',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES auth.users(id),
  
  -- Each document can have only one version with a specific version number
  CONSTRAINT unique_version_per_document UNIQUE (document_id, version_number)
);

COMMENT ON TABLE api.document_versions IS 'Version history for documents';
COMMENT ON COLUMN api.document_versions.document_id IS 'Document this version belongs to';
COMMENT ON COLUMN api.document_versions.version_number IS 'Sequential version number';
COMMENT ON COLUMN api.document_versions.content IS 'Snapshot of document content at this version';
COMMENT ON COLUMN api.document_versions.notes IS 'Optional notes about this version';

-- Now that document_versions exists, add the foreign key constraint to documents
ALTER TABLE api.documents 
ADD CONSTRAINT fk_document_current_version 
FOREIGN KEY (current_version) REFERENCES api.document_versions(id) ON DELETE SET NULL;

-- Deployments Table
CREATE TABLE api.deployments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES api.projects(id) ON DELETE CASCADE,
  platform TEXT NOT NULL CHECK (platform IN ('vercel', 'supabase', 'other')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'failed')),
  deployment_url TEXT,
  verification_status TEXT NOT NULL DEFAULT 'unverified' CHECK (verification_status IN ('unverified', 'verified', 'failed')),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES auth.users(id),
  updated_by UUID NOT NULL REFERENCES auth.users(id)
);

COMMENT ON TABLE api.deployments IS 'Deployment information for projects';
COMMENT ON COLUMN api.deployments.project_id IS 'Project this deployment belongs to';
COMMENT ON COLUMN api.deployments.platform IS 'Deployment platform (vercel, supabase, etc.)';
COMMENT ON COLUMN api.deployments.deployment_url IS 'URL where the deployment is accessible';

-- Credit Transactions Table
CREATE TABLE api.credit_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  operation_type reference.credit_operation_type NOT NULL,
  amount INTEGER NOT NULL,
  balance_after INTEGER NOT NULL CHECK (balance_after >= 0),
  related_entity_id UUID,
  related_entity_type TEXT CHECK (
    related_entity_type IS NULL OR 
    related_entity_type IN ('project', 'document', 'deployment')
  ),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Constraint to ensure transaction amount is not zero
  CONSTRAINT non_zero_amount CHECK (amount != 0)
);

COMMENT ON TABLE api.credit_transactions IS 'Records of credit balance changes';
COMMENT ON COLUMN api.credit_transactions.user_id IS 'User whose credits are affected';
COMMENT ON COLUMN api.credit_transactions.operation_type IS 'Type of operation affecting credits';
COMMENT ON COLUMN api.credit_transactions.amount IS 'Amount of credits added or deducted (positive or negative)';
COMMENT ON COLUMN api.credit_transactions.balance_after IS 'Credit balance after this transaction';

-- =========================================================
-- Stripe Schema Tables
-- =========================================================

-- Customers Table
CREATE TABLE stripe.customers (
  id TEXT PRIMARY KEY, -- Stripe customer ID (e.g., cus_...)
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  name TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Each user can have only one Stripe customer record
  CONSTRAINT unique_user_id UNIQUE (user_id)
);

COMMENT ON TABLE stripe.customers IS 'Stripe customers linked to application users';
COMMENT ON COLUMN stripe.customers.id IS 'Stripe customer ID (cus_...)';
COMMENT ON COLUMN stripe.customers.user_id IS 'References auth.users.id for the linked user';

-- Products Table
CREATE TABLE stripe.products (
  id TEXT PRIMARY KEY, -- Stripe product ID (e.g., prod_...)
  name TEXT NOT NULL,
  description TEXT,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE stripe.products IS 'Stripe products for subscriptions and purchases';
COMMENT ON COLUMN stripe.products.id IS 'Stripe product ID (prod_...)';
COMMENT ON COLUMN stripe.products.active IS 'Whether this product is currently active';

-- Prices Table
CREATE TABLE stripe.prices (
  id TEXT PRIMARY KEY, -- Stripe price ID (e.g., price_...)
  product_id TEXT NOT NULL REFERENCES stripe.products(id) ON DELETE CASCADE,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  currency TEXT NOT NULL,
  unit_amount INTEGER NOT NULL CHECK (unit_amount >= 0), -- Amount in cents/smallest currency unit
  type TEXT NOT NULL CHECK (type IN ('one_time', 'recurring')),
  interval TEXT CHECK (
    (type = 'recurring' AND interval IN ('month', 'year')) OR
    (type = 'one_time' AND interval IS NULL)
  ), -- 'month', 'year', etc. (for recurring)
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE stripe.prices IS 'Stripe prices for products';
COMMENT ON COLUMN stripe.prices.id IS 'Stripe price ID (price_...)';
COMMENT ON COLUMN stripe.prices.product_id IS 'References stripe.products.id';
COMMENT ON COLUMN stripe.prices.unit_amount IS 'Price amount in cents/smallest currency unit';
COMMENT ON COLUMN stripe.prices.type IS 'Type of price (one_time or recurring)';
COMMENT ON COLUMN stripe.prices.interval IS 'Billing interval for recurring prices';

-- Subscriptions Table
CREATE TABLE stripe.subscriptions (
  id TEXT PRIMARY KEY, -- Stripe subscription ID (e.g., sub_...)
  customer_id TEXT NOT NULL REFERENCES stripe.customers(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('active', 'canceled', 'incomplete', 'incomplete_expired', 'past_due', 'trialing', 'unpaid')),
  price_id TEXT NOT NULL REFERENCES stripe.prices(id) ON DELETE RESTRICT,
  cancel_at_period_end BOOLEAN NOT NULL DEFAULT FALSE,
  current_period_start TIMESTAMPTZ NOT NULL,
  current_period_end TIMESTAMPTZ NOT NULL,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Check constraint to ensure period end is after period start
  CONSTRAINT valid_subscription_period CHECK (current_period_end > current_period_start)
);

COMMENT ON TABLE stripe.subscriptions IS 'Stripe subscriptions for users';
COMMENT ON COLUMN stripe.subscriptions.id IS 'Stripe subscription ID (sub_...)';
COMMENT ON COLUMN stripe.subscriptions.customer_id IS 'References stripe.customers.id';
COMMENT ON COLUMN stripe.subscriptions.status IS 'Current status of the subscription';
COMMENT ON COLUMN stripe.subscriptions.price_id IS 'References stripe.prices.id for the subscription plan';

-- Webhook Events Table
CREATE TABLE stripe.webhook_events (
  id TEXT PRIMARY KEY, -- Stripe event ID (e.g., evt_...)
  type TEXT NOT NULL, -- Event type (e.g., 'customer.created', 'invoice.paid')
  api_version TEXT NOT NULL, -- Stripe API version
  created TIMESTAMPTZ NOT NULL, -- Timestamp from Stripe
  data JSONB NOT NULL, -- Raw event data from Stripe
  idempotency_key TEXT, -- Optional idempotency key
  processing_status TEXT NOT NULL DEFAULT 'pending' CHECK (processing_status IN ('pending', 'processed', 'failed')),
  processing_error TEXT, -- Error message if processing failed
  processing_attempts INTEGER NOT NULL DEFAULT 0 CHECK (processing_attempts >= 0),
  processed_at TIMESTAMPTZ, -- When event was processed
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW() -- When event was received
);

COMMENT ON TABLE stripe.webhook_events IS 'Raw Stripe webhook events for processing and audit';
COMMENT ON COLUMN stripe.webhook_events.id IS 'Stripe event ID (evt_...)';
COMMENT ON COLUMN stripe.webhook_events.type IS 'Webhook event type from Stripe';
COMMENT ON COLUMN stripe.webhook_events.data IS 'Complete event payload as JSON';
COMMENT ON COLUMN stripe.webhook_events.processing_status IS 'Status of event processing';

-- Subscription Benefits Table
CREATE TABLE stripe.subscription_benefits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id TEXT NOT NULL REFERENCES stripe.products(id) ON DELETE CASCADE,
  monthly_credits INTEGER NOT NULL CHECK (monthly_credits >= 0),
  max_projects INTEGER,
  has_priority_support BOOLEAN NOT NULL DEFAULT FALSE,
  has_advanced_features BOOLEAN NOT NULL DEFAULT FALSE,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Each product can have only one benefits configuration
  CONSTRAINT unique_product_benefits UNIQUE (product_id)
);

COMMENT ON TABLE stripe.subscription_benefits IS 'Benefits associated with each subscription tier';
COMMENT ON COLUMN stripe.subscription_benefits.product_id IS 'References stripe.products.id';
COMMENT ON COLUMN stripe.subscription_benefits.monthly_credits IS 'Credits allocated monthly for this subscription';
COMMENT ON COLUMN stripe.subscription_benefits.max_projects IS 'Maximum number of projects allowed (NULL for unlimited)';

-- =========================================================
-- Analytics Schema Tables
-- =========================================================

-- Project Metrics Table
CREATE TABLE analytics.project_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES api.projects(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_date DATE NOT NULL DEFAULT CURRENT_DATE,
  highest_stage_reached reference.framework_day NOT NULL,
  time_spent_seconds INTEGER NOT NULL DEFAULT 0 CHECK (time_spent_seconds >= 0),
  documents_completed INTEGER NOT NULL DEFAULT 0 CHECK (documents_completed >= 0),
  deployment_attempted BOOLEAN NOT NULL DEFAULT FALSE,
  deployment_successful BOOLEAN NOT NULL DEFAULT FALSE,
  
  -- Each project has one metrics record per day
  CONSTRAINT unique_project_day UNIQUE (project_id, created_date)
);

COMMENT ON TABLE analytics.project_metrics IS 'Daily metrics for project progress and activity';
COMMENT ON COLUMN analytics.project_metrics.project_id IS 'References api.projects.id';
COMMENT ON COLUMN analytics.project_metrics.created_date IS 'Date this metric record is for';
COMMENT ON COLUMN analytics.project_metrics.time_spent_seconds IS 'Time spent on this project on this date';

-- Document Metrics Table
CREATE TABLE analytics.document_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL REFERENCES api.documents(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_date DATE NOT NULL DEFAULT CURRENT_DATE,
  generation_attempts INTEGER NOT NULL DEFAULT 0 CHECK (generation_attempts >= 0),
  edit_count INTEGER NOT NULL DEFAULT 0 CHECK (edit_count >= 0),
  time_spent_seconds INTEGER NOT NULL DEFAULT 0 CHECK (time_spent_seconds >= 0),
  content_length INTEGER,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  
  -- Each document has one metrics record per day
  CONSTRAINT unique_document_day UNIQUE (document_id, created_date)
);

COMMENT ON TABLE analytics.document_metrics IS 'Daily metrics for document generation and editing';
COMMENT ON COLUMN analytics.document_metrics.document_id IS 'References api.documents.id';
COMMENT ON COLUMN analytics.document_metrics.generation_attempts IS 'Number of generation attempts on this date';
COMMENT ON COLUMN analytics.document_metrics.edit_count IS 'Number of edits made on this date';

-- User Engagement Table
CREATE TABLE analytics.user_engagement (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  session_date DATE NOT NULL DEFAULT CURRENT_DATE,
  session_count INTEGER NOT NULL DEFAULT 0 CHECK (session_count >= 0),
  total_duration_seconds INTEGER NOT NULL DEFAULT 0 CHECK (total_duration_seconds >= 0),
  features_used JSONB DEFAULT '{}',
  projects_accessed INTEGER NOT NULL DEFAULT 0 CHECK (projects_accessed >= 0),
  documents_accessed INTEGER NOT NULL DEFAULT 0 CHECK (documents_accessed >= 0),
  
  -- Each user has one engagement record per day
  CONSTRAINT unique_user_day UNIQUE (user_id, session_date)
);

COMMENT ON TABLE analytics.user_engagement IS 'Daily user engagement and activity metrics';
COMMENT ON COLUMN analytics.user_engagement.user_id IS 'References auth.users.id';
COMMENT ON COLUMN analytics.user_engagement.session_date IS 'Date this engagement record is for';
COMMENT ON COLUMN analytics.user_engagement.features_used IS 'JSON tracking features used during sessions';

-- Conversion Events Table
CREATE TABLE analytics.conversion_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL CHECK (
    event_type IN (
      'signup',
      'project_created',
      'document_completed',
      'deployment_completed',
      'credit_purchased',
      'subscription_started',
      'subscription_renewed',
      'subscription_cancelled'
    )
  ),
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  details JSONB DEFAULT '{}',
  attribution_source TEXT,
  attribution_campaign TEXT
);

COMMENT ON TABLE analytics.conversion_events IS 'Tracks important conversion events in the user journey';
COMMENT ON COLUMN analytics.conversion_events.user_id IS 'References auth.users.id';
COMMENT ON COLUMN analytics.conversion_events.event_type IS 'Type of conversion event';
COMMENT ON COLUMN analytics.conversion_events.details IS 'Additional details about the event';
COMMENT ON COLUMN analytics.conversion_events.attribution_source IS 'Traffic source for attribution';

-- =========================================================
-- Create Helper Functions for RLS and Credit Management
-- =========================================================

-- Function to check if a user owns a project
CREATE OR REPLACE FUNCTION api.owns_project(project_uuid UUID)
RETURNS BOOLEAN AS $$
DECLARE
  is_owner BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM api.projects
    WHERE id = project_uuid
    AND user_id = auth.uid()
    AND deleted_at IS NULL
  ) INTO is_owner;
  
  RETURN is_owner;
EXCEPTION
  WHEN others THEN
    RAISE WARNING 'Error checking project ownership: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, public, pg_temp;

COMMENT ON FUNCTION api.owns_project(UUID) IS 'Helper function to check if current user owns a project';

-- Function to check if a user has sufficient credits
CREATE OR REPLACE FUNCTION api.check_user_credits(user_uuid UUID, required_credits INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
  available_credits INTEGER;
BEGIN
  -- Get current credit balance
  SELECT credit_balance INTO available_credits
  FROM api.profiles
  WHERE id = user_uuid;
  
  -- Check if user has enough credits
  RETURN COALESCE(available_credits, 0) >= required_credits;
EXCEPTION
  WHEN others THEN
    RAISE WARNING 'Error checking credits for user %: %', user_uuid, SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, public, pg_temp;

COMMENT ON FUNCTION api.check_user_credits(UUID, INTEGER) IS 'Check if a user has sufficient credits for an operation';

-- Function to deduct credits from a user
CREATE OR REPLACE FUNCTION api.deduct_user_credits(
  user_uuid UUID, 
  credits_to_deduct INTEGER, 
  operation reference.credit_operation_type,
  related_entity_id UUID DEFAULT NULL,
  related_entity_type TEXT DEFAULT NULL,
  metadata JSONB DEFAULT '{}'
)
RETURNS BOOLEAN AS $$
DECLARE
  current_balance INTEGER;
  new_balance INTEGER;
BEGIN
  -- Check parameters
  IF credits_to_deduct <= 0 THEN
    RAISE EXCEPTION 'Credits to deduct must be positive';
  END IF;
  
  -- Get current balance with a lock for update
  SELECT credit_balance INTO current_balance
  FROM api.profiles
  WHERE id = user_uuid
  FOR UPDATE;
  
  -- Check if user has enough credits
  IF current_balance < credits_to_deduct THEN
    RETURN FALSE;
  END IF;
  
  -- Calculate new balance
  new_balance := current_balance - credits_to_deduct;
  
  -- Update user's credit balance
  UPDATE api.profiles
  SET credit_balance = new_balance
  WHERE id = user_uuid;
  
  -- Record the transaction
  INSERT INTO api.credit_transactions (
    user_id,
    operation_type,
    amount,
    balance_after,
    related_entity_id,
    related_entity_type,
    metadata,
    created_at
  ) VALUES (
    user_uuid,
    operation,
    -credits_to_deduct,
    new_balance,
    related_entity_id,
    related_entity_type,
    metadata,
    NOW()
  );
  
  RETURN TRUE;
EXCEPTION
  WHEN others THEN
    RAISE WARNING 'Error deducting credits for user %: %', user_uuid, SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, reference, public, pg_temp;

COMMENT ON FUNCTION api.deduct_user_credits(UUID, INTEGER, reference.credit_operation_type, UUID, TEXT, JSONB) 
IS 'Deduct credits from a user and record the transaction';

-- Function to add credits to a user
CREATE OR REPLACE FUNCTION api.add_user_credits(
  user_uuid UUID, 
  credits_to_add INTEGER, 
  operation reference.credit_operation_type,
  related_entity_id UUID DEFAULT NULL,
  related_entity_type TEXT DEFAULT NULL,
  metadata JSONB DEFAULT '{}'
)
RETURNS BOOLEAN AS $$
DECLARE
  current_balance INTEGER;
  new_balance INTEGER;
BEGIN
  -- Check parameters
  IF credits_to_add <= 0 THEN
    RAISE EXCEPTION 'Credits to add must be positive';
  END IF;
  
  -- Get current balance with a lock for update
  SELECT credit_balance INTO current_balance
  FROM api.profiles
  WHERE id = user_uuid
  FOR UPDATE;
  
  -- Calculate new balance
  new_balance := COALESCE(current_balance, 0) + credits_to_add;
  
  -- Update user's credit balance
  UPDATE api.profiles
  SET credit_balance = new_balance
  WHERE id = user_uuid;
  
  -- Record the transaction
  INSERT INTO api.credit_transactions (
    user_id,
    operation_type,
    amount,
    balance_after,
    related_entity_id,
    related_entity_type,
    metadata,
    created_at
  ) VALUES (
    user_uuid,
    operation,
    credits_to_add,
    new_balance,
    related_entity_id,
    related_entity_type,
    metadata,
    NOW()
  );
  
  RETURN TRUE;
EXCEPTION
  WHEN others THEN
    RAISE WARNING 'Error adding credits for user %: %', user_uuid, SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, reference, public, pg_temp;

COMMENT ON FUNCTION api.add_user_credits(UUID, INTEGER, reference.credit_operation_type, UUID, TEXT, JSONB) 
IS 'Add credits to a user and record the transaction';

-- Function to create a new document version
CREATE OR REPLACE FUNCTION api.create_document_version(
  document_uuid UUID, 
  new_content TEXT, 
  version_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  current_max_version INTEGER;
  new_version_number INTEGER;
  new_version_id UUID;
BEGIN
  -- Find the current maximum version number
  SELECT COALESCE(MAX(version_number), 0)
  INTO current_max_version
  FROM api.document_versions
  WHERE document_id = document_uuid;
  
  -- Calculate new version number
  new_version_number := current_max_version + 1;
  
  -- Create new version
  INSERT INTO api.document_versions (
    document_id,
    version_number,
    content,
    notes,
    created_by,
    created_at
  ) VALUES (
    document_uuid,
    new_version_number,
    new_content,
    version_notes,
    auth.uid(),
    NOW()
  )
  RETURNING id INTO new_version_id;
  
  -- Update the document to point to the new version
  UPDATE api.documents
  SET 
    content = new_content,
    current_version = new_version_id,
    updated_at = NOW(),
    updated_by = auth.uid()
  WHERE id = document_uuid;
  
  RETURN new_version_id;
EXCEPTION
  WHEN others THEN
    RAISE EXCEPTION 'Error creating document version: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, public, pg_temp;

COMMENT ON FUNCTION api.create_document_version(UUID, TEXT, TEXT) 
IS 'Create a new version of a document and update the current version pointer';

-- =========================================================
-- Analytics Helper Functions
-- =========================================================

-- Function to track project progress and update analytics
CREATE OR REPLACE FUNCTION analytics.update_project_metrics(
  project_uuid UUID,
  time_spent INTEGER DEFAULT 0,
  document_completed BOOLEAN DEFAULT FALSE
)
RETURNS VOID AS $$
DECLARE
  project_user_id UUID;
  project_highest_stage reference.framework_day;
  today_date DATE := CURRENT_DATE;
  metric_record_exists BOOLEAN;
BEGIN
  -- Get project owner and current highest stage
  SELECT user_id, framework_stage INTO project_user_id, project_highest_stage
  FROM api.projects
  WHERE id = project_uuid;
  
  -- Check if metrics record exists for today
  SELECT EXISTS (
    SELECT 1 FROM analytics.project_metrics
    WHERE project_id = project_uuid AND created_date = today_date
  ) INTO metric_record_exists;
  
  IF metric_record_exists THEN
    -- Update existing record
    UPDATE analytics.project_metrics
    SET 
      time_spent_seconds = time_spent_seconds + time_spent,
      highest_stage_reached = project_highest_stage,
      documents_completed = documents_completed + (CASE WHEN document_completed THEN 1 ELSE 0 END)
    WHERE project_id = project_uuid AND created_date = today_date;
  ELSE
    -- Create new record
    INSERT INTO analytics.project_metrics (
      project_id,
      user_id,
      created_date,
      highest_stage_reached,
      time_spent_seconds,
      documents_completed
    ) VALUES (
      project_uuid,
      project_user_id,
      today_date,
      project_highest_stage,
      time_spent,
      CASE WHEN document_completed THEN 1 ELSE 0 END
    );
  END IF;
EXCEPTION
  WHEN others THEN
    RAISE WARNING 'Error updating project metrics: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = analytics, api, reference, public, pg_temp;

COMMENT ON FUNCTION analytics.update_project_metrics(UUID, INTEGER, BOOLEAN) 
IS 'Update project metrics with usage data';

-- Function to refresh materialized views
CREATE OR REPLACE FUNCTION analytics.refresh_all_materialized_views()
RETURNS void AS $$
BEGIN
  -- We'll add the actual REFRESH commands once materialized views are created
  -- For now, just a placeholder that does nothing
  NULL;
EXCEPTION
  WHEN others THEN
    RAISE WARNING 'Error refreshing materialized views: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = analytics, public, pg_temp;

COMMENT ON FUNCTION analytics.refresh_all_materialized_views() 
IS 'Refresh all analytics materialized views in the correct order';

-- Function to compute user retention metrics
CREATE OR REPLACE FUNCTION analytics.compute_user_retention(days INTEGER DEFAULT 30)
RETURNS TABLE (
  cohort_date DATE,
  users_count INTEGER,
  retained_count INTEGER,
  retention_rate NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH cohorts AS (
    SELECT 
      DATE_TRUNC('day', created_at)::DATE AS signup_date,
      id AS user_id
    FROM auth.users
    WHERE created_at >= (CURRENT_DATE - (days || ' days')::INTERVAL)
  ),
  activity AS (
    SELECT 
      user_id,
      MAX(session_date) AS last_active_date
    FROM analytics.user_engagement
    GROUP BY user_id
  )
  SELECT 
    c.signup_date AS cohort_date,
    COUNT(DISTINCT c.user_id) AS users_count,
    COUNT(DISTINCT CASE 
      WHEN a.last_active_date >= (CURRENT_DATE - '7 days'::INTERVAL) 
      THEN c.user_id 
    END) AS retained_count,
    ROUND(
      COUNT(DISTINCT CASE 
        WHEN a.last_active_date >= (CURRENT_DATE - '7 days'::INTERVAL) 
        THEN c.user_id 
      END)::NUMERIC / 
      NULLIF(COUNT(DISTINCT c.user_id), 0)::NUMERIC * 100, 
      2
    ) AS retention_rate
  FROM cohorts c
  LEFT JOIN activity a ON c.user_id = a.user_id
  GROUP BY c.signup_date
  ORDER BY c.signup_date DESC;
EXCEPTION
  WHEN others THEN
    RAISE WARNING 'Error computing user retention: %', SQLERRM;
    RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = analytics, auth, public, pg_temp;

COMMENT ON FUNCTION analytics.compute_user_retention(INTEGER) 
IS 'Compute user retention metrics for a given period';

-- =========================================================
-- Trigger Functions for Data Integrity
-- =========================================================

-- Function to create a profile when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO api.profiles (
    id, 
    display_name, 
    credit_balance, 
    created_at, 
    updated_at
  ) VALUES (
    NEW.id, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email), 
    2, -- Start with 2 free credits
    NOW(), 
    NOW()
  );
  
  -- Log a signup event in analytics
  INSERT INTO analytics.conversion_events (
    user_id, 
    event_type, 
    occurred_at, 
    details
  ) VALUES (
    NEW.id, 
    'signup', 
    NOW(), 
    jsonb_build_object('email', NEW.email)
  );
  
  RETURN NEW;
EXCEPTION
  WHEN others THEN
    -- Log the error but don't prevent user creation
    RAISE WARNING 'Error creating profile for new user: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, api, analytics, pg_temp;

COMMENT ON FUNCTION public.handle_new_user() 
IS 'Create user profile and log signup event when a new user is created';

-- Function to track project activity
CREATE OR REPLACE FUNCTION api.track_project_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Update user engagement when project is updated
  INSERT INTO analytics.user_engagement (
    user_id,
    session_date,
    session_count,
    total_duration_seconds,
    projects_accessed,
    features_used
  ) VALUES (
    NEW.user_id,
    CURRENT_DATE,
    1,
    0,
    1,
    jsonb_build_object('project_updated', true)
  )
  ON CONFLICT (user_id, session_date) DO UPDATE
  SET 
    projects_accessed = analytics.user_engagement.projects_accessed + 1,
    features_used = analytics.user_engagement.features_used || 
                    jsonb_build_object('project_updated', true);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, analytics, public, pg_temp;

COMMENT ON FUNCTION api.track_project_update() 
IS 'Track project updates in user engagement metrics';

-- Function to handle project creation for analytics and credit management
CREATE OR REPLACE FUNCTION api.handle_project_creation()
RETURNS TRIGGER AS $$
DECLARE
  success BOOLEAN;
BEGIN
  -- Deduct credits for project creation (if applicable)
  success := api.deduct_user_credits(
    NEW.user_id, 
    1, 
    'project_creation'::reference.credit_operation_type, 
    NEW.id, 
    'project',
    jsonb_build_object('project_name', NEW.name)
  );
  
  -- Log the project creation event
  INSERT INTO analytics.conversion_events (
    user_id,
    event_type,
    occurred_at,
    details
  ) VALUES (
    NEW.user_id,
    'project_created',
    NOW(),
    jsonb_build_object('project_id', NEW.id, 'project_name', NEW.name)
  );
  
  RETURN NEW;
EXCEPTION
  WHEN others THEN
    RAISE WARNING 'Error handling project creation: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, analytics, reference, public, pg_temp;

COMMENT ON FUNCTION api.handle_project_creation() 
IS 'Handle credit deduction and event logging for new project creation';

-- Function to create initial document version when a document is created
CREATE OR REPLACE FUNCTION api.handle_document_creation()
RETURNS TRIGGER AS $$
DECLARE
  new_version_id UUID;
BEGIN
  -- Create initial version
  INSERT INTO api.document_versions (
    document_id,
    version_number,
    content,
    created_by,
    created_at
  ) VALUES (
    NEW.id,
    1,
    COALESCE(NEW.content, ''),
    NEW.created_by,
    NOW()
  )
  RETURNING id INTO new_version_id;
  
  -- Update document to point to this version
  UPDATE api.documents
  SET current_version = new_version_id
  WHERE id = NEW.id;
  
  -- Log document metrics
  INSERT INTO analytics.document_metrics (
    document_id,
    user_id,
    created_date,
    generation_attempts,
    content_length,
    is_completed
  ) VALUES (
    NEW.id,
    NEW.created_by,
    CURRENT_DATE,
    1,
    COALESCE(char_length(NEW.content), 0),
    NEW.status = 'completed'
  );
  
  RETURN NEW;
EXCEPTION
  WHEN others THEN
    RAISE WARNING 'Error handling document creation: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, analytics, public, pg_temp;

COMMENT ON FUNCTION api.handle_document_creation() 
IS 'Create initial version and metrics for new document';

-- Function to track document updates and create versions for significant changes
CREATE OR REPLACE FUNCTION api.handle_document_update()
RETURNS TRIGGER AS $$
DECLARE
  content_changed BOOLEAN;
  status_changed BOOLEAN;
  new_version_id UUID;
BEGIN
  -- Check if content changed significantly 
  content_changed := (OLD.content IS DISTINCT FROM NEW.content);
  status_changed := (OLD.status IS DISTINCT FROM NEW.status);
  
  -- If content changed significantly, create a new version
  IF content_changed THEN
    INSERT INTO api.document_versions (
      document_id,
      version_number,
      content,
      created_by,
      created_at
    ) VALUES (
      NEW.id,
      COALESCE((
        SELECT MAX(version_number) + 1
        FROM api.document_versions
        WHERE document_id = NEW.id
      ), 1),
      NEW.content,
      NEW.updated_by,
      NOW()
    )
    RETURNING id INTO new_version_id;
    
    -- Update the current_version pointer
    NEW.current_version = new_version_id;
  END IF;
  
  -- Update analytics if status changed to completed
  IF status_changed AND NEW.status = 'completed' THEN
    -- Log document completion
    INSERT INTO analytics.conversion_events (
      user_id,
      event_type,
      occurred_at,
      details
    ) VALUES (
      NEW.updated_by,
      'document_completed',
      NOW(),
      jsonb_build_object(
        'document_id', NEW.id, 
        'document_type', NEW.type,
        'project_id', NEW.project_id
      )
    );
    
    -- Update document metrics
    INSERT INTO analytics.document_metrics (
      document_id,
      user_id,
      created_date,
      is_completed
    ) VALUES (
      NEW.id,
      NEW.updated_by,
      CURRENT_DATE,
      TRUE
    )
    ON CONFLICT (document_id, created_date) DO UPDATE
    SET 
      is_completed = TRUE,
      edit_count = analytics.document_metrics.edit_count + 1,
      content_length = COALESCE(char_length(NEW.content), 0);
  ELSIF content_changed THEN
    -- Just update edit metrics
    INSERT INTO analytics.document_metrics (
      document_id,
      user_id,
      created_date,
      edit_count,
      content_length
    ) VALUES (
      NEW.id,
      NEW.updated_by,
      CURRENT_DATE,
      1,
      COALESCE(char_length(NEW.content), 0)
    )
    ON CONFLICT (document_id, created_date) DO UPDATE
    SET 
      edit_count = analytics.document_metrics.edit_count + 1,
      content_length = COALESCE(char_length(NEW.content), 0);
  END IF;
  
  RETURN NEW;
EXCEPTION
  WHEN others THEN
    RAISE WARNING 'Error handling document update: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, analytics, public, pg_temp;

COMMENT ON FUNCTION api.handle_document_update() 
IS 'Track document updates, create versions for changes, and update metrics';

-- Function to track deployment status changes
CREATE OR REPLACE FUNCTION api.handle_deployment_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Track when a deployment is completed successfully
  IF OLD.status != 'completed' AND NEW.status = 'completed' THEN
    -- Log deployment completion
    INSERT INTO analytics.conversion_events (
      user_id,
      event_type,
      occurred_at,
      details
    ) VALUES (
      NEW.updated_by,
      'deployment_completed',
      NOW(),
      jsonb_build_object(
        'deployment_id', NEW.id, 
        'project_id', NEW.project_id,
        'platform', NEW.platform,
        'url', NEW.deployment_url
      )
    );
    
    -- Update project metrics to record successful deployment
    UPDATE analytics.project_metrics
    SET deployment_attempted = TRUE,
        deployment_successful = TRUE
    WHERE project_id = NEW.project_id
    AND created_date = CURRENT_DATE;
    
    -- If this is the first deployment, update project progress
    UPDATE api.projects
    SET 
      progress_percentage = GREATEST(progress_percentage, 90),
      updated_at = NOW(),
      updated_by = NEW.updated_by
    WHERE id = NEW.project_id
    AND progress_percentage < 90;
  END IF;
  
  RETURN NEW;
EXCEPTION
  WHEN others THEN
    RAISE WARNING 'Error handling deployment update: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, analytics, public, pg_temp;

COMMENT ON FUNCTION api.handle_deployment_update() 
IS 'Track deployment status changes and update project progress';

-- Function to handle subscription status changes
CREATE OR REPLACE FUNCTION stripe.handle_subscription_update()
RETURNS TRIGGER AS $$
DECLARE
  user_id UUID;
  subscription_product_id TEXT;
  monthly_credits INTEGER;
BEGIN
  -- Get user ID from customer record
  SELECT c.user_id INTO user_id
  FROM stripe.customers c
  WHERE c.id = NEW.customer_id;
  
  -- Get product ID from price
  SELECT p.product_id INTO subscription_product_id
  FROM stripe.prices p
  WHERE p.id = NEW.price_id;
  
  -- Check if this is a new active subscription
  IF (OLD IS NULL OR OLD.status != 'active') AND NEW.status = 'active' THEN
    -- Get monthly credit allocation for this subscription
    SELECT sb.monthly_credits INTO monthly_credits
    FROM stripe.subscription_benefits sb
    WHERE sb.product_id = subscription_product_id;
    
    -- Add subscription credits to user
    IF monthly_credits > 0 THEN
      PERFORM api.add_user_credits(
        user_id,
        monthly_credits,
        'subscription_renewal'::reference.credit_operation_type,
        NULL,
        NULL,
        jsonb_build_object(
          'subscription_id', NEW.id,
          'product_id', subscription_product_id
        )
      );
    END IF;
    
    -- Update user's subscription tier
    UPDATE api.profiles
    SET subscription_tier = subscription_product_id
    WHERE id = user_id;
    
    -- Log subscription start event
    INSERT INTO analytics.conversion_events (
      user_id,
      event_type,
      occurred_at,
      details
    ) VALUES (
      user_id,
      'subscription_started',
      NOW(),
      jsonb_build_object(
        'subscription_id', NEW.id,
        'product_id', subscription_product_id,
        'price_id', NEW.price_id
      )
    );
  -- Check if subscription was cancelled
  ELSIF OLD.status = 'active' AND NEW.status = 'canceled' THEN
    -- Log subscription cancellation
    INSERT INTO analytics.conversion_events (
      user_id,
      event_type,
      occurred_at,
      details
    ) VALUES (
      user_id,
      'subscription_cancelled',
      NOW(),
      jsonb_build_object(
        'subscription_id', NEW.id,
        'product_id', subscription_product_id,
        'price_id', NEW.price_id
      )
    );
  -- Check for subscription renewal (period change with active status)
  ELSIF NEW.status = 'active' AND 
        OLD.current_period_end != NEW.current_period_end AND
        NEW.current_period_start >= OLD.current_period_end THEN
    -- Get monthly credit allocation for this subscription
    SELECT sb.monthly_credits INTO monthly_credits
    FROM stripe.subscription_benefits sb
    WHERE sb.product_id = subscription_product_id;
    
    -- Add renewal credits to user
    IF monthly_credits > 0 THEN
      PERFORM api.add_user_credits(
        user_id,
        monthly_credits,
        'subscription_renewal'::reference.credit_operation_type,
        NULL,
        NULL,
        jsonb_build_object(
          'subscription_id', NEW.id,
          'product_id', subscription_product_id,
          'renewal_date', NEW.current_period_start
        )
      );
    END IF;
    
    -- Log subscription renewal event
    INSERT INTO analytics.conversion_events (
      user_id,
      event_type,
      occurred_at,
      details
    ) VALUES (
      user_id,
      'subscription_renewed',
      NOW(),
      jsonb_build_object(
        'subscription_id', NEW.id,
        'product_id', subscription_product_id,
        'price_id', NEW.price_id,
        'renewal_date', NEW.current_period_start
      )
    );
  END IF;
  
  RETURN NEW;
EXCEPTION
  WHEN others THEN
    RAISE WARNING 'Error handling subscription update: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = stripe, api, analytics, reference, public, pg_temp;

COMMENT ON FUNCTION stripe.handle_subscription_update() 
IS 'Handle subscription status changes, credit allocation, and event logging';

-- =========================================================
-- Create Database Triggers
-- =========================================================

-- Create user profile trigger
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create timestamp update triggers
CREATE TRIGGER set_timestamp_profiles
BEFORE UPDATE ON api.profiles
FOR EACH ROW EXECUTE FUNCTION public.trigger_updated_at();

CREATE TRIGGER set_timestamp_projects
BEFORE UPDATE ON api.projects
FOR EACH ROW EXECUTE FUNCTION public.trigger_updated_at();

CREATE TRIGGER set_timestamp_documents
BEFORE UPDATE ON api.documents
FOR EACH ROW EXECUTE FUNCTION public.trigger_updated_at();

CREATE TRIGGER set_timestamp_deployments
BEFORE UPDATE ON api.deployments
FOR EACH ROW EXECUTE FUNCTION public.trigger_updated_at();

CREATE TRIGGER set_timestamp_stripe_customers
BEFORE UPDATE ON stripe.customers
FOR EACH ROW EXECUTE FUNCTION public.trigger_updated_at();

CREATE TRIGGER set_timestamp_stripe_products
BEFORE UPDATE ON stripe.products
FOR EACH ROW EXECUTE FUNCTION public.trigger_updated_at();

CREATE TRIGGER set_timestamp_stripe_prices
BEFORE UPDATE ON stripe.prices
FOR EACH ROW EXECUTE FUNCTION public.trigger_updated_at();

CREATE TRIGGER set_timestamp_stripe_subscriptions
BEFORE UPDATE ON stripe.subscriptions
FOR EACH ROW EXECUTE FUNCTION public.trigger_updated_at();

CREATE TRIGGER set_timestamp_subscription_benefits
BEFORE UPDATE ON stripe.subscription_benefits
FOR EACH ROW EXECUTE FUNCTION public.trigger_updated_at();

-- Create user ID management triggers
CREATE TRIGGER set_user_ids_projects
BEFORE INSERT OR UPDATE ON api.projects
FOR EACH ROW EXECUTE FUNCTION public.set_user_ids();

CREATE TRIGGER set_user_ids_documents
BEFORE INSERT OR UPDATE ON api.documents
FOR EACH ROW EXECUTE FUNCTION public.set_user_ids();

CREATE TRIGGER set_user_ids_deployments
BEFORE INSERT OR UPDATE ON api.deployments
FOR EACH ROW EXECUTE FUNCTION public.set_user_ids();

-- Create project activity tracking triggers
CREATE TRIGGER track_project_activity
AFTER UPDATE ON api.projects
FOR EACH ROW EXECUTE FUNCTION api.track_project_update();

CREATE TRIGGER on_project_created
AFTER INSERT ON api.projects
FOR EACH ROW EXECUTE FUNCTION api.handle_project_creation();

-- Create document management triggers
CREATE TRIGGER on_document_created
AFTER INSERT ON api.documents
FOR EACH ROW EXECUTE FUNCTION api.handle_document_creation();

CREATE TRIGGER on_document_updated
BEFORE UPDATE ON api.documents
FOR EACH ROW EXECUTE FUNCTION api.handle_document_update();

-- Create deployment tracking trigger
CREATE TRIGGER on_deployment_updated
AFTER UPDATE ON api.deployments
FOR EACH ROW EXECUTE FUNCTION api.handle_deployment_update();

-- Create subscription management trigger
CREATE TRIGGER on_subscription_updated
AFTER INSERT OR UPDATE ON stripe.subscriptions
FOR EACH ROW EXECUTE FUNCTION stripe.handle_subscription_update();

-- =========================================================
-- Enable RLS and Create Security Policies
-- =========================================================

-- Enable RLS on all api schema tables
ALTER TABLE api.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.document_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.deployments ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.credit_transactions ENABLE ROW LEVEL SECURITY;

-- Enable RLS on stripe schema tables to protect billing data
ALTER TABLE stripe.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe.subscription_benefits ENABLE ROW LEVEL SECURITY;

-- Enable RLS on analytics tables for user-specific data
ALTER TABLE analytics.project_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.document_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.user_engagement ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.conversion_events ENABLE ROW LEVEL SECURITY;

-- =========================================================
-- Profile Policies
-- =========================================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON api.profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON api.profiles
  FOR UPDATE
  USING (auth.uid() = id);

-- Admin users can view all profiles (using JWT claim for role)
CREATE POLICY "Admins can view all profiles"
  ON api.profiles
  FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

-- =========================================================
-- Project Policies
-- =========================================================

-- Users can view their own projects (that aren't deleted)
CREATE POLICY "Users can view own projects"
  ON api.projects
  FOR SELECT
  USING (auth.uid() = user_id AND deleted_at IS NULL);

-- Users can insert their own projects
CREATE POLICY "Users can create own projects"
  ON api.projects
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id AND 
    auth.uid() = created_by AND
    auth.uid() = updated_by
  );

-- Users can update their own projects
CREATE POLICY "Users can update own projects"
  ON api.projects
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id AND
    auth.uid() = updated_by
  );

-- Users can delete (soft delete) their own projects
CREATE POLICY "Users can delete own projects"
  ON api.projects
  FOR UPDATE
  USING (
    auth.uid() = user_id AND
    deleted_at IS NULL AND
    NEW.deleted_at IS NOT NULL AND
    NEW.status = 'archived'
  );

-- Admin access to all projects
CREATE POLICY "Admins can view all projects"
  ON api.projects
  FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

-- =========================================================
-- Document Policies
-- =========================================================

-- Users can view documents for their own projects
CREATE POLICY "Users can view own documents"
  ON api.documents
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM api.projects
      WHERE api.projects.id = api.documents.project_id
      AND api.projects.user_id = auth.uid()
      AND api.projects.deleted_at IS NULL
    )
  );

-- Users can create documents for their own projects
CREATE POLICY "Users can create documents for own projects"
  ON api.documents
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM api.projects
      WHERE api.projects.id = api.documents.project_id
      AND api.projects.user_id = auth.uid()
      AND api.projects.deleted_at IS NULL
    )
    AND auth.uid() = created_by
    AND auth.uid() = updated_by
  );

-- Users can update documents for their own projects
CREATE POLICY "Users can update own documents"
  ON api.documents
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM api.projects
      WHERE api.projects.id = api.documents.project_id
      AND api.projects.user_id = auth.uid()
      AND api.projects.deleted_at IS NULL
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM api.projects
      WHERE api.projects.id = api.documents.project_id
      AND api.projects.user_id = auth.uid()
      AND api.projects.deleted_at IS NULL
    )
    AND auth.uid() = updated_by
  );

-- Users can delete documents for their own projects
CREATE POLICY "Users can delete own documents"
  ON api.documents
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM api.projects
      WHERE api.projects.id = api.documents.project_id
      AND api.projects.user_id = auth.uid()
      AND api.projects.deleted_at IS NULL
    )
  );

-- Admin access to all documents
CREATE POLICY "Admins can view all documents"
  ON api.documents
  FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

-- =========================================================
-- Document Versions Policies
-- =========================================================

-- Users can view document versions for their own documents
CREATE POLICY "Users can view own document versions"
  ON api.document_versions
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM api.documents
      JOIN api.projects ON api.documents.project_id = api.projects.id
      WHERE api.document_versions.document_id = api.documents.id
      AND api.projects.user_id = auth.uid()
      AND api.projects.deleted_at IS NULL
    )
  );

-- Users can create document versions for their own documents
CREATE POLICY "Users can create versions for own documents"
  ON api.document_versions
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM api.documents
      JOIN api.projects ON api.documents.project_id = api.projects.id
      WHERE api.document_versions.document_id = api.documents.id
      AND api.projects.user_id = auth.uid()
      AND api.projects.deleted_at IS NULL
    )
    AND auth.uid() = created_by
  );

-- Users can delete document versions for their own documents (if needed)
CREATE POLICY "Users can delete own document versions"
  ON api.document_versions
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM api.documents
      JOIN api.projects ON api.documents.project_id = api.projects.id
      WHERE api.document_versions.document_id = api.documents.id
      AND api.projects.user_id = auth.uid()
      AND api.projects.deleted_at IS NULL
    )
  );

-- Admin access to all document versions
CREATE POLICY "Admins can view all document versions"
  ON api.document_versions
  FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

-- =========================================================
-- Deployments Policies
-- =========================================================

-- Users can view deployments for their own projects
CREATE POLICY "Users can view own deployments"
  ON api.deployments
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM api.projects
      WHERE api.projects.id = api.deployments.project_id
      AND api.projects.user_id = auth.uid()
      AND api.projects.deleted_at IS NULL
    )
  );

-- Users can create deployments for their own projects
CREATE POLICY "Users can create deployments for own projects"
  ON api.deployments
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM api.projects
      WHERE api.projects.id = api.deployments.project_id
      AND api.projects.user_id = auth.uid()
      AND api.projects.deleted_at IS NULL
    )
    AND auth.uid() = created_by
    AND auth.uid() = updated_by
  );

-- Users can update deployments for their own projects
CREATE POLICY "Users can update own deployments"
  ON api.deployments
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM api.projects
      WHERE api.projects.id = api.deployments.project_id
      AND api.projects.user_id = auth.uid()
      AND api.projects.deleted_at IS NULL
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM api.projects
      WHERE api.projects.id = api.deployments.project_id
      AND api.projects.user_id = auth.uid()
      AND api.projects.deleted_at IS NULL
    )
    AND auth.uid() = updated_by
  );

-- Users can delete deployments for their own projects
CREATE POLICY "Users can delete own deployments"
  ON api.deployments
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM api.projects
      WHERE api.projects.id = api.deployments.project_id
      AND api.projects.user_id = auth.uid()
      AND api.projects.deleted_at IS NULL
    )
  );

-- Admin access to all deployments
CREATE POLICY "Admins can view all deployments"
  ON api.deployments
  FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

-- =========================================================
-- Credit Transactions Policies
-- =========================================================

-- Users can view their own credit transactions
CREATE POLICY "Users can view own credit transactions"
  ON api.credit_transactions
  FOR SELECT
  USING (auth.uid() = user_id);

-- Admin access to all credit transactions
CREATE POLICY "Admins can view all credit transactions"
  ON api.credit_transactions
  FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

-- =========================================================
-- Stripe Integration Policies
-- =========================================================

-- Users can view their own Stripe customer data
CREATE POLICY "Users can view own customer data"
  ON stripe.customers
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can view their own subscriptions
CREATE POLICY "Users can view own subscriptions"
  ON stripe.subscriptions
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM stripe.customers
      WHERE stripe.customers.id = stripe.subscriptions.customer_id
      AND stripe.customers.user_id = auth.uid()
    )
  );

-- Users can view subscription benefits for all products
CREATE POLICY "Users can view all subscription benefits"
  ON stripe.subscription_benefits
  FOR SELECT
  USING (true);

-- Admin access to all Stripe data
CREATE POLICY "Admins can view all customers"
  ON stripe.customers
  FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Admins can view all subscriptions"
  ON stripe.subscriptions
  FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

-- =========================================================
-- Analytics Policies
-- =========================================================

-- Users can view their own project metrics
CREATE POLICY "Users can view own project metrics"
  ON analytics.project_metrics
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can view their own document metrics
CREATE POLICY "Users can view own document metrics"
  ON analytics.document_metrics
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can view their own engagement data
CREATE POLICY "Users can view own engagement data"
  ON analytics.user_engagement
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can view their own conversion events
CREATE POLICY "Users can view own conversion events"
  ON analytics.conversion_events
  FOR SELECT
  USING (auth.uid() = user_id);

-- Admin access to all analytics data
CREATE POLICY "Admins can view all project metrics"
  ON analytics.project_metrics
  FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Admins can view all document metrics"
  ON analytics.document_metrics
  FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Admins can view all user engagement data"
  ON analytics.user_engagement
  FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Admins can view all conversion events"
  ON analytics.conversion_events
  FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

-- =========================================================
-- Views and Materialized Views
-- =========================================================

-- User Profile and Project Summary View
CREATE OR REPLACE VIEW api.user_project_summary AS
SELECT
  p.id AS user_id,
  p.display_name,
  p.avatar_url,
  p.credit_balance,
  p.subscription_tier,
  COUNT(pr.id) AS total_projects,
  SUM(CASE WHEN pr.status = 'completed' THEN 1 ELSE 0 END) AS completed_projects,
  MAX(pr.updated_at) AS last_project_update,
  COALESCE(MAX(pr.progress_percentage), 0) AS max_progress
FROM
  api.profiles p
LEFT JOIN
  api.projects pr ON p.id = pr.user_id AND pr.deleted_at IS NULL
GROUP BY
  p.id, p.display_name, p.avatar_url, p.credit_balance, p.subscription_tier;

COMMENT ON VIEW api.user_project_summary IS 'Summarized user profile data with project statistics';

-- Project Details View
CREATE OR REPLACE VIEW api.project_details AS
SELECT
  p.id AS project_id,
  p.name AS project_name,
  p.description,
  p.status,
  p.framework_stage,
  p.progress_percentage,
  p.created_at,
  p.updated_at,
  u.display_name AS owner_name,
  COUNT(DISTINCT d.id) AS document_count,
  SUM(CASE WHEN d.status = 'completed' THEN 1 ELSE 0 END) AS completed_documents,
  COUNT(DISTINCT dv.id) AS version_count,
  COUNT(DISTINCT dep.id) AS deployment_count,
  MAX(dep.deployment_url) AS latest_deployment_url
FROM
  api.projects p
JOIN
  api.profiles u ON p.user_id = u.id
LEFT JOIN
  api.documents d ON p.id = d.project_id
LEFT JOIN
  api.document_versions dv ON d.id = dv.document_id
LEFT JOIN
  api.deployments dep ON p.id = dep.project_id
WHERE
  p.deleted_at IS NULL
GROUP BY
  p.id, p.name, p.description, p.status, p.framework_stage, 
  p.progress_percentage, p.created_at, p.updated_at, u.display_name;

COMMENT ON VIEW api.project_details IS 'Detailed project information with document and deployment counts';

-- Credit Usage Materialized View
CREATE MATERIALIZED VIEW analytics.credit_usage_summary AS
SELECT
  ct.user_id,
  DATE_TRUNC('day', ct.created_at) AS usage_date,
  ct.operation_type,
  SUM(CASE WHEN ct.amount < 0 THEN ABS(ct.amount) ELSE 0 END) AS credits_used,
  SUM(CASE WHEN ct.amount > 0 THEN ct.amount ELSE 0 END) AS credits_added,
  COUNT(*) AS transaction_count
FROM
  api.credit_transactions ct
GROUP BY
  ct.user_id, DATE_TRUNC('day', ct.created_at), ct.operation_type
WITH NO DATA;

COMMENT ON MATERIALIZED VIEW analytics.credit_usage_summary IS 'Summary of credit usage patterns by user and operation type';

-- Create unique index for the materialized view
CREATE UNIQUE INDEX idx_credit_usage_summary_user_date_op 
ON analytics.credit_usage_summary (user_id, usage_date, operation_type);

-- User Activity Timeline View
CREATE OR REPLACE VIEW analytics.user_activity_timeline AS
SELECT
  u.id AS user_id,
  u.display_name,
  u.created_at AS signup_date,
  COALESCE(MAX(p.created_at), u.created_at) AS first_project_date,
  COALESCE(MAX(d.created_at), u.created_at) AS first_document_date,
  COALESCE(MAX(dep.created_at), u.created_at) AS first_deployment_date,
  COALESCE(MAX(s.created_at), u.created_at) AS first_subscription_date,
  COALESCE(MAX(ct.created_at), u.created_at) AS first_purchase_date,
  COALESCE(MAX(ue.session_date), u.created_at::date) AS last_active_date,
  GREATEST(
    COALESCE(MAX(p.updated_at), u.created_at),
    COALESCE(MAX(d.updated_at), u.created_at),
    COALESCE(MAX(dep.updated_at), u.created_at)
  ) AS last_content_update
FROM
  api.profiles u
LEFT JOIN
  api.projects p ON u.id = p.user_id AND p.deleted_at IS NULL
LEFT JOIN
  api.documents d ON p.id = d.project_id
LEFT JOIN
  api.deployments dep ON p.id = dep.project_id
LEFT JOIN
  stripe.customers c ON u.id = c.user_id
LEFT JOIN
  stripe.subscriptions s ON c.id = s.customer_id
LEFT JOIN
  api.credit_transactions ct ON u.id = ct.user_id AND ct.operation_type = 'purchase'
LEFT JOIN
  analytics.user_engagement ue ON u.id = ue.user_id
GROUP BY
  u.id, u.display_name, u.created_at;

COMMENT ON VIEW analytics.user_activity_timeline IS 'Timeline view of user activity across the platform';

-- Update refresh_all_materialized_views function with the actual views
CREATE OR REPLACE FUNCTION analytics.refresh_all_materialized_views()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.credit_usage_summary;
  -- Add other materialized views here as they are created
EXCEPTION
  WHEN others THEN
    RAISE WARNING 'Error refreshing materialized views: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = analytics, public, pg_temp;

-- =========================================================
-- Indexes for Performance Optimization
-- =========================================================

-- Profiles Table Indexes
CREATE INDEX idx_profiles_display_name ON api.profiles USING gin (display_name gin_trgm_ops);
CREATE INDEX idx_profiles_credit_balance ON api.profiles (credit_balance);
CREATE INDEX idx_profiles_last_login ON api.profiles (last_login);
CREATE INDEX idx_profiles_notification_prefs ON api.profiles USING gin (notification_preferences);
CREATE INDEX idx_profiles_subscription_tier ON api.profiles (subscription_tier);

-- Projects Table Indexes
CREATE INDEX idx_projects_user_id ON api.projects (user_id);
CREATE INDEX idx_projects_status ON api.projects (status);
CREATE INDEX idx_projects_framework_stage ON api.projects (framework_stage);
CREATE INDEX idx_projects_deleted_at ON api.projects (deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_projects_name ON api.projects USING gin (name gin_trgm_ops);
CREATE INDEX idx_projects_created_at ON api.projects (created_at);
CREATE INDEX idx_projects_progress ON api.projects (progress_percentage);
CREATE INDEX idx_projects_metadata ON api.projects USING gin (metadata);
CREATE INDEX idx_projects_user_status_date ON api.projects (user_id, status, created_at);

-- Documents Table Indexes
CREATE INDEX idx_documents_project_id ON api.documents (project_id);
CREATE INDEX idx_documents_type ON api.documents (type);
CREATE INDEX idx_documents_status ON api.documents (status);
CREATE INDEX idx_documents_current_version ON api.documents (current_version);
CREATE INDEX idx_documents_title ON api.documents USING gin (title gin_trgm_ops);
CREATE INDEX idx_documents_content_search ON api.documents USING gin (to_tsvector('english', coalesce(content, '')));
CREATE INDEX idx_documents_metadata ON api.documents USING gin (metadata);
CREATE INDEX idx_documents_project_type ON api.documents (project_id, type);
CREATE INDEX idx_documents_created_at ON api.documents (created_at);

-- Document Versions Table Indexes
CREATE INDEX idx_document_versions_document_id ON api.document_versions (document_id);
CREATE INDEX idx_document_versions_content_search ON api.document_versions USING gin (to_tsvector('english', coalesce(content, '')));
CREATE INDEX idx_document_versions_created_at ON api.document_versions (created_at);
CREATE INDEX idx_document_versions_created_by ON api.document_versions (created_by);

-- Deployments Table Indexes
CREATE INDEX idx_deployments_project_id ON api.deployments (project_id);
CREATE INDEX idx_deployments_status ON api.deployments (status);
CREATE INDEX idx_deployments_platform ON api.deployments (platform);
CREATE INDEX idx_deployments_created_at ON api.deployments (created_at);
CREATE INDEX idx_deployments_url ON api.deployments USING gin (deployment_url gin_trgm_ops);
CREATE INDEX idx_deployments_metadata ON api.deployments USING gin (metadata);

-- Credit Transactions Table Indexes
CREATE INDEX idx_credit_transactions_user_id ON api.credit_transactions (user_id);
CREATE INDEX idx_credit_transactions_operation_type ON api.credit_transactions (operation_type);
CREATE INDEX idx_credit_transactions_created_at ON api.credit_transactions (created_at);
CREATE INDEX idx_credit_transactions_user_operation ON api.credit_transactions (user_id, operation_type);
CREATE INDEX idx_credit_transactions_related_entity ON api.credit_transactions (related_entity_id) 
WHERE related_entity_id IS NOT NULL;
CREATE INDEX idx_credit_transactions_metadata ON api.credit_transactions USING gin (metadata);

-- Stripe Tables Indexes
CREATE INDEX idx_stripe_customers_user_id ON stripe.customers (user_id);
CREATE INDEX idx_stripe_prices_product_id ON stripe.prices (product_id);
CREATE INDEX idx_stripe_subscriptions_customer_id ON stripe.subscriptions (customer_id);
CREATE INDEX idx_stripe_subscriptions_status ON stripe.subscriptions (status);
CREATE INDEX idx_stripe_webhook_events_type ON stripe.webhook_events (type);
CREATE INDEX idx_stripe_webhook_events_processing_status ON stripe.webhook_events (processing_status);
CREATE INDEX idx_stripe_webhook_events_created ON stripe.webhook_events (created);
CREATE INDEX idx_stripe_webhook_events_processed_at ON stripe.webhook_events (processed_at) 
WHERE processed_at IS NOT NULL;
CREATE INDEX idx_stripe_webhook_processing_status_attempts ON stripe.webhook_events 
(processing_status, processing_attempts) 
WHERE processing_status = 'pending';
CREATE INDEX idx_subscription_benefits_monthly_credits ON stripe.subscription_benefits (monthly_credits);

-- Analytics Tables Indexes
CREATE INDEX idx_project_metrics_user_id ON analytics.project_metrics (user_id);
CREATE INDEX idx_project_metrics_created_date ON analytics.project_metrics (created_date);
CREATE INDEX idx_project_metrics_highest_stage ON analytics.project_metrics (highest_stage_reached);
CREATE INDEX idx_project_metrics_deployment ON analytics.project_metrics (deployment_attempted, deployment_successful);

CREATE INDEX idx_document_metrics_user_id ON analytics.document_metrics (user_id);
CREATE INDEX idx_document_metrics_created_date ON analytics.document_metrics (created_date);
CREATE INDEX idx_document_metrics_is_completed ON analytics.document_metrics (is_completed);

CREATE INDEX idx_user_engagement_user_id ON analytics.user_engagement (user_id);
CREATE INDEX idx_user_engagement_session_date ON analytics.user_engagement (session_date);
CREATE INDEX idx_user_engagement_duration ON analytics.user_engagement (total_duration_seconds);
CREATE INDEX idx_user_engagement_features ON analytics.user_engagement USING gin (features_used);

CREATE INDEX idx_conversion_events_user_id ON analytics.conversion_events (user_id);
CREATE INDEX idx_conversion_events_event_type ON analytics.conversion_events (event_type);
CREATE INDEX idx_conversion_events_occurred_at ON analytics.conversion_events (occurred_at);
CREATE INDEX idx_conversion_events_attribution ON analytics.conversion_events (attribution_source, attribution_campaign) 
WHERE attribution_source IS NOT NULL;
CREATE INDEX idx_conversion_events_details ON analytics.conversion_events USING gin (details);

-- =========================================================
-- Create Helper Functions for Common Application Operations
-- =========================================================

-- Function to get project details with documents efficiently
CREATE OR REPLACE FUNCTION api.get_project_with_documents(project_uuid UUID)
RETURNS TABLE (
  project_id UUID,
  project_name TEXT,
  project_description TEXT,
  project_status reference.project_status,
  framework_stage reference.framework_day,
  progress_percentage INTEGER,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  document_id UUID,
  document_type reference.document_type,
  document_title TEXT,
  document_status TEXT,
  document_updated_at TIMESTAMPTZ,
  version_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id AS project_id,
    p.name AS project_name,
    p.description AS project_description,
    p.status AS project_status,
    p.framework_stage,
    p.progress_percentage,
    p.created_at,
    p.updated_at,
    d.id AS document_id,
    d.type AS document_type,
    d.title AS document_title,
    d.status AS document_status,
    d.updated_at AS document_updated_at,
    COALESCE(
      (SELECT COUNT(*) FROM api.document_versions dv WHERE dv.document_id = d.id),
      0
    ) AS version_count
  FROM
    api.projects p
  LEFT JOIN
    api.documents d ON p.id = d.project_id
  WHERE
    p.id = project_uuid
    AND p.deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, reference, public, pg_temp;

COMMENT ON FUNCTION api.get_project_with_documents(UUID) 
IS 'Efficiently get project details with all associated documents';

-- Function to get user dashboard summary efficiently
CREATE OR REPLACE FUNCTION api.get_user_dashboard_summary(user_uuid UUID)
RETURNS TABLE (
  user_id UUID,
  display_name TEXT,
  credit_balance INTEGER,
  subscription_tier TEXT,
  project_count INTEGER,
  active_projects INTEGER,
  completed_projects INTEGER,
  recent_projects JSON,
  document_count INTEGER,
  deployment_count INTEGER,
  last_activity TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  WITH recent_projects AS (
    SELECT
      p.id,
      p.name,
      p.status,
      p.progress_percentage,
      p.updated_at,
      p.framework_stage
    FROM
      api.projects p
    WHERE
      p.user_id = user_uuid
      AND p.deleted_at IS NULL
    ORDER BY
      p.updated_at DESC
    LIMIT 5
  ),
  project_stats AS (
    SELECT
      COUNT(*) AS total_projects,
      COUNT(*) FILTER (WHERE status = 'in_progress') AS active_projects,
      COUNT(*) FILTER (WHERE status = 'completed') AS completed_projects
    FROM
      api.projects
    WHERE
      user_id = user_uuid
      AND deleted_at IS NULL
  ),
  document_stats AS (
    SELECT
      COUNT(*) AS total_documents
    FROM
      api.documents d
    JOIN
      api.projects p ON d.project_id = p.id
    WHERE
      p.user_id = user_uuid
      AND p.deleted_at IS NULL
  ),
  deployment_stats AS (
    SELECT
      COUNT(*) AS total_deployments
    FROM
      api.deployments d
    JOIN
      api.projects p ON d.project_id = p.id
    WHERE
      p.user_id = user_uuid
      AND p.deleted_at IS NULL
  ),
  last_activity AS (
    SELECT
      GREATEST(
        COALESCE(MAX(p.updated_at), '1970-01-01'::TIMESTAMPTZ),
        COALESCE(MAX(d.updated_at), '1970-01-01'::TIMESTAMPTZ),
        COALESCE(MAX(dep.updated_at), '1970-01-01'::TIMESTAMPTZ)
      ) AS latest_activity
    FROM
      api.profiles u
    LEFT JOIN
      api.projects p ON u.id = p.user_id AND p.deleted_at IS NULL
    LEFT JOIN
      api.documents d ON p.id = d.project_id
    LEFT JOIN
      api.deployments dep ON p.id = dep.project_id
    WHERE
      u.id = user_uuid
  )
  SELECT
    u.id AS user_id,
    u.display_name,
    u.credit_balance,
    u.subscription_tier,
    ps.total_projects,
    ps.active_projects,
    ps.completed_projects,
    COALESCE(
      (SELECT json_agg(rp) FROM recent_projects rp),
      '[]'::json
    ) AS recent_projects,
    ds.total_documents,
    dep.total_deployments,
    la.latest_activity
  FROM
    api.profiles u
  CROSS JOIN
    project_stats ps
  CROSS JOIN
    document_stats ds
  CROSS JOIN
    deployment_stats dep
  CROSS JOIN
    last_activity la
  WHERE
    u.id = user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, public, pg_temp;

COMMENT ON FUNCTION api.get_user_dashboard_summary(UUID) 
IS 'Get comprehensive dashboard summary for a user with projects, documents, and activity';

-- Function to "warm" important caches after schema changes or deployments
CREATE OR REPLACE FUNCTION public.warm_database_caches()
RETURNS void AS $$
BEGIN
  -- Analyze tables to update statistics
  ANALYZE api.profiles;
  ANALYZE api.projects;
  ANALYZE api.documents;
  ANALYZE api.document_versions;
  ANALYZE api.credit_transactions;
  
  -- Refresh materialized views
  PERFORM analytics.refresh_all_materialized_views();
  
  -- Execute common queries to warm the cache
  PERFORM COUNT(*) FROM api.profiles;
  PERFORM COUNT(*) FROM api.projects WHERE deleted_at IS NULL;
  PERFORM COUNT(*) FROM api.documents;
  
  -- Touch indexes on hot tables
  PERFORM id FROM api.projects ORDER BY created_at DESC LIMIT 1;
  PERFORM id FROM api.documents ORDER BY created_at DESC LIMIT 1;
  PERFORM id FROM api.credit_transactions ORDER BY created_at DESC LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, api, analytics, pg_temp;

COMMENT ON FUNCTION public.warm_database_caches() 
IS 'Warm database caches for improved performance after deployments or schema changes';

-- End of migration script