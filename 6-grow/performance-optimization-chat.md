# Post-Launch Performance Optimization

[⬅️ Growth Overview](README.md)

## Performance Optimization

**Goal**: Optimize your application for speed, responsiveness, and efficiency after launch to improve user retention and satisfaction.

**Process**: Follow this chat pattern with your AI coding tool such as [Claude](https://claude.ai) or [v0.app](https://v0.app). Pay attention to the notes in `[brackets]` and replace the bracketed text with your own content.

**Timeframe**: Implement over 1-2 weeks post-launch based on analytics data and user feedback

### 1: Performance Audit & Baseline

```
I need to optimize the performance of my application to ensure it loads quickly, responds efficiently to user interactions, and uses resources efficiently. Before making any changes, I want to conduct a performance audit and establish baselines.

Please help me:

1. Identify key performance metrics to track:
   - Initial load time
   - Time to interactive
   - First contentful paint
   - Largest contentful paint
   - Cumulative layout shift
   - Time to first byte
   - Runtime performance (frame rate, CPU usage)
   - Memory usage
   - Network request count and size

2. Implement measurement tools for:
   - Client-side performance monitoring
   - Server-side response time tracking
   - Database query performance
   - API request timing
   - Resource usage analysis

3. Establish a baseline of current performance:
   - How to capture performance metrics
   - Creating a performance benchmark
   - Identifying the most significant bottlenecks
   - Setting realistic improvement targets

Please provide code examples for implementing these performance measurement tools and explain how to interpret the results to prioritize optimization efforts.
```

### 2: Frontend Optimization Strategies

```
Based on our performance audit, I need to implement frontend optimizations to improve loading speed and runtime performance.

Please help me implement the following optimizations:

1. Asset optimization:
   - Image optimization (formats, compression, sizing)
   - JavaScript bundling and code splitting
   - CSS optimization
   - Font loading strategies
   - Lazy loading of non-critical resources

2. Rendering performance:
   - Component optimization
   - Virtual list implementation for long lists
   - Reducing re-renders
   - Memoization of expensive computations
   - Efficient state management

3. Network optimization:
   - Implementing proper caching strategies
   - Prefetching and preloading critical resources
   - Reducing unnecessary network requests
   - Implementing service workers (if applicable)
   - API request batching and aggregation

4. Build optimizations:
   - Tree shaking for unused code
   - Minification and compression
   - Modern JavaScript syntax and features
   - Dependency optimization

Please provide specific code examples for these optimizations that I can apply to my [Next.js/React/etc.] application. Include before/after comparisons where possible to illustrate the impact.
```

### 3: Backend & Database Optimization

```
I need to optimize the backend and database performance of my application to reduce latency and improve scalability.

Please help me implement:

1. Database query optimization:
   - Identifying and optimizing slow queries
   - Adding appropriate indexes
   - Implementing query caching
   - Connection pooling configuration
   - Batch operations for multiple records

2. API response optimization:
   - Implementing response compression
   - Optimizing serialization/deserialization
   - Pagination and filtering strategies
   - GraphQL optimization (if applicable)
   - Partial response patterns

3. Backend processing efficiency:
   - Implementing background processing for long-running tasks
   - Server-side caching strategies
   - Resource pooling
   - Memory usage optimization
   - Implementing timeouts for external services

4. Scaling considerations:
   - Stateless design patterns
   - Horizontal scaling preparation
   - Load balancing considerations
   - Database scaling strategies

Please provide specific code examples for these backend optimizations, focusing on my Supabase implementation and any server-side components of my application.
```

### 4: Mobile & Responsive Performance

```
I need to ensure my application performs well on mobile devices and across different screen sizes.

Please help me implement:

1. Mobile-specific optimizations:
   - Touch event handling optimization
   - Reducing layout thrashing on mobile
   - Viewport considerations
   - Reducing network usage for mobile users
   - Handling variable network conditions

2. Responsive image strategies:
   - Implementation of responsive images
   - Image loading prioritization
   - Lazy loading for offscreen images
   - Proper srcset and sizes attributes
   - Next-gen image formats with fallbacks

3. Mobile-first performance strategies:
   - Critical CSS implementation
   - Mobile-oriented content prioritization
   - Touch target size optimization
   - Reducing animations on mobile
   - Battery usage considerations

4. Testing across devices:
   - How to test performance on various devices
   - Emulation vs. real device testing
   - Mobile-specific performance metrics
   - Identifying mobile-specific bottlenecks

Please provide code examples for these mobile optimizations and explain how to validate their effectiveness across different devices and screen sizes.
```

### 5: Caching & Data Persistence

```
I need to implement effective caching strategies throughout my application to reduce redundant data fetching and improve responsiveness.

Please help me implement:

1. Client-side caching:
   - In-memory cache implementation
   - Local storage caching strategies
   - Service worker caching (if applicable)
   - Cache invalidation approaches
   - State persistence between sessions

2. API response caching:
   - Implementing HTTP caching headers
   - Cache-Control strategy
   - ETag implementation
   - Conditional requests
   - Edge caching considerations

3. Database query caching:
   - Implementing query result caching
   - Cache key strategies
   - Cache lifetime management
   - Selective cache invalidation
   - Cache warming strategies

4. Offline capabilities (if applicable):
   - Offline-first architecture
   - Data synchronization
   - Conflict resolution
   - Background sync implementation

Please provide code examples for these caching strategies and explain how to properly invalidate caches when data changes to prevent stale data issues.
```

### 6: Resource Loading Optimization

```
I need to optimize how resources are loaded in my application to improve perceived performance and reduce loading times.

Please help me implement:

1. Critical rendering path optimization:
   - Identifying and prioritizing critical CSS
   - Deferring non-critical JavaScript
   - Optimizing font loading
   - Reducing render-blocking resources
   - Managing third-party scripts

2. Progressive loading strategies:
   - Skeleton screens implementation
   - Progressive image loading
   - Content placeholders
   - Incremental data loading
   - Streaming responses (if applicable)

3. Preloading and prefetching:
   - Resource hints implementation (preload, prefetch, preconnect)
   - Route prefetching
   - Strategic preloading of assets
   - Dynamic prefetching based on user behavior
   - Balancing preloading with bandwidth considerations

4. Loading sequence optimization:
   - Prioritizing above-the-fold content
   - Deferring below-the-fold requests
   - Managing loading order
   - Implementing priority hints

Please provide code examples for these resource loading optimizations and explain how to measure their impact on user-perceived performance metrics.
```

### 7: JavaScript & Runtime Performance

```
I need to optimize the JavaScript execution and runtime performance of my application to ensure smooth interactivity and responsiveness.

Please help me implement:

1. JavaScript optimization:
   - Reducing bundle size
   - Code splitting strategies
   - Tree shaking implementation
   - Modern JavaScript features for performance
   - Avoiding memory leaks

2. Runtime performance:
   - Optimizing expensive calculations
   - Debouncing and throttling event handlers
   - Using requestAnimationFrame for animations
   - Avoiding layout thrashing
   - Optimizing DOM manipulations

3. Framework-specific optimizations for [React/Next.js/etc.]:
   - Virtual DOM optimization techniques
   - Component memoization
   - Efficient state management
   - Preventing unnecessary re-renders
   - Custom hooks for performance

4. Web workers implementation (if applicable):
   - Offloading CPU-intensive tasks
   - Implementing a worker communication pattern
   - Managing worker lifecycle
   - Sharing data between workers and main thread

Please provide code examples for these JavaScript optimizations, focusing on framework-specific best practices for my application.
```

### 8: Performance Monitoring & Continuous Improvement

```
Finally, I need to implement ongoing performance monitoring and establish a process for continuous performance improvement.

Please help me create:

1. Performance monitoring implementation:
   - Real User Monitoring (RUM) setup
   - Core Web Vitals tracking
   - Custom performance metric collection
   - Error and exception tracking
   - Performance regression detection

2. Automated performance testing:
   - Lighthouse CI implementation
   - Performance budgets
   - Automated testing in CI/CD pipeline
   - Synthetic monitoring setup
   - Load testing strategies

3. Performance analysis tools:
   - Chrome DevTools performance profiling
   - Bundle analysis tools
   - Database query analysis
   - Network request analysis
   - Memory profiling

4. Continuous improvement process:
   - Regular performance reviews
   - Prioritization framework for optimizations
   - Performance documentation
   - Team performance awareness
   - User-reported performance issues handling

Please provide code examples and configuration for implementing these monitoring systems, along with guidance on interpreting the results to continuously improve application performance.
``` 