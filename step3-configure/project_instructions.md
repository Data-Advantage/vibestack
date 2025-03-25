# Next.js/Supabase Application Development Guide

This guide outlines the architecture, best practices, and implementation details for building a modern web application with v0 AI agents.

## Core Technology Stack

### Frontend
- **TypeScript** as the primary language
- **React 19+** for UI components
- **Next.js 15+** with App Router
- **Tailwind CSS v4** for styling
- **shadcn/ui** component library
- **Lucide** icon library
- **Google Fonts** with the `Inter` font

### Backend
- **Supabase** for PostgreSQL database
- **Supabase Auth** for authentication and user management
- **Supabase Storage** for user file uploads
- **Supabase Realtime** for real-time data subscriptions

### AI
- **Vercel AI SDK** for AI-powered apps & agents
  - **OpenAI Responses API** uses `model: openai.responses('gpt-4o-mini')` (not Completions API)
  - **OpenAI Object Generation** uses `model: openai.responses('gpt-4o')`
  - **Image Generation** uses `model: google('gemini-2.0-flash-exp-image-generation'),`
- **Vercel AI SDK UI** for chatbots and generative user interfaces

### Infrastructure
- **Vercel** for hosting, environment variables, and preview deployments
- **Vercel Blob Storage** for static assets
- **Supabase Storage** for user-generated content

## Architecture Principles

### Content & Interactive Requirements
- Static marketing pages with strong SEO optimization
- Protected app areas behind authentication
- Real-time interactive components using Supabase subscriptions
- Progressive enhancement where static content becomes interactive after hydration

### SEO Optimization
- pSEO pages organized by category & slug
- Implement Next.js Metadata API for title, description, and OpenGraph tags
- Use server-side rendering for SEO-critical content
- Implement proper canonical URLs and sitemap generation
- Optimize images with next/image and appropriate alt text
- Implement JSON-LD structured data as appropriate

### Performance Targets
- **Core Web Vitals**: LCP: < 2.5s, FID: < 100ms, CLS: < 0.1
- Mobile-optimized bundle sizes
- Efficient code splitting and lazy loading
- Optimized asset delivery

### Responsive Design Approach
- Mobile-first development methodology
- Fluid layouts that adapt to any screen size
- Touch-friendly interface with appropriate sizing
- Consistent breakpoints (sm: 640px, md: 768px, lg: 1024px, xl: 1280px, 2xl: 1536px)
- Tailwind responsive modifiers for consistent implementation

## Implementation Roadmap

For detailed implementation steps and phases, refer to the [implementation-roadmap.md](source/implementation-roadmap.md) guide. This document outlines a ruthlessly prioritized approach to building a Next.js/Supabase application with Google Login and Stripe integration.

## Development Guides

For detailed implementation instructions, refer to the following development guides that are in the v0 Project Sources:

### Architecture & Structure
- [project-structure.md](source/project-structure.md) - Complete project directory organization
- [config-files.md](source/config-files.md) - Configuration file setup and options
- [typescript-patterns.md](source/typescript-patterns.md) - TypeScript best practices and patterns

### Backend & Data
- [database-patterns.md](source/database-patterns.md) - Database schema design and RLS policies
- [integration-details.md](source/integration-details.md) - External service integration specifications

### Authentication
- [auth-implementation.md](source/auth-implementation.md) - Supabase Auth implementation
- [login-with-google.md](source/login-with-google.md) - Login with Google setup

### Frontend
- [ui-components.md](source/ui-components.md) - Component architecture and shadcn/ui implementation
- [accessibility-standards.md](source/accessibility-standards.md) - Accessibility requirements and practices

### AI Implementation
- [ai-sdk-core.md](source/ai-sdk-core.md) - Core Vercel AI SDK implementation
- [ai-sdk-ui.md](source/ai-sdk-ui.md) - UI components for AI features
- [ai-sdk-providers.md](source/ai-sdk-providers.md) - AI model provider configuration