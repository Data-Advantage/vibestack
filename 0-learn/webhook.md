# Webhooks

Webhooks are user-defined HTTP callbacks that are triggered by specific events in a source system and sent to a destination URL. In VibeStack applications, webhooks provide a powerful way to integrate with external services and build event-driven architectures.

## Introduction to Webhooks

At their core, webhooks implement a simple concept:

1. A **source system** monitors for specific events (e.g., payment processed, form submitted)
2. When an event occurs, the source system sends an HTTP request to a pre-configured URL
3. The **destination system** receives the request, processes the data, and typically returns a 2xx response
4. The communication is asynchronous and initiated by the source system

Webhooks enable real-time integration, eliminate polling, and support a decoupled architecture.

## Common Webhook Use Cases in VibeStack

| Source | Event | Webhook Purpose |
|--------|-------|-----------------|
| Stripe | `payment.succeeded` | Update subscription status in database |
| Supabase | Record created/updated | Trigger external workflows |
| GitHub | `push`, `pull_request` | Trigger CI/CD pipeline |
| Form submission | Form completion | Process lead data, send confirmation email |
| Email service | Email opened/clicked | Update user engagement metrics |
| Calendar service | Appointment booked | Notify team, update availability |

## Receiving Webhooks in Next.js

### Basic Webhook Endpoint

Create a route handler in Next.js to receive webhook requests:

```typescript
// app/api/webhooks/stripe/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { headers } from 'next/headers';
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);
const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET!;

export async function POST(req: NextRequest) {
  const body = await req.text();
  const signature = headers().get('stripe-signature') || '';

  try {
    // Verify webhook signature
    const event = stripe.webhooks.constructEvent(body, signature, webhookSecret);

    // Handle the event
    switch (event.type) {
      case 'payment_intent.succeeded':
        const paymentIntent = event.data.object as Stripe.PaymentIntent;
        await handleSuccessfulPayment(paymentIntent);
        break;
      case 'customer.subscription.updated':
        const subscription = event.data.object as Stripe.Subscription;
        await handleSubscriptionUpdate(subscription);
        break;
      // Handle other event types
      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    // Return a 200 response to acknowledge receipt of the event
    return new NextResponse(JSON.stringify({ received: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (err: any) {
    console.error(`Webhook error: ${err.message}`);
    return new NextResponse(JSON.stringify({ error: err.message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

async function handleSuccessfulPayment(paymentIntent: Stripe.PaymentIntent) {
  // Implementation for handling successful payment
  console.log(`Processing payment: ${paymentIntent.id}`);
  // Update database, send confirmation emails, etc.
}

async function handleSubscriptionUpdate(subscription: Stripe.Subscription) {
  // Implementation for handling subscription updates
  console.log(`Subscription updated: ${subscription.id}`);
  // Update user subscription status in database
}
```

### Webhook Security

To secure your webhook endpoints:

1. **Verify signatures**: Most webhook providers include a signature header
2. **Use HTTPS**: Always use HTTPS for webhook endpoints
3. **Keep secrets secure**: Store webhook secrets in environment variables
4. **Implement idempotency**: Process webhooks idempotently to handle duplicates
5. **IP filtering**: Optionally restrict to known IP ranges of the webhook provider

## Supabase Webhook Integration

Supabase provides built-in webhook functionality through Database Webhooks:

### Setting Up a Supabase Database Webhook

```sql
-- Create a webhook when a new user profile is created
create or replace function public.handle_new_user()
returns trigger as $$
begin
  perform net.http_post(
    'https://your-vibestack-app.vercel.app/api/webhooks/new-user',
    json_build_object('user_id', new.id, 'created_at', new.created_at)::text,
    'application/json'
  );
  return new;
end;
$$ language plpgsql security definer;

-- Create trigger on insert to profiles table
create trigger on_user_created
  after insert on public.profiles
  for each row execute procedure public.handle_new_user();
```

### Receiving Supabase Webhooks

```typescript
// app/api/webhooks/new-user/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { headers } from 'next/headers';

// Note: Prefer server component or client for Supabase connection
// This is just an example of webhook handling
const supabaseAdmin = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

export async function POST(req: NextRequest) {
  // Get the webhookKey from environment variables
  const webhookKey = process.env.WEBHOOK_KEY;
  
  // Get the authorization header
  const authHeader = headers().get('authorization');
  
  // Verify the webhook key
  if (authHeader !== `Bearer ${webhookKey}`) {
    return new NextResponse(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' }
    });
  }
  
  try {
    const payload = await req.json();
    const { user_id, created_at } = payload;
    
    // Process the new user
    // e.g., send welcome email, set up default data, etc.
    await setupNewUserDefaults(user_id);
    
    return new NextResponse(JSON.stringify({ received: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error: any) {
    console.error('Error processing new user webhook:', error);
    return new NextResponse(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

async function setupNewUserDefaults(userId: string) {
  // Example: Add default items for the new user
  await supabaseAdmin
    .from('user_settings')
    .insert({
      user_id: userId,
      theme: 'light',
      notifications_enabled: true
    });
  
  // Additional setup as needed
}
```

## Sending Webhooks from Your VibeStack App

Your application can also be a webhook provider:

```typescript
// lib/webhooks.ts
import crypto from 'crypto';

interface WebhookPayload {
  event: string;
  data: any;
  timestamp: number;
}

export async function sendWebhook(
  url: string,
  event: string,
  data: any,
  secret: string
) {
  // Create the payload
  const payload: WebhookPayload = {
    event,
    data,
    timestamp: Date.now()
  };
  
  // Create the signature
  const signature = crypto
    .createHmac('sha256', secret)
    .update(JSON.stringify(payload))
    .digest('hex');
  
  // Send the webhook
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Webhook-Signature': signature
      },
      body: JSON.stringify(payload)
    });
    
    // Check if successful
    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Failed to send webhook: ${error}`);
    }
    
    return {
      success: true,
      statusCode: response.status
    };
  } catch (error) {
    console.error('Error sending webhook:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : String(error)
    };
  }
}
```

## Testing Webhooks

### Local Development

For local testing, you can use tools like:

1. **ngrok**: Exposes your local server to the internet
   ```bash
   # Install ngrok
   npm install -g ngrok
   
   # Start your Next.js app
   npm run dev
   
   # Create a tunnel to your local server
   ngrok http 3000
   ```

2. **Webhook simulators**: Tools like Stripe CLI
   ```bash
   # Install Stripe CLI
   brew install stripe/stripe-cli/stripe
   
   # Forward events to your local server
   stripe listen --forward-to http://localhost:3000/api/webhooks/stripe
   ```

### Mock Webhook Sender

Create a tool to simulate webhook events:

```typescript
// scripts/send-test-webhook.ts
import fetch from 'node-fetch';
import crypto from 'crypto';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const webhookUrl = 'http://localhost:3000/api/webhooks/test';
const secret = process.env.WEBHOOK_TEST_SECRET || 'test-secret';

async function sendTestWebhook() {
  // Create test payload
  const payload = {
    event: 'test.event',
    data: {
      id: crypto.randomUUID(),
      test: true,
      message: 'This is a test webhook event'
    },
    timestamp: Date.now()
  };
  
  // Create signature
  const signature = crypto
    .createHmac('sha256', secret)
    .update(JSON.stringify(payload))
    .digest('hex');
  
  try {
    const response = await fetch(webhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Webhook-Signature': signature
      },
      body: JSON.stringify(payload)
    });
    
    const result = await response.text();
    console.log(`Status: ${response.status}`);
    console.log(`Response: ${result}`);
  } catch (error) {
    console.error('Error sending test webhook:', error);
  }
}

sendTestWebhook();
```

## Webhook Best Practices

1. **Respond quickly**: Process webhooks asynchronously and respond with 200 OK immediately
2. **Implement retry logic**: Handle temporary failures gracefully
3. **Verify signatures**: Always validate webhook authenticity
4. **Use idempotency keys**: Process webhooks idempotently to handle duplicates
5. **Log webhook events**: Maintain logs for debugging and auditing
6. **Set up monitoring**: Alert on webhook failures
7. **Handle rate limits**: Be prepared for bursts of webhook events

## Resources

- [Supabase Webhooks Documentation](https://supabase.com/docs/guides/database/webhooks)
- [Stripe Webhooks Guide](https://stripe.com/docs/webhooks)
- [GitHub Webhooks](https://docs.github.com/en/developers/webhooks-and-events/webhooks)
- [ngrok Documentation](https://ngrok.com/docs)
- [Webhook.site](https://webhook.site/) - Testing and debugging webhooks
