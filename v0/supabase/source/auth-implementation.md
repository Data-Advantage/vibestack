# Authentication Implementation

This document outlines the implementation of Supabase Authentication in Next.js 15+ applications with App Router.

## Overview

Supabase Auth provides a complete authentication system that works seamlessly with Next.js Server Components, Client Components, and App Router. The implementation uses cookie-based sessions rather than localStorage for better SSR compatibility.

## Required Packages

- `@supabase/supabase-js` - Core Supabase client library
- `@supabase/ssr` - New package that replaces the older Auth Helpers

## Environment Setup

```
NEXT_PUBLIC_SUPABASE_URL=<your_supabase_project_url>
NEXT_PUBLIC_SUPABASE_ANON_KEY=<your_supabase_anon_key>
```

For admin operations (not exposed to client):
```
SUPABASE_SERVICE_ROLE_KEY=<your_service_role_key>
```

## Client Utilities Structure

Create three core utilities:

1. `lib/supabase/client.ts` - For Client Components
2. `lib/supabase/server.ts` - For Server Components and Server Actions
3. `lib/supabase/middleware.ts` - For auth token refreshing in middleware

### Client Creation Pattern

The key pattern for Supabase Auth in Next.js:

- **Create New Clients Per Request**: Each server component or action creates a fresh client
- **Lightweight Operation**: Creating a client is inexpensive and maintains auth context
- **Server Context**: Server clients need request cookies for proper authentication
- **Client Singleton**: Browser client automatically implements a singleton pattern

### Browser Client (for Client Components)

```typescript
// lib/supabase/client.ts
import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
```

### Server Client (for Server Components and Actions)

```typescript
// lib/supabase/server.ts
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // The `setAll` method was called from a Server Component.
            // This can be ignored if you have middleware refreshing
            // user sessions.
          }
        },
      },
    }
  )
}
```

## Middleware Implementation

Server Components cannot set cookies directly, so middleware is needed to handle session refreshing:

```typescript
// middleware.ts
import { NextRequest } from 'next/server'
import { updateSession } from '@/lib/supabase/middleware'

export async function middleware(request: NextRequest) {
  return await updateSession(request)
}

export const config = {
  matcher: [
    // Match all paths except static assets and images
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
```

## Cookie Handling

The cookies object in Supabase utilities provides:

- Storage of session data in cookies instead of localStorage
- Access to auth state on both client and server sides
- Proper session refreshing through middleware
- Consistent authentication across page navigations

The session cookie is named `sb-<project_ref>-auth-token` by default.

## Authentication Patterns

### Authentication Flows

Implement server actions for common auth flows:

- **Login**: Email/password and social login
- **Signup**: New user registration with email verification
- **Password Reset**: Forgot password flow
- **Email Verification**: Confirm newly registered emails
- **OAuth**: Social login with providers like Google, GitHub, etc.

### Protected Routes

#### For Server Components:

```typescript
// Example protected page
export default async function ProtectedPage() {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.getUser();
  
  if (error || !data?.user) {
    redirect('/login');
  }
  
  return <p>Protected content for {data.user.email}</p>;
}
```

#### For Client Components:

Create a custom hook for auth state management:

```typescript
// lib/hooks/use-auth.ts
'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'

export function useAuth() {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)
  const router = useRouter()
  const supabase = createClient()

  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (event, session) => {
        setUser(session?.user || null)
        setLoading(false)
        router.refresh()
      }
    )

    return () => {
      subscription.unsubscribe()
    }
  }, [router, supabase])

  return { user, loading }
}
```

## Security Best Practices

- Always use `getUser()` not `getSession()` on server-side (exposes less data)
- Configure proper Row Level Security policies on all database tables
- Set up secure HTTP headers in Next.js config
- Implement proper CSRF protection (handled by Supabase's cookie approach)
- Use server components for sensitive operations where possible
- Never expose your service role key to the client
- Validate all user inputs with a schema validation library like Zod

## Implementation Steps

1. Set up Supabase project and capture credentials
2. Create auth utility files (client.ts, server.ts, middleware.ts)
3. Set up middleware.ts for session handling
4. Build login and register forms with shadcn/ui blocks
5. Implement server actions for authentication flows
6. Create protected routes with user checking
7. Add email verification and password reset flows
8. Configure OAuth providers in Supabase Dashboard (if needed)

Remember that Supabase Auth is designed to be flexible. You can customize the authentication flows to match your application's specific requirements while maintaining security best practices.