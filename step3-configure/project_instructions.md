# Next.js/Supabase Application Development Guide

This guide outlines the architecture, best practices, and implementation details for building a modern web application using Next.js 15+, React 19+, TypeScript, Tailwind CSS v4, and Supabase.

## Core Technology Stack

### Frontend
- **TypeScript** as the primary language
- **React 19+** for UI components
- **Next.js 15+** with App Router for routing and server components
- **Tailwind CSS v4** for styling
- **shadcn/ui** component library (based on Radix UI primitives with "new-york" style)

### Backend
- **Supabase** for PostgreSQL database
- **Supabase Auth** for authentication and user management
- **Supabase Storage** for file uploads and management
- **Supabase Realtime** for real-time data subscriptions

### AI
- **Vercel AI SDK** for AI-powered apps & agents
  - **OpenAI Responses API** uses `model: openai.responses('gpt-4o')` instead of Completions API which is `model: openai('gpt-4o')`
  - **Image Generation** uses `model: openai.image('dall-e-3')`
- **Vercel AI SDK UI** for chatbots and generative user interfaces


### Infrastructure
- **Vercel** for hosting, environment variables, and preview deployments
- **Vercel Blob Storage** for static assets
- **Supabase Storage** for user-generated content

## Architecture Principles

### Content & Interactive Requirements
- Static marketing/informational pages with strong SEO optimization
- Protected app areas behind authentication
- Real-time interactive components using Supabase subscriptions
- Progressive enhancement where static content becomes interactive after hydration

### SEO Optimization
- Implement Next.js Metadata API for title, description, and OpenGraph tags
- Use server-side rendering for SEO-critical content
- Implement proper canonical URLs and sitemap generation
- Optimize images with next/image and appropriate alt text
- Implement structured data where appropriate

### Performance Targets
- **Core Web Vitals**:
  - LCP (Largest Contentful Paint): < 2.5s
  - FID (First Input Delay): < 100ms
  - CLS (Cumulative Layout Shift): < 0.1
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

### Phase 1: Project Foundation
1. Create a new Next.js 15 project with TypeScript and App Router
2. Set up Tailwind CSS v4 with shadcn/ui (new-york style)
3. Implement basic project structure following architecture patterns
4. Configure fonts and global styling
5. Create root layout with proper HTML structure

### Phase 2: Authentication Framework
1. Set up Supabase project and configure environment variables
2. Implement auth utilities (client, server, middleware)
3. Create login, signup, and password reset pages
4. Implement server actions for auth flows
5. Set up protected routes with middleware

### Phase 3: Core UI Components
1. Install and configure shadcn/ui components
2. Implement theme switching capability
3. Create responsive layout components
4. Build navigation components for different screen sizes
5. Implement accessibility features

### Phase 4: Protected Dashboard
1. Create dashboard layout with navigation
2. Implement user profile management
3. Build data visualization components
4. Create feature-specific sections
5. Implement permission-based UI elements

### Phase 5: Database and Data Management
1. Design database schema with proper relationships
2. Implement Row Level Security policies
3. Create type definitions for database entities
4. Build data fetching hooks and utilities
5. Implement CRUD operations with proper error handling

### Phase 6: Feature Development
1. Implement specific business features
2. Create domain-specific components
3. Build specialized forms and interactions
4. Implement real-time updates where needed
5. Add Google analytics and monitoring

## Detailed Implementation Guides

For detailed implementation instructions, refer to the following Source documents stored in the v0 Project Settings:

- Project Structure: [source/project-structure.md](source/project-structure.md)
- Configuration Files: [source/config-files.md](source/config-files.md)
- Authentication Implementation: [source/auth-implementation.md](source/auth-implementation.md)
- Database Patterns: [source/database-patterns.md](source/database-patterns.md)
- UI Components: [source/ui-components.md](source/ui-components.md)
- TypeScript Patterns: [source/typescript-patterns.md](source/typescript-patterns.md)