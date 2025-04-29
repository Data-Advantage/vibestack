# Resetting a Remote Supabase Database

This document outlines the process for resetting a remote Supabase database to its initial state with all migrations applied.

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) installed
- Access to your Supabase project credentials (connection string)
- Appropriate permissions to reset the database

## Warning

**⚠️ CAUTION: This command will delete all data in your database and recreate the schema from your migrations. This action cannot be undone.**

## Command Syntax

```bash
supabase db reset --db-url "postgresql://[user]:[password]@[host]:[port]/[database]"
```

## Example

```bash
supabase db reset --db-url "postgresql://postgres.xjypmumesfpyqdjojloj:[password]@aws-0-us-east-1.pooler.supabase.com:5432/postgres"
```

## Steps to Reset a Remote Database

1. **Backup your data** (if needed) before proceeding
2. Open your terminal or command prompt
3. Navigate to your project directory where migrations are stored
4. Replace `[password]` in the connection string with your actual database password
5. Run the command

## What This Command Does

This command:
1. Drops all tables, functions, and other objects from your database
2. Recreates the schema based on your migration files
3. Applies all migrations in order
4. Resets your database to a clean state with your schema intact

## Troubleshooting

- **Connection issues**: Verify your connection string and ensure network access to the Supabase instance
- **Permission errors**: Confirm you have the necessary permissions to reset the database
- **Missing migrations**: Ensure you're running the command from your project directory with migrations

## Security Considerations

- Never commit your database password to version control
- Consider using environment variables for sensitive connection information
- Restrict this operation to development/staging environments when possible