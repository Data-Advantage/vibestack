# Day 3: Build

[⬅️ Day 3 Overview](README.md)

## 3.1 Authentication System

**Goal**: Implement a robust authentication system with proper user management flows using Clerk (auth + billing).

**Process**: Follow this chat pattern with your AI coding tool such as v0.app. Pay attention to the notes in `[brackets]` and replace the bracketed text with your own content.

**Timeframe**: 30-45 minutes

### 3.1.1: Authentication Requirements Analysis

```
I need to implement a complete authentication system for my SaaS application. I've already built a prototype and refined it based on user feedback. Now I need to add proper authentication flows.

Please paste your product requirements document below:

<product-requirements-document>
[Paste your PRD from step 1.1 here]
</product-requirements-document>

Based on these requirements, I need to implement the following authentication components:

1. User authentication with Clerk
2. Email/password signup with email verification
3. Social login options (if applicable to your product)
4. Secure session management (via Clerk)
5. Password reset functionality (via Clerk)
6. User profile management (Clerk UI)
7. Role-based access control for different user types (app roles in Convex)

Please analyze my requirements and help me create a comprehensive authentication implementation plan that:

1. Outlines each authentication flow in detail
2. Identifies the UI components needed for each flow
3. Provides guidance on implementing security best practices
4. Explains how to connect the auth system to my existing application
5. Suggests testing strategies for each authentication component

Please focus on creating a secure, user-friendly authentication system that integrates seamlessly with Clerk and Convex.
```

### 3.1.2: Signup & Email Verification (Clerk)

```
Let's start by implementing the user signup and email verification flow. I need to create:

1. A signup experience using Clerk components with:
   - Email field with validation
   - Password field with strength requirements
   - Name/profile fields as needed
   - Terms of service acceptance

2. The email verification process using Clerk-hosted UI:
   - Verification email sending
   - Verification page/route
   - Success/error states
   - Redirect to login after verification

Please provide the code for these components and explain how to:
- Connect them to Clerk components (SignUp, SignIn)
- Handle form validation and errors
- Manage the verification flow
- Implement proper security measures
- Style the components according to my design system
 - Wire `middleware.ts` and `ClerkProvider` in `app/layout.tsx`
 - Use `SignedIn`/`SignedOut`/`UserButton` for navigation
 - Set required env vars: `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`, `CLERK_SECRET_KEY`

Note: I'm using Next.js App Router, Clerk, and Convex.
```

### 3.1.3: Login & Session Management (Clerk)

```
Now I need to implement the login functionality and session management for my application.

Please help me create:

1. A login experience using Clerk:
   - Email/password and optional OAuth
   - Forgot password link (Clerk-managed)
   - Login button with loading state
   - Option to navigate to signup

2. Session management implementation (handled by Clerk):
   - Session persistence and refresh
   - Token handling via Clerk middleware and provider

3. Authentication state management:
   - Use `SignedIn`, `SignedOut`, `UserButton`
   - Protected routes/pages (middleware)
   - Redirect logic for authenticated/unauthenticated users
   - Loading states during auth checks
   - Ensure `ClerkProvider` is wrapping the App Router in `app/layout.tsx`

Please provide the complete code for these components and explain how to integrate them with my existing application structure.
```

### 3.1.4: Password Reset Flow (Clerk-managed)

```
I need to implement a secure password reset flow for my application.

Please help me:

1. Use Clerk-hosted reset flow and components
2. Configure redirect URLs and success states
3. Ensure security best practices

Provide the minimal code and configuration to wire this up.
```

### 3.1.5: User Profile Management (Clerk UI)

```
Now I need to implement user profile management functionality that allows users to:
- View their profile information
- Update personal details
- Manage email preferences/notifications
- Delete their account (if applicable)

Please help me:
- Add a `/user` route using `<UserProfile />`
- Integrate it into the header via `<UserButton />`
- Display subscription status via Clerk Billing portal
```

### 3.1.6: Role-Based Access Control

```
I need to implement role-based access control (RBAC) for my application to manage different user types and their permissions.

Based on my product requirements, I need to manage these user roles:
[List your specific user roles, such as:
- Admin
- Paid user
- Free user
- Organization owner
- Team member
- etc.]

For each role, I need to:
1. Define specific permissions/capabilities
2. Restrict access to certain features/routes
3. Show/hide UI elements based on permissions
4. Apply server-side authorization checks

Please help me create:

1. A role management system that:
   - Stores user roles in Convex (app-specific roles)
   - Validates permissions on both client and server
   - Handles role assignment and changes

2. Protected components/routes that:
   - Check for required permissions
   - Redirect unauthorized users
   - Gracefully handle permission errors
   - Show appropriate UI for different roles

3. Admin functionality for role management (if applicable)

Please provide the code for implementing this RBAC system and explain how to integrate it with Clerk and Convex.
```

### 3.1.7: Testing & Security Audit

```
To ensure my authentication system is secure and working correctly, I need to implement comprehensive testing and perform a security audit.

Please help me with:

1. Testing strategies for:
   - Unit testing authentication components
   - Integration testing auth flows
   - Edge case handling (network errors, timeouts, etc.)
   - Testing across different browsers/devices

2. Security considerations:
   - Rate limiting and brute force protection
   - Token security and management (Clerk)
   - CSRF protection
   - XSS prevention
   - Secure data storage

3. Common authentication vulnerabilities to check:
   - Account enumeration
   - Password reset vulnerabilities
   - Session fixation
   - Insecure direct object references

Please provide guidance on implementing these tests and security measures, along with any code snippets or configuration needed to secure my authentication system.
```

### 3.1.8: Implementation Review & Optimization

```
Now that we've designed all aspects of the authentication system, let's review the implementation and identify any optimizations or improvements:

1. Review the complete authentication flow from signup to profile management:
   - Are there any gaps or missing components?
   - Is the user experience smooth and intuitive?
   - Are there opportunities to streamline the process?

2. Identify performance optimizations:
   - Reducing unnecessary renders/reflows
   - Optimizing authentication checks
   - Lazy load auth components where possible

3. Accessibility considerations:
   - Keyboard navigation for all auth forms
   - Screen reader compatibility
   - Focus management
   - Clear error messaging

4. Mobile responsiveness:
   - Touch-friendly inputs
   - Viewport adaptations
   - Testing on various devices

Please provide recommendations for these improvements along with any final code adjustments needed to complete the authentication system implementation.
``` 