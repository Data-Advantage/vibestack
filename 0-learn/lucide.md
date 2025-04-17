# Lucide Icons

[Lucide](https://lucide.dev/) is a beautiful, consistent, and open-source icon library used in VibeStack for UI elements, providing a clean and modern look to your application.

## Installation & Setup

Lucide is already integrated with your VibeStack project. The icons are available through the `lucide-react` package.

```bash
# For reference, this is how it was installed
npm install lucide-react
```

## Basic Usage

```jsx
import { Search, Menu, Bell, Settings } from 'lucide-react';

function Navbar() {
  return (
    <nav>
      <Menu className="w-6 h-6" />
      <div className="search-container">
        <Search className="w-4 h-4 text-gray-500" />
        <input type="text" placeholder="Search..." />
      </div>
      <div className="navbar-actions">
        <Bell className="w-5 h-5" />
        <Settings className="w-5 h-5" />
      </div>
    </nav>
  );
}
```

## Styling Icons

Lucide icons are essentially SVGs, so you can style them with all the standard CSS properties:

```jsx
// Size customization
<User className="w-6 h-6" />

// Color customization
<Heart className="text-red-500" />

// Both size and color
<Star className="w-8 h-8 text-yellow-400" />

// With Tailwind, you can add hover effects
<Bell className="w-5 h-5 text-gray-600 hover:text-blue-500 transition-colors" />
```

## Icon Customization

You can customize Lucide icons with these props:

```jsx
<AlertCircle 
  size={24} // Sets both width and height
  color="#ff0000" // Sets the stroke color
  strokeWidth={2} // Changes line thickness
  absoluteStrokeWidth // Keeps stroke width consistent regardless of size
/>
```

## Icon Patterns and Best Practices

1. **Consistency**: Use the same icon style throughout your application
2. **Accessibility**: Add appropriate ARIA labels when icons convey meaning
   ```jsx
   <Button aria-label="Settings">
     <Settings className="w-5 h-5" />
   </Button>
   ```
3. **Loading States**: Use the `Loader` icon with animation for loading states
   ```jsx
   <Loader className="w-5 h-5 animate-spin" />
   ```
4. **Indicators**: Use small icons to indicate status
   ```jsx
   <div className="relative">
     <Bell className="w-6 h-6" />
     <span className="absolute top-0 right-0 w-2 h-2 bg-red-500 rounded-full"></span>
   </div>
   ```

## Common Icons Used in VibeStack

| Icon | Import | Usage |
|------|--------|-------|
| `User` | `import { User } from 'lucide-react'` | User profiles, accounts |
| `Settings` | `import { Settings } from 'lucide-react'` | Configuration pages |
| `LogIn`/`LogOut` | `import { LogIn, LogOut } from 'lucide-react'` | Authentication actions |
| `Plus`/`Minus` | `import { Plus, Minus } from 'lucide-react'` | Add/remove items |
| `ChevronDown` | `import { ChevronDown } from 'lucide-react'` | Dropdown menus |
| `Search` | `import { Search } from 'lucide-react'` | Search functionality |
| `Moon`/`Sun` | `import { Moon, Sun } from 'lucide-react'` | Dark/light theme toggle |

## Resources

- [Lucide Documentation](https://lucide.dev/docs/lucide-react)
- [Icon Explorer](https://lucide.dev/icons/)
- [GitHub Repository](https://github.com/lucide-icons/lucide)
