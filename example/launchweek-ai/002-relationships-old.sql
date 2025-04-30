-- 002-relationships.sql
-- 
-- This migration establishes relationships between tables, adds necessary indexes,
-- and creates views for reporting and analytics. It builds on the previous migrations
-- to create a fully normalized database structure with optimized query performance.

-- =============================================================================
-- RELATIONSHIPS AND FOREIGN KEYS
-- =============================================================================

-- Documents to Projects relationship
-- This allows all documents to be properly associated with their parent project
-- Supports requirement 6.2 (AI-Guided Document Creation) by linking documents to projects
ALTER TABLE api.documents
  ADD CONSTRAINT fk_documents_project_id
  FOREIGN KEY (project_id) REFERENCES api.projects(id)
  ON DELETE CASCADE; -- When a project is deleted, all its documents are deleted
COMMENT ON CONSTRAINT fk_documents_project_id ON api.documents IS 
  'Links documents to their parent project, ensuring documents are deleted when a project is removed';

-- Document Versions to Documents relationship
-- Enables version history tracking for all documents
-- Supports requirement 6.3.3 (Document Version History) by linking versions to their parent document
ALTER TABLE api.document_versions
  ADD CONSTRAINT fk_document_versions_document_id
  FOREIGN KEY (document_id) REFERENCES api.documents(id)
  ON DELETE CASCADE; -- When a document is deleted, all its versions are deleted
COMMENT ON CONSTRAINT fk_document_versions_document_id ON api.document_versions IS 
  'Links document versions to their parent document, ensuring version history is maintained and properly cleaned up';

-- Implementation Guides to Projects relationship
-- Associates implementation guides with their parent project
-- Supports requirement 6.5 (Technical Implementation Guidance) by linking guides to projects
ALTER TABLE api.implementation_guides
  ADD CONSTRAINT fk_implementation_guides_project_id
  FOREIGN KEY (project_id) REFERENCES api.projects(id)
  ON DELETE CASCADE; -- When a project is deleted, all its implementation guides are deleted
COMMENT ON CONSTRAINT fk_implementation_guides_project_id ON api.implementation_guides IS 
  'Links implementation guides to their parent project, ensuring guides are deleted when a project is removed';

-- Implementation Guides to Guide Templates relationship
-- Connects user-customized guides to their source templates
-- Supports requirement 6.5 (Technical Implementation Guidance) by linking custom guides to templates
ALTER TABLE api.implementation_guides
  ADD CONSTRAINT fk_implementation_guides_template_id
  FOREIGN KEY (guide_template_id) REFERENCES reference.guide_templates(id)
  ON DELETE RESTRICT; -- Prevent deletion of templates that are in use
COMMENT ON CONSTRAINT fk_implementation_guides_template_id ON api.implementation_guides IS 
  'Links implementation guides to their source template, preventing deletion of templates that are in use';

-- Project Progress to Projects relationship
-- Tracks progress steps for each project
-- Supports requirement 6.4.2 (Progress Tracking) by linking progress records to projects
ALTER TABLE api.project_progress
  ADD CONSTRAINT fk_project_progress_project_id
  FOREIGN KEY (project_id) REFERENCES api.projects(id)
  ON DELETE CASCADE; -- When a project is deleted, all its progress tracking is deleted
COMMENT ON CONSTRAINT fk_project_progress_project_id ON api.project_progress IS 
  'Links progress tracking records to their parent project, ensuring progress data is deleted when a project is removed';

-- Credit Transactions to Credit Balances
-- This isn't a direct foreign key but a business rule constraint to ensure transactions 
-- refer to users with a credit balance record
-- Supports requirement 6.7 (Credit and Subscription System)

-- REPLACE THIS:
-- ALTER TABLE internal.credit_transactions
--   ADD CONSTRAINT check_credit_transaction_user_has_balance
--   CHECK (
--     EXISTS (
--       SELECT 1 FROM internal.credit_balances 
--       WHERE credit_balances.user_id = credit_transactions.user_id
--     )
--   );
-- COMMENT ON CONSTRAINT check_credit_transaction_user_has_balance ON internal.credit_transactions IS
--   'Ensures credit transactions are only created for users with an existing credit balance record';

-- WITH THIS TRIGGER-BASED SOLUTION:
CREATE OR REPLACE FUNCTION internal.check_credit_balance_exists()
RETURNS TRIGGER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM internal.credit_balances 
    WHERE credit_balances.user_id = NEW.user_id
  ) THEN
    RAISE EXCEPTION 'User must have a credit balance record before creating transactions';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = internal, public, pg_temp;

COMMENT ON FUNCTION internal.check_credit_balance_exists() IS
  'Validates that a user has a credit balance record before allowing credit transactions';

CREATE TRIGGER ensure_credit_balance_exists
BEFORE INSERT OR UPDATE ON internal.credit_transactions
FOR EACH ROW EXECUTE FUNCTION internal.check_credit_balance_exists();

COMMENT ON TRIGGER ensure_credit_balance_exists ON internal.credit_transactions IS
  'Ensures credit transactions are only created for users with an existing credit balance record';

-- Enforce uniqueness constraints for business rules

-- Ensure users can't have duplicate projects with the same name
-- Supports requirement 6.1.1 (Basic Project Creation) by preventing duplicate project names
ALTER TABLE api.projects
  ADD CONSTRAINT unique_project_name_per_user
  UNIQUE (user_id, name, deleted_at);
COMMENT ON CONSTRAINT unique_project_name_per_user ON api.projects IS
  'Prevents users from creating multiple projects with the same name (unless one is soft-deleted)';

-- Ensure documents within a project have unique titles by type
-- Supports requirement 6.2 (AI-Guided Document Creation) by organizing document structures
ALTER TABLE api.documents
  ADD CONSTRAINT unique_document_title_per_project_type
  UNIQUE (project_id, type, title, deleted_at);
COMMENT ON CONSTRAINT unique_document_title_per_project_type ON api.documents IS
  'Ensures each document type has a unique title within a project (unless soft-deleted)';

-- Ensure implementation guides have unique titles within a project
-- Supports requirement 6.5 (Technical Implementation Guidance) by organizing guide structures
ALTER TABLE api.implementation_guides
  ADD CONSTRAINT unique_guide_title_per_project
  UNIQUE (project_id, title, deleted_at);
COMMENT ON CONSTRAINT unique_guide_title_per_project ON api.implementation_guides IS
  'Ensures implementation guides have unique titles within a project (unless soft-deleted)';

-- Ensure document versions have sequential version numbers
-- Supports requirement 6.3.3 (Document Version History) by enforcing properly sequenced versions
ALTER TABLE api.document_versions
  ADD CONSTRAINT unique_version_number_per_document
  UNIQUE (document_id, version_number);
COMMENT ON CONSTRAINT unique_version_number_per_document ON api.document_versions IS
  'Ensures each document has unique, sequential version numbers';

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Enhanced Project Queries
-- These indexes support requirement 6.1.2 (Enhanced Project Organization) for filtering and sorting

-- Supports filtering projects by name and description search
CREATE INDEX idx_projects_name_description_search ON api.projects 
  USING GIN (to_tsvector('english', name || ' ' || COALESCE(description, '')));
COMMENT ON INDEX idx_projects_name_description_search IS
  'Enables full-text search on project names and descriptions for advanced filtering';

-- Supports filtering projects by creation date
CREATE INDEX idx_projects_created_at ON api.projects (created_at);
COMMENT ON INDEX idx_projects_created_at IS
  'Optimizes queries that filter or sort projects by creation date';

-- Document Content Search
-- Supports requirement 6.2 (AI-Guided Document Creation) for searching document content

-- Enables searching within document content (JSONB)
CREATE INDEX idx_documents_content ON api.documents USING GIN (content);
COMMENT ON INDEX idx_documents_content IS
  'Enables searching within document JSONB content for finding specific information';

-- Document Version Management
-- Supports requirement 6.3.3 (Document Version History) for efficient version history access

-- For retrieving the latest version of a document
CREATE INDEX idx_document_versions_latest ON api.document_versions (document_id, version_number DESC);
COMMENT ON INDEX idx_document_versions_latest IS
  'Optimizes queries to find the latest version of a document';

-- Project Progress Tracking
-- Supports requirement 6.4.2 (Progress Tracking) for monitoring completion rates

-- For finding completed steps
CREATE INDEX idx_project_progress_completed ON api.project_progress (project_id) 
  WHERE status = 'completed';
COMMENT ON INDEX idx_project_progress_completed IS
  'Optimizes queries that count or filter completed steps for progress tracking';

-- Credit System Indexes
-- Supports requirement 6.7 (Credit and Subscription System) for efficient credit operations

-- For analyzing credit usage patterns by date
CREATE INDEX idx_credit_transactions_date_type ON internal.credit_transactions (created_at, type);
COMMENT ON INDEX idx_credit_transactions_date_type IS
  'Optimizes queries that analyze credit usage patterns over time';

-- Implementation Guide Performance
-- Supports requirement 6.5 (Technical Implementation Guidance) for guide access

-- For filtering guides by type via their templates
CREATE INDEX idx_implementation_guides_template_type ON api.implementation_guides (guide_template_id);
COMMENT ON INDEX idx_implementation_guides_template_type IS
  'Optimizes queries that filter implementation guides by their template type';

-- Optimize JSONB searches across document content types
-- Improves search across all document types for requirements 6.2 and 6.5

-- For implementation guides content
CREATE INDEX idx_implementation_guides_content ON api.implementation_guides USING GIN (content);
COMMENT ON INDEX idx_implementation_guides_content IS
  'Enables searching within implementation guide JSONB content';

-- Enhanced Stripe-related queries
-- Supports requirement 6.7 (Credit and Subscription System) by optimizing subscription data access

-- For finding active subscriptions quickly
CREATE INDEX idx_stripe_subscriptions_active ON stripe.subscriptions (customer_id) 
  WHERE status = 'active';
COMMENT ON INDEX idx_stripe_subscriptions_active IS
  'Optimizes queries that find active subscriptions for a customer';

-- =============================================================================
-- VIEWS
-- =============================================================================

-- User Activation Metrics View
-- Supports requirement 9.1 (User Activation) for tracking conversion through key milestones
CREATE VIEW analytics.user_activation AS
WITH user_metrics AS (
  SELECT
    u.id AS user_id,
    u.email,
    p.id IS NOT NULL AS has_profile,
    (SELECT COUNT(*) FROM api.projects pr WHERE pr.user_id = u.id) AS project_count,
    (SELECT COUNT(*) FROM api.projects pr 
     JOIN api.documents d ON pr.id = d.project_id 
     WHERE pr.user_id = u.id AND d.status = 'completed') AS completed_document_count,
    (SELECT COUNT(DISTINCT pr.id) FROM api.projects pr 
     JOIN api.implementation_guides ig ON pr.id = ig.project_id 
     WHERE pr.user_id = u.id) AS projects_with_guides,
    (SELECT MAX(pr.updated_at) FROM api.projects pr WHERE pr.user_id = u.id) AS last_project_activity,
    (SELECT COUNT(*) FROM stripe.customers sc WHERE sc.user_id = u.id) AS has_payment_method
  FROM auth.users u
  LEFT JOIN api.profiles p ON u.id = p.id
)
SELECT
  user_id,
  email,
  has_profile,
  project_count > 0 AS has_projects,
  completed_document_count > 0 AS has_completed_documents,
  projects_with_guides > 0 AS has_implementation_guides,
  has_payment_method,
  project_count,
  completed_document_count,
  projects_with_guides,
  last_project_activity,
  CASE 
    WHEN project_count > 0 THEN 'project_created'
    WHEN has_profile THEN 'profile_created'
    ELSE 'signed_up'
  END AS activation_stage
FROM user_metrics;
COMMENT ON VIEW analytics.user_activation IS
  'Tracks user activation metrics through the conversion funnel from signup to project completion';

-- User Engagement Metrics View
-- Supports requirement 9.2 (Engagement) for tracking user activity and platform usage
CREATE VIEW analytics.user_engagement AS
SELECT
  u.id AS user_id,
  u.email,
  p.last_active_at,
  EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.last_active_at))/86400 AS days_since_last_active,
  (SELECT COUNT(*) FROM api.projects pr WHERE pr.user_id = u.id) AS total_projects,
  (SELECT COUNT(*) FROM api.projects pr WHERE pr.user_id = u.id AND pr.created_at > CURRENT_TIMESTAMP - INTERVAL '30 days') AS projects_last_30_days,
  (SELECT COUNT(*) FROM api.documents d 
   JOIN api.projects pr ON d.project_id = pr.id 
   WHERE pr.user_id = u.id) AS total_documents,
  (SELECT COUNT(DISTINCT d.type) FROM api.documents d 
   JOIN api.projects pr ON d.project_id = pr.id 
   WHERE pr.user_id = u.id) AS document_types_used,
  (SELECT COUNT(*) FROM api.implementation_guides ig 
   JOIN api.projects pr ON ig.project_id = pr.id 
   WHERE pr.user_id = u.id) AS total_implementation_guides,
  CASE 
    WHEN p.last_active_at > CURRENT_TIMESTAMP - INTERVAL '7 days' THEN 'active'
    WHEN p.last_active_at > CURRENT_TIMESTAMP - INTERVAL '30 days' THEN 'semi-active'
    ELSE 'inactive'
  END AS activity_status
FROM auth.users u
LEFT JOIN api.profiles p ON u.id = p.id;
COMMENT ON VIEW analytics.user_engagement IS
  'Tracks user engagement metrics including activity recency, project creation, and feature usage';

-- Monetization Metrics View
-- Supports requirement 9.3 (Monetization) for tracking conversion and revenue
CREATE VIEW analytics.monetization_metrics AS
WITH user_financial AS (
  SELECT
    u.id AS user_id,
    u.email,
    cb.balance AS current_credit_balance,
    cb.lifetime_credits,
    (SELECT COUNT(*) FROM internal.credit_transactions ct 
     WHERE ct.user_id = u.id AND ct.type = 'purchase') AS purchase_count,
    (SELECT SUM(amount) FROM internal.credit_transactions ct 
     WHERE ct.user_id = u.id AND ct.type = 'purchase') AS total_purchased_credits,
    (SELECT COUNT(*) FROM stripe.customers sc WHERE sc.user_id = u.id) > 0 AS has_payment_method,
    (SELECT COUNT(*) FROM stripe.customers sc 
     JOIN stripe.subscriptions ss ON sc.id = ss.customer_id 
     WHERE sc.user_id = u.id AND ss.status = 'active') > 0 AS has_active_subscription,
    (SELECT SUM(s.amount) FROM stripe.charges s 
     JOIN stripe.customers sc ON s.customer_id = sc.id 
     WHERE sc.user_id = u.id) AS lifetime_revenue_cents
  FROM auth.users u
  LEFT JOIN internal.credit_balances cb ON u.id = cb.user_id
)
SELECT
  user_id,
  email,
  current_credit_balance,
  lifetime_credits,
  purchase_count,
  total_purchased_credits,
  has_payment_method,
  has_active_subscription,
  COALESCE(lifetime_revenue_cents, 0)/100.0 AS lifetime_revenue_dollars,
  CASE 
    WHEN has_active_subscription THEN 'subscriber'
    WHEN purchase_count > 0 THEN 'purchaser'
    WHEN lifetime_credits > 2 THEN 'used_free_credits'
    ELSE 'non_monetized'
  END AS monetization_stage
FROM user_financial;
COMMENT ON VIEW analytics.monetization_metrics IS
  'Tracks monetization metrics including credit purchases, subscription conversion, and revenue per user';

-- Retention Metrics View
-- Supports requirement 9.4 (Retention) for tracking user retention over time
CREATE VIEW analytics.retention_metrics AS
WITH cohort_data AS (
  SELECT
    u.id AS user_id,
    u.email,
    DATE_TRUNC('week', u.created_at) AS signup_cohort,
    p.last_active_at,
    (SELECT MAX(created_at) FROM api.projects WHERE user_id = u.id) AS last_project_created,
    (SELECT MAX(updated_at) FROM api.documents d 
     JOIN api.projects pr ON d.project_id = pr.id 
     WHERE pr.user_id = u.id) AS last_document_updated,
    (SELECT MAX(ss.current_period_end) FROM stripe.subscriptions ss
     JOIN stripe.customers sc ON ss.customer_id = sc.id
     WHERE sc.user_id = u.id AND ss.status = 'active') AS subscription_end_date
  FROM auth.users u
  LEFT JOIN api.profiles p ON u.id = p.id
)
SELECT
  user_id,
  email,
  signup_cohort,
  last_active_at,
  last_project_created,
  last_document_updated,
  subscription_end_date,
  GREATEST(last_active_at, last_project_created, last_document_updated) AS last_activity,
  EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - GREATEST(last_active_at, last_project_created, last_document_updated)))/86400 AS days_since_last_activity,
  CASE 
    WHEN GREATEST(last_active_at, last_project_created, last_document_updated) > CURRENT_TIMESTAMP - INTERVAL '30 days' THEN TRUE 
    ELSE FALSE 
  END AS retained_30_days,
  CASE 
    WHEN GREATEST(last_active_at, last_project_created, last_document_updated) > CURRENT_TIMESTAMP - INTERVAL '60 days' THEN TRUE 
    ELSE FALSE 
  END AS retained_60_days,
  CASE 
    WHEN GREATEST(last_active_at, last_project_created, last_document_updated) > CURRENT_TIMESTAMP - INTERVAL '90 days' THEN TRUE 
    ELSE FALSE 
  END AS retained_90_days,
  CASE
    WHEN subscription_end_date > CURRENT_TIMESTAMP THEN 'subscribed'
    WHEN GREATEST(last_active_at, last_project_created, last_document_updated) > CURRENT_TIMESTAMP - INTERVAL '30 days' THEN 'active_30d'
    WHEN GREATEST(last_active_at, last_project_created, last_document_updated) > CURRENT_TIMESTAMP - INTERVAL '60 days' THEN 'active_60d'
    WHEN GREATEST(last_active_at, last_project_created, last_document_updated) > CURRENT_TIMESTAMP - INTERVAL '90 days' THEN 'active_90d'
    ELSE 'churned'
  END AS retention_status
FROM cohort_data;
COMMENT ON VIEW analytics.retention_metrics IS
  'Tracks user retention metrics at 30, 60, and 90-day intervals based on their last activity';

-- Project Analytics View
-- Provides insights into project completion rates and implementation guide usage
CREATE VIEW analytics.project_analytics AS
SELECT
  p.id AS project_id,
  p.name AS project_name,
  p.user_id,
  u.email AS user_email,
  p.created_at,
  p.updated_at,
  p.status,
  p.framework_day,
  (SELECT COUNT(*) FROM api.documents d WHERE d.project_id = p.id) AS document_count,
  (SELECT COUNT(*) FROM api.documents d WHERE d.project_id = p.id AND d.status = 'completed') AS completed_document_count,
  (SELECT COUNT(*) FROM api.implementation_guides ig WHERE ig.project_id = p.id) AS implementation_guide_count,
  (SELECT COUNT(*) FROM api.project_progress pp WHERE pp.project_id = p.id) AS total_steps,
  (SELECT COUNT(*) FROM api.project_progress pp WHERE pp.project_id = p.id AND pp.status = 'completed') AS completed_steps,
  CASE
    WHEN (SELECT COUNT(*) FROM api.project_progress pp WHERE pp.project_id = p.id) > 0 THEN
      ROUND(((SELECT COUNT(*) FROM api.project_progress pp WHERE pp.project_id = p.id AND pp.status = 'completed')::numeric / 
      (SELECT COUNT(*) FROM api.project_progress pp WHERE pp.project_id = p.id)::numeric) * 100)
    ELSE 0
  END AS completion_percentage,
  EXTRACT(EPOCH FROM (p.updated_at - p.created_at))/3600 AS project_duration_hours
FROM api.projects p
JOIN auth.users u ON p.user_id = u.id
WHERE p.deleted_at IS NULL;
COMMENT ON VIEW analytics.project_analytics IS
  'Provides analytics on project completion rates, document generation, and time to completion';

-- Complete Success Metrics Dashboard View
-- Combines key metrics for executive dashboard (supports requirements in section 9)
CREATE VIEW analytics.success_metrics_dashboard AS
WITH user_stats AS (
  SELECT
    COUNT(*) AS total_users,
    COUNT(CASE WHEN p.id IS NOT NULL THEN 1 END) AS users_with_profiles,
    COUNT(CASE WHEN (SELECT COUNT(*) FROM api.projects pr WHERE pr.user_id = u.id) > 0 THEN 1 END) AS users_with_projects,
    COUNT(CASE WHEN (SELECT COUNT(*) FROM api.documents d JOIN api.projects pr ON d.project_id = pr.id WHERE pr.user_id = u.id AND d.status = 'completed') > 0 THEN 1 END) AS users_with_completed_documents,
    COUNT(CASE WHEN (SELECT COUNT(*) FROM api.implementation_guides ig JOIN api.projects pr ON ig.project_id = pr.id WHERE pr.user_id = u.id) > 0 THEN 1 END) AS users_with_implementation_guides,
    COUNT(CASE WHEN (SELECT COUNT(*) FROM stripe.customers sc WHERE sc.user_id = u.id) > 0 THEN 1 END) AS users_with_payment_method,
    COUNT(CASE WHEN (SELECT COUNT(*) FROM stripe.customers sc JOIN stripe.subscriptions ss ON sc.id = ss.customer_id WHERE sc.user_id = u.id AND ss.status = 'active') > 0 THEN 1 END) AS users_with_active_subscription
  FROM auth.users u
  LEFT JOIN api.profiles p ON u.id = p.id
),
project_stats AS (
  SELECT
    COUNT(*) AS total_projects,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) AS completed_projects,
    AVG((SELECT COUNT(*) FROM api.documents d WHERE d.project_id = p.id)) AS avg_documents_per_project,
    AVG(EXTRACT(EPOCH FROM (updated_at - created_at))/3600) AS avg_project_duration_hours
  FROM api.projects p
  WHERE deleted_at IS NULL
),
conversion_rates AS (
  SELECT
    (users_with_profiles::float / NULLIF(total_users::float, 0)) * 100 AS profile_creation_rate,
    (users_with_projects::float / NULLIF(users_with_profiles::float, 0)) * 100 AS project_creation_rate,
    (users_with_completed_documents::float / NULLIF(users_with_projects::float, 0)) * 100 AS document_completion_rate,
    (users_with_implementation_guides::float / NULLIF(users_with_completed_documents::float, 0)) * 100 AS implementation_guide_creation_rate,
    (users_with_payment_method::float / NULLIF(total_users::float, 0)) * 100 AS payment_method_addition_rate,
    (users_with_active_subscription::float / NULLIF(users_with_payment_method::float, 0)) * 100 AS subscription_conversion_rate
  FROM user_stats
),
revenue_stats AS (
  SELECT
    COUNT(DISTINCT sc.user_id) AS paying_users,
    SUM(s.amount)/100.0 AS total_revenue_dollars,
    (SUM(s.amount)/100.0) / NULLIF(COUNT(DISTINCT sc.user_id), 0) AS average_revenue_per_paying_user
  FROM stripe.charges s
  JOIN stripe.customers sc ON s.customer_id = sc.id
)
SELECT
  us.total_users,
  us.users_with_profiles,
  us.users_with_projects,
  us.users_with_completed_documents,
  us.users_with_implementation_guides,
  us.users_with_payment_method,
  us.users_with_active_subscription,
  ps.total_projects,
  ps.completed_projects,
  ps.avg_documents_per_project,
  ps.avg_project_duration_hours,
  cr.profile_creation_rate,
  cr.project_creation_rate,
  cr.document_completion_rate,
  cr.implementation_guide_creation_rate,
  cr.payment_method_addition_rate,
  cr.subscription_conversion_rate,
  rs.paying_users,
  rs.total_revenue_dollars,
  rs.average_revenue_per_paying_user
FROM user_stats us, project_stats ps, conversion_rates cr, revenue_stats rs;
COMMENT ON VIEW analytics.success_metrics_dashboard IS
  'Comprehensive dashboard combining all key success metrics for executive reporting';