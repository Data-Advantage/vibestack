# SarahsRecipes.ai - Product Requirements Document

## Executive Summary

Sarah's Recipes is a user-friendly recipe management application that empowers home cooks to capture, organize, and share their favorite recipes without the distraction of ads or lengthy narratives. Using artificial intelligence, the app extracts recipe details from various sources (URLs, text, images), creates beautiful visual representations, and provides a clean cooking experience.

This document outlines the requirements for the MVP release, detailing both functional and non-functional aspects to guide development, design, and business decisions. The requirements directly align with the comprehensive Supabase data model that has been implemented.

## Product Vision

Sarah's Recipes aims to solve three key problems for home cooks:
1. **Too Many Ads**: Recipe websites are cluttered with advertisements and unnecessary content
2. **Too Much Time**: Manually capturing recipes is tedious and error-prone
3. **Too Scattered**: Recipes are trapped across dozens of websites, screenshots, and books

Our solution provides an ad-free, centralized recipe collection with AI-powered extraction to save time and enhance the cooking experience.

## User Personas

### Primary: The Organized Home Cook (Sarah)
- Regularly cooks 5-10 meals per week
- Values efficiency and organization
- Frustrated by ads and life stories on recipe sites
- Wants to preserve family recipes
- Enjoys planning meals for the week ahead
- Values having a consolidated shopping list

### Secondary: The Recipe Collector (Michael)
- Enjoys trying new recipes
- Has a large collection spread across various platforms
- Shares recipes with family and friends
- Needs shopping list functionality
- Likes to discover and try friends' recipes
- Often participates in potluck gatherings

### Social Foodie (Jamie)
- Cooks occasionally but loves food culture
- Enjoys discovering recipes from friends
- Frequently uses social features to share cooking experiences
- Organizes potluck gatherings with friends
- Values the visual appeal of recipes

## Functional Requirements

### 1. User Authentication & Profile Management

#### Feature Description
Allow users to create accounts, manage their profiles, and securely access their personal recipe collections.

#### User Stories
- As a new user, I want to create an account so that I can save and access my recipes across devices.
- As a new user, I want to sign up with my Google account so I can quickly get started without creating a new password.
- As a registered user, I want to log in securely so that I can access my personal recipe collection.
- As a user, I want to update my profile information so that my account reflects my current details.
- As a user, I want to upload a profile picture so that my account feels personalized.
- As a user, I want to add optional biographical information and location data so others can learn about me.
- As a user, I want to add my social media and website links to my profile so others can connect with me across platforms.
- As a user, I want to have a unique username so I can be identified in the community.
- As a user, I want to log out of my account so that my information remains secure when using shared devices.

#### Acceptance Criteria
- User can register with email, password, first name, and last name
- User can register and login with Google OAuth
- User can log in with email and password
- User can view and edit profile information (first name, last name, profile picture, bio, location)
- User can add multiple social media and website links to their profile
- System generates a unique username based on user's name and unique identifier
- User can reset password via email
- User can log out from any screen
- User profile changes persist between sessions
- Profile picture is displayed in the navigation menu
- Soft deletion supported for user accounts (deleted_at field)

#### Dependencies
- Requires Supabase authentication setup
- Requires Google OAuth integration
- Requires secure storage for profile images
- Requires user profile database schema

### 2. Recipe Capture & Creation

#### Feature Description
Enable users to add recipes through multiple methods: URL extraction, text input, image upload, camera capture, or manual entry.

#### User Stories
- As a user, I want to paste a URL from a recipe website so that the app automatically extracts the recipe details.
- As a user, I want to paste recipe text so that the app parses it into structured recipe components.
- As a user, I want to upload an image of a recipe so that the app extracts the content.
- As a user, I want to take a photo of a physical recipe so that I can digitize my collection.
- As a user, I want to chat with Recipe Assistant about a partial recipe idea and have the chat AI fill in the rest of the form.
- As a user, I want to manually enter a recipe so that I can customize every detail.
- As a user, I want all recipe components (title, ingredients, instructions, times, servings) properly categorized so that the information is well-organized.
- As a user, I want to add cuisine and course information so I can categorize my recipes.
- As a user, I want to specify dietary tags so I can filter recipes by dietary preferences.
- As a user, I want to cite the original source URL so I can reference where the recipe came from.
- As a user without a recipe image, I want the system to generate an AI image based on my recipe so my collection looks complete and attractive.

#### Acceptance Criteria
- URL extraction supports major recipe websites (AllRecipes, Food Network, etc.)
- Text extraction accurately identifies recipe title, ingredients, instructions, and metadata
- Image upload supports common formats (JPG, PNG, GIF, WEBP, HEIF)
- Camera capture interface is mobile-friendly
- Recipe Assistant chat extrapolates the conversation into a full structured recipe
- Manual entry form includes all standard recipe fields
- All extraction methods provide edit capability before final save
- AI automatically generates recipe images when none are provided by the user
- Extracted recipes include: name, description, prep time, cook time, total time, servings, cuisine, course, dietary tags, source URL, and image URL
- Support for categorizing by cuisine types (American, Italian, Mexican, etc.)
- Support for categorizing by course types (appetizer, breakfast, lunch, dinner, etc.)
- Support for dietary tags (vegetarian, vegan, gluten-free, etc.)
- SEO-friendly slug generation for recipe URLs
- Recipes appear with high quality previews when shared on social media or texting with OpenSocial images
- Saved recipes appear immediately in the user's recipe collection

#### Dependencies
- Requires AI integration for extraction features
- Requires AI image generation capabilities
- Requires camera access permissions
- Requires secure file upload/storage
- Requires recipe database schema

### 3. Recipe Components Management

#### Feature Description
Support structured data for ingredients, instructions, and nutritional information.

#### User Stories
- As a user, I want to add specific ingredients with quantities and notes so my recipes are accurate.
- As a user, I want to view ingredients in a logical order so I can follow the recipe easily.
- As a user, I want to add step-by-step instructions so I know how to prepare the dish.
- As a user, I want nutritional information to be automatically calculated so I can track dietary values.
- As a user, I want nutritional information to update when I change ingredients so it remains accurate.
- As a user, I want to edit individual recipe components without changing the entire recipe.
- As a user, I want to convert ingredient measurements between different units (cups to ml, oz to grams, etc.) so I can cook with my preferred system.

#### Acceptance Criteria
- Ingredients can be added with name, quantity, notes, and sort order
- Instructions can be added with step number and detailed instruction text
- Nutritional information is automatically calculated when a recipe is created
- Nutritional information recalculates when ingredients are changed
- Nutritional details include calories, protein, fats, carbohydrates, etc.
- Components are displayed in logical order (ingredients by sort_order, instructions by step_number)
- Components can be edited individually
- Changes to components are immediately reflected in recipe view
- Measurement conversion is available for common units (volume, weight, temperature)
- Default measurements are preserved from original recipe
- Conversion maintains proper ratios and proportions

#### Dependencies
- Requires database schema for ingredients, instructions, and nutritional info
- Requires UI components for editing structured data
- Requires nutritional calculation service/API
- Requires measurement conversion system

### 4. Recipe Management & Organization

#### Feature Description
Allow users to view, edit, categorize, and organize their recipe collection.

#### User Stories
- As a user, I want to view my entire recipe collection so that I can find recipes I've saved.
- As a user, I want to view detailed information about a specific recipe so that I can cook from it.
- As a user, I want to edit only my own recipes so I maintain control of my content.
- As a user, I want to print a recipe so I can reference it while cooking without a device.
- As a user, I want to see the number of likes my recipe has received so I know how popular it is.
- As a user, I want to make a copy of someone else's recipe so I can modify it to my preferences.
- As a user, I want to see if someone has copied my recipe and see how they changed it
- As a user, I want to categorize recipes by cuisine and course type so that I can easily find recipes for specific occasions.
- As a user, I want to tag recipes with dietary preferences so I can find appropriate recipes.
- As a user, I want to see attractive recipe images so that I can visualize dishes before cooking.
- As a user, I want to pin favorite recipes (up to 3) to my profile so I can quickly access my most-used recipes.
- As a user, I want a shareable public URL for my recipe so I can share it with others outside the platform.

#### Acceptance Criteria
- Recipes are displayed in a grid with images, titles, and basic information
- Recipe detail view shows all recipe components in a clean, ad-free format
- Print functionality generates a clean, printer-friendly version of the recipe
- Recipe cards display the current like count
- Edit functionality is restricted to recipe owners only
- "Copy Recipe" functionality allows users to create personal copies of any recipe
- Copied recipes maintain attribution to the original creator
- Recipes can be categorized by cuisine (American, Italian, Mexican, etc.)
- Recipes can be categorized by course (appetizer, main, dessert, etc.)
- Recipes can be tagged with dietary preferences (vegetarian, vegan, gluten-free, etc.)
- Missing recipe images can be AI-generated based on recipe details
- Recipe view includes "Add to Shopping List" functionality
- Users can pin up to 3 recipes on their profile page for quick access
- Each recipe has a unique, human-readable slug for public sharing
- Support for soft deletion of recipes (deleted_at field)

#### Dependencies
- Requires recipe database schema
- Requires integration with AI image generation
- Requires filtering/sorting capabilities
- Requires recipe forking logic
- Requires print stylesheet and functionality

### 5. Shopping List Management

#### Feature Description
Allow users to create and manage shopping lists from recipe ingredients and custom items.

#### User Stories
- As a user, I want to add recipe ingredients to my shopping list so that I know what to buy.
- As a user, I want to add custom items to my shopping list so that I can include non-recipe items.
- As a user, I want to check off items while shopping so that I can track what I've already purchased.
- As a user, I want to remove items from my shopping list so that I can maintain an accurate list.
- As a user, I want to clear completed items so that my list stays organized.
- As a user, I want to see which recipe an ingredient is from so I remember why I'm buying it.
- As a user, I want to organize my shopping list items in a specific order.
- As a user, I want a unified shopping list that combines ingredients from multiple recipes to simplify my shopping experience.

#### Acceptance Criteria
- Users can add all or selected ingredients from a recipe to the shopping list
- Users can add custom items with optional quantity specification
- Shopping list items can be checked/unchecked
- Shopping list items can be removed individually
- "Clear Completed" functionality removes all checked items
- Shopping list is accessible from the main navigation
- Shopping list shows a count of items in the navigation badge
- Shopping list items store reference to original recipe (if applicable)
- Shopping list items can be sorted in custom order
- Shopping list stores both original recipe quantity and custom quantity
- Similar ingredients from multiple recipes are intelligently combined when possible

#### Dependencies
- Requires shopping list database schema
- Requires integration with recipe ingredient data
- Requires real-time updates for item status changes

### 6. Social & Interaction Features

#### Feature Description
Enable users to share recipes and interact with the community's recipe collection through likes, favorites, and follows.

#### User Stories
- As a user, I want to view recipes from other users so that I can discover new dishes.
- As a user, I want to like recipes so that I can show appreciation and bookmark them.
- As a user, I want to favorite recipes so that I can save recipes I want to try later.
- As a user, I want to follow other users so that I can see their new recipes.
- As a user, I want to see my liked recipes in one place so that I can easily access them.
- As a user, I want to see my favorited recipes in one place so that I can easily access them.
- As a user, I want to share recipes with friends outside the app so that I can spread culinary inspiration.
- As a user, I want to try recipes my friends have created and enjoyed.
- As a user, I want to share a recipe with a beautiful OpenSocial preview on social media and texting

#### Acceptance Criteria
- Community recipes are viewable in an "All Recipes" section
- Like functionality is available on recipe cards and detail views
- Favorite functionality saves recipes to a dedicated list
- Follow functionality creates connections between users
- Liked recipes are accessible through a dedicated view
- Favorited recipes are accessible through a dedicated view
- Recipe cards show the creator's username
- Recipes display like count
- Users can view who they follow and who follows them
- Feed prioritizes recipes from followed users

#### Dependencies
- Requires likes database schema
- Requires favorites database schema
- Requires follows database schema
- Requires sharing functionality
- Requires community content moderation strategy

### 7. Meal Planning

#### Feature Description
Enable users to plan meals by scheduling recipes for future cooking dates.

#### User Stories
- As a user, I want to add recipes to specific dates so I can plan my meals.
- As a user, I want to view my meal plan in a calendar format so I can see my upcoming meals.
- As a user, I want to organize multiple recipes for a single day so I can plan complete meals.
- As a user, I want to remove recipes from my meal plan if my plans change.
- As a user, I want to plan meals by day, week, or month so I can organize at different scales.

#### Acceptance Criteria
- Users can add recipes to future dates
- Users can view recipes planned for each date
- Users can arrange multiple recipes for a single date in a specific order
- Users can remove recipes from planned dates
- Calendar view shows upcoming meal plans with daily, weekly, and monthly views
- Cannot add recipes to dates in the past
- Option to add meal plan ingredients to shopping list

#### Dependencies
- Requires meal plan database schema
- Requires calendar view UI component
- Requires integration with recipe database
- Requires integration with shopping list

### 8. Potluck Events

#### Feature Description
Allow users to create and manage potluck events where friends can sign up to bring specific dishes.

#### User Stories
- As a host, I want to create a potluck event so I can organize a gathering with shared food responsibilities.
- As a host, I want to define slots for different dish types so the meal is balanced.
- As a host, I want to allow or disallow invitees to create their own custom slots.
- As a host, I want to allow invitees to create their own custom slots if all designated slots are already full.
- As a host, I want to invite friends to my potluck so they can sign up for slots.
- As a host, I want to designate co-hosts from users I follow so they can help manage the event.
- As a host, I want to generate a public URL for my potluck so anyone can view it and sign up.
- As an invitee, I want to claim a slot in a potluck so I can contribute to the meal.
- As an invitee, I want to specify which recipe I'm bringing so others know what to expect.
- As an invitee, I want to add comments about my dish so I can provide additional information.
- As an invitee, I want to specify dietary preferences/restrictions so hosts can plan accordingly.
- As a non-registered invitee, I want to sign up for a slot without creating a full account first.
- As a host or invitee, I want to see what everyone is bringing so I can anticipate the meal.

#### Acceptance Criteria
- Users can create potluck events with date, time, location, and description
- Each potluck has a unique, shareable slug for public access
- Hosts can define slots (appetizers, mains, sides, desserts, drinks, etc.)
- Hosts can choose to allow custom slots, or custom slots after all defined slots are full
- Hosts can designate co-hosts from users they follow
- Hosts can send invitations via email or shareable link
- Events can be marked as open for public signup
- Invitees can claim open slots
- Invitees can link their slot to a recipe in the system or provide custom text
- Invitees can add comments about their dish
- Invitees can specify dietary restrictions/preferences
- Non-registered users can sign up with minimal information (name, email)
- Automatic account creation for non-registered users who sign up for slots
- Event page shows all slots and what's being brought
- Free tier users can host one potluck event and attend unlimited potlucks
- Premium users get unlimited potluck hosting

#### Dependencies
- Requires potluck database schema
- Requires invitation system
- Requires slot management logic
- Requires integration with recipe database
- Requires simplified account creation flow

### 9. Recipe Assistant

#### Feature Description
Provide an AI-powered conversational assistant for recipe help, ingredient substitutions, and recipe creation guidance.

#### User Stories
- As a user, I want to start a conversation with a recipe assistant by uploading a food image so I can learn what I can make with it.
- As a user, I want to ask questions about ingredients and get suggestions for recipes.
- As a user, I want to ask cooking questions and get expert guidance.
- As a user, I want to convert promising chat conversations into formal recipes so I can save and share them.
- As a user, I want to access my conversation history so I can reference past advice.

#### Acceptance Criteria
- Users can initiate a chat with the Recipe Assistant from the main navigation
- Users can upload images of food/ingredients to start conversations
- Assistant can identify ingredients in images and suggest recipes
- Assistant can answer cooking questions with helpful, accurate information
- Users can convert assistant suggestions into formal recipes in their collection
- Conversation history is saved and accessible to users
- Clear indication of AI-generated content
- Assistant maintains context throughout a conversation

#### Dependencies
- Requires integration with conversational AI service
- Requires image recognition capabilities
- Requires conversation history storage
- Requires conversion flow from chat to structured recipe

### 10. Role-Based Access Control

#### Feature Description
Implement user roles to manage permissions and administrative functions.

#### User Stories
- As an admin, I want to manage user roles so I can control access to administrative functions.
- As an admin, I want to moderate user-contributed content so I can maintain quality standards.
- As an admin, I want to be able to reset passwords for users
- As an admin, I want to be able to edit or delete any recipe
- As an admin, I want to be able to add a recipe on behalf of any user
- As an admin, I want to have 'host' abilities for any potluck
- As a regular user, I want to use all standard features without administrative privileges.

#### Acceptance Criteria
- Support for different user roles (admin, user)
- Admins can manage other users' content
- Admins can manage reference data
- Regular users have appropriate permissions for their own content
- Role assignments are securely managed

#### Dependencies
- Requires user roles database schema
- Requires role mappings database schema
- Requires permission checks throughout application

### 11. API Access

#### Feature Description
Provide programmatic access to user's recipe data through secure API keys.

#### User Stories
- As a developer user, I want to create API keys so I can access my recipes programmatically.
- As a developer user, I want to manage my API keys so I can control access to my data.
- As a developer user, I want to track API key usage so I know when my keys are being used.

#### Acceptance Criteria
- Users can generate named API keys
- Users can view their existing API keys
- Users can delete API keys
- API keys are securely stored and transmitted
- API key usage is tracked with timestamps

#### Dependencies
- Requires user API keys database schema
- Requires secure API authentication mechanism
- Requires API access endpoints

### 12. AI-Powered Features

#### Feature Description
Integrate AI technology for recipe extraction, image generation, and enhanced user experience.

#### User Stories
- As a user, I want the app to automatically extract recipe details from various sources so that I save time on manual entry.
- As a user, I want AI-generated images for recipes without photos so that all my recipes have visual representation.
- As a user, I want the app to intelligently categorize my recipes so that organization is effortless.

#### Acceptance Criteria
- AI extraction successfully identifies recipe components from URLs with >90% accuracy
- AI extraction successfully identifies recipe components from text with >85% accuracy
- AI extraction successfully identifies recipe components from images with >80% accuracy
- AI generates relevant, high-quality images based on recipe title and ingredients
- AI suggests appropriate cuisine and course categories based on recipe content
- AI helps identify appropriate dietary tags based on ingredients
- All AI functions provide edit capability before final save

#### Dependencies
- Requires integration with Google Gemini AI or similar services
- Requires sufficient training data for extraction models
- Requires image generation capabilities

## Business Model

### Free Tier
- Create and manage unlimited manual recipes
- Limited to 10 total recipes with AI-enhancement (URL extraction, text extraction, image recognition, generated recipe images)
- Unlimited meal planning functionality
- Unlimited shopping list functionality
- Limited Recipe Assistant usage (10 conversations)
- Host unlimited potluck events, attend unlimited potlucks as guest
- Full social features (likes, favorites, follows)

### Premium Tier ($3/month or $27/year)
- Unlimited AI-enhanced recipes (URL extraction, text extraction, image recognition)
- Unlimited AI-generated recipe images
- Unlimited Recipe Assistant conversations
- Unlimited meal planning functionality
- Unlimited shopping list functionality
- Host unlimited potluck events, attend unlimited potlucks as guest
- Full social features (likes, favorites, follows)

#### Acceptance Criteria
- System tracks AI feature usage for free tier users
- Clear indication of remaining free tier allocations
- Seamless upgrade process to premium
- Appropriate restrictions enforced for free tier users
- Subscription management interface
- Payment processing integration

#### Dependencies
- Requires usage tracking system
- Requires subscription management
- Requires payment processor integration
