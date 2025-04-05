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
- `reference` - Publicly available lookup tables
- `analytics` - Reporting data
- `audit` - Tracking changes

This separation provides clearer organization, better security isolation, and more maintainable code.

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

## UUID Generation Options

When creating UUIDs as primary keys in Supabase, use `pgcrypto` with the `gen_random_uuid()` function.

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

- Create appropriate indexes for frequently queried columns
- Use pagination for large datasets
- Implement query optimization for complex joins
- Consider materialized views for complex analytical queries
- Use appropriate foreign key constraints and cascading operations

Remember that proper database design is crucial for application scalability and security. Always consider the implications of your schema design on performance, security, and maintainability.

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