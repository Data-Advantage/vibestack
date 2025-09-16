# Convex Setup Workflow: Bridging v0 and Local Development

## Overview

This document explains the workflow for setting up Convex in a v0 project, which requires a hybrid approach between v0's web-based development environment and local CLI tools. Since v0 doesn't provide terminal access, we need to download the project, run Convex CLI commands locally, and then upload the generated files back to v0.

## The Challenge

Convex requires CLI tools to:
- Generate TypeScript API definitions (`convex/_generated/`)
- Push database schemas to the cloud
- Start the development server
- Create deployment configurations

v0 limitations:
- No terminal/CLI access
- Cannot run `npx convex dev`
- Cannot generate the required `_generated` files

## Solution: Hybrid Workflow

### Phase 1: Initial Setup in v0

1. **Create Convex Schema and Functions in v0**
   - Define your database schema in `convex/schema.ts`
   - Create query/mutation functions (e.g., `convex/recipes.ts`)
   - Set up ConvexClientProvider component
   - Configure environment variables in v0 Project Settings

2. **Add Convex Package to package.json**
---
{
  "dependencies": {
    "convex": "^1.27.0"
  }
}
---

3. **Create Basic Convex Files Structure**
---
convex/
├── schema.ts          # Database schema definitions
├── recipes.ts         # Recipe-related queries/mutations
├── mealPlans.ts       # Meal planning functions
├── shoppingLists.ts   # Shopping list functions
└── connectionTest.ts  # Diagnostic connection test
---

### Phase 2: Local Development Setup

4. **Download Project from v0**
   - Click the three dots in top-right of v0 interface
   - Select "Download ZIP"
   - Extract the project to your local development environment

5. **Install Dependencies Locally**
---
npm install
---

6. **Initialize Convex Project**
---
npx convex dev
---

This command will:
- Prompt you to create a new Convex project or connect to existing
- Generate the `convex/_generated/` directory
- Push your schema to Convex cloud database
- Start the local development server
- Create deployment configuration

7. **Generated Files Structure**
After running `npx convex dev`, you'll see:
---
convex/
├── _generated/
│   ├── api.d.ts       # API definitions for queries/mutations
│   ├── dataModel.d.ts # TypeScript types for your schema
│   └── server.d.ts    # Server-side type definitions
├── schema.ts
├── recipes.ts
└── ... (your other functions)
---

### Phase 3: Upload Generated Files to v0

8. **Copy Generated Files Back to v0**
   - Navigate to your local `convex/_generated/` directory
   - Copy all files from this directory
   - In v0, create the `convex/_generated/` directory structure
   - Paste each file individually into v0

9. **Key Files to Upload**
---
convex/_generated/api.d.ts
convex/_generated/dataModel.d.ts
convex/_generated/server.d.ts
---

### Phase 4: Verification in v0

10. **Test the Integration**
    - Navigate to `/convex` in your v0 preview
    - Run the diagnostics to verify all components are working
    - Test creating a recipe at `/recipe/new`

## Environment Variables Setup

Ensure these are configured in v0 Project Settings:

---
NEXT_PUBLIC_CONVEX_URL=https://your-deployment.convex.cloud
CONVEX_DEPLOYMENT=dev:your-deployment-name
---

## File-by-File Breakdown

### convex/schema.ts
Defines your database tables and validation rules:
---
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  recipes: defineTable({
    title: v.string(),
    description: v.optional(v.string()),
    ingredients: v.array(v.string()),
    instructions: v.array(v.string()),
    prepTime: v.optional(v.number()),
    cookTime: v.optional(v.number()),
    servings: v.optional(v.number()),
    difficulty: v.optional(v.union(v.literal("easy"), v.literal("medium"), v.literal("hard"))),
    tags: v.optional(v.array(v.string())),
    userId: v.string(),
    createdAt: v.number(),
  }),
});
---

### convex/recipes.ts
Contains queries and mutations for recipe operations:
---
import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

export const create = mutation({
  args: {
    title: v.string(),
    description: v.optional(v.string()),
    ingredients: v.array(v.string()),
    instructions: v.array(v.string()),
    prepTime: v.optional(v.number()),
    cookTime: v.optional(v.number()),
    servings: v.optional(v.number()),
    difficulty: v.optional(v.union(v.literal("easy"), v.literal("medium"), v.literal("hard"))),
    tags: v.optional(v.array(v.string())),
    userId: v.string(),
  },
  handler: async (ctx, args) => {
    return await ctx.db.insert("recipes", {
      ...args,
      createdAt: Date.now(),
    });
  },
});
---

### components/convex-client-provider.tsx
Wraps your app with Convex client:
---
"use client";
import { ConvexProvider, ConvexReactClient } from "convex/react";
import { ReactNode, useState, useEffect } from "react";

export function ConvexClientProvider({ children }: { children: ReactNode }) {
  const [convexClient, setConvexClient] = useState<ConvexReactClient | null>(null);

  useEffect(() => {
    const url = process.env.NEXT_PUBLIC_CONVEX_URL;
    if (url) {
      setConvexClient(new ConvexReactClient(url));
    }
  }, []);

  if (!convexClient) {
    return <div>Loading...</div>;
  }

  return <ConvexProvider client={convexClient}>{children}</ConvexProvider>;
}
---

## Workflow Benefits

### Advantages of This Approach
- **Rapid Prototyping**: Use v0 for quick UI development
- **Full Convex Integration**: Access to all Convex features
- **Type Safety**: Generated TypeScript definitions
- **Real Database**: Actual cloud database, not mock data
- **Seamless Transition**: Easy to continue development locally later

### When to Use This Workflow
- Building a real SaaS application with database needs
- Need type-safe database operations
- Want real-time data synchronization
- Planning to deploy to production

### When to Avoid This Workflow
- Simple prototypes without database needs
- Pure UI/design work
- Short-term experiments
- When local development is preferred from the start

## Troubleshooting

### Common Issues

**1. Environment Variables Not Working**
- Ensure `NEXT_PUBLIC_CONVEX_URL` is set in v0 Project Settings
- Verify the URL format: `https://your-deployment.convex.cloud`

**2. Generated Files Not Found**
- Make sure you've run `npx convex dev` locally first
- Verify all files in `convex/_generated/` are uploaded to v0
- Check file paths match exactly

**3. Schema Validation Errors**
- Ensure your local schema matches what's in v0
- Re-run `npx convex dev` after schema changes
- Upload updated generated files to v0

**4. Connection Test Failures**
- Check that Convex deployment is active
- Verify environment variables are correct
- Ensure generated API files are present

## Best Practices

### Development Workflow
1. **Start in v0** for rapid UI prototyping
2. **Move to local** when you need CLI tools
3. **Sync back to v0** for continued web-based development
4. **Deploy from local** for production

### File Management
- Keep local and v0 projects in sync
- Version control your local project
- Document any manual file transfers
- Use consistent naming conventions

### Schema Evolution
- Always update schema locally first
- Run `npx convex dev` to push changes
- Upload new generated files to v0
- Test thoroughly in both environments

## Conclusion

This hybrid workflow enables you to leverage both v0's rapid development capabilities and Convex's powerful backend features. While it requires some manual file management, it provides a path to building production-ready applications with real database integration while maintaining the speed and convenience of v0's development environment.

The key is understanding when to use each environment and maintaining consistency between your local and v0 codebases.


