**IMPORTANT**: _Dear v0.dev_ agent: you must pay attention to this guide and implement it as best as you can!

# Next.js & Supabase Application Development Guide

## Core Technology Stack

### Frontend
- TypeScript as the primary language
- React 19+ for UI components
- Next.js 15+ (with App Router) for routing and server components
- Tailwind CSS v4 for styling
- shadcn/ui for component library (based on Radix UI primitives)

#### Frontend component details
- Standard UI components should be built with https://ui.shadcn.com/docs/components
- shadcn/ui components should be styled with `new-york`
- Sidebars should be built with https://ui.shadcn.com/blocks/sidebar
- Authentication should be built with https://ui.shadcn.com/blocks/login
- Charts should be built with https://ui.shadcn.com/charts
- Themes should be built with https://ui.shadcn.com/colors
- Toasts should be built with sonner https://ui.shadcn.com/docs/components/sonner not https://ui.shadcn.com/docs/components/toast

#### Frontend theming details
- Add an `@import "tailwindcss";` to `./app/globals.css` that imports Tailwind CSS.
- Create a `postcss.config.mjs` file with the Tailwind v4 plugin:
  ```js
  export default {
    plugins: {
      '@tailwindcss/postcss': {},
    },
  }
  ```
- Install Tailwind v4: `npm install -D tailwindcss @tailwindcss/postcss postcss`
- Tailwind v4 requires zero configuration by default, but a `tailwind.config.ts` file is still useful for:
  - Customizing theme colors and other design tokens
  - Specifying content paths
  - Enabling features like dark mode
- Use CSS variables for theming in `globals.css` to support shadcn/ui components and dark mode
  - Example: `--primary: 240 5.9% 10%;` for HSL values
- Place `globals.css` in the `app/` directory when using App Router
- Import it in your root layout.tsx file

### Backend
- Supabase for PostgreSQL database
- Supabase for authentication and user management
- Supabase for row-level security policies
- Supabase for user uploads
- Supabase for realtime subscriptions when needed

### Files
- Vercel Storage Blob Store for static images, documents, & files such as logos, diagrams, photos, and downloades embedded on the website as resources
- Appropriate filename prefixes such as `logo-dataadvantage.png` or `avatar-johnsmith.svg`
- Supabase Storage for user generated or user requested images, documents, & files

### Deployment
- Vercel for hosting & CDN
- Vercel for environment variable management
- Vercel for preview deployments

## Application Architecture

### Content & Interactive Requirements
- Static marketing/informational pages with strong SEO optimization
- Protected app areas behind authentication
- Real-time interactive components using Supabase subscriptions
- Progressive enhancement where static content becomes interactive after hydration

### SEO Optimization
- Implement Next.js Metadata API for title, description, and OpenGraph tags
- Create a reusable SEO component for consistent metadata across pages
- Use `next/image` with proper alt text and loading attributes
- Implement server-side rendering for dynamic but SEO-important pages
- Set up proper canonical URLs and sitemap.xml generation

### Accessibility (a11y) Standards
- **Semantic HTML**: Use appropriate HTML elements (`<nav>`, `<main>`, `<section>`, `<button>`, etc.) rather than generic `<div>` tags
- **ARIA Attributes**: Implement ARIA roles, states, and properties for dynamic content and custom components
- **Keyboard Navigation**: Ensure all interactive elements are keyboard accessible with proper focus states
- **Focus Management**: Implement proper focus management for modals, drawers, and other interactive components
- **Color Contrast**: Maintain WCAG AA standard (minimum 4.5:1 for normal text, 3:1 for large text)
- **Screen Reader Support**: Test with screen readers and provide text alternatives for non-text content
- **Responsive Design**: Ensure the application works across devices and zoom levels
- **Form Accessibility**: Include proper labels, error messages, and validation feedback

### Responsive Mobile Development
- **Mobile-First Approach**: Design for mobile devices first, then progressively enhance for larger screens
- **Fluid Typography**: Implement responsive font sizing using `clamp()` or Tailwind's responsive modifiers
- **Touch Targets**: Ensure interactive elements are at least 44x44px for comfortable touch interactions
- **Viewport Configuration**: Set proper meta viewport tag (`content="width=device-width, initial-scale=1"`)
- **Breakpoint Strategy**: 
  - Define consistent breakpoints (sm: 640px, md: 768px, lg: 1024px, xl: 1280px, 2xl: 1536px)
  - Use Tailwind's responsive prefixes (`sm:`, `md:`, `lg:`, etc.) consistently
- **Navigation Patterns**: Implement mobile-appropriate navigation (bottom bars, hamburger menus, etc.)
- **Gesture Support**: Consider touch gestures (swipe, pinch, etc.) for enhanced mobile UX
- **Responsive Images**: Use `next/image` with proper sizing and responsive variants
- **Offline Support**: Implement service workers for offline capabilities when appropriate
- **Performance Budgets**: Set stricter performance budgets for mobile devices

### Performance Considerations
- Prioritize Core Web Vitals for both content and app sections
- Implement proper code splitting to keep initial load fast
- Use deferred loading for app features on content-heavy pages
- Implement React Suspense for loading states
- Optimize for mobile networks with reduced payload sizes
- Implement progressive loading strategies for mobile users

## Project Structure

### Next.js App Directory Structure

```
app/
├── (auth)/                    # Auth-related routes (grouped)
│   ├── login/                 # Login page
│   │   ├── page.tsx           # Login page component
│   │   └── actions.ts         # Server actions for auth login
│   ├── signup/                # Sign up page
│   │   ├── page.tsx           # Sign up page component
│   │   └── actions.ts         # Server actions for sign up
│   ├── confirm/               # Email verification
│   │   └── route.ts           # Email confirmation route handler
│   ├── reset-password/        # Password reset flow
│   │   ├── page.tsx           # Reset password page
│   │   └── actions.ts         # Password reset actions
│   └── layout.tsx             # Auth layout wrapper
├── (marketing)/               # Marketing pages (grouped)
│   ├── page.tsx               # Homepage
│   ├── about/                 # About page
│   ├── pricing/               # Pricing page
│   ├── contact/               # Contact page
│   └── layout.tsx             # Marketing layout wrapper
├── dashboard/                 # App dashboard (protected)
│   ├── page.tsx               # Dashboard main page
│   ├── layout.tsx             # Dashboard layout with navigation
│   └── [feature]/             # Feature-specific routes
│       ├── page.tsx           # Feature page
│       └── actions.ts         # Feature-specific server actions
├── api/                       # API routes
│   ├── webhooks/              # External webhooks (unprotected)
│   │   └── [service]/route.ts # Service-specific webhook handlers
│   └── [domain]/              # Domain-specific API endpoints
│       └── route.ts           # Route handlers for domain
└── error.tsx                  # Global error page
├── globals.css                # Global styles and Tailwind config
├── layout.tsx                 # Root layout
├── not-found.tsx              # 404 page
├── page.tsx                   # Root page
```

### Supporting Directories

```
components/                     # React components
├── ui/                         # UI primitives (shadcn)
│   ├── button.tsx              # Button component
│   ├── form.tsx                # Form components
│   ├── input.tsx               # Input component
│   └── ...                     # Other shadcn components
├── auth/                       # Auth-specific components
│   ├── login-form.tsx          # Login form component
│   ├── signup-form.tsx         # Signup form component
│   └── password-reset-form.tsx # Password reset form
├── [domain]/                   # Domain-specific components
│   ├── [component].tsx         # Domain component
│   └── ...                     # Other domain components
├── layout/                     # Layout components
│   ├── header.tsx              # Site header
│   ├── footer.tsx              # Site footer
│   ├── sidebar.tsx             # Sidebar navigation
│   └── ...                     # Other layout components
└── providers/                  # React context providers
    ├── auth-provider.tsx       # Auth state provider
    └── theme-provider.tsx      # Theme provider

lib/                           # Utility functions and services
├── supabase/                  # Supabase client setup
│   ├── client.ts              # Browser client for Client Components
│   ├── server.ts              # Server client for Server Components
│   ├── middleware.ts          # Auth refresh helpers for middleware
│   ├── admin.ts               # Admin client (server-side only)
│   └── types.ts               # Re-exports of generated types
├── actions/                   # Centralized server actions
│   ├── auth.ts                # Auth-related actions
│   └── [domain].ts            # Domain-specific actions
├── utils/                     # General utility functions
│   ├── formatting.ts          # Date, number, text formatting
│   ├── validation.ts          # Input validation helpers
│   └── ...                    # Other utilities
├── hooks/                     # Custom React hooks
│   ├── use-auth.ts            # Auth-related hooks
│   ├── use-form.ts            # Form handling hooks
│   ├── use-[domain].ts        # Domain-specific hooks
│   └── ...                    # Other hooks
└── constants/                 # Application constants
    ├── routes.ts              # Route definitions
    └── config.ts              # App configuration constants

types/                         # TypeScript type definitions
├── supabase.ts                # Generated Supabase database types
├── api/                       # API-related types
│   ├── requests.ts            # Request types for API endpoints
│   └── responses.ts           # Response types for API endpoints
├── forms/                     # Form-related types
│   └── [domain].ts            # Domain-specific form types
└── [domain]/                  # Domain-specific types
    └── index.ts               # Domain type exports

public/                        # Static assets (if needed mostly on Vercel Storage Blob Store)
└── ...                        # Other static assets

middleware.ts                  # Root Next.js middleware for auth protection
next.config.js                 # Next.js configuration
postcss.config.mjs             # Configuration for PostCSS
tailwind.config.js             # Tailwind CSS configuration
tsconfig.json                  # TypeScript configuration
```

## Component Architecture

### Component Organization Strategy
| Category | Purpose | Examples |
|----------|---------|----------|
| **UI Components** | Reusable presentation components | Buttons, Cards, Inputs, Modals |
| **Domain Components** | Feature-specific components | UserProfile, InvoiceForm, ProductCard |
| **Layout Components** | Page structure components | Header, Footer, Sidebar, PageContainer |
| **Provider Components** | Context providers | AuthProvider, ThemeProvider, SettingsProvider |
| **Composite Components** | Composed of multiple components | SignupForm, DashboardStats, UserTable |

### Server vs. Client Components
- **Server Components**:
  - Data fetching directly from the database
  - SEO-critical content rendering
  - Static or rarely changing content
  - Components that don't need interactivity

- **Client Components**:
  - Interactive UI elements (use `"use client"` directive)
  - Form handling
  - State-dependent rendering
  - Event handling
  - Components using browser APIs

## State Management

### Best Practices
- **Local Component State**: Use `useState` for component-specific state
- **Form State**: Use React Hook Form for form state management
- **Global State**: Use context providers for authentication, theme, etc.
- **Server State**: Use React Query or SWR for remote data management
- **URL State**: Store filter/search parameters in the URL for shareable states
- **Feature-Specific State**: Create domain-specific context providers when needed
- **State Persistence**: Use local storage for user preferences

### Data Fetching Patterns
- **Custom Hooks**: Create domain-specific React Query hooks
- **Query Keys**: Use consistent query key structure for caching
- **Mutations**: Implement optimistic updates for better UX
- **Loading States**: Handle loading, error, and success states
- **Error Handling**: Implement toast notifications for errors
- **Pagination**: Support paginated data with cursor or offset pagination

## Supabase Implementation

### Schema Organization

#### Reserved Schemas
- Respect Supabase's built-in schemas: `auth`, `storage`, `graphql`, `realtime`, and `supabase_functions`
- These are managed by Supabase and have special purposes

#### Custom Schema Structure
- Avoid using the `public` schema for user data
- Create purpose-specific schemas:
  - `api` for user-generated content and application data
  - `reference` for publicly available lookup tables
  - `analytics` for reporting data
  - `audit` for tracking changes

### Table Structure Best Practices

#### User Profiles
- Store extended user data in `api.profiles`, not directly in `auth.users`
- Link profiles to auth users with a foreign key reference
- Apply Row Level Security (RLS) policies for user data protection

#### User-Generated Content
- Store in the `api` schema (e.g., `api.posts`, `api.comments`)
- Always include a `user_id` column to track ownership
- Apply appropriate RLS policies based on ownership and visibility rules

### Row Level Security (RLS)

#### General RLS Best Practices
- Enable RLS on all tables storing user data
- Create specific policies for each operation type (SELECT, INSERT, UPDATE, DELETE)
- Use `auth.uid()` function to identify the authenticated user
- Start with restrictive policies, then add permissions as needed

#### Common Policy Patterns
- Ownership-based access: Users can only access their own data
- Role-based access: Permissions based on user roles (admin, moderator, etc.)
- Relationship-based access: Access based on team membership or other relationships

### Storage Implementation

#### Storage Buckets
- Create separate buckets based on access patterns:
  - `public` for openly accessible files
  - `protected` for authenticated-only access
  - `private` for user-specific private files
  
#### Storage RLS
- Apply RLS policies to storage buckets to control file access
- Control file uploads based on user identity and file location
- Set up policies for viewing, uploading, and deleting files

## Authentication & Authorization

### Implementation
- Implement Supabase Auth with email/password
- Create middleware for protected routes
- Set up proper row-level security policies in Supabase

### Server-Side Auth Setup

Supabase Auth is fully compatible with SSR in Next.js. The implementation requires storing user sessions in cookies instead of localStorage.

#### Required Packages
- `@supabase/supabase-js` and `@supabase/ssr` (replaces the older Auth Helpers package)

#### Environment Variables Setup
NEXT_PUBLIC_SUPABASE_URL=<your_supabase_project_url>
NEXT_PUBLIC_SUPABASE_ANON_KEY=<your_supabase_anon_key>

### Client Utilities Structure
- Create `utils/supabase/client.ts` for Client Components
- Create `utils/supabase/server.ts` for Server Components and Actions
- Create `utils/supabase/middleware.ts` for auth token refreshing

#### Client Creation Pattern

- **Create New Clients Per Request**: Each server component, server action, or API route should create a fresh Supabase client
- **Lightweight Operation**: Creating a client is an inexpensive operation that properly maintains auth context
- **Server Context**: Server clients need request-specific cookies for proper authentication state
- **Client Singleton**: The browser client automatically implements a singleton pattern

#### Client side
```utils/supabase/client.ts
import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
```

#### Server-side
```utils/supabase/server.ts
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()

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

#### Middleware
In Next.js, because Server Components cannot set cookies, you'll also need a middleware client to handle cookie refreshes. The middleware should run before every route that needs access to Supabase, or that is protected by Supabase Auth.
```
import { type NextRequest } from 'next/server'
import { updateSession } from '@/utils/supabase/middleware'

export async function middleware(request: NextRequest) {
  return await updateSession(request)
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * Feel free to modify this pattern to include more paths.
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
```

### Client Creation Pattern

- **Create New Clients Per Request**: Each server component, server action, or API route should create a fresh Supabase client
- **Lightweight Operation**: Creating a Supabase client is an inexpensive operation that properly maintains auth context
- **Server Context**: Server clients need request-specific cookies for proper authentication state
- **Client Singleton**: The browser client automatically implements a singleton pattern regardless of how many times you call the creation function

### Cookie Handling Implementation

The `cookies` object in your Supabase utility functions serves several important purposes:

- Enables the Supabase client to read/write session data to cookies instead of localStorage
- Makes auth state accessible on both client and server sides
- Allows proper session refreshing through middleware
- Maintains a consistent authentication state across page navigations

The session cookie is named `sb-<project_ref>-auth-token` by default.

### Middleware Implementation
- Configure root-level `middleware.ts` using `updateSession`
- Set up appropriate matchers to exclude static assets
- Implement automatic session refreshing

### Authentication Patterns
- Implement server actions for login, signup, and OAuth flows
- Create email verification route handler at `app/auth/confirm/route.ts`
- Configure OAuth providers in Supabase Dashboard

### Protected Routes
- For Server Components:
```tsx
// Example for a protected page
export default async function ProtectedPage() {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.getUser();
  
  if (error || !data?.user) {
    redirect('/login');
  }
  
  return <p>Protected content for {data.user.email}</p>;
}
- For Client Components:
  - Create a custom hook for auth state
  - Implement appropriate redirection logic
  - Use Supabase's realtime capabilities for instant auth state updates

### Security Best Practices
- Always use `getUser()` not `getSession()` on server-side
- Configure proper Row Level Security policies
- Set up secure HTTP headers in Next.js config
- Implement proper CSRF protection

## API Development

### Route Handler Pattern
- **Request Validation**: Validate incoming requests with Zod or similar
- **Authentication**: Verify user session in each protected endpoint
- **Error Handling**: Implement consistent error response format
- **Response Formatting**: Use consistent JSON structure for responses
- **HTTP Methods**: Implement proper HTTP methods (GET, POST, PUT, DELETE)
- **Status Codes**: Use appropriate HTTP status codes for different scenarios

## TypeScript Best Practices

### Type System Organization
- **Database Types**: Generate and maintain Supabase database types
- **Domain Types**: Create domain-specific type definitions extending database types
- **API Types**: Define request/response types for API endpoints
- **Shared Types**: Place common types in a central location
- **Form Types**: Create specialized types for form state and validation
- **Enums**: Define string literal unions for type-safe enumerations

## Implementation Roadmap

## Phase 1: Project Foundation (Initial Prompt)
1. Create a new Next.js 15 project with TypeScript and App Router
2. Set up Tailwind CSS v4 and basic configuration
3. Create basic directory structure following the document's architecture
4. Set up the Inter font from Google Fonts:  `import { Inter } from "next/font/google"`
5. Implement root layout with basic HTML structure
6. Create a simple homepage in the marketing section
7. Test and validate the initial setup works

## Phase 2: Authentication Framework (Second Prompt)
1. Set up Supabase project and capture credentials
2. Implement auth utilities (client.ts, server.ts, middleware.ts)
3. Create middleware.ts for session handling
4. Build basic login and register pages with forms
5. Implement server actions for authentication flows
6. Test user registration and login functionality

## Phase 3: Core UI Components (Third Prompt)
1. Install and configure shadcn/ui
2. Build essential UI components:
   - Button, Input, Form components
   - Navbar/Header component
   - Page container and layout components
3. Create a responsive layout structure with mobile-first approach
4. Create adaptive navigation components for different screen sizes
5. Implement dark/light mode theming
6. Implement accessibility features (skip links, focus management, ARIA attributes)

## Phase 4: Protected Dashboard (Fourth Prompt)
1. Create dashboard layout with navigation
2. Implement protected routes logic
3. Build user profile page with data from Supabase
4. Create simple dashboard homepage with user info
5. Test authentication flow and protection

## Phase 5: Database and Data Management (Fifth Prompt)
1. Design initial database schema for core functionality
2. Implement Row Level Security policies
3. Create type definitions based on database schema
4. Build data hooks for fetching from Supabase
5. Implement basic CRUD functionality
6. Test data operations with authentication

## Phase 6: Feature Development (Subsequent Prompts)
1. Define specific feature requirements
2. Design component architecture for the feature
3. Implement backend data structures
4. Build UI components and interactions
5. Connect to Supabase data sources
6. Test feature functionality end-to-end

## Phase 7: Analytics Implementation
1. Install Google Analytics with `import { GoogleAnalytics } from "@next/third-parties/google"`