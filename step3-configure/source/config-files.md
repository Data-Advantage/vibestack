# Configuration Files

This document outlines the essential configuration files needed for a Next.js 15+ and Supabase application with Tailwind CSS v4.

## Environment Variables

### .env.example

```
# Authentication Redirect URLs
NEXT_PUBLIC_SITE_URL=http://sara...s-ai.vercel.app
NEXT_PUBLIC_AUTH_REDIRECT_URL=http://sara...s-ai:3000/auth/callback

# Supabase Configuration (usually installed via Vercel-Supabase integration)
NEXT_PUBLIC_SUPABASE_URL=https://qify...dzxs.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJh...jyK8
SUPABASE_SERVICE_ROLE_KEY=eyJh...F12o
POSTGRES_URL=postgres://postgres.qjfy...dzxs:Pj7d...HWGT@aws-0-us-west-1.pooler.supabase.com:6543/postgres?sslmode=require&supa=base-pooler.x
POSTGRES_PRISMA_URL=postgres://postgres.qjfy...dzxs:Pj7d...HWGT@aws-0-us-west-1.pooler.supabase.com:6543/postgres?sslmode=require&supa=base-pooler.x
POSTGRES_URL_NON_POOLING=postgres://postgres.qjfy...dzxs:Pj7d...HWGT@aws-0-us-west-1.pooler.supabase.com:5432/postgres?sslmode=require
POSTGRES_USER=postgres
POSTGRES_PASSWORD=Pj7d...HWGT
POSTGRES_DATABASE=postgres
POSTGRES_HOST=db.qjfy...dzxs.supabase.co

# Stripe Integration (if applicable)
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_51R6...ELpo
STRIPE_SECRET_KEY=sk_test_51R6...dxumE
STRIPE_WEBHOOK_SECRET=whsec_hb4D...R1Qq
NEXT_PUBLIC_STRIPE_PRICE_MONTHLY=price_1R6f...xgAYF
NEXT_PUBLIC_STRIPE_PRICE_YEARLY=price_1R6...fTPn
STRIPE_PRODUCT_ID=prod_S0gz...KxPU

# AI Integration (if applicable)
OPENAI_API_KEY=sk-MjR0...wX6C
GEMINI_API_KEY=AJza...ofog
```

## Tailwind CSS Setup

### tailwind.config.ts
- Minimal configuration required for Tailwind v4
- Include content paths to your application files
- Enable dark mode with `darkMode: ["class", '[data-theme="dark"]']`
- Extend theme colors to support shadcn/ui components with CSS variables

### postcss.config.mjs
- Configure with Tailwind v4 plugin:
  ```js
  export default {
    plugins: {
      '@tailwindcss/postcss': {},
    },
  }
  ```

### globals.css
- Import Tailwind CSS with `@import "tailwindcss";`
- Include CSS variables for theming that support shadcn/ui components
- Define light and dark theme color palettes using HSL values
- Place in `app/` directory and import in root layout

## Core Configuration Files

### next.config.js
- Configure image domains for external images (including Supabase)
- Add security headers
- Enable experimental features as needed
- Configure redirects and rewrites if necessary

### tsconfig.json
- Use Next.js recommended TypeScript settings
- Set paths alias for easier imports (`@/*`)
- Include Next.js types
- Configure strict mode for better type safety

### middleware.ts
- Implement authentication session refresh logic
- Configure route matching pattern to exclude static assets

## Environment Variables

### .env.example
- Supabase configuration:
  - `NEXT_PUBLIC_SUPABASE_URL`
  - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
  - `SUPABASE_SERVICE_ROLE_KEY` (for admin operations, not exposed to client)
- Application configuration:
  - `NEXT_PUBLIC_SITE_URL`
- Analytics integration (if applicable)

## Package Dependencies

### Key Dependencies
- **Core**: next, react, react-dom
- **Supabase**: @supabase/supabase-js, @supabase/ssr
- **UI**: tailwindcss, @tailwindcss/postcss, shadcn/ui components
- **Utilities**: zod, clsx, tailwind-merge
- **Notifications**: sonner (preferred over toast)

### Installation Steps
1. Install Next.js, React, and Supabase core dependencies
2. Install Tailwind CSS v4 and PostCSS
3. Initialize shadcn/ui with the "new-york" style
4. Add utility packages for form validation and class merging

Remember that specific versions and exact implementations will change over time. Focus on understanding the configuration principles rather than copying exact code snippets.

# Sitemap

Example code

```typescript:app/sitemap.ts
import { MetadataRoute } from 'next';

export default function sitemap(): MetadataRoute.Sitemap {
  // For static routes
  const staticRoutes = [
    {
      url: 'https://yourdomain.com',
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 1,
    },
    {
      url: 'https://yourdomain.com/about',
      lastModified: new Date(),
      changeFrequency: 'monthly',
      priority: 0.8,
    },
    {
      url: 'https://yourdomain.com/pricing',
      lastModified: new Date(), 
      changeFrequency: 'weekly',
      priority: 0.9,
    },
    {
      url: 'https://yourdomain.com/contact',
      lastModified: new Date(),
      changeFrequency: 'monthly',
      priority: 0.7,
    },
  ];

  // For dynamic routes, you could fetch data here
  // Example (pseudo-code):
  // const blogPosts = await fetchBlogPosts();
  // const blogRoutes = blogPosts.map(post => ({
  //   url: `https://yourdomain.com/blog/${post.slug}`,
  //   lastModified: post.updatedAt,
  //   changeFrequency: 'weekly',
  //   priority: 0.8,
  // }));

  // Return all routes
  return [
    ...staticRoutes,
    // ...blogRoutes, // Uncomment when implemented
  ];
}
```