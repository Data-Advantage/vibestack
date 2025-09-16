# Development Plan: SaaS Starter Implementation

## Overview

Complete step-by-step development plan for building a SaaS application using the hybrid v0 + local development workflow. This plan covers account setup, project initialization, and the three-phase development approach.

---

## Prerequisites & Account Setup

### 1. Convex Account Setup
1. **Create Account:** Visit [convex.dev](https://convex.dev) and sign up
2. **Install CLI:** `npm install -g convex`
3. **Login:** `npx convex login` (opens browser for authentication)
4. **Verify:** `npx convex --version` should show v1.27.0+

### 2. Clerk Account Setup
1. **Create Account:** Visit [clerk.com](https://clerk.com) and sign up
2. **Create Application:** Dashboard → "Add Application"
3. **Configure Authentication:** Enable email/password, social providers as needed
4. **Set up Billing:** Dashboard → Subscriptions → Configure pricing tiers
5. **Note API Keys:** Copy publishable and secret keys for environment variables

### 3. Vercel Account Setup (for AI features)
1. **Create Account:** Visit [vercel.com](https://vercel.com) and sign up
2. **Generate AI Gateway Key:** Dashboard → Settings → AI → Create API Key
3. **Save Key:** Store for `AI_GATEWAY_API_KEY` environment variable

---

## Development Phases

### Phase 1: Mock Data + v0 Setup
**Goal:** Rapid UI prototyping with mock data and basic structure

#### 1.1 Initial v0 Project Setup
1. **Start New v0 Project:** Create new project in v0.app
2. **Install Dependencies:** Add to package.json via v0 interface
   ```json
   {
     "dependencies": {
       "@clerk/nextjs": "latest",
       "convex": "^1.27.0",
       "tailwindcss": "latest",
       "lucide-react": "latest",
       "zod": "latest",
       "ai": "latest"
     }
   }
   ```

#### 1.2 Project Structure Creation
Create these directories and files in v0:
```
app/
├── layout.tsx              # Root layout with providers
├── page.tsx                # Landing/dashboard page
├── dashboard/
│   └── page.tsx            # Main dashboard
├── pricing/
│   └── page.tsx            # Pricing page
├── convex/
│   └── page.tsx            # Diagnostics page
├── sign-in/
│   └── page.tsx            # Clerk SignIn
├── sign-up/
│   └── page.tsx            # Clerk SignUp
├── user/
│   └── page.tsx            # Clerk UserProfile
├── billing/
│   └── page.tsx            # Clerk BillingPortal
├── terms/
│   └── page.tsx            # Terms of Service
└── privacy/
    └── page.tsx            # Privacy Policy

components/
├── header.tsx              # Navigation header
├── footer.tsx              # Site footer
├── theme-toggle.tsx        # Dark/light theme toggle
└── convex-client-provider.tsx # Convex wrapper

convex/
├── mock/                   # Mock data directory
│   ├── users.json
│   ├── tasks.json
│   └── settings.json
├── schema.ts               # Database schema (placeholder)
├── tasks.ts                # Task functions (placeholder)
└── connectionTest.ts       # Diagnostics helper

lib/
├── mockData.ts             # Mock data helper
└── utils.ts                # Utility functions

middleware.ts               # Clerk middleware
```

#### 1.3 Environment Variables Setup
Configure in v0 Project Settings:
```
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...
NEXT_PUBLIC_CONVEX_URL=https://placeholder.convex.cloud
CONVEX_DEPLOYMENT=dev:placeholder
AI_GATEWAY_API_KEY=your_vercel_ai_key
```

#### 1.4 Mock Data Implementation
Create functional UI with mock JSON data:
- Users can browse mock tasks
- Forms submit but don't persist
- Authentication UI works but uses test data
- All pages render correctly

**Phase 1 Deliverables:**
- ✅ Complete UI/UX implementation
- ✅ Clerk authentication flows
- ✅ Mock data integration
- ✅ Responsive design
- ✅ Theme switching
- ✅ All core pages functional

---

### Phase 2: Hybrid Convex Integration
**Goal:** Bridge to real database while maintaining v0 development speed

#### 2.1 Local Environment Setup
1. **Download v0 Project:**
   - Click three dots in v0 interface
   - Select "Download ZIP"
   - Extract to local development directory

2. **Local Dependencies:**
   ```bash
   cd your-project
   npm install
   ```

#### 2.2 Convex Project Creation
1. **Initialize Convex:**
   ```bash
   npx convex dev
   ```
   - Creates new Convex project
   - Generates deployment URL
   - Pushes schema to cloud
   - Starts local dev server

2. **Update Environment Variables:**
   - Copy generated `NEXT_PUBLIC_CONVEX_URL` 
   - Copy generated `CONVEX_DEPLOYMENT`
   - Update both locally and in v0 Project Settings

#### 2.3 Schema Development
Update `convex/schema.ts` with real schema:
```typescript
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  tasks: defineTable({
    text: v.string(),
    isCompleted: v.boolean(),
    userId: v.string(),
    createdAt: v.number(),
  }),
  
  users: defineTable({
    clerkId: v.string(),
    email: v.string(),
    name: v.optional(v.string()),
    subscription: v.optional(v.string()),
    createdAt: v.number(),
  }).index("by_clerk_id", ["clerkId"]),
});
```

#### 2.4 Function Implementation
Create real Convex functions in `convex/tasks.ts`:
```typescript
import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

export const create = mutation({
  args: { text: v.string(), userId: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db.insert("tasks", {
      ...args,
      isCompleted: false,
      createdAt: Date.now(),
    });
  },
});

export const list = query({
  args: { userId: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("tasks")
      .filter((q) => q.eq(q.field("userId"), args.userId))
      .collect();
  },
});
```

#### 2.5 Generated Files Upload
After `npx convex dev` generates files:
1. **Copy from local `convex/_generated/`:**
   - `api.d.ts`
   - `dataModel.d.ts` 
   - `server.d.ts`

2. **Upload to v0:**
   - Create `convex/_generated/` directory in v0
   - Paste each file individually
   - Ensure exact file paths match

#### 2.6 UI Integration
Replace mock data calls with real Convex queries:
```typescript
// Before (mock data)
const tasks = getMockData('tasks');

// After (real Convex)
const tasks = useQuery(api.tasks.list, { userId: user.id });
```

**Phase 2 Deliverables:**
- ✅ Real database integration
- ✅ Type-safe queries/mutations
- ✅ Generated TypeScript definitions
- ✅ Working CRUD operations
- ✅ User-specific data isolation
- ✅ Diagnostics page shows green status

---

### Phase 3: Production Deployment
**Goal:** Full production-ready application

#### 3.1 Data Migration
Import existing mock data:
```bash
npx convex import --table tasks convex/mock/tasks.json
npx convex import --table users convex/mock/users.json
```

#### 3.2 Production Environment Setup
1. **Convex Production Deployment:**
   ```bash
   npx convex deploy
   ```
   - Creates production deployment
   - Generates production URLs
   - Configures environment variables

2. **Clerk Production Setup:**
   - Create production instance in Clerk Dashboard
   - Configure domain settings
   - Set up webhook endpoints
   - Update API keys

#### 3.3 Full Local Development
Transition to complete local development:
- All files in local repository
- Git version control
- Local development server
- Hot reload and debugging
- Advanced Convex features

#### 3.4 Advanced Features Implementation
- Real-time subscriptions
- File storage (Convex file storage)
- Advanced queries and indexes
- Cron jobs and scheduled functions
- Vector search capabilities
- Advanced authentication flows

#### 3.5 Production Deployment
Deploy to Vercel:
```bash
npx vercel deploy
```

Configure production environment variables:
```
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_live_...
CLERK_SECRET_KEY=sk_live_...
NEXT_PUBLIC_CONVEX_URL=https://production.convex.cloud
CONVEX_DEPLOYMENT=production:deployment-name
AI_GATEWAY_API_KEY=production_ai_key
```

**Phase 3 Deliverables:**
- ✅ Production database with real data
- ✅ Production authentication
- ✅ Custom domain deployment
- ✅ Monitoring and analytics
- ✅ Backup and recovery plans
- ✅ Performance optimization

---

## Workflow Best Practices

### File Synchronization
- **Local → v0:** Manual upload of generated files
- **v0 → Local:** Download ZIP when major changes made
- **Version Control:** Maintain local git repository
- **Documentation:** Track manual sync points

### Development Speed Optimization
- **UI Changes:** Use v0 for rapid iteration
- **Database Changes:** Use local Convex CLI
- **Testing:** Use `/convex` diagnostics page
- **Debugging:** Local environment for complex issues

### Quality Assurance
- **Phase 1:** UI/UX validation with stakeholders
- **Phase 2:** Data integrity and API testing
- **Phase 3:** Full end-to-end testing and performance validation

---

## Common Troubleshooting

### Environment Variables Issues
- Verify all keys are correctly set in both environments
- Check key format and permissions
- Ensure production vs development key usage

### Generated Files Problems
- Confirm `npx convex dev` ran successfully
- Verify exact file paths in v0
- Check TypeScript compilation errors

### Authentication Flow Issues
- Validate Clerk configuration matches environment
- Test sign-up/sign-in flows thoroughly  
- Verify webhook endpoints for production

### Database Connection Problems
- Check Convex deployment status
- Validate schema compilation
- Test with simple queries first
