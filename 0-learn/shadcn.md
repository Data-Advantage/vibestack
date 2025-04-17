## components.json

Configures `shadcn/ui`, defining the style, component paths, Tailwind setup, and icon library used when adding new UI components via the CLI (`npx shadcn-ui@latest add ...`).

```json:components.json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "", // Usually empty for Tailwind v4
    "css": "app/globals.css", // Path to your global CSS file
    "baseColor": "stone", // Base color scheme for components
    "cssVariables": true, // Use CSS variables for theming
    "prefix": "" // Optional prefix for Tailwind classes
  },
  "aliases": {
    "components": "@/components", // Base directory for components
    "utils": "@/lib/utils",     // Utility functions (like cn)
    "ui": "@/components/ui",    // Directory for shadcn UI components
    "lib": "@/lib",             // General library directory
    "hooks": "@/hooks"          // Custom hooks directory
  },
  "iconLibrary": "lucide" // Specify icon library (lucide-react)
}
```