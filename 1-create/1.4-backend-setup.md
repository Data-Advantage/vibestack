# Day 1: Create

[⬅️ Day 1 Overview](README.md)

## 1.4 Backend Setup (Convex + Clerk) — Chef Packaging Guide

This step creates a “backend package” Chef can use to scaffold your initial Convex schema, queries, mutations, and storage paths from your PRD. Then you’ll verify with a diagnostics page and prepare to copy the Convex outputs into v0.

Timeframe: 30–45 minutes

References: `docs/convex-setup-workflow.md`, `docs/convex-diagnostics.md`, `docs/development-plan.md`, `docs/clerk-billing.md`

## Table of Contents
- 1.4.1: Prepare Backend Package (inputs for Chef)
- 1.4.2: Initialize Convex locally
- 1.4.3: Run Chef and generate schema/functions
- 1.4.4: Wire Clerk + Convex in app
- 1.4.5: Diagnostics page `/convex`
- 1.4.6: Prepare v0 handoff (copy Convex files into v0)

### 1.4.1: Prepare Backend Package (inputs for Chef)

Create a folder `backend-package/` with:
- `product-requirements.md` (from 1.1)
- `entities.md` (list core objects, attributes, ownership, expected queries)
- `permissions.md` (who can read/write which objects; any roles)
- `files.md` (what files are stored, size limits, access rules)
- `features.md` (feature flags, plan gating references from Clerk)

Chef prompt (example):
```
You are Chef for Convex. Given my backend-package folder contents (PRD, entities, permissions, files, features), generate:
- convex/schema.ts with tables keyed by Clerk user IDs
- convex/queries/* for common reads (user-owned and shared)
- convex/mutations/* for create/update/delete with basic validation
- Storage helpers for file uploads if files.md exists
Return idiomatic Convex code ready to paste.
```

### 1.4.2: Initialize Convex locally

1) `npm i convex`
2) `npx convex dev` to create deployment and `_generated` types
3) Add `NEXT_PUBLIC_CONVEX_URL` and `CONVEX_DEPLOYMENT` to `.env.local`

### Environment Variables

Set these in your local `.env.local` and in v0 Project Settings:
- `NEXT_PUBLIC_CONVEX_URL`
- `CONVEX_DEPLOYMENT`
- `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`
- `CLERK_SECRET_KEY`
- `AI_GATEWAY_API_KEY`
- Optional for billing: `CLERK_PLAN_ID`

### 1.4.3: Run Chef and generate schema/functions

Open `https://chef.convex.dev`, connect your project, paste the backend package. Chef outputs:
- `convex/schema.ts`
- `convex/queries/*.ts`
- `convex/mutations/*.ts`
- Optional storage helpers

Iterate in Chef until core entities and minimum CRUD are covered.

### 1.4.4: Wire Clerk + Convex in app

Install Clerk: `npm i @clerk/nextjs`. Then:
1) Add `middleware.ts` with Clerk middleware
2) Wrap `app/layout.tsx` with `ClerkProvider` and your `ConvexClientProvider`
3) Use `SignedIn`/`SignedOut`/`UserButton` where appropriate
4) Protect any routes that require authentication

See `docs/clerk-billing.md` and `docs/convex-setup-workflow.md`.

### 1.4.5: Diagnostics page `/convex`

Create `app/convex/page.tsx` to show env, Clerk session, and a sample query. See `docs/convex-diagnostics.md`.

### 1.4.6: Prepare v0 handoff (copy Convex files into v0)

If using v0, download your local Convex `convex/_generated/*` and paste into v0 under the same paths. Then copy Chef’s generated `convex/schema.ts`, `queries`, `mutations` to v0. Update env vars in v0. Verify `/convex` runs green.

---

Note on legacy docs: If you need the previous Supabase/Postgres workflow and SQL migrations, see `0-learn/supabase-database-setup.md`.


