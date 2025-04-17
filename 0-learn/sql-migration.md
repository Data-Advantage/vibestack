# SQL Migration

SQL migrations are a way to manage and version control changes to your database schema over time. They provide a structured approach to evolve your database as your application grows.

## Key Concepts

- **Migration Files**: SQL scripts that alter database structure
- **Version Control**: Each migration is versioned (often by timestamp)
- **Up/Down Migrations**: Scripts to apply changes (up) and revert them (down)
- **Migration History**: Tracking which migrations have been applied
- **Idempotency**: Migrations should be safely rerunnable

## Common Migration Operations

- Creating new tables
- Adding, modifying, or removing columns
- Adding indexes and constraints
- Seeding reference data
- Setting up Row Level Security policies

## Resources

- [Supabase CLI Migrations Guide](https://supabase.com/docs/guides/cli/migrations)
- [Database Schema Migration Tools](https://supabase.com/docs/guides/database/migrations)

## How It's Used in VibeStack

In Day 1 of the VibeStack workflow, you'll create an initial SQL migration file that sets up your Supabase database schema with tables, relationships, and security policies. This provides the data foundation for your SaaS application.
