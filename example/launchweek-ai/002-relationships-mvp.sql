-- 002-relationships.sql
-- LaunchWeek.ai Relationships Migration

-- This migration establishes the relationships between tables and optimizes query performance:
-- - Defines foreign key constraints between tables
-- - Creates indexes for optimizing common query patterns
-- - Sets up views for analytics and reporting

------------------------------------------------------------------------------
-- PART 1: RELATIONSHIPS AND FOREIGN KEYS
------------------------------------------------------------------------------
-- Define relationships between tables that weren't already established

-- Link framework_progress to projects
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fk_framework_progress_project_id' AND conrelid = 'api.framework_progress'::regclass
  ) THEN
    ALTER TABLE api.framework_progress
      ADD CONSTRAINT fk_framework_progress_project_id
      FOREIGN KEY (project_id) REFERENCES api.projects(id) ON DELETE CASCADE;
  END IF;
END $$;
COMMENT ON CONSTRAINT fk_framework_progress_project_id ON api.framework_progress IS 
  'Ensures framework progress is associated with a valid project and is removed when project is deleted';

-- Link framework_steps to projects
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fk_framework_steps_project_id' AND conrelid = 'api.framework_steps'::regclass
  ) THEN
    ALTER TABLE api.framework_steps
      ADD CONSTRAINT fk_framework_steps_project_id
      FOREIGN KEY (project_id) REFERENCES api.projects(id) ON DELETE CASCADE;
  END IF;
END $$;
COMMENT ON CONSTRAINT fk_framework_steps_project_id ON api.framework_steps IS 
  'Ensures framework steps are associated with a valid project and are removed when project is deleted';

-- Link documents to projects
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fk_documents_project_id' AND conrelid = 'api.documents'::regclass
  ) THEN
    ALTER TABLE api.documents
      ADD CONSTRAINT fk_documents_project_id
      FOREIGN KEY (project_id) REFERENCES api.projects(id) ON DELETE CASCADE;
  END IF;
END $$;
COMMENT ON CONSTRAINT fk_documents_project_id ON api.documents IS 
  'Ensures documents are associated with a valid project and are removed when project is deleted';

-- Link documents to framework steps
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fk_documents_step_id' AND conrelid = 'api.documents'::regclass
  ) THEN
    ALTER TABLE api.documents
      ADD CONSTRAINT fk_documents_step_id
      FOREIGN KEY (step_id) REFERENCES api.framework_steps(id) ON DELETE SET NULL;
  END IF;
END $$;
COMMENT ON CONSTRAINT fk_documents_step_id ON api.documents IS 
  'Links documents to specific framework steps, setting to NULL if step is deleted';

-- Link documents created_by and updated_by fields to users
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fk_documents_created_by' AND conrelid = 'api.documents'::regclass
  ) THEN
    ALTER TABLE api.documents
      ADD CONSTRAINT fk_documents_created_by
      FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fk_documents_updated_by' AND conrelid = 'api.documents'::regclass
  ) THEN
    ALTER TABLE api.documents
      ADD CONSTRAINT fk_documents_updated_by
      FOREIGN KEY (updated_by) REFERENCES auth.users(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Link implementation plans to projects
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fk_implementation_plans_project_id' AND conrelid = 'api.implementation_plans'::regclass
  ) THEN
    ALTER TABLE api.implementation_plans
      ADD CONSTRAINT fk_implementation_plans_project_id
      FOREIGN KEY (project_id) REFERENCES api.projects(id) ON DELETE CASCADE;
  END IF;
END $$;
COMMENT ON CONSTRAINT fk_implementation_plans_project_id ON api.implementation_plans IS 
  'Ensures implementation plans are associated with a valid project and are removed when project is deleted';

-- Link implementation tasks to plans
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fk_implementation_tasks_plan_id' AND conrelid = 'api.implementation_tasks'::regclass
  ) THEN
    ALTER TABLE api.implementation_tasks
      ADD CONSTRAINT fk_implementation_tasks_plan_id
      FOREIGN KEY (plan_id) REFERENCES api.implementation_plans(id) ON DELETE CASCADE;
  END IF;
END $$;
COMMENT ON CONSTRAINT fk_implementation_tasks_plan_id ON api.implementation_tasks IS 
  'Ensures implementation tasks are associated with a valid plan and are removed when plan is deleted';

-- Link AI conversations to projects
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fk_ai_conversations_project_id' AND conrelid = 'api.ai_conversations'::regclass
  ) THEN
    ALTER TABLE api.ai_conversations
      ADD CONSTRAINT fk_ai_conversations_project_id
      FOREIGN KEY (project_id) REFERENCES api.projects(id) ON DELETE CASCADE;
  END IF;
END $$;
COMMENT ON CONSTRAINT fk_ai_conversations_project_id ON api.ai_conversations IS 
  'Ensures AI conversations are associated with a valid project and are removed when project is deleted';

-- Link AI conversations to framework steps
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fk_ai_conversations_step_id' AND conrelid = 'api.ai_conversations'::regclass
  ) THEN
    ALTER TABLE api.ai_conversations
      ADD CONSTRAINT fk_ai_conversations_step_id
      FOREIGN KEY (step_id) REFERENCES api.framework_steps(id) ON DELETE SET NULL;
  END IF;
END $$;
COMMENT ON CONSTRAINT fk_ai_conversations_step_id ON api.ai_conversations IS 
  'Links AI conversations to specific framework steps, setting to NULL if step is deleted';

-- Link AI conversations to implementation tasks
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fk_ai_conversations_task_id' AND conrelid = 'api.ai_conversations'::regclass
  ) THEN
    ALTER TABLE api.ai_conversations
      ADD CONSTRAINT fk_ai_conversations_task_id
      FOREIGN KEY (task_id) REFERENCES api.implementation_tasks(id) ON DELETE SET NULL;
  END IF;
END $$;
COMMENT ON CONSTRAINT fk_ai_conversations_task_id ON api.ai_conversations IS 
  'Links AI conversations to specific implementation tasks, setting to NULL if task is deleted';

-- Link AI messages to conversations
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fk_ai_messages_conversation_id' AND conrelid = 'api.ai_messages'::regclass
  ) THEN
    ALTER TABLE api.ai_messages
      ADD CONSTRAINT fk_ai_messages_conversation_id
      FOREIGN KEY (conversation_id) REFERENCES api.ai_conversations(id) ON DELETE CASCADE;
  END IF;
END $$;
COMMENT ON CONSTRAINT fk_ai_messages_conversation_id ON api.ai_messages IS 
  'Ensures AI messages are associated with a valid conversation and are removed when conversation is deleted';

-- Link internal AI tasks to projects
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fk_ai_tasks_project_id' AND conrelid = 'internal.ai_tasks'::regclass
  ) THEN
    ALTER TABLE internal.ai_tasks
      ADD CONSTRAINT fk_ai_tasks_project_id
      FOREIGN KEY (project_id) REFERENCES api.projects(id) ON DELETE CASCADE;
  END IF;
END $$;
COMMENT ON CONSTRAINT fk_ai_tasks_project_id ON internal.ai_tasks IS 
  'Ensures AI tasks are associated with a valid project and are removed when project is deleted';

-- Link internal AI tasks to conversations
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fk_ai_tasks_conversation_id' AND conrelid = 'internal.ai_tasks'::regclass
  ) THEN
    ALTER TABLE internal.ai_tasks
      ADD CONSTRAINT fk_ai_tasks_conversation_id
      FOREIGN KEY (conversation_id) REFERENCES api.ai_conversations(id) ON DELETE SET NULL;
  END IF;
END $$;
COMMENT ON CONSTRAINT fk_ai_tasks_conversation_id ON internal.ai_tasks IS 
  'Links AI tasks to specific conversations, setting to NULL if conversation is deleted';

-- Link reference step templates to day templates
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fk_step_templates_day_template_id' AND conrelid = 'reference.step_templates'::regclass
  ) THEN
    ALTER TABLE reference.step_templates
      ADD CONSTRAINT fk_step_templates_day_template_id
      FOREIGN KEY (day_template_id) REFERENCES reference.day_templates(id) ON DELETE CASCADE;
  END IF;
END $$;
COMMENT ON CONSTRAINT fk_step_templates_day_template_id ON reference.step_templates IS 
  'Ensures step templates are associated with a valid day template and are removed when day template is deleted';

-- Link reference prompt templates to step templates
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fk_prompt_templates_step_template_id' AND conrelid = 'reference.prompt_templates'::regclass
  ) THEN
    ALTER TABLE reference.prompt_templates
      ADD CONSTRAINT fk_prompt_templates_step_template_id
      FOREIGN KEY (step_template_id) REFERENCES reference.step_templates(id) ON DELETE CASCADE;
  END IF;
END $$;
COMMENT ON CONSTRAINT fk_prompt_templates_step_template_id ON reference.prompt_templates IS 
  'Ensures prompt templates are associated with a valid step template and are removed when step template is deleted';

-- Link profile current_project_id to projects
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fk_profiles_current_project_id' AND conrelid = 'api.profiles'::regclass
  ) THEN
    ALTER TABLE api.profiles
      ADD CONSTRAINT fk_profiles_current_project_id
      FOREIGN KEY (current_project_id) REFERENCES api.projects(id) ON DELETE SET NULL;
  END IF;
END $$;
COMMENT ON CONSTRAINT fk_profiles_current_project_id ON api.profiles IS 
  'Links user profiles to their current active project, setting to NULL if project is deleted';

-- Add unique constraints for fields that need to be unique
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'uq_framework_progress_project_day' AND conrelid = 'api.framework_progress'::regclass
  ) THEN
    ALTER TABLE api.framework_progress
      ADD CONSTRAINT uq_framework_progress_project_day
      UNIQUE (project_id, framework_day);
  END IF;
END $$;
COMMENT ON CONSTRAINT uq_framework_progress_project_day ON api.framework_progress IS 
  'Ensures there is only one progress record per day for each project';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'uq_framework_steps_project_day_number' AND conrelid = 'api.framework_steps'::regclass
  ) THEN
    ALTER TABLE api.framework_steps
      ADD CONSTRAINT uq_framework_steps_project_day_number
      UNIQUE (project_id, framework_day, step_number);
  END IF;
END $$;
COMMENT ON CONSTRAINT uq_framework_steps_project_day_number ON api.framework_steps IS 
  'Ensures step numbers are unique within each day for each project';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'uq_day_templates_framework_day' AND conrelid = 'reference.day_templates'::regclass
  ) THEN
    ALTER TABLE reference.day_templates
      ADD CONSTRAINT uq_day_templates_framework_day
      UNIQUE (framework_day);
  END IF;
END $$;
COMMENT ON CONSTRAINT uq_day_templates_framework_day ON reference.day_templates IS 
  'Ensures there is only one template per framework day';

------------------------------------------------------------------------------
-- PART 2: INDEXES
------------------------------------------------------------------------------
-- Create indexes for optimizing query performance

-- Foreign key indexes that weren't already created

-- framework_progress indexes
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'framework_progress_project_id_idx'
  ) THEN
    CREATE INDEX framework_progress_project_id_idx ON api.framework_progress(project_id);
  END IF;
END $$;
COMMENT ON INDEX api.framework_progress_project_id_idx IS 
  'Improves performance when querying framework progress by project';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'framework_progress_status_idx'
  ) THEN
    CREATE INDEX framework_progress_status_idx ON api.framework_progress(status);
  END IF;
END $$;
COMMENT ON INDEX api.framework_progress_status_idx IS 
  'Improves performance when filtering framework progress by status';

-- framework_steps indexes
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'framework_steps_project_id_idx'
  ) THEN
    CREATE INDEX framework_steps_project_id_idx ON api.framework_steps(project_id);
  END IF;
END $$;
COMMENT ON INDEX api.framework_steps_project_id_idx IS 
  'Improves performance when querying steps by project';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'framework_steps_status_idx'
  ) THEN
    CREATE INDEX framework_steps_status_idx ON api.framework_steps(status);
  END IF;
END $$;
COMMENT ON INDEX api.framework_steps_status_idx IS 
  'Improves performance when filtering steps by status';

-- documents indexes
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'documents_project_id_idx'
  ) THEN
    CREATE INDEX documents_project_id_idx ON api.documents(project_id);
  END IF;
END $$;
COMMENT ON INDEX api.documents_project_id_idx IS 
  'Improves performance when querying documents by project';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'documents_step_id_idx'
  ) THEN
    CREATE INDEX documents_step_id_idx ON api.documents(step_id);
  END IF;
END $$;
COMMENT ON INDEX api.documents_step_id_idx IS 
  'Improves performance when querying documents by framework step';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'documents_type_idx'
  ) THEN
    CREATE INDEX documents_type_idx ON api.documents(type);
  END IF;
END $$;
COMMENT ON INDEX api.documents_type_idx IS 
  'Improves performance when filtering documents by type';

-- implementation_plans indexes
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'implementation_plans_project_id_idx'
  ) THEN
    CREATE INDEX implementation_plans_project_id_idx ON api.implementation_plans(project_id);
  END IF;
END $$;
COMMENT ON INDEX api.implementation_plans_project_id_idx IS 
  'Improves performance when querying implementation plans by project';

-- implementation_tasks indexes
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'implementation_tasks_plan_id_idx'
  ) THEN
    CREATE INDEX implementation_tasks_plan_id_idx ON api.implementation_tasks(plan_id);
  END IF;
END $$;
COMMENT ON INDEX api.implementation_tasks_plan_id_idx IS 
  'Improves performance when querying implementation tasks by plan';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'implementation_tasks_status_idx'
  ) THEN
    CREATE INDEX implementation_tasks_status_idx ON api.implementation_tasks(status);
  END IF;
END $$;
COMMENT ON INDEX api.implementation_tasks_status_idx IS 
  'Improves performance when filtering implementation tasks by status';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'implementation_tasks_priority_idx'
  ) THEN
    CREATE INDEX implementation_tasks_priority_idx ON api.implementation_tasks(priority);
  END IF;
END $$;
COMMENT ON INDEX api.implementation_tasks_priority_idx IS 
  'Improves performance when filtering implementation tasks by priority';

-- ai_conversations indexes
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'ai_conversations_project_id_idx'
  ) THEN
    CREATE INDEX ai_conversations_project_id_idx ON api.ai_conversations(project_id);
  END IF;
END $$;
COMMENT ON INDEX api.ai_conversations_project_id_idx IS 
  'Improves performance when querying AI conversations by project';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'ai_conversations_step_id_idx'
  ) THEN
    CREATE INDEX ai_conversations_step_id_idx ON api.ai_conversations(step_id);
  END IF;
END $$;
COMMENT ON INDEX api.ai_conversations_step_id_idx IS 
  'Improves performance when querying AI conversations by framework step';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'ai_conversations_task_id_idx'
  ) THEN
    CREATE INDEX ai_conversations_task_id_idx ON api.ai_conversations(task_id);
  END IF;
END $$;
COMMENT ON INDEX api.ai_conversations_task_id_idx IS 
  'Improves performance when querying AI conversations by implementation task';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'ai_conversations_is_complete_idx'
  ) THEN
    CREATE INDEX ai_conversations_is_complete_idx ON api.ai_conversations(is_complete);
  END IF;
END $$;
COMMENT ON INDEX api.ai_conversations_is_complete_idx IS 
  'Improves performance when filtering AI conversations by completion status';

-- ai_messages indexes
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'ai_messages_conversation_id_idx'
  ) THEN
    CREATE INDEX ai_messages_conversation_id_idx ON api.ai_messages(conversation_id);
  END IF;
END $$;
COMMENT ON INDEX api.ai_messages_conversation_id_idx IS 
  'Improves performance when querying AI messages by conversation';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'ai_messages_conversation_id_sequence_idx'
  ) THEN
    CREATE INDEX ai_messages_conversation_id_sequence_idx ON api.ai_messages(conversation_id, sequence_number);
  END IF;
END $$;
COMMENT ON INDEX api.ai_messages_conversation_id_sequence_idx IS 
  'Improves performance when retrieving ordered messages within a conversation';

-- Add GIN indexes for JSONB fields
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'documents_content_json_idx'
  ) THEN
    CREATE INDEX documents_content_json_idx ON api.documents USING GIN (content_json);
  END IF;
END $$;
COMMENT ON INDEX api.documents_content_json_idx IS 
  'Enables efficient querying of JSONB content in documents';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'implementation_plans_content_idx'
  ) THEN
    CREATE INDEX implementation_plans_content_idx ON api.implementation_plans USING GIN (content);
  END IF;
END $$;
COMMENT ON INDEX api.implementation_plans_content_idx IS 
  'Enables efficient querying of JSONB content in implementation plans';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'implementation_tasks_dependencies_idx'
  ) THEN
    CREATE INDEX implementation_tasks_dependencies_idx ON api.implementation_tasks USING GIN (dependencies);
  END IF;
END $$;
COMMENT ON INDEX api.implementation_tasks_dependencies_idx IS 
  'Enables efficient querying of task dependencies arrays';

-- Add text search indexes
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'projects_name_description_idx'
  ) THEN
    CREATE INDEX projects_name_description_idx ON api.projects USING GIN (to_tsvector('english', name || ' ' || COALESCE(description, '')));
  END IF;
END $$;
COMMENT ON INDEX api.projects_name_description_idx IS 
  'Enables full-text search across project names and descriptions';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'documents_title_content_idx'
  ) THEN
    CREATE INDEX documents_title_content_idx ON api.documents USING GIN (to_tsvector('english', title || ' ' || COALESCE(content, '')));
  END IF;
END $$;
COMMENT ON INDEX api.documents_title_content_idx IS 
  'Enables full-text search across document titles and content';

------------------------------------------------------------------------------
-- PART 3: VIEWS
------------------------------------------------------------------------------
-- Create views for analytics and reporting

-- User project summary view
CREATE OR REPLACE VIEW analytics.user_project_summary AS
SELECT
  u.id AS user_id,
  u.email,
  p.display_name,
  COUNT(DISTINCT pr.id) AS total_projects,
  SUM(CASE WHEN pr.status = 'launched' THEN 1 ELSE 0 END) AS launched_projects,
  SUM(CASE WHEN pr.status = 'in_progress' THEN 1 ELSE 0 END) AS in_progress_projects,
  SUM(CASE WHEN pr.status = 'draft' THEN 1 ELSE 0 END) AS draft_projects,
  AVG(pr.completion_percentage) AS avg_completion_percentage,
  MIN(pr.created_at) AS first_project_date,
  MAX(pr.created_at) AS most_recent_project_date
FROM
  auth.users u
  LEFT JOIN api.profiles p ON u.id = p.id
  LEFT JOIN api.projects pr ON u.id = pr.user_id AND pr.deleted_at IS NULL
GROUP BY
  u.id, u.email, p.display_name;

COMMENT ON VIEW analytics.user_project_summary IS 
  'Provides an overview of user project statistics, including counts by status and completion rates';

-- Framework progress analytics view
CREATE OR REPLACE VIEW analytics.framework_progress_stats AS
SELECT
  fp.framework_day,
  COUNT(fp.id) AS total_instances,
  SUM(CASE WHEN fp.status = 'completed' THEN 1 ELSE 0 END) AS completed_count,
  ROUND(100.0 * SUM(CASE WHEN fp.status = 'completed' THEN 1 ELSE 0 END) / NULLIF(COUNT(fp.id), 0), 2) AS completion_percentage,
  AVG(EXTRACT(EPOCH FROM (fp.completed_at - fp.started_at)) / 3600) AS avg_completion_hours,
  MIN(EXTRACT(EPOCH FROM (fp.completed_at - fp.started_at)) / 3600) AS min_completion_hours,
  MAX(EXTRACT(EPOCH FROM (fp.completed_at - fp.started_at)) / 3600) AS max_completion_hours
FROM
  api.framework_progress fp
WHERE
  fp.started_at IS NOT NULL
GROUP BY
  fp.framework_day
ORDER BY
  CASE
    WHEN fp.framework_day = 'day_1' THEN 1
    WHEN fp.framework_day = 'day_2' THEN 2
    WHEN fp.framework_day = 'day_3' THEN 3
    WHEN fp.framework_day = 'day_4' THEN 4
    WHEN fp.framework_day = 'day_5' THEN 5
  END;

COMMENT ON VIEW analytics.framework_progress_stats IS 
  'Provides statistics on framework progress by day, including completion rates and time metrics';

-- AI usage analytics view
CREATE OR REPLACE VIEW analytics.ai_usage_metrics AS
SELECT
  DATE_TRUNC('day', ac.created_at) AS usage_date,
  COUNT(DISTINCT ac.id) AS conversation_count,
  COUNT(DISTINCT ac.project_id) AS projects_with_ai,
  COUNT(am.id) AS total_messages,
  SUM(CASE WHEN am.role = 'user' THEN 1 ELSE 0 END) AS user_messages,
  SUM(CASE WHEN am.role = 'assistant' THEN 1 ELSE 0 END) AS assistant_messages,
  SUM(am.tokens) AS total_tokens,
  AVG(am.tokens) AS avg_tokens_per_message,
  SUM(ac.token_count) AS total_conversation_tokens,
  AVG(ac.token_count) AS avg_tokens_per_conversation
FROM
  api.ai_conversations ac
  JOIN api.ai_messages am ON ac.id = am.conversation_id
GROUP BY
  DATE_TRUNC('day', ac.created_at)
ORDER BY
  usage_date DESC;

COMMENT ON VIEW analytics.ai_usage_metrics IS 
  'Provides daily metrics on AI usage, including conversation counts, message distribution, and token consumption';

-- Framework steps performance view
CREATE OR REPLACE VIEW analytics.step_performance AS
SELECT
  fs.framework_day,
  fs.step_type,
  COUNT(fs.id) AS total_instances,
  SUM(CASE WHEN fs.status = 'completed' THEN 1 ELSE 0 END) AS completed_count,
  SUM(CASE WHEN fs.status = 'failed' THEN 1 ELSE 0 END) AS failed_count,
  ROUND(100.0 * SUM(CASE WHEN fs.status = 'completed' THEN 1 ELSE 0 END) / NULLIF(COUNT(fs.id), 0), 2) AS completion_percentage,
  AVG(EXTRACT(EPOCH FROM (fs.completed_at - fs.started_at)) / 60) AS avg_completion_minutes
FROM
  api.framework_steps fs
WHERE
  fs.started_at IS NOT NULL
GROUP BY
  fs.framework_day, fs.step_type
ORDER BY
  CASE
    WHEN fs.framework_day = 'day_1' THEN 1
    WHEN fs.framework_day = 'day_2' THEN 2
    WHEN fs.framework_day = 'day_3' THEN 3
    WHEN fs.framework_day = 'day_4' THEN 4
    WHEN fs.framework_day = 'day_5' THEN 5
  END,
  fs.step_type;

COMMENT ON VIEW analytics.step_performance IS 
  'Provides performance metrics for framework steps by day and type, including completion rates and average time';

-- Project completion timeline view
CREATE OR REPLACE VIEW analytics.project_timeline AS
SELECT
  p.id AS project_id,
  p.name AS project_name,
  p.user_id,
  u.email AS user_email,
  p.created_at AS project_start,
  MIN(CASE WHEN fp.framework_day = 'day_1' THEN fp.completed_at END) AS day_1_completion,
  MIN(CASE WHEN fp.framework_day = 'day_2' THEN fp.completed_at END) AS day_2_completion,
  MIN(CASE WHEN fp.framework_day = 'day_3' THEN fp.completed_at END) AS day_3_completion,
  MIN(CASE WHEN fp.framework_day = 'day_4' THEN fp.completed_at END) AS day_4_completion,
  MIN(CASE WHEN fp.framework_day = 'day_5' THEN fp.completed_at END) AS day_5_completion,
  p.status AS current_status,
  p.completion_percentage
FROM
  api.projects p
  JOIN auth.users u ON p.user_id = u.id
  LEFT JOIN api.framework_progress fp ON p.id = fp.project_id
WHERE
  p.deleted_at IS NULL
GROUP BY
  p.id, p.name, p.user_id, u.email, p.created_at, p.status, p.completion_percentage
ORDER BY
  p.created_at DESC;

COMMENT ON VIEW analytics.project_timeline IS 
  'Provides a timeline view of project progression through the framework days';

-- Document analytics view
CREATE OR REPLACE VIEW analytics.document_metrics AS
SELECT
  d.type AS document_type,
  COUNT(d.id) AS total_documents,
  AVG(LENGTH(d.content)) AS avg_content_length,
  AVG(d.version) AS avg_version_count,
  COUNT(DISTINCT d.project_id) AS projects_with_documents,
  SUM(CASE WHEN d.is_finalized THEN 1 ELSE 0 END) AS finalized_documents,
  ROUND(100.0 * SUM(CASE WHEN d.is_finalized THEN 1 ELSE 0 END) / NULLIF(COUNT(d.id), 0), 2) AS finalization_percentage
FROM
  api.documents d
GROUP BY
  d.type
ORDER BY
  d.type;

COMMENT ON VIEW analytics.document_metrics IS 
  'Provides metrics on document creation, including counts by type, average length, and finalization rates';

-- User engagement view
CREATE OR REPLACE VIEW analytics.user_engagement AS
SELECT
  u.id AS user_id,
  u.email,
  p.display_name,
  MAX(pr.updated_at) AS last_project_activity,
  MAX(fp.updated_at) AS last_framework_progress,
  MAX(ac.updated_at) AS last_ai_conversation,
  MAX(d.updated_at) AS last_document_update,
  COUNT(DISTINCT pr.id) AS project_count,
  COUNT(DISTINCT ac.id) AS conversation_count,
  COUNT(DISTINCT d.id) AS document_count,
  EXTRACT(EPOCH FROM (NOW() - MAX(
    GREATEST(
      COALESCE(pr.updated_at, '1970-01-01'::timestamptz),
      COALESCE(fp.updated_at, '1970-01-01'::timestamptz),
      COALESCE(ac.updated_at, '1970-01-01'::timestamptz),
      COALESCE(d.updated_at, '1970-01-01'::timestamptz)
    )
  ))) / 86400 AS days_since_last_activity
FROM
  auth.users u
  LEFT JOIN api.profiles p ON u.id = p.id
  LEFT JOIN api.projects pr ON u.id = pr.user_id AND pr.deleted_at IS NULL
  LEFT JOIN api.framework_progress fp ON pr.id = fp.project_id
  LEFT JOIN api.ai_conversations ac ON pr.id = ac.project_id
  LEFT JOIN api.documents d ON pr.id = d.project_id
GROUP BY
  u.id, u.email, p.display_name
ORDER BY
  days_since_last_activity;

COMMENT ON VIEW analytics.user_engagement IS 
  'Provides user engagement metrics, including last activity timestamps and content creation counts';

-- Subscription metrics view (if using Stripe)
CREATE OR REPLACE VIEW analytics.subscription_metrics AS
SELECT
  DATE_TRUNC('month', s.created_at) AS month,
  p.name AS plan_name,
  COUNT(DISTINCT s.id) AS new_subscriptions,
  COUNT(DISTINCT s.customer_id) AS unique_customers,
  SUM(CASE WHEN s.status = 'active' THEN 1 ELSE 0 END) AS active_subscriptions,
  SUM(CASE WHEN s.status = 'canceled' THEN 1 ELSE 0 END) AS canceled_subscriptions,
  SUM(pi.unit_amount) / 100.0 AS monthly_revenue
FROM
  stripe.subscriptions s
  JOIN stripe.prices pi ON s.price_id = pi.id
  JOIN stripe.products p ON pi.product_id = p.id
GROUP BY
  DATE_TRUNC('month', s.created_at), p.name
ORDER BY
  month DESC, p.name;

COMMENT ON VIEW analytics.subscription_metrics IS 
  'Provides monthly subscription metrics, including new subscriptions, cancellations, and revenue';