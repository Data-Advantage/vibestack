# Convex Diagnostics System Documentation

## Overview

The Convex Diagnostics System is a comprehensive health check and monitoring solution for the SarahsRecipes.ai application's Convex database integration. It provides real-time status monitoring, connection testing, and setup guidance for developers working with the Convex backend.

## Architecture

The diagnostics system consists of three main components:

1. **Server-Side Page** (`app/convex/page.tsx`) - Handles server-side environment checks
2. **Client-Side Diagnostics Component** (`components/convex-diagnostics.tsx`) - Performs comprehensive client-side testing
3. **Database Connection Test** (`convex/connectionTest.ts`) - Tests actual database connectivity

## Components Breakdown

### 1. Convex Diagnostics Page (`app/convex/page.tsx`)

The main page component that serves as the entry point for diagnostics. It performs server-side checks and passes data to the client component.

**Key Features:**
- Server-side package availability checking
- Environment variable validation
- Dynamic import testing for Convex server modules

**Code Structure:**

---
import { ConvexDiagnostics } from "@/components/convex-diagnostics"

export default function ConvexPage() {
  console.log("[v0] Convex diagnostics page loading")

  let serverPackageAvailable = false
  try {
    // Use dynamic import for server-side check
    eval('require("convex/server")')
    serverPackageAvailable = true
  } catch (error) {
    console.log("[v0] Server-side convex package check failed:", error)
    serverPackageAvailable = false
  }

  // Server-side environment variable checks
  const serverEnvVars = {
    convexDeployment: process.env.CONVEX_DEPLOYMENT || null,
    convexUrl: process.env.NEXT_PUBLIC_CONVEX_URL || null,
  }

  const serverData = {
    envVars: serverEnvVars,
    packageAvailable: serverPackageAvailable,
  }

  return (
    <div className="min-h-screen bg-background">
      <ConvexDiagnostics serverData={serverData} />
    </div>
  )
}
---

**Server-Side Checks:**
- `CONVEX_DEPLOYMENT` environment variable presence
- `NEXT_PUBLIC_CONVEX_URL` environment variable presence
- Convex server package availability via dynamic require

### 2. Convex Diagnostics Component (`components/convex-diagnostics.tsx`)

The main client-side component that performs comprehensive diagnostics and displays results in a user-friendly interface.

**Key Features:**
- Real-time diagnostic testing
- Visual status indicators with icons and badges
- Comprehensive setup instructions
- Re-run capability for diagnostics

**Diagnostic Checks Performed:**

1. **Environment Variables**
   - `CONVEX_DEPLOYMENT` (server-side)
   - `NEXT_PUBLIC_CONVEX_URL` (client-side)

2. **Package Availability**
   - Convex package on server
   - Convex package on client (ConvexReactClient import)

3. **Component Availability**
   - ConvexClientProvider component
   - Convex schema files

4. **Generated Files**
   - Convex generated API files (`_generated/api`)

5. **Connection Testing**
   - Client connection capability
   - Server database connection (via connectionTest query)

**Status Types:**
- `success` - Check passed (green indicator)
- `warning` - Partial success or non-critical issue (yellow indicator)
- `error` - Check failed (red indicator)

**Interface Structure:**

---
interface DiagnosticResult {
  name: string
  status: "success" | "error" | "warning"
  message: string
  details?: string
}

interface ConvexDiagnosticsProps {
  serverData: {
    envVars: {
      convexDeployment: string | null
      convexUrl: string | null
    }
    packageAvailable: boolean
  }
}
---

### 3. Connection Test Function (`convex/connectionTest.ts`)

A Convex query function that tests actual database connectivity by querying table counts.

**Functionality:**
- Queries all main tables (recipes, mealPlans, shoppingLists)
- Returns table counts and connection status
- Provides error handling and detailed error messages

**Code Structure:**

---
import { query } from "./_generated/server"

export const testConnection = query({
  args: {},
  handler: async (ctx) => {
    try {
      // Test database connection by getting table info
      const recipesCount = await ctx.db
        .query("recipes")
        .collect()
        .then((r) => r.length)
      const mealPlansCount = await ctx.db
        .query("mealPlans")
        .collect()
        .then((r) => r.length)
      const shoppingListsCount = await ctx.db
        .query("shoppingLists")
        .collect()
        .then((r) => r.length)

      return {
        success: true,
        timestamp: Date.now(),
        tables: {
          recipes: recipesCount,
          mealPlans: mealPlansCount,
          shoppingLists: shoppingListsCount,
        },
        message: "Convex database connection successful",
      }
    } catch (error) {
      return {
        success: false,
        timestamp: Date.now(),
        error: error instanceof Error ? error.message : "Unknown error",
        message: "Convex database connection failed",
      }
    }
  },
})
---

## Diagnostic Flow

### 1. Page Load
1. Server-side page component loads
2. Performs server-side environment and package checks
3. Passes server data to client component

### 2. Client-Side Diagnostics
1. Component mounts and triggers `runDiagnostics()`
2. Sequentially performs all diagnostic checks
3. Updates UI with real-time results
4. Displays overall status and individual check results

### 3. Connection Testing
1. Attempts to import Convex generated API files
2. If successful, could call `testConnection` query (currently shows warning if files missing)
3. Tests client connection capability
4. Provides detailed feedback on connection status

## UI Components and Styling

### Status Indicators
- **Success**: Green CheckCircle icon with "Connected" badge
- **Warning**: Yellow AlertTriangle icon with "Warning" badge  
- **Error**: Red XCircle icon with "Error" badge

### Layout Structure
- Header with title and description
- Overall status card with pass/fail ratio
- Alert for setup requirements (if needed)
- Individual diagnostic result cards
- Setup instructions card with step-by-step guidance

### Interactive Elements
- "Re-run Diagnostics" button for manual testing
- Expandable details for each diagnostic check
- Copy-friendly code snippets in setup instructions

## Setup Instructions Integration

The component provides comprehensive setup guidance including:

1. **Package Installation**: `npm install convex`
2. **Convex Initialization**: `npx convex dev`
3. **Environment Variables**: Required env vars with examples
4. **Client Provider Setup**: ConvexClientProvider integration
5. **Schema Definition**: Database schema and function creation

## Error Handling

### Server-Side Errors
- Package import failures are caught and logged
- Environment variable absence is handled gracefully
- Dynamic require errors are captured and reported

### Client-Side Errors
- Import failures for Convex packages are caught
- Connection test failures provide detailed error messages
- Component mounting issues are handled with loading states

### User Feedback
- Clear error messages with actionable guidance
- Detailed error information in diagnostic details
- Setup instructions tailored to detected issues

## Development Workflow

### For Developers
1. Access `/convex` route to view diagnostics
2. Follow setup instructions for any failing checks
3. Use "Re-run Diagnostics" to verify fixes
4. Monitor connection status during development

### For Debugging
- Console logs provide detailed execution flow
- Error details include stack traces and specific failure points
- Server and client checks are separated for targeted debugging

## Integration Points

### With Main Application
- Integrated into main app routing (`/convex`)
- Uses shared UI components (Card, Badge, Button, Alert)
- Follows app design system and theming

### With Convex Backend
- Directly tests Convex package availability
- Validates environment variable configuration
- Tests actual database connectivity via queries

### With Development Environment
- Provides guidance for local development setup
- Validates generated file presence
- Tests both server and client-side integration

## Maintenance and Updates

### Adding New Checks
1. Add new diagnostic logic to `runDiagnostics()` function
2. Update `DiagnosticResult` interface if needed
3. Add corresponding UI handling for new check types

### Modifying Setup Instructions
1. Update setup steps in the instructions card
2. Add new environment variables or configuration steps
3. Update code snippets and examples

### Error Message Updates
1. Modify error messages in diagnostic checks
2. Update setup guidance based on common issues
3. Add new troubleshooting information

This diagnostics system provides a comprehensive foundation for monitoring and maintaining the Convex integration in SarahsRecipes.ai, ensuring developers can quickly identify and resolve configuration issues.
