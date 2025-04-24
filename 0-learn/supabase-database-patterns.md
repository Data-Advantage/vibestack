# Database Patterns

This document outlines the recommended database patterns and best practices for implementing Supabase in your Next.js application.

## Schema Organization

### Reserved Schemas
Respect Supabase's built-in schemas which have special purposes:
- `auth` - Authentication and user management
- `storage` - File storage and management
- `graphql` - GraphQL API
- `realtime` - Realtime subscriptions
- `supabase_functions` - Edge functions

These schemas are managed by Supabase and should not be modified directly.

### Custom Schema Structure
Avoid using the `public` schema for user data. Instead, create purpose-specific schemas:

- `api` - User-generated content and application data
- `config` - Application configuration data
- `reference` - Publicly available lookup tables
- `analytics` - Reporting data - (try to use only views)
- `audit` - Tracking changes - (use only if needed in requirements)
- `stripe` - Synced data from Stripe webhooks

This separation provides clearer organization, better security isolation, and more maintainable code.

### Enum Placement
PostgreSQL enums should usually be placed in the `reference` schema. Since enums represent fixed sets of values that are referenced across multiple tables, they align with the purpose of the reference schema as a container for lookup data.

Example:
```sql
-- Create enum in reference schema
CREATE TYPE reference.status AS ENUM ('pending', 'active', 'completed', 'cancelled');

-- Use enum in table definition
CREATE TABLE api.tasks (
  id uuid primary key default gen_random_uuid(),
  status reference.status NOT NULL DEFAULT 'pending',
  -- other columns
);
```

This approach keeps all reference data organized in a single schema and makes it clear that these values are shared across the application.

## Table Structure Best Practices

### User Profiles
- Store extended user data in `api.profiles`, not directly in `auth.users`
- Link profiles to auth users with a foreign key reference
- Apply Row Level Security (RLS) policies for user data protection

Example structure:
```sql
create table api.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

### User-Generated Content
- Store in the `api` schema (e.g., `api.posts`, `api.comments`)
- Always include a `user_id` column to track ownership
- Apply appropriate RLS policies based on ownership and visibility rules
- Consider adding `created_at` and `updated_at` timestamps for audit purposes

### Common Table Patterns
- Use UUIDs as primary keys for better distribution and security
- Include `created_at` and `updated_at` timestamps on all tables
- Use foreign key constraints to maintain referential integrity
- Consider soft deletes with a `deleted_at` timestamp instead of hard deletes
- Use enums for status fields and other fixed-value columns

## Simplified Constraints in Initial Migrations

When creating your initial database schema, focus on essential constraints and defer complex ones:

### Start With Essential Constraints Only

- **Primary Keys**: Always include these from the beginning
- **Foreign Keys**: Include these for basic referential integrity
- **NOT NULL**: Apply to columns that must have values
- **Simple CHECK constraints**: Use for basic data validation (e.g., `CHECK (amount >= 0)`)

### Defer Complex Constraints

Defer these types of constraints until their need is validated through actual usage:

```sql
-- Too complex for initial migration - defer this
CONSTRAINT valid_deleted_status CHECK (
  (deleted_at IS NULL) OR 
  (deleted_at IS NOT NULL AND status = 'archived')
)

-- Non-critical constraint - implement later if needed
CONSTRAINT unique_document_type_per_project UNIQUE (project_id, type)
```

### Minimize Metadata JSONB Fields

Avoid adding metadata JSONB fields to every table in your initial migration:

```sql
-- Don't add this to every table by default
metadata JSONB DEFAULT '{}',
```

Instead:
- Add metadata fields only to tables where you know they'll be needed
- Consider explicit columns for known attributes instead of generic metadata
- Add metadata columns later when their specific use case is identified

### Simplified Versioning Patterns

When implementing document versioning, start with the simplest approach that meets your immediate needs:

#### Start Simple

Instead of creating complex versioning systems with:
- Multiple interconnected tables
- Circular foreign key references
- Custom version management functions
- Multiple triggers

Simply add a version counter to your main table:
```sql
CREATE TABLE api.documents (
  /* other fields */
  content TEXT,
  version INTEGER NOT NULL DEFAULT 1,
  /* other fields */
);
```

#### Add History Only If Needed

If history tracking is required, consider:
1. Using a simple history table that stores just what changed
2. Adding this table later when the need is confirmed
3. Using a basic trigger to update the version number and store history

Here's a simple approach that avoids complexity while still tracking changes:

```sql
-- Main document table with version counter
CREATE TABLE api.documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content TEXT,
  version INTEGER NOT NULL DEFAULT 1,
  updated_by UUID REFERENCES auth.users(id),
  -- other fields
);

-- Simple history table - only created when needed
CREATE TABLE api.document_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID REFERENCES api.documents(id) ON DELETE CASCADE,
  content TEXT NOT NULL, -- Previous content snapshot
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  changed_by UUID REFERENCES auth.users(id),
  from_version INTEGER NOT NULL,
  to_version INTEGER NOT NULL
);

-- Simple trigger to track changes
CREATE FUNCTION api.track_document_changes()
RETURNS TRIGGER AS $$
BEGIN
  -- Only track if content changed
  IF OLD.content IS DISTINCT FROM NEW.content THEN
    -- Increment version counter
    NEW.version = OLD.version + 1;
    
    -- Record history
    INSERT INTO api.document_history (
      document_id, content, changed_at, changed_by, 
      from_version, to_version
    ) VALUES (
      OLD.id, OLD.content, NOW(), NEW.updated_by,
      OLD.version, NEW.version
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to documents table
CREATE TRIGGER track_document_changes
BEFORE UPDATE ON api.documents
FOR EACH ROW EXECUTE FUNCTION api.track_document_changes();
```

This approach captures previous versions without circular references or complex joins.

#### When to Use Complex Versioning

Only implement complex versioning systems with separate version tables when you have specific requirements for:
- Branching versions (non-linear history)
- Comparing arbitrary versions
- Extensive metadata for each version
- Version-specific permissions

For most applications, simple versioning is sufficient for initial development.

## UUID Generation Options

When creating UUIDs as primary keys in Supabase, use `pgcrypto` with the `gen_random_uuid()` function unless there is the need for the more advanced features of `uuid-ossp`.

## Best Practices for Trigger Functions

### 1. Use Proper Schema Qualification

Always place utility functions in the `public` schema and fully qualify their names when referenced:

```sql
-- Create function in public schema
CREATE FUNCTION public.update_timestamp() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Reference with full schema qualification
CREATE TRIGGER set_updated_at BEFORE UPDATE ON api.my_table 
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
```

### 2. Avoid Dynamic SQL for Trigger Creation

Use explicit trigger creation statements instead of DO blocks or dynamic SQL:

```sql
-- Create triggers with explicit statements for better reliability
CREATE TRIGGER set_updated_at BEFORE UPDATE ON api.profiles 
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
```

### 3. Follow Proper Function Order

1. Create utility functions first (at the beginning of your migration)
2. Create tables next
3. Create triggers referencing the functions
4. Apply other constraints and policies

### 4. Test Before Deployment

Before deploying, verify that trigger functions work properly by:
- Checking function visibility in the correct schema
- Testing trigger creation on a sample table
- Verifying the trigger behavior with simple CRUD operations

### 5. Common Issues to Avoid

- **Missing schema qualification**: Always use `public.function_name()` not just `function_name()`
- **Creation order problems**: Create functions before they're referenced by triggers
- **Search path confusion**: Don't rely on search_path for function resolution in triggers
- **Dynamic SQL failures**: Be careful with DO blocks that create triggers

## Row Level Security (RLS)

### General RLS Best Practices
- Enable RLS on all tables storing user data
- Create specific policies for each operation type (SELECT, INSERT, UPDATE, DELETE)
- Use `auth.uid()` function to identify the authenticated user
- Start with restrictive policies, then add permissions as needed

### RLS Implementation Sequence

When implementing Row Level Security, be aware of this critical sequence:

1. **Plan your policies first:** Document who needs what access to which tables
2. **Create policies before or immediately after enabling RLS:** Tables with RLS enabled but no policies will block all access by default
3. **Test each policy:** Verify that legitimate access works and unauthorized access is blocked

#### Common Warning: RLS Enabled Without Policies

If you see the linter warning "RLS Enabled No Policy," it means:
- The table has Row Level Security turned on
- No access policies have been defined
- Regular users cannot access any data in this table
- You need to create appropriate policies based on your application's needs

This is a common issue during development that should be resolved before deployment.

### Common Policy Patterns

#### Ownership-based Access
Users can only access their own data:

```sql
create policy "Users can view their own profiles"
  on api.profiles for select
  using (auth.uid() = id);

create policy "Users can update their own profiles"
  on api.profiles for update
  using (auth.uid() = id);
```

#### Role-based Access
Permissions based on user roles:

```sql
create policy "Admins can view all profiles"
  on api.profiles for select
  using (auth.jwt() ->> 'role' = 'admin');
```

#### Relationship-based Access
Access based on team membership or other relationships:

```sql
create policy "Team members can view team data"
  on api.team_data for select
  using (
    auth.uid() in (
      select user_id from api.team_members 
      where team_id = api.team_data.team_id
    )
  );
```

### RLS Optimization Patterns

As applications grow, Row Level Security policies can become complex and impact performance. Follow these simplified patterns:

#### 1. Use Functions for Common Policy Patterns

For repeated policy logic (especially admin access), use a shared function:

```sql
-- Create once, use everywhere
CREATE FUNCTION public.is_admin() RETURNS BOOLEAN AS $$
  SELECT auth.jwt() ->> 'role' = 'admin';
$$ LANGUAGE sql SECURITY DEFINER;

-- Then in policies
CREATE POLICY "Admin access" ON api.table USING (public.is_admin());
```

#### 2. Simplify Relationship Checks

For complex ownership hierarchies (e.g., users → projects → documents):
- Create views that join related tables instead of using nested EXISTS subqueries
- Apply simpler policies to these views
- Consider adding ownership fields (e.g., adding user_id to documents) for direct checks

#### 3. Index Policy Columns

Always add indexes on columns used in RLS policies:
```sql
CREATE INDEX ON api.table(user_id);
```

#### 4. Avoid Redundant Conditions

When USING and WITH CHECK conditions are identical, use WITH CHECK only:
```sql
CREATE POLICY "Users edit own data" ON api.table FOR UPDATE WITH CHECK (auth.uid() = user_id);
```

## Database Function Security

### Function Search Path

PostgreSQL functions can be vulnerable to "search path injection" attacks if not properly secured. Always set an explicit search path for your functions:

```sql
CREATE OR REPLACE FUNCTION api.my_function()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = api, pg_temp
AS $$
BEGIN
  -- function body
END;
$$;
```

### Key Best Practices:

- Always set explicit search paths for all functions to prevent search path injection attacks
- Include only necessary schemas in the search path (principle of least privilege)
- Always include pg_temp at the end of the search path for temporary object access
- Choose security context carefully:
  - Use `SECURITY DEFINER` when the function needs elevated permissions
  - Use `SECURITY INVOKER` (default) when the function should run with caller's permissions
- Be extra cautious with trigger functions that modify data across schemas

### Security Implications:

Without an explicit search path, functions inherit the calling user's search path, which can lead to:
- Execution of unintended code
- Privilege escalation
- Data exposure through malicious search path manipulation

This best practice is flagged by the Supabase Security Advisor and should be addressed for all database functions.

## Trigger Function Best Practices

### Handling the NEW Record in Trigger Functions

PostgreSQL trigger functions often need to access the `NEW` record (the row being inserted or updated). 
When using `NEW` in SQL contexts within PL/pgSQL functions, you may encounter the error 
"missing FROM-clause entry for table 'new'".

#### Best Practice: Use Local Variables

Always assign the `NEW` record to a local variable at the beginning of your trigger function, 
then reference this variable instead of directly using `NEW` in SQL operations:

```sql
CREATE OR REPLACE FUNCTION my_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
  record_data RECORD;  -- Local variable to store NEW
BEGIN
  -- Assign NEW to local variable
  record_data := NEW;
  
  -- Use record_data instead of NEW in SQL contexts
  INSERT INTO api.audit_log(
    entity_id, 
    changed_by
  ) VALUES (
    record_data.id,
    auth.uid()
  );
  
  -- Return the record_data (or NEW if no modifications needed)
  RETURN record_data;
END;
$$ LANGUAGE plpgsql;
```

This approach ensures:
- SQL operations can properly reference the fields of the record
- Prevents the common "missing FROM-clause entry for table 'new'" error
- Works even when the trigger function is defined before the table it operates on
- Maintains consistent behavior across different PostgreSQL versions

### Additional Trigger Function Considerations

- Use `DECLARE` section to create any needed local variables
- Include descriptive comments about the trigger's purpose
- Return the modified record (`RETURN record_data`) when using `BEFORE` triggers
- Return `NULL` when using `AFTER` triggers that don't need to modify the record
- Always handle potential exceptions with appropriate error messages

## Storage Implementation

### Storage Buckets
Create separate buckets based on access patterns:
- `public` - Openly accessible files
- `protected` - Authenticated-only access
- `private` - User-specific private files

### Storage RLS
Apply RLS policies to storage buckets to control file access:
- Control file uploads based on user identity and file location
- Set up policies for viewing, uploading, and deleting files

Example storage policy:
```sql
-- Allow users to upload their own profile images
create policy "Users can upload their own avatar"
  on storage.objects for insert
  with check (
    auth.uid() = (storage.foldername())[1]::uuid
    and storage.filename() ~ '^avatar\.(jpg|jpeg|png)$'
  );
```

### Preventing Ambiguous Column References in Storage Policies

When writing storage policies that involve JOINs with other tables, always fully qualify column names that exist in multiple tables, especially the `name` column in `storage.objects`.

#### Quick Reference

- Storage functions require table qualification: use `storage.objects.name` not just `name`
- This is particularly important in EXISTS subqueries that join `storage.objects` with your application tables
- Common error message to watch for: "column reference is ambiguous"
- Most frequently affected functions: `storage.foldername()` and `storage.filename()`

Remember: When in doubt, fully qualify all column references in complex queries to avoid ambiguity.

## Data Access from Next.js

### Server Components
- Create a fresh Supabase client per request using `createClient()` from your server utilities
- Access data directly in Server Components with RLS automatically applied based on the user's session
- Use proper error handling and type checking for database operations

### Client Components
- Use custom hooks or React Query for data fetching in Client Components
- Implement optimistic updates for better user experience
- Create domain-specific hooks that encapsulate Supabase queries
- Handle loading, error, and success states appropriately

### Realtime Subscriptions
- Use Supabase's realtime capabilities for live updates
- Implement channel-based subscriptions for specific tables or rows
- Properly clean up subscriptions when components unmount

## Database Type Safety

- Generate TypeScript types from your database schema using Supabase CLI
- Create a central export for your database types
- Extend database types with domain-specific interfaces when needed
- Use strongly typed Supabase queries with proper return type annotations

## Performance Considerations

- Focus on primary key and foreign key indexes
- Only add other appropriate indexes later when we identify performance bottlenecks
- Use pagination for large datasets
- Implement query optimization for complex joins
- Consider materialized views for complex analytical queries
- Use appropriate foreign key constraints and cascading operations

Remember that proper database design is crucial for application scalability and security. Always consider the implications of your schema design on performance, security, and maintainability.

## Avoiding Premature Optimization

Follow the principle of "optimize later" when building your database:

### Anti-Patterns to Avoid

#### 1. Cache Warming Functions
Do not implement cache warming functions (like `warm_database_caches()`) in initial database setup. These are premature optimizations that:
- Add unnecessary complexity 
- Often provide limited benefits
- Are difficult to test effectively
- May interfere with PostgreSQL's built-in query planner and caching mechanisms

PostgreSQL has sophisticated caching mechanisms that adapt to actual usage patterns. Let the database engine handle caching automatically until you have concrete evidence that manual intervention is required.

#### 2. Over-Indexing
Resist the urge to add indexes to every column "just in case." Each index:
- Slows down write operations
- Increases storage requirements
- Complicates the query planner's job

#### 3. Complex Stored Procedures for Simple Logic
Keep application logic in your application code when possible. Only move logic to database functions when there's a clear performance or security benefit.

#### 4. Materialized Views in Initial Setup
Avoid creating materialized views and their refresh functions in your initial schema:

```sql
-- Avoid this in initial setup
CREATE MATERIALIZED VIEW analytics.credit_usage_summary AS
SELECT user_id, DATE_TRUNC('day', created_at) AS usage_date, SUM(amount) as total
FROM api.credit_transactions
GROUP BY user_id, DATE_TRUNC('day', created_at)
WITH NO DATA;

-- Also avoid the accompanying refresh function
CREATE FUNCTION analytics.refresh_all_materialized_views()...
```

Instead:
- Start with regular views that don't require refresh management
- Only convert to materialized views when you have evidence of performance issues
- Add refresh infrastructure only when the performance benefit is measurable and necessary

Materialized views introduce additional complexity with caching invalidation, refresh timing, and transaction management that aren't justified without proven performance needs.

### When to Optimize

1. **Measure first**: Use query analysis tools to identify actual bottlenecks
2. **Start simple**: Basic optimizations (proper indexing, query restructuring) often yield the biggest gains
3. **Document why**: When implementing optimizations, document the specific performance issue being addressed
4. **Test thoroughly**: Verify that optimizations improve performance under realistic conditions

By avoiding premature optimization, you keep your database schema cleaner, more maintainable, and paradoxically, often faster than an over-engineered solution.

## Simplified Analytics Approach

When creating analytics capabilities for your application, start with minimal infrastructure:

### Use Views Instead of Complex Infrastructure

For a new application, avoid creating complex analytics infrastructure with dedicated tables, functions, and ETL processes. Instead:

1. **Create Simple Views Only**: 
   - Place read-only analytical views in the `analytics` schema
   - Base these views directly on your application tables in the `api` schema
   - Start with aggregate counts and basic metrics only

```sql
-- Example of a simple analytics view
CREATE VIEW analytics.daily_user_signups AS
SELECT 
  DATE_TRUNC('day', created_at) AS signup_date,
  COUNT(*) AS signup_count
FROM auth.users
GROUP BY DATE_TRUNC('day', created_at)
ORDER BY signup_date DESC;
```

2. **Avoid These Until Needed**:
   - Dedicated analytics tables
   - Complex ETL processes
   - Scheduled data transformations
   - Custom aggregation functions
   - Materialized views (unless performance issues arise)

### Incremental Approach to Analytics

As your application and data needs grow:

1. First, expand your analytics views to answer specific business questions
2. Only when views become too slow, consider materialized views
3. If materialized views need frequent refreshing, then consider dedicated analytics tables

This measured approach prevents overbuilding analytics infrastructure before you understand your actual reporting needs.

## Standard Utility Functions

Common utility functions simplify database operations and ensure consistent behavior. These should be placed in the `public` schema for organization and accessibility.

### Timestamp Management Best Practices

#### Standardizing Timestamp Functions

A common issue in database schemas is the creation of multiple redundant timestamp management functions (e.g., `update_updated_at()`, `set_timestamps()`, `trigger_updated_at()`). To prevent this:

**1. Standardize on a single timestamp function implementation:**

```sql
-- Single standard timestamp function for the entire project
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
```

**2. Use consistent trigger naming:**

```sql
-- Use this exact pattern for all tables
CREATE TRIGGER handle_timestamps
BEFORE INSERT OR UPDATE ON api.table_name
FOR EACH ROW EXECUTE FUNCTION public.handle_timestamps();
```

**3. Add this function ONCE at the beginning of your migrations:**
The timestamp function should be defined once at the start of your migrations and reused across all tables.

**4. Never create alternative timestamp functions:**
If you find yourself writing a new function that updates timestamps, stop and use the standard one instead.

### User Management Examples

```sql
-- Create profile automatically when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public, pg_temp
AS $$
BEGIN
  INSERT INTO api.profiles (id, display_name)
  VALUES (new.id, new.email);
  
  RETURN new;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### Business Logic Function Examples

If these functions are needed, they should be placed in the relevant schema (e.g., `api`) when they operate on domain-specific data:

```sql
-- Function to check and deduct credits
CREATE OR REPLACE FUNCTION api.check_and_deduct_credits(
  user_uuid UUID,
  required_credits INTEGER
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = api, public, pg_temp
AS $$
DECLARE
  current_balance INTEGER;
BEGIN
  -- Get current balance
  SELECT credit_balance INTO current_balance
  FROM api.profiles
  WHERE id = user_uuid;
  
  -- Check if enough credits
  IF current_balance >= required_credits THEN
    -- Deduct credits
    UPDATE api.profiles
    SET credit_balance = credit_balance - required_credits
    WHERE id = user_uuid;
    
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$;
```

Remember to always:
- Set the appropriate security context (`SECURITY DEFINER` when elevated privileges are needed)
- Explicitly define the search path to prevent search path injection
- Include proper error handling for robust function behavior
- Document the purpose and usage of each function

## Standard Stripe Tables

When integrating Stripe payments with your application, a consistent table structure helps maintain webhook data and synchronize payment state. These tables should be placed in the `stripe` schema as mentioned in the schema organization section.

### Core Stripe Tables

A complete Stripe integration requires syncing data from webhooks into several related tables. Here's a comprehensive set of tables for managing Stripe data:

1. **stripe.customers** - Links Stripe customers to application users
   ```sql
   CREATE TABLE stripe.customers (
     id TEXT PRIMARY KEY, -- Stripe customer ID (e.g., cus_...)
     user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
     email TEXT NOT NULL,
     name TEXT,
     metadata JSONB,
     created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
     updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
   );
   ```

2. **stripe.products** - Stores Stripe products
   ```sql
   CREATE TABLE stripe.products (
     id TEXT PRIMARY KEY, -- Stripe product ID (e.g., prod_...)
     name TEXT NOT NULL,
     description TEXT,
     active BOOLEAN NOT NULL DEFAULT TRUE,
     metadata JSONB,
     created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
     updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
   );
   ```

3. **stripe.prices** - Stores Stripe prices for products
   ```sql
   CREATE TABLE stripe.prices (
     id TEXT PRIMARY KEY, -- Stripe price ID (e.g., price_...)
     product_id TEXT REFERENCES stripe.products(id),
     active BOOLEAN NOT NULL DEFAULT TRUE,
     currency TEXT NOT NULL,
     unit_amount INTEGER NOT NULL, -- Amount in cents/smallest currency unit
     type TEXT NOT NULL, -- 'one_time' or 'recurring'
     interval TEXT, -- 'month', 'year', etc. (for recurring)
     metadata JSONB,
     created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
     updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
   );
   ```

4. **stripe.subscriptions** - Stores active subscriptions
   ```sql
   CREATE TABLE stripe.subscriptions (
     id TEXT PRIMARY KEY, -- Stripe subscription ID (e.g., sub_...)
     customer_id TEXT REFERENCES stripe.customers(id),
     status TEXT NOT NULL, -- 'active', 'canceled', 'past_due', etc.
     price_id TEXT REFERENCES stripe.prices(id),
     cancel_at_period_end BOOLEAN NOT NULL DEFAULT FALSE,
     current_period_start TIMESTAMPTZ NOT NULL,
     current_period_end TIMESTAMPTZ NOT NULL,
     metadata JSONB,
     created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
     updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
   );
   ```

5. **stripe.webhook_events** - Stores raw Stripe webhook events
   ```sql
   CREATE TABLE stripe.webhook_events (
     id TEXT PRIMARY KEY, -- Stripe event ID (e.g., evt_...)
     type TEXT NOT NULL, -- Event type (e.g., 'customer.created', 'invoice.paid')
     api_version TEXT NOT NULL, -- Stripe API version
     created TIMESTAMPTZ NOT NULL, -- Timestamp from Stripe
     data JSONB NOT NULL, -- Raw event data from Stripe
     idempotency_key TEXT, -- Optional idempotency key
     processing_status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'processed', 'failed'
     processing_error TEXT, -- Error message if processing failed
     processing_attempts INTEGER NOT NULL DEFAULT 0, -- Number of processing attempts
     processed_at TIMESTAMPTZ, -- When event was processed
     received_at TIMESTAMPTZ NOT NULL DEFAULT NOW() -- When event was received
   );
   ```

### Additional Recommended Tables

6. **stripe.invoices** - Tracks invoice data
   ```sql
   CREATE TABLE stripe.invoices (
     id TEXT PRIMARY KEY, -- Stripe invoice ID (e.g., in_...)
     customer_id TEXT REFERENCES stripe.customers(id),
     subscription_id TEXT REFERENCES stripe.subscriptions(id),
     status TEXT NOT NULL, -- 'draft', 'open', 'paid', 'uncollectible', 'void'
     currency TEXT NOT NULL,
     amount_due INTEGER NOT NULL,
     amount_paid INTEGER NOT NULL,
     amount_remaining INTEGER NOT NULL,
     invoice_pdf TEXT, -- URL to PDF invoice
     hosted_invoice_url TEXT, -- URL to hosted invoice page
     period_start TIMESTAMPTZ,
     period_end TIMESTAMPTZ,
     created TIMESTAMPTZ NOT NULL,
     metadata JSONB,
     updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
   );
   ```

7. **stripe.payment_methods** - Stores customer payment methods
   ```sql
   CREATE TABLE stripe.payment_methods (
     id TEXT PRIMARY KEY, -- Stripe payment method ID (e.g., pm_...)
     customer_id TEXT REFERENCES stripe.customers(id),
     type TEXT NOT NULL, -- 'card', 'bank_account', etc.
     card_brand TEXT, -- 'visa', 'mastercard', etc.
     card_last4 TEXT, -- Last 4 digits of card
     card_exp_month INTEGER,
     card_exp_year INTEGER,
     is_default BOOLEAN DEFAULT FALSE,
     created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
     updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
   );
   ```

8. **stripe.charges** - Records charge data
   ```sql
   CREATE TABLE stripe.charges (
     id TEXT PRIMARY KEY, -- Stripe charge ID (e.g., ch_...)
     customer_id TEXT REFERENCES stripe.customers(id),
     invoice_id TEXT REFERENCES stripe.invoices(id),
     payment_intent_id TEXT,
     amount INTEGER NOT NULL,
     currency TEXT NOT NULL,
     payment_method_id TEXT,
     status TEXT NOT NULL, -- 'succeeded', 'pending', 'failed'
     created TIMESTAMPTZ NOT NULL,
     metadata JSONB,
     updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
   );
   ```

### Application-Specific Tables

9. **config.subscription_benefits** - Maps subscription tiers to application benefits
   ```sql
   CREATE TABLE config.subscription_benefits (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     product_id TEXT REFERENCES stripe.products(id) ON DELETE CASCADE,
     monthly_credits INTEGER NOT NULL DEFAULT 0,
     max_projects INTEGER,
     has_priority_support BOOLEAN NOT NULL DEFAULT FALSE,
     has_advanced_features BOOLEAN NOT NULL DEFAULT FALSE,
     created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
     updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
   );
   ```

### Webhook Syncing Strategy

When implementing webhook handlers, follow this sequence:

1. **Capture raw event** - Always store the complete webhook payload in `stripe.webhook_events`
2. **Extract relevant data** - Parse the event data for the specific tables that need updating
3. **Maintain referential integrity** - Ensure related records exist before creating dependent records
4. **Update application state** - After syncing to Stripe tables, update application tables as needed (e.g., credit balances)
5. **Mark event as processed** - Update the webhook event record to reflect successful processing

## Config Schema for Application Settings

A dedicated `config` schema provides a clear separation between application configuration and user/business data, keeping settings separate from your core application data.

### Recommended Config Tables

1. **config.subscription_benefits** - Maps product IDs to application features
   ```sql
   CREATE TABLE config.subscription_benefits (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     product_id TEXT REFERENCES stripe.products(id) ON DELETE CASCADE,
     monthly_credits INTEGER NOT NULL DEFAULT 0,
     max_projects INTEGER,
     has_priority_support BOOLEAN NOT NULL DEFAULT FALSE,
     has_advanced_features BOOLEAN NOT NULL DEFAULT FALSE,
     created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
     updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
   );
   ```

This approach separates your application configuration from both your business data and external integrations like Stripe, making your schema more maintainable and clearly organized.

## Supabase Storage Function Array Access Pattern

When working with Supabase storage functions that return arrays (`storage.foldername()`, `storage.filename()`), always use this pattern:

```sql
-- Correct pattern for accessing array elements
(storage.foldername(storage.objects.name))[1]
```

- Always use parentheses around the function call
- Arrays are 1-indexed in PostgreSQL
- Type cast when comparing with UUIDs: `(storage.foldername(...))[1] = entity.id::text`

### Example

```sql
CREATE POLICY "Users can access their files" ON storage.objects
FOR SELECT USING (
  bucket_id = 'user-files' AND 
  auth.uid()::text = (storage.foldername(storage.objects.name))[1]
);
```