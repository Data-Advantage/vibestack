# Vibestack Quick Start Guide 🚀

Welcome to Vibestack! This guide will help you start building web applications using AI tools without writing a single line of code.

## Prerequisites

- An account on one or more of these platforms:
  - [Claude](https://claude.ai) for ideas & requirements
  - [v0.dev](https://www.v0.dev) for UI generation
  - [Supabase](https://www.supabase.com) for backend functionality
  - [Cursor](https://www.cursor.com) for code generation and editing
- A basic understanding of what you want to build (no technical knowledge required!)

## Step 1: Define Your Project

Before using any prompts, take a moment to write down:

1. **What problem does your application solve?**
2. **Who are your target users?**
3. **What are the 3-5 core features your app needs?**

This clarity will help you select the right prompts and get better results from AI tools.

## Step 2: Start with a UI Prototype (v0.dev)

v0.dev is perfect for quickly generating beautiful UI components:

1. Visit [v0.dev](https://www.v0.dev) and sign in
2. Copy one of our UI prompts below
3. Paste it into v0.dev, adding your specific details
4. Review and iterate on the generated UI

### Example Prompt for a Landing Page:

```
Create a modern landing page for [Your Product], a [brief description]. 
It should include:
- A hero section with a headline, subheading, and call-to-action button
- A features section with 3-4 key benefits
- A clean navigation bar with logo, links, and a sign-up button
- Mobile responsive design with Tailwind CSS
- Modern, professional aesthetic with [preferred color scheme]
```

## Step 3: Set Up Your Backend (Supabase)

Supabase provides database, authentication, and storage capabilities:

1. Visit [Supabase](https://www.supabase.com) and create a new project
2. Set up authentication (email/password or social logins)
3. Use our database schema prompts to create your tables
4. Configure row-level security for data protection

### Example Prompt for Supabase Schema:

```
Create a Supabase database schema for a [type of app] with the following features:
- User profiles with [specific fields]
- [Content type] table that belongs to users
- Relationships between [table 1] and [table 2]
- Row-level security policies to ensure users can only access their own data
```

## Step 4: Connect Frontend to Backend (Cursor)

Cursor is an AI-powered code editor that can help connect your UI to your backend:

1. Download and install [Cursor](https://www.cursor.com)
2. Create a new Next.js project with `npx create-next-app@latest`
3. Use our integration prompts to connect your Supabase backend
4. Test your application locally

### Example Prompt for Next.js + Supabase Integration:

```
Help me integrate Supabase authentication into my Next.js application.
I need:
- Login/signup functionality
- Protected routes for authenticated users
- User profile management
- Supabase client setup for both server and client components
```

## Step 5: Deploy Your Application

Once you're happy with your application:

1. Create a [Vercel](https://vercel.com) account
2. Connect your GitHub repository
3. Configure environment variables for Supabase
4. Deploy your application

## Common Prompt Patterns

For best results with AI tools, structure your prompts with:

1. **Context**: Briefly describe your project and goals
2. **Specificity**: Include exactly what you need, being as detailed as possible
3. **Examples**: Reference similar components or features you like
4. **Constraints**: Mention technical requirements or limitations
5. **Output Format**: Specify what form you want the response in

## Next Steps

- Explore our [prompt collection](../prompts/) for specific components and features
- Check out the [technical documentation](../docs/) for more advanced usage
- Join our community to share your creations and get help

Remember, Vibestack is designed to help you iterate quickly. Don't be afraid to try different prompts and approaches until you get the results you're looking for!

---

Need help? Have questions? [Contact us](https://www.buildadataadvantage.com) or follow us on [Twitter/X](https://twitter.com/dataadvantageai)
