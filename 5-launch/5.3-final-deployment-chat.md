# Day 5: Launch 

[⬅️ Day 5 Overview](README.md)

## 5.3 Final Deployment

**Goal**: Deploy your application to Vercel, configure custom domains, environment variables, and production database, and verify everything works correctly.

**Process**: Follow this chat pattern with an AI chat tool such as [Claude.ai](https://www.claude.ai). Pay attention to the notes in `[brackets]` and replace the brackets with your own thoughts and ideas.

**Timeframe**: 60-90 minutes

## Table of Contents
- [5.3.1: Creating/Logging into Vercel](#531-creatinglogging-into-vercel)
- [5.3.2: Connecting Your GitHub Repository](#532-connecting-your-github-repository)
- [5.3.3: Setting Up Your Vercel Project](#533-setting-up-your-vercel-project)
- [5.3.4: Deployment Options](#534-deployment-options)
- [5.3.5: Custom Domain & SSL Configuration](#535-custom-domain--ssl-configuration)
- [5.3.6: Environment Variables Configuration](#536-environment-variables-configuration)
- [5.3.7: Database Configuration for Production](#537-database-configuration-for-production)
- [5.3.8: Vercel Deployment Process](#538-vercel-deployment-process)
- [5.3.9: Production Testing & Verification](#539-production-testing--verification)
- [5.3.10: Deployment Documentation](#5310-deployment-documentation)

### 5.3.1: Creating/Logging into Vercel

```
I need to deploy my Next.js application to Vercel. Please guide me through:

1. Creating a Vercel account or logging in
2. Best practices for connecting my GitHub repository
3. Optimal project configuration settings
```

1. Go to [Vercel](https://vercel.com) and sign up or log in
2. If signing up, you can use GitHub, GitLab, or email authentication

### 5.3.2: Connecting Your GitHub Repository

```
Now that I have a Vercel account, how do I connect my GitHub repository and what permissions should I grant?
```

1. In the Vercel dashboard, click "Add New..." → "Project"
2. Select "Import Git Repository" and authorize Vercel to access your GitHub account
3. Select the repository containing your Next.js application
4. If needed, click "Configure GitHub App" to grant access to specific repositories

### 5.3.3: Setting Up Your Vercel Project

```
What are the optimal build settings for my Next.js project on Vercel? Should I use the default settings or customize them?
```

1. Vercel will automatically detect Next.js and suggest optimal settings
2. Verify the framework preset shows "Next.js"
3. Configure your project name (this will be used in your deployment URL)
4. For build settings, keep the defaults for a standard Next.js project:
   - Build Command: `next build`
   - Output Directory: `.next`
   - Install Command: `npm install` (or `yarn install` if using Yarn)

### 5.3.4: Deployment Options

```
What deployment options should I consider for my project? Which branch should I deploy from, and are there any region-specific considerations?
```

1. Choose your preferred deployment branch (usually "main" or "master")
2. Select your preferred deployment regions if available
3. Click "Deploy" to initiate your first deployment

### 5.3.5: Custom Domain & SSL Configuration

```
I want to set up a custom domain for my application. Please guide me through:

1. Adding a custom domain to my Vercel project
2. Setting up the necessary DNS records
3. Verifying domain ownership
4. Ensuring SSL certificates are properly configured
5. Verifying the domain is working correctly
```

#### Adding Your Custom Domain
1. From the Vercel dashboard, select your project
2. Navigate to "Settings" → "Domains"
3. Click "Add" and enter your domain name
4. Choose the domain configuration type (usually "Primary Domain")

#### Setting Up DNS Records
1. Vercel will provide the necessary DNS records to configure
2. Log in to your domain registrar (GoDaddy, Namecheap, etc.)
3. Find the DNS management section
4. Add the records Vercel suggests:
   - For apex domains (example.com): Add an A record pointing to Vercel's IP
   - For subdomains (www.example.com): Add a CNAME record pointing to Vercel

#### Verifying Domain Ownership
1. Return to Vercel and click "Verify" next to your domain
2. Vercel will check if the DNS records are properly configured
3. If verification fails, wait for DNS propagation (can take up to 48 hours) and try again

#### SSL Certificate Setup
1. Vercel automatically provisions SSL certificates for verified domains
2. No manual action is required for SSL configuration
3. Your certificate will automatically renew before expiration

#### Verification
1. Once DNS propagation is complete, visit your domain to verify it's working
2. Check that HTTPS is working correctly (lock icon in browser)
3. Test on both desktop and mobile devices

### 5.3.6: Environment Variables Configuration

```
I need to configure environment variables for my production deployment. Please advise on:

1. How to add environment variables in Vercel
2. The different types of environment variables
3. Best practices for storing sensitive information
4. Which variables should be configured for production
5. How to verify my environment variables are working correctly
```

#### Adding Environment Variables
1. In the Vercel dashboard, select your project
2. Navigate to "Settings" → "Environment Variables"
3. Click "Add New" for each variable you need to add
4. Enter the variable name and value
5. Select the appropriate environments (Development, Preview, Production)

#### Environment Variable Types
1. **Production**: Used in your production deployment
2. **Preview**: Used in preview deployments (PR review environments)
3. **Development**: Used in local development with Vercel CLI

#### Secure Storage of Sensitive Information
1. All environment variables in Vercel are encrypted at rest
2. Never commit sensitive environment variables to your repository
3. Use Vercel's environment variable UI for all sensitive values
4. Consider using Vercel's integration with secret management tools for team environments

#### Recommended Variables to Configure
1. API keys for all third-party services
2. Database connection strings
3. Authentication secrets (JWT tokens, cookie secrets)
4. Payment processing keys (Stripe, etc.)
5. Feature flags for production environment

#### Verification
1. After deployment, verify your environment variables are working correctly
2. Check functionalities that depend on environment variables
3. Monitor logs for any environment variable-related errors

### 5.3.7: Database Configuration for Production

```
I need to configure my database for production use with Vercel. Please provide guidance on:

1. Connecting to a production database
2. Security best practices for database configuration
3. Handling database migrations in production
4. Setting up monitoring and maintenance procedures
```

#### Connecting to Your Production Database
1. Ensure your database service is configured for production use
2. Set up appropriate firewalls to only allow connections from Vercel's IP ranges
3. Create a dedicated production database user with appropriate permissions
4. Configure your connection string as an environment variable in Vercel

#### Security Best Practices
1. Enable SSL/TLS for database connections
2. Use connection pooling appropriate for serverless environments
3. Set appropriate connection limits
4. Enable database encryption at rest if available
5. Regularly backup your production database

#### Database Migrations
1. Configure your migration strategy for production deployments
2. Consider using database migration tools compatible with Vercel
3. Test migrations in a staging environment before applying to production
4. Have a rollback plan for failed migrations

#### Monitoring and Maintenance
1. Set up database monitoring tools
2. Configure alerts for database performance issues
3. Establish a regular backup schedule
4. Document database schema and relationships

### 5.3.8: Vercel Deployment Process

```
I'm ready to deploy my application to production. Please walk me through:

1. Pre-deployment checklist to ensure everything is ready
2. The actual deployment process
3. Post-deployment verification steps
4. Monitoring my deployment for issues
```

#### Pre-Deployment Checklist
1. Run all tests locally to ensure code quality
2. Verify all environment variables are configured
3. Test your application with production-like environment variables
4. Check your build output locally using `next build`
5. Review your Git repository for any sensitive information

#### Deployment Process
1. Commit and push your final changes to your deployment branch
2. Vercel will automatically start building your application
3. Monitor the build process in the Vercel dashboard
4. If the build fails, review the logs to identify and fix issues

#### Post-Deployment Verification
1. Test critical user flows on the deployed application
2. Verify all API endpoints are functioning correctly
3. Check that database connections are working
4. Test authentication and authorization
5. Verify payment processing (if applicable)
6. Test on multiple devices and browsers

#### Monitoring Your Deployment
1. Review the deployment details in Vercel dashboard
2. Check the deployment logs for any warnings or errors
3. Monitor application performance using Vercel Analytics
4. Set up alerts for critical errors or performance issues

### 5.3.9: Production Testing & Verification

```
Now that my application is deployed, what should I test to ensure everything is working correctly in production? Please provide a comprehensive testing plan.
```

#### Critical User Flows to Test
1. User registration and login
2. Core application functionality
3. Payment processing and subscription management
4. Account settings and profile management
5. Any data import/export features

#### Cross-Browser and Device Testing
1. Test on Chrome, Firefox, Safari, and Edge
2. Verify mobile responsiveness on iOS and Android devices
3. Check tablet displays and orientation changes
4. Verify desktop experience at different screen resolutions

#### Performance Testing
1. Run Lighthouse tests on key pages
2. Check Core Web Vitals in Vercel Analytics
3. Verify API response times under load
4. Test database query performance with real data

#### Security Verification
1. Verify SSL is properly configured
2. Check authentication security
3. Test authorization rules for different user types
4. Verify API endpoints are properly secured
5. Test for common security vulnerabilities

### 5.3.10: Deployment Documentation

```
I need to create comprehensive deployment documentation for my team. What should this documentation include to ensure smooth operations and maintenance?
```

Create a comprehensive document containing:

#### Vercel Configuration
1. Project name and ID
2. Deployment branch and settings
3. Build and development settings
4. Team access (if applicable)

#### Environment Variables
1. List of all environment variables (excluding actual values of secrets)
2. Purpose of each variable
3. Which services depend on each variable

#### Domain Configuration
1. Domain names and DNS records
2. SSL certificate details
3. Custom domain settings

#### Database Configuration
1. Database type and version
2. Connection details (excluding passwords)
3. Migration process
4. Backup procedures

#### Monitoring Setup
1. Analytics configuration
2. Error tracking tools
3. Performance monitoring
4. Alerting configuration

#### Troubleshooting Guide
1. Common deployment issues and solutions
2. How to roll back to previous deployments
3. Contact information for support
4. Emergency procedures for critical issues 