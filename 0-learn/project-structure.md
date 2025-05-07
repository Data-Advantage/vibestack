## Project Structure

### Full Next.js App Directory Structure

```
app/
├── (auth)/                    # Public auth-related routes (grouped)
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
├── (dashboard)/               # Protected dashboard routes (grouped) - REQUIRES LOGIN
│   ├── dashboard/             # Main dashboard page
│   │   └── page.tsx           # Dashboard main page
│   ├── settings/              # User settings 
│   │   └── page.tsx           # Settings page
│   ├── billing/               # Billing and subscription management
│   │   └── page.tsx           # Billing page
│   ├── [feature]/             # Feature-specific routes
│   │   ├── page.tsx           # Feature page
│   │   └── actions.ts         # Feature-specific server actions
│   └── layout.tsx             # Dashboard layout with navigation
├── (marketing)/               # Public marketing pages (grouped)
│   ├── page.tsx               # Homepage
│   ├── about/                 # About page
│   ├── blog/                  # Blog section
│   │   ├── page.tsx           # Blog listing page
│   │   └── [slug]/            # Individual blog posts
│   │       └── page.tsx       # Blog post template
│   ├── pricing/               # Pricing page
│   ├── contact/               # Contact page
│   └── layout.tsx             # Marketing layout wrapper
├── (seo)/                     # Public SEO-optimized content pages (grouped)
│   ├── layout.tsx             # SEO pages layout wrapper
│   ├── [category]/            # Dynamic category pages
│   │   ├── page.tsx           # Category listing template
│   │   └── [slug]/            # Individual content pages
│   │       └── page.tsx       # Individual page template
│   └── sitemap.xml/           # Dynamic sitemap generation
│       └── route.ts           # Sitemap route handler
├── api/                       # API routes
│   ├── webhooks/              # Public external webhooks (unprotected)
│   │   ├── [service]/route.ts # Service-specific webhook handlers
│   │   └── stripe/route.ts    # Stripe webhook handler
│   └── [domain]/              # Domain-specific API endpoints (some may be protected)
│       └── route.ts           # Route handlers for domain
└── error.tsx                  # Global error page
├── globals.css                # Global styles and Tailwind config
├── layout.tsx                 # Root layout
├── not-found.tsx              # 404 page
├── page.tsx                   # Root page
├── sitemap.ts                 # Built-in Next.js sitemap generation
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
├── dashboard/                  # Dashboard-specific components
│   ├── sidebar-nav.tsx         # Dashboard sidebar navigation
│   ├── header.tsx              # Dashboard header
│   ├── stats-card.tsx          # Statistics display components
│   └── ...                     # Other dashboard components  
├── [domain]/                   # Domain-specific components
│   ├── [component].tsx         # Domain component
├── marketing/                  # Marketing page components
│   ├── hero.tsx                # Main value proposition section
│   ├── features.tsx            # Product features showcase
│   ├── pricing.tsx             # Pricing section components
│   ├── testimonials.tsx        # User testimonials section
│   └── cta.tsx                 # Call-to-action section
├── blog/                       # Blog-related components
│   ├── post-card.tsx           # Blog post card component
│   ├── post-header.tsx         # Blog post header
│   ├── code-block.tsx          # Syntax highlighting for code
│   └── mdx-components.tsx      # Custom MDX component renderers
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
├── stripe/                    # Stripe integration
│   ├── client.ts              # Stripe client setup
│   └── utils.ts               # Helpers for Stripe operations
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

config/                        # Application configuration
├── site.ts                    # Site-wide information and metadata
├── features.ts                # Feature flags and configuration
├── pricing.ts                 # Pricing tiers and feature matrices
└── navigation.ts              # Navigation structure

content/                       # MDX content (optional)
├── blog/                      # Blog posts in MDX format
│   ├── post-1.mdx             # Individual blog post
│   └── ...                    # Additional blog posts
├── docs/                      # Documentation in MDX format
│   ├── getting-started.mdx    # Getting started guide
│   └── ...                    # Additional documentation pages
└── _schemas/                  # Content validation schemas
    └── blog-post.ts           # Schema for blog post frontmatter

types/                         # TypeScript type definitions
├── supabase.ts                # Generated Supabase database types
├── api/                       # API-related types
│   ├── requests.ts            # Request types for API endpoints
│   └── responses.ts           # Response types for API endpoints
├── forms/                     # Form-related types
│   └── [domain].ts            # Domain-specific form types
└── [domain]/                  # Domain-specific types
    └── index.ts               # Domain type exports

public/                        # Static assets (only if needed - mostly use Vercel Storage Blob Store or Supabase Storage)
├── logo.svg                   # Primary brand logo (light mode)
├── logo-dark.svg              # Dark mode variant of the logo
├── logo-mark.svg              # Symbol/icon-only version of the logo
├── robots.txt                 # Instructions for search engine crawlers
└── ...                        # Other static assets

.env.example                   # Documentation artifact
middleware.ts                  # Simple middleware that checks auth for dashboard routes only
next.config.js                 # Next.js configuration
postcss.config.mjs             # Configuration for PostCSS
tsconfig.json                  # TypeScript configuration
```

### Files to NOT Create with V0

```
public/
├── favicon.ico                # Main favicon for browser tabs
├── apple-touch-icon.png       # Icon for iOS when added to home screen (180x180px)
```