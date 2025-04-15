# Day 3: Build

[⬅️ Day 3 Overview](README.md)

## 3.6 Testing & Quality Assurance

**Goal**: Verify that your application works as expected and fix any remaining issues.

**Process**: Follow this chat pattern with your AI coding tool such as [v0.dev](https://www.v0.dev). Pay attention to the notes in `[brackets]` and replace the bracketed text with your own content.

**Timeframe**: 30-45 minutes

### 3.6.1: Testing Strategy & Plan

```
Now that I've built the core functionality of my application, I need to implement a comprehensive testing strategy to ensure everything works correctly before launch.

Please help me create:

1. A testing strategy that covers:
   - Unit testing for critical components and functions
   - Integration testing for feature workflows
   - End-to-end testing for critical user journeys
   - Cross-browser and device compatibility testing
   - Accessibility testing
   - Performance testing

2. Testing priorities based on:
   - Core user flows (authentication, payment, main features)
   - High-risk areas (financial transactions, data persistence)
   - Areas with complex business logic
   - Reported issues from user feedback

3. A practical testing plan that:
   - Outlines what to test manually vs. automatically
   - Suggests appropriate testing tools for my tech stack
   - Provides a methodical approach for thorough testing
   - Considers time constraints before launch

Please help me develop this testing strategy with specific recommendations for my [Next.js/React/etc.] application with Supabase backend, keeping in mind I'm aiming to launch soon and need to focus on the most critical tests first.
```

### 3.6.2: Core User Flow Testing

```
I need to thoroughly test the core user flows in my application to ensure they work correctly end-to-end.

Please help me create test cases for these critical user journeys:

1. User authentication flow:
   - Signup process
   - Email verification
   - Login/logout
   - Password reset
   - Account management

2. Subscription and payment flow:
   - Plan selection
   - Checkout process
   - Subscription management
   - Payment method updates
   - Handling expired/failed payments

3. Core feature flows:
   - [Describe your main feature flow 1]
   - [Describe your main feature flow 2]
   - [Describe your main feature flow 3]

For each flow, please provide:
- Step-by-step test cases
- Expected results at each step
- Edge cases to test
- Common failure points to check
- Suggestions for how to automate these tests

I need both manual testing procedures and code examples for automated tests where appropriate.
```

### 3.6.3: Error Handling & Edge Cases

```
I need to test error handling and edge cases in my application to ensure it's robust and provides good user experience even when things go wrong.

Please help me identify and test:

1. Critical error scenarios:
   - Network connection failures
   - API errors and timeouts
   - Database errors
   - Authentication failures
   - Payment processing errors

2. Edge cases for user inputs:
   - Empty or incomplete form submissions
   - Invalid data inputs
   - Boundary value cases
   - Large data sets
   - Special characters and encoding issues

3. State management edge cases:
   - Race conditions
   - Concurrent operations
   - Interrupted operations (page reload, browser close)
   - Session expiration
   - User role transitions

4. Device and environment variations:
   - Slow network connections
   - Low-end device performance
   - Storage limitations
   - Browser permission denials
   - Ad blockers and privacy extensions

For each category, please provide specific test cases and code examples for implementing proper error handling and graceful degradation. Include both frontend and backend considerations.
```

### 3.6.4: Cross-Browser & Responsive Testing

```
I need to ensure my application works correctly across different browsers, devices, and screen sizes.

Please help me create:

1. A browser testing matrix covering:
   - Modern browsers (Chrome, Firefox, Safari, Edge)
   - Mobile browsers (iOS Safari, Chrome for Android)
   - Minimum supported browser versions
   - Critical features to test in each browser

2. Responsive design testing strategy:
   - Key breakpoints to test
   - Device-specific issues to watch for
   - Layout testing methodology
   - Touch vs. mouse interaction differences

3. Common cross-browser issues to check:
   - CSS compatibility
   - JavaScript API support
   - Form handling differences
   - Animation and rendering
   - Web API support variations

4. Testing tools and approaches:
   - Browser developer tools
   - Device emulators
   - Cross-browser testing services
   - Responsive design testing tools
   - Automated cross-browser testing

Please provide a structured approach to efficiently test across browsers and devices, with specific tools and techniques for my [Next.js/React/etc.] application.
```

### 3.6.5: Accessibility Testing

```
I need to ensure my application is accessible to users with disabilities and complies with accessibility standards.

Please help me implement:

1. Accessibility testing for:
   - Keyboard navigation
   - Screen reader compatibility
   - Color contrast and visual presentation
   - Form labels and error messages
   - Focus management
   - Alternative text for images

2. WCAG compliance checking:
   - WCAG 2.1 AA compliance requirements
   - Automated accessibility testing tools
   - Manual testing procedures
   - Documentation of compliance

3. Common accessibility issues to address:
   - Missing or inadequate alternative text
   - Improper heading structure
   - Missing form labels
   - Keyboard traps
   - Non-descriptive link text
   - Low contrast text

4. Accessibility testing with assistive technologies:
   - Screen reader testing
   - Keyboard-only navigation testing
   - Magnification tool testing
   - Voice recognition compatibility
   - Custom input device considerations

Please provide both automated testing approaches and manual testing procedures to ensure my application is accessible to all users.
```

### 3.6.6: Performance & Load Testing

```
I need to test the performance of my application under various conditions to ensure it remains responsive and reliable.

Please help me implement:

1. Performance testing for:
   - Page load times
   - Time to interactive
   - API response times
   - Resource loading efficiency
   - Animation smoothness
   - Runtime performance

2. Load testing considerations:
   - Concurrent user simulation
   - Database query performance under load
   - API endpoint stress testing
   - Resource utilization
   - Identifying bottlenecks

3. Performance testing tools:
   - Lighthouse and web vitals measurement
   - Network throttling techniques
   - CPU throttling for device testing
   - Memory usage monitoring
   - Server response time testing

4. Performance budgets:
   - Setting realistic performance targets
   - Measuring against performance budgets
   - Identifying performance regressions
   - Automated performance testing

Please provide specific testing approaches and tools that would be appropriate for my [Next.js/React/etc.] application with Supabase backend, including code examples where relevant.
```

### 3.6.7: Security Testing

```
I need to test the security of my application to identify and address potential vulnerabilities.

Please help me implement:

1. Security testing for common vulnerabilities:
   - Authentication and session management
   - Authorization and access control
   - Input validation and sanitization
   - SQL injection (for Supabase)
   - Cross-site scripting (XSS)
   - Cross-site request forgery (CSRF)
   - API security

2. Security testing approaches:
   - Security headers verification
   - Sensitive data exposure checks
   - Third-party dependency security
   - Environment variable protection
   - File upload security
   - Payment processing security

3. Security testing tools:
   - Static application security testing
   - Dynamic analysis tools
   - API security scanners
   - Dependency vulnerability scanners
   - Security headers analyzers

4. Security best practices verification:
   - HTTPS implementation
   - Password policies
   - Rate limiting
   - Error handling (not exposing sensitive details)
   - Content Security Policy

Please provide specific security tests and checks I should perform on my application, with emphasis on a Supabase backend and [Next.js/React/etc.] frontend.
```

### 3.6.8: Bug Fixing & Final QA

```
Now that we've conducted thorough testing, I need to systematically address any identified issues and perform final quality assurance.

Please help me create:

1. Bug tracking and prioritization:
   - Categorizing bugs by severity
   - Prioritizing fixes based on impact
   - Creating reproducible test cases
   - Documenting bug details for efficient fixing

2. Bug fixing methodology:
   - Root cause analysis approaches
   - Validation of fixes
   - Regression testing after fixes
   - Documentation of fixes

3. Final QA checklist covering:
   - Core functionality verification
   - Cross-browser compatibility
   - Mobile responsiveness
   - Accessibility compliance
   - Performance benchmarks
   - Security requirements

4. Pre-launch verification:
   - Deployment testing
   - Database migration verification
   - Environment configuration checks
   - Production simulations
   - Rollback procedures

Please provide a structured approach to efficiently address any issues found during testing and conduct a thorough final QA before launching the application.
``` 