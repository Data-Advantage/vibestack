# STORYD.AI - Site Organization & Navigation

## Table of Contents

1. [Overall Architecture](#1-overall-architecture)
2. [NextJS Directory Structure](#2-nextjs-directory-structure)
3. [Route Organization](#3-route-organization)
4. [Navigation Contexts](#4-navigation-contexts)
5. [URL Structure & Parameters](#5-url-structure--parameters)
6. [State Management Strategy](#6-state-management-strategy)
7. [Implementation Guidelines](#7-implementation-guidelines)

---

## 1. Overall Architecture

### 1.1 Application Contexts

STORYD.AI consists of four distinct application contexts, each serving different user types and functional areas:

1. **Marketing Context**: Public-facing marketing site accessible to all users and search engines
2. **Application Context**: Main dashboard and tools for authenticated users
3. **Presentation Context**: In-depth presentation creation workflow with phase-based navigation
4. **Admin Context**: Administrative tools for platform management

### 1.2 Architectural Philosophy

- **API-First Approach**: All UI functionality should be backed by robust API endpoints
- **Progressive Enhancement**: Core functionality works without JavaScript, enhanced with client-side features
- **Separation of Concerns**: Clear boundaries between marketing, application, and admin contexts
- **Performance Focus**: Optimize initial load and navigation transitions
- **SEO Optimization**: Marketing pages fully optimized for search engines

### 1.3 Technology Foundation

- **Framework**: Next.js with App Router
- **UI Components**: shadcn/ui with Tailwind CSS
- **Authentication**: Supabase Auth
- **State Management**: Server components with minimal client state
- **Navigation**: Combination of server and client navigation for optimal performance

---

## 2. NextJS Directory Structure

### 2.1 Root Directory Structure

```
/app                     # Next.js App Router routes
  /api                   # API routes
  /(marketing)           # Marketing routes (public)
  /(app)                 # Application routes (authenticated)
  /(presentation)        # Presentation creation routes
  /(admin)               # Admin routes
/components              # Shared React components
  /ui                    # shadcn/ui components
  /marketing             # Marketing-specific components
  /app                   # Application-specific components
  /presentation          # Presentation-specific components
  /admin                 # Admin-specific components
/lib                     # Shared utilities and functions
/hooks                   # Custom React hooks
/context                 # React context providers
/styles                  # Global styles and Tailwind config
/types                   # TypeScript type definitions
/middleware.ts           # Next.js middleware for auth and routing
/public                  # Static assets
/supabase                # Supabase configuration and types
```

### 2.2 Detailed Component Structure

#### 2.2.1 UI Components

```
/components/ui
  /navigation              # Navigation components
    /header                # Global header component
    /marketing-navigation  # Marketing-specific navigation
    /app-navigation        # App-specific navigation
    /app-sidebar           # App context sidebar
    /admin-sidebar         # Admin context sidebar
    /presentation-sidebar  # Presentation context sidebar
    /tabs                  # Tab navigation components
    /breadcrumbs           # Breadcrumb components
  /layout                  # Layout components
    /container             # Container components
    /grid                  # Grid layout components
    /split                 # Split view components
    /responsive            # Responsive layout utilities
  /data-display            # Data display components
    /card                  # Card components
    /table                 # Table components
    /list                  # List components
    /stats                 # Statistical display components
  /inputs                  # Input components
    /form                  # Form components
    /button                # Button components
    /select                # Select components
    /toggle                # Toggle components
  /feedback                # Feedback components
    /alert                 # Alert components
    /toast                 # Toast notification components
    /progress              # Progress indicators
    /skeleton              # Skeleton loaders
  /overlays                # Overlay components
    /dialog                # Dialog components
    /drawer                # Drawer components
    /popover               # Popover components
    /tooltip               # Tooltip components
```

#### 2.2.2 Feature-Specific Components

```
/components/marketing
  /hero                    # Marketing hero sections
  /features                # Feature showcase components
  /pricing                 # Pricing components
  /testimonials            # Testimonial components
  /faq                     # FAQ components
  /cta                     # Call-to-action components

/components/app
  /dashboard               # Dashboard components
  /projects                # Project management components
  /presentations           # Presentation list components
  /narratives              # Narrative template components
  /settings                # Settings components
  /billing                 # Billing and credits components

/components/presentation
  /phase-nav               # Phase navigation components
  /plan                    # Plan phase components
  /think                   # Think phase components
  /write                   # Write phase components
  /automate                # Automate phase components
  /preview                 # Presentation preview components
  /editor                  # Content editing components

/components/admin
  /users                   # User management components
  /analytics               # Analytics components
  /system                  # System monitoring components
  /settings                # Admin settings components
```

### 2.3 API Route Structure

```
/app/api
  /auth                    # Authentication endpoints
  /presentations           # Presentation management endpoints
  /projects                # Project management endpoints
  /narratives              # Narrative template endpoints
  /billing                 # Billing and credit endpoints
  /admin                   # Admin-only endpoints
  /webhooks                # Webhook receivers
```

---

## 3. Route Organization

### 3.1 Marketing Routes

```
/app/(marketing)
  /page.tsx                # Homepage
  /features
    /page.tsx              # Features overview
    /[feature]/page.tsx    # Individual feature pages
  /solutions
    /page.tsx              # Solutions overview
    /[solution]/page.tsx   # Industry-specific solution pages
  /pricing
    /page.tsx              # Pricing page
  /about
    /page.tsx              # About page
  /contact
    /page.tsx              # Contact page
  /blog
    /page.tsx              # Blog index
    /[slug]/page.tsx       # Blog post pages
  /developers
    /page.tsx              # Developer overview
    /docs/page.tsx         # Documentation overview
    /docs/[category]/page.tsx # Documentation category pages
    /docs/[category]/[doc]/page.tsx # Individual documentation pages
  /privacy/page.tsx        # Privacy policy
  /terms/page.tsx          # Terms of service
```

### 3.2 Application Routes

```
/app/(app)
  /dashboard
    /page.tsx              # Main dashboard
  /presentations
    /page.tsx              # Presentations list
    /new/page.tsx          # Create new presentation
  /projects
    /page.tsx              # Projects list
    /new/page.tsx          # Create new project
    /[project_id]/page.tsx # Project details
    /[project_id]/settings/page.tsx # Project settings
    /[project_id]/branding/page.tsx # Project branding
    /[project_id]/knowledge/page.tsx # Project knowledge base
  /narratives
    /page.tsx              # Narratives list
    /category/[category]/page.tsx # Category-specific narratives
    /new/page.tsx          # Create new narrative
    /private/page.tsx      # Private narratives
    /[narrative_slug]/page.tsx # Narrative detail
    /[narrative_slug]/edit/page.tsx # Edit narrative
  /design
    /page.tsx              # Design overview
    /themes/page.tsx       # Theme management
    /colors/page.tsx       # Color management
    /fonts/page.tsx        # Font management
    /backgrounds/page.tsx  # Background management
    /icons/page.tsx        # Icon sets
    /languages/page.tsx    # Language support
  /credentials
    /page.tsx              # Credentials overview
    /api/page.tsx          # API key management
    /webhooks/page.tsx     # Webhook management
    /mcp/page.tsx          # MCP token management
  /integrations
    /page.tsx              # Integrations overview
    /[integration]/page.tsx # Specific integration settings
  /account
    /page.tsx              # Account overview
    /user/page.tsx         # User profile
    /billing/page.tsx      # Billing and credits
    /usage/page.tsx        # Usage reports
  /settings
    /page.tsx              # Application settings
```

### 3.3 Presentation Routes

```
/app/(presentation)
  /presentations/[id]
    /page.tsx              # Presentation overview
    /settings/page.tsx     # Presentation settings
    /history/page.tsx      # Version history
    /share/page.tsx        # Sharing options
    /plan
      /page.tsx            # Plan phase overview
      /topic/page.tsx      # Topic definition
      /documents/page.tsx  # Document management
      /images/page.tsx     # Image management
      /links/page.tsx      # Link management
      /outline/page.tsx    # Presentation outline
      /settings/page.tsx   # Plan phase settings
    /think
      /page.tsx            # Think phase overview
      /analysis/page.tsx   # Analysis tools
      /lookups/page.tsx    # Information lookups
      /research/page.tsx   # Research tools
      /datasets/page.tsx   # Dataset analysis
      /story/page.tsx      # Narrative structure
    /write
      /page.tsx            # Write phase overview
      /slides/page.tsx     # Slide management
      /content/page.tsx    # Content editing
      /design/page.tsx     # Design customization
      /preview/page.tsx    # Content preview
    /automate
      /page.tsx            # Automate phase overview
      /export/page.tsx     # Export options
      /parameters/page.tsx # Generation parameters
      /webhook/page.tsx    # Webhook configuration
      /api/page.tsx        # API implementation examples
      /mcp/page.tsx        # MCP configuration
```

### 3.4 Admin Routes

```
/app/(admin)
  /admin
    /page.tsx              # Admin dashboard
    /users
      /page.tsx            # User management
      /[user_id]/page.tsx  # Individual user details
    /account-status/page.tsx # Account status management
    /token-usage/page.tsx  # Token usage monitoring
    /errors/page.tsx       # System error monitoring
    /analytics/page.tsx    # Usage analytics
    /settings/page.tsx     # Admin settings
```

---

## 4. Navigation Contexts

### 4.1 Global App Header

The global header appears on all pages across all contexts and contains:

- **Logo**: Company logo with link to appropriate home (marketing or app dashboard)
- **Authentication Controls**: 
  - For unauthenticated users: Login and Signup buttons
  - For authenticated users: User menu with profile picture and logout option
- **Theme Toggle**: Switch between light and dark mode
- **Search**: Global search functionality in authenticated contexts
- **Notifications**: User-specific notification center in authenticated contexts
- **Context Indicator**: Visual indication of current application context
- **Any additional global actions as needed**

### 4.1.1 Alert Header

An alert header appears above the global header when needed:

- **System Announcements**: Platform-wide notices that affect all users
- **Maintenance Notices**: Scheduled downtime or performance warnings
- **Critical Updates**: Important information that needs immediate attention
- **Feature Announcements**: New functionality notifications

This area is typically hidden when not in use but takes precedence when displayed.

### 4.2 Marketing Navigation

#### 4.2.1 Primary Navigation

The marketing-navigation appears below the global header on marketing pages:

- **Home**: Landing page with value proposition
- **Features**: Platform capabilities overview
  - API capabilities
  - Business storytelling
  - Customization
  - Output quality
- **Solutions**: Industry-specific implementations
  - Sales
  - Reporting
  - Training
  - Fundraising
- **Pricing**: Credit packages and options
- **About**: Company information
- **Contact**: Support and sales

#### 4.2.2 Secondary Navigation

- **Developers**: Technical resources
  - API Documentation
  - Implementation guides
  - Playground
  - SDKs

#### 4.2.3 Footer Navigation

- Terms of Service
- Privacy Policy
- Social Media Links (X, LinkedIn, YouTube, GitHub)

### 4.3 Application Navigation

#### 4.3.1 Main Sidebar

The app-sidebar contains:

- **Dashboard**: User homepage
- **Presentations**: List of presentations
- **Projects**: Project management
- **Narratives**: Template management
- **Design**: Visual styling management
- **Credentials**: Authentication management
  - API Keys
  - Webhooks
  - MCP Tokens
- **Integrations**: External service connections
- **Documentation**: Implementation guides
- **Account**: User profile and billing
  - User Profile
  - Billing
  - Usage
- **Settings**: Application preferences

#### 4.3.2 Bottom Sidebar

Bottom area of app-sidebar contains:
- Account button with dropdown menu
- Credit balance indicator
- Sign out option

### 4.4 Presentation Navigation

#### 4.4.1 Phase-Based Navigation

The presentation-sidebar contains phase-based navigation:

- **Plan**: Initial setup phase
  - Topic definition
  - Document management
  - Image management
  - Link management
  - Presentation outline
  - Settings
- **Think**: Research and analysis phase
  - Analysis tools
  - Information lookups
  - Research tools
  - Dataset analysis
  - Narrative structure
- **Write**: Content creation phase
  - Slide management
  - Content editing
  - Design customization
  - Preview
- **Automate**: Output generation phase
  - Export options
  - Generation parameters
  - Webhook configuration
  - API examples
  - MCP configuration

Bottom area of presentation-sidebar contains:
- Account button with dropdown menu
- Credit balance indicator
- Sign out option

#### 4.4.2 Presentation Context Actions

- Return to presentations list
- Presentation settings
- Version history
- Sharing options

### 4.5 Admin Navigation

#### 4.5.1 Admin Sidebar

The admin-sidebar contains:

- **Dashboard**: Platform overview
- **User Management**: Account control
- **Account Status**: Status management
- **Token Usage**: AI usage monitoring
- **System Errors**: Error tracking
- **Analytics**: Usage metrics
- **Settings**: Platform configuration

#### 4.5.2 Admin Context

- Return to normal app
- Admin user identification

---

## 5. URL Structure & Parameters

### 5.1 Path Parameter Conventions

| Context | Path Pattern | Example | Parameters |
|---------|--------------|---------|------------|
| Marketing | `/<page>` | `/features` | `page`: Page identifier |
| Marketing Sub-pages | `/<page>/<subpage>` | `/features/api` | `subpage`: Section identifier |
| App Dashboard | `/dashboard` | `/dashboard` | None |
| Presentations List | `/presentations` | `/presentations` | None |
| Presentation Detail | `/presentations/:id` | `/presentations/pres_123abc` | `id`: Presentation ID |
| Presentation Phase | `/presentations/:id/:phase` | `/presentations/pres_123abc/write` | `phase`: Process phase |
| Presentation Sub-phase | `/presentations/:id/:phase/:subphase` | `/presentations/pres_123abc/plan/documents` | `subphase`: Phase component |
| Projects | `/projects` | `/projects` | None |
| Project Detail | `/projects/:project_id` | `/projects/proj_456def` | `project_id`: Project ID |
| Project Section | `/projects/:project_id/:section` | `/projects/proj_456def/branding` | `section`: Project area |
| Admin Dashboard | `/admin` | `/admin` | None |
| Admin Section | `/admin/:section` | `/admin/users` | `section`: Admin area |
| Admin Detail | `/admin/:section/:id` | `/admin/users/user_789ghi` | `id`: Resource ID |

### 5.2 ID Prefix Standards

- `pres_` for presentation IDs
- `proj_` for project IDs
- `user_` for user IDs
- `tmpl_` for template IDs
- `brand_` for brand profile IDs

### 5.3 Query Parameters

#### 5.3.1 Global Parameters

- `theme` - Override theme preference (light, dark, system)
- `lang` - Specify content language
- `ref` - Referral source tracking
- `debug` - Enable debug info (admins only)

#### 5.3.2 Context-Specific Parameters

**Marketing**:
- `campaign` - Marketing campaign tracking
- `source` - Traffic source tracking
- `medium` - Traffic medium tracking

**App**:
- `tab` - Pre-select specific tab
- `panel` - Open specific panel
- `notification` - Highlight notification
- `search` - Initial search query
- `breadcrumb` - Deep linking with breadcrumb state

**Presentation**:
- `template` - Specify template for new presentations
- `brand` - Apply specific brand profile
- `version` - View specific presentation version
- `project` - Associate with project
- `slide` - Jump to specific slide
- `compare` - Compare with version
- `phase` - Select specific presentation phase

**Project**:
- `filter` - Filter items
- `sort` - Sort items
- `view` - Change view mode
- `search` - Filter by search term
- `timeframe` - Filter by time period

**Admin**:
- `status` - Filter by status
- `role` - Filter users by role
- `before` - Items before timestamp
- `after` - Items after timestamp
- `limit` - Limit item count
- `export` - Export format
- `environment` - Switch between environments (dev/staging/prod)

---

## 6. State Management Strategy

### 6.1 URL-Based State

States persisted in the URL:
- Current view/page location
- Selected resource (presentation, project, etc.)
- Major filters and sorting options
- Selected tabs or major UI sections
- Version information when applicable

### 6.2 Session-Based State

States stored in session storage:
- Form input values during multi-step processes
- Temporary view preferences
- Recently visited resources
- Expanded/collapsed state of UI components

### 6.3 Persistent State

States stored in local storage or user preferences:
- Theme preference
- Language preference
- View mode preferences (list vs. grid)
- Sidebar collapsed/expanded state
- Dashboard widget arrangement

### 6.4 Server State

States managed on the server:
- Authentication status
- User profile information
- Credit balance and usage
- Presentation and project data
- System configurations

---

## 7. Implementation Guidelines

### 7.1 Technical Requirements

1. **Server Components**
   - Use Next.js server components for initial page rendering
   - Leverage React Server Components for data-heavy pages
   - Implement streaming where appropriate for long operations

2. **Client Components**
   - Use client components for interactive elements
   - Implement optimistic UI updates for better UX
   - Leverage React hooks for state management

3. **Navigation System**
   - Implement global header as a client component for interactive elements (theme toggle, authentication)
   - Ensure header is consistent across all contexts
   - Use context-specific navigation components for marketing, app, presentation, and admin areas
   - Implement parallel routes for layout persistence
   - Use intercepting routes for modals and overlays
   - Create custom navigation hooks for consistent UX

4. **Middleware**
   - Implement auth middleware for protected routes
   - Use middleware for language detection and routing
   - Create request validation middleware for API routes

### 7.2 Mobile Considerations

1. **Responsive Design**
   - Desktop-first for complex app interfaces
   - Mobile-friendly marketing pages
   - Tailored mobile experience for presentation viewing
   - Touch-friendly controls for interactive elements

2. **Navigation Adaptations**
   - Collapsible app-sidebar for application context
   - Collapsible presentation-sidebar for presentation phases
   - Simplified admin-sidebar for admin context on mobile
   - Bottom tab bar for presentation phases on mobile
   - Hamburger menu for marketing-navigation
   - Adaptable header for all screen sizes

### 7.3 Performance Optimization

1. **Load Performance**
   - Route-based code splitting
   - Image optimization with Next.js Image
   - Font optimization with next/font
   - Critical CSS extraction
   - Efficient component loading order

2. **Interaction Performance**
   - Use React suspense boundaries
   - Implement skeleton loaders
   - Prefetch likely next routes
   - Implement virtualization for long lists
   - Optimize re-renders with memoization

### 7.4 Accessibility Guidelines

1. **Required Standards**
   - WCAG 2.1 AA compliance
   - Keyboard navigation support
   - Screen reader compatibility
   - Sufficient color contrast
   - Focus management during navigation
   - Accessible form controls

2. **Implementation Approach**
   - Use semantic HTML
   - Implement ARIA attributes appropriately
   - Test with screen readers
   - Create accessible color system
   - Ensure keyboard focus indicators

### 7.5 SEO Optimization

1. **Marketing Pages**
   - Implement metadata with next/head
   - Create optimized page titles and descriptions
   - Implement structured data with JSON-LD
   - Create XML sitemap
   - Implement canonical URLs

2. **Dynamic Routes**
   - Generate static paths for key marketing pages
   - Implement dynamic sitemap generation
   - Create dedicated robots.txt
   - Support social media preview cards
   - Implement breadcrumbs for structured data

### 7.6 Development Workflow

1. **Component Organization**
   - Create component documentation with Storybook
   - Implement component-level tests
   - Use atomic design principles
   - Maintain consistent component API
   - Create reusable composition patterns

2. **Route Organization**
   - Group routes by context
   - Maintain consistent loading states
   - Implement error boundaries
   - Create layout components for route groups
   - Document route parameters and requirements

### 7.7 Navigation System Diagram

The following diagram illustrates the overall navigation architecture of STORYD.AI, showing how the global header and context-specific navigation components work together. Each application context has a unique navigation pattern optimized for its specific use case, as detailed in the subsections below.

#### 7.7.1 Marketing Context Navigation

```
+------------------------------------------------------------------------+
|                                                                        |
|                          ALERT HEADER                                  |
| [System announcements/maintenance notices]                             |
|                                                                        |
+------------------------------------------------------------------------+
|                                                                        |
|                         GLOBAL HEADER                                  |
| [Logo]                [Login] [Signup]                     [Theme]     |
|                                                                        |
+------------------------------------------------------------------------+
|                                                                        |
|                     MARKETING-NAVIGATION                               |
| [Home] [Features] [Solutions] [Pricing] [About] [Contact] [Developers] |
|                                                                        |
+------------------------------------------------------------------------+
|                                                                        |
|                       MAIN CONTENT AREA                                |
|                                                                        |
|  - Hero sections                                                       |
|  - Feature highlights                                                  |
|  - Testimonials                                                        |
|  - Pricing tables                                                      |
|  - Call-to-action sections                                             |
|  - SEO-optimized content                                               |
|                                                                        |
+------------------------------------------------------------------------+
|                                                                        |
|                            FOOTER                                      |
|  [Terms] [Privacy] [Social Links] [Contact] [Blog] [Status]            |
|  [Copyright]                                                           |
|                                                                        |
+------------------------------------------------------------------------+
```

**Key Characteristics:**
- No sidebar navigation
- Horizontal marketing-navigation below header
- Focus on conversion and information
- SEO-optimized structure
- Public-facing content only
- No authentication required
- Responsive design prioritized
- Alert header for system-wide announcements

#### 7.7.2 App Context Navigation

```
+----------------------------------------------------------------------+
|                                                                      |
|                          ALERT HEADER                                |
| [System announcements/maintenance notices]                           |
|                                                                      |
+----------------------------------------------------------------------+
|                                                                      |
|                         GLOBAL HEADER                                |
| [Logo]      [Context: App]     [Search] [Notif] [Profile] [Theme]    |
|                                                                      |
+----------------------------------------------------------------------+
|                |                                                     |
|                |  [Breadcrumbs....................................]  |
|                |                                                     |
|                |                                                     |
|  APP-          |                                                     |
|  SIDEBAR       |             MAIN CONTENT AREA                       |
|                |                                                     |
| Dashboard      |             - Dashboard widgets                     |
| Projects       |             - Project listings                      |
| Presentations  |             - Content management                    |
| Narratives     |             - Configuration forms                   |
| Design         |             - Analytics displays                    |
| Credentials    |             - Resource browsers                     |
| Integrations   |             - Search results                        |
| Documentation  |             - Status indicators                     |
| Account        |                                                     |
| Settings       |                                                     |
|                |                                                     |
|                |                                                     |
| [Account]      |                                                     |
| [Credits: 123] |                                                     |
| [Sign out]     |                                                     |
+----------------+-----------------------------------------------------+
|                                                                      |
|                            FOOTER                                    |
|  [Support] [API Docs] [Status] [Privacy] [Terms]                     |
|  [Copyright]                        [Version: x.x.x]                 |
|                                                                      |
+----------------------------------------------------------------------+
```

**Key Characteristics:**
- Vertical app-sidebar on left side
- Dashboard-centric layout
- Tools and resource management
- Project and presentation listings
- Personalized content
- Authentication required
- User settings and preferences
- Bottom sidebar with account info and credits
- Global search functionality
- Notification center
- Context indicator in header
- Breadcrumb navigation
- Alert header for system-wide announcements

#### 7.7.3 Presentation Context Navigation

```
+----------------------------------------------------------------------+
|                                                                      |
|                          ALERT HEADER                                |
| [System announcements/maintenance notices]                           |
|                                                                      |
+----------------------------------------------------------------------+
|                                                                      |
|                         GLOBAL HEADER                                |
| [Logo]  [Context: Presentation]   [Search] [Notif] [Profile] [Theme] |
|                                                                      |
+----------------------------------------------------------------------+
|                |                                                     |
|                |  [Breadcrumbs: Projects > Project Name > Phase]     |
|  PHASE         |                                                     |
|  NAV           |                                                     |
|  ---------     |                                                     |
|  Plan          |                                                     |
|  Think         |             MAIN CONTENT AREA                       |
|  Write         |                                                     |
|  Automate      |             - Phase-specific tools                  |
|                |             - Interactive editors                   |
|                |             - Content previews                      |
|  PHASE         |             - Configuration panels                  |
|  DETAILS       |             - Progress indicators                   |
|  ---------     |             - Resource browsers                     |
|  Topic         |             - Real-time collaboration               |
|  Documents     |                                                     |
|  Images        |                                                     |
|  Links         |                                                     |
|  Outline       |                                                     |
|  Settings      |                                                     |
|                |                                                     |
| [Back to       |                                                     |
|  Projects]     |                                                     |
| [Account]      |                                                     |
| [Credits: 123] |                                                     |
| [Sign out]     |                                                     |
+----------------+-----------------------------------------------------+
|                                                                      |
|                            FOOTER                                    |
|  [Support] [API Docs] [Status] [Privacy] [Terms]                     |
|  [Copyright]                        [Version: x.x.x]                 |
|                                                                      |
+----------------------------------------------------------------------+
```

**Key Characteristics:**
- Process-oriented presentation-sidebar
- Phase-based navigation structure
- Tool-centric interface
- In-depth content creation focus
- Active project context always visible
- Authentication required
- Progress indicators for phases
- Bottom sidebar with account info and credits
- Back navigation to projects list
- Context indicator in header
- Breadcrumb navigation showing project and phase
- Version information in footer
- Alert header for system-wide announcements

#### 7.7.4 Admin Context Navigation

```
+----------------------------------------------------------------------+
|                                                                      |
|                          ALERT HEADER                                |
| [System announcements/maintenance notices]                           |
|                                                                      |
+----------------------------------------------------------------------+
|                                                                      |
|                         GLOBAL HEADER                                |
| [Logo]   [Context: ADMIN]    [Search] [Alerts] [Profile] [Theme]     |
|                                                                      |
+----------------------------------------------------------------------+
|                |                                                     |
|                |  [Breadcrumbs: Admin > Section > Subsection]        |
|  ADMIN-        |                                                     |
|  SIDEBAR       |                                                     |
|                |                                                     |
| Dashboard      |             MAIN CONTENT AREA                       |
| Users          |                                                     |
| Analytics      |             - Admin dashboards                      |
| Token Usage    |             - System monitoring                     |
| Account Status |             - User management tables                |
| System Errors  |             - Configuration panels                  |
| Settings       |             - Analytics displays                    |
|                |             - System logs                           |
|                |             - Error reports                         |
|                |             - Audit trails                          |
|                |                                                     |
| [Return        |                                                     |
|  to App]       |                                                     |
| [Admin         |                                                     |
|  Level: Full]  |                                                     |
| [Sign out]     |                                                     |
+----------------+-----------------------------------------------------+
|                                                                      |
|                            FOOTER                                    |
|  [Support] [System Status] [Admin Docs] [API Status]                 |
|  [Copyright]     [Version: x.x.x]     [Environment: Production]      |
|                                                                      |
+----------------------------------------------------------------------+
```

**Key Characteristics:**
- Admin-specific sidebar
- System monitoring focus
- User management tools
- Platform configuration
- Elevated permission requirements
- Limited access (admin users only)
- System-wide controls
- Return to normal app option
- Admin level indicator
- Alert center for notifications specific to admin functions
- Breadcrumb navigation
- Environment indicator in footer (prod/staging/dev)
- Version information in footer
- Alert header for system-wide announcements

#### Navigation System Flow

```
+---------------------------+
|                           |
|     GLOBAL HEADER         |
|      (Consistent)         |
+-----+-----------+---------+
      |           |
+-----v---+ +-----v-----+
|Marketing| |Authenticated|
|Context  | |Contexts    |
+-----+---+ +-----+-----+
      |           |
      |     +-----+-----+-----+
      |     |     |     |     |
+-----v---+ |     |     |     |
|Marketing| |     |     |     |
|Navigation|v     v     v     v
+---------+ +-----+-----+-----+
            |App  |Pres.|Admin|
            |Side-|Side-|Side-|
            |bar  |bar  |bar  |
            +-----+-----+-----+
```

### 7.8 Navigation Component Relationships

| Component            | Present In                | Contains                                     | Mobile Adaptation        |
|----------------------|---------------------------|----------------------------------------------|--------------------------|
| Global Header        | All contexts              | Logo, Auth Controls, Theme Toggle            | Fixed, simplified        |
| Marketing-Navigation | Marketing context only    | Main site sections, sub-navigation           | Hamburger menu           |
| App-Sidebar          | Application context only  | Main app sections, user controls             | Collapsible drawer       |
| Presentation-Sidebar | Presentation context only | Phase navigation, context actions            | Bottom tabs or drawer    |
| Admin-Sidebar        | Admin context only        | Admin sections, monitoring                   | Simplified, collapsible  |

### 7.9 State Sharing Between Navigation Components

- **Global Header**: Shares authentication state with all other navigation components
- **Theme Toggle**: Controls theme for all contexts via global state/localStorage
- **Context Detection**: Middleware detects context to activate appropriate navigation
- **Cross-Context Actions**: Some actions (like creating a new presentation) may navigate between contexts
- **Breadcrumbs**: Track user path across contexts when performing multi-step operations 