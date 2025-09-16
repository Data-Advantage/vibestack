# Day 3: Build

[⬅️ Day 3 Overview](README.md)

## 3.4 Advanced Features

**Goal**: Implement the remaining features from your PRD that make your application unique.

**Process**: Follow this chat pattern with your AI coding tool such as [v0.app](https://v0.app). Pay attention to the notes in `[brackets]` and replace the bracketed text with your own content.

**Timeframe**: 45-60 minutes

### 3.4.1: Feature Prioritization & Planning

```
Now that I have the authentication system, API integrations, and payment processing in place, I need to implement the remaining core features that make my application unique. I need to prioritize these features based on my product requirements and user feedback.

Please paste your product requirements document and feedback analysis below:

<product-requirements-document>
[Paste your PRD from step 1.1 here]
</product-requirements-document>

<feedback-analysis>
[Paste your feedback analysis from step 2.1 here]
</feedback-analysis>

Based on these documents, please help me:

1. Identify the remaining core features that need to be implemented
2. Prioritize these features based on:
   - Impact on delivering my unique value proposition
   - User feedback and requests
   - Technical dependencies and implementation complexity
   - Relationship to paid vs. free functionality

3. Create an implementation plan that:
   - Groups related features for efficient development
   - Outlines the components and functionality needed for each feature
   - Considers dependencies between features
   - Includes a suggested order of implementation

Please focus on helping me implement the features that will deliver the most value to users while making my application stand out in the market.
```

### 3.4.2: Core Feature Implementation - [Feature Name 1]

```
Let's start implementing the first core feature identified in our prioritization: [Feature Name 1]

According to my PRD and feedback analysis, this feature should:
[Describe the key aspects and requirements of this feature]

Please help me create:

1. The necessary components for this feature:
   - [List the key components needed]
   - [For example: Main feature interface]
   - [Data input/management components]
   - [Results or output display]
   - [User interaction elements]

2. The data model and backend requirements:
   - Convex queries and mutations needed
   - Data structures in Convex (if any)
   - Data validation requirements

3. User interaction and experience:
   - How users will access and use this feature
   - State management for the feature
   - Success/error handling
   - Integration with other application components

Please provide the complete code for implementing this feature, ensuring it integrates properly with my existing authentication, API, and payment systems. Include both frontend components and backend functionality.
```

### 3.4.3: Core Feature Implementation - [Feature Name 2]

```
Now let's implement the next core feature: [Feature Name 2]

According to my PRD and feedback analysis, this feature should:
[Describe the key aspects and requirements of this feature]

Please help me create:

1. The necessary components for this feature:
   - [List the key components needed]
   - [For example: Feature dashboard or interface]
   - [Control and configuration elements]
   - [Output visualization]
   - [Integration points with other features]

2. The data model and backend requirements:
   - API endpoints needed
   - Database queries and operations
   - Data processing logic
   - Performance considerations

3. User interaction and experience:
   - Workflow and user journey
   - Interactive elements and controls
   - Feedback mechanisms
   - Responsive behavior across devices

Please provide the complete code for implementing this feature, ensuring it fits seamlessly with the application's existing structure and design system. Include all necessary frontend and backend components.
```

### 3.4.4: Core Feature Implementation - [Feature Name 3]

```
Let's implement the next priority feature: [Feature Name 3]

According to my PRD and feedback analysis, this feature should:
[Describe the key aspects and requirements of this feature]

Please help me create:

1. The necessary components for this feature:
   - [List the key components needed]
   - [For example: User interaction elements]
   - [Data visualization components]
   - [Configuration options]
   - [Results display]

2. The data model and backend requirements:
   - Required database structures
   - API integration points
   - Data transformation and processing
   - Storage considerations

3. User interaction and experience:
   - Entry points to the feature
   - User flow through the feature
   - Success/error states
   - Performance optimization

Please provide the complete code for implementing this feature, accounting for different user roles and subscription levels if relevant. Include both frontend and backend implementation details.
```

### 3.4.5: Subscription-based Feature Gating

```
Now I need to implement subscription-based feature gating to ensure users have access only to the features included in their subscription tier.

Based on my product requirements and pricing model, I need to:

1. Create a feature access control system that:
   - Checks user subscription status before allowing access to premium features
   - Provides appropriate messaging for upgrade opportunities
   - Handles graceful degradation for free tier users
   - Manages feature limits based on subscription level

2. Implement UI components for:
   - Feature upgrade prompts
   - Usage limits and quota displays
   - Premium feature indicators
   - "Upgrade to access" messaging

3. Set up the backend logic for:
   - Feature entitlement checking
   - Usage tracking and limits
   - Quota management
   - Subscription level verification

Please provide the code for implementing this feature gating system that integrates with my existing authentication and subscription management.
```

### 3.4.6: Feature Integration & Testing

```
Now that we've implemented all the core features, I need to ensure they work together seamlessly and perform well as a cohesive application.

Please help me with:

1. Integration testing strategy:
   - Key user journeys across multiple features
   - Edge cases and potential conflicts
   - Performance testing under load
   - Cross-browser and device testing

2. Feature dependency management:
   - Ensuring features that depend on each other work properly
   - Handling conditional feature availability
   - Managing shared resources and state

3. Final optimizations:
   - Performance improvements
   - Code refactoring for maintainability
   - Consistency in UI/UX across features
   - Error handling standardization

Please provide guidance on testing these integrated features and any necessary code adjustments to ensure the application functions as a unified whole rather than a collection of separate features.
``` 