# Radix UI

[Radix UI](https://www.radix-ui.com/) is a low-level UI component library focused on accessibility, customization, and developer experience that powers many of the components in VibeStack.

## Introduction to Radix UI

Radix UI provides a collection of unstyled, accessible UI primitives for building high-quality React applications. Unlike component libraries that come with predefined styles, Radix components are completely unstyled, giving you complete design freedom.

Key benefits:
- **Accessibility built-in**: WAI-ARIA compliant components
- **Unstyled components**: Total styling flexibility
- **Composable parts**: Granular control over component structure
- **Uncontrolled by default**: With controlled options when needed
- **Keyboard navigation**: First-class keyboard user experience

## Installation & Setup

Radix UI is divided into separate primitives, each installed individually:

```bash
# Example installing Dialog primitive
npm install @radix-ui/react-dialog

# Multiple primitives example
npm install @radix-ui/react-dialog @radix-ui/react-dropdown-menu @radix-ui/react-tabs
```

## Basic Usage Example

Here's an example of a Radix Dialog component:

```jsx
import * as Dialog from '@radix-ui/react-dialog';

function DeleteConfirmation() {
  return (
    <Dialog.Root>
      <Dialog.Trigger asChild>
        <button className="text-red-500">Delete Item</button>
      </Dialog.Trigger>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-black/50" />
        <Dialog.Content className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-white p-6 rounded-lg shadow-lg">
          <Dialog.Title className="text-xl font-bold">Confirm Deletion</Dialog.Title>
          <Dialog.Description className="mt-2 text-gray-600">
            This action cannot be undone. Are you sure you want to delete this item?
          </Dialog.Description>
          <div className="mt-4 flex justify-end gap-2">
            <Dialog.Close asChild>
              <button className="px-4 py-2 bg-gray-200 rounded">Cancel</button>
            </Dialog.Close>
            <button className="px-4 py-2 bg-red-500 text-white rounded">Delete</button>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
```

## Common Radix Primitives in VibeStack

| Component | Description | Usage |
|-----------|-------------|-------|
| Dialog | Modal dialogs | Confirmations, forms, details views |
| Dropdown Menu | Contextual menus | Navigation, actions, options |
| Tabs | Tabbed interfaces | Content organization, settings panels |
| Select | Dropdown selection | Form inputs, filtering |
| Toast | Brief notifications | System messages, confirmations |
| Tooltip | Contextual information | Help text, additional details |
| Popover | Anchored content | Rich interactions, complex forms |

## Integration with shadcn/ui

In VibeStack, we use [shadcn/ui](shadcn.md), which builds upon Radix primitives by adding Tailwind styling. This gives us the best of both worlds:

- Radix's robust accessibility and functionality
- Beautiful, consistent styling with Tailwind
- Customization flexibility

Example of how the relationship works:

```jsx
// The shadcn/ui Button component
// At its core, this can use Radix's Button primitive, 
// but with added Tailwind styling and variants

import { Button } from "@/components/ui/button";

function Example() {
  return (
    <div className="space-x-2">
      <Button variant="default">Default</Button>
      <Button variant="destructive">Destructive</Button>
      <Button variant="outline">Outline</Button>
      <Button variant="ghost">Ghost</Button>
      <Button variant="link">Link</Button>
    </div>
  );
}
```

## Advanced Patterns

### Compound Components

Radix uses the compound component pattern for compositional flexibility:

```jsx
<Select.Root>
  <Select.Trigger>
    <Select.Value />
    <Select.Icon />
  </Select.Trigger>
  <Select.Portal>
    <Select.Content>
      <Select.ScrollUpButton />
      <Select.Viewport>
        <Select.Item>
          <Select.ItemText />
          <Select.ItemIndicator />
        </Select.Item>
      </Select.Viewport>
      <Select.ScrollDownButton />
    </Select.Content>
  </Select.Portal>
</Select.Root>
```

### Handling State

Radix components can be either controlled or uncontrolled:

```jsx
// Uncontrolled
<Tabs.Root defaultValue="tab1">
  {/* Tab content */}
</Tabs.Root>

// Controlled
const [value, setValue] = useState('tab1');
<Tabs.Root value={value} onValueChange={setValue}>
  {/* Tab content */}
</Tabs.Root>
```

## Accessibility Features

- **Keyboard navigation**: Tab, arrow keys, space, and enter
- **ARIA attributes**: Role, aria-expanded, aria-selected, etc.
- **Focus management**: Proper focus trapping in modals
- **Screen reader announcements**: For important state changes

## Resources

- [Radix UI Documentation](https://www.radix-ui.com/docs/primitives/overview/introduction)
- [shadcn/ui](https://ui.shadcn.com/) (built on Radix UI)
- [Radix UI GitHub](https://github.com/radix-ui/primitives)
- [Radix UI Discord](https://discord.com/invite/7Xb99uG)
