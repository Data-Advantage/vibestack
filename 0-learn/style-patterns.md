# USe Theme variables

Theme variables are special CSS variables defined using the @theme directive that influence which utility classes exist in your project.

For example, you can add a new color to your project by defining a theme variable like --color-mint-500:

```css
@import "tailwindcss";

@theme {
  --color-mint-500: oklch(0.72 0.11 178);
}
```

Now you can use utility classes like bg-mint-500, text-mint-500, or fill-mint-500 in your HTML:

```html
<div class="bg-mint-500">
  <!-- ... -->
</div>
```

Tailwind also generates regular CSS variables for your theme variables so you can reference your design tokens in arbitrary values or inline styles:

```html
<div style="background-color: var(--color-mint-500)">
  <!-- ... -->
</div>
```

# Use Media queries and breakpoints

For example:

```html
<div class="grid grid-cols-2 sm:grid-cols-3">
  <!-- ... -->
</div>
```

Which generates this CSS:

```css
.sm\:grid-cols-3 {
  @media (width >= 40rem) {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}
```

# Dark Mode

To make this as easy as possible, Tailwind includes a dark variant that lets you style your site differently when dark mode is enabled:

Styling an element in dark mode is just a matter of adding the dark: prefix to any utility you want to apply when dark mode is active:

```html
<div class="bg-white dark:bg-gray-800 rounded-lg px-6 py-8 ring shadow-xl ring-gray-900/5">
  <div>
    <span class="inline-flex items-center justify-center rounded-md bg-indigo-500 p-2 shadow-lg">
      <svg
        class="h-6 w-6 text-white"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        aria-hidden="true"
      >
        <!-- ... -->
      </svg>
    </span>
  </div>
  <h3 class="text-gray-900 dark:text-white mt-5 text-base font-medium tracking-tight ">Writes upside-down</h3>
  <p class="text-gray-500 dark:text-gray-400 mt-2 text-sm ">
    The Zero Gravity Pen can be used to write in any orientation, including upside-down. It even works in outer space.
  </p>
</div>
```

By default this uses the prefers-color-scheme CSS media feature, but you can also build sites that support toggling dark mode manually by overriding the dark variant.

Just like with hover states or media queries, the important thing to understand is that a single utility class will never include both the light and dark styles — you style things in dark mode by using multiple classes, one for the light mode styles and another for the dark mode styles.

Generated CSS:

```css
.dark\:bg-gray-800 {
  @media (prefers-color-scheme: dark) {
    background-color: var(--color-gray-800);
  }
}
```