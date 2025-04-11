-- 000-initial-migration.sql

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create schemas
CREATE SCHEMA IF NOT EXISTS api;
CREATE SCHEMA IF NOT EXISTS reference;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS stripe;

-- Set up reference tables

-- Days of the launch week process
CREATE TABLE reference.launch_days (
  id SMALLINT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Task types/categories
CREATE TABLE reference.task_types (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- AI providers
CREATE TABLE reference.ai_providers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  api_endpoint TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- AI models by provider
CREATE TABLE reference.ai_models (
  id TEXT PRIMARY KEY,
  provider_id TEXT NOT NULL REFERENCES reference.ai_providers(id),
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  max_tokens INTEGER,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Subscription tiers
CREATE TABLE reference.subscription_tiers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  max_projects INTEGER NOT NULL,
  price_monthly INTEGER,  -- in cents
  price_yearly INTEGER,   -- in cents
  stripe_price_id_monthly TEXT,
  stripe_price_id_yearly TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Set up main application tables

-- User profiles that extend auth.users
CREATE TABLE api.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  email_verified BOOLEAN NOT NULL DEFAULT FALSE,
  onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE,
  active_project_id UUID,  -- Will be set via foreign key later
  subscription_tier_id TEXT REFERENCES reference.subscription_tiers(id) DEFAULT 'free',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Projects table for SaaS projects being built
CREATE TABLE api.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  current_day SMALLINT NOT NULL DEFAULT 1 REFERENCES reference.launch_days(id),
  start_date TIMESTAMPTZ,
  target_completion_date TIMESTAMPTZ,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  is_archived BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Update the foreign key for active_project_id in profiles
ALTER TABLE api.profiles 
ADD CONSTRAINT fk_active_project 
FOREIGN KEY (active_project_id) 
REFERENCES api.projects(id);

-- Project tasks (steps in the process)
CREATE TABLE api.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES api.projects(id) ON DELETE CASCADE,
  task_type_id TEXT NOT NULL REFERENCES reference.task_types(id),
  day_id SMALLINT NOT NULL REFERENCES reference.launch_days(id),
  name TEXT NOT NULL,
  description TEXT,
  sequence_order INTEGER NOT NULL,
  is_required BOOLEAN NOT NULL DEFAULT TRUE,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- AI prompts library
CREATE TABLE api.prompts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_type_id TEXT NOT NULL REFERENCES reference.task_types(id),
  day_id SMALLINT REFERENCES reference.launch_days(id),
  title TEXT NOT NULL,
  description TEXT,
  prompt_text TEXT NOT NULL,
  example_output TEXT,
  sequence_order INTEGER NOT NULL,
  preferred_model_id TEXT REFERENCES reference.ai_models(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- User-customized prompts
CREATE TABLE api.user_prompts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  parent_prompt_id UUID REFERENCES api.prompts(id),
  title TEXT NOT NULL,
  description TEXT,
  prompt_text TEXT NOT NULL,
  is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Generated content (outputs from AI processing)
CREATE TABLE api.generated_content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES api.projects(id) ON DELETE CASCADE,
  task_id UUID REFERENCES api.tasks(id),
  prompt_id UUID REFERENCES api.prompts(id),
  user_prompt_id UUID REFERENCES api.user_prompts(id),
  model_id TEXT REFERENCES reference.ai_models(id),
  content_type TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  tokens_used INTEGER,
  processing_time FLOAT,
  is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- AI processing queue
CREATE TABLE api.processing_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  project_id UUID REFERENCES api.projects(id) ON DELETE CASCADE,
  task_id UUID REFERENCES api.tasks(id),
  prompt_text TEXT NOT NULL,
  model_id TEXT REFERENCES reference.ai_models(id),
  status TEXT NOT NULL DEFAULT 'pending',
  progress FLOAT DEFAULT 0,
  result_id UUID REFERENCES api.generated_content(id),
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Project documents and assets
CREATE TABLE api.project_assets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES api.projects(id) ON DELETE CASCADE,
  task_id UUID REFERENCES api.tasks(id),
  name TEXT NOT NULL,
  description TEXT,
  asset_type TEXT NOT NULL,
  content TEXT,
  file_path TEXT,
  file_size INTEGER,
  mime_type TEXT,
  is_final BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Project notes and drafts
CREATE TABLE api.notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  project_id UUID REFERENCES api.projects(id) ON DELETE CASCADE,
  task_id UUID REFERENCES api.tasks(id),
  title TEXT NOT NULL,
  content TEXT,
  is_pinned BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- User feedback on AI generated content
CREATE TABLE api.content_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content_id UUID NOT NULL REFERENCES api.generated_content(id) ON DELETE CASCADE,
  rating SMALLINT,
  feedback_text TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- External tool integration settings
CREATE TABLE api.integrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  service_name TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  credentials JSONB,
  settings JSONB,
  last_used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Stripe tables for payment processing
CREATE TABLE stripe.customers (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  name TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE stripe.subscriptions (
  id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL REFERENCES stripe.customers(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL,
  tier_id TEXT NOT NULL REFERENCES reference.subscription_tiers(id),
  current_period_start TIMESTAMPTZ NOT NULL,
  current_period_end TIMESTAMPTZ NOT NULL,
  cancel_at_period_end BOOLEAN NOT NULL DEFAULT FALSE,
  canceled_at TIMESTAMPTZ,
  trial_start TIMESTAMPTZ,
  trial_end TIMESTAMPTZ,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create analytics tables
CREATE TABLE analytics.user_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  session_id TEXT,
  event_type TEXT NOT NULL,
  page_path TEXT,
  event_data JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE analytics.task_completions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES api.projects(id) ON DELETE CASCADE,
  task_id UUID NOT NULL REFERENCES api.tasks(id) ON DELETE CASCADE,
  day_id SMALLINT NOT NULL REFERENCES reference.launch_days(id),
  completion_time INTEGER, -- in seconds
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE analytics.user_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES api.projects(id) ON DELETE CASCADE,
  day_id SMALLINT NOT NULL REFERENCES reference.launch_days(id),
  completed_tasks INTEGER NOT NULL DEFAULT 0,
  total_tasks INTEGER NOT NULL DEFAULT 0,
  completion_rate FLOAT,
  day_completed BOOLEAN NOT NULL DEFAULT FALSE,
  completion_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Add unique constraint for ON CONFLICT in update_project_progress function
ALTER TABLE analytics.user_progress 
ADD CONSTRAINT user_progress_unique_combination 
UNIQUE (user_id, project_id, day_id);

-- Create audit tables
CREATE TABLE audit.actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name TEXT NOT NULL,
  action_type TEXT NOT NULL,
  record_id UUID NOT NULL,
  user_id UUID,
  old_data JSONB,
  new_data JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create utility functions
CREATE OR REPLACE FUNCTION public.update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp;

-- Create audit function
CREATE OR REPLACE FUNCTION public.record_audit()
RETURNS TRIGGER AS $$
DECLARE
  record_data RECORD;
  old_data JSONB := null;
  new_data JSONB := null;
  action_type TEXT;
BEGIN
  record_data := NEW;
  
  -- Set action type based on operation
  IF (TG_OP = 'INSERT') THEN
    action_type := 'INSERT';
    new_data := to_jsonb(record_data);
  ELSIF (TG_OP = 'UPDATE') THEN
    action_type := 'UPDATE';
    old_data := to_jsonb(OLD);
    new_data := to_jsonb(record_data);
  ELSIF (TG_OP = 'DELETE') THEN
    action_type := 'DELETE';
    old_data := to_jsonb(OLD);
    record_data := OLD;
  END IF;

  -- Insert into audit log
  INSERT INTO audit.actions (
    table_name,
    action_type,
    record_id,
    user_id,
    old_data,
    new_data
  ) VALUES (
    TG_TABLE_NAME,
    action_type,
    (record_data.id)::uuid,
    (SELECT auth.uid()),
    old_data,
    new_data
  );

  -- For DELETE operations, return OLD
  IF (TG_OP = 'DELETE') THEN
    RETURN OLD;
  END IF;

  RETURN record_data;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp;

-- Function to check project limit based on subscription
CREATE OR REPLACE FUNCTION api.check_project_limit()
RETURNS TRIGGER AS $$
DECLARE
  record_data RECORD;
  current_count INTEGER;
  max_projects INTEGER;
  tier_id TEXT;
BEGIN
  record_data := NEW;
  
  -- Get user's subscription tier
  SELECT subscription_tier_id INTO tier_id
  FROM api.profiles
  WHERE id = record_data.user_id;
  
  -- Get max projects allowed for this tier
  SELECT max_projects INTO max_projects
  FROM reference.subscription_tiers
  WHERE id = tier_id;
  
  -- Count user's active projects
  SELECT COUNT(*) INTO current_count
  FROM api.projects
  WHERE user_id = record_data.user_id
  AND is_archived = false;
  
  -- If this is an insert, add 1 to account for the new project
  IF (TG_OP = 'INSERT') THEN
    current_count := current_count + 1;
  END IF;
  
  -- Check if limit would be exceeded
  IF (current_count > max_projects) THEN
    RAISE EXCEPTION 'Project limit of % exceeded for subscription tier %', max_projects, tier_id;
  END IF;
  
  RETURN record_data;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = api, public, pg_temp;

-- Function to update project progress
CREATE OR REPLACE FUNCTION api.update_project_progress()
RETURNS TRIGGER AS $$
DECLARE
  record_data RECORD;
  p_id UUID;
  d_id SMALLINT;
  completed_count INTEGER;
  total_count INTEGER;
  completion_rate FLOAT;
  day_complete BOOLEAN;
BEGIN
  record_data := NEW;
  
  -- Get project and day from the task
  SELECT project_id, day_id INTO p_id, d_id
  FROM api.tasks
  WHERE id = record_data.id;
  
  -- Only proceed if this is a completed task
  IF (record_data.is_completed = TRUE) THEN
    -- Count completed tasks for this day and project
    SELECT COUNT(*) INTO completed_count
    FROM api.tasks
    WHERE project_id = p_id
    AND day_id = d_id
    AND is_completed = TRUE;
    
    -- Count total tasks for this day and project
    SELECT COUNT(*) INTO total_count
    FROM api.tasks
    WHERE project_id = p_id
    AND day_id = d_id;
    
    -- Calculate completion rate
    completion_rate := completed_count::FLOAT / NULLIF(total_count, 0)::FLOAT;
    
    -- Check if day is complete (all required tasks done)
    SELECT (COUNT(*) = 0) INTO day_complete
    FROM api.tasks
    WHERE project_id = p_id
    AND day_id = d_id
    AND is_required = TRUE
    AND is_completed = FALSE;
    
    -- Update or insert progress record
    INSERT INTO analytics.user_progress (
      user_id,
      project_id,
      day_id,
      completed_tasks,
      total_tasks,
      completion_rate,
      day_completed,
      completion_date
    )
    VALUES (
      (SELECT user_id FROM api.projects WHERE id = p_id),
      p_id,
      d_id,
      completed_count,
      total_count,
      completion_rate,
      day_complete,
      CASE WHEN day_complete THEN now() ELSE NULL END
    )
    ON CONFLICT (user_id, project_id, day_id) DO UPDATE
    SET 
      completed_tasks = EXCLUDED.completed_tasks,
      completion_rate = EXCLUDED.completion_rate,
      day_completed = EXCLUDED.day_completed,
      completion_date = EXCLUDED.completion_date,
      updated_at = now();
      
    -- If day is complete, and it's the current day, advance the project to next day
    IF day_complete AND (SELECT current_day FROM api.projects WHERE id = p_id) = d_id THEN
      UPDATE api.projects
      SET current_day = d_id + 1
      WHERE id = p_id
      AND d_id < 5; -- Only advance if not already at day 5
    END IF;
  END IF;
  
  RETURN record_data;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = api, analytics, public, pg_temp;

-- Create triggers for updated_at timestamps
CREATE TRIGGER set_timestamp_profiles
BEFORE UPDATE ON api.profiles
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_timestamp_projects
BEFORE UPDATE ON api.projects
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_timestamp_tasks
BEFORE UPDATE ON api.tasks
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_timestamp_prompts
BEFORE UPDATE ON api.prompts
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_timestamp_user_prompts
BEFORE UPDATE ON api.user_prompts
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_timestamp_generated_content
BEFORE UPDATE ON api.generated_content
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_timestamp_processing_queue
BEFORE UPDATE ON api.processing_queue
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_timestamp_project_assets
BEFORE UPDATE ON api.project_assets
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_timestamp_notes
BEFORE UPDATE ON api.notes
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_timestamp_content_feedback
BEFORE UPDATE ON api.content_feedback
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_timestamp_integrations
BEFORE UPDATE ON api.integrations
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_timestamp_stripe_customers
BEFORE UPDATE ON stripe.customers
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_timestamp_stripe_subscriptions
BEFORE UPDATE ON stripe.subscriptions
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_timestamp_user_progress
BEFORE UPDATE ON analytics.user_progress
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_timestamp_reference_launch_days
BEFORE UPDATE ON reference.launch_days
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_timestamp_reference_task_types
BEFORE UPDATE ON reference.task_types
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_timestamp_reference_ai_providers
BEFORE UPDATE ON reference.ai_providers
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_timestamp_reference_ai_models
BEFORE UPDATE ON reference.ai_models
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

CREATE TRIGGER set_timestamp_reference_subscription_tiers
BEFORE UPDATE ON reference.subscription_tiers
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- Create audit log triggers
CREATE TRIGGER audit_log_profiles
AFTER INSERT OR UPDATE OR DELETE ON api.profiles
FOR EACH ROW EXECUTE FUNCTION public.record_audit();

CREATE TRIGGER audit_log_projects
AFTER INSERT OR UPDATE OR DELETE ON api.projects
FOR EACH ROW EXECUTE FUNCTION public.record_audit();

CREATE TRIGGER audit_log_tasks
AFTER INSERT OR UPDATE OR DELETE ON api.tasks
FOR EACH ROW EXECUTE FUNCTION public.record_audit();

-- Project limit check triggers
CREATE TRIGGER check_project_limit
BEFORE INSERT ON api.projects
FOR EACH ROW EXECUTE FUNCTION api.check_project_limit();

-- Task completion triggers for progress tracking
CREATE TRIGGER update_project_progress
AFTER UPDATE OF is_completed ON api.tasks
FOR EACH ROW EXECUTE FUNCTION api.update_project_progress();

-- Enable Row Level Security on tables
ALTER TABLE api.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.user_prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.generated_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.processing_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.project_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.content_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE api.integrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.user_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.task_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.user_progress ENABLE ROW LEVEL SECURITY;

-- Create policies for profiles
CREATE POLICY "Users can view their own profile"
  ON api.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON api.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Create policies for projects
CREATE POLICY "Users can view their own projects"
  ON api.projects FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create projects"
  ON api.projects FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own projects"
  ON api.projects FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own projects"
  ON api.projects FOR DELETE
  USING (auth.uid() = user_id);

-- Create policies for tasks
CREATE POLICY "Users can view tasks for their projects"
  ON api.tasks FOR SELECT
  USING (auth.uid() = (SELECT user_id FROM api.projects WHERE id = project_id));

CREATE POLICY "Users can create tasks for their projects"
  ON api.tasks FOR INSERT
  WITH CHECK (auth.uid() = (SELECT user_id FROM api.projects WHERE id = project_id));

CREATE POLICY "Users can update tasks for their projects"
  ON api.tasks FOR UPDATE
  USING (auth.uid() = (SELECT user_id FROM api.projects WHERE id = project_id));

CREATE POLICY "Users can delete tasks for their projects"
  ON api.tasks FOR DELETE
  USING (auth.uid() = (SELECT user_id FROM api.projects WHERE id = project_id));

-- Create policies for prompts (library prompts are readable by all authenticated users)
CREATE POLICY "All users can view prompts"
  ON api.prompts FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Create policies for user prompts
CREATE POLICY "Users can view their own custom prompts"
  ON api.user_prompts FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own custom prompts"
  ON api.user_prompts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own custom prompts"
  ON api.user_prompts FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own custom prompts"
  ON api.user_prompts FOR DELETE
  USING (auth.uid() = user_id);

-- Create policies for generated content
CREATE POLICY "Users can view generated content for their projects"
  ON api.generated_content FOR SELECT
  USING (auth.uid() = (SELECT user_id FROM api.projects WHERE id = project_id));

CREATE POLICY "Users can create generated content for their projects"
  ON api.generated_content FOR INSERT
  WITH CHECK (auth.uid() = (SELECT user_id FROM api.projects WHERE id = project_id));

CREATE POLICY "Users can update generated content for their projects"
  ON api.generated_content FOR UPDATE
  USING (auth.uid() = (SELECT user_id FROM api.projects WHERE id = project_id));

CREATE POLICY "Users can delete generated content for their projects"
  ON api.generated_content FOR DELETE
  USING (auth.uid() = (SELECT user_id FROM api.projects WHERE id = project_id));

-- Create policies for processing queue
CREATE POLICY "Users can view their processing queue"
  ON api.processing_queue FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can add to processing queue"
  ON api.processing_queue FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their processing queue"
  ON api.processing_queue FOR UPDATE
  USING (auth.uid() = user_id);

-- Create policies for project assets
CREATE POLICY "Users can view assets for their projects"
  ON api.project_assets FOR SELECT
  USING (auth.uid() = (SELECT user_id FROM api.projects WHERE id = project_id));

CREATE POLICY "Users can create assets for their projects"
  ON api.project_assets FOR INSERT
  WITH CHECK (auth.uid() = (SELECT user_id FROM api.projects WHERE id = project_id));

CREATE POLICY "Users can update assets for their projects"
  ON api.project_assets FOR UPDATE
  USING (auth.uid() = (SELECT user_id FROM api.projects WHERE id = project_id));

CREATE POLICY "Users can delete assets for their projects"
  ON api.project_assets FOR DELETE
  USING (auth.uid() = (SELECT user_id FROM api.projects WHERE id = project_id));

-- Create policies for notes
CREATE POLICY "Users can view their notes"
  ON api.notes FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create notes"
  ON api.notes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their notes"
  ON api.notes FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their notes"
  ON api.notes FOR DELETE
  USING (auth.uid() = user_id);

-- Create policies for content feedback
CREATE POLICY "Users can view their content feedback"
  ON api.content_feedback FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create content feedback"
  ON api.content_feedback FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their content feedback"
  ON api.content_feedback FOR UPDATE
  USING (auth.uid() = user_id);

-- Create policies for integrations
CREATE POLICY "Users can view their integrations"
  ON api.integrations FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create integrations"
  ON api.integrations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their integrations"
  ON api.integrations FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their integrations"
  ON api.integrations FOR DELETE
  USING (auth.uid() = user_id);

-- Create policies for stripe data
CREATE POLICY "Users can view their stripe customer"
  ON stripe.customers FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view their stripe subscriptions"
  ON stripe.subscriptions FOR SELECT
  USING (auth.uid() = user_id);

-- Create policies for analytics
CREATE POLICY "Users can view their analytics data"
  ON analytics.user_events FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view their task completion data"
  ON analytics.task_completions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view their progress data"
  ON analytics.user_progress FOR SELECT
  USING (auth.uid() = user_id);

-- Create indexes for performance
CREATE INDEX idx_projects_user_id ON api.projects(user_id);
CREATE INDEX idx_tasks_project_id ON api.tasks(project_id);
CREATE INDEX idx_tasks_day_id ON api.tasks(day_id);
CREATE INDEX idx_generated_content_project_id ON api.generated_content(project_id);
CREATE INDEX idx_generated_content_task_id ON api.generated_content(task_id);
CREATE INDEX idx_project_assets_project_id ON api.project_assets(project_id);
CREATE INDEX idx_project_assets_task_id ON api.project_assets(task_id);
CREATE INDEX idx_notes_user_id ON api.notes(user_id);
CREATE INDEX idx_notes_project_id ON api.notes(project_id);
CREATE INDEX idx_processing_queue_user_id ON api.processing_queue(user_id);
CREATE INDEX idx_processing_queue_status ON api.processing_queue(status);
CREATE INDEX idx_user_prompts_user_id ON api.user_prompts(user_id);
CREATE INDEX idx_content_feedback_content_id ON api.content_feedback(content_id);
CREATE INDEX idx_stripe_customers_user_id ON stripe.customers(user_id);
CREATE INDEX idx_stripe_subscriptions_user_id ON stripe.subscriptions(user_id);
CREATE INDEX idx_analytics_user_events_user_id ON analytics.user_events(user_id);
CREATE INDEX idx_analytics_task_completions_user_id ON analytics.task_completions(user_id);
CREATE INDEX idx_analytics_task_completions_project_id ON analytics.task_completions(project_id);
CREATE INDEX idx_analytics_user_progress_user_id ON analytics.user_progress(user_id);
CREATE INDEX idx_analytics_user_progress_project_id ON analytics.user_progress(project_id);

-- Insert initial reference data
INSERT INTO reference.launch_days (id, name, description)
VALUES 
  (1, 'Day 1: Idea & Initial App Build', 'Define your product vision, create a database schema, and build the initial application'),
  (2, 'Day 2: Feedback & Refinement', 'Gather user feedback and refine your application based on input'),
  (3, 'Day 3: Full App Build', 'Complete all essential functionality and ensure responsive design'),
  (4, 'Day 4: Marketing Content Build', 'Create landing page content, email templates, and SEO strategy'),
  (5, 'Day 5: Promotion & Launch', 'Deploy your application and begin user acquisition');

INSERT INTO reference.task_types (id, name, description)
VALUES 
  ('product_requirements', 'Product Requirements', 'Define your product vision, features, and user stories'),
  ('database_schema', 'Database Schema', 'Create the database structure for your application'),
  ('marketing_story', 'Marketing Story', 'Develop your brand voice and marketing messaging'),
  ('initial_build', 'Initial App Build', 'Create the first version of your application'),
  ('user_feedback', 'User Feedback', 'Collect and analyze feedback from potential users'),
  ('design_refinement', 'Design Refinement', 'Improve the user interface and experience'),
  ('feature_implementation', 'Feature Implementation', 'Build core features of your application'),
  ('auth_setup', 'Authentication Setup', 'Implement user authentication and profiles'),
  ('responsive_design', 'Responsive Design', 'Ensure your app works well on all devices'),
  ('landing_page', 'Landing Page', 'Create your product landing page content'),
  ('email_templates', 'Email Templates', 'Develop email marketing campaigns'),
  ('social_media', 'Social Media', 'Create social media announcements'),
  ('seo_strategy', 'SEO Strategy', 'Build a search engine optimization plan'),
  ('deployment', 'Deployment', 'Launch your application on production servers'),
  ('launch_announcement', 'Launch Announcement', 'Promote your product launch');

INSERT INTO reference.ai_providers (id, name, description, api_endpoint)
VALUES 
  ('openai', 'OpenAI', 'Provider of GPT models', 'https://api.openai.com/v1'),
  ('anthropic', 'Anthropic', 'Provider of Claude models', 'https://api.anthropic.com/v1'),
  ('google', 'Google', 'Provider of Gemini models', 'https://generativelanguage.googleapis.com');

INSERT INTO reference.ai_models (id, provider_id, name, description, max_tokens)
VALUES 
  ('gpt4-turbo', 'openai', 'GPT-4 Turbo', 'Most powerful GPT model for complex tasks', 16000),
  ('gpt3-turbo', 'openai', 'GPT-3.5 Turbo', 'Fast and efficient for most tasks', 8000),
  ('claude-3-sonnet', 'anthropic', 'Claude 3 Sonnet', 'Powerful reasoning for complex tasks', 24000),
  ('claude-2', 'anthropic', 'Claude 2', 'Good balance of performance and cost', 100000),
  ('gemini-pro', 'google', 'Gemini Pro', 'Google''s advanced reasoning model', 8000);

INSERT INTO reference.subscription_tiers (id, name, description, max_projects, price_monthly, price_yearly, stripe_price_id_monthly, stripe_price_id_yearly)
VALUES 
  ('free', 'Free', 'Limited to 2 simultaneous projects', 2, 0, 0, NULL, NULL),
  ('pro', 'Pro', 'Up to 20 simultaneous projects', 20, 700, 7000, 'price_monthly_pro', 'price_yearly_pro');