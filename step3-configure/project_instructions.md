# Next.js/Supabase Application Development Guide

This guide outlines the architecture, best practices, and implementation details for building a modern web application with the v0 AI code agent.

## Core Technology Stack

### Frontend
- **TypeScript** as the primary language
- **React 19+** for UI components
- **Next.js 15+** with App Router
- **Tailwind CSS v3.4** for styling
- **shadcn** component library such as `import { Button } from "@/components/ui/button"`
- **Lucide** icon library such as `import { Camera } from 'lucide-react'`
- **Google Fonts** with `import { Inter } from 'next/font/google'` in `app/layout.tsx`
- **Forms** with `import Form from 'next/form'`
- **Links** with `import Link from 'next/link'`
- **Image Optimization** with `import Image from 'next/image'`
- **Self-Hosted Video** with `<video>`
- **Externally-Hosted Video** with `<iframe>`
- **Lazy Loading** with `import dynamic from 'next/dynamic'`
- **Dark Mode** with `import { ThemeProvider as NextThemesProvider } from 'next-themes'` and enable class-based dark mode in `tailwind.config.js`

### Metadata & Analytics
- **<head> tags** using `import type { Metadata } from 'next'` and `export const metadata: Metadata = { title: 'My Page Title' }`
- **Static Metadata** using `import type { Metadata } from 'next'`
- **Dynamic Metadata** using `import type { Metadata, ResolvingMetadata } from 'next'`
- **favicon** in `app/favicon.ico`
- **icon.svg** in `app/icon.ts` using `import { ImageResponse } from 'next/og'`
- **apple-icon.png** in `app/apple-icon.ts` using `import { ImageResponse } from 'next/og'`
- **Open Graph** with `app/{route}/opengraph-image.tsx` using `import { ImageResponse } from 'next/og'`
- **manifest.json** in `app/manifest.ts` using `import type { MetadataRoute } from 'next'` function `manifest(): MetadataRoute.Manifest`
- **sitemap.xml** in `app/sitemap.ts` using `import type { MetadataRoute } from 'next'` function `sitemap(): MetadataRoute.Sitemap`
- **robots.txt** in  `app/robots.ts` using `import type { MetadataRoute } from 'next'` function `robots(): MetadataRoute.Robots`
- **Core Web Vitals** for analytics with `import { useReportWebVitals } from 'next/web-vitals'`

### Blog & Static Content
- **Markdwon** files in `/app/blog/post-1.md`
- **Post URLs** from the `.md` filenames
- **Post Metadata** with YAML Front Matter using `npm install gray-matter`:
```
---
title: 'My Title Here'
date: '2020-01-02'
---
```
- **HTML Conversion** at build time using `import fs`, `import path` to connect to the `posts` folder and read the markdown files
- **Fetch Blog Data** with `getStaticsProps()`

### Backend
- **Supabase** for PostgreSQL database using `@supabase/supabase-js` with `lib/supabaseAdmin.ts` for reusable access
- **Supabase Auth** for authentication and user management using `@supabase/ssr`
- **Supabase Storage** for user file uploads
- **Supabase Realtime** for real-time data subscriptions

### AI
- **Vercel AI SDK** for AI-powered apps & agents
  - **OpenAI Responses API** uses `model: openai.responses('gpt-4o-mini')` (not Completions API)
  - **OpenAI Object Generation** uses `model: openai.responses('gpt-4o')`
  - **Image Generation** uses `model: google('gemini-2.0-flash-exp-image-generation'),`
- **Vercel AI SDK UI** for chatbots and generative user interfaces

## Payments
- **Stripe** server side code with `import Stripe from 'stripe'`
- **Stripe Customer Portal** integration
- **Stripe Webhook Handler** at `app/api/webhooks/stripe/route.tx` to store data in the `stripe` schema in Supabase
- **Stripe Secrets** stored as `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET`

## Infrastructure
- **Vercel** for hosting, environment variables, and preview deployments
- **Vercel Blob Storage** for static assets
- **Supabase Storage** for user-generated content

## Responsive Design Approach
- Mobile-first development methodology
- Fluid layouts that adapt to any screen size
- Touch-friendly interface with appropriate sizing
- Consistent breakpoints (sm: 640px, md: 768px, lg: 1024px, xl: 1280px, 2xl: 1536px)
- Tailwind responsive modifiers for consistent implementation