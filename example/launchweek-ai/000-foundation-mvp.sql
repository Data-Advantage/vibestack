-- 000-foundation.sql
-- LaunchWeek.ai Foundation Migration

-- This migration establishes the core structure of the LaunchWeek.ai database:
-- - Enables required PostgreSQL extensions
-- - Creates custom schemas for organizing database objects
-- - Defines custom types and enumerations needed by the application
-- - Creates domain types for data validation

------------------------------------------------------------------------------
-- PART 1: EXTENSIONS
------------------------------------------------------------------------------
-- Enable PostgreSQL extensions required for our application
-- These are already available in Supabase but explicitly enable them for clarity

-- Core crypto functionality for UUID generation, hashing, and encryption
-- Used for generating UUIDs as primary keys throughout the application
CREATE EXTENSION IF NOT EXISTS pgcrypto SCHEMA extensions;

-- Additional UUID generation functions (if needed beyond pgcrypto)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA extensions;

-- JSON Web Token support for authentication workflows
CREATE EXTENSION IF NOT EXISTS pgjwt SCHEMA extensions;

-- Query performance tracking
CREATE EXTENSION IF NOT EXISTS pg_stat_statements SCHEMA extensions;

-- Automatic timestamp updates for modified records
-- Required for all tables with updated_at columns
CREATE EXTENSION IF NOT EXISTS moddatetime SCHEMA extensions;

------------------------------------------------------------------------------
-- PART 2: SCHEMAS
------------------------------------------------------------------------------
-- Create custom schemas to organize database objects

-- User-generated content and application data
-- Stores projects, documents, conversations, and user-specific data
CREATE SCHEMA IF NOT EXISTS api;
COMMENT ON SCHEMA api IS 'User-generated content and application data, including user-specific instances of templates';

-- Sensitive internal operations not directly accessible to users
-- Contains data that requires elevated permissions and system-managed records
CREATE SCHEMA IF NOT EXISTS internal;
COMMENT ON SCHEMA internal IS 'Sensitive internal operations not directly accessible to users, financial data, and system-generated records requiring special access controls';

-- Publicly available lookup tables and reusable templates
-- Contains static reference data and templates for features
CREATE SCHEMA IF NOT EXISTS reference;
COMMENT ON SCHEMA reference IS 'Publicly available lookup tables and reusable templates for features that have both templates and user customizations';

-- Application configuration data
-- Stores system settings and subscription tier information
CREATE SCHEMA IF NOT EXISTS config;
COMMENT ON SCHEMA config IS 'Application configuration data including feature flags and subscription settings';

-- Synced data from Stripe webhooks
-- Stores payment and subscription information from Stripe
CREATE SCHEMA IF NOT EXISTS stripe;
COMMENT ON SCHEMA stripe IS 'Synced data from Stripe webhooks for payment processing and subscription management';

-- Reporting data (primarily views)
-- Contains analytics views derived from the application data
CREATE SCHEMA IF NOT EXISTS analytics;
COMMENT ON SCHEMA analytics IS 'Reporting data, primarily views for analytics and business intelligence';

------------------------------------------------------------------------------
-- PART 3: TYPES AND DOMAINS
------------------------------------------------------------------------------
-- Define custom types for consistent data representation

-- Task status enum for tracking status of tasks, steps, and AI generation
CREATE TYPE reference.task_status AS ENUM (
  'pending',
  'in_progress',
  'completed',
  'failed',
  'cancelled'
);
COMMENT ON TYPE reference.task_status IS 'Status values for tasks, steps, and AI generation processes';

-- Project status enum for tracking overall project lifecycle
CREATE TYPE reference.project_status AS ENUM (
  'draft',
  'in_progress',
  'launched',
  'archived'
);
COMMENT ON TYPE reference.project_status IS 'Status values for project lifecycle tracking';

-- Framework day enum for organizing the 5-day framework structure
CREATE TYPE reference.framework_day AS ENUM (
  'day_1',
  'day_2',
  'day_3',
  'day_4',
  'day_5'
);
COMMENT ON TYPE reference.framework_day IS 'Values representing days in the 5-day framework process';

-- Document type enum for categorizing different documents in the workflow
CREATE TYPE reference.document_type AS ENUM (
  'product_requirements',
  'marketing_story',
  'landing_page',
  'database_migration',
  'implementation_plan'
);
COMMENT ON TYPE reference.document_type IS 'Types of documents generated in the workflow process';

-- Step type enum for categorizing different types of activities within the framework
CREATE TYPE reference.step_type AS ENUM (
  'planning',
  'content_creation',
  'implementation',
  'deployment',
  'feedback',
  'refinement'
);
COMMENT ON TYPE reference.step_type IS 'Types of steps in the framework process';

-- Priority level enum for implementation tasks
CREATE TYPE reference.priority_level AS ENUM (
  'high',
  'medium',
  'low'
);
COMMENT ON TYPE reference.priority_level IS 'Priority levels for implementation tasks';

-- Message role enum for AI conversation participants
CREATE TYPE reference.message_role AS ENUM (
  'user',
  'assistant',
  'system'
);
COMMENT ON TYPE reference.message_role IS 'Roles in AI conversation messages';

-- Domain types for common data patterns with validation

-- Email address domain with validation
CREATE DOMAIN reference.email AS TEXT
CHECK (VALUE ~ '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$');
COMMENT ON DOMAIN reference.email IS 'Email address with format validation';

-- URL domain with validation
CREATE DOMAIN reference.url AS TEXT
CHECK (VALUE ~ '^https?://');
COMMENT ON DOMAIN reference.url IS 'URL with format validation (must start with http:// or https://)';

-- Non-empty text domain
CREATE DOMAIN reference.non_empty_text AS TEXT
CHECK (VALUE IS NOT NULL AND LENGTH(TRIM(VALUE)) > 0);
COMMENT ON DOMAIN reference.non_empty_text IS 'Text that cannot be empty or only whitespace';