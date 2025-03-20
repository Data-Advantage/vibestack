# UI Components

This document outlines the UI component architecture, implementation patterns, and best practices for your Next.js and Supabase application.

## Component Organization

Organize components into these clear categories for better maintainability:

| Category | Purpose | Examples |
|----------|---------|----------|
| **UI Components** | Reusable presentation components | Buttons, Cards, Inputs, Modals |
| **Domain Components** | Feature-specific components | UserProfile, InvoiceForm, ProductCard |
| **Layout Components** | Page structure components | Header, Footer, Sidebar, PageContainer |
| **Provider Components** | Context providers | AuthProvider, ThemeProvider, SettingsProvider |
| **Composite Components** | Composed of multiple components | SignupForm, DashboardStats, UserTable |

### Directory Structure
Follow this structure to organize components by responsibility:
```
components/
├── ui/                # shadcn/ui components
├── auth/              # Authentication components
├── [domain]/          # Domain-specific components
├── layout/            # Layout and structure components
└── providers/         # Context providers
```

## Server vs. Client Components

### Server Components
Use Server Components for:
- Data fetching directly from the database
- SEO-critical content rendering
- Static or rarely changing content
- Components that don't need interactivity

### Client Components
Use Client Components (with `"use client"` directive) for:
- Interactive UI elements
- Form handling
- State-dependent rendering
- Event handling
- Components using browser APIs

### Decision Framework
1. Start with Server Components by default
2. Switch to Client Components only when needed for interactivity
3. Keep Client Components small and focused
4. Pass server data as props to Client Components

## shadcn/ui Implementation

### Core Components
- Use shadcn/ui components as the foundation: https://ui.shadcn.com/docs/components
- Style with the "new-york" theme variant for consistent design
- Customize components through Tailwind classes and CSS variables

### Specialized Components
- Sidebars: Use https://ui.shadcn.com/blocks/sidebar
- Authentication: Implement with https://ui.shadcn.com/blocks/login
- Charts: Build with https://ui.shadcn.com/charts
- Themes: Configure with https://ui.shadcn.com/colors
- Toasts: Use sonner (https://ui.shadcn.com/docs/components/sonner) rather than toast

## Accessibility Standards

Implement these accessibility features in all components:

### Semantic HTML
- Use appropriate HTML elements (`<nav>`, `<main>`, `<section>`, `<button>`, etc.)
- Avoid generic `<div>` tags for interactive elements

### ARIA Attributes
- Implement ARIA roles, states, and properties for dynamic content
- Use `aria-label`, `aria-expanded`, `aria-controls`, etc. appropriately

### Keyboard Navigation
- Ensure all interactive elements are keyboard accessible
- Implement visible focus states using Tailwind's focus modifiers
- Maintain logical tab order through proper HTML structure

### Focus Management
- Trap focus within modals, drawers, and other overlays
- Return focus to triggering elements when overlays close
- Handle focus for dynamically rendered content

### Color Contrast
- Maintain WCAG AA standard (minimum 4.5:1 for normal text, 3:1 for large text)
- Test contrast ratios using browser devtools

### Screen Reader Support
- Provide text alternatives for non-text content
- Use `aria-live` regions for dynamic content updates
- Hide decorative elements from screen readers

### Form Accessibility
- Use proper `<label>` elements connected to inputs
- Provide clear error messages and validation feedback
- Group related form controls with `<fieldset>` and `<legend>`

## Responsive Design Patterns

### Mobile-First Approach
- Design for mobile devices first, then enhance for larger screens
- Use Tailwind's responsive modifiers (`sm:`, `md:`, `lg:`, etc.)

### Layout Patterns
- Stack elements vertically on mobile, horizontally on larger screens
- Hide secondary navigation in menus on mobile
- Implement touch-friendly targets (minimum 44x44px)

### Responsive Typography
- Use fluid typography scaling with Tailwind's size classes
- Implement proper heading hierarchy across screen sizes

### Adaptive Components
- Convert complex tables to cards on mobile
- Switch multi-column layouts to single column on small screens
- Adjust or hide non-essential UI elements on mobile

## State Management

### Component State
- Use React's `useState` and `useReducer` for local component state
- Implement controlled forms with React Hook Form
- Use refs for imperative DOM interactions

### Global State
- Implement context providers for application-wide state:
  - Authentication state
  - Theme preferences
  - User settings
  - Feature flags

### Data Fetching State
- Handle loading, error, and success states for all data operations
- Implement skeleton loaders during data fetching
- Provide clear error feedback to users

## Theme Implementation

- Implement themes using CSS variables in `globals.css`
- Use HSL color format for better color manipulation
- Support both light and dark modes through Tailwind's dark mode
- Create a theme toggle component with persistent user preference

## Implementation Best Practices

1. Create base components with shadcn/ui first
2. Build domain-specific components on top of UI primitives
3. Implement responsive designs with Tailwind's responsive utilities
4. Test components across devices and screen sizes
5. Validate accessibility with automated tools and manual testing
6. Document component APIs and usage patterns

Remember that well-structured components make your application more maintainable, accessible, and consistent. Focus on creating a component system that balances reusability with domain-specific needs.