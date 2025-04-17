# SQL (Structured Query Language)

SQL is the standard language for interacting with relational databases like PostgreSQL, which forms the backbone of your Supabase implementation in VibeStack.

## Core SQL Concepts

### Basic Queries
```sql
-- Select all columns from a table
SELECT * FROM users;

-- Select specific columns
SELECT id, name, email FROM users;

-- Filter results with WHERE clause
SELECT * FROM users WHERE status = 'active';

-- Sort results
SELECT * FROM users ORDER BY created_at DESC;

-- Limit results
SELECT * FROM users LIMIT 10;
```

### Data Manipulation
```sql
-- Insert new records
INSERT INTO users (name, email) VALUES ('Jane Doe', 'jane@example.com');

-- Update existing records
UPDATE users SET status = 'inactive' WHERE last_login < NOW() - INTERVAL '90 days';

-- Delete records
DELETE FROM users WHERE status = 'deleted';
```

### Joins
```sql
-- Inner join (only matching records)
SELECT users.name, subscriptions.plan 
FROM users
JOIN subscriptions ON users.id = subscriptions.user_id;

-- Left join (all records from users, matching from subscriptions)
SELECT users.name, subscriptions.plan 
FROM users
LEFT JOIN subscriptions ON users.id = subscriptions.user_id;
```

## Best Practices for VibeStack

1. **Use Parameterized Queries**: Prevent SQL injection by using parameterized queries instead of string concatenation.

2. **Index Strategically**: Add indexes to columns frequently used in WHERE clauses and joins, but be mindful of write performance.

3. **Use Row Level Security (RLS)**: With Supabase, implement RLS policies to control data access at the database level.

4. **Transactions for Multi-step Operations**: Use transactions when multiple related operations need to succeed or fail together.

5. **Optimize Queries**: Use EXPLAIN ANALYZE to understand and optimize query performance.

## Common SQL Functions

- **Aggregation**: `COUNT()`, `SUM()`, `AVG()`, `MIN()`, `MAX()`
- **String**: `CONCAT()`, `LOWER()`, `UPPER()`, `TRIM()`
- **Date/Time**: `NOW()`, `DATE_TRUNC()`, `EXTRACT()`
- **Conditional**: `CASE`, `COALESCE()`, `NULLIF()`

## Database Design Principles

1. **Normalization**: Structure data to minimize redundancy (typically to 3NF)
2. **Appropriate Data Types**: Choose correct data types for columns
3. **Constraints**: Use PRIMARY KEY, FOREIGN KEY, UNIQUE, NOT NULL constraints
4. **Naming Conventions**: Consistent table and column naming

## Supabase-Specific SQL Tips

1. Use PostgreSQL extensions enabled in Supabase (e.g., `uuid-ossp` for UUID generation)
2. Leverage JSON operations for flexible data structures
3. Utilize Supabase's built-in full-text search capabilities
4. Implement trigger functions for automated reactions to data changes

## Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Supabase PostgreSQL Documentation](https://supabase.com/docs/guides/database)
- [SQL Tutorial on W3Schools](https://www.w3schools.com/sql/)
- [Mode Analytics SQL Tutorial](https://mode.com/sql-tutorial/)
