# Configuration Files

This document outlines the essential configuration files needed for a Next.js 15+ and Supabase application with Tailwind CSS v4.

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