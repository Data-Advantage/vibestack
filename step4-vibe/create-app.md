# Prompt 1: Project Setup with Existing Supabase Integration
```
Create a new Next.js 15 project with TypeScript, App Router, and Tailwind CSS according to the specifications in config-files.md. Install shadcn/ui and Lucide icons. Set up the project structure following the patterns in project-structure.md. Note that Supabase integration has already been configured with necessary environment variables. Create a .env.example file to document all the required environment variables for future reference and project maintenance. Include placeholders for Supabase credentials, authentication redirect URLs, and any other configuration variables mentioned in integration-details.md.
```

# Prompt 2: Authentication Framework

```
Implement the authentication system using Supabase Auth with Google OAuth as specified in auth-implementation.md. Create the auth middleware for protected routes, auth utilities in lib/supabase/client.ts and server.ts, login/signup components with Google OAuth support, an auth provider component for global state management, and logic for protected route redirection. Follow the patterns and best practices outlined in auth-implementation.md and project-structure.md.
```

# Prompt 3: Database Schema and Data Access

```
Design and implement the core database tables (users, subscriptions, products) in Supabase following the patterns in database-patterns.md. Set up Row Level Security policies as described in the database guide. Generate TypeScript types for the database schema as outlined in typescript-patterns.md. Create database triggers for new user signup events and implement data fetching utilities for interaction with the Supabase database.
```

# Prompt 4: Stripe Integration

```
Set up Stripe integration for subscription handling as detailed in integration-details.md. Implement a webhook endpoint at app/api/webhooks/stripe/route.ts to process Stripe events. Create the necessary database schema updates to track subscription status. Build checkout session creation logic, and ensure proper synchronization between Stripe and the Supabase database. Implement proper error handling and webhook verification.
```

# Prompt 5: Core UI Components

```
Develop the core UI components following the guidelines in ui-components.md. Create layout components including header and navigation. Build a dashboard shell that displays authenticated user information. Implement a subscription status indicator component. Create a payment component with Stripe Checkout redirect. Add responsive styling for both mobile and desktop views. Ensure all components follow the accessibility standards in accessibility-standards.md.
```

# Prompt 6: Essential User Flows

```
Implement the complete user flows from signup to paid conversion, following the authentication patterns in auth-implementation.md. Create a subscription management page that displays current subscription status and allows upgrades/downgrades. Build an account settings page where users can manage their profile information. Implement a Stripe customer portal redirect for subscription management. Add subscription tier gating for features using Row Level Security as described in database-patterns.md.
```

#Prompt 7: AI SDK Integration (Optional)

```
Integrate the AI capabilities using the patterns described in ai-sdk-core.md and ai-sdk-providers.md. Implement the UI components for AI interactions as outlined in ai-sdk-ui.md. Ensure the AI features are properly gated based on subscription tiers, and that they follow the security best practices outlined in the documentation.
```

# Prompt 8: Finalization and Quality Assurance

```
Implement error boundaries and fallbacks throughout the application. Add SEO metadata to all relevant pages. Implement loading states and optimistic updates for better user experience. Create a comprehensive test plan covering authentication, payment processing, and general navigation. Configure all environment variables for production deployment to Vercel. Verify that all Row Level Security policies are working correctly and that Stripe webhooks are processing as expected. Ensure mobile responsiveness according to accessibility-standards.md.
```