# PostgreSQL

[PostgreSQL](https://www.postgresql.org/) is a powerful, open-source relational database management system that forms the foundation of Supabase, which is a core component of the VibeStack architecture.

## Introduction to PostgreSQL

PostgreSQL (often called "Postgres") is an advanced, enterprise-class database system with over 30 years of active development. Key features include:

- **ACID Compliance**: Ensuring data validity despite errors or failures
- **Advanced Data Types**: Including JSON, arrays, hstore, and geometric types
- **Extensibility**: Custom functions, operators, data types, and more
- **Concurrent Support**: Multi-version concurrency control (MVCC)
- **Full-Text Search**: Built-in indexing and searching capabilities
- **Advanced Indexing**: B-tree, Hash, GiST, SP-GiST, GIN, and BRIN

## Connection Through Supabase

In VibeStack, you'll typically interact with PostgreSQL through Supabase, which provides a user-friendly interface and API for database operations:

```typescript
// lib/supabase/client.ts
import { createClient } from '@supabase/supabase-js';

export const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

// Query example
const { data, error } = await supabase
  .from('your_table')
  .select('*')
  .eq('status', 'active');
```

## Schema Design

### Basic Schema Example

Here's a simple schema example for a VibeStack application:

```sql
-- Users table (extends Supabase auth.users)
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Projects table
CREATE TABLE public.projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  owner_id UUID REFERENCES public.profiles(id) NOT NULL,
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Project members junction table
CREATE TABLE public.project_members (
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('admin', 'editor', 'viewer')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  PRIMARY KEY (project_id, user_id)
);
```

### Data Types

PostgreSQL supports a rich set of data types:

| Data Type | Description | Example |
|-----------|-------------|---------|
| `TEXT` | Variable length text | `'Hello, world!'` |
| `VARCHAR(n)` | Variable length with limit | `VARCHAR(100)` |
| `INTEGER` | 4-byte integer | `42` |
| `BIGINT` | 8-byte integer | `9223372036854775807` |
| `NUMERIC` | Exact decimal number | `NUMERIC(10,2)` for currency |
| `BOOLEAN` | True/false value | `TRUE`, `FALSE` |
| `UUID` | Universal unique identifier | `uuid_generate_v4()` |
| `TIMESTAMP` | Date and time | `TIMESTAMP WITH TIME ZONE` |
| `JSONB` | Binary JSON data | `'{"key": "value"}'` |
| `ARRAY` | Array of values | `INTEGER[]`, `TEXT[]` |

## Row Level Security (RLS)

PostgreSQL's Row Level Security feature is a cornerstone of securing your VibeStack application. RLS allows you to define policies that restrict which rows a user can access.

### Example RLS Policy

```sql
-- Enable RLS on the projects table
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

-- Create policy for viewing projects
CREATE POLICY view_projects ON public.projects
  FOR SELECT
  USING (
    is_public OR                                  -- Public projects are visible to all
    owner_id = auth.uid() OR                      -- Owner can see their projects
    EXISTS (                                       -- Members can see their projects
      SELECT 1 FROM public.project_members
      WHERE project_id = projects.id AND user_id = auth.uid()
    )
  );

-- Create policy for updating projects
CREATE POLICY update_projects ON public.projects
  FOR UPDATE
  USING (
    owner_id = auth.uid() OR                      -- Owner can update
    EXISTS (                                       -- Admins and editors can update
      SELECT 1 FROM public.project_members
      WHERE project_id = projects.id 
      AND user_id = auth.uid() 
      AND role IN ('admin', 'editor')
    )
  );
```

## Common PostgreSQL Operations

### SELECT Queries

```sql
-- Basic select
SELECT * FROM projects WHERE is_public = true;

-- Joins
SELECT p.name, pr.display_name as owner
FROM projects p
JOIN profiles pr ON p.owner_id = pr.id;

-- Aggregation
SELECT COUNT(*), owner_id 
FROM projects 
GROUP BY owner_id
HAVING COUNT(*) > 5;

-- Window functions
SELECT 
  p.name, 
  p.created_at,
  ROW_NUMBER() OVER(PARTITION BY p.owner_id ORDER BY p.created_at DESC) as row_num
FROM projects p;
```

### Data Manipulation

```sql
-- Insert
INSERT INTO projects (name, description, owner_id, is_public)
VALUES ('New Project', 'Description here', 'user-uuid', true);

-- Update
UPDATE projects 
SET name = 'Updated Name', updated_at = now()
WHERE id = 'project-uuid';

-- Delete
DELETE FROM projects WHERE id = 'project-uuid';
```

### Using JSON

```sql
-- Query JSON data
SELECT data->>'name' as name
FROM resources
WHERE data->>'type' = 'document';

-- Update JSON data
UPDATE resources 
SET data = jsonb_set(data, '{status}', '"archived"')
WHERE id = 'resource-uuid';
```

## Real-time Features with Supabase

PostgreSQL's LISTEN/NOTIFY feature powers Supabase's real-time capabilities:

```typescript
// Subscribe to changes on the projects table
const channel = supabase
  .channel('schema-db-changes')
  .on(
    'postgres_changes',
    {
      event: '*', // Listen to all changes
      schema: 'public',
      table: 'projects',
    },
    (payload) => {
      console.log('Change received!', payload);
      // Update UI or state based on the change
    }
  )
  .subscribe();
```

## Migrations and Schema Management

For VibeStack projects, it's recommended to manage your PostgreSQL schema using migration files:

```sql
-- migrations/001_initial_schema.sql
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- More table definitions...

-- Apply migrations from your application or using Supabase migrations
```

## Performance Optimization

### Indexing

```sql
-- B-tree index (default, good for equality and range queries)
CREATE INDEX idx_projects_owner ON projects(owner_id);

-- Unique index
CREATE UNIQUE INDEX idx_projects_name_owner ON projects(name, owner_id);

-- Partial index
CREATE INDEX idx_active_projects ON projects(created_at) 
WHERE is_archived = false;

-- Text search index
CREATE INDEX idx_projects_description_gin ON projects 
USING GIN (to_tsvector('english', description));
```

### Query Optimization

- Use `EXPLAIN ANALYZE` to understand query execution plans
- Consider denormalization for frequently accessed data
- Use appropriate indexes for your query patterns
- Keep statistics up to date with regular `ANALYZE`

## Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Supabase PostgreSQL Documentation](https://supabase.com/docs/guides/database)
- [SQL Tutorial](https://www.postgresqltutorial.com/)
- [PostgreSQL Weekly Newsletter](https://postgresweekly.com/)
- [pgAdmin](https://www.pgadmin.org/) - GUI tool for PostgreSQL
