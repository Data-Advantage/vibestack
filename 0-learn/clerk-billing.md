# Clerk Billing for B2C SaaS - Vibe Code Tool Implementation Guide

## 🚨 Important Beta Notice

> **Warning**: This feature is currently in Beta. The low-level JavaScript APIs exposed via `Clerk.billing` are experimental and may undergo breaking changes. To mitigate potential disruptions, we recommend pinning your SDK and clerk-js package versions.

## Overview

Clerk billing for B2C SaaS allows you to create subscription plans and manage billing for individual users in your Vibe Code Tool application. This guide covers the complete setup process for implementing user-based subscription billing.

### Key Features
- ✅ Individual user subscriptions
- ✅ Multiple pricing tiers
- ✅ Feature-based access control
- ✅ Built-in pricing table component
- ✅ Stripe integration for payments

### Pricing
- **Clerk Billing**: 0.7% per transaction
- **Stripe Fees**: Paid directly to Stripe
- No additional Stripe Billing setup required

## Getting Started

### 1. Enable Billing

1. Navigate to the [Billing Settings page](https://dashboard.clerk.com) in your Clerk Dashboard
2. Follow the guided setup process
3. Choose your payment gateway option:
   - **Clerk Development Gateway**: Shared test Stripe account for development
   - **Stripe Account**: Connect your own Stripe account for production

### 2. Create Your Plans

## Environment Configuration

Add this section after "Getting Started":

```typescript
// .env.local
CLERK_PLAN_ID=plan_pro_xyz123  # Your Pro plan ID from Clerk Dashboard
```

## Plan Structure (Replace the existing plan structure)

```
Free Plan (Default):
- ✅ Basic code generation
- ✅ 10 generations/month
- ✅ Community support

Pro Plan ($30/month):
- ✅ Everything in Free
- ✅ AI-powered suggestions  
- ✅ Unlimited generations
- ✅ Code export in multiple formats
- ✅ Priority support
```

## Implementation Changes

Replace the access control examples with:

```typescript
// utils/billing.ts
import { auth } from '@clerk/nextjs/server'

const PRO_PLAN_ID = process.env.CLERK_PLAN_ID!

export async function checkUserAccess() {
  const { has } = await auth()
  
  return {
    isPro: has({ plan: PRO_PLAN_ID }),
    canUseAI: has({ plan: PRO_PLAN_ID }),
    canExportUnlimited: has({ plan: PRO_PLAN_ID }),
    hasPrioritySupport: has({ plan: PRO_PLAN_ID })
  }
}
```

```typescript
// app/ai-features/page.tsx (Updated example)
import { auth } from '@clerk/nextjs/server'

export default async function AIFeaturesPage() {
  const { has } = await auth()
  const PRO_PLAN_ID = process.env.CLERK_PLAN_ID!

  const hasProPlan = has({ plan: PRO_PLAN_ID })

  if (!hasProPlan) {
    return (
      <div className="p-8 text-center">
        <h1 className="text-2xl font-bold mb-4">Pro Feature</h1>
        <p>Upgrade to Pro to access advanced AI code suggestions.</p>
        <a href="/pricing" className="btn btn-primary mt-4">
          Upgrade to Pro
        </a>
      </div>
    )
  }

  return (
    <div>
      <h1>AI-Powered Code Suggestions</h1>
      {/* Your Pro AI features here */}
    </div>
  )
}
```

```typescript
// Updated Protect component example
<Protect
  plan={process.env.CLERK_PLAN_ID}
  fallback={
    <div className="upgrade-prompt">
      <h3>🚀 Unlock Pro Features</h3>
      <p>Upgrade to Pro for unlimited access</p>
      <a href="/pricing">Upgrade Now</a>
    </div>
  }
>
  <div className="pro-features">
    <h2>Pro Tools</h2>
    {/* Pro features */}
  </div>
</Protect>

### 3. Add Features to Plans

Features enable granular access control for your Vibe Code Tool functionality.

**Example Features:**
- `code-generation`: Basic code generation
- `ai-suggestions`: Advanced AI-powered suggestions
- `unlimited-exports`: Unlimited code exports
- `priority-support`: Priority customer support

#### Adding Features:
1. Go to **Plans** page in Clerk Dashboard
2. Select your plan
3. In the **Features** section, click **Add Feature**
4. Define feature name and description

## Implementation

### Create a Pricing Page

Create a dedicated pricing page for your Vibe Code Tool users:

```typescript
// app/pricing/page.tsx
import { PricingTable } from '@clerk/nextjs'

export default function PricingPage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="text-center mb-8">
        <h1 className="text-4xl font-bold mb-4">
          Choose Your Vibe Code Tool Plan
        </h1>
        <p className="text-lg text-gray-600">
          Unlock the full potential of AI-powered code generation
        </p>
      </div>
      
      <div style={{ maxWidth: '1200px', margin: '0 auto' }}>
        <PricingTable />
      </div>
    </div>
  )
}
```

### Access Control Implementation

#### Method 1: Using `has()` Method

**Protect Premium Features:**
```typescript
// app/ai-features/page.tsx
import { auth } from '@clerk/nextjs/server'

export default async function AIFeaturesPage() {
  const { has } = await auth()

  const hasProPlan = has({ plan: 'pro' })
  const hasAIFeatures = has({ feature: 'ai-suggestions' })

  if (!hasProPlan || !hasAIFeatures) {
    return (
      <div className="p-8 text-center">
        <h1 className="text-2xl font-bold mb-4">Premium Feature</h1>
        <p>Upgrade to Pro to access advanced AI code suggestions.</p>
        <a href="/pricing" className="btn btn-primary mt-4">
          View Plans
        </a>
      </div>
    )
  }

  return (
    <div>
      <h1>AI-Powered Code Suggestions</h1>
      {/* Your premium AI features here */}
    </div>
  )
}
```

**Feature-based Access:**
```typescript
// Check for specific features
const canExportUnlimited = has({ feature: 'unlimited-exports' })
const hasPrioritySupport = has({ feature: 'priority-support' })
```

#### Method 2: Using `<Protect>` Component

**Protect Code Generation Features:**
```typescript
// app/code-generator/page.tsx
import { Protect } from '@clerk/nextjs'

export default function CodeGeneratorPage() {
  return (
    <div>
      <h1>Vibe Code Generator</h1>
      
      {/* Basic features available to all */}
      <div className="basic-features">
        <h2>Basic Code Generation</h2>
        {/* Basic functionality */}
      </div>

      {/* Pro features protected */}
      <Protect
        feature="ai-suggestions"
        fallback={
          <div className="upgrade-prompt">
            <h3>🚀 Unlock AI Suggestions</h3>
            <p>Upgrade to Pro for intelligent code suggestions</p>
            <a href="/pricing">Upgrade Now</a>
          </div>
        }
      >
        <div className="pro-features">
          <h2>AI-Powered Suggestions</h2>
          {/* Advanced AI features */}
        </div>
      </Protect>

      {/* Enterprise features */}
      <Protect
        plan="enterprise"
        fallback={<p>Enterprise features available with Enterprise plan</p>}
      >
        <div className="enterprise-features">
          <h2>Enterprise Tools</h2>
          {/* Enterprise-only features */}
        </div>
      </Protect>
    </div>
  )
}
```

### Usage Limits and Feature Gating

```typescript
// utils/billing.ts
import { auth } from '@clerk/nextjs/server'

export async function checkUserAccess() {
  const { has } = await auth()
  
  return {
    hasBasic: has({ plan: 'starter' }),
    hasPro: has({ plan: 'pro' }),
    hasEnterprise: has({ plan: 'enterprise' }),
    canUseAI: has({ feature: 'ai-suggestions' }),
    canExportUnlimited: has({ feature: 'unlimited-exports' }),
    hasPrioritySupport: has({ feature: 'priority-support' })
  }
}

// Usage in components
export default async function Dashboard() {
  const access = await checkUserAccess()
  
  return (
    <div>
      {access.canUseAI && <AIFeaturesPanel />}
      {access.hasPrioritySupport && <PrioritySupportWidget />}
    </div>
  )
}
```

## Best Practices for Vibe Code Tool

### 1. Plan Structure Recommendations

```
Starter Plan ($9/month):
- ✅ Basic code generation
- ✅ 100 generations/month
- ✅ Community support

Pro Plan ($29/month):
- ✅ Everything in Starter
- ✅ AI-powered suggestions
- ✅ Unlimited generations
- ✅ Code export in multiple formats
- ✅ Email support

Enterprise Plan ($99/month):
- ✅ Everything in Pro
- ✅ Priority support
- ✅ Custom integrations
- ✅ Team collaboration
- ✅ Advanced analytics
```

### 2. Feature Organization

```typescript
// Define features clearly
const FEATURES = {
  BASIC_GENERATION: 'code-generation',
  AI_SUGGESTIONS: 'ai-suggestions', 
  UNLIMITED_EXPORTS: 'unlimited-exports',
  PRIORITY_SUPPORT: 'priority-support',
  TEAM_COLLABORATION: 'team-collaboration',
  CUSTOM_INTEGRATIONS: 'custom-integrations'
} as const
```

### 3. Graceful Upgrade Prompts

```typescript
// components/UpgradePrompt.tsx
interface UpgradePromptProps {
  feature: string
  planRequired: string
}

export function UpgradePrompt({ feature, planRequired }: UpgradePromptProps) {
  return (
    <div className="border-2 border-dashed border-gray-300 p-6 text-center rounded-lg">
      <h3 className="text-lg font-semibold mb-2">
        🔓 Unlock {feature}
      </h3>
      <p className="text-gray-600 mb-4">
        Upgrade to {planRequired} to access this feature
      </p>
      <a 
        href="/pricing" 
        className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700"
      >
        View Plans
      </a>
    </div>
  )
}
```

## Important Notes

1. **Version Pinning**: Pin your Clerk SDK versions during beta
2. **Testing**: Use the development gateway for testing
3. **Migration**: Plans created in Clerk Dashboard won't sync with existing Stripe products
4. **Combination**: You can combine B2C and B2B billing in the same app if needed

## Resources

- [Clerk Dashboard](https://dashboard.clerk.com)
- [Clerk Billing Documentation](https://clerk.com/docs)
- [Stripe Integration Guide](https://stripe.com/docs)
