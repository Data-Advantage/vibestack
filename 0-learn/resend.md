# Resend

[Resend](https://resend.com) is a developer-focused email API service that makes it easy to send transactional and marketing emails from your VibeStack application.

## Introduction to Resend

Resend provides a modern, developer-friendly platform for sending emails, offering:

- Simple, RESTful API
- High deliverability rates
- React-based email components
- Detailed analytics and logs
- Webhook support
- SMTP compatibility

## Installation & Setup

To get started with Resend in your VibeStack application:

```bash
# Install the Resend SDK for Node.js
npm install resend
```

Then, configure the API key in your environment variables:

```env
# .env file
RESEND_API_KEY=re_123456789
```

## Basic Usage

### Sending a Simple Email

```typescript
// lib/email.ts
import { Resend } from 'resend';

// Initialize with API key from environment variable
const resend = new Resend(process.env.RESEND_API_KEY);

export async function sendEmail({
  to,
  subject,
  text,
  html,
}: {
  to: string;
  subject: string;
  text: string;
  html?: string;
}) {
  try {
    const { data, error } = await resend.emails.send({
      from: 'Your App <noreply@yourdomain.com>',
      to,
      subject,
      text,
      html,
    });
    
    if (error) {
      console.error('Email sending failed:', error);
      return { success: false, error };
    }
    
    return { success: true, data };
  } catch (error) {
    console.error('Exception when sending email:', error);
    return { success: false, error };
  }
}
```

### Using React for Email Templates

Resend supports React-based email templates through `react-email`:

```bash
# Install react-email
npm install react-email @react-email/components
```

Example usage:

```tsx
// emails/welcome-email.tsx
import { 
  Body,
  Button,
  Container,
  Head,
  Heading,
  Html,
  Link,
  Section,
  Text
} from '@react-email/components';
import * as React from 'react';

interface WelcomeEmailProps {
  username: string;
  userEmail: string;
}

export default function WelcomeEmail({ username, userEmail }: WelcomeEmailProps) {
  return (
    <Html>
      <Head />
      <Body style={{ fontFamily: 'Arial, sans-serif', padding: '20px' }}>
        <Container>
          <Heading as="h1">Welcome to VibeStack, {username}!</Heading>
          <Text>We're excited to have you on board.</Text>
          <Text>Your account has been created with the email: {userEmail}</Text>
          <Section style={{ textAlign: 'center', margin: '30px 0' }}>
            <Button 
              href="https://your-app.com/dashboard" 
              style={{ 
                backgroundColor: '#007BFF', 
                color: '#fff',
                padding: '12px 20px',
                borderRadius: '4px',
                textDecoration: 'none',
              }}
            >
              Go to Dashboard
            </Button>
          </Section>
          <Text>
            If you have any questions, please{' '}
            <Link href="https://your-app.com/support">contact our support team</Link>.
          </Text>
        </Container>
      </Body>
    </Html>
  );
}
```

And to send the email:

```typescript
// Sending a React-based email
import { Resend } from 'resend';
import WelcomeEmail from '../emails/welcome-email';

const resend = new Resend(process.env.RESEND_API_KEY);

export async function sendWelcomeEmail(user: { name: string; email: string }) {
  try {
    const { data, error } = await resend.emails.send({
      from: 'Your App <noreply@yourdomain.com>',
      to: user.email,
      subject: 'Welcome to VibeStack!',
      react: WelcomeEmail({ username: user.name, userEmail: user.email }),
    });
    
    return { success: !error, data, error };
  } catch (error) {
    console.error('Exception when sending welcome email:', error);
    return { success: false, error };
  }
}
```

## Common Email Types in VibeStack

| Email Type | Purpose | Tips |
|------------|---------|------|
| Welcome | Onboard new users | Keep it concise, include a clear CTA |
| Verification | Verify email ownership | Short, urgent, clear instructions |
| Password Reset | Help users recover accounts | Security-focused, limited time validity |
| Notifications | Alert users to activity | Actionable, customizable preferences |
| Receipts | Confirm purchases/subscriptions | Clear line items, support info |
| Feature Updates | Highlight new functionality | Screenshot/GIF of the feature, how-to |

## Best Practices

1. **Domain Verification**: Verify your sending domain through DNS records to improve deliverability
2. **Error Handling**: Implement comprehensive error handling for all email operations
3. **Retry Logic**: Add retry mechanisms for transient failures
4. **Template Organization**: Create a structured system for email templates
5. **Preview Testing**: Test emails across multiple clients before sending
6. **Analytics**: Monitor open rates, click rates, and deliverability

## Implementation with Next.js

In a Next.js application, you can create a server action for sending emails:

```typescript
// app/actions/email.ts
'use server'

import { Resend } from 'resend';
import WelcomeEmail from '@/emails/welcome-email';

const resend = new Resend(process.env.RESEND_API_KEY);

export async function sendWelcomeEmail(
  formData: FormData
) {
  const email = formData.get('email') as string;
  const name = formData.get('name') as string;
  
  try {
    const { data, error } = await resend.emails.send({
      from: 'VibeStack <onboarding@yourdomain.com>',
      to: email,
      subject: 'Welcome to VibeStack!',
      react: WelcomeEmail({ username: name, userEmail: email }),
    });
    
    if (error) {
      return { success: false, error: error.message };
    }
    
    return { success: true, messageId: data?.id };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}
```

## Resources

- [Resend Documentation](https://resend.com/docs)
- [React Email](https://react.email)
- [Email Deliverability Guide](https://resend.com/blog/email-deliverability-guide)
- [Resend GitHub](https://github.com/resendlabs/resend-node)
