# SaaS Starter App — Project Instructions

A compact SaaS starter for vibe coders 🚀 using modern defaults and batteries-included auth, billing, and data sync. Barebones starter template ready for app-specific customization.

---

## Tech Stack

- Next.js 15 (App Router)  
- React 19 + Tailwind v4 + shadcn/ui + Lucide icons  
- Clerk.com for **authentication, billing, and user account/profile management**  
- Convex.dev v1.27.0 for database + sync engine + diagnostics (basic setup, no schema yet)
- Vercel AI Gateway + AI-SDK v5.0.39 (`npm i ai`) with `streamObject` / `generateObject` + `zod`  
- Vercel AI Elements (`npx ai-elements@latest`)  

---

## Development Approach

**Barebones SaaS starter approach:**
1. Set up Clerk auth integration and basic structure
2. Create core pages with responsive design
3. Install Convex basics (no schema yet - added per project)
4. Template ready for cloning to specific SaaS projects

**📋 See `development-plan.md` for complete implementation details, account setup, and troubleshooting. See `convex-setup-workflow.md` for detailed Convex integration workflow.**

---

## Core Starter Routes

**These are the ONLY pages to create initially. Other pages added per project.**

- `/` → marketing (anon) or dashboard (signed-in)  
- `/pricing` → plan comparison ($3/mo, $30/year)  
- `/dashboard` → main app interface (placeholder for project-specific content)
- `/convex` → Convex connection diagnostics & setup status - see Project Sources "convex-diagnostics.md" document
- `/sign-in` → Clerk SignIn  
- `/sign-up` → Clerk SignUp  
- `/user` → Clerk UserProfile  
- `/billing` → Clerk BillingPortal  
- `/terms` → Terms of Service
- `/privacy` → Privacy Policy

---

## Header Component

Create header with app logo/name, nav links, theme toggle, and Clerk auth buttons. Key imports: `SignedIn, SignedOut, SignInButton, UserButton` from `@clerk/nextjs`. Structure: container with flex layout, left side (logo + nav), right side (theme toggle + auth). Show Dashboard link only when signed in. Use `UserButton` for signed-in users, `SignInButton` for signed-out. Include a Dark/Light toggle.

---

## Footer Component

Simple footer with copyright, terms/privacy links. Structure: container with responsive flex layout, copyright text on left, link group on right. Links: `/terms`, `/privacy`, `/pricing`. Add to layout after main content with `border-t bg-muted/30` styling.

---

## Dark Mode Toggle

**See Project Sources `dark-mode.md` for complete implementation details.**

---

## Clerk Integration

### Middleware (`middleware.ts`)

---

    import { clerkMiddleware } from "@clerk/nextjs/server";  
    export default clerkMiddleware();  
    export const config = { matcher: ["/((?!_next|[^?]*\\.).*)","/(api|trpc)(.*)"], };

---

### Layout (`app/layout.tsx`)
Wrap with `ClerkProvider` and `ConvexClientProvider`. Include Header/Footer. Structure: `min-h-screen flex flex-col` with `flex-1` main content.

**Use Clerk's out-of-box UI components - never rebuild auth/billing manually**

---

## ConvexClientProvider

---

    "use client";
    import { ConvexProvider, ConvexReactClient } from "convex/react";

    const convex = new ConvexReactClient(process.env.NEXT_PUBLIC_CONVEX_URL!);

    export function ConvexClientProvider({ children }: { children: React.ReactNode }) {
      return <ConvexProvider client={convex}>{children}</ConvexProvider>;
    }

---

## Basic Convex Setup

Install Convex basics without schema. Create empty `convex/schema.ts` file for future use. Set up connection diagnostics at `/convex` route. Schema and functions added per specific project needs.

---

## Dashboard Page

Create placeholder dashboard at `/dashboard` route. Protected page that shows when user is signed in. Include basic layout with welcome message and placeholder sections for project-specific features. Use `auth()` from `@clerk/nextjs/server` to protect route.

---

## Home Page Logic

Root `/` page shows marketing content for anonymous users, redirects to `/dashboard` for signed-in users. Use `SignedIn, SignedOut` components to conditionally render content. Marketing section includes hero, features, CTA buttons linking to `/sign-up` and `/pricing`.

---

## Pricing

Configure in Clerk Dashboard:
- **Monthly:** $3/month  
- **Yearly:** $30/year  

PlanId is in env var CLERK_PLAN_ID. Check clerk-billing.md for setup details.

---

## Environment Variables

---

    AI_GATEWAY_API_KEY=
    CLERK_PLAN_ID=
    CLERK_SECRET_KEY=
    NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
    NEXT_PUBLIC_CONVEX_URL=
    CONVEX_DEPLOYMENT=

---