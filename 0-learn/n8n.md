# n8n

[n8n](https://n8n.io/) is a powerful workflow automation tool that helps you connect apps and automate tasks with a visual, no-code/low-code approach.

## Introduction to n8n

n8n (pronounced "n-eight-n") is an extendable workflow automation platform that allows you to connect different services and systems, enabling them to communicate with each other through an intuitive visual interface. It's an open-source alternative to services like Zapier, Make (formerly Integromat), or Tray.io.

## Key Concepts

### Workflows

Workflows in n8n are sequences of connected nodes that process data. Each workflow consists of:

- **Trigger Node**: The starting point that initiates the workflow (e.g., webhook, scheduled event)
- **Regular Nodes**: Process and transform data
- **Connection Lines**: Define the data flow between nodes

### Nodes

Nodes are the building blocks of n8n workflows. They represent:

- **Triggers**: Starting events that initiate workflows (HTTP requests, schedules, webhooks)
- **Apps & Services**: Integrations with external services (Supabase, Stripe, Email, etc.)
- **Helpers**: Utilities for transforming and manipulating data

### Executions

When a workflow runs, n8n creates an execution, which:

- Processes data through each node in sequence
- Maintains a log of operation results
- Can be viewed, debugged, and retried

## Setup with VibeStack

### Self-Hosted Installation

For production use with VibeStack, you can self-host n8n:

```bash
# Using Docker
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

### Cloud Option

Alternatively, you can use [n8n.cloud](https://www.n8n.cloud/) for a managed solution without the overhead of self-hosting.

## Common Use Cases in VibeStack

### User Onboarding Automation

```
Trigger: New User Signs Up in Supabase
↓
Action: Send Welcome Email
↓
Action: Create User Record in CRM
↓
Action: Trigger Initial Data Setup
↓
Action: Notify Team in Slack
```

### Payment Processing

```
Trigger: New Stripe Subscription
↓
Action: Update User Status in Database
↓
Action: Create Invoice in Accounting System
↓
Action: Send Receipt Email
```

### Content Generation Pipeline

```
Trigger: Scheduled (Daily/Weekly)
↓
Action: Fetch Latest Data from API
↓
Action: Generate Content with AI
↓
Action: Post to Blog/Social Media
↓
Action: Send Notification
```

## Integrating n8n with Supabase

n8n works seamlessly with Supabase through dedicated nodes:

### Database Operations

```javascript
// Example: Fetch users with active subscriptions
// n8n Supabase node configuration:
{
  "operation": "Select",
  "schema": "public",
  "table": "users",
  "returnAll": false,
  "limit": 10,
  "additionalFields": {
    "where": "subscription_status = 'active'"
  }
}
```

### Authentication Hooks

You can use n8n to respond to Supabase auth events by setting up webhook triggers that connect to Supabase auth hooks.

## Best Practices

1. **Error Handling**: Use Error Trigger nodes to catch and respond to failures
2. **Credentials Security**: Store sensitive credentials in n8n's encrypted storage
3. **Modular Workflows**: Break complex processes into smaller, reusable workflows
4. **Version Control**: Export workflows and store in version control alongside your VibeStack code
5. **Monitoring**: Set up notifications for workflow failures

## Advanced Features

- **Custom JavaScript**: Write custom code nodes for complex logic
- **Webhooks**: Create dynamic endpoints for external services to trigger workflows
- **Queues & Batching**: Process data in batches for efficiency
- **Credentials Management**: Securely store and manage API keys and access tokens

## Resources

- [n8n Documentation](https://docs.n8n.io/)
- [n8n Community Forum](https://community.n8n.io/)
- [n8n Blog](https://blog.n8n.io/) for tutorials and use cases
- [GitHub Repository](https://github.com/n8n-io/n8n)
- [n8n Academy](https://academy.n8n.io/) for structured learning
