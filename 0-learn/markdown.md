# Markdown in VibeStack

Markdown is a lightweight markup language with plain text formatting syntax designed to be converted to HTML and many other formats. It's widely used for documentation, README files, forum posts, and more. In VibeStack, we use Markdown extensively for documentation and content management.

## Why Use Markdown?

- **Simplicity**: Easy to learn and read even in its raw form
- **Portability**: Works across platforms and applications
- **Flexibility**: Can be converted to many formats (HTML, PDF, DOCX)
- **Lightweight**: Files are small and text-based
- **Version Control Friendly**: Easy to track changes in Git

## Basic Syntax

### Headings

```markdown
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6
```

### Text Formatting

```markdown
*Italic text* or _Italic text_
**Bold text** or __Bold text__
***Bold and italic text*** or ___Bold and italic text___
~~Strikethrough text~~
```

### Lists

#### Unordered Lists

```markdown
- Item 1
- Item 2
  - Subitem 2.1
  - Subitem 2.2
- Item 3
```

#### Ordered Lists

```markdown
1. First item
2. Second item
3. Third item
   1. Subitem 3.1
   2. Subitem 3.2
```

### Links

```markdown
[Link text](https://www.example.com)
[Link with title](https://www.example.com "Title text")
```

### Images

```markdown
![Alt text](image-path.jpg)
![Alt text](image-path.jpg "Optional title")
```

### Blockquotes

```markdown
> This is a blockquote
> 
> It can span multiple lines
```

### Code

#### Inline Code

```markdown
Use the `console.log()` function to debug your code.
```

#### Code Blocks

````markdown
```javascript
function greet(name) {
  console.log(`Hello, ${name}!`);
}
```
````

### Horizontal Rules

```markdown
---
***
___
```

## Extended Markdown Syntax

### Tables

```markdown
| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |
```

### Task Lists

```markdown
- [x] Completed task
- [ ] Incomplete task
- [ ] Another task
```

### Footnotes

```markdown
Here's a sentence with a footnote[^1].

[^1]: This is the footnote content.
```

### Definition Lists

```markdown
Term
: Definition
```

### Emoji

```markdown
:smile: :heart: :thumbsup:
```

## Markdown in VibeStack Components

### Using Markdown in Next.js Components

In VibeStack, we often need to render Markdown content in our React components. We use libraries like `react-markdown` to accomplish this:

```typescript
import ReactMarkdown from 'react-markdown';

function MarkdownRenderer({ content }) {
  return <ReactMarkdown>{content}</ReactMarkdown>;
}
```

### With Syntax Highlighting

For code blocks with syntax highlighting, we use `react-syntax-highlighter`:

```typescript
import ReactMarkdown from 'react-markdown';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { atomDark } from 'react-syntax-highlighter/dist/cjs/styles/prism';

function MarkdownWithCodeHighlighting({ content }) {
  return (
    <ReactMarkdown
      components={{
        code({ node, inline, className, children, ...props }) {
          const match = /language-(\w+)/.exec(className || '');
          return !inline && match ? (
            <SyntaxHighlighter
              style={atomDark}
              language={match[1]}
              PreTag="div"
              {...props}
            >
              {String(children).replace(/\n$/, '')}
            </SyntaxHighlighter>
          ) : (
            <code className={className} {...props}>
              {children}
            </code>
          );
        },
      }}
    >
      {content}
    </ReactMarkdown>
  );
}
```

## Markdown Storage Strategies

### File-based Storage

For static content like documentation, we store Markdown files directly in the codebase:

```
/docs
  /api
    authentication.md
    endpoints.md
  /guides
    getting-started.md
```

### Database Storage

For user-generated content or dynamic documentation, we store Markdown in the database:

```typescript
// Supabase table example
type Document = {
  id: string;
  title: string;
  content: string; // Markdown content
  author_id: string;
  created_at: string;
  updated_at: string;
};
```

## Best Practices for Markdown in VibeStack

1. **Consistency**: Use a consistent style throughout your Markdown files
2. **Readability**: Format your Markdown with line breaks and spacing for better readability
3. **Headers**: Use descriptive headers and maintain a logical hierarchy
4. **Links**: Use relative links for internal navigation
5. **Images**: Optimize images before embedding them
6. **Validation**: Validate Markdown syntax before committing changes

## Tools for Working with Markdown

- **VS Code**: With extensions like "Markdown All in One" and "Markdown Preview Enhanced"
- **Typora**: WYSIWYG Markdown editor
- **Marked**: Markdown preview tool for macOS
- **Dillinger**: Online Markdown editor
- **MDX**: JSX in Markdown for advanced content creation

## Markdown Integration with UI Components

For advanced use cases, we use MDX (Markdown JSX) to mix UI components with Markdown:

```jsx
import { Button } from '@/components/ui/button';

# Getting Started

This guide will help you set up your VibeStack project.

<Button variant="primary">Download Starter Kit</Button>

## Step 1: Installation

Run the following command:

```bash
npm install vibestack
```
```

## Resources

- [CommonMark Specification](https://commonmark.org/)
- [GitHub Flavored Markdown Spec](https://github.github.com/gfm/)
- [Markdown Guide](https://www.markdownguide.org/)
- [MDX Documentation](https://mdxjs.com/)
- [React Markdown](https://github.com/remarkjs/react-markdown)
