# Supabase

[Supabase](https://supabase.com/) is an open-source Firebase alternative that provides a suite of tools for building modern applications. In VibeStack, Supabase serves as the foundation for database, authentication, storage, and realtime features.

## Introduction to Supabase

Supabase combines several powerful open-source tools into a developer-friendly platform:

- **PostgreSQL Database**: Robust relational database with JSONB support and extensions
- **Auth**: User management and multiple authentication methods
- **Storage**: File storage and management with security rules
- **Realtime**: Live data updates via WebSockets
- **Edge Functions**: Serverless functions for custom backend logic
- **Vector**: AI vector embeddings and similarity search

## Setting Up Supabase in VibeStack

### Configuration

To connect your Next.js application to Supabase:

```typescript
// lib/supabase/server.ts
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import { type CookieOptions } from '@supabase/ssr';

export function createClient() {
  const cookieStore = cookies();
  
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value;
        },
        set(name: string, value: string, options: CookieOptions) {
          try {
            cookieStore.set({ name, value, ...options });
          } catch (error) {
            // Handle errors if cookies cannot be set
          }
        },
        remove(name: string, options: CookieOptions) {
          try {
            cookieStore.delete({ name, ...options });
          } catch (error) {
            // Handle errors if cookies cannot be removed
          }
        },
      },
    }
  );
}

// lib/supabase/client.ts
import { createBrowserClient } from '@supabase/ssr';

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
```

### Middleware for Auth

```typescript
// middleware.ts
import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@supabase/ssr';

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({
    request: {
      headers: request.headers,
    },
  });
  
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return request.cookies.get(name)?.value;
        },
        set(name: string, value: string, options: any) {
          request.cookies.set({
            name,
            value,
            ...options,
          });
          response = NextResponse.next({
            request: {
              headers: request.headers,
            },
          });
          response.cookies.set({
            name,
            value,
            ...options,
          });
        },
        remove(name: string, options: any) {
          request.cookies.delete({
            name,
            ...options,
          });
          response = NextResponse.next({
            request: {
              headers: request.headers,
            },
          });
          response.cookies.delete({
            name,
            ...options,
          });
        },
      },
    }
  );
  
  // Refresh session if expired
  await supabase.auth.getSession();
  
  return response;
}
```

## Authentication

Supabase provides multiple authentication options:

### Email/Password Authentication

```typescript
'use client'

import { useState } from 'react';
import { createClient } from '@/lib/supabase/client';

export default function SignUpForm() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  
  const supabase = createClient();
  
  async function handleSignUp(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError('');
    
    try {
      const { error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          emailRedirectTo: `${window.location.origin}/auth/callback`,
        },
      });
      
      if (error) throw error;
      
      // Success message or redirect
    } catch (error: any) {
      setError(error.message);
    } finally {
      setLoading(false);
    }
  }
  
  return (
    <form onSubmit={handleSignUp}>
      {/* Form fields */}
      <input
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        required
      />
      <input
        type="password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        required
      />
      <button type="submit" disabled={loading}>
        {loading ? 'Signing up...' : 'Sign Up'}
      </button>
      {error && <p className="error">{error}</p>}
    </form>
  );
}
```

### OAuth Authentication

```typescript
'use client'

import { createClient } from '@/lib/supabase/client';

export default function OAuthButtons() {
  const supabase = createClient();
  
  async function signInWithProvider(provider: 'google' | 'github') {
    await supabase.auth.signInWithOAuth({
      provider,
      options: {
        redirectTo: `${window.location.origin}/auth/callback`,
      },
    });
  }
  
  return (
    <div>
      <button onClick={() => signInWithProvider('google')}>
        Sign in with Google
      </button>
      <button onClick={() => signInWithProvider('github')}>
        Sign in with GitHub
      </button>
    </div>
  );
}
```

### Auth Callback Handler

```typescript
// app/auth/callback/route.ts
import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs';
import { cookies } from 'next/headers';
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  const requestUrl = new URL(request.url);
  const code = requestUrl.searchParams.get('code');
  
  if (code) {
    const cookieStore = cookies();
    const supabase = createRouteHandlerClient({ cookies: () => cookieStore });
    await supabase.auth.exchangeCodeForSession(code);
  }
  
  // URL to redirect to after sign in
  return NextResponse.redirect(new URL('/dashboard', request.url));
}
```

## Database Operations

### Basic CRUD Operations

```typescript
// Server component example
import { createClient } from '@/lib/supabase/server';

export default async function TasksList() {
  const supabase = createClient();
  
  const { data: tasks, error } = await supabase
    .from('tasks')
    .select('id, title, status, created_at')
    .order('created_at', { ascending: false });
  
  if (error) {
    console.error('Error fetching tasks:', error);
    return <div>Error loading tasks</div>;
  }
  
  return (
    <ul>
      {tasks.map((task) => (
        <li key={task.id}>
          <h3>{task.title}</h3>
          <span>Status: {task.status}</span>
        </li>
      ))}
    </ul>
  );
}
```

### Advanced Queries

```typescript
// Complex query with joins and filters
const { data: projects, error } = await supabase
  .from('projects')
  .select(`
    id, 
    name, 
    description,
    created_at,
    team_members:project_members(
      user_id,
      role,
      users(id, name, avatar_url)
    )
  `)
  .eq('is_archived', false)
  .in('status', ['active', 'planning'])
  .order('created_at', { ascending: false })
  .limit(10);
```

### Server Actions

```typescript
// app/actions/tasks.ts
'use server'

import { createClient } from '@/lib/supabase/server';
import { revalidatePath } from 'next/cache';
import { z } from 'zod';

const taskSchema = z.object({
  title: z.string().min(3).max(100),
  description: z.string().optional(),
  status: z.enum(['todo', 'in_progress', 'completed']).default('todo'),
  due_date: z.string().optional(),
});

export async function createTask(formData: FormData) {
  const supabase = createClient();
  
  try {
    // Extract form data
    const newTask = {
      title: formData.get('title') as string,
      description: formData.get('description') as string,
      status: formData.get('status') as 'todo' | 'in_progress' | 'completed',
      due_date: formData.get('due_date') as string,
    };
    
    // Validate data
    const validatedTask = taskSchema.parse(newTask);
    
    // Get user ID (assumes authenticated user)
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) {
      return { success: false, error: 'Not authenticated' };
    }
    
    // Insert task with user_id
    const { data, error } = await supabase
      .from('tasks')
      .insert({
        ...validatedTask,
        user_id: session.user.id,
      })
      .select()
      .single();
    
    if (error) throw error;
    
    // Revalidate the tasks list page
    revalidatePath('/dashboard/tasks');
    
    return { success: true, task: data };
  } catch (error: any) {
    console.error('Error creating task:', error);
    return { success: false, error: error.message };
  }
}
```

## Row Level Security

Implementing security policies in PostgreSQL:

```sql
-- Enable RLS on the tasks table
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- Policy for selecting tasks (users can only see their own tasks)
CREATE POLICY select_own_tasks ON public.tasks
  FOR SELECT
  USING (user_id = auth.uid());

-- Policy for inserting tasks (users can only create tasks for themselves)
CREATE POLICY insert_own_tasks ON public.tasks
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Policy for updating tasks (users can only update their own tasks)
CREATE POLICY update_own_tasks ON public.tasks
  FOR UPDATE
  USING (user_id = auth.uid());

-- Policy for deleting tasks (users can only delete their own tasks)
CREATE POLICY delete_own_tasks ON public.tasks
  FOR DELETE
  USING (user_id = auth.uid());
```

## Realtime Subscriptions

Listen for database changes in real-time:

```typescript
'use client'

import { useEffect, useState } from 'react';
import { createClient } from '@/lib/supabase/client';

export default function RealtimeTasks() {
  const [tasks, setTasks] = useState<any[]>([]);
  const supabase = createClient();
  
  useEffect(() => {
    // Fetch initial tasks
    const fetchTasks = async () => {
      const { data } = await supabase
        .from('tasks')
        .select('*')
        .order('created_at', { ascending: false });
      
      if (data) setTasks(data);
    };
    
    fetchTasks();
    
    // Set up realtime subscription
    const channel = supabase
      .channel('table:tasks')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'tasks',
        },
        (payload) => {
          if (payload.eventType === 'INSERT') {
            setTasks((prev) => [payload.new, ...prev]);
          } else if (payload.eventType === 'UPDATE') {
            setTasks((prev) =>
              prev.map((task) => (task.id === payload.new.id ? payload.new : task))
            );
          } else if (payload.eventType === 'DELETE') {
            setTasks((prev) => prev.filter((task) => task.id !== payload.old.id));
          }
        }
      )
      .subscribe();
    
    // Clean up subscription on unmount
    return () => {
      supabase.removeChannel(channel);
    };
  }, [supabase]);
  
  return (
    <ul>
      {tasks.map((task) => (
        <li key={task.id}>{task.title}</li>
      ))}
    </ul>
  );
}
```

## Storage

Managing files with Supabase Storage:

```typescript
'use client'

import { useState } from 'react';
import { createClient } from '@/lib/supabase/client';

export default function FileUploader() {
  const [file, setFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState('');
  const [downloadUrl, setDownloadUrl] = useState('');
  
  const supabase = createClient();
  
  async function handleUpload() {
    if (!file) return;
    
    setUploading(true);
    setUploadError('');
    
    try {
      // Generate a unique file path
      const fileExt = file.name.split('.').pop();
      const fileName = `${Date.now()}.${fileExt}`;
      const filePath = `user-uploads/${fileName}`;
      
      // Upload the file
      const { error: uploadError } = await supabase.storage
        .from('documents')
        .upload(filePath, file);
      
      if (uploadError) throw uploadError;
      
      // Get the public URL
      const { data } = supabase.storage
        .from('documents')
        .getPublicUrl(filePath);
      
      setDownloadUrl(data.publicUrl);
    } catch (error: any) {
      setUploadError(error.message);
    } finally {
      setUploading(false);
    }
  }
  
  return (
    <div>
      <input
        type="file"
        onChange={(e) => setFile(e.target.files?.[0] || null)}
      />
      <button 
        onClick={handleUpload}
        disabled={!file || uploading}
      >
        {uploading ? 'Uploading...' : 'Upload'}
      </button>
      
      {uploadError && <p className="error">{uploadError}</p>}
      {downloadUrl && (
        <div>
          <p>File uploaded successfully!</p>
          <a href={downloadUrl} target="_blank" rel="noreferrer">
            View File
          </a>
        </div>
      )}
    </div>
  );
}
```

## Edge Functions

Deploying serverless functions with Supabase:

```typescript
// /supabase/functions/generate-summary/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.32.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST',
  'Access-Control-Allow-Headers': 'Authorization, X-Client-Info, Content-Type',
};

serve(async (req) => {
  // Handle CORS preflight request
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }
  
  try {
    const { text } = await req.json();
    
    if (!text) {
      return new Response(
        JSON.stringify({ error: 'Text is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
      );
    }
    
    // Initialize Supabase client with JWT token from request
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    );
    
    // Get the current authenticated user
    const { data: { user } } = await supabaseClient.auth.getUser();
    
    if (!user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
      );
    }
    
    // Process the text (e.g., with a third-party API like OpenAI)
    const summary = 'This is a summary of the provided text.'; // Replace with actual implementation
    
    // Store the result
    await supabaseClient
      .from('summaries')
      .insert({
        user_id: user.id,
        original_text: text,
        summary,
      });
    
    return new Response(
      JSON.stringify({ summary }),
      { headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    );
  }
});
```

## Type Safety with Database Types

Generate TypeScript types from your database schema:

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Generate types
supabase gen types typescript --project-id your-project-id > lib/database.types.ts
```

Using the generated types:

```typescript
// lib/database.types.ts (generated)
export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

export interface Database {
  public: {
    Tables: {
      tasks: {
        Row: {
          id: string
          created_at: string
          title: string
          description: string | null
          status: 'todo' | 'in_progress' | 'completed'
          user_id: string
          due_date: string | null
        }
        Insert: {
          id?: string
          created_at?: string
          title: string
          description?: string | null
          status?: 'todo' | 'in_progress' | 'completed'
          user_id: string
          due_date?: string | null
        }
        Update: {
          id?: string
          created_at?: string
          title?: string
          description?: string | null
          status?: 'todo' | 'in_progress' | 'completed'
          user_id?: string
          due_date?: string | null
        }
      }
      // Other tables...
    }
    // Views, functions, etc...
  }
}

// Using the types
import { createClient } from '@supabase/supabase-js';
import { Database } from '@/lib/database.types';

const supabase = createClient<Database>(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

// Now you get type checking for table names, columns, and enums
const { data, error } = await supabase
  .from('tasks')
  .select('id, title, status')
  .eq('status', 'todo'); // Type-checked: 'status' must be 'todo', 'in_progress', or 'completed'
```

## Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Next.js with Supabase Guide](https://supabase.com/docs/guides/getting-started/quickstarts/nextjs)
- [Auth Helpers for Next.js](https://supabase.com/docs/guides/auth/auth-helpers/nextjs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Supabase GitHub Repository](https://github.com/supabase/supabase)
- [Supabase Community](https://supabase.com/community)