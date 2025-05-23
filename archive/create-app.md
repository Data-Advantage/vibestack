# Prompt 1: Project Setup with Existing Supabase Integration
```
Create a stub Next.js 15 project with a root landing page that will eventually become the app described in the Project Settings Source file `product-requirements-document.md`. Use TypeScript, App Router, and Tailwind CSS according to the specifications in Project Settings Sources file `config-files.md`. Install shadcn/ui and Lucide icons. Set up only the following core files and directories:

Files to create (see details in Project Settings Source file `config-files.md`):
- next.config.js (Next 15)
- postcss.config.mjs
- tsconfig.json
- .env.example (documenting all required environment variables)
- app/layout.tsx (root layout)
- app/page.tsx (landing page)
- app/globals.css
- lib/constants/config.ts
- lib/constants/routes.ts
- public/logo.svg
- public/robots.txt

Files to NOT create:
- tailwind.config.ts (obsolete in Tailwind v4)

Note that Supabase integration has already been configured with necessary environment variables. The .env.example file should document all the required environment variables for future reference including placeholders for Supabase credentials, authentication redirect URLs, and any other configuration variables mentioned in integration-details.md.```

# Prompt 2: Authentication Framework

## Step 1: Basic Supabase Setup & Environment Configuration

This step focuses on establishing the foundation and validating the basic connection to Supabase.

```
Implement the core Supabase configuration and test the connection.

Files to create:
- lib/supabase/client.ts (browser client)
- lib/supabase/server.ts (server client)
- .env.local (ensure all Supabase environment variables are set correctly)
- components/auth/client-test-connection.tsx (client component with interactive button to test browser connectivity)
- components/auth/server-test-connection.tsx (server component that automatically tests server connectivity)
- components/auth/env-variables-check.tsx (shows if the env relevant env vars are installed)
- app/auth-test/page.tsx (test page to verify setup)

First, ensure your .env.local file contains the correct Supabase variables:
- NEXT_PUBLIC_SUPABASE_URL
- NEXT_PUBLIC_SUPABASE_ANON_KEY
- SUPABASE_SERVICE_ROLE_KEY (for admin functions)

Create the basic Supabase clients and a simple test page to verify you can connect to Supabase successfully before proceeding to authentication flows.

Connection Tests:
- Both tests should use `auth.getSession()` which is guaranteed to work with any Supabase project
- Display the actual JSON response data to confirm data is being returned
- Include proper loading states, success/error handling, and user feedback
- The test page should display environment variable status to verify configuration
- Show if relevant Environment Variables are set
```

## Step 2: Core Authentication UI & Client-Side Auth

This step implements the basic authentication UI and client-side authentication flows without relying on server actions initially.

```
Implement the core authentication UI components and basic client-side authentication.

Files to create:
- components/auth/login-form.tsx (client-side authentication)
- components/auth/signup-form.tsx (client-side authentication)
- components/providers/auth-provider.tsx (global auth state)
- lib/hooks/use-auth.ts (simplified auth hooks)
- app/(auth)/layout.tsx (basic layout for auth pages)
- app/(auth)/login/page.tsx
- app/(auth)/signup/page.tsx
- app/dashboard/page.tsx (simple dashboard showing auth success)

Focus on implementing client-side authentication first using the createClientComponentClient from Supabase. Don't implement server actions yet. The goal is to get a simple login/signup flow working that can authenticate users and store their session information properly. Use simple React state and context for managing authentication state.
```

## Step 3: Server Actions, Middleware & Advanced Features

After basic authentication is working, this step adds the more complex server-side components and protected routes.

```
Implement server actions, middleware, and additional authentication features.

Files to create:
- middleware.ts (auth middleware for protected routes)
- lib/supabase/middleware.ts (auth refresh helpers)
- lib/actions/auth.ts (auth-related server actions)
- app/(auth)/login/actions.ts
- app/(auth)/signup/actions.ts
- app/(auth)/confirm/route.ts
- app/(auth)/reset-password/page.tsx
- app/(auth)/reset-password/actions.ts
- components/auth/password-reset-form.tsx
- app/dashboard/layout.tsx (dashboard layout with auth protection)
- types/api/requests.ts (auth-related requests)
- types/api/responses.ts (auth-related responses)

For Google OAuth implementation:
1. Add UI components with visually complete "Login with Google" buttons
2. Include code stubs with TODO comments for future implementation

Once basic email/password authentication is working correctly, gradually implement the more complex server-side authentication features. Convert client-side auth to server actions if desired. Add middleware to protect routes and implement additional features like password reset.
```

## Original (working to decompose this)

```
Implement the authentication system using Supabase Auth with email/password authentication as specified in Project Settings Sources file `auth-implementation.md`, and add code stubs for Google OAuth to be fully implemented later. Use the UI components for Authentication/Login as specified in `ui-components.md`.

Files to create:
- middleware.ts (auth middleware for protected routes)
- lib/supabase/client.ts (browser client)
- lib/supabase/server.ts (server client)
- lib/supabase/middleware.ts (auth refresh helpers)
- lib/actions/auth.ts (auth-related server actions)
- lib/hooks/use-auth.ts (auth-related hooks)
- components/providers/auth-provider.tsx (global auth state)
- components/auth/login-form.tsx
- components/auth/signup-form.tsx
- components/auth/password-reset-form.tsx
- app/(auth)/layout.tsx
- app/(auth)/login/page.tsx
- app/(auth)/login/actions.ts
- app/(auth)/signup/page.tsx
- app/(auth)/signup/actions.ts
- app/(auth)/confirm/route.ts
- app/(auth)/reset-password/page.tsx
- app/(auth)/reset-password/actions.ts
- app/dashboard/page.tsx (basic dashboard showing successful login)
- app/dashboard/layout.tsx (dashboard layout)
- types/api/requests.ts (auth-related requests)
- types/api/responses.ts (auth-related responses)

For Google OAuth implementation:
1. Create UI components with visually complete "Login with Google" buttons in the login/signup forms
2. Add code stubs with clearly marked TODO comments indicating Google OAuth will be implemented later
3. Include commented-out code showing what the eventual implementation will look like
4. Do not implement the actual Google OAuth functionality yet (this will be done later)

Create a basic dashboard page that displays the logged-in user's email and name (if available) to provide visual confirmation that authentication was successful. Redirect unauthenticated users to the login page.

Follow the patterns and best practices outlined in auth-implementation.md and project-structure.md for implementing protected route redirection and properly structuring the auth code.
```

# Prompt 3: Database Schema and Data Access

```
Design and implement the core database tables (users, subscriptions, products) in Supabase following the patterns in database-patterns.md.

Files to create:
- lib/supabase/admin.ts (admin client for server-side only)
- lib/supabase/types.ts (re-exports of generated types)
- types/supabase.ts (generated database types)
- lib/utils/formatting.ts (data formatting utilities)
- lib/utils/validation.ts (input validation helpers)
- types/forms/[domain].ts (appropriate domain-specific form types)
- types/[domain]/index.ts (domain-specific type exports)

Set up Row Level Security policies as described in the database guide. Generate TypeScript types for the database schema as outlined in typescript-patterns.md. Create database triggers for new user signup events and implement data fetching utilities for interaction with the Supabase database.
```

# Prompt 4: Stripe Integration

```
Set up Stripe integration for subscription handling as detailed in Project Settings -> Sources: `stripe.md`.

Files to create:
- app/api/webhooks/stripe/route.ts (webhook endpoint)
- lib/actions/[payment_domain].ts (payment-related server actions)
- components/[payment_domain]/checkout-button.tsx
- components/[payment_domain]/subscription-status.tsx
- types/api/requests.ts (payment-related requests)
- types/api/responses.ts (payment-related responses)
- lib/hooks/use-subscription.ts

Implement the webhook endpoint to process Stripe events. Ensure that there is a sufficient database schema to track subscription status. Build checkout session creation logic, and ensure proper synchronization between Stripe and the Supabase database. Implement proper error handling and webhook verification. Ask me for any ENV variables that are needed.
```

# Prompt 5: Core UI Components

```
Develop the core UI components following the guidelines in ui-components.md.

Files to create:
- components/ui/button.tsx
- components/ui/form.tsx
- components/ui/input.tsx
- components/ui/card.tsx
- components/ui/dialog.tsx
- components/ui/toast.tsx
- components/ui/dropdown-menu.tsx
- components/ui/avatar.tsx
- components/layout/header.tsx
- components/layout/footer.tsx
- components/layout/sidebar.tsx
- components/providers/theme-provider.tsx
- app/not-found.tsx (404 page)
- app/error.tsx (global error page)
- app/(marketing)/layout.tsx
- app/(marketing)/page.tsx (homepage)
- public/logo-dark.svg
- public/logo-mark.svg
- public/apple-touch-icon.png

Add responsive styling for both mobile and desktop views. Ensure all components follow the accessibility standards in accessibility-standards.md.
```

# Prompt 6: Essential User Flows

```
Implement the complete user flows from signup to paid conversion.

Files to create:
- app/dashboard/page.tsx (main dashboard)
- app/dashboard/layout.tsx (dashboard layout with navigation)
- app/dashboard/[feature]/page.tsx (create feature-specific pages)
- app/dashboard/[feature]/actions.ts (feature-specific server actions)
- app/dashboard/settings/page.tsx (account settings)
- app/dashboard/billing/page.tsx (subscription management)
- components/dashboard/user-nav.tsx
- components/dashboard/main-nav.tsx
- components/dashboard/subscription-card.tsx
- lib/actions/[domain].ts (domain-specific server actions)
- lib/hooks/use-[domain].ts (domain-specific hooks)
- app/(marketing)/about/page.tsx
- app/(marketing)/pricing/page.tsx
- app/(marketing)/contact/page.tsx

Add a small informational note near the Google login buttons to clarify that Google login will be available after deployment.

Create a subscription management page that displays current subscription status and allows upgrades/downgrades. Build an account settings page where users can manage their profile information. Implement a Stripe customer portal redirect for subscription management. Add subscription tier gating for features using Row Level Security.
```


#Prompt 7: AI SDK Integration (Optional)

```
Integrate the AI capabilities using the patterns described in ai-sdk-core.md and ai-sdk-providers.md.

Files to create:
- components/ai/chat-interface.tsx
- components/ai/prompt-input.tsx
- components/ai/response-display.tsx
- lib/ai/providers.ts
- lib/ai/models.ts
- lib/hooks/use-ai.ts
- app/dashboard/ai-features/page.tsx
- app/dashboard/ai-features/actions.ts
- types/ai/index.ts

Implement the UI components for AI interactions as outlined in ai-sdk-ui.md. Ensure the AI features are properly gated based on subscription tiers, and that they follow the security best practices outlined in the documentation.
```

# Prompt 8: Finalization and Quality Assurance

```
Implement error boundaries, SEO, Google OAuth authentication, and finalize the application.

Files to update or create:
- lib/supabase/client.ts (update with Google OAuth implementation)
- lib/actions/auth.ts (update with Google OAuth implementation)
- components/auth/login-form.tsx (enable Google login button functionality)
- components/auth/signup-form.tsx (enable Google login button functionality)
- app/(auth)/login/actions.ts (update to handle Google OAuth)

New files to create:
- app/(seo)/layout.tsx
- app/(seo)/[category]/page.tsx
- app/(seo)/[category]/[slug]/page.tsx
- app/(seo)/sitemap.xml/route.ts
- app/sitemap.ts
- app/(marketing)/blog/page.tsx
- app/(marketing)/blog/[slug]/page.tsx
- app/api/[domain]/route.ts (any remaining API endpoints)
- components/layout/error-boundary.tsx
- components/ui/fallback.tsx
- lib/utils/error-handling.ts

For Google OAuth implementation:
1. Uncomment and complete the Google OAuth code stubs created in Prompt 2
2. Connect the Google login buttons to the actual authentication flow
3. Ensure proper redirection and error handling for Google OAuth
4. Test the complete authentication flow with Google

Add SEO metadata to all relevant pages. Implement loading states and optimistic updates for better user experience. Create a comprehensive test plan covering authentication, payment processing, and general navigation. Configure all environment variables for production deployment to Vercel. Verify that all Row Level Security policies are working correctly and that Stripe webhooks are processing as expected. Ensure mobile responsiveness according to accessibility-standards.md.
```