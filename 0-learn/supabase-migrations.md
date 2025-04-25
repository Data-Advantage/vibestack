# Supabase Database Migrations Guide

This guide walks you through setting up and managing database migrations for your Supabase project using the Supabase CLI.

## 1. Understanding Database Migrations

Database migrations are SQL statements that create, update, or delete your existing database schemas. They provide a structured way to:

- Track changes to your database over time
- Apply changes consistently across environments
- Roll back changes if needed
- Collaborate with team members on database development

> **Important:** Migrations are applied in chronological order based on their timestamp prefixes. Always ensure your migrations can be applied sequentially without errors.

## 2. Setting Up Your Development Environment

Before you begin, you'll need to set up your local development environment:

1. **Install the Supabase CLI**:
   ```bash
   # Using npm
   npm install -g supabase
   
   # Using Homebrew on macOS
   brew install supabase/tap/supabase
   ```

2. **Start your local Supabase stack**:
   ```bash
   supabase start
   ```

3. **Create a migrations directory** (if not already created):
   ```bash
   mkdir -p supabase/migrations
   ```

> **Note:** The Supabase CLI automatically creates the migrations directory when you run `supabase init` to set up a new project.

## 3. Creating Your First Migration

Let's create a migration to establish a database table:

1. **Generate a migration file**:
   ```bash
   supabase migration new create_employees_table
   ```
   This creates a timestamped SQL file in the `supabase/migrations` directory.

2. **Add SQL to your migration file**:
   ```sql
   -- supabase/migrations/<timestamp>_create_employees_table.sql
   create table if not exists employees (
     id bigint primary key generated always as identity,
     name text not null,
     email text,
     created_at timestamptz default now()
   );
   ```

3. **Apply your migration**:
   ```bash
   supabase migration up
   ```

> **Note:** After applying the migration, you can visit the Dashboard to see your new `employees` table.

## 4. Making Schema Changes with Migrations

When your application evolves, you'll need to modify your database schema:

1. **Create a new migration for schema changes**:
   ```bash
   supabase migration new add_department_column
   ```

2. **Add SQL for the schema modification**:
   ```sql
   -- supabase/migrations/<timestamp>_add_department_column.sql
   alter table if exists public.employees
   add department text default 'Hooli';
   ```

3. **Apply the new migration**:
   ```bash
   supabase migration up
   ```

> **Important:** Always test migrations locally before applying them to production to avoid unexpected issues.

## 5. Seeding Your Database

Seed files populate your database with initial data, which is especially useful for development and testing:

1. **Create a seed file** at `supabase/seed.sql`:
   ```sql
   -- supabase/seed.sql
   insert into public.employees
     (name)
   values
     ('Erlich Bachman'),
     ('Richard Hendricks'),
     ('Monica Hall');
   ```

2. **Apply migrations and seed data** in one command:
   ```bash
   supabase db reset
   ```

> **Note:** The `db reset` command will reset your local database, reapply all migrations, and then apply your seed data.

## 6. Using Dashboard and Diffing Changes

If you prefer using the Supabase Dashboard to create tables and columns visually:

1. **Create or modify a table in the Dashboard**
   - Use the Table Editor to add tables, columns, relationships, etc.

2. **Generate a migration from your changes**:
   ```bash
   supabase db diff -f create_cities_table
   ```

3. **Review the generated migration file**:
   ```sql
   -- supabase/migrations/<timestamp>_create_cities_table.sql
   create table "public"."cities" (
     "id" bigint primary key generated always as identity,
     "name" text,
     "population" bigint
   );
   ```

4. **Test your migration**:
   ```bash
   supabase db reset
   ```

> **Tip:** You can also copy table definitions directly from the Table Editor in the Dashboard.

## 7. Deploying to Production

Once you've developed and tested your migrations locally, you'll want to deploy them to production:

1. **Login to the Supabase CLI**:
   ```bash
   supabase login
   ```

2. **Link your local project to your remote Supabase project**:
   ```bash
   supabase link
   ```
   You'll be prompted to select your remote project.

3. **Push your migrations to the remote database**:
   ```bash
   supabase db push
   ```

4. **Optionally include seed data in the deployment**:
   ```bash
   supabase db push --include-seed
   ```

> **Important:** Be careful when using `--include-seed` in production as it may duplicate or overwrite existing data.

## 8. Managing Complex Migrations

For more complex database changes, consider these best practices:

1. **Handling Dependencies Between Migrations**:
   - Ensure migrations are applied in the correct order
   - Split complex changes into multiple migrations
   - Consider dependencies between tables and constraints

2. **Dealing with Data Migrations**:
   - For data transformations, create separate migrations
   - For large datasets, consider batching updates
   ```sql
   -- Example of a data migration
   UPDATE employees
   SET department = 'Engineering'
   WHERE email LIKE '%@engineering.com';
   ```

3. **Testing Migrations**:
   - Create automated tests for your migrations
   - Test both up and down migrations
   - Verify data integrity after migrations

## 9. Rollback and Recovery

Sometimes you need to undo migrations:

1. **Rolling back the most recent migration**:
   ```bash
   supabase migration down
   ```

2. **Creating idempotent migrations** (can be run multiple times without error):
   ```sql
   -- Example of an idempotent migration
   CREATE TABLE IF NOT EXISTS employees (...);
   ALTER TABLE IF EXISTS employees ADD COLUMN IF NOT EXISTS department text;
   ```

3. **Creating reversible migrations**:
   - Add down migrations for critical changes
   - Document the rollback process

## 10. Best Practices for Database Migrations

1. **Version Control**:
   - Always commit migration files to your version control system
   - Use descriptive names for migration files
   - Include comments in complex SQL operations

2. **Migration Structure**:
   - Keep migrations small and focused
   - Make migrations reversible when possible
   - Use schemas to organize database objects

3. **Team Collaboration**:
   - Coordinate migration development with team members
   - Review migrations before applying to production
   - Document schema changes

4. **Security Considerations**:
   - Be careful with permissions in migrations
   - Don't include sensitive data in seed files
   - Use row-level security for production data

5. **Performance**:
   - Consider the impact of migrations on production performance
   - Use transactions for atomic operations
   - Schedule migrations during low-traffic periods

By following this guide, you'll have a robust workflow for managing database changes in your Supabase projects, from local development through to production deployment.
