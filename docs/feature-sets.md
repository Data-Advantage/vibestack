# Starter Template

```
app/
├── (auth)/                     # Auth-related routes (grouped)
│   ├── login                   # Login page
│   ├── signup                  # Sign up page
│   ├── confirm                 # Email verification
│   ├── reset-password          # Password reset flow
├── dashboard                   # App dashboard (protected by login)
└── error.tsx                   # Global error page
├── layout.tsx                  # Root layout
├── globals.css                 # Global styles and Tailwind config
├── page.tsx                    # Root page
├── robots.ts                   # Built-in Next.js robots.txt generation
├── sitemap.ts                  # Built-in Next.js sitemap.xml generation
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
lib/                           # Utility functions and services
├── supabase/                  # Supabase client setup
│   ├── client.ts              # Browser client for Client Components
│   ├── server.ts              # Server client for Server Components
│   ├── middleware.ts          # Auth refresh helpers for middleware
│   ├── admin.ts               # Admin client (server-side only)
│   └── types.ts               # Re-exports of generated types
├── actions/                   # Centralized server actions
│   ├── auth.ts                # Auth-related actions
├── utils/                     # General utility functions
│   ├── formatting.ts          # Date, number, text formatting
│   ├── validation.ts          # Input validation helpers
│   └── ...                    # Other utilities
└── constants/                 # Application constants
    ├── routes.ts              # Route definitions
    └── config.ts              # App configuration constants
.env.example                   # Environment variable documentation artifact
next.config.js                 # Next.js configuration
postcss.config.mjs             # Configuration for PostCSS
tailwind.config.ts             # Tailwind configuration
tsconfig.json                  # TypeScript configuration
```

# App Build (on Day 1)

- /api
- /

# Software (Day 3)

- /login (with Google)

# Marketing (Day 4)

```
app/
├── (marketing)/               # Marketing pages (grouped)
│   ├── about                  # About page
│   ├── blog                   # Blog section
│   ├── pricing                # Pricing page
│   ├── contact                # Contact page
├── (seo)/                     # SEO-optimized content pages (grouped)
│   ├── [category]/            # Category pages
│      ├── [topic-slug]/       # Topic pages
```