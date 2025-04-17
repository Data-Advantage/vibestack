# Stripe Customer Portal

The Stripe Customer Portal is a pre-built, hosted page that lets your customers manage their subscriptions and billing information. This document covers how to integrate and customize the Stripe Customer Portal in your VibeStack application.

## Overview

The Stripe Customer Portal enables your customers to:
- View their subscription status
- Upgrade or downgrade subscription plans
- Update payment methods
- View billing history and download invoices
- Update billing information
- Cancel subscriptions

## Integration with VibeStack

### Prerequisites

1. A Stripe account with API access
2. Stripe Customer Portal enabled in your Stripe Dashboard
3. Configured products and prices in Stripe

### Environment Setup

Add these environment variables to your project:

```bash
# .env.local
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
```

### Installation

Install the required packages:

```bash
npm install @stripe/stripe-js stripe
```

### Backend Configuration

Create a server-side utility for Stripe interactions:

```typescript
// lib/stripe.ts
import Stripe from 'stripe';

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY as string, {
  apiVersion: '2023-10-16', // Use the latest API version
  appInfo: {
    name: 'VibeStack',
    version: '1.0.0',
  },
});
```

### Creating a Customer Portal Session

Create an API endpoint to generate a Customer Portal session:

```typescript
// pages/api/create-customer-portal-session.ts
import type { NextApiRequest, NextApiResponse } from 'next';
import { getServerSession } from 'next-auth/next';
import { authOptions } from './auth/[...nextauth]';
import { stripe } from '@/lib/stripe';
import { supabase } from '@/lib/supabase';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Get the session and verify the user is authenticated
    const session = await getServerSession(req, res, authOptions);
    
    if (!session?.user) {
      return res.status(401).json({ error: 'Not authenticated' });
    }
    
    const userId = session.user.id;
    
    // Get the user's Stripe customer ID from your database
    const { data: userData, error } = await supabase
      .from('users')
      .select('stripe_customer_id')
      .eq('id', userId)
      .single();
      
    if (error || !userData?.stripe_customer_id) {
      return res.status(400).json({ 
        error: 'No Stripe customer found for this user' 
      });
    }
    
    // Create a customer portal session
    const stripeSession = await stripe.billingPortal.sessions.create({
      customer: userData.stripe_customer_id,
      return_url: `${req.headers.origin}/account`,
    });
    
    // Return the URL to redirect the user to
    res.status(200).json({ url: stripeSession.url });
  } catch (error) {
    console.error('Error creating portal session:', error);
    res.status(500).json({ error: 'Failed to create customer portal session' });
  }
}
```

### Frontend Integration

Create a button to redirect users to the Customer Portal:

```tsx
// components/ManageSubscriptionButton.tsx
import { useState } from 'react';
import { useRouter } from 'next/router';
import { Button } from './ui/button';

export default function ManageSubscriptionButton() {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(false);

  const handlePortalAccess = async () => {
    setIsLoading(true);
    
    try {
      const response = await fetch('/api/create-customer-portal-session', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
      });
      
      const { url, error } = await response.json();
      
      if (error) throw new Error(error);
      
      // Redirect to the Stripe Customer Portal
      router.push(url);
    } catch (error) {
      console.error('Error accessing customer portal:', error);
      // Handle error (show toast, etc.)
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Button 
      onClick={handlePortalAccess} 
      disabled={isLoading}
      variant="outline"
    >
      {isLoading ? 'Loading...' : 'Manage Subscription'}
    </Button>
  );
}
```

Use this button in your account page:

```tsx
// pages/account.tsx
import { useSession } from 'next-auth/react';
import ManageSubscriptionButton from '@/components/ManageSubscriptionButton';

export default function AccountPage() {
  const { data: session } = useSession();
  
  if (!session) {
    return <div>Please sign in to access this page.</div>;
  }
  
  return (
    <div className="container mx-auto py-10">
      <h1 className="text-2xl font-bold mb-6">Account Settings</h1>
      
      <section className="bg-white p-6 rounded-lg shadow-sm">
        <h2 className="text-xl font-semibold mb-4">Subscription</h2>
        <p className="mb-4">Manage your subscription and billing details.</p>
        <ManageSubscriptionButton />
      </section>
      
      {/* Other account sections */}
    </div>
  );
}
```

## Customizing the Customer Portal

Stripe allows you to customize the Customer Portal through the Stripe Dashboard.

### Branding

Configure these elements to match your brand:
- Logo
- Brand color
- Icon
- Product name

### Features and Functionality

You can enable or disable these features:
- **Subscription management**: Allow users to switch plans
- **Payment method updates**: Allow users to add/update payment methods
- **Billing history**: Enable viewing and downloading of invoices
- **Customer update**: Allow customers to update billing information
- **Cancellation options**: Configure cancellation flow and reasons

Example portal configuration:

```typescript
// Example of setting up portal configuration (run once during setup)
async function configureCustomerPortal() {
  const configuration = await stripe.billingPortal.configurations.create({
    business_profile: {
      headline: 'VibeStack Subscription Management',
      privacy_policy_url: 'https://yourvibestackapp.com/privacy',
      terms_of_service_url: 'https://yourvibestackapp.com/terms',
    },
    features: {
      subscription_update: {
        enabled: true,
        products: ['prod_ABC123', 'prod_DEF456'],
        proration_behavior: 'create_prorations',
      },
      subscription_cancel: {
        enabled: true,
        mode: 'at_period_end',
        cancellation_reason: {
          enabled: true,
          options: [
            'too_expensive',
            'missing_features',
            'switched_service',
            'unused',
            'other',
          ],
        },
      },
      customer_update: {
        enabled: true,
        allowed_updates: ['email', 'address', 'phone', 'name'],
      },
      invoice_history: { enabled: true },
      payment_method_update: { enabled: true },
    },
    default_return_url: 'https://yourvibestackapp.com/account',
  });
  
  console.log('Portal configuration created:', configuration.id);
  return configuration;
}
```

## Handling Portal Events with Webhooks

Set up webhooks to respond to Customer Portal events:

```typescript
// pages/api/webhooks/stripe.ts
import { NextApiRequest, NextApiResponse } from 'next';
import { buffer } from 'micro';
import Stripe from 'stripe';
import { stripe } from '@/lib/stripe';
import { supabase } from '@/lib/supabase';

// Disable body parser for this route
export const config = {
  api: {
    bodyParser: false,
  },
};

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }
  
  const signature = req.headers['stripe-signature'] as string;
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET as string;
  const buf = await buffer(req);
  
  let event: Stripe.Event;
  
  try {
    event = stripe.webhooks.constructEvent(
      buf.toString(),
      signature,
      webhookSecret
    );
  } catch (error: any) {
    console.error(`Webhook signature verification failed: ${error.message}`);
    return res.status(400).json({ error: error.message });
  }
  
  // Handle specific events
  switch (event.type) {
    case 'customer.subscription.updated':
      await handleSubscriptionUpdated(event.data.object as Stripe.Subscription);
      break;
    case 'customer.subscription.deleted':
      await handleSubscriptionDeleted(event.data.object as Stripe.Subscription);
      break;
    // Add other events as needed
  }
  
  res.status(200).json({ received: true });
}

async function handleSubscriptionUpdated(subscription: Stripe.Subscription) {
  // Get customer ID
  const { customer } = subscription;
  
  // Update subscription status in your database
  const { error } = await supabase
    .from('users')
    .update({ 
      subscription_status: subscription.status,
      price_id: subscription.items.data[0].price.id,
      subscription_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
    })
    .eq('stripe_customer_id', customer);
    
  if (error) {
    console.error('Error updating subscription:', error);
  }
}

async function handleSubscriptionDeleted(subscription: Stripe.Subscription) {
  const { customer } = subscription;
  
  // Update user record to reflect canceled subscription
  const { error } = await supabase
    .from('users')
    .update({ 
      subscription_status: 'canceled',
      price_id: null,
      subscription_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
    })
    .eq('stripe_customer_id', customer);
    
  if (error) {
    console.error('Error updating subscription cancellation:', error);
  }
}
```

## Database Schema

Suggested schema for tracking Stripe customers and subscriptions:

```sql
-- Example schema for users table with Stripe customer fields
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  -- other user fields
  
  -- Stripe-related fields
  stripe_customer_id TEXT,
  subscription_status TEXT,
  price_id TEXT,
  subscription_period_end TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create an index for the stripe_customer_id for faster lookups
CREATE INDEX idx_users_stripe_customer_id ON users(stripe_customer_id);
```

## Testing

### Test Mode

Always use Stripe test mode (`sk_test_`) keys for development and testing.

### Test Cards

Use these test card numbers for testing:
- **Success**: 4242 4242 4242 4242
- **3D Secure**: 4000 0000 0000 3220
- **Decline**: 4000 0000 0000 0002
- **Insufficient Funds**: 4000 0000 0000 9995

### Testing Webhooks Locally

Use the Stripe CLI to forward webhooks to your local environment:

```bash
# Install Stripe CLI (if not already installed)
# https://stripe.com/docs/stripe-cli

# Login to Stripe
stripe login

# Listen for webhooks and forward to your local server
stripe listen --forward-to http://localhost:3000/api/webhooks/stripe
```

## Best Practices

1. **Security**:
   - Never log full payment details
   - Validate webhook signatures
   - Use HTTPS for all communications

2. **Error Handling**:
   - Implement proper error handling for API calls
   - Log errors for debugging
   - Show user-friendly error messages

3. **User Experience**:
   - Clearly explain subscription terms
   - Show confirmation before major actions
   - Provide clear feedback on success/failure

4. **Compliance**:
   - Ensure your terms of service are clear
   - Follow tax regulations for your markets
   - Adhere to card network rules

## Troubleshooting

### Common Issues

1. **Webhook Failures**:
   - Check webhook signature
   - Verify correct endpoint URL
   - Confirm webhook secret is correct

2. **Customer Portal Access Issues**:
   - Verify the customer ID exists in Stripe
   - Check that the customer has an active subscription
   - Confirm API keys are correctly set

3. **Subscription Not Updating**:
   - Check webhook events are being received
   - Verify database updates are working
   - Confirm webhook handlers are processing events

## Resources

- [Stripe Customer Portal Documentation](https://stripe.com/docs/billing/subscriptions/customer-portal)
- [Stripe API Reference](https://stripe.com/docs/api)
- [Stripe Webhooks Guide](https://stripe.com/docs/webhooks)
- [Stripe Testing Guide](https://stripe.com/docs/testing)
- [Stripe Elements for Custom Payment Forms](https://stripe.com/docs/payments/elements)
