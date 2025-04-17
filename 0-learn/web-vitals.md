# Web Vitals

Web Vitals are a set of quality signals that measure the user experience of a web page, focusing on loading performance, interactivity, and visual stability.

## Key Metrics

- **Largest Contentful Paint (LCP)**: Measures loading performance - the time when the largest content element becomes visible
  - Good: ≤ 2.5 seconds
  - Needs Improvement: 2.5 - 4.0 seconds
  - Poor: > 4.0 seconds

- **First Input Delay (FID)**: Measures interactivity - the time from when a user first interacts with a page to when the browser responds
  - Good: ≤ 100 milliseconds
  - Needs Improvement: 100 - 300 milliseconds
  - Poor: > 300 milliseconds

- **Interaction to Next Paint (INP)**: A newer metric measuring overall responsiveness to user interactions
  - Good: ≤ 200 milliseconds
  - Needs Improvement: 200 - 500 milliseconds
  - Poor: > 500 milliseconds

- **Cumulative Layout Shift (CLS)**: Measures visual stability - the amount of unexpected layout shift during page loading
  - Good: ≤ 0.1
  - Needs Improvement: 0.1 - 0.25
  - Poor: > 0.25

## Additional Important Metrics

- **Time to First Byte (TTFB)**: How quickly the server responds
- **First Contentful Paint (FCP)**: When the first content appears
- **Total Blocking Time (TBT)**: Sum of time when the main thread is blocked

## Resources

- [Web Vitals Documentation](https://web.dev/vitals/)
- [PageSpeed Insights](https://pagespeed.web.dev/)
- [Lighthouse](https://developers.google.com/web/tools/lighthouse)

## How They're Used in VibeStack

In Day 3 of the VibeStack workflow, you'll measure and optimize your application's Web Vitals as part of the performance optimization process. This ensures your SaaS application provides a fast, responsive, and stable user experience, which is crucial for user satisfaction and retention. You'll implement strategies to improve each core metric through code splitting, image optimization, and other techniques.
