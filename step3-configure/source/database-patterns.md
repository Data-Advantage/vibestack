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

## Row Level Security (RLS)

### General RLS Best Practices
- Enable RLS on all tables storing user data
- Create specific policies for each operation type (SELECT, INSERT, UPDATE, DELETE)
- Use `auth.uid()` function to identify the authenticated user
- Start with restrictive policies, then add permissions as needed

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