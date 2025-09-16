# Day 3: Build

[⬅️ Day 3 Overview](README.md)

## 3.3 Payment Integration

**Goal**: Connect your application to billing via Clerk Billing (Stripe under the hood) for seamless subscription management.

**Process**: Follow this chat pattern with your AI coding tool such as [v0.app](https://v0.app). Pay attention to the notes in `[brackets]` and replace the bracketed text with your own content.

**Timeframe**: 30-45 minutes

### 3.3.1: Payment Requirements Analysis

```
I need to implement payment processing and subscription management for my SaaS application using Stripe. I've already built the core application, authentication system, and API integrations. Now I need to add payment capabilities.

Please paste your product requirements document sections related to pricing, subscriptions, and payment below:

<product-requirements-document>
[Paste relevant parts of your PRD from step 1.1 here, focusing on pricing tiers, billing, and payment requirements]
</product-requirements-document>

Based on these requirements, I need to implement the following payment components (Clerk Billing-first):

1. Clerk Billing configuration (plans, prices)
2. Subscription plan gating in app (via Clerk + Convex roles)
3. Checkout and Billing portal (hosted by Clerk/Stripe)
4. User subscription status display
5. Webhook/event handling (if implementing custom logic)

Please analyze my requirements and help me create a comprehensive payment implementation plan that:

1. Outlines the Stripe setup process
2. Details the necessary components for subscription management
3. Explains how to handle payment processing securely
4. Describes how to track subscription status in the application
5. Provides guidance on implementing webhooks and events

Please focus on creating a secure, user-friendly payment system that integrates seamlessly with Clerk + Convex and my existing authentication system.
```

### 3.3.2: Clerk Billing Configuration & Integration (preferred)

```
Let's start by setting up Clerk Billing (Stripe under the hood) and configuring the integration.

I need guidance on:

1. Configuring Clerk Billing plans and portal
2. Setting `CLERK_PLAN_ID` and plan mapping in app UI
3. Wiring hosted checkout and billing portal buttons
4. Reflecting subscription status in UI

Please provide step-by-step instructions and code examples for integrating Clerk Billing with my Next.js app and Convex authorization checks. Include details on securely storing required environment variables.
```

### 3.3.3: Subscription Management Implementation

```
Now I need to implement the subscription plan management functionality.

Please help me create:

1. A subscription plans component/page that displays:
   - Available subscription tiers
   - Features included in each tier
   - Pricing options (monthly/yearly)
   - Comparison table
   - CTA buttons for each plan

2. Subscription plan data management:
   - Displaying current user subscription status from Clerk
   - Handling plan changes and upgrades/downgrades via Clerk Billing portal
   - Mapping plan to feature entitlements (Convex roles/permissions)

3. Free tier implementation (if applicable):
   - Free trial period setup
   - Feature limitations
   - Upgrade prompts
   - Usage tracking

Please provide the code for these components and explain how to:
- Fetch and display subscription plans from Stripe
- Show the appropriate UI based on the user's current subscription
- Handle plan selection and the start of the checkout process
- Store minimal subscription state in Convex if needed for authorization checks (else read from Clerk)
```

### 3.3.4: Webhook Implementation (Optional / Advanced)

```
If I need custom logic beyond what Clerk Billing provides, I may implement webhooks.

Please help me create:

1. A webhook endpoint that:
   - Verifies Stripe signatures
   - Processes relevant events
   - Updates the database accordingly
   - Handles errors gracefully

2. Event handlers for key subscription events:
   - `checkout.session.completed`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.paid`
   - `invoice.payment_failed`

3. Subscription lifecycle management:
   - Handling failed payments
   - Processing subscription cancellations
   - Managing subscription updates
   - Dealing with payment method changes

Please provide the complete code for implementing this webhook system and explain how to test it locally using Stripe's webhook testing tools. Include error handling and security best practices.
```

### 3.3.5: Testing & Troubleshooting

```
Finally, I need to thoroughly test my payment system to ensure it works correctly.

Please help me with:

1. Testing strategies for:
   - Creating test subscriptions
   - Simulating payment successes and failures
   - Testing webhook events
   - Verifying subscription state changes

2. Common issues and how to troubleshoot:
   - Webhook delivery problems
   - API errors and rate limiting
   - Payment failures
   - Subscription sync issues

3. Monitoring and logging:
   - Tracking important payment events
   - Logging webhook processing
   - Setting up alerts for payment failures
   - Monitoring subscription metrics

Please provide a comprehensive testing plan and troubleshooting guide for my Stripe integration, including test credit card numbers and webhook event examples for testing various scenarios.
``` 