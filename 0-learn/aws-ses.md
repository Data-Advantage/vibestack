# AWS SES (Simple Email Service)

Amazon Simple Email Service (SES) is a cloud-based email sending service designed to help digital marketers and application developers send marketing, notification, and transactional emails. In VibeStack applications, SES provides a reliable and cost-effective way to incorporate email communications.

## Introduction to AWS SES

AWS SES handles the underlying infrastructure for high email deliverability and provides a robust system for sending large volumes of email. It includes:

- **High Deliverability**: Amazon works with ISPs to maximize delivery rates
- **Scalability**: Send a few emails or millions without provisioning servers
- **Analytics**: Track open rates, click-through rates, and other key metrics
- **Cost Effectiveness**: Pay only for what you send
- **Flexibility**: Send emails via API or SMTP
- **Authentication**: Support for SPF, DKIM, and DMARC
- **Content Filtering**: Helps prevent emails from being marked as spam

## Setting Up AWS SES

### Account Setup

1. **Create an AWS Account**: If you don't already have one, create an account at [aws.amazon.com](https://aws.amazon.com/).

2. **Access SES Console**: Navigate to the SES service from the AWS Management Console.

3. **Region Selection**: Choose the AWS region closest to your main user base.

### Domain Verification

Before you can send emails from your domain, you must verify ownership:

```typescript
// Example of using AWS SDK to verify a domain
import { SESClient, VerifyDomainIdentityCommand } from "@aws-sdk/client-ses";

const sesClient = new SESClient({ region: "us-east-1" });

async function verifyDomain(domain: string) {
  try {
    const command = new VerifyDomainIdentityCommand({ Domain: domain });
    const response = await sesClient.send(command);
    console.log("Verification token:", response.VerificationToken);
    console.log("Add this token as a TXT record to your DNS configuration.");
    return response.VerificationToken;
  } catch (error) {
    console.error("Error verifying domain:", error);
    throw error;
  }
}

// Usage
verifyDomain("yourdomain.com");
```

### DNS Configuration

After verifying your domain, you'll need to set up the following DNS records:

1. **TXT Record**: For domain verification
2. **DKIM Records**: Three CNAME records for DKIM signing
3. **SPF Record**: TXT record to specify authorized email servers
4. **DMARC Record**: TXT record to specify policy for emails that fail authentication

Example DNS records:

```
# Domain verification
_amazonses.yourdomain.com. TXT "verification-token-from-aws"

# DKIM records
selector1._domainkey.yourdomain.com. CNAME selector1-xxxxx._domainkey.amazonses.com.
selector2._domainkey.yourdomain.com. CNAME selector2-xxxxx._domainkey.amazonses.com.
selector3._domainkey.yourdomain.com. CNAME selector3-xxxxx._domainkey.amazonses.com.

# SPF record
yourdomain.com. TXT "v=spf1 include:amazonses.com ~all"

# DMARC record
_dmarc.yourdomain.com. TXT "v=DMARC1; p=quarantine; pct=100; rua=mailto:dmarc-reports@yourdomain.com"
```

### Moving Out of the Sandbox

By default, new SES accounts are placed in a "sandbox" with limitations:

- You can only send emails to verified email addresses
- Daily sending quotas are limited

To move out of the sandbox:

1. Navigate to the SES console
2. Click on "Request Production Access"
3. Fill out the form with details about your use case
4. Wait for AWS to approve your request (typically 1-2 business days)

## Integrating SES with VibeStack

### Installation

```bash
npm install @aws-sdk/client-ses
```

### Configuration

Create a utility file to configure the SES client:

```typescript
// lib/aws/ses.ts
import { SESClient } from "@aws-sdk/client-ses";

export const sesClient = new SESClient({
  region: process.env.AWS_REGION || "us-east-1",
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!,
  },
});
```

Add these environment variables to your project:

```bash
# .env.local
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
```

### Sending Email with the AWS SDK

```typescript
// lib/email/sendEmail.ts
import { SendEmailCommand } from "@aws-sdk/client-ses";
import { sesClient } from "../aws/ses";

interface EmailParams {
  to: string | string[];
  from: string;
  subject: string;
  html: string;
  text: string;
  replyTo?: string;
}

export async function sendEmail({
  to,
  from,
  subject,
  html,
  text,
  replyTo,
}: EmailParams) {
  const recipients = Array.isArray(to) ? to : [to];
  
  const params = {
    Destination: {
      ToAddresses: recipients,
    },
    Message: {
      Body: {
        Html: {
          Charset: "UTF-8",
          Data: html,
        },
        Text: {
          Charset: "UTF-8",
          Data: text,
        },
      },
      Subject: {
        Charset: "UTF-8",
        Data: subject,
      },
    },
    Source: from,
    ReplyToAddresses: replyTo ? [replyTo] : undefined,
  };

  try {
    const command = new SendEmailCommand(params);
    const result = await sesClient.send(command);
    return { success: true, messageId: result.MessageId };
  } catch (error) {
    console.error("Error sending email:", error);
    return { success: false, error };
  }
}
```

### Create Email Templates

```typescript
// lib/email/templates.ts
interface WelcomeEmailParams {
  userName: string;
  verificationLink: string;
}

export function welcomeEmailTemplate({ userName, verificationLink }: WelcomeEmailParams) {
  return {
    subject: `Welcome to VibeStack, ${userName}!`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1>Welcome to VibeStack!</h1>
        <p>Hi ${userName},</p>
        <p>Thank you for signing up. We're excited to have you on board!</p>
        <p>Please verify your email address by clicking the button below:</p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="${verificationLink}" style="background-color: #4F46E5; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; font-weight: bold;">
            Verify Email
          </a>
        </div>
        <p>If you didn't create this account, you can safely ignore this email.</p>
        <p>Best regards,<br>The VibeStack Team</p>
      </div>
    `,
    text: `
      Welcome to VibeStack!
      
      Hi ${userName},
      
      Thank you for signing up. We're excited to have you on board!
      
      Please verify your email address by clicking the link below:
      ${verificationLink}
      
      If you didn't create this account, you can safely ignore this email.
      
      Best regards,
      The VibeStack Team
    `,
  };
}
```

### Using Email Templates in API Routes

```typescript
// pages/api/auth/signup.ts
import type { NextApiRequest, NextApiResponse } from 'next';
import { sendEmail } from '@/lib/email/sendEmail';
import { welcomeEmailTemplate } from '@/lib/email/templates';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { email, name } = req.body;
    
    // Create user account logic here...
    
    // Generate verification token and link
    const verificationToken = generateToken(); // Implement this function
    const verificationLink = `${process.env.NEXT_PUBLIC_APP_URL}/verify?token=${verificationToken}`;
    
    // Send welcome email
    const emailTemplate = welcomeEmailTemplate({
      userName: name,
      verificationLink,
    });
    
    const emailResult = await sendEmail({
      to: email,
      from: 'welcome@yourdomain.com',
      subject: emailTemplate.subject,
      html: emailTemplate.html,
      text: emailTemplate.text,
    });
    
    if (!emailResult.success) {
      console.error('Failed to send welcome email:', emailResult.error);
    }
    
    return res.status(201).json({ success: true });
  } catch (error) {
    console.error('Error in signup handler:', error);
    return res.status(500).json({ error: 'Failed to create account' });
  }
}
```

## Email Types and Templates

### Transactional Emails

Emails triggered by user actions or system events:

1. **Welcome Emails**: Sent when users sign up
2. **Password Reset**: Sent when users request password recovery
3. **Account Verification**: To verify email addresses
4. **Order Confirmation**: For e-commerce transactions
5. **Receipt/Invoice**: For payments and subscriptions
6. **Status Updates**: For order processing, ticket status, etc.

### Promotional Emails

Marketing and engagement emails:

1. **Newsletter**: Regular content updates
2. **Product Updates**: New feature announcements
3. **Special Offers**: Discounts and promotions
4. **Event Invitations**: Webinars, product launches, etc.
5. **Re-engagement**: For inactive users

## Best Practices for Email Deliverability

1. **Authentication**: Implement SPF, DKIM, and DMARC
2. **Warm Up Your Domain**: Gradually increase sending volume
3. **Monitor Bounce Rates**: Keep bounce rates below 5%
4. **Handle Bounces**: Process and remove bounced addresses from your list
5. **Honor Unsubscribe Requests**: Always include and respect unsubscribe links
6. **Segment Your Lists**: Send targeted content to interested subscribers
7. **Maintain List Hygiene**: Regularly remove inactive subscribers
8. **Avoid Spam Triggers**: Don't use excessive capital letters, spam words, or misleading subjects
9. **Test Before Sending**: Preview emails on different devices and clients

## Handling Email Events

AWS SES can send notifications about email events via SNS (Simple Notification Service):

```typescript
// Example SES Configuration Set with SNS Notification
import { 
  SESClient, 
  CreateConfigurationSetCommand,
  CreateConfigurationSetEventDestinationCommand 
} from "@aws-sdk/client-ses";

async function setupEventTracking() {
  const sesClient = new SESClient({ region: "us-east-1" });
  
  // Step 1: Create a Configuration Set
  const configSetCommand = new CreateConfigurationSetCommand({
    ConfigurationSet: {
      Name: "VibeStackEmailTracking",
    },
  });
  
  await sesClient.send(configSetCommand);
  
  // Step 2: Create an Event Destination (SNS Topic)
  const eventDestinationCommand = new CreateConfigurationSetEventDestinationCommand({
    ConfigurationSetName: "VibeStackEmailTracking",
    EventDestination: {
      Name: "EmailEventsDestination",
      Enabled: true,
      MatchingEventTypes: [
        "send",
        "reject",
        "bounce",
        "complaint",
        "delivery",
        "open",
        "click",
      ],
      SNSDestination: {
        TopicARN: "arn:aws:sns:us-east-1:123456789012:email-events-topic",
      },
    },
  });
  
  await sesClient.send(eventDestinationCommand);
}
```

To use a configuration set when sending an email:

```typescript
const params = {
  // ... other email parameters
  ConfigurationSetName: "VibeStackEmailTracking",
};
```

## Handling Bounces and Complaints

Create a Lambda function to process SNS notifications:

```typescript
// AWS Lambda function to process email events
export const handler = async (event) => {
  try {
    for (const record of event.Records) {
      const message = JSON.parse(record.Sns.Message);
      
      // Handle different notification types
      switch (message.notificationType) {
        case 'Bounce':
          await handleBounce(message.bounce);
          break;
        case 'Complaint':
          await handleComplaint(message.complaint);
          break;
        case 'Delivery':
          await logDelivery(message.delivery);
          break;
        // Handle other event types...
      }
    }
    
    return { statusCode: 200, body: 'Processed successfully' };
  } catch (error) {
    console.error('Error processing SNS message:', error);
    return { statusCode: 500, body: 'Error processing message' };
  }
};

async function handleBounce(bounce) {
  // Extract email addresses that bounced
  const bouncedRecipients = bounce.bouncedRecipients.map(r => r.emailAddress);
  
  // Add to suppression list or update database
  for (const email of bouncedRecipients) {
    await updateBouncedEmailStatus(email, bounce.bounceType, bounce.bounceSubType);
  }
}

async function handleComplaint(complaint) {
  // Extract email addresses that complained
  const complainingRecipients = complaint.complainedRecipients.map(r => r.emailAddress);
  
  // Update database or suppression list
  for (const email of complainingRecipients) {
    await updateComplaintStatus(email, complaint.complaintFeedbackType);
  }
}

// Implement these functions based on your application needs
async function updateBouncedEmailStatus(email, bounceType, bounceSubType) {
  // Update database logic
}

async function updateComplaintStatus(email, feedbackType) {
  // Update database logic
}

async function logDelivery(delivery) {
  // Log successful delivery
}
```

## Email Templates with React and JSX

For better maintainability, use React components for email templates:

```bash
npm install react-email @react-email/components
```

```tsx
// emails/WelcomeEmail.tsx
import React from 'react';
import { 
  Html, 
  Head, 
  Body, 
  Container, 
  Section, 
  Heading, 
  Text, 
  Button, 
  Hr 
} from '@react-email/components';

interface WelcomeEmailProps {
  userName: string;
  verificationLink: string;
}

export const WelcomeEmail: React.FC<WelcomeEmailProps> = ({ 
  userName, 
  verificationLink 
}) => {
  return (
    <Html>
      <Head />
      <Body style={{ fontFamily: 'Arial, sans-serif', margin: '0', padding: '0' }}>
        <Container style={{ maxWidth: '600px', margin: '0 auto' }}>
          <Section>
            <Heading as="h1">Welcome to VibeStack!</Heading>
            <Text>Hi {userName},</Text>
            <Text>Thank you for signing up. We're excited to have you on board!</Text>
            <Text>Please verify your email address by clicking the button below:</Text>
            
            <Section style={{ textAlign: 'center', margin: '30px 0' }}>
              <Button
                href={verificationLink}
                style={{
                  backgroundColor: '#4F46E5',
                  color: 'white',
                  padding: '12px 24px',
                  borderRadius: '4px',
                  fontWeight: 'bold',
                  textDecoration: 'none',
                }}
              >
                Verify Email
              </Button>
            </Section>
            
            <Text>If you didn't create this account, you can safely ignore this email.</Text>
            <Hr />
            <Text style={{ fontSize: '14px', color: '#666' }}>
              Best regards,<br />
              The VibeStack Team
            </Text>
          </Section>
        </Container>
      </Body>
    </Html>
  );
};
```

Render the React email template:

```typescript
// lib/email/renderEmail.ts
import { renderAsync } from '@react-email/render';
import { WelcomeEmail } from '@/emails/WelcomeEmail';

export async function renderWelcomeEmail(props: { userName: string; verificationLink: string }) {
  const html = await renderAsync(WelcomeEmail(props));
  // Generate plain text version or use a library like html-to-text
  const text = htmlToText(html);
  
  return {
    html,
    text,
  };
}
```

## Using SES with Serverless Functions

### With AWS Lambda

```typescript
// AWS Lambda function to send emails
import { SESClient, SendEmailCommand } from "@aws-sdk/client-ses";

const sesClient = new SESClient({ region: "us-east-1" });

export const handler = async (event) => {
  try {
    const { to, subject, html, text } = JSON.parse(event.body);
    
    const params = {
      Destination: {
        ToAddresses: [to],
      },
      Message: {
        Body: {
          Html: {
            Charset: "UTF-8",
            Data: html,
          },
          Text: {
            Charset: "UTF-8",
            Data: text,
          },
        },
        Subject: {
          Charset: "UTF-8",
          Data: subject,
        },
      },
      Source: "noreply@yourdomain.com",
    };
    
    const command = new SendEmailCommand(params);
    const result = await sesClient.send(command);
    
    return {
      statusCode: 200,
      body: JSON.stringify({
        success: true,
        messageId: result.MessageId,
      }),
    };
  } catch (error) {
    console.error("Error sending email:", error);
    
    return {
      statusCode: 500,
      body: JSON.stringify({
        success: false,
        error: error.message,
      }),
    };
  }
};
```

## Monitoring Email Performance

### Email Metrics to Track

1. **Delivery Rate**: Percentage of emails successfully delivered
2. **Open Rate**: Percentage of delivered emails that are opened
3. **Click-Through Rate (CTR)**: Percentage of email recipients who clicked on a link
4. **Bounce Rate**: Percentage of emails that couldn't be delivered
5. **Complaint Rate**: Percentage of emails marked as spam
6. **Unsubscribe Rate**: Percentage of recipients who unsubscribe

### Tracking Pixel for Opens

```typescript
// Add tracking pixel to email template
function addTrackingPixel(html: string, emailId: string) {
  const trackingUrl = `https://yourvibestackapp.com/api/email/track?id=${emailId}&event=open`;
  const trackingPixel = `<img src="${trackingUrl}" width="1" height="1" alt="" style="display: none;" />`;
  
  // Insert before closing body tag
  return html.replace('</body>', `${trackingPixel}</body>`);
}
```

### Tracking Links for Clicks

```typescript
// Wrap links with tracking URLs
function wrapLinksWithTracking(html: string, emailId: string) {
  const dom = new JSDOM(html);
  const links = dom.window.document.querySelectorAll('a');
  
  links.forEach((link) => {
    const originalUrl = link.getAttribute('href');
    if (originalUrl) {
      const encodedUrl = encodeURIComponent(originalUrl);
      const trackingUrl = `https://yourvibestackapp.com/api/email/track?id=${emailId}&event=click&url=${encodedUrl}`;
      link.setAttribute('href', trackingUrl);
    }
  });
  
  return dom.serialize();
}
```

## Testing Emails Locally

For local development, use a tool like [Mailhog](https://github.com/mailhog/MailHog) or [Ethereal](https://ethereal.email/):

```typescript
// lib/email/sendEmailDev.ts
import nodemailer from 'nodemailer';

export async function sendEmailDev(options: {
  to: string | string[];
  subject: string;
  html: string;
  text: string;
  from: string;
}) {
  // Create a test account using Ethereal
  const testAccount = await nodemailer.createTestAccount();
  
  // Create a transporter
  const transporter = nodemailer.createTransport({
    host: 'smtp.ethereal.email',
    port: 587,
    secure: false,
    auth: {
      user: testAccount.user,
      pass: testAccount.pass,
    },
  });
  
  // Send mail
  const info = await transporter.sendMail({
    from: options.from,
    to: Array.isArray(options.to) ? options.to.join(', ') : options.to,
    subject: options.subject,
    text: options.text,
    html: options.html,
  });
  
  console.log('Message sent: %s', info.messageId);
  // Preview URL
  console.log('Preview URL: %s', nodemailer.getTestMessageUrl(info));
  
  return info;
}
```

## Resources

- [AWS SES Documentation](https://docs.aws.amazon.com/ses/latest/dg/Welcome.html)
- [AWS SES Console](https://console.aws.amazon.com/ses/)
- [AWS SDK for JavaScript v3](https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/clients/client-ses/)
- [Email Deliverability Best Practices](https://docs.aws.amazon.com/ses/latest/dg/deliverability-and-success.html)
- [React Email](https://react.email/): Framework for building email templates with React
- [MJML](https://mjml.io/): Framework for responsive email design
- [DMARC](https://dmarc.org/): Email authentication protocol
