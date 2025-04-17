# Middleware

Middleware in Next.js is a powerful feature that allows you to run code before a request is completed, enabling request manipulation, authentication checks, redirects, and more. In VibeStack applications, middleware serves as a critical component for controlling navigation flow and implementing authentication.

## Introduction to Next.js Middleware

Middleware runs on the Edge runtime and executes before a page is rendered, making it ideal for:

- **Authentication**: Protecting routes and redirecting unauthenticated users
- **Request Manipulation**: Modifying headers or rewriting URLs
- **Internationalization**: Handling language detection and routing
- **Analytics**: Tracking page views and user behavior
- **Content Security**: Implementing security headers
- **A/B Testing**: Directing users to different versions of pages

## Basic Middleware Implementation

In a VibeStack project, create a `middleware.ts` file at the project root:

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // Get the pathname of the request
  const path = request.nextUrl.pathname;
  
  // Example: Redirect /old-path to /new-path
  if (path === '/old-path') {
    return NextResponse.redirect(new URL('/new-path', request.url));
  }
  
  // Continue to the requested page
  return NextResponse.next();
}

// Specify which paths this middleware should run on
export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
```

## Authentication Middleware with Supabase

Protecting routes in a VibeStack application using Supabase authentication:

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { createServerClient } from '@supabase/ssr';

export async function middleware(request: NextRequest) {
  const requestHeaders = new Headers(request.headers);
  const pathname = request.nextUrl.pathname;

  // Create a Supabase client configured to use cookies
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return request.cookies.get(name)?.value;
        },
        set(name: string, value: string, options: any) {
          requestHeaders.append('Set-Cookie', `${name}=${value}; Path=/; HttpOnly; SameSite=Lax`);
        },
        remove(name: string, options: any) {
          requestHeaders.append('Set-Cookie', `${name}=; Max-Age=0; Path=/; HttpOnly; SameSite=Lax`);
        },
      },
    }
  );

  // Get the user's session
  const { data: { session } } = await supabase.auth.getSession();

  // Protect dashboard routes
  if (pathname.startsWith('/dashboard') && !session) {
    // Redirect to login page if not authenticated
    const redirectUrl = new URL('/login', request.url);
    redirectUrl.searchParams.set('redirect', pathname);
    return NextResponse.redirect(redirectUrl);
  }

  // Redirect authenticated users away from auth pages
  if ((pathname === '/login' || pathname === '/register') && session) {
    return NextResponse.redirect(new URL('/dashboard', request.url));
  }

  // Continue with the request
  return NextResponse.next({
    request: {
      headers: requestHeaders,
    },
  });
}

export const config = {
  matcher: [
    // Apply middleware to all routes except static files and API routes
    '/((?!api|_next/static|_next/image|favicon.ico).*)',
  ],
};
```

## Middleware for Route Groups

In a VibeStack application with different route groups (e.g., marketing, app, admin), you can apply specific middleware to each group:

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { createServerClient } from '@supabase/ssr';

export async function middleware(request: NextRequest) {
  const pathname = request.nextUrl.pathname;
  
  // Create Supabase client as shown in previous example
  const supabase = createServerClient(/* config */);
  const { data: { session } } = await supabase.auth.getSession();
  
  // Admin routes - require admin role
  if (pathname.startsWith('/admin')) {
    if (!session) {
      return NextResponse.redirect(new URL('/login', request.url));
    }
    
    // Check for admin role (customize based on your user data structure)
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', session.user.id)
      .single();
      
    if (!profile || profile.role !== 'admin') {
      return NextResponse.redirect(new URL('/dashboard', request.url));
    }
  }
  
  // App routes - require authentication
  if (pathname.startsWith('/app') && !session) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
  
  // API routes - can have their own authentication
  if (pathname.startsWith('/api/protected')) {
    if (!session) {
      return new NextResponse(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }
  }
  
  return NextResponse.next();
}

export const config = {
  matcher: [
    '/admin/:path*',
    '/app/:path*',
    '/api/protected/:path*',
  ],
};
```

## Response Manipulation

Modify responses by setting custom headers:

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // Get response from the origin
  const response = NextResponse.next();
  
  // Add security headers
  response.headers.set('X-Frame-Options', 'DENY');
  response.headers.set('X-Content-Type-Options', 'nosniff');
  response.headers.set('Referrer-Policy', 'origin-when-cross-origin');
  response.headers.set('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
  
  return response;
}
```

## URL Rewriting

Rewrite URLs internally without redirecting:

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const url = request.nextUrl.clone();
  
  // Example: Rewrite /blog/[slug] to /articles/[slug]
  if (url.pathname.startsWith('/blog/')) {
    url.pathname = url.pathname.replace('/blog/', '/articles/');
    return NextResponse.rewrite(url);
  }
  
  return NextResponse.next();
}
```

## Middleware with Edge API Routes

Combining middleware with Edge API routes for optimal performance:

```typescript
// app/api/edge/route.ts
import { NextRequest, NextResponse } from 'next/server';

export const runtime = 'edge';

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const id = searchParams.get('id');
  
  // Process the request with Edge runtime benefits
  const data = { id, message: 'Hello from the Edge!' };
  
  return NextResponse.json(data);
}
```

## Advanced Middleware Patterns

### Rate Limiting

Implement basic rate limiting in middleware:

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// Simple memory-based store (for demo purposes only)
// In production, use Redis or a similar solution
const ipRequestCounts = new Map<string, { count: number, timestamp: number }>();

export function middleware(request: NextRequest) {
  const ip = request.ip || 'unknown';
  
  // Only rate limit API routes
  if (request.nextUrl.pathname.startsWith('/api/')) {
    const now = Date.now();
    const windowMs = 60 * 1000; // 1 minute window
    const maxRequests = 60; // 60 requests per minute
    
    const requestData = ipRequestCounts.get(ip) || { count: 0, timestamp: now };
    
    // Reset counter if outside window
    if (now - requestData.timestamp > windowMs) {
      requestData.count = 0;
      requestData.timestamp = now;
    }
    
    requestData.count++;
    ipRequestCounts.set(ip, requestData);
    
    if (requestData.count > maxRequests) {
      return new NextResponse(
        JSON.stringify({ error: 'Too Many Requests' }),
        { status: 429, headers: { 'Content-Type': 'application/json' } }
      );
    }
  }
  
  return NextResponse.next();
}
```

### A/B Testing

Implement simple A/B testing:

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // Only apply to homepage
  if (request.nextUrl.pathname === '/') {
    const bucket = request.cookies.get('ab-test-bucket')?.value;
    
    // If user doesn't have a bucket, assign one
    if (!bucket) {
      const response = NextResponse.next();
      const experimentBucket = Math.random() < 0.5 ? 'A' : 'B';
      
      // Set cookie with experiment bucket
      response.cookies.set('ab-test-bucket', experimentBucket, {
        maxAge: 60 * 60 * 24 * 7, // 1 week
        path: '/',
      });
      
      // Rewrite to the appropriate variant
      const url = request.nextUrl.clone();
      url.pathname = experimentBucket === 'A' ? '/variant-a' : '/variant-b';
      return NextResponse.rewrite(url);
    }
    
    // User already has a bucket, rewrite to their variant
    const url = request.nextUrl.clone();
    url.pathname = bucket === 'A' ? '/variant-a' : '/variant-b';
    return NextResponse.rewrite(url);
  }
  
  return NextResponse.next();
}
```

## Middleware Limitations

- **Runtime Environment**: Middleware uses the Edge runtime, which has limited Node.js APIs
- **Execution Time**: Limited to 1-2 ms in serverless environments
- **Size Limit**: Code size is limited (1MB including dependencies)
- **Headers Mutation**: Some headers cannot be modified due to HTTP spec
- **Response Body**: Cannot modify the response body directly

## Best Practices

1. **Keep it Light**: Minimize middleware code size and execution time
2. **Use Matchers**: Limit middleware execution to relevant routes only
3. **Avoid Heavy Dependencies**: Don't import large libraries in middleware
4. **Cache When Possible**: Cache results to improve performance
5. **Separate Concerns**: Use different middleware files for different purposes
6. **Error Handling**: Implement proper error handling to avoid silent failures

## Resources

- [Next.js Middleware Documentation](https://nextjs.org/docs/middleware)
- [Edge Runtime](https://edge-runtime.vercel.app/)
- [Supabase Auth Helpers](https://supabase.com/docs/reference/javascript/auth-getuser)
- [Next.js Response Cookies API](https://nextjs.org/docs/app/api-reference/cookies)
- [Vercel Edge Middleware Examples](https://vercel.com/templates/next.js/edge-middleware)
