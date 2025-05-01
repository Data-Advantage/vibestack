-- 003-security.sql
-- LaunchWeek.ai Security Migration

-- This migration establishes security measures, automation, and API endpoints:
-- - Creates triggers for automated data operations and business rules
-- - Implements Row Level Security (RLS) policies to protect user data
-- - Configures storage buckets and security
-- - Creates custom API functions for application operations

------------------------------------------------------------------------------
-- PART 1: TRIGGERS
------------------------------------------------------------------------------
-- Create triggers for automation and business rule enforcement

-- Update project completion percentage based on framework progress
CREATE OR REPLACE FUNCTION public.update_project_completion()
RETURNS TRIGGER AS $$
DECLARE
  avg_completion NUMERIC;
BEGIN
  -- Calculate average completion percentage across all framework days
  SELECT AVG(completion_percentage) INTO avg_completion
  FROM api.framework_progress
  WHERE project_id = NEW.project_id;
  
  -- Update the project completion percentage
  UPDATE api.projects
  SET completion_percentage = COALESCE(avg_completion, 0)
  WHERE id = NEW.project_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;
COMMENT ON FUNCTION public.update_project_completion() IS 'Updates project completion percentage based on framework progress changes';

CREATE TRIGGER update_project_completion
AFTER INSERT OR UPDATE OF completion_percentage ON api.framework_progress
FOR EACH ROW EXECUTE FUNCTION public.update_project_completion();

-- Update framework step status when it's completed
CREATE OR REPLACE FUNCTION public.handle_step_completion()
RETURNS TRIGGER AS $$
BEGIN
  -- If step is now completed and wasn't before
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status <> 'completed') THEN
    -- Set completed_at timestamp
    NEW.completed_at = now();
    
    -- Update framework progress for this day
    UPDATE api.framework_progress
    SET 
      status = CASE
        -- Only mark as completed if all steps for the day are completed
        WHEN NOT EXISTS (
          SELECT 1 FROM api.framework_steps
          WHERE project_id = NEW.project_id 
          AND framework_day = NEW.framework_day
          AND status <> 'completed'
          AND id <> NEW.id
        ) THEN 'completed'
        ELSE 'in_progress'
      END,
      -- Recalculate completion percentage based on completed steps
      completion_percentage = (
        SELECT COUNT(*)::float * 100 / NULLIF((SELECT COUNT(*) FROM api.framework_steps WHERE project_id = NEW.project_id AND framework_day = NEW.framework_day), 0)
        FROM api.framework_steps
        WHERE project_id = NEW.project_id 
        AND framework_day = NEW.framework_day
        AND status = 'completed'
      )
    WHERE project_id = NEW.project_id AND framework_day = NEW.framework_day;
  END IF;
  
  -- If step is now started and wasn't before
  IF NEW.status = 'in_progress' AND (OLD.status IS NULL OR OLD.status = 'pending') THEN
    -- Set started_at timestamp if not already set
    IF NEW.started_at IS NULL THEN
      NEW.started_at = now();
    END IF;
    
    -- Ensure corresponding framework_progress record exists and is in progress
    UPDATE api.framework_progress
    SET 
      status = 'in_progress',
      started_at = COALESCE(started_at, now())
    WHERE project_id = NEW.project_id AND framework_day = NEW.framework_day;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;
COMMENT ON FUNCTION public.handle_step_completion() IS 'Updates step completion timestamps and framework progress when step status changes';

CREATE TRIGGER handle_step_completion
BEFORE UPDATE OF status ON api.framework_steps
FOR EACH ROW EXECUTE FUNCTION public.handle_step_completion();

-- Update conversation token count when messages are added
CREATE OR REPLACE FUNCTION public.update_conversation_token_count()
RETURNS TRIGGER AS $$
BEGIN
  -- Update the total token count in the conversation
  UPDATE api.ai_conversations
  SET token_count = token_count + COALESCE(NEW.tokens, 0)
  WHERE id = NEW.conversation_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;
COMMENT ON FUNCTION public.update_conversation_token_count() IS 'Updates the total token count in a conversation when new messages are added';

CREATE TRIGGER update_conversation_token_count
AFTER INSERT ON api.ai_messages
FOR EACH ROW EXECUTE FUNCTION public.update_conversation_token_count();

-- Initialize framework_progress records when a new project is created
CREATE OR REPLACE FUNCTION public.initialize_framework_progress()
RETURNS TRIGGER AS $$
DECLARE
  day_rec RECORD;
BEGIN
  -- Create framework progress records for each day
  FOR day_rec IN SELECT framework_day FROM reference.day_templates ORDER BY order_number
  LOOP
    INSERT INTO api.framework_progress (
      project_id, 
      framework_day, 
      status, 
      completion_percentage
    )
    VALUES (
      NEW.id, 
      day_rec.framework_day, 
      CASE WHEN day_rec.framework_day = 'day_1' THEN 'pending' ELSE 'pending' END,
      0
    );
  END LOOP;
  
  -- Set the initial framework day
  NEW.current_framework_day = 'day_1';
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;
COMMENT ON FUNCTION public.initialize_framework_progress() IS 'Creates initial framework progress records for all days when a new project is created';

CREATE TRIGGER initialize_framework_progress
BEFORE INSERT ON api.projects
FOR EACH ROW EXECUTE FUNCTION public.initialize_framework_progress();

-- Initialize framework steps for a project based on templates
CREATE OR REPLACE FUNCTION public.initialize_framework_steps()
RETURNS TRIGGER AS $$
DECLARE
  day_rec RECORD;
  step_rec RECORD;
BEGIN
  -- For each day template
  FOR day_rec IN 
    SELECT * FROM reference.day_templates ORDER BY order_number
  LOOP
    -- For each step in that day
    FOR step_rec IN 
      SELECT * FROM reference.step_templates 
      WHERE day_template_id = day_rec.id 
      ORDER BY order_number
    LOOP
      -- Create framework step record
      INSERT INTO api.framework_steps (
        project_id,
        framework_day,
        step_number,
        title,
        description,
        step_type,
        status
      )
      VALUES (
        NEW.id,
        day_rec.framework_day,
        step_rec.order_number,
        step_rec.title,
        step_rec.description,
        step_rec.step_type,
        'pending'
      );
    END LOOP;
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;
COMMENT ON FUNCTION public.initialize_framework_steps() IS 'Creates initial framework step records based on templates when a new project is created';

CREATE TRIGGER initialize_framework_steps
AFTER INSERT ON api.projects
FOR EACH ROW EXECUTE FUNCTION public.initialize_framework_steps();

-- Function to maintain version numbers when updating documents
CREATE OR REPLACE FUNCTION public.handle_document_versioning()
RETURNS TRIGGER AS $$
BEGIN
  -- Increment the version number
  NEW.version = OLD.version + 1;
  
  -- Set the updated_by field
  NEW.updated_by = auth.uid();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;
COMMENT ON FUNCTION public.handle_document_versioning() IS 'Increments document version number and sets updated_by field when content is modified';

CREATE TRIGGER handle_document_versioning
BEFORE UPDATE OF content, content_json ON api.documents
FOR EACH ROW EXECUTE FUNCTION public.handle_document_versioning();

-- Function to set created_by when inserting documents
CREATE OR REPLACE FUNCTION public.set_document_created_by()
RETURNS TRIGGER AS $$
BEGIN
  -- Set the created_by field
  NEW.created_by = auth.uid();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;
COMMENT ON FUNCTION public.set_document_created_by() IS 'Sets created_by field to current user when a document is created';

CREATE TRIGGER set_document_created_by
BEFORE INSERT ON api.documents
FOR EACH ROW EXECUTE FUNCTION public.set_document_created_by();

-- Process credit transactions
CREATE OR REPLACE FUNCTION internal.process_credit_transaction()
RETURNS TRIGGER AS $$
DECLARE
  current_balance INTEGER;
  credit_constant INTEGER;
BEGIN
  -- Get current balance
  SELECT balance INTO current_balance
  FROM internal.user_credits
  WHERE user_id = NEW.user_id;
  
  -- If no record exists, create one with initial free credits
  IF current_balance IS NULL THEN
    -- Get the constant for initial credits
    SELECT COALESCE(value::INTEGER, 1) INTO credit_constant
    FROM constants.credit_system
    WHERE name = 'INITIAL_FREE_CREDITS';
    
    -- Only create a new record if this isn't already a signup bonus transaction
    -- This prevents double-crediting when the handle_new_user trigger fires
    IF NEW.transaction_type != 'signup_bonus' THEN
      INSERT INTO internal.user_credits (user_id, balance, last_updated)
      VALUES (NEW.user_id, credit_constant, now());
      current_balance := credit_constant;
    ELSE
      -- For signup bonus, start from 0 since we're adding the bonus now
      INSERT INTO internal.user_credits (user_id, balance, last_updated)
      VALUES (NEW.user_id, 0, now());
      current_balance := 0;
    END IF;
  END IF;
  
  -- For debits, check if the user has enough credits
  IF NEW.amount < 0 AND (current_balance + NEW.amount) < 0 THEN
    -- Set error in the transaction record
    NEW.operation_result := 'insufficient_credits';
    NEW.error_details := format('Insufficient credits: balance %s, requested %s', current_balance, ABS(NEW.amount));
    -- Don't modify the balance
    NEW.balance_after := current_balance;
    RETURN NEW;
  END IF;
  
  -- Calculate new balance
  current_balance := current_balance + NEW.amount;
  
  -- Update user_credits with new balance
  UPDATE internal.user_credits
  SET 
    balance = current_balance,
    last_updated = now()
  WHERE user_id = NEW.user_id;
  
  -- Set the balance_after field on the transaction
  NEW.balance_after := current_balance;
  NEW.operation_result := 'success';
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = internal, constants, public, pg_temp;
COMMENT ON FUNCTION internal.process_credit_transaction() IS 'Updates user credit balance when a transaction is processed, with error handling';

CREATE TRIGGER process_credit_transaction
BEFORE INSERT ON internal.credit_transactions
FOR EACH ROW EXECUTE FUNCTION internal.process_credit_transaction();

-- Add initial credit for new user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  credit_constant INTEGER;
BEGIN
  -- Create profile
  INSERT INTO api.profiles (id, display_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'name', NEW.email));
  
  -- Get the constant for initial credits
  SELECT COALESCE(value::INTEGER, 1) INTO credit_constant
  FROM constants.credit_system
  WHERE name = 'INITIAL_FREE_CREDITS';
  
  -- Add initial credit as a transaction
  INSERT INTO internal.credit_transactions (
    user_id,
    amount,
    transaction_type,
    metadata
  )
  VALUES (
    NEW.id,
    credit_constant,
    'signup_bonus',
    jsonb_build_object(
      'source', 'new_user_signup',
      'signup_date', now()
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, constants, pg_temp;
COMMENT ON FUNCTION public.handle_new_user() IS 'Creates a profile record and adds initial credit when a new user signs up';

------------------------------------------------------------------------------
-- PART 2: ROW LEVEL SECURITY (RLS) POLICIES
------------------------------------------------------------------------------
-- Enable RLS and implement security policies for tables

-- Enable RLS on api.profiles
ALTER TABLE api.profiles ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view their own profile"
  ON api.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON api.profiles FOR UPDATE
  USING (auth.uid() = id);

COMMENT ON POLICY "Users can view their own profile" ON api.profiles IS 
  'Allows users to view only their own profile information';
COMMENT ON POLICY "Users can update their own profile" ON api.profiles IS 
  'Allows users to update only their own profile information';

-- Enable RLS on api.projects
ALTER TABLE api.projects ENABLE ROW LEVEL SECURITY;

-- Projects policies
CREATE POLICY "Users can view their own projects"
  ON api.projects FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own projects"
  ON api.projects FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own projects"
  ON api.projects FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own projects"
  ON api.projects FOR DELETE
  USING (auth.uid() = user_id);

COMMENT ON POLICY "Users can view their own projects" ON api.projects IS 
  'Allows users to view only the projects they own';
COMMENT ON POLICY "Users can insert their own projects" ON api.projects IS 
  'Ensures users can only create projects for themselves';
COMMENT ON POLICY "Users can update their own projects" ON api.projects IS 
  'Allows users to update only the projects they own';
COMMENT ON POLICY "Users can delete their own projects" ON api.projects IS 
  'Allows users to delete only the projects they own';

-- Enable RLS on api.framework_progress
ALTER TABLE api.framework_progress ENABLE ROW LEVEL SECURITY;

-- Framework progress policies
CREATE POLICY "Users can view progress for their own projects"
  ON api.framework_progress FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM api.projects
    WHERE id = api.framework_progress.project_id
    AND user_id = auth.uid()
  ));

CREATE POLICY "Users can update progress for their own projects"
  ON api.framework_progress FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM api.projects
    WHERE id = api.framework_progress.project_id
    AND user_id = auth.uid()
  ));

COMMENT ON POLICY "Users can view progress for their own projects" ON api.framework_progress IS 
  'Allows users to view progress only for projects they own';
COMMENT ON POLICY "Users can update progress for their own projects" ON api.framework_progress IS 
  'Allows users to update progress only for projects they own';

-- Enable RLS on api.framework_steps
ALTER TABLE api.framework_steps ENABLE ROW LEVEL SECURITY;

-- Framework steps policies
CREATE POLICY "Users can view steps for their own projects"
  ON api.framework_steps FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM api.projects
    WHERE id = api.framework_steps.project_id
    AND user_id = auth.uid()
  ));

CREATE POLICY "Users can update steps for their own projects"
  ON api.framework_steps FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM api.projects
    WHERE id = api.framework_steps.project_id
    AND user_id = auth.uid()
  ));

COMMENT ON POLICY "Users can view steps for their own projects" ON api.framework_steps IS 
  'Allows users to view steps only for projects they own';
COMMENT ON POLICY "Users can update steps for their own projects" ON api.framework_steps IS 
  'Allows users to update steps only for projects they own';

-- Enable RLS on api.documents
ALTER TABLE api.documents ENABLE ROW LEVEL SECURITY;

-- Documents policies
CREATE POLICY "Users can view documents for their own projects"
  ON api.documents FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM api.projects
    WHERE id = api.documents.project_id
    AND user_id = auth.uid()
  ));

CREATE POLICY "Users can insert documents for their own projects"
  ON api.documents FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM api.projects
    WHERE id = api.documents.project_id
    AND user_id = auth.uid()
  ));

CREATE POLICY "Users can update documents for their own projects"
  ON api.documents FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM api.projects
    WHERE id = api.documents.project_id
    AND user_id = auth.uid()
  ));

CREATE POLICY "Users can delete documents for their own projects"
  ON api.documents FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM api.projects
    WHERE id = api.documents.project_id
    AND user_id = auth.uid()
  ));

COMMENT ON POLICY "Users can view documents for their own projects" ON api.documents IS 
  'Allows users to view documents only for projects they own';
COMMENT ON POLICY "Users can insert documents for their own projects" ON api.documents IS 
  'Allows users to create documents only for projects they own';
COMMENT ON POLICY "Users can update documents for their own projects" ON api.documents IS 
  'Allows users to update documents only for projects they own';
COMMENT ON POLICY "Users can delete documents for their own projects" ON api.documents IS 
  'Allows users to delete documents only for projects they own';

-- Enable RLS on api.implementation_plans
ALTER TABLE api.implementation_plans ENABLE ROW LEVEL SECURITY;

-- Implementation plans policies
CREATE POLICY "Users can view implementation plans for their own projects"
  ON api.implementation_plans FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM api.projects
    WHERE id = api.implementation_plans.project_id
    AND user_id = auth.uid()
  ));

CREATE POLICY "Users can insert implementation plans for their own projects"
  ON api.implementation_plans FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM api.projects
    WHERE id = api.implementation_plans.project_id
    AND user_id = auth.uid()
  ));

CREATE POLICY "Users can update implementation plans for their own projects"
  ON api.implementation_plans FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM api.projects
    WHERE id = api.implementation_plans.project_id
    AND user_id = auth.uid()
  ));

CREATE POLICY "Users can delete implementation plans for their own projects"
  ON api.implementation_plans FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM api.projects
    WHERE id = api.implementation_plans.project_id
    AND user_id = auth.uid()
  ));

COMMENT ON POLICY "Users can view implementation plans for their own projects" ON api.implementation_plans IS 
  'Allows users to view implementation plans only for projects they own';
COMMENT ON POLICY "Users can insert implementation plans for their own projects" ON api.implementation_plans IS 
  'Allows users to create implementation plans only for projects they own';
COMMENT ON POLICY "Users can update implementation plans for their own projects" ON api.implementation_plans IS 
  'Allows users to update implementation plans only for projects they own';
COMMENT ON POLICY "Users can delete implementation plans for their own projects" ON api.implementation_plans IS 
  'Allows users to delete implementation plans only for projects they own';

-- Enable RLS on api.implementation_tasks
ALTER TABLE api.implementation_tasks ENABLE ROW LEVEL SECURITY;

-- Implementation tasks policies
CREATE POLICY "Users can view tasks for their own implementation plans"
  ON api.implementation_tasks FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM api.implementation_plans ip
    JOIN api.projects p ON ip.project_id = p.id
    WHERE ip.id = api.implementation_tasks.plan_id
    AND p.user_id = auth.uid()
  ));

CREATE POLICY "Users can insert tasks for their own implementation plans"
  ON api.implementation_tasks FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM api.implementation_plans ip
    JOIN api.projects p ON ip.project_id = p.id
    WHERE ip.id = api.implementation_tasks.plan_id
    AND p.user_id = auth.uid()
  ));

CREATE POLICY "Users can update tasks for their own implementation plans"
  ON api.implementation_tasks FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM api.implementation_plans ip
    JOIN api.projects p ON ip.project_id = p.id
    WHERE ip.id = api.implementation_tasks.plan_id
    AND p.user_id = auth.uid()
  ));

CREATE POLICY "Users can delete tasks for their own implementation plans"
  ON api.implementation_tasks FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM api.implementation_plans ip
    JOIN api.projects p ON ip.project_id = p.id
    WHERE ip.id = api.implementation_tasks.plan_id
    AND p.user_id = auth.uid()
  ));

COMMENT ON POLICY "Users can view tasks for their own implementation plans" ON api.implementation_tasks IS 
  'Allows users to view tasks only for implementation plans they own';
COMMENT ON POLICY "Users can insert tasks for their own implementation plans" ON api.implementation_tasks IS 
  'Allows users to create tasks only for implementation plans they own';
COMMENT ON POLICY "Users can update tasks for their own implementation plans" ON api.implementation_tasks IS 
  'Allows users to update tasks only for implementation plans they own';
COMMENT ON POLICY "Users can delete tasks for their own implementation plans" ON api.implementation_tasks IS 
  'Allows users to delete tasks only for implementation plans they own';

-- Enable RLS on api.ai_conversations
ALTER TABLE api.ai_conversations ENABLE ROW LEVEL SECURITY;

-- AI conversations policies
CREATE POLICY "Users can view conversations for their own projects"
  ON api.ai_conversations FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM api.projects
    WHERE id = api.ai_conversations.project_id
    AND user_id = auth.uid()
  ));

CREATE POLICY "Users can insert conversations for their own projects"
  ON api.ai_conversations FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM api.projects
    WHERE id = api.ai_conversations.project_id
    AND user_id = auth.uid()
  ));

CREATE POLICY "Users can update conversations for their own projects"
  ON api.ai_conversations FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM api.projects
    WHERE id = api.ai_conversations.project_id
    AND user_id = auth.uid()
  ));

CREATE POLICY "Users can delete conversations for their own projects"
  ON api.ai_conversations FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM api.projects
    WHERE id = api.ai_conversations.project_id
    AND user_id = auth.uid()
  ));

COMMENT ON POLICY "Users can view conversations for their own projects" ON api.ai_conversations IS 
  'Allows users to view AI conversations only for projects they own';
COMMENT ON POLICY "Users can insert conversations for their own projects" ON api.ai_conversations IS 
  'Allows users to create AI conversations only for projects they own';
COMMENT ON POLICY "Users can update conversations for their own projects" ON api.ai_conversations IS 
  'Allows users to update AI conversations only for projects they own';
COMMENT ON POLICY "Users can delete conversations for their own projects" ON api.ai_conversations IS 
  'Allows users to delete AI conversations only for projects they own';

-- Enable RLS on api.ai_messages
ALTER TABLE api.ai_messages ENABLE ROW LEVEL SECURITY;

-- AI messages policies
CREATE POLICY "Users can view messages for their own conversations"
  ON api.ai_messages FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM api.ai_conversations ac
    JOIN api.projects p ON ac.project_id = p.id
    WHERE ac.id = api.ai_messages.conversation_id
    AND p.user_id = auth.uid()
  ));

CREATE POLICY "Users can insert messages for their own conversations"
  ON api.ai_messages FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM api.ai_conversations ac
    JOIN api.projects p ON ac.project_id = p.id
    WHERE ac.id = api.ai_messages.conversation_id
    AND p.user_id = auth.uid()
  ));

COMMENT ON POLICY "Users can view messages for their own conversations" ON api.ai_messages IS 
  'Allows users to view AI messages only for conversations in their projects';
COMMENT ON POLICY "Users can insert messages for their own conversations" ON api.ai_messages IS 
  'Allows users to create AI messages only for conversations in their projects';

-- Enable RLS on internal.ai_tasks
ALTER TABLE internal.ai_tasks ENABLE ROW LEVEL SECURITY;

-- AI tasks policies
CREATE POLICY "Users can view their own AI tasks"
  ON internal.ai_tasks FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert AI tasks for their own projects"
  ON internal.ai_tasks FOR INSERT
  WITH CHECK (user_id = auth.uid() AND EXISTS (
    SELECT 1 FROM api.projects
    WHERE id = internal.ai_tasks.project_id
    AND user_id = auth.uid()
  ));

COMMENT ON POLICY "Users can view their own AI tasks" ON internal.ai_tasks IS 
  'Allows users to view only their own AI tasks';
COMMENT ON POLICY "Users can insert AI tasks for their own projects" ON internal.ai_tasks IS 
  'Allows users to create AI tasks only for their own projects';

-- Enable RLS on internal.user_credits
ALTER TABLE internal.user_credits ENABLE ROW LEVEL SECURITY;

-- User credits policies
CREATE POLICY "Users can view their own credits"
  ON internal.user_credits FOR SELECT
  USING (user_id = auth.uid());

COMMENT ON POLICY "Users can view their own credits" ON internal.user_credits IS 
  'Allows users to view only their own credit balance';

-- Enable RLS on internal.credit_transactions
ALTER TABLE internal.credit_transactions ENABLE ROW LEVEL SECURITY;

-- Credit transactions policies
CREATE POLICY "Users can view their own credit transactions"
  ON internal.credit_transactions FOR SELECT
  USING (user_id = auth.uid());

COMMENT ON POLICY "Users can view their own credit transactions" ON internal.credit_transactions IS 
  'Allows users to view only their own credit transactions';

-- Enable RLS on reference tables (read-only for authenticated users)
ALTER TABLE reference.day_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE reference.step_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE reference.prompt_templates ENABLE ROW LEVEL SECURITY;

-- Reference tables policies
CREATE POLICY "Authenticated users can view day templates"
  ON reference.day_templates FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can view step templates"
  ON reference.step_templates FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can view prompt templates"
  ON reference.prompt_templates FOR SELECT
  USING (auth.role() = 'authenticated');

COMMENT ON POLICY "Authenticated users can view day templates" ON reference.day_templates IS 
  'Allows all authenticated users to view day templates';
COMMENT ON POLICY "Authenticated users can view step templates" ON reference.step_templates IS 
  'Allows all authenticated users to view step templates';
COMMENT ON POLICY "Authenticated users can view prompt templates" ON reference.prompt_templates IS 
  'Allows all authenticated users to view prompt templates';

-- Enable RLS on config tables (read-only for authenticated users)
ALTER TABLE config.subscription_benefits ENABLE ROW LEVEL SECURITY;

-- Config tables policies
CREATE POLICY "Authenticated users can view subscription benefits"
  ON config.subscription_benefits FOR SELECT
  USING (auth.role() = 'authenticated');

COMMENT ON POLICY "Authenticated users can view subscription benefits" ON config.subscription_benefits IS 
  'Allows all authenticated users to view subscription tier benefits';

-- Enable RLS on Stripe-related tables
ALTER TABLE stripe.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe.charges ENABLE ROW LEVEL SECURITY;

-- Stripe tables policies
CREATE POLICY "Users can view their own Stripe customer data"
  ON stripe.customers FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can view their own subscriptions"
  ON stripe.subscriptions FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM stripe.customers
    WHERE id = stripe.subscriptions.customer_id
    AND user_id = auth.uid()
  ));

CREATE POLICY "Users can view their own invoices"
  ON stripe.invoices FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM stripe.customers
    WHERE id = stripe.invoices.customer_id
    AND user_id = auth.uid()
  ));

CREATE POLICY "Users can view their own payment methods"
  ON stripe.payment_methods FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM stripe.customers
    WHERE id = stripe.payment_methods.customer_id
    AND user_id = auth.uid()
  ));

CREATE POLICY "Users can view their own charges"
  ON stripe.charges FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM stripe.customers
    WHERE id = stripe.charges.customer_id
    AND user_id = auth.uid()
  ));

COMMENT ON POLICY "Users can view their own Stripe customer data" ON stripe.customers IS 
  'Allows users to view only their own Stripe customer data';
COMMENT ON POLICY "Users can view their own subscriptions" ON stripe.subscriptions IS 
  'Allows users to view only their own subscriptions';
COMMENT ON POLICY "Users can view their own invoices" ON stripe.invoices IS 
  'Allows users to view only their own invoices';
COMMENT ON POLICY "Users can view their own payment methods" ON stripe.payment_methods IS 
  'Allows users to view only their own payment methods';
COMMENT ON POLICY "Users can view their own charges" ON stripe.charges IS 
  'Allows users to view only their own charges';

-- Apply RLS to analytics views for admin use only
-- Note: These would normally be accessed via service role bypassing RLS, 
-- but we add policies as a safeguard

------------------------------------------------------------------------------
-- PART 3: STORAGE CONFIGURATION
------------------------------------------------------------------------------
-- Configure storage buckets and apply security policies

-- Create storage buckets
-- Note: To be executed via the Supabase dashboard or API directly
/*
  1. Create 'public' bucket (open access for assets like logos)
  2. Create 'protected' bucket (authenticated access only)
  3. Create 'private' bucket (user-specific access)
*/

-- Apply RLS policies to storage
-- Note: These would be applied through the Supabase dashboard or API

-- Example policies for private bucket:
/*
CREATE POLICY "Users can upload their own files"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'private' AND
    auth.uid()::text = (storage.foldername(storage.objects.name))[1]
  );

CREATE POLICY "Users can view their own files"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'private' AND
    auth.uid()::text = (storage.foldername(storage.objects.name))[1]
  );

CREATE POLICY "Users can update their own files"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'private' AND
    auth.uid()::text = (storage.foldername(storage.objects.name))[1]
  );

CREATE POLICY "Users can delete their own files"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'private' AND
    auth.uid()::text = (storage.foldername(storage.objects.name))[1]
  );
*/

------------------------------------------------------------------------------
-- PART 4: CUSTOM API FUNCTIONS
------------------------------------------------------------------------------
-- Create database functions for complex operations

-- Function to start a project's first day
CREATE OR REPLACE FUNCTION api.start_project_day(
  project_id UUID,
  day reference.framework_day
)
RETURNS api.framework_progress AS $$
DECLARE
  progress_record api.framework_progress;
BEGIN
  -- Check if user owns the project
  IF NOT api.user_owns_project(project_id) THEN
    RAISE EXCEPTION 'Not authorized to access this project';
  END IF;
  
  -- Update the project's current day
  UPDATE api.projects
  SET current_framework_day = day
  WHERE id = project_id
  AND user_id = auth.uid();
  
  -- Update the framework progress for this day
  UPDATE api.framework_progress
  SET 
    status = 'in_progress',
    started_at = COALESCE(started_at, now())
  WHERE project_id = project_id
  AND framework_day = day
  RETURNING * INTO progress_record;
  
  -- Mark the first step as in_progress if it exists
  UPDATE api.framework_steps
  SET 
    status = 'in_progress',
    started_at = now()
  WHERE project_id = project_id
  AND framework_day = day
  AND step_number = (
    SELECT MIN(step_number)
    FROM api.framework_steps
    WHERE project_id = project_id
    AND framework_day = day
  );
  
  RETURN progress_record;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, public, pg_temp;
COMMENT ON FUNCTION api.start_project_day(UUID, reference.framework_day) IS 
  'Starts a specific day in the framework for a project, updating progress tracking';

-- Function to complete a framework step
CREATE OR REPLACE FUNCTION api.complete_framework_step(
  step_id UUID
)
RETURNS api.framework_steps AS $$
DECLARE
  step_record api.framework_steps;
  project_record api.projects;
  next_step_record api.framework_steps;
  current_day reference.framework_day;
  next_day reference.framework_day;
BEGIN
  -- Get step information
  SELECT * INTO step_record
  FROM api.framework_steps
  WHERE id = step_id;
  
  -- Check if step exists
  IF step_record IS NULL THEN
    RAISE EXCEPTION 'Step not found';
  END IF;
  
  -- Check if user owns the project
  IF NOT api.user_owns_project(step_record.project_id) THEN
    RAISE EXCEPTION 'Not authorized to access this step';
  END IF;
  
  -- Get project information
  SELECT * INTO project_record
  FROM api.projects
  WHERE id = step_record.project_id;
  
  -- Mark step as completed
  UPDATE api.framework_steps
  SET 
    status = 'completed',
    completed_at = now()
  WHERE id = step_id
  RETURNING * INTO step_record;
  
  -- Check if there's a next step in current day
  SELECT * INTO next_step_record
  FROM api.framework_steps
  WHERE project_id = step_record.project_id
  AND framework_day = step_record.framework_day
  AND step_number > step_record.step_number
  AND status = 'pending'
  ORDER BY step_number
  LIMIT 1;
  
  -- If there's a next step, mark it as in_progress
  IF next_step_record IS NOT NULL THEN
    UPDATE api.framework_steps
    SET 
      status = 'in_progress',
      started_at = now()
    WHERE id = next_step_record.id;
  ELSE
    -- Check if all steps in the day are completed
    IF NOT EXISTS (
      SELECT 1 FROM api.framework_steps
      WHERE project_id = step_record.project_id
      AND framework_day = step_record.framework_day
      AND status <> 'completed'
    ) THEN
      -- Mark the day as completed
      UPDATE api.framework_progress
      SET 
        status = 'completed',
        completion_percentage = 100,
        completed_at = now()
      WHERE project_id = step_record.project_id
      AND framework_day = step_record.framework_day;
      
      -- Determine next day
      current_day := step_record.framework_day;
      
      IF current_day = 'day_1' THEN
        next_day := 'day_2';
      ELSIF current_day = 'day_2' THEN
        next_day := 'day_3';
      ELSIF current_day = 'day_3' THEN
        next_day := 'day_4';
      ELSIF current_day = 'day_4' THEN
        next_day := 'day_5';
      ELSE
        next_day := NULL; -- No next day after day_5
      END IF;
      
      -- If there's a next day, update the project
      IF next_day IS NOT NULL THEN
        UPDATE api.projects
        SET current_framework_day = next_day
        WHERE id = step_record.project_id;
      ELSE
        -- If no next day (all completed), update project status to launched
        UPDATE api.projects
        SET 
          status = 'launched',
          completion_percentage = 100
        WHERE id = step_record.project_id;
      END IF;
    END IF;
  END IF;
  
  RETURN step_record;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, public, pg_temp;
COMMENT ON FUNCTION api.complete_framework_step(UUID) IS 
  'Marks a framework step as completed and handles progression to the next step or day';

-- Function to create a new AI conversation
CREATE OR REPLACE FUNCTION api.create_ai_conversation(
  project_id UUID,
  step_id UUID,
  task_id UUID,
  title TEXT,
  model TEXT,
  initial_message TEXT
)
RETURNS api.ai_conversations AS $$
DECLARE
  conversation_record api.ai_conversations;
BEGIN
  -- Check if user owns the project
  IF NOT api.user_owns_project(project_id) THEN
    RAISE EXCEPTION 'Not authorized to create a conversation for this project';
  END IF;
  
  -- Check if user has credits for this operation
  IF internal.get_user_credit_balance(auth.uid()) <= 0 THEN
    RAISE EXCEPTION 'Insufficient credits to start a new AI conversation';
  END IF;
  
  -- Create conversation
  INSERT INTO api.ai_conversations (
    project_id,
    step_id,
    task_id,
    title,
    model,
    is_complete,
    token_count
  )
  VALUES (
    project_id,
    step_id,
    task_id,
    title,
    model,
    false,
    0
  )
  RETURNING * INTO conversation_record;
  
  -- Add initial system message if provided
  IF initial_message IS NOT NULL THEN
    INSERT INTO api.ai_messages (
      conversation_id,
      role,
      content,
      tokens,
      sequence_number
    )
    VALUES (
      conversation_record.id,
      'system',
      initial_message,
      length(initial_message) / 4, -- Rough estimate
      1
    );
  END IF;
  
  -- Deduct a credit for conversation creation
  INSERT INTO internal.credit_transactions (
    user_id,
    amount,
    transaction_type,
    reference
  )
  VALUES (
    auth.uid(),
    -1,
    'conversation_creation',
    conversation_record.id::text
  );
  
  RETURN conversation_record;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, internal, public, pg_temp;
COMMENT ON FUNCTION api.create_ai_conversation(UUID, UUID, UUID, TEXT, TEXT, TEXT) IS 
  'Creates a new AI conversation and initializes it with an optional system message';

-- Function to add a message to a conversation
CREATE OR REPLACE FUNCTION api.add_message_to_conversation(
  conversation_id UUID,
  role reference.message_role,
  content TEXT
)
RETURNS api.ai_messages AS $$
DECLARE
  conversation_record api.ai_conversations;
  message_record api.ai_messages;
  next_sequence INTEGER;
BEGIN
  -- Get conversation to check ownership
  SELECT * INTO conversation_record
  FROM api.ai_conversations
  WHERE id = conversation_id;
  
  -- Check if conversation exists
  IF conversation_record IS NULL THEN
    RAISE EXCEPTION 'Conversation not found';
  END IF;
  
  -- Check if user owns the project
  IF NOT api.user_owns_project(conversation_record.project_id) THEN
    RAISE EXCEPTION 'Not authorized to add messages to this conversation';
  END IF;
  
  -- Check if conversation is complete
  IF conversation_record.is_complete THEN
    RAISE EXCEPTION 'Cannot add messages to a completed conversation';
  END IF;
  
  -- Get next sequence number
  SELECT COALESCE(MAX(sequence_number), 0) + 1 INTO next_sequence
  FROM api.ai_messages
  WHERE conversation_id = add_message_to_conversation.conversation_id;
  
  -- Calculate approximate token count (rough estimate)
  DECLARE
    token_estimate INTEGER := length(content) / 4;
  BEGIN
    -- Insert message
    INSERT INTO api.ai_messages (
      conversation_id,
      role,
      content,
      tokens,
      sequence_number
    )
    VALUES (
      conversation_id,
      role,
      content,
      token_estimate,
      next_sequence
    )
    RETURNING * INTO message_record;
  END;
  
  RETURN message_record;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, public, pg_temp;
COMMENT ON FUNCTION api.add_message_to_conversation(UUID, reference.message_role, TEXT) IS 
  'Adds a new message to an existing AI conversation';

-- Function to create a document
CREATE OR REPLACE FUNCTION api.create_document(
  project_id UUID,
  step_id UUID,
  type reference.document_type,
  title TEXT,
  content TEXT,
  content_json JSONB
)
RETURNS api.documents AS $$
DECLARE
  document_record api.documents;
BEGIN
  -- Check if user owns the project
  IF NOT api.user_owns_project(project_id) THEN
    RAISE EXCEPTION 'Not authorized to create a document for this project';
  END IF;
  
  -- Insert document
  INSERT INTO api.documents (
    project_id,
    step_id,
    type,
    title,
    content,
    content_json,
    version,
    is_finalized
  )
  VALUES (
    project_id,
    step_id,
    type,
    title,
    content,
    content_json,
    1,
    false
  )
  RETURNING * INTO document_record;
  
  RETURN document_record;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, public, pg_temp;
COMMENT ON FUNCTION api.create_document(UUID, UUID, reference.document_type, TEXT, TEXT, JSONB) IS 
  'Creates a new document associated with a project and optional step';

-- Function to finalize a document
CREATE OR REPLACE FUNCTION api.finalize_document(
  document_id UUID
)
RETURNS api.documents AS $$
DECLARE
  document_record api.documents;
BEGIN
  -- Get document to check ownership
  SELECT * INTO document_record
  FROM api.documents
  WHERE id = document_id;
  
  -- Check if document exists
  IF document_record IS NULL THEN
    RAISE EXCEPTION 'Document not found';
  END IF;
  
  -- Check if user owns the project
  IF NOT api.user_owns_project(document_record.project_id) THEN
    RAISE EXCEPTION 'Not authorized to finalize this document';
  END IF;
  
  -- Update document to finalized
  UPDATE api.documents
  SET is_finalized = true
  WHERE id = document_id
  RETURNING * INTO document_record;
  
  RETURN document_record;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, public, pg_temp;
COMMENT ON FUNCTION api.finalize_document(UUID) IS 
  'Marks a document as finalized, indicating it is complete and ready for use';

-- Function to create an implementation plan
CREATE OR REPLACE FUNCTION api.create_implementation_plan(
  project_id UUID,
  title TEXT,
  description TEXT,
  content JSONB
)
RETURNS api.implementation_plans AS $$
DECLARE
  plan_record api.implementation_plans;
BEGIN
  -- Check if user owns the project
  IF NOT api.user_owns_project(project_id) THEN
    RAISE EXCEPTION 'Not authorized to create an implementation plan for this project';
  END IF;
  
  -- Insert implementation plan
  INSERT INTO api.implementation_plans (
    project_id,
    title,
    description,
    content
  )
  VALUES (
    project_id,
    title,
    description,
    content
  )
  RETURNING * INTO plan_record;
  
  RETURN plan_record;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, public, pg_temp;
COMMENT ON FUNCTION api.create_implementation_plan(UUID, TEXT, TEXT, JSONB) IS 
  'Creates a new implementation plan for a project';

-- Function to add credit to a user's account (admin function)
CREATE OR REPLACE FUNCTION internal.add_user_credits(
  user_id UUID,
  amount INTEGER,
  transaction_type TEXT,
  reference TEXT
)
RETURNS internal.credit_transactions AS $$
DECLARE
  transaction_record internal.credit_transactions;
BEGIN
  -- Check that amount is positive
  IF amount <= 0 THEN
    RAISE EXCEPTION 'Credit amount must be positive';
  END IF;
  
  -- Insert credit transaction
  INSERT INTO internal.credit_transactions (
    user_id,
    amount,
    transaction_type,
    reference,
    metadata
  )
  VALUES (
    user_id,
    amount,
    transaction_type,
    reference,
    jsonb_build_object(
      'added_by', auth.uid(),
      'added_at', now()
    )
  )
  RETURNING * INTO transaction_record;
  
  RETURN transaction_record;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = internal, public, pg_temp;
COMMENT ON FUNCTION internal.add_user_credits(UUID, INTEGER, TEXT, TEXT) IS 
  'Administrative function to add credits to a user account';

-- Function to initialize demo data for new users
CREATE OR REPLACE FUNCTION api.initialize_demo_project()
RETURNS api.projects AS $$
DECLARE
  project_record api.projects;
BEGIN
  -- Create a demo project for the user
  INSERT INTO api.projects (
    user_id,
    name,
    description,
    status
  )
  VALUES (
    auth.uid(),
    'Welcome to LaunchWeek.ai',
    'This is a demo project to help you get started with the 5-day framework.',
    'draft'
  )
  RETURNING * INTO project_record;
  
  -- Create initial product requirements document
  INSERT INTO api.documents (
    project_id,
    type,
    title,
    content,
    version,
    is_finalized,
    created_by
  )
  VALUES (
    project_record.id,
    'product_requirements',
    'Sample Product Requirements',
    'This is a sample product requirements document to help you understand how to structure your own PRD.',
    1,
    false,
    auth.uid()
  );
  
  -- Note: We don't add additional credits here since users already get 1 free credit at signup
  
  RETURN project_record;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, internal, public, pg_temp;
COMMENT ON FUNCTION api.initialize_demo_project() IS 
  'Creates a demo project and initial resources for new users';

-- Function to get project statistics for a specific project
CREATE OR REPLACE FUNCTION api.get_project_statistics(
  project_id UUID
)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  -- Check if user owns the project
  IF NOT api.user_owns_project(project_id) THEN
    RAISE EXCEPTION 'Not authorized to access this project';
  END IF;
  
  -- Gather statistics
  SELECT jsonb_build_object(
    'documents_count', (SELECT COUNT(*) FROM api.documents WHERE project_id = get_project_statistics.project_id),
    'conversations_count', (SELECT COUNT(*) FROM api.ai_conversations WHERE project_id = get_project_statistics.project_id),
    'completed_steps', (SELECT COUNT(*) FROM api.framework_steps WHERE project_id = get_project_statistics.project_id AND status = 'completed'),
    'total_steps', (SELECT COUNT(*) FROM api.framework_steps WHERE project_id = get_project_statistics.project_id),
    'days_progress', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'day', framework_day,
          'status', status,
          'completion_percentage', completion_percentage
        )
      )
      FROM api.framework_progress
      WHERE project_id = get_project_statistics.project_id
      ORDER BY 
        CASE 
          WHEN framework_day = 'day_1' THEN 1
          WHEN framework_day = 'day_2' THEN 2
          WHEN framework_day = 'day_3' THEN 3
          WHEN framework_day = 'day_4' THEN 4
          WHEN framework_day = 'day_5' THEN 5
        END
    ),
    'total_tokens', (
      SELECT COALESCE(SUM(token_count), 0)
      FROM api.ai_conversations
      WHERE project_id = get_project_statistics.project_id
    )
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = api, public, pg_temp;
COMMENT ON FUNCTION api.get_project_statistics(UUID) IS 
  'Returns detailed statistics about a specific project';

-- Centralized function to check user credit balance
CREATE OR REPLACE FUNCTION internal.get_user_credit_balance(
  user_id UUID
)
RETURNS INTEGER AS $$
DECLARE
  balance INTEGER;
BEGIN
  -- Get user's credit balance
  SELECT uc.balance INTO balance
  FROM internal.user_credits uc
  WHERE uc.user_id = get_user_credit_balance.user_id;
  
  -- Return 0 if no record exists
  RETURN COALESCE(balance, 0);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = internal, public, pg_temp;
COMMENT ON FUNCTION internal.get_user_credit_balance(UUID) IS 'Gets the current credit balance for a user';

-- Centralized function to check if a credit has already been consumed for a project progression
CREATE OR REPLACE FUNCTION internal.has_consumed_credit_for_progression(
  project_id UUID,
  progression_type TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  consumption_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM internal.project_credit_consumption
    WHERE project_id = has_consumed_credit_for_progression.project_id
    AND progression_type = has_consumed_credit_for_progression.progression_type
  ) INTO consumption_exists;
  
  RETURN consumption_exists;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = internal, public, pg_temp;
COMMENT ON FUNCTION internal.has_consumed_credit_for_progression(UUID, TEXT) IS 'Checks if a credit has already been consumed for a specific project progression';

-- Function to progress from PRD to marketing story (Day 1 to Day 2)
CREATE OR REPLACE FUNCTION api.progress_to_marketing_story(
  project_id UUID
)
RETURNS JSONB AS $$
DECLARE
  user_id UUID;
  project_record api.projects;
  user_credit_balance INTEGER;
  min_credits INTEGER;
  transaction_id UUID;
  result JSONB;
BEGIN
  -- Get the project details
  SELECT * INTO project_record
  FROM api.projects p
  WHERE p.id = project_id;
  
  -- Check if project exists
  IF project_record IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'result', 'system_error',
      'message', 'Project not found'
    );
  END IF;
  
  -- Check if user owns the project
  IF project_record.user_id != auth.uid() THEN
    RETURN jsonb_build_object(
      'success', false,
      'result', 'system_error',
      'message', 'Not authorized to access this project'
    );
  END IF;
  
  -- Check if the project is already past day 1
  IF project_record.current_framework_day != 'day_1' THEN
    RETURN jsonb_build_object(
      'success', false,
      'result', 'already_consumed',
      'message', 'Project has already progressed past PRD stage'
    );
  END IF;
  
  -- Check if a credit has already been consumed for this progression
  IF internal.has_consumed_credit_for_progression(project_id, 'prd_to_marketing') THEN
    RETURN jsonb_build_object(
      'success', false,
      'result', 'already_consumed',
      'message', 'Credit has already been consumed for this progression'
    );
  END IF;
  
  -- Get minimum credits needed
  SELECT COALESCE(value::INTEGER, 1) INTO min_credits
  FROM constants.credit_system
  WHERE name = 'MIN_CREDITS_FOR_PROGRESSION';
  
  -- Get user's credit balance
  user_credit_balance := internal.get_user_credit_balance(auth.uid());
  
  -- Check if user has enough credits
  IF user_credit_balance < min_credits THEN
    RETURN jsonb_build_object(
      'success', false,
      'result', 'insufficient_credits',
      'message', format('Insufficient credits. Required: %s, Current balance: %s', min_credits, user_credit_balance)
    );
  END IF;
  
  -- Start a transaction block for atomic operations
  BEGIN
    -- Consume a credit
    INSERT INTO internal.credit_transactions (
      user_id,
      amount,
      transaction_type,
      metadata
    )
    VALUES (
      auth.uid(),
      -min_credits,
      'project_progression',
      jsonb_build_object(
        'project_id', project_id, 
        'progression_type', 'prd_to_marketing', 
        'framework_day_from', 'day_1',
        'framework_day_to', 'day_2'
      )
    )
    RETURNING id INTO transaction_id;
    
    -- Check if the transaction was successful by getting its result
    DECLARE
      transaction_result reference.credit_operation_result;
    BEGIN
      SELECT operation_result INTO transaction_result
      FROM internal.credit_transactions
      WHERE id = transaction_id;
      
      -- If there was an issue with the credit deduction, return an error
      IF transaction_result != 'success' THEN
        RAISE EXCEPTION 'Credit transaction failed: %', transaction_result;
      END IF;
    END;
    
    -- Record the consumption for this project progression
    INSERT INTO internal.project_credit_consumption (
      project_id,
      user_id,
      transaction_id,
      progression_type,
      framework_day_from,
      framework_day_to,
      metadata
    )
    VALUES (
      project_id,
      auth.uid(),
      transaction_id,
      'prd_to_marketing',
      'day_1',
      'day_2',
      jsonb_build_object(
        'project_name', project_record.name,
        'progression_date', now()
      )
    );
    
    -- Update project to day 2
    UPDATE api.projects
    SET current_framework_day = 'day_2'
    WHERE id = project_id;
    
    -- Update framework progress for day 2
    UPDATE api.framework_progress
    SET 
      status = 'in_progress',
      started_at = now()
    WHERE project_id = project_id
    AND framework_day = 'day_2';
    
    -- Mark the first step of day 2 as in_progress
    UPDATE api.framework_steps
    SET 
      status = 'in_progress',
      started_at = now()
    WHERE project_id = project_id
    AND framework_day = 'day_2'
    AND step_number = (
      SELECT MIN(step_number)
      FROM api.framework_steps
      WHERE project_id = project_id
      AND framework_day = 'day_2'
    );
    
    -- Successful completion
    RETURN jsonb_build_object(
      'success', true,
      'result', 'success',
      'message', 'Successfully progressed project to marketing story stage',
      'framework_day', 'day_2',
      'credits_remaining', user_credit_balance - min_credits
    );
    
  EXCEPTION
    WHEN OTHERS THEN
      -- Log error and roll back everything
      RAISE NOTICE 'Error in progress_to_marketing_story: %', SQLERRM;
      RETURN jsonb_build_object(
        'success', false,
        'result', 'system_error',
        'message', format('System error occurred: %s', SQLERRM)
      );
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, internal, constants, public, pg_temp;
COMMENT ON FUNCTION api.progress_to_marketing_story(UUID) IS 'Consumes a credit and progresses a project from PRD (Day 1) to marketing story (Day 2) with comprehensive error handling';

-- Function to check if user can progress to marketing story
CREATE OR REPLACE FUNCTION api.can_progress_to_marketing_story(
  project_id UUID
)
RETURNS JSONB AS $$
DECLARE
  user_credit_balance INTEGER;
  min_credits INTEGER;
  project_record api.projects;
BEGIN
  -- Get the project record
  SELECT * INTO project_record
  FROM api.projects p
  WHERE p.id = project_id;
  
  -- Check if project exists
  IF project_record IS NULL THEN
    RETURN jsonb_build_object(
      'can_progress', false,
      'reason', 'project_not_found',
      'message', 'Project not found'
    );
  END IF;
  
  -- Check if user owns the project
  IF project_record.user_id != auth.uid() THEN
    RETURN jsonb_build_object(
      'can_progress', false,
      'reason', 'not_authorized',
      'message', 'Not authorized to access this project'
    );
  END IF;
  
  -- Check if the project is already past day 1
  IF project_record.current_framework_day != 'day_1' THEN
    RETURN jsonb_build_object(
      'can_progress', false,
      'reason', 'already_progressed',
      'message', 'Project has already progressed past PRD stage'
    );
  END IF;
  
  -- Check if a credit has already been consumed for this progression
  IF internal.has_consumed_credit_for_progression(project_id, 'prd_to_marketing') THEN
    RETURN jsonb_build_object(
      'can_progress', false,
      'reason', 'already_consumed',
      'message', 'Credit has already been consumed for this progression'
    );
  END IF;
  
  -- Get minimum credits needed
  SELECT COALESCE(value::INTEGER, 1) INTO min_credits
  FROM constants.credit_system
  WHERE name = 'MIN_CREDITS_FOR_PROGRESSION';
  
  -- Get user's credit balance
  user_credit_balance := internal.get_user_credit_balance(auth.uid());
  
  -- Return results
  IF user_credit_balance >= min_credits THEN
    RETURN jsonb_build_object(
      'can_progress', true,
      'credits_available', user_credit_balance,
      'credits_required', min_credits
    );
  ELSE
    RETURN jsonb_build_object(
      'can_progress', false,
      'reason', 'insufficient_credits',
      'credits_available', user_credit_balance,
      'credits_required', min_credits,
      'message', format('You need %s credit(s) to progress (you have %s)', min_credits, user_credit_balance)
    );
  END IF;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = api, internal, constants, public, pg_temp;
COMMENT ON FUNCTION api.can_progress_to_marketing_story(UUID) IS 'Checks if the current user has enough credits to progress a specific project to the marketing story stage';

-- Function to purchase credit packages with improved error handling
CREATE OR REPLACE FUNCTION api.purchase_credit_package(
  package_id UUID,
  stripe_payment_id TEXT
)
RETURNS JSONB AS $$
DECLARE
  package_record config.credit_packages;
  transaction_id UUID;
BEGIN
  -- Start a transaction block
  BEGIN
    -- Get package information
    SELECT * INTO package_record
    FROM config.credit_packages
    WHERE id = package_id AND is_active = true;
    
    -- Check if package exists
    IF package_record IS NULL THEN
      RETURN jsonb_build_object(
        'success', false,
        'result', 'invalid_package',
        'message', 'Credit package not found or inactive'
      );
    END IF;
    
    -- Add credits to user account
    INSERT INTO internal.credit_transactions (
      user_id,
      amount,
      transaction_type,
      stripe_payment_id,
      price_cents,
      metadata
    )
    VALUES (
      auth.uid(),
      package_record.credits,
      package_record.transaction_type,
      stripe_payment_id,
      package_record.price_cents,
      jsonb_build_object(
        'package_id', package_record.id,
        'package_name', package_record.name,
        'purchase_date', now()
      )
    )
    RETURNING id INTO transaction_id;
    
    -- Get the new balance
    DECLARE
      new_balance INTEGER;
    BEGIN
      SELECT balance_after INTO new_balance
      FROM internal.credit_transactions
      WHERE id = transaction_id;
      
      RETURN jsonb_build_object(
        'success', true,
        'result', 'success',
        'message', format('Successfully purchased %s credits', package_record.credits),
        'credits_purchased', package_record.credits,
        'new_balance', new_balance,
        'transaction_id', transaction_id
      );
    END;
  EXCEPTION
    WHEN OTHERS THEN
      -- Log error and return failure
      RAISE NOTICE 'Error in purchase_credit_package: %', SQLERRM;
      RETURN jsonb_build_object(
        'success', false,
        'result', 'system_error',
        'message', format('System error occurred: %s', SQLERRM)
      );
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = api, internal, config, public, pg_temp;
COMMENT ON FUNCTION api.purchase_credit_package(UUID, TEXT) IS 'Processes a credit package purchase and adds credits to the user account with enhanced error handling';

-- Function to get summary of available credit packages
CREATE OR REPLACE FUNCTION api.get_credit_packages()
RETURNS JSONB AS $$
DECLARE
  packages JSONB;
BEGIN
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', id,
      'name', name,
      'credits', credits,
      'price_cents', price_cents,
      'price_formatted', format('$%s.%s', price_cents / 100, LPAD((price_cents % 100)::TEXT, 2, '0'))
    )
  )
  INTO packages
  FROM config.credit_packages
  WHERE is_active = true
  ORDER BY credits ASC;
  
  RETURN jsonb_build_object(
    'packages', COALESCE(packages, '[]'::JSONB)
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = config, public, pg_temp;
COMMENT ON FUNCTION api.get_credit_packages() IS 'Returns a list of active credit packages available for purchase with formatted prices';

-- Enhanced function to get user credit history
CREATE OR REPLACE FUNCTION api.get_my_credit_history()
RETURNS JSONB AS $$
DECLARE
  history JSONB;
  balance INTEGER;
BEGIN
  -- Get current balance
  balance := internal.get_user_credit_balance(auth.uid());
  
  -- Get transaction history
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', ct.id,
      'date', ct.created_at,
      'type', ct.transaction_type,
      'amount', ct.amount,
      'balance_after', ct.balance_after,
      'price_cents', ct.price_cents,
      'price_formatted', CASE 
        WHEN ct.price_cents IS NOT NULL 
        THEN format('$%s.%s', ct.price_cents / 100, LPAD((ct.price_cents % 100)::TEXT, 2, '0'))
        ELSE NULL
      END,
      'status', ct.operation_result,
      'metadata', ct.metadata
    )
    ORDER BY ct.created_at DESC
  )
  INTO history
  FROM internal.credit_transactions ct
  WHERE ct.user_id = auth.uid();
  
  RETURN jsonb_build_object(
    'current_balance', balance,
    'transactions', COALESCE(history, '[]'::JSONB)
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = api, internal, public, pg_temp;
COMMENT ON FUNCTION api.get_my_credit_history() IS 'Returns the current user''s credit balance and transaction history';