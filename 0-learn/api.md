# API Development

Application Programming Interfaces (APIs) are a crucial component of modern web applications, allowing different software systems to communicate with each other. In VibeStack applications, APIs enable seamless data exchange between frontend, backend, and third-party services.

## Introduction to API Development

An API defines the methods and data formats that applications can use to request and exchange information. Key concepts include:

- **Endpoints**: URLs that represent specific functions or resources
- **HTTP Methods**: Actions (GET, POST, PUT, DELETE) that define operations
- **Request/Response Format**: Typically JSON for modern web APIs
- **Authentication**: Methods to verify API consumers
- **Status Codes**: Standardized responses indicating success or failure

## API Types in VibeStack

### REST APIs

Representational State Transfer (REST) is the most common API architecture for web applications:

- **Resource-Based**: URLs represent resources (e.g., `/users`, `/products`)
- **Stateless**: Each request contains all information needed for the server to fulfill it
- **Standard HTTP Methods**: GET (read), POST (create), PUT/PATCH (update), DELETE (remove)
- **Status Codes**: 2xx (success), 4xx (client error), 5xx (server error)

### GraphQL APIs

GraphQL offers an alternative approach with specific advantages:

- **Single Endpoint**: Typically a single `/graphql` endpoint
- **Client-Specified Data**: Clients request exactly what they need
- **Strongly Typed**: Schema defines available types and operations
- **Reduced Overfetching**: Only required data is returned

### RPC-Style APIs

Remote Procedure Call APIs treat endpoints as function calls:

- **Action-Based**: Endpoints represent actions rather than resources
- **Typically POST**: Most operations use POST method with action in URL or body
- **Used in tRPC**: Type-safe RPC library popular in TypeScript ecosystems

## Implementing APIs in Next.js

### Route Handlers (App Router)

Next.js App Router provides a straightforward way to create API endpoints:

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function GET(request: NextRequest) {
  const supabase = createClient();
  const { searchParams } = new URL(request.url);
  const role = searchParams.get('role');
  
  const query = supabase.from('users').select('id, name, email');
  
  // Apply optional filtering
  if (role) {
    query.eq('role', role);
  }
  
  const { data, error } = await query;
  
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
  
  return NextResponse.json({ users: data });
}

export async function POST(request: NextRequest) {
  try {
    const supabase = createClient();
    const userData = await request.json();
    
    const { data, error } = await supabase
      .from('users')
      .insert(userData)
      .select('id, name, email')
      .single();
    
    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }
    
    return NextResponse.json({ user: data }, { status: 201 });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
```

### Dynamic Route Handlers

For resource-specific operations:

```typescript
// app/api/users/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  const supabase = createClient();
  const { id } = params;
  
  const { data, error } = await supabase
    .from('users')
    .select('id, name, email, profile')
    .eq('id', id)
    .single();
  
  if (error) {
    return NextResponse.json(
      { error: error.message },
      { status: error.code === 'PGRST116' ? 404 : 500 }
    );
  }
  
  return NextResponse.json({ user: data });
}

export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  const supabase = createClient();
  const { id } = params;
  const updates = await request.json();
  
  const { data, error } = await supabase
    .from('users')
    .update(updates)
    .eq('id', id)
    .select('id, name, email')
    .single();
  
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }
  
  return NextResponse.json({ user: data });
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  const supabase = createClient();
  const { id } = params;
  
  const { error } = await supabase
    .from('users')
    .delete()
    .eq('id', id);
  
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }
  
  return new NextResponse(null, { status: 204 });
}
```

### Server Actions (Alternative Approach)

Next.js Server Actions provide an RPC-like approach:

```typescript
// app/actions/users.ts
'use server'

import { createClient } from '@/lib/supabase/server';
import { revalidatePath } from 'next/cache';
import { z } from 'zod';

const userSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  role: z.enum(['user', 'admin']).default('user')
});

export async function createUser(formData: FormData) {
  const supabase = createClient();
  
  try {
    // Validate input
    const userData = userSchema.parse({
      name: formData.get('name'),
      email: formData.get('email'),
      role: formData.get('role')
    });
    
    // Create user
    const { data, error } = await supabase
      .from('users')
      .insert(userData)
      .select('id, name, email')
      .single();
    
    if (error) throw new Error(error.message);
    
    // Revalidate cache
    revalidatePath('/users');
    
    return { success: true, user: data };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}
```

## API Authentication

### Using Supabase Auth

```typescript
// app/api/protected/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function GET(request: NextRequest) {
  const supabase = createClient();
  
  // Check if user is authenticated
  const { data: { session } } = await supabase.auth.getSession();
  
  if (!session) {
    return NextResponse.json(
      { error: 'Unauthorized' },
      { status: 401 }
    );
  }
  
  // Access user-specific data
  const { data, error } = await supabase
    .from('user_items')
    .select('*')
    .eq('user_id', session.user.id);
  
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
  
  return NextResponse.json({ items: data });
}
```

### API Key Authentication

For service-to-service or external API consumers:

```typescript
// app/api/external/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { headers } from 'next/headers';

export async function GET(request: NextRequest) {
  const apiKey = headers().get('x-api-key');
  
  // Validate API key
  if (apiKey !== process.env.EXTERNAL_API_KEY) {
    return NextResponse.json(
      { error: 'Unauthorized' },
      { status: 401 }
    );
  }
  
  // Process authorized request
  // ...
  
  return NextResponse.json({ data: 'Secured data' });
}
```

## Error Handling

Implement consistent error responses:

```typescript
// lib/api-errors.ts
export class ApiError extends Error {
  status: number;
  
  constructor(message: string, status: number = 500) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
  }
}

export function handleApiError(error: unknown) {
  console.error('API Error:', error);
  
  if (error instanceof ApiError) {
    return NextResponse.json(
      { error: error.message },
      { status: error.status }
    );
  }
  
  return NextResponse.json(
    { error: 'Internal Server Error' },
    { status: 500 }
  );
}
```

Usage in route handler:

```typescript
// app/api/example/route.ts
import { NextRequest } from 'next/server';
import { ApiError, handleApiError } from '@/lib/api-errors';

export async function GET(request: NextRequest) {
  try {
    // Check for required parameter
    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    
    if (!id) {
      throw new ApiError('Missing required parameter: id', 400);
    }
    
    // Implementation continues...
    
  } catch (error) {
    return handleApiError(error);
  }
}
```

## Request Validation

Using Zod for robust request validation:

```typescript
// app/api/products/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';

const productSchema = z.object({
  name: z.string().min(2).max(100),
  price: z.number().positive(),
  category: z.string(),
  inStock: z.boolean().default(true)
});

type Product = z.infer<typeof productSchema>;

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    
    // Validate request body
    const validatedData = productSchema.parse(body);
    
    // Process the validated data
    // ...
    
    return NextResponse.json({ success: true, product: validatedData }, { status: 201 });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Validation Error', details: error.errors },
        { status: 400 }
      );
    }
    
    return NextResponse.json(
      { error: 'Internal Server Error' },
      { status: 500 }
    );
  }
}
```

## API Documentation

### OpenAPI Specification

Document your APIs using OpenAPI (formerly Swagger):

```typescript
// app/api/docs/route.ts
import { NextResponse } from 'next/server';

export function GET() {
  const openApiSpec = {
    openapi: '3.0.0',
    info: {
      title: 'VibeStack API',
      version: '1.0.0',
      description: 'API documentation for VibeStack'
    },
    paths: {
      '/api/users': {
        get: {
          summary: 'Get all users',
          parameters: [
            {
              name: 'role',
              in: 'query',
              schema: { type: 'string' },
              description: 'Filter by user role'
            }
          ],
          responses: {
            '200': {
              description: 'List of users',
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    properties: {
                      users: {
                        type: 'array',
                        items: { $ref: '#/components/schemas/User' }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      // Other endpoints...
    },
    components: {
      schemas: {
        User: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            name: { type: 'string' },
            email: { type: 'string', format: 'email' },
            role: { type: 'string', enum: ['user', 'admin'] }
          }
        }
      }
    }
  };
  
  return NextResponse.json(openApiSpec);
}
```

## API Best Practices

1. **Versioning**: Include version in URL path (`/api/v1/users`) or header
2. **Pagination**: Implement standard pagination for collection endpoints
3. **Filtering & Sorting**: Allow clients to filter and sort collection results
4. **Rate Limiting**: Protect your API from abuse with rate limits
5. **CORS**: Configure proper Cross-Origin Resource Sharing
6. **Content Negotiation**: Support different content types (usually JSON)
7. **Response Shaping**: Allow clients to specify fields to include/exclude
8. **Caching**: Implement HTTP caching with appropriate headers

### Pagination Example

```typescript
// app/api/articles/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export async function GET(request: NextRequest) {
  const supabase = createClient();
  const { searchParams } = new URL(request.url);
  
  // Pagination parameters
  const page = parseInt(searchParams.get('page') || '1');
  const limit = parseInt(searchParams.get('limit') || '20');
  const offset = (page - 1) * limit;
  
  // Filtering parameters
  const category = searchParams.get('category');
  
  // Sorting parameters
  const sortBy = searchParams.get('sort_by') || 'created_at';
  const sortOrder = searchParams.get('sort_order') || 'desc';
  
  // Build query
  let query = supabase.from('articles').select('*', { count: 'exact' });
  
  // Apply filters
  if (category) {
    query = query.eq('category', category);
  }
  
  // Apply pagination and sorting
  query = query
    .order(sortBy, { ascending: sortOrder === 'asc' })
    .range(offset, offset + limit - 1);
  
  // Execute query
  const { data, error, count } = await query;
  
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
  
  // Calculate pagination info
  const totalPages = count ? Math.ceil(count / limit) : 0;
  const hasNext = page < totalPages;
  const hasPrevious = page > 1;
  
  return NextResponse.json({
    data,
    pagination: {
      page,
      limit,
      total: count,
      totalPages,
      hasNext,
      hasPrevious
    }
  });
}
```

## Testing APIs

### Using Jest and Supertest

```typescript
// __tests__/api/users.test.ts
import { createMocks } from 'node-mocks-http';
import { GET, POST } from '@/app/api/users/route';

jest.mock('@/lib/supabase/server', () => ({
  createClient: jest.fn(() => ({
    from: jest.fn(() => ({
      select: jest.fn(() => ({
        eq: jest.fn(() => ({
          data: [{ id: '1', name: 'Test User', email: 'test@example.com' }],
          error: null
        })),
        data: [{ id: '1', name: 'Test User', email: 'test@example.com' }],
        error: null
      })),
      insert: jest.fn(() => ({
        select: jest.fn(() => ({
          single: jest.fn(() => ({
            data: { id: '1', name: 'New User', email: 'new@example.com' },
            error: null
          }))
        }))
      }))
    }))
  }))
}));

describe('Users API', () => {
  it('GET /api/users should return users list', async () => {
    const { req, res } = createMocks({
      method: 'GET',
      url: '/api/users'
    });
    
    await GET(req);
    
    expect(res._getStatusCode()).toBe(200);
    expect(JSON.parse(res._getData())).toEqual({
      users: [{ id: '1', name: 'Test User', email: 'test@example.com' }]
    });
  });
  
  it('POST /api/users should create a new user', async () => {
    const { req, res } = createMocks({
      method: 'POST',
      url: '/api/users',
      body: {
        name: 'New User',
        email: 'new@example.com'
      }
    });
    
    await POST(req);
    
    expect(res._getStatusCode()).toBe(201);
    expect(JSON.parse(res._getData())).toEqual({
      user: { id: '1', name: 'New User', email: 'new@example.com' }
    });
  });
});
```

## Resources

- [Next.js API Routes Documentation](https://nextjs.org/docs/app/building-your-application/routing/route-handlers)
- [RESTful API Design Guidelines](https://restfulapi.net/)
- [Supabase JavaScript API Reference](https://supabase.com/docs/reference/javascript/introduction)
- [OpenAPI Specification](https://swagger.io/specification/)
- [JSON:API Specification](https://jsonapi.org/)
- [GraphQL Documentation](https://graphql.org/learn/)
