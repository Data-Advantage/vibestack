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
| 1.1 - Product Requirements | [product-requirements-chat](1.1-product-requirements-chat.md) | `product-requirements-document.md` |
| 1.2 - Marketing Story | [marketing-story-chat](1.2-marketing-story-chat.md) | `marketing-content.md` |
| 1.3 - Database Setup | [database-setup-chat](1.3-database-setup-chat.md) | `000-initial-sql-migration.sql` |

### 1.1 - The Product Requirements

**Goal**: Create a `product-requirements-document.md` file that has a full written description of your product vision, features, and implementation details.

#### Process
1. Copy paste each Step in [product-requirements-chat](1.1-product-requirements-chat.md) into a Claude.ai conversation.
2. Follow all directions in [brackets] and replace the bracketed text with your own content.
3. Save the final output into a file named `product-requirements-document.md`

### 1.2 - The Marketing Story

**Goal**: Create compelling marketing narratives and website content that will help users understand and connect with your product.

#### Process
1. Copy paste each Step in [marketing-story-chat](1.2-marketing-story-chat.md) into an AI chat tool like Claude.ai.
2. Follow all directions in [brackets] and replace the bracketed text with your own content.
3. Save the final output as `marketing-content.md`

### 1.3 - The Database Setup

**Goal**: Define the data structure (schema) required for the web application, creating an `000-initial-sql-migration.sql` file that will fully install a custom Postgres database into your Supabase instance.

#### Process
1. Copy paste each Step in [database-setup-chat](1.3-database-setup-chat.md) into an AI chat tool like Claude.ai.
2. Follow all directions in [brackets] and replace the bracketed text with your own content.
3. Save the final output as `000-initial-sql-migration.sql`

## Afternoon: Building Your Initial App (2-4 hours)

| Phase | AI Chat Conversation Guide | Output |
|-------|-----------------|-----------------|
| 1.4 - Prototype App | [prototype-app-chat](1.4-prototype-app-chat.md) | Deployed working prototype |

### 1.4 - The Initial App Build

**Goal**: Create a working basic version of your application using the requirements developed in the morning.

#### Process
1. Set up accounts on necessary platforms (Supabase, Vercel, etc.)
2. Copy paste each Step in [initial-app-chat](1.4-initial-app-chat.md) into an AI chat tool.
3. Use the PRD, database schema, and marketing story you created in the morning to guide the AI.
4. Follow the implementation instructions to deploy your initial app.
5. By day's end, you'll have a basic working version online!

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