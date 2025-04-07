# Configuration Files

This document outlines the essential configuration files needed for a Next.js 15+ and Supabase application with Tailwind CSS v4.

- [Project Setup](#project-setup)
- [Environment Variables](#environment-variables)
- [Core Configuration](#core-configuration)
- [Styling & Theming](#styling--theming)
- [Application Structure & Features](#application-structure--features)

## Project Setup

### package.json

Defines project dependencies, scripts, and metadata.

```package.json
{
  "name": "{{appname}}",
  "version": "{{0.1.0}}",
  "private": true,
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "class-variance-authority": "^0.7.1",
    "clsx": "^2.1.1",
    "lucide-react": "^0.487.0",
    "next": "15.2.4",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "@supabase/ssr": "^0.6.1",
    "@supabase/supabase-js": "^2.49.4",
    "tailwind-merge": "^3.2.0",
    "tw-animate-css": "^1.2.5"
  },
  "devDependencies": {
    "@eslint/eslintrc": "^3",
    "@tailwindcss/postcss": "^4",
    "@types/node": "^20",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "eslint": "^9",
    "eslint-config-next": "15.2.4",
    "tailwindcss": "^4",
    "typescript": "^5"
  }
}
```

### Key Dependencies

- **Core**: `next`, `react`, `react-dom`
- **Supabase**: `@supabase/supabase-js`, `@supabase/ssr`
- **UI**: `tailwindcss`, `@tailwindcss/postcss`, `shadcn` components (installed via CLI)
- **Utilities**: `zod`, `clsx`, `tailwind-merge`
- **Notifications**: `sonner` (preferred over `react-hot-toast`)

### Installation Steps

1.  Install Next.js, React core dependencies (`npm install react react-dom next`).
2.  Install Supabase dependencies (`npm install @supabase/supabase-js @supabase/ssr`).
3.  Install Tailwind CSS v4 and PostCSS (`npm install -D tailwindcss @tailwindcss/postcss postcss`).
4.  Initialize `shadcn/ui` with the "new-york" style (`npx shadcn-ui@latest init`).
5.  Install utility packages (`npm install zod clsx tailwind-merge sonner`).

## Environment Variables

### .env.example

Store sensitive keys and configuration specific to the deployment environment. Never commit `.env` files directly; use `.env.example` as a template.

### Key Dependencies

- **Core**: `next`, `react`, `react-dom`
- **Supabase**: `@supabase/supabase-js`, `@supabase/ssr`
- **UI**: `tailwindcss`, `@tailwindcss/postcss`, `shadcn/ui` components (installed via CLI)
- **Utilities**: `zod`, `clsx`, `tailwind-merge`
- **Notifications**: `sonner` (preferred over `react-hot-toast`)

### Installation Steps

1.  Install Next.js, React core dependencies (`npm install react react-dom next`).
2.  Install Supabase dependencies (`npm install @supabase/supabase-js @supabase/ssr`).
3.  Install Tailwind CSS v4 and PostCSS (`npm install -D tailwindcss @tailwindcss/postcss postcss`).
4.  Initialize `shadcn/ui` with the "new-york" style (`npx shadcn-ui@latest init`).
5.  Install utility packages (`npm install zod clsx tailwind-merge sonner`).

## Environment Variables

### .env.example

Store sensitive keys and configuration specific to the deployment environment. Never commit `.env` files directly; use `.env.example` as a template.

## Authentication Redirect URLs

```
NEXT_PUBLIC_SITE_URL=http://localhost:3000 # Change for production (e.g., https://your-app.vercel.app)
NEXT_PUBLIC_AUTH_REDIRECT_URL=http://localhost:3000/auth/callback # Adjust if necessary
```

### Supabase Configuration (usually installed via Vercel-Supabase integration or manually from Supabase dashboard)

```
NEXT_PUBLIC_SUPABASE_URL=YOUR_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=YOUR_SUPABASE_SERVICE_ROLE_KEY # Keep this secret!
```

### Database Connection Strings (provided by Supabase)

```
POSTGRES_URL=YOUR_SUPABASE_DB_CONNECTION_STRING_POOLED
POSTGRES_PRISMA_URL=YOUR_SUPABASE_DB_CONNECTION_STRING_POOLED # Prisma uses the pooled URL
POSTGRES_URL_NON_POOLING=YOUR_SUPABASE_DB_CONNECTION_STRING_NON_POOLED
POSTGRES_USER=postgres
POSTGRES_PASSWORD=YOUR_SUPABASE_DB_PASSWORD
POSTGRES_DATABASE=postgres
POSTGRES_HOST=YOUR_SUPABASE_DB_HOST
```

### Stripe Integration (if applicable)

```
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
NEXT_PUBLIC_STRIPE_PRICE_MONTHLY=price_...
NEXT_PUBLIC_STRIPE_PRICE_YEARLY=price_...
STRIPE_PRODUCT_ID=prod_...
```

### AI Integration (if applicable)

```
OPENAI_API_KEY=sk-...
GEMINI_API_KEY=AIza...
```


## Core Configuration

### next.config.js

Configure Next.js features like image domains, redirects, headers, and experimental flags.

```next.config.js
import type { NextConfig } from "next";

/** @type {import('next').NextConfig} */
const nextConfig: NextConfig = {
  // Example: Allow images from Supabase storage
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'your_supabase_project_id.supabase.co', // Replace with your Supabase project ID hostname
        port: '',
        pathname: '/storage/v1/object/public/**',
      },
    ],
  },
  // Add other configurations like security headers, redirects, etc.
  // async headers() {
  //   return [
  //     {
  //       source: '/:path*',
  //       headers: securityHeaders,
  //     },
  //   ]
  // },
};

// Example Security Headers (consider using a dedicated library or stricter rules)
// const securityHeaders = [
//   { key: 'X-DNS-Prefetch-Control', value: 'on' },
//   { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains; preload' },
//   { key: 'X-XSS-Protection', value: '1; mode=block' },
//   { key: 'X-Frame-Options', value: 'SAMEORIGIN' },
//   { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=()' },
//   { key: 'X-Content-Type-Options', value: 'nosniff' },
//   { key: 'Referrer-Policy', value: 'origin-when-cross-origin' }
// ]

export default nextConfig;

```

### tsconfig.json

Configure TypeScript compiler options, paths aliases, and included/excluded files.

```tsconfig.json
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler", // Changed from "node" for modern tooling
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./*"] // Base path alias
    }
  },
  "include": [
    "next-env.d.ts",
    "**/*.ts",
    "**/*.tsx",
    ".next/types/**/*.ts",
    "**/*.mjs" // Include .mjs files if used (e.g., for ESLint config)
  ],
  "exclude": ["node_modules"]
}
```

### eslint.config.mjs

Configure ESLint rules for code quality and consistency using the new flat config format.

```eslint.config.mjs
// @ts-check

import eslint from "@eslint/js";
import tseslint from "typescript-eslint";
import reactRecommended from "eslint-plugin-react/configs/recommended.js";
import reactJsxRuntime from "eslint-plugin-react/configs/jsx-runtime.js"; // Needed for React 17+ JSX Transform
import hooksPlugin from "eslint-plugin-react-hooks";
import nextPlugin from "@next/eslint-plugin-next";
import importPlugin from "eslint-plugin-import"; // For import sorting/ordering
import jsxA11yPlugin from "eslint-plugin-jsx-a11y"; // For accessibility rules

/** @type { import("eslint").Linter.FlatConfig[] } */
const eslintConfig = tseslint.config(
  // Base configs
  eslint.configs.recommended,
  ...tseslint.configs.recommended,

  // React specific configs
  reactRecommended,
  reactJsxRuntime, // Use this for React 17+
  {
    plugins: {
      "react-hooks": hooksPlugin,
      "jsx-a11y": jsxA11yPlugin,
    },
    rules: {
      ...hooksPlugin.configs.recommended.rules, // Enforce Rules of Hooks
      ...jsxA11yPlugin.configs.recommended.rules, // Enforce accessibility best practices
    },
    settings: {
      react: {
        version: "detect", // Automatically detect the React version
      },
    },
  },

  // Next.js specific configs
  {
    plugins: {
      "@next/next": nextPlugin,
    },
    rules: {
      ...nextPlugin.configs.recommended.rules,
      ...nextPlugin.configs["core-web-vitals"].rules,
      // Example: Warn about using <img> instead of <Image>
      "@next/next/no-img-element": "warn",
    },
  },

  // Import plugin for sorting and path resolution (optional but recommended)
  {
    plugins: {
      import: importPlugin,
    },
    rules: {
      "import/order": [
        "warn",
        {
          groups: [
            "builtin",
            "external",
            "internal",
            "parent",
            "sibling",
            "index",
            "object",
            "type",
          ],
          "newlines-between": "always",
          alphabetize: { order: "asc", caseInsensitive: true },
        },
      ],
      "import/no-unresolved": "off", // Often handled better by TypeScript/IDE
      "sort-imports": ["warn", { ignoreDeclarationSort: true }], // Let import/order handle it
    },
    settings: {
      "import/resolver": {
        typescript: true,
        node: true,
      },
    },
  },

  // Global ignores and overrides
  {
    ignores: [
      "node_modules/",
      ".next/",
      "out/",
      "build/",
      // Add other generated/ignored directories
    ],
  },

  // Specific overrides, e.g., disable certain rules for config files
  {
    files: ["*.config.js", "*.config.mjs", ".*rc.js"],
    rules: {
      "@typescript-eslint/no-var-requires": "off", // Allow require in JS config files
    },
  },

  // Ensure JSX files are parsed correctly
  {
    files: ["**/*.{ts,tsx}"],
    languageOptions: {
      parserOptions: {
        ecmaFeatures: {
          jsx: true,
        },
      },
    },
  },
);

export default eslintConfig;

```

### components.json

Configures `shadcn/ui`, defining the style, component paths, Tailwind setup, and icon library used when adding new UI components via the CLI (`npx shadcn-ui@latest add ...`).

```json:components.json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "", // Usually empty for Tailwind v4
    "css": "app/globals.css", // Path to your global CSS file
    "baseColor": "stone", // Base color scheme for components
    "cssVariables": true, // Use CSS variables for theming
    "prefix": "" // Optional prefix for Tailwind classes
  },
  "aliases": {
    "components": "@/components", // Base directory for components
    "utils": "@/lib/utils",     // Utility functions (like cn)
    "ui": "@/components/ui",    // Directory for shadcn UI components
    "lib": "@/lib",             // General library directory
    "hooks": "@/hooks"          // Custom hooks directory
  },
  "iconLibrary": "lucide" // Specify icon library (lucide-react)
}
```

### middleware.ts

Intercept requests to perform actions like authentication checks, redirects, or setting headers. This example includes Supabase session refreshing.

```typescript:middleware.ts
import { NextResponse, type NextRequest } from "next/server";
import { createServerClient } from "@supabase/ssr";

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
        set(name: string, value: string, options) {
          request.cookies.set({ name, value, ...options });
          response = NextResponse.next({ // Recreate response to apply cookie changes
            request: { headers: request.headers },
          });
          response.cookies.set({ name, value, ...options });
        },
        remove(name: string, options) {
          request.cookies.set({ name, value: "", ...options });
          response = NextResponse.next({ // Recreate response to apply cookie changes
            request: { headers: request.headers },
          });
          response.cookies.set({ name, value: "", ...options });
        },
      },
    },
  );

  // Refresh session if expired - required for Server Components
  await supabase.auth.getSession();

  // Optional: Add protected route logic here
  // const { data: { session } } = await supabase.auth.getSession();
  // const { pathname } = request.nextUrl;
  // if (!session && pathname.startsWith('/dashboard')) {
  //   return NextResponse.redirect(new URL('/login', request.url));
  // }

  return response;
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * Feel free to modify this pattern to include more exceptions.
     */
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};
```

## Styling & Theming

### Tailwind CSS v4 & PostCSS

Configure Tailwind CSS v4 using PostCSS. Note that `tailwind.config.ts` is generally not needed in v4 unless using specific plugins or themes that require it.

#### postcss.config.mjs

Configure the Tailwind v4 PostCSS plugin.

```javascript:postcss.config.mjs
const config = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};
export default config;
```

#### app/globals.css

Import Tailwind v4, define base styles, CSS variables for theming (compatible with `shadcn/ui`), and color palettes.

```css:app/globals.css
@import "tailwindcss";
@import "tw-animate-css";

@custom-variant dark (&:is(.dark *));

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --font-sans: var(--font-geist-sans);
  --font-mono: var(--font-geist-mono);
  --color-sidebar-ring: var(--sidebar-ring);
  --color-sidebar-border: var(--sidebar-border);
  --color-sidebar-accent-foreground: var(--sidebar-accent-foreground);
  --color-sidebar-accent: var(--sidebar-accent);
  --color-sidebar-primary-foreground: var(--sidebar-primary-foreground);
  --color-sidebar-primary: var(--sidebar-primary);
  --color-sidebar-foreground: var(--sidebar-foreground);
  --color-sidebar: var(--sidebar);
  --color-chart-5: var(--chart-5);
  --color-chart-4: var(--chart-4);
  --color-chart-3: var(--chart-3);
  --color-chart-2: var(--chart-2);
  --color-chart-1: var(--chart-1);
  --color-ring: var(--ring);
  --color-input: var(--input);
  --color-border: var(--border);
  --color-destructive: var(--destructive);
  --color-accent-foreground: var(--accent-foreground);
  --color-accent: var(--accent);
  --color-muted-foreground: var(--muted-foreground);
  --color-muted: var(--muted);
  --color-secondary-foreground: var(--secondary-foreground);
  --color-secondary: var(--secondary);
  --color-primary-foreground: var(--primary-foreground);
  --color-primary: var(--primary);
  --color-popover-foreground: var(--popover-foreground);
  --color-popover: var(--popover);
  --color-card-foreground: var(--card-foreground);
  --color-card: var(--card);
  --radius-sm: calc(var(--radius) - 4px);
  --radius-md: calc(var(--radius) - 2px);
  --radius-lg: var(--radius);
  --radius-xl: calc(var(--radius) + 4px);
}

:root {
  --radius: 0.625rem;
  --background: oklch(1 0 0);
  --foreground: oklch(0.147 0.004 49.25);
  --card: oklch(1 0 0);
  --card-foreground: oklch(0.147 0.004 49.25);
  --popover: oklch(1 0 0);
  --popover-foreground: oklch(0.147 0.004 49.25);
  --primary: oklch(0.216 0.006 56.043);
  --primary-foreground: oklch(0.985 0.001 106.423);
  --secondary: oklch(0.97 0.001 106.424);
  --secondary-foreground: oklch(0.216 0.006 56.043);
  --muted: oklch(0.97 0.001 106.424);
  --muted-foreground: oklch(0.553 0.013 58.071);
  --accent: oklch(0.97 0.001 106.424);
  --accent-foreground: oklch(0.216 0.006 56.043);
  --destructive: oklch(0.577 0.245 27.325);
  --border: oklch(0.923 0.003 48.717);
  --input: oklch(0.923 0.003 48.717);
  --ring: oklch(0.709 0.01 56.259);
  --chart-1: oklch(0.646 0.222 41.116);
  --chart-2: oklch(0.6 0.118 184.704);
  --chart-3: oklch(0.398 0.07 227.392);
  --chart-4: oklch(0.828 0.189 84.429);
  --chart-5: oklch(0.769 0.188 70.08);
  --sidebar: oklch(0.985 0.001 106.423);
  --sidebar-foreground: oklch(0.147 0.004 49.25);
  --sidebar-primary: oklch(0.216 0.006 56.043);
  --sidebar-primary-foreground: oklch(0.985 0.001 106.423);
  --sidebar-accent: oklch(0.97 0.001 106.424);
  --sidebar-accent-foreground: oklch(0.216 0.006 56.043);
  --sidebar-border: oklch(0.923 0.003 48.717);
  --sidebar-ring: oklch(0.709 0.01 56.259);
}

.dark {
  --background: oklch(0.147 0.004 49.25);
  --foreground: oklch(0.985 0.001 106.423);
  --card: oklch(0.216 0.006 56.043);
  --card-foreground: oklch(0.985 0.001 106.423);
  --popover: oklch(0.216 0.006 56.043);
  --popover-foreground: oklch(0.985 0.001 106.423);
  --primary: oklch(0.923 0.003 48.717);
  --primary-foreground: oklch(0.216 0.006 56.043);
  --secondary: oklch(0.268 0.007 34.298);
  --secondary-foreground: oklch(0.985 0.001 106.423);
  --muted: oklch(0.268 0.007 34.298);
  --muted-foreground: oklch(0.709 0.01 56.259);
  --accent: oklch(0.268 0.007 34.298);
  --accent-foreground: oklch(0.985 0.001 106.423);
  --destructive: oklch(0.704 0.191 22.216);
  --border: oklch(1 0 0 / 10%);
  --input: oklch(1 0 0 / 15%);
  --ring: oklch(0.553 0.013 58.071);
  --chart-1: oklch(0.488 0.243 264.376);
  --chart-2: oklch(0.696 0.17 162.48);
  --chart-3: oklch(0.769 0.188 70.08);
  --chart-4: oklch(0.627 0.265 303.9);
  --chart-5: oklch(0.645 0.246 16.439);
  --sidebar: oklch(0.216 0.006 56.043);
  --sidebar-foreground: oklch(0.985 0.001 106.423);
  --sidebar-primary: oklch(0.488 0.243 264.376);
  --sidebar-primary-foreground: oklch(0.985 0.001 106.423);
  --sidebar-accent: oklch(0.268 0.007 34.298);
  --sidebar-accent-foreground: oklch(0.985 0.001 106.423);
  --sidebar-border: oklch(1 0 0 / 10%);
  --sidebar-ring: oklch(0.553 0.013 58.071);
}

@layer base {
  * {
    @apply border-border outline-ring/50;
  }
  body {
    @apply bg-background text-foreground;
  }
}
```

### Dark Mode / Theme Provider

Use `next-themes` for handling light/dark/system theme switching.

#### components/providers/theme-provider.tsx

A client component wrapper around `next-themes` provider.

```typescript:components/providers/theme-provider.tsx
"use client";

import * as React from "react";
import { ThemeProvider as NextThemesProvider } from "next-themes";
import type { ThemeProviderProps } from "next-themes/dist/types";

export function ThemeProvider({ children, ...props }: ThemeProviderProps) {
  return <NextThemesProvider {...props}>{children}</NextThemesProvider>;
}
```

### Root Layout Setup (`app/layout.tsx`)

Combine font setup, global CSS import, and ThemeProvider wrapping in the root layout.

```typescript:app/layout.tsx
import type { Metadata } from "next";
import { GeistSans } from "geist/font/sans"; // Use new Geist package
import { GeistMono } from "geist/font/mono"; // Use new Geist package
import { ThemeProvider } from "@/components/providers/theme-provider"; // Adjust path if needed
import { cn } from "@/lib/utils"; // Assuming shadcn/ui setup
import "./globals.css";

export const metadata: Metadata = {
  title: "Create Next App",
  description: "Generated by create next app",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body
        className={cn(
          "min-h-screen bg-background font-sans antialiased",
          GeistSans.variable, // Add font variables directly
          GeistMono.variable
        )}
      >
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange // Prevent theme transition flashes
        >
          {/* Add Navbar, Footer, or other global layout components here */}
          {children}
        </ThemeProvider>
      </body>
    </html>
  );
}
```

## Application Structure & Features

### Utility Functions (`lib/utils.ts`)

Contains helper functions used across the application. The `cn` function, commonly generated by `shadcn/ui` initialization, merges Tailwind classes using `tailwind-merge` and handles conditional classes with `clsx`.

```ts:lib/utils.ts
import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
```

### Example Page (`app/page.tsx`)

A basic page demonstrating the use of Tailwind utility classes and potentially configured fonts/themes.

```app/page.tsx
import Image from "next/image";

export default function Home() {
  return (
    <div className="grid grid-rows-[auto_1fr_auto] items-center justify-items-center min-h-screen p-8 pb-20 gap-16 sm:p-20">
      <main className="flex flex-col gap-8 row-start-2 items-center sm:items-start">
        <Image
          className="dark:invert" // Example of dark mode styling
          src="/next.svg"
          alt="Next.js logo"
          width={180}
          height={38}
          priority
        />
        <ol className="list-inside list-decimal text-sm/6 text-center sm:text-left font-mono"> {/* Use font-mono variable */}
          <li className="mb-2">
            Get started by editing{" "}
            <code className="bg-black/[.05] dark:bg-white/[.06] px-1 py-0.5 rounded font-mono font-semibold">
              app/page.tsx
            </code>
            .
          </li>
          <li>Save and see your changes instantly.</li>
        </ol>

        <div className="flex gap-4 items-center flex-col sm:flex-row">
          <a
            className="rounded-full border border-transparent transition-colors flex items-center justify-center bg-foreground text-background gap-2 hover:bg-foreground/80 font-medium h-10 sm:h-12 px-4 sm:px-5"
            href="https://vercel.com/new?utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app"
            target="_blank"
            rel="noopener noreferrer"
          >
            <Image
              className="dark:invert"
              src="/vercel.svg"
              alt="Vercel logomark"
              width={20}
              height={20}
            />
            Deploy now
          </a>
          <a
            className="rounded-full border border-border transition-colors flex items-center justify-center hover:bg-accent hover:text-accent-foreground font-medium h-10 sm:h-12 px-4 sm:px-5 w-full sm:w-auto"
            href="https://nextjs.org/docs?utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app"
            target="_blank"
            rel="noopener noreferrer"
          >
            Read our docs
          </a>
        </div>
      </main>
      <footer className="row-start-3 flex gap-6 flex-wrap items-center justify-center">
        <a
          className="flex items-center gap-2 hover:underline hover:underline-offset-4"
          href="https://nextjs.org/learn?utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app"
          target="_blank"
          rel="noopener noreferrer"
        >
          {/* Consider using an icon library instead of separate SVGs */}
          Learn
        </a>
        <a
          className="flex items-center gap-2 hover:underline hover:underline-offset-4"
          href="https://vercel.com/templates?framework=next.js&utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app"
          target="_blank"
          rel="noopener noreferrer"
        >
          Examples
        </a>
        <a
          className="flex items-center gap-2 hover:underline hover:underline-offset-4"
          href="https://nextjs.org?utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app"
          target="_blank"
          rel="noopener noreferrer"
        >
          Go to nextjs.org →
        </a>
      </footer>
    </div>
  );
}
```

### Sitemap (`app/sitemap.ts`)

Generate a sitemap dynamically or statically for SEO.

```typescript:app/sitemap.ts
import { MetadataRoute } from 'next';

// Replace with your actual domain
const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000';

export default function sitemap(): MetadataRoute.Sitemap {
  // Define static routes
  const staticRoutes = [
    {
      url: `${SITE_URL}/`,
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 1,
    },
    {
      url: `${SITE_URL}/about`,
      lastModified: new Date(),
      changeFrequency: 'monthly',
      priority: 0.8,
    },
    {
      url: `${SITE_URL}/pricing`,
      lastModified: new Date(),
      changeFrequency: 'weekly',
      priority: 0.9,
    },
    {
      url: `${SITE_URL}/contact`,
      lastModified: new Date(),
      changeFrequency: 'monthly',
      priority: 0.7,
    },
    // Add other static pages like /login, /signup, etc.
  ];

  // Example: Fetch dynamic routes (e.g., blog posts)
  // This part needs actual data fetching logic
  const dynamicRoutes = async () => {
    try {
      // const posts = await fetchFromYourCMS('/posts'); // Replace with actual fetch
      // return posts.map(post => ({
      //   url: `${SITE_URL}/blog/${post.slug}`,
      //   lastModified: new Date(post.updatedAt), // Ensure date format is valid
      //   changeFrequency: 'weekly',
      //   priority: 0.6,
      // }));
      return []; // Return empty array if no dynamic routes yet
    } catch (error) {
      console.error("Failed to fetch dynamic routes for sitemap:", error);
      return [];
    }
  };

  // Note: sitemap() function cannot be async directly in Next.js App Router.
  // If you need async data, fetch it outside or use alternative generation methods.
  // For simplicity, this example assumes dynamic routes are handled elsewhere or fetched synchronously (not recommended for large datasets).

  // For now, returning only static routes
  const allRoutes: MetadataRoute.Sitemap = [
    ...staticRoutes,
    // ...await dynamicRoutes(), // This won't work directly here due to sync requirement
  ];

  return allRoutes;
}
```

Remember that specific versions and exact implementations will change over time. Focus on understanding the configuration principles rather than copying exact code snippets.