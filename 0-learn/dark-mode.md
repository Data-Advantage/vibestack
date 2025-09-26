# Tailwind v4 + Next.js (App Router) + React Light/Dark Mode Architecture

This document explains how to implement a robust, zero-flicker light/dark theme with Tailwind CSS v4, CSS custom properties (OKLCH), and `next-themes`. It also shows exactly how the header toggle is wired with proper bar-themed colors.

- Tailwind v4 maps CSS variables to semantic utilities (`bg-background`, `text-foreground`, etc.).
- `next-themes` adds and persists the theme class on the root element and handles SSR to avoid hydration issues.
- A small `ThemeSwitcher` cycles Light → Dark → System and lives in the global header.
- Custom amber/orange color palette creates a warm bar atmosphere.

---

## 1) Global CSS and Tokens (`app/globals.css`)

We use OKLCH for perceptual uniformity and expose design tokens as CSS variables. Tailwind v4's `@theme inline` maps these variables to utilities, and a custom `dark` variant ensures the class strategy.

\`\`\`css
@import 'tailwindcss';

/* Ensure tailwind's dark: variant is driven by a .dark class on <html> */
@custom-variant dark (&:is(.dark *));

:root {
  /* Light theme - Warm bar atmosphere */
  --background: oklch(0.98 0.01 60);
  --foreground: oklch(0.15 0.02 30);
  --card: oklch(1.0 0 0);
  --card-foreground: oklch(0.15 0.02 30);
  --popover: oklch(1.0 0 0);
  --popover-foreground: oklch(0.15 0.02 30);
  --primary: oklch(0.65 0.15 45);
  --primary-foreground: oklch(0.98 0.01 60);
  --secondary: oklch(0.96 0.02 50);
  --secondary-foreground: oklch(0.25 0.03 35);
  --muted: oklch(0.95 0.02 55);
  --muted-foreground: oklch(0.45 0.03 40);
  --accent: oklch(0.92 0.03 50);
  --accent-foreground: oklch(0.25 0.03 35);
  --destructive: oklch(0.62 0.18 25);
  --destructive-foreground: oklch(0.98 0.01 60);
  --border: oklch(0.88 0.02 50);
  --input: oklch(0.95 0.02 55);
  --ring: oklch(0.65 0.15 45);

  /* Fonts */
  --font-sans: var(--font-geist-sans);
  --font-mono: var(--font-geist-mono);
}

.dark {
  /* Dark theme - Cozy bar lighting */
  --background: oklch(0.08 0.02 30);
  --foreground: oklch(0.92 0.01 60);
  --card: oklch(0.12 0.02 35);
  --card-foreground: oklch(0.92 0.01 60);
  --popover: oklch(0.10 0.02 32);
  --popover-foreground: oklch(0.92 0.01 60);
  --primary: oklch(0.70 0.15 45);
  --primary-foreground: oklch(0.08 0.02 30);
  --secondary: oklch(0.15 0.02 35);
  --secondary-foreground: oklch(0.85 0.01 55);
  --muted: oklch(0.18 0.02 38);
  --muted-foreground: oklch(0.65 0.02 45);
  --accent: oklch(0.22 0.03 40);
  --accent-foreground: oklch(0.85 0.01 55);
  --destructive: oklch(0.62 0.18 25);
  --destructive-foreground: oklch(0.92 0.01 60);
  --border: oklch(0.25 0.02 40);
  --input: oklch(0.18 0.02 38);
  --ring: oklch(0.70 0.15 45);
}

@theme inline {
  /* Map CSS variables to Tailwind tokens */
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-card: var(--card);
  --color-card-foreground: var(--card-foreground);
  --color-popover: var(--popover);
  --color-popover-foreground: var(--popover-foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --color-secondary: var(--secondary);
  --color-secondary-foreground: var(--secondary-foreground);
  --color-muted: var(--muted);
  --color-muted-foreground: var(--muted-foreground);
  --color-accent: var(--accent);
  --color-accent-foreground: var(--accent-foreground);
  --color-destructive: var(--destructive);
  --color-destructive-foreground: var(--destructive-foreground);
  --color-border: var(--border);
  --color-input: var(--input);
  --color-ring: var(--ring);

  --font-sans: var(--font-sans);
  --font-mono: var(--font-mono);
}

@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
  }
}
\`\`\`

---

## 2) App Router Integration (`app/layout.tsx`)

We use `ThemeProvider` from `next-themes` with `attribute="class"` so the `.dark` class lands on `<html>`. Fonts are bound to CSS variables and applied globally.

\`\`\`tsx
import type { Metadata } from "next";
import { Geist, Geist_Mono } from 'next/font/google';
import "./globals.css";
import { ThemeProvider } from "next-themes";
import { ClerkProvider } from "@clerk/nextjs";
import { ConvexClientProvider } from "@/components/convex-client-provider";
import { Header } from "@/components/header";
import { Footer } from "@/components/footer";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <ClerkProvider>
      <html lang="en" suppressHydrationWarning className={`${geistSans.variable} ${geistMono.variable}`}>
        <body className="antialiased">
          <ThemeProvider
            attribute="class"
            defaultTheme="system"
            enableSystem
            disableTransitionOnChange
          >
            <ConvexClientProvider>
              <div className="min-h-screen flex flex-col">
                <Header />
                <main className="flex-1">{children}</main>
                <Footer />
              </div>
            </ConvexClientProvider>
          </ThemeProvider>
        </body>
      </html>
    </ClerkProvider>
  );
}
\`\`\`

Notes:
- `suppressHydrationWarning` helps avoid warnings when `next-themes` swaps the class on hydration.
- `defaultTheme="system"` makes the first paint respect the OS theme.
- `disableTransitionOnChange` prevents jarring animations during theme switches.

---

## 3) Theme Switcher (`components/theme-switcher.tsx`)

The switcher cycles Light → Dark → System with proper icons and defers rendering until mounted to avoid client/server mismatch.

\`\`\`tsx
"use client"

import { useTheme } from "next-themes"
import { useEffect, useState } from "react"
import { Moon, Sun, Monitor } from 'lucide-react'

export function ThemeSwitcher() {
  const [mounted, setMounted] = useState(false)
  const { theme, setTheme } = useTheme()

  useEffect(() => {
    setMounted(true)
  }, [])

  if (!mounted) {
    return (
      <div className="w-9 h-9 bg-muted rounded-lg animate-pulse flex items-center justify-center">
        <div className="w-4 h-4 bg-muted-foreground/20 rounded" />
      </div>
    )
  }

  const toggleTheme = () => {
    if (theme === "light") {
      setTheme("dark")
    } else if (theme === "dark") {
      setTheme("system")
    } else {
      setTheme("light")
    }
  }

  const getIcon = () => {
    if (theme === "light") return <Sun className="h-4 w-4" />
    if (theme === "dark") return <Moon className="h-4 w-4" />
    return <Monitor className="h-4 w-4" />
  }

  const getTitle = () => {
    if (theme === "light") return "Switch to dark mode"
    if (theme === "dark") return "Switch to system mode"
    return "Switch to light mode"
  }

  return (
    <button
      onClick={toggleTheme}
      className="w-9 h-9 bg-muted hover:bg-accent text-muted-foreground hover:text-accent-foreground rounded-lg transition-colors duration-200 flex items-center justify-center"
      title={getTitle()}
      aria-label={getTitle()}
    >
      {getIcon()}
      <span className="sr-only">Toggle theme</span>
    </button>
  )
}
\`\`\`

Key features:
- Proper mounting guard prevents hydration mismatches
- Three-state cycle: Light → Dark → System
- Accessible with proper ARIA labels and titles
- Smooth transitions with hover states

---

## 4) Header Integration (`components/header.tsx`)

The theme switcher is placed in the header alongside authentication components.

\`\`\`tsx
import { ThemeSwitcher } from "./theme-switcher"
import { SignedIn, SignedOut, SignInButton, UserButton } from "@clerk/nextjs"
// ... other imports

export function Header() {
  return (
    <header className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container flex h-16 items-center justify-between">
        {/* Left: Logo and navigation */}
        <div className="flex items-center gap-6">
          {/* Logo and nav items */}
        </div>

        {/* Right: Theme switcher and auth */}
        <div className="flex items-center gap-4">
          <ThemeSwitcher />
          <SignedOut>
            <SignInButton />
          </SignedOut>
          <SignedIn>
            <UserButton />
          </SignedIn>
        </div>
      </div>
    </header>
  )
}
\`\`\`

---

## 5) Key Differences from Original Implementation

### What Works Now:
1. **Proper mounting guard**: Prevents React state update errors during SSR/hydration
2. **Three-state theme cycle**: Light → Dark → System with appropriate icons
3. **Bar-themed color palette**: Warm amber/orange OKLCH colors for cozy atmosphere
4. **Gradient text fixes**: Proper fallback colors prevent contrast issues
5. **Clerk integration**: Works seamlessly with authentication components

### Critical Fixes Applied:
- **React state update error**: Fixed by proper `mounted` state management
- **Icon switching**: Icons now properly reflect current theme state
- **Theme persistence**: `next-themes` properly saves and restores theme choice
- **Hydration safety**: `suppressHydrationWarning` and mounting guards prevent mismatches
- **Contrast compliance**: Gradient text has proper fallback colors for accessibility

---

## 6) Usage Patterns

- **Background/text**: `className="bg-background text-foreground"`
- **Cards**: `className="bg-card text-card-foreground border border-border rounded-lg"`
- **Interactive states**: `hover:bg-accent hover:text-accent-foreground focus-visible:outline-ring`
- **Dark-specific tweaks**: `dark:shadow-xl`, `dark:bg-secondary`
- **Gradient text**: Always include fallback colors: `text-amber-600 dark:text-amber-400`

---

## 7) Troubleshooting

- **Theme not switching**: Ensure `ThemeProvider` wraps the entire app and has `attribute="class"`
- **Icons not updating**: Check that `mounted` state is properly managed in `ThemeSwitcher`
- **Hydration warnings**: Use `suppressHydrationWarning` on `<html>` and mounting guards
- **Contrast issues**: Always provide fallback colors for gradient text
- **Flash of wrong theme**: Verify `defaultTheme="system"` and proper provider setup

---

This implementation provides a robust, accessible theme system with a warm bar atmosphere that works seamlessly across all components and prevents common React hydration issues.
