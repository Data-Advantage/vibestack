# Stripe Integration Guide for Next.js/Supabase Applications

This guide walks through setting up Stripe with your Supabase + Next.js application to handle subscriptions for your SaaS app.

## 1. Create Stripe Products & Prices

1. Log into your [Stripe Dashboard](https://dashboard.stripe.com)
2. Go to Products > Add Product
3. Create one product with two pricing options:
   - **Monthly Subscription**: Set your monthly price
   - **Annual Subscription**: Set your yearly price (consider offering a discount)
4. For each pricing option, make sure to:
   - Add clear descriptions
   - Set the recurring price (monthly or yearly)
   - Note the Product ID and Price IDs for later use in your app

## 2. Test Mode vs Live Mode in Stripe

Stripe provides two separate environments:

- **Test Mode**: For development and testing without real transactions
- **Live Mode**: For production use with real payments

### Managing Test vs Live Mode:

1. **Toggle Environment**: Use the "Test Mode" toggle in the Stripe Dashboard to switch between environments
2. **Separate API Keys**: Stripe provides different API keys for each environment:
   - Test keys start with `pk_test_` and `sk_test_`
   - Live keys start with `pk_live_` and `sk_live_`

3. **Environment Variables**:
```
# Test environment
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_abc123...
STRIPE_SECRET_KEY=sk_test_abc123...
STRIPE_WEBHOOK_SECRET=whsec_test_abc123...

# Production environment
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_abc123...
STRIPE_SECRET_KEY=sk_live_abc123...
STRIPE_WEBHOOK_SECRET=whsec_live_abc123...
```

4. **Deployment-Specific Configuration**: 
   - Development/Preview: Use test keys for `https://{randomid}.lite.vusercontent.net`
   - Production: Use live keys for `https://{appname}.vercel.app`

## 3. Stripe Webhook Setup

### Create Webhook Endpoints

1. Go to Developers > Webhooks in Stripe Dashboard
2. Create webhook endpoints for each environment:
   - Local development: `http://localhost:3000/api/webhooks/stripe`
   - Preview deployments: `https://{randomid}.lite.vusercontent.net/api/webhooks/stripe`
   - Production: `https://{appname}.vercel.app/api/webhooks/stripe`

3. For each endpoint, select these events:
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `customer.updated`
   - `invoice.paid`
   - `invoice.payment_failed`
   - `product.created`
   - `product.updated`
   - `price.created`
   - `price.updated`

4. Copy the Webhook Signing Secret for each environment

### NextJS Webhook Implementation

Create a webhook handler at `app/api/webhooks/stripe/route.ts`:

```typescript
import { NextRequest, NextResponse } from 'next/server';
import Stripe from 'stripe';
import { createAdminClient } from '@/lib/supabase/admin';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);
const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET!;

// Relevant events to process
const relevantEvents = new Set([
  'customer.subscription.created',
  'customer.subscription.updated',
  'customer.subscription.deleted',
  'customer.updated',
  'invoice.paid',
  'invoice.payment_failed',
  'product.created',
  'product.updated',
  'price.created',
  'price.updated',
]);

// Your app's product IDs (to filter out irrelevant product events)
const appProductIds = [process.env.STRIPE_PRODUCT_ID!];

export async function POST(req: NextRequest) {
  const body = await req.text();
  const signature = req.headers.get('stripe-signature') as string;

  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      webhookSecret
    );
  } catch (error: any) {
    console.log(`Webhook signature verification failed: ${error.message}`);
    return NextResponse.json(
      { error: `Webhook signature verification failed` },
      { status: 400 }
    );
  }

  // Filter to only handle events for your app's products
  if (
    (event.type === 'product.created' || 
     event.type === 'product.updated') && 
    !appProductIds.includes((event.data.object as Stripe.Product).id)
  ) {
    return NextResponse.json({ received: true, relevant: false });
  }

  if (
    (event.type === 'price.created' || 
     event.type === 'price.updated') && 
    !appProductIds.includes((event.data.object as Stripe.Price).product as string)
  ) {
    return NextResponse.json({ received: true, relevant: false });
  }

  // Check if we need to process this event
  if (relevantEvents.has(event.type)) {
    try {
      const supabase = createAdminClient();
      
      // Store the event in Supabase for processing
      const { error } = await supabase
        .from('stripe.webhook_events')
        .insert({
          stripe_event_id: event.id,
          event_type: event.type,
          event_data: event.data,
          processed: false
        });
      
      if (error) throw error;
      
      console.log(`✅ Webhook event ${event.id} stored for processing`);
    } catch (error: any) {
      console.log(`❌ Error storing webhook event: ${error.message}`);
      return NextResponse.json(
        { error: 'Error storing webhook event' },
        { status: 500 }
      );
    }
  }

  // Return a 200 response to acknowledge receipt of the event
  return NextResponse.json({ received: true });
}
```

## 4. Customer Portal Integration

The Stripe Customer Portal allows users to manage their subscriptions without you needing to build custom UI:

1. **Configure Customer Portal in Stripe Dashboard**:
   - Go to Settings > Customer Portal
   - Set branding, allowed actions, and return URL

2. **Create an API endpoint to generate portal sessions**:

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@/lib/supabase/server';
import { cookies } from 'next/headers';
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

export async function POST(req: NextRequest) {
  const cookieStore = cookies();
  const supabase = createServerClient(cookieStore);
  
  // Check user authentication
  const { data: { session } } = await supabase.auth.getSession();
  
  if (!session) {
    return NextResponse.json(
      { error: 'Unauthorized' },
      { status: 401 }
    );
  }
  
  try {
    // Get the user's Stripe customer ID
    const { data: userSubscription } = await supabase
      .from('user_subscription_details')
      .select('stripe_customer_id')
      .eq('user_id', session.user.id)
      .single();
    
    if (!userSubscription?.stripe_customer_id) {
      return NextResponse.json(
        { error: 'No subscription found' },
        { status: 404 }
      );
    }
    
    // Create a portal session
    const portalSession = await stripe.billingPortal.sessions.create({
      customer: userSubscription.stripe_customer_id,
      return_url: `${process.env.NEXT_PUBLIC_APP_URL}/dashboard/account`,
    });
    
    // Return the URL to the client
    return NextResponse.json({ url: portalSession.url });
  } catch (error: any) {
    console.error('Error creating portal session:', error);
    return NextResponse.json(
      { error: 'Failed to create portal session' },
      { status: 500 }
    );
  }
}
```

3. **Create a component to handle subscription management**:

```tsx
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';

export default function ManageSubscriptionButton() {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(false);

  const handleManageSubscription = async () => {
    setIsLoading(true);

    try {
      const response = await fetch('/api/stripe/portal', {
        method: 'POST',
      });
      
      if (!response.ok) {
        throw new Error('Failed to create portal session');
      }
      
      const { url } = await response.json();
      router.push(url);
    } catch (error) {
      console.error('Error opening Stripe portal:', error);
      alert('Failed to open subscription management portal');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Button
      onClick={handleManageSubscription}
      disabled={isLoading}
      variant="outline"
    >
      {isLoading ? 'Loading...' : 'Manage Subscription'}
    </Button>
  );
}
```

## 5. Checkout Sessions for New Subscriptions

Create an API endpoint to initiate the checkout process:

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@/lib/supabase/server';
import { cookies } from 'next/headers';
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

export async function POST(req: NextRequest) {
  const cookieStore = cookies();
  const supabase = createServerClient(cookieStore);
  
  // Check user authentication
  const { data: { session } } = await supabase.auth.getSession();
  
  if (!session) {
    return NextResponse.json(
      { error: 'Unauthorized' },
      { status: 401 }
    );
  }
  
  // Get request body
  const { priceId, planType } = await req.json();
  
  try {
    // Check if user already has a Stripe customer ID
    const { data: profile } = await supabase
      .from('profiles')
      .select('*')
      .eq('user_id', session.user.id)
      .single();
    
    // Get or create customer in Stripe
    let customerId;
    const { data: customer } = await supabase
      .from('stripe_customers')
      .select('stripe_customer_id')
      .eq('user_id', session.user.id)
      .single();
    
    if (customer?.stripe_customer_id) {
      customerId = customer.stripe_customer_id;
    } else {
      // Create a new customer in Stripe
      const stripeCustomer = await stripe.customers.create({
        email: session.user.email,
        name: profile?.full_name || session.user.email,
        metadata: {
          user_id: session.user.id
        }
      });
      
      customerId = stripeCustomer.id;
      
      // Store the customer ID in Supabase
      await supabase
        .from('stripe_customers')
        .insert({
          user_id: session.user.id,
          stripe_customer_id: customerId
        });
    }
    
    // Get app URL based on environment
    const appUrl = process.env.NEXT_PUBLIC_APP_URL || 
      (process.env.VERCEL_ENV === 'production' 
        ? `https://${process.env.VERCEL_URL}` 
        : `https://${process.env.VERCEL_URL}.lite.vusercontent.net`);
    
    // Create checkout session
    const checkoutSession = await stripe.checkout.sessions.create({
      customer: customerId,
      line_items: [
        {
          price: priceId,
          quantity: 1,
        },
      ],
      mode: 'subscription',
      success_url: `${appUrl}/dashboard/account?success=true&plan=${planType}`,
      cancel_url: `${appUrl}/pricing?canceled=true`,
      allow_promotion_codes: true,
      metadata: {
        user_id: session.user.id,
        plan_type: planType
      }
    });
    
    return NextResponse.json({ url: checkoutSession.url });
  } catch (error: any) {
    console.error('Error creating checkout session:', error);
    return NextResponse.json(
      { error: 'Failed to create checkout session' },
      { status: 500 }
    );
  }
}
```

## 6. Supabase Database Functions

Create a function to sync Stripe subscription data to your app:

```sql
CREATE OR REPLACE FUNCTION stripe.sync_subscription_to_app()
RETURNS TRIGGER AS $$
DECLARE
  subscription_tier text;
  subscription_status text;
BEGIN
  -- Convert Stripe subscription status to app status
  CASE NEW.status
    WHEN 'active' THEN subscription_status := 'active';
    WHEN 'trialing' THEN subscription_status := 'active';
    WHEN 'past_due' THEN subscription_status := 'past_due';
    WHEN 'canceled' THEN subscription_status := 'canceled';
    WHEN 'unpaid' THEN subscription_status := 'past_due';
    WHEN 'incomplete' THEN subscription_status := 'incomplete';
    WHEN 'incomplete_expired' THEN subscription_status := 'incomplete_expired';
    ELSE subscription_status := 'inactive';
  END CASE;
  
  -- Set subscription tier based on product
  IF NEW.product_id = (SELECT product_id FROM stripe.products WHERE is_default = true LIMIT 1) THEN
    subscription_tier := 'pro';
  ELSE
    subscription_tier := 'free';
  END IF;
  
  -- Update/insert user subscription
  INSERT INTO user_subscriptions (
    user_id,
    stripe_subscription_id,
    subscription_tier,
    status,
    current_period_start,
    current_period_end,
    cancel_at_period_end
  )
  VALUES (
    NEW.user_id,
    NEW.stripe_subscription_id,
    subscription_tier,
    subscription_status,
    to_timestamp(NEW.current_period_start),
    to_timestamp(NEW.current_period_end),
    NEW.cancel_at_period_end
  )
  ON CONFLICT (user_id) 
  DO UPDATE SET
    stripe_subscription_id = EXCLUDED.stripe_subscription_id,
    subscription_tier = EXCLUDED.subscription_tier,
    status = EXCLUDED.status,
    current_period_start = EXCLUDED.current_period_start,
    current_period_end = EXCLUDED.current_period_end,
    cancel_at_period_end = EXCLUDED.cancel_at_period_end,
    updated_at = now();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for subscription changes
CREATE TRIGGER on_stripe_subscription_change
AFTER INSERT OR UPDATE ON stripe.subscriptions
FOR EACH ROW EXECUTE FUNCTION stripe.sync_subscription_to_app();
```

## 7. Managing Subscriptions on Front End

Create a component to handle subscription checkout:

```tsx
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';

type SubscribeButtonProps = {
  priceId: string;
  planType: 'monthly' | 'yearly';
  variant?: 'default' | 'outline' | 'secondary';
  text?: string;
};

export default function SubscribeButton({ 
  priceId, 
  planType, 
  variant = 'default',
  text = 'Subscribe'
}: SubscribeButtonProps) {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(false);

  const handleSubscribe = async () => {
    setIsLoading(true);

    try {
      const response = await fetch('/api/stripe/checkout', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          priceId,
          planType,
        }),
      });
      
      if (!response.ok) {
        throw new Error('Failed to create checkout session');
      }
      
      const { url } = await response.json();
      router.push(url);
    } catch (error) {
      console.error('Error creating checkout session:', error);
      alert('Failed to start subscription process');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Button
      onClick={handleSubscribe}
      disabled={isLoading}
      variant={variant}
    >
      {isLoading ? 'Loading...' : text}
    </Button>
  );
}
```

## 8. Tracking Specific Products in Webhooks

To ensure your webhook only processes events for your specific product:

1. **Store Your Product ID in Environment Variables**:
```
STRIPE_PRODUCT_ID=prod_abc123
```

2. **Update the Webhook Handler to Filter by Product ID**:
See the webhook implementation above, which includes product filtering.

## 9. Handling Development vs Production Environment

To manage different webhook URLs between environments:

1. **For Local Development**:
   - Use [Stripe CLI](https://stripe.com/docs/stripe-cli) to forward webhooks:
   ```bash
   stripe listen --forward-to localhost:3000/api/webhooks/stripe
   ```

2. **For Preview/Test Deployments**:
   - Create a separate webhook endpoint in Stripe dashboard pointing to:
   ```
   https://{randomid}.lite.vusercontent.net/api/webhooks/stripe
   ```

3. **For Production**:
   - Create a production webhook endpoint in Stripe pointing to:
   ```
   https://{appname}.vercel.app/api/webhooks/stripe
   ```

## 10. Additional Considerations and Best Practices

1. **Error Handling and Retry Logic**:
   - Implement retry logic for failed webhook processing
   - Set up monitoring and alerts for critical subscription events

2. **Security**:
   - Always verify webhook signatures
   - Store API keys securely in environment variables
   - Use strong CORS policies on API endpoints
   - Implement rate limiting on API endpoints

3. **Database Structure**:
   - Keep Stripe data in a separate schema (e.g., `stripe`)
   - Maintain proper relations between app users and Stripe customers
   - Use views to simplify access to subscription details

4. **Testing**:
   - Test all subscription flows in Stripe Test Mode before going live
   - Create test customers and subscriptions in Test Mode
   - Validate webhook handling for all important events

5. **Monitoring and Troubleshooting**:
   - Store all webhook events for auditing purposes
   - Implement logging for key subscription operations
   - Set up alerts for subscription failures

6. **User Experience**:
   - Provide clear feedback during the subscription process
   - Handle subscription failures gracefully
   - Automatically redirect users to appropriate areas after subscription changes

7. **Compliance**:
   - Ensure proper storage and handling of payment information
   - Maintain records of subscription events for accounting purposes
   - Provide clear terms of service and privacy policy

By following this guide, you'll have a robust Stripe integration for your Next.js and Supabase application, with proper handling of environments, product filtering, and user subscription management. 