# Environment Variables

## .env.example

Store sensitive keys and configuration specific to the deployment environment. Never commit `.env` files directly; use `.env.example` as a template.

## Authentication Redirect URLs

```
NEXT_PUBLIC_SITE_URL=http://localhost:3000 # Change for production (e.g., https://your-app.vercel.app)
NEXT_PUBLIC_AUTH_REDIRECT_URL=http://localhost:3000/auth/callback # Adjust if necessary
```

## Supabase Configuration (usually installed via Vercel-Supabase integration or manually from Supabase dashboard)

```
NEXT_PUBLIC_SUPABASE_URL=YOUR_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=YOUR_SUPABASE_SERVICE_ROLE_KEY # Keep this secret!
```

## Database Connection Strings (provided by Supabase)

```
POSTGRES_URL=YOUR_SUPABASE_DB_CONNECTION_STRING_POOLED
POSTGRES_PRISMA_URL=YOUR_SUPABASE_DB_CONNECTION_STRING_POOLED # Prisma uses the pooled URL
POSTGRES_URL_NON_POOLING=YOUR_SUPABASE_DB_CONNECTION_STRING_NON_POOLED
POSTGRES_USER=postgres
POSTGRES_PASSWORD=YOUR_SUPABASE_DB_PASSWORD
POSTGRES_DATABASE=postgres
POSTGRES_HOST=YOUR_SUPABASE_DB_HOST
```

## Stripe Integration (if applicable)

```
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
NEXT_PUBLIC_STRIPE_PRICE_MONTHLY=price_...
NEXT_PUBLIC_STRIPE_PRICE_YEARLY=price_...
STRIPE_PRODUCT_ID=prod_...
```

## AI Integration (if applicable)

```
OPENAI_API_KEY=sk-...
GEMINI_API_KEY=AIza...
```
