# Setting Up Google Authentication with Supabase in Next.js

Offical documentation: https://supabase.com/docs/guides/auth/social-login/auth-google

## Step 1: Collect Details from Supabase

### Project ID

1. Navigate to your Supabase Dashboard
   - Go to Project Settings
   - Find the Project ID
   - Copy the Project ID and have it available for later

### Callback URL

1. Navigate to your Supabase Dashboard:
   - Go to Authentication > Providers
   - Find and enable Google provider
   - Copy the Callback URL shown there
   - Place this in a note file or have it available, this will be used later

## Step 2: Create and Configure Google Cloud Project

1. Have a Google Cloud account at https://cloud.google.com

2. Create a new project for your app at [Google Cloud Console](https://console.cloud.google.com)

3. Configure the OAuth Consent Screen:
   - Go to "APIs & Services" > "OAuth consent screen"
   - Fill in the required information about your application

4. Configure the Data Access:
   - Click 'Data Access'
   - Click Add or remove scopes
   - Ensure the following non-sensitive scopes are added:
     - `.../auth/userinfo.email`
     - `.../auth/userinfo.profile`
     - `openid`
   - Click 'Save'

3. Create OAuth Client Credentials:
   - Go to "APIs & Services" > "Credentials" 
   - Click "Create Credentials" > "OAuth client ID"
   - Set application type to "Web application"
   - Add Authorized JavaScript origins:
     ```
     https://{YOUR_PROJECT_ID}.supabase.co
     ```
     (Get your Project ID from Supabase Project Settings)

## Step 3: Configure Supabase Authentication

1. Navigate to your Supabase Dashboard:
   - Go to Authentication > Providers
   - Find and enable Google provider
   - Copy the Callback URL shown there

2. Return to Google Cloud Console:
   - Edit your OAuth client
   - Add the Supabase Callback URL to "Authorized redirect URIs"
   - Save your changes

3. Copy your Google OAuth credentials:
   - Note your Client ID and Client Secret

4. In Supabase Authentication settings:
   - Paste your Google Client ID and Client Secret
   - Save the configuration

## Step 4: Continue to Implement Your Next.js Application