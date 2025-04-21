[⬅️ Vibestack Overview](../README.md)

# Day 1: Create

Turn your idea into a working prototype with core functionality and key components.

## Introduction
Welcome to Day 1 of the Vibestack workflow! Today is divided into two key phases:
- **Morning**: Transform your concept into well-defined plans and requirements
- **Afternoon**: Build your initial app prototype based on those requirements

By the end of today, you'll have both foundational documents AND a working initial version of your application.

This process typically takes 6-8 hours total. You'll need access to an AI assistant like Claude.ai, a basic text editor to save your outputs, and accounts for the recommended tools. No coding experience is required—the AI will help you navigate technical challenges.

## Morning: Planning & Requirements (2-4 hours)

| Phase | AI Chat Conversation Guide | Output |
|-------|-----------------|-----------------|
| 1.1 - Product Requirements | [product-requirements](1.1-product-requirements.md) | `product-requirements-document.md` |
| 1.2 - Marketing Story | [marketing-story](1.2-marketing-story.md) | `marketing-content.md` |
| 1.3 - Landing Page | [landing-page](1.3-landing-page.md) | Deployed landing page |

### 1.1 - Product Requirements

**Goal**: Create a `product-requirements-document.md` file that has a full written description of your product vision, features, and implementation details.

#### Process
1. Copy paste each Step in [product-requirements](1.1-product-requirements.md) into a Claude.ai conversation.
2. Follow all directions in [brackets] and replace the bracketed text with your own content.
3. Save the final output into a file named `product-requirements-document.md`

### 1.2 - Marketing Story

**Goal**: Create compelling marketing narratives and website content that will help users understand and connect with your product.

#### Process
1. Copy paste each Step in [marketing-story](1.2-marketing-story.md) into an AI chat tool like Claude.ai.
2. Follow all directions in [brackets] and replace the bracketed text with your own content.
3. Save the final output as `marketing-content.md`

### 1.3 - Landing Page

**Goal**: Publish a real landing page at a *.vercel.app domain. Take in email address signups of interested users.

#### Process
1. Begin by adding your product requirements and marketing documents to your v0 project.
2. Set up the Supabase starter template and use the Vercel Supabase integration for automatic configuration.
3. Create a compelling landing page based on your marketing content.
4. Apply a cohesive visual style to your design.
5. Deploy to Vercel and thoroughly test your waitlist signup functionality.
6. Follow the detailed guide in [landing-page](1.3-landing-page.md).

## Afternoon: Building Your Initial App (2-4 hours)

| Phase | AI Chat Conversation Guide | Output |
|-------|-----------------|-----------------|
| 1.4 - Database Setup | [database-setup](1.4-database-setup.md) | `000-initial-sql-migration.sql` |
| 1.5 - Working Prototype | [working-prototype](1.5-working-prototype.md) | Deployed working prototype |

### 1.4 - Database Setup

**Goal**: Define the data structure (schema) required for the web application, creating an `000-initial-sql-migration.sql` file that will fully install a custom Postgres database into your Supabase instance.

#### Process
1. Copy paste each Step in [database-setup](1.4-database-setup.md) into an AI chat tool like Claude.ai.
2. Follow all directions in [brackets] and replace the bracketed text with your own content.
3. Save the final output as `000-initial-sql-migration.sql`

### 1.5 - Working Prototype

**Goal**: Expand your landing page into a working prototype with core functionality.

#### Process
1. Review your existing progress from sections 1.3 and 1.4
2. Follow each subsection in [working-prototype](1.5-working-prototype.md):
   - 1.5.1: Review Existing Progress
   - 1.5.2: Add Database Schema to Project Settings
   - 1.5.3: App Implementation Planning
   - 1.5.4: Enhance the Homepage
   - 1.5.5: Navigation Structure
   - 1.5.6: Database Connection
   - 1.5.7-1.5.10: Implement core features and prepare for deployment
3. By day's end, you'll have a functional prototype that uses your database schema and builds upon your landing page!

## Day 1 Completion Checklist

Before moving on to Day 2, ensure you have:

- [ ] Completed product requirements document with:
  - [ ] Clear product vision statement
  - [ ] Defined user personas
  - [ ] Prioritized MVP features
  - [ ] User stories with acceptance criteria
  - [ ] Non-functional requirements (security, performance, etc.)

- [ ] Created database schema with:
  - [ ] Tables for all key entities in your application
  - [ ] Defined relationships between tables
  - [ ] Appropriate data types and constraints
  - [ ] SQL ready to implement in Supabase

- [ ] Developed marketing content including:
  - [ ] Value proposition
  - [ ] Key messaging for target audience
  - [ ] Website structure outline
  - [ ] Content for main landing page sections

- [ ] Initial app implementation with:
  - [ ] Basic app functionality deployed online
  - [ ] Database connected and functioning
  - [ ] Core user flows working as expected
  - [ ] URL where you can access your working application

**What's Next**: On Day 2, you'll gather feedback on your initial app and begin refining both the user experience and functionality based on that feedback.