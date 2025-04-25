# Supabase Database Patterns

This document outlines the recommended database patterns and best practices for implementing Supabase in your Next.js application, organized by migration phase.

## 1. Initial Schema Analysis

### Schema Organization

#### Reserved Schemas
Respect Supabase's built-in schemas which have special purposes:
- `auth` - Authentication and user management
- `extensions` - PostgreSQL extensions and their objects
- `graphql` - GraphQL API implementation and schema definitions
- `graphql_public` - Public GraphQL interface and exposed operations
- `pgbouncer` - Connection pooling configuration and management
- `public` - Open access to database tables and objects (insecure)
- `realtime` - Realtime subscriptions
- `storage` - File storage and management
- `supabase_functions` - Edge functions

#### Default Database Roles

Supabase provides several pre-configured database roles to manage access control:

- **anon**: Public role for unauthenticated requests
- **authenticated**: Default role for authenticated users
- **authenticator**: Special role used by the API to switch between roles
- **dashboard_user**: Used for Supabase dashboard access
- **pgbouncer**: Used by the connection pooler
- **service_role**: Server-side role that bypasses Row Level Security (RLS)
- **supabase_admin**: Administrative role for Supabase
- **supabase_auth_admin**: Manages authentication tables and functions
- **supabase_read_only_user**: Read-only access to the database
- **supabase_realtime_admin**: Manages realtime subscription features
- **supabase_replication_admin**: Handles database replication
- **supabase_storage_admin**: Manages storage functionality
- **postgres**: Superuser role with full database access

These roles are managed by Supabase and have specific permissions designed for their intended use cases. When building your application, you'll typically interact with the database through either the `anon` role (for unauthenticated access) or the `authenticated` role (for logged-in users). The `service_role` is useful for server-side operations that need to bypass RLS.

#### Custom Schema Structure
Avoid using the `public` schema for user data. Instead, create purpose-specific schemas:

- `api` - User-generated content and application data, including user-specific instances of templates
- `internal` - Sensitive internal operations not directly accessible to users, financial data (credit balances, transactions), and system-generated records requiring special access controls
- `reference` - Publicly available lookup tables and reusable templates for features that have both templates and user customizations

#### Optional Custom Schemas
Additional custom schemas can be created for specialized functionality when needed:

- `analytics` - Reporting data (primarily views)
- `audit` - Tracking changes (use only if needed)
- `config` - Application configuration data
- `stripe` - Synced data from Stripe webhooks (if using Stripe)

#### Schema Placement Considerations

**Financial/Billing Data**
Financial data like credit balances and transactions should be placed in the `internal` schema (e.g., `internal.credit_transactions`).

Financial data is different from user-generated content as it:
- Consists of system-generated records (not user-authored)
- Requires special access controls
- Is administrative in nature rather than creative content

**Content Templates vs User-Specific Content**
For features that include both reusable templates and user-specific customizations:
- Place reusable templates in the `reference` schema (e.g., `reference.guide_templates`)
- Store user-specific instances in the `api` schema (e.g., `api.implementation_guides`)

This hybrid approach separates reusable content from user-specific customizations, providing better content management and reducing duplication.

#### Enum Placement
PostgreSQL enums should usually be placed in the `reference` schema as they represent fixed sets of values referenced across multiple tables.

```sql
-- Example enum placement
CREATE TYPE reference.status AS ENUM ('pending', 'active', 'completed', 'cancelled');

-- Usage in table definition
CREATE TABLE api.tasks (
  id uuid primary key default gen_random_uuid(),
  status reference.status NOT NULL DEFAULT 'pending'
);
```

### Default PostgreSQL Extensions
Supabase provides several pre-installed PostgreSQL extensions to enhance database functionality:

#### Core Extensions
1. **plpgsql (1.0)** - Installed in `pg_catalog` schema
   - PL/pgSQL procedural language for creating functions and triggers
   - Core procedural language used throughout PostgreSQL

2. **pg_stat_statements (1.10)** - Installed in `extensions` schema
   - Tracks planning and execution statistics of all SQL statements
   - Used by Query Performance monitoring tools
   - Helps identify slow queries and optimization opportunities

3. **pgjwt (0.2.0)** - Installed in `extensions` schema
   - JSON Web Token API for PostgreSQL
   - Provides functions for token generation and verification
   - Useful for custom authentication implementations

4. **pgcrypto (1.3)** - Installed in `extensions` schema
   - Cryptographic functions for PostgreSQL
   - Provides secure hashing, encryption, and UUID generation
   - Used for `gen_random_uuid()` function in primary keys

5. **uuid-ossp (1.1)** - Installed in `extensions` schema
   - Functions for generating universally unique identifiers (UUIDs)
   - Alternative UUID generation with more options than pgcrypto
   - Includes functions for creating UUIDs based on time, MAC address, etc.

6. **pg_graphql (1.5.11)** - Installed in `graphql` schema
   - GraphQL support for PostgreSQL
   - Automatically generates a GraphQL schema from your database schema
   - Provides a GraphQL API for your PostgreSQL database

#### Optional Extensions
Supabase also provides many optional extensions that can be enabled when needed. While it's best to rely on core extensions when possible, you may enable these additional extensions for specific use cases.
Available optional extensions include:

- address_standardizer
- address_standardizer_data_us
- autoinc
- bloom
- btree_gin
- btree_gist
- citext
- cube
- dblink
- dict_int
- dict_xsyn
- earthdistance
- fuzzystrmatch
- hstore
- http
- hypopg
- index_advisor
- insert_username
- intarray
- isn
- ltree
- moddatetime
- pg_cron
- pg_hashids
- pg_jsonschema
- pg_net
- pg_prewarm
- pg_repack
- pg_stat_monitor
- pg_trgm
- pg_walinspect
- pgaudit
- pgmq
- pgroonga
- pgroonga_database
- pgrouting
- pgrowlocks
- pgs
- pgstattuple
- pgtap
- plcoffee
- pls
- plpgsql_check
- plv8
- postgres_fdw
- postgis
- postgis_raster
- postgis_sfcgal
- postgis_tiger_geocoder
- postgis_topology
- refint
- rum
- seg
- sslinfo
- tablefunc
- tcn
- timescaledb
- tsm_system_rows
- tsm_system_time
- unaccent
- vector
- wrappers

### Database Type Safety
- Generate TypeScript types from your database schema using Supabase CLI
- Create a central export for your database types
- Extend database types with domain-specific interfaces when needed
- Use strongly typed Supabase queries with proper return type annotations

## 2. Foundation Migration

### UUID Generation Options
Use `pgcrypto` with the `gen_random_uuid()` function unless there is a need for more advanced features of `uuid-ossp`.

### Common Table Patterns
- Use UUIDs as primary keys for better distribution and security
- Include `created_at` and `updated_at` timestamps on all tables
- Use foreign key constraints to maintain referential integrity
- Consider soft deletes with a `deleted_at` timestamp instead of hard deletes
- Use enums for status fields and other fixed-value columns

### Simplified Constraints in Initial Migrations
Focus on essential constraints and defer complex ones:

#### Start With Essential Constraints Only
- **Primary Keys**: Always include these from the beginning
- **Foreign Keys**: Include these for basic referential integrity
- **NOT NULL**: Apply to columns that must have values
- **Simple CHECK constraints**: Use for basic data validation (e.g., `CHECK (amount >= 0)`)

#### Defer Complex Constraints
Defer complex constraints until their need is validated through actual usage.

### Avoiding Premature Optimization
Follow the principle of "optimize later" when building your database:

#### Anti-Patterns to Avoid
1. **Cache Warming Functions** - Let PostgreSQL handle caching automatically
2. **Over-Indexing** - Resist adding indexes to every column "just in case"
3. **Complex Stored Procedures for Simple Logic** - Keep application logic in your application code when possible
4. **Materialized Views in Initial Setup** - Start with regular views that don't require refresh management

## 3. Structure Migration

### User Profiles
- Store extended user data in `api.profiles`, not directly in `auth.users`
- Link profiles to auth users with a foreign key reference
- Apply Row Level Security (RLS) policies for user data protection

```sql
-- Example profile structure
CREATE TABLE api.profiles (
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

### Standard Utility Functions
Common utility functions simplify database operations and ensure consistent behavior. These should be placed in the `public` schema for organization and accessibility.

#### Standardizing Timestamp Functions
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

-- Apply with consistent naming convention
CREATE TRIGGER handle_timestamps
BEFORE INSERT OR UPDATE ON api.table_name
FOR EACH ROW EXECUTE FUNCTION public.handle_timestamps();
```

### User Management Example
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

### Simplified Versioning Patterns
When implementing document versioning, start with the simplest approach that meets your immediate needs:

#### Start Simple
Instead of creating complex versioning systems, simply add a version counter to your main table.

```sql
CREATE TABLE api.documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content TEXT,
  version INTEGER NOT NULL DEFAULT 1,
  updated_by UUID REFERENCES auth.users(id)
);
```

## 4. Relationships Migration

### Relationships and Foreign Keys
- Define all relationships between tables
- Specify foreign key constraints with appropriate actions:
  - ON DELETE (CASCADE, SET NULL, RESTRICT)
  - ON UPDATE (CASCADE, RESTRICT)
- Add unique constraints or composite keys where needed
- Implement check constraints to enforce business rules

### Indexes
Create indexes for:
- Foreign keys that will be frequently queried
- Columns often used in WHERE clauses
- Columns used for sorting (ORDER BY)
- Consider composite indexes for multi-column queries
- Add GIN indexes for JSONB or array columns if needed

Remember:
- Each index speeds up read operations
- Each index slows down write operations
- Each index increases storage requirements

### Views
Create views for:
- Common complex queries
- Reporting and analytics
- Joining data across schemas

Consider materialized views only for complex analytics that are infrequently updated.

### Simplified Analytics Approach
When creating analytics capabilities for your application, start with minimal infrastructure:

#### Use Views Instead of Complex Infrastructure
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

## 5. Security Migration

### Database Function Security

#### Function Security Organization
Organize functions by security sensitivity to create layers of protection:

1. **Functions in `internal` schema** - Highest security
   - Place sensitive operations here (financial, permissions, admin)
   - Never allow direct access from application code
   - Only call these from controlled database triggers or API functions

2. **Functions in `api` schema** - Public API with permission checks
   - Create wrapper functions that validate permissions
   - Then call internal functions if validation passes

3. **Functions in `public` schema** - General utilities only
   - Place only non-sensitive, general-purpose utilities here
   - Avoid financial, permissions, or sensitive data operations

#### Function Search Path
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

#### Key Best Practices
- Always set explicit search paths for all functions
- Include only necessary schemas in the search path
- Always include pg_temp at the end of the search path
- Choose security context carefully:
  - Use `SECURITY DEFINER` when the function needs elevated permissions
  - Use `SECURITY INVOKER` (default) when the function should run with caller's permissions

### Trigger Function Best Practices

#### Use Proper Schema Qualification
Always place utility functions in the `public` schema and fully qualify their names when referenced:

```sql
-- Create trigger with full schema qualification
CREATE TRIGGER set_updated_at 
BEFORE UPDATE ON api.my_table 
FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
```

#### Handling the NEW Record in Trigger Functions
When using `NEW` in SQL contexts within PL/pgSQL functions, you may encounter the error "missing FROM-clause entry for table 'new'". Always assign the `NEW` record to a local variable at the beginning of your trigger function, then reference this variable instead of directly using `NEW` in SQL operations.

```sql
-- Best practice: use local variables
CREATE FUNCTION my_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
  record_data RECORD;  -- Local variable to store NEW
BEGIN
  record_data := NEW;  -- Assign NEW to local variable
  
  -- Use record_data instead of NEW in SQL contexts
  INSERT INTO api.audit_log(entity_id, changed_by) 
  VALUES (record_data.id, auth.uid());
  
  RETURN record_data;
END;
$$ LANGUAGE plpgsql;
```

#### Additional Trigger Function Considerations
- Use `DECLARE` section to create any needed local variables
- Include descriptive comments about the trigger's purpose
- Return the modified record when using `BEFORE` triggers
- Return `NULL` when using `AFTER` triggers that don't need to modify the record
- Always handle potential exceptions with appropriate error messages

### Storage Implementation

#### Storage Buckets
Create separate buckets based on access patterns:
- `public` - Openly accessible files
- `protected` - Authenticated-only access
- `private` - User-specific private files

#### Storage RLS
Apply RLS policies to storage buckets to control file access:
- Control file uploads based on user identity and file location
- Set up policies for viewing, uploading, and deleting files

```sql
-- Example storage policy
CREATE POLICY "Users can upload their own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    auth.uid() = (storage.foldername())[1]::uuid
    AND storage.filename() ~ '^avatar\.(jpg|jpeg|png)$'
  );
```

#### Storage Array Access Pattern
When working with storage functions that return arrays, always use this pattern:

```sql
-- Correct pattern for accessing array elements
(storage.foldername(storage.objects.name))[1]

-- Example in policy
CREATE POLICY "Users can access their files" 
ON storage.objects FOR SELECT 
USING (
  bucket_id = 'user-files' AND 
  auth.uid()::text = (storage.foldername(storage.objects.name))[1]
);
```

#### Preventing Ambiguous Column References
When writing storage policies that involve JOINs with other tables, always fully qualify column names that exist in multiple tables, especially the `name` column in `storage.objects`.

### Row Level Security (RLS)

#### General RLS Best Practices
- Enable RLS on all tables storing user data
- Create specific policies for each operation type (SELECT, INSERT, UPDATE, DELETE)
- Use `auth.uid()` function to identify the authenticated user
- Start with restrictive policies, then add permissions as needed

#### RLS Implementation Sequence
1. **Plan your policies first:** Document who needs what access to which tables
2. **Create policies before or immediately after enabling RLS:** Tables with RLS enabled but no policies will block all access by default
3. **Test each policy:** Verify that legitimate access works and unauthorized access is blocked

#### Common Policy Patterns
1. **Ownership-based Access** - Users can only access their own data
```sql
CREATE POLICY "Users can view their own profiles"
  ON api.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profiles"
  ON api.profiles FOR UPDATE
  USING (auth.uid() = id);
```

2. **Role-based Access** - Permissions based on user roles
```sql
CREATE POLICY "Admins can view all profiles"
  ON api.profiles FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');
```

3. **Relationship-based Access** - Access based on team membership or other relationships
```sql
CREATE POLICY "Team members can view team data"
  ON api.team_data FOR SELECT
  USING (
    auth.uid() IN (
      SELECT user_id FROM api.team_members 
      WHERE team_id = api.team_data.team_id
    )
  );
```

#### RLS Optimization Patterns
1. **Use Functions for Common Policy Patterns** - Create shared functions for repeated policy logic
```sql
CREATE FUNCTION public.is_admin() RETURNS BOOLEAN AS $$
  SELECT auth.jwt() ->> 'role' = 'admin';
$$ LANGUAGE sql SECURITY DEFINER;
```

2. **Simplify Relationship Checks** - Create views that join related tables instead of using nested EXISTS subqueries
3. **Index Policy Columns** - Always add indexes on columns used in RLS policies
4. **Avoid Redundant Conditions** - When USING and WITH CHECK conditions are identical, use WITH CHECK only

## 6. Seed Data

When creating seed data, focus exclusively on:
1. Populating reference tables with required values
2. Including standard lookup data the application needs to function
3. NOT inserting any user data or user-generated content
4. Providing only minimal reference data needed for operation

Examples of appropriate seed data include:
- Status options and types
- Category definitions
- Configuration settings
- Role definitions
- Permission types
- Standard options for dropdown menus
- Other static lookup values

## 7. Schema Validation

Before finalizing your schema, validate it against:

### Completeness Check
- Are all key entities from the product requirements represented?
- Have you implemented all necessary relationships?
- Does the schema support all the main user flows described in the requirements?
- Is anything missing from the core business objects?

### Security Assessment
- Have you enabled RLS on all user-data tables?
- Do all sensitive tables have appropriate policies?
- Have you handled storage security properly?
- Are there any potential security holes in your design?

### Scalability and Performance Considerations
- Will this schema design scale with expected user growth?
- Have you identified potential performance bottlenecks?
- Are your indexing strategies appropriate for expected query patterns?
- Have you avoided premature optimization?

### Database Maintenance
- Have you implemented proper triggers for timestamps and auditing?
- Are your foreign key constraints appropriate?
- Is your schema organized logically for future modifications?

## 8. Schema Refinement (Optional)

If refinement is needed, consider:
1. Addressing any concerns about the proposed schema
2. Adding any missing entities or attributes
3. Addressing performance or scaling considerations
4. Implementing simplifications or optimizations

## 9. Implementation Examples

### Standard Stripe Tables
When integrating Stripe payments with your application, use a consistent table structure in the `stripe` schema:

#### Core Stripe Tables
1. **stripe.customers** - Links Stripe customers to application users
   - Fields: id, user_id, email, name, metadata, created_at, updated_at

2. **stripe.products** - Stores Stripe products
   - Fields: id, name, description, active, metadata, created_at, updated_at

3. **stripe.prices** - Stores Stripe prices for products
   - Fields: id, product_id, active, currency, unit_amount, type, interval, metadata, created_at, updated_at

4. **stripe.subscriptions** - Stores active subscriptions
   - Fields: id, customer_id, status, price_id, cancel_at_period_end, current_period_start, current_period_end, metadata, created_at, updated_at

5. **stripe.webhook_events** - Stores raw Stripe webhook events
   - Fields: id, type, api_version, created, data, processing_status, processing_error, processing_attempts, processed_at, received_at

#### Additional Recommended Tables
6. **stripe.invoices** - Tracks invoice data
   - Fields: id, customer_id, subscription_id, status, currency, amount_due, amount_paid, amount_remaining, invoice_pdf, hosted_invoice_url, period_start, period_end, created, metadata, updated_at

7. **stripe.payment_methods** - Stores customer payment methods
   - Fields: id, customer_id, type, card_brand, card_last4, card_exp_month, card_exp_year, is_default, created_at, updated_at

8. **stripe.charges** - Records charge data
   - Fields: id, customer_id, invoice_id, payment_intent_id, amount, currency, payment_method_id, status, created, metadata, updated_at

### Config Schema for Application Settings
A dedicated `config` schema provides a clear separation between application configuration and user/business data.

9. **config.subscription_benefits** - Maps subscription tiers to application benefits (sample only)
   - Fields: id, product_id, monthly_credits, max_projects, has_priority_support, has_advanced_features, created_at, updated_at

### Data Access from Next.js

#### Server Components
- Create a fresh Supabase client per request using `createClient()`
- Access data directly in Server Components with RLS automatically applied based on the user's session
- Use proper error handling and type checking for database operations

#### Client Components
- Use custom hooks or React Query for data fetching in Client Components
- Implement optimistic updates for better user experience
- Create domain-specific hooks that encapsulate Supabase queries
- Handle loading, error, and success states appropriately

#### Realtime Subscriptions
- Use Supabase's realtime capabilities for live updates
- Implement channel-based subscriptions for specific tables or rows
- Properly clean up subscriptions when components unmount
