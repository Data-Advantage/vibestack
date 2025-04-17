# Azure OpenAI Service

Azure OpenAI Service is Microsoft's cloud-based offering that provides access to OpenAI's powerful language models, including GPT-4, GPT-3.5-Turbo, and DALL-E, with the added benefits of Azure's enterprise security, compliance, and regional availability. In VibeStack applications, Azure OpenAI enables advanced AI capabilities with enterprise-grade reliability and privacy controls.

## Introduction to Azure OpenAI

Azure OpenAI combines OpenAI's leading models with Azure's enterprise platform, providing:

- **Enterprise Security**: Azure Active Directory integration, private networking, and compliance certifications
- **Regional Deployment**: Models available in multiple Azure regions for data residency compliance
- **Managed Infrastructure**: Simplified deployment without managing complex ML infrastructure
- **Content Filtering**: Built-in content filtering and abuse monitoring
- **Cost Management**: Azure subscription billing and resource governance

## Available Models

Azure OpenAI provides access to several types of models:

### GPT Models (Text Generation)

- **GPT-4**: Most powerful model for complex reasoning, code generation, and creative content
- **GPT-3.5-Turbo**: Efficient, cost-effective model for chat and text generation
- **GPT-4 Turbo**: Enhanced version with improved performance and additional capabilities
- **GPT-4 Vision**: Supports multimodal inputs including images

### Embedding Models

- **text-embedding-ada-002**: Converts text to numerical vectors for similarity search

### DALL-E Models (Image Generation)

- **DALL-E 3**: Creates images from text descriptions
- **DALL-E 2**: Previous generation image generation model

## Setting Up Azure OpenAI

### Prerequisites

1. **Azure Subscription**: An active Azure subscription
2. **Access Approval**: Complete the [access request form](https://aka.ms/oai/access) for Azure OpenAI
3. **Supported Region**: Choose a region where Azure OpenAI is available (e.g., East US, West Europe)

### Creating an Azure OpenAI Resource

1. Sign in to the [Azure Portal](https://portal.azure.com/)
2. Search for "Azure OpenAI" and select it
3. Click "Create"
4. Fill in the required details:
   - Subscription and Resource Group
   - Region
   - Name
   - Pricing tier
5. Click "Review + create", then "Create"

### Deploying a Model

After resource creation:

1. Navigate to your Azure OpenAI resource
2. Select "Model deployments" from the left menu
3. Click "Create new deployment"
4. Select a model (e.g., "gpt-35-turbo")
5. Set a deployment name and version
6. Configure advanced options if needed (e.g., content filter settings)
7. Click "Create"

## Integrating with VibeStack

### Installation

```bash
npm install @azure/openai
```

### Configuration

Create a utility file for Azure OpenAI configuration:

```typescript
// lib/azure-openai/client.ts
import { OpenAIClient, AzureKeyCredential } from "@azure/openai";

// Azure OpenAI configuration
const endpoint = process.env.AZURE_OPENAI_ENDPOINT!;
const apiKey = process.env.AZURE_OPENAI_API_KEY!;
const deploymentName = process.env.AZURE_OPENAI_DEPLOYMENT_NAME!;

// Create a client instance
export const openaiClient = new OpenAIClient(
  endpoint,
  new AzureKeyCredential(apiKey)
);

export { deploymentName };
```

Add these environment variables to your project:

```bash
# .env.local
AZURE_OPENAI_ENDPOINT=https://your-resource-name.openai.azure.com/
AZURE_OPENAI_API_KEY=your-api-key
AZURE_OPENAI_DEPLOYMENT_NAME=your-deployment-name
```

### Text Generation with GPT

```typescript
// lib/azure-openai/generate-text.ts
import { openaiClient, deploymentName } from "./client";

interface GenerateTextOptions {
  prompt: string;
  maxTokens?: number;
  temperature?: number;
  topP?: number;
  frequencyPenalty?: number;
  presencePenalty?: number;
  stopSequences?: string[];
}

export async function generateText({
  prompt,
  maxTokens = 2000,
  temperature = 0.7,
  topP = 0.95,
  frequencyPenalty = 0,
  presencePenalty = 0,
  stopSequences = [],
}: GenerateTextOptions) {
  try {
    const response = await openaiClient.getCompletions(
      deploymentName,
      [prompt],
      {
        maxTokens,
        temperature,
        topP,
        frequencyPenalty,
        presencePenalty,
        stop: stopSequences.length > 0 ? stopSequences : undefined,
      }
    );

    return {
      text: response.choices[0].text,
      usage: {
        promptTokens: response.usage.promptTokens,
        completionTokens: response.usage.completionTokens,
        totalTokens: response.usage.totalTokens,
      },
    };
  } catch (error) {
    console.error("Error generating text:", error);
    throw error;
  }
}
```

### Chat Completion

```typescript
// lib/azure-openai/chat.ts
import { ChatRequestMessage, ChatCompletionsOptions } from "@azure/openai";
import { openaiClient, deploymentName } from "./client";

interface ChatOptions {
  messages: ChatRequestMessage[];
  temperature?: number;
  maxTokens?: number;
  topP?: number;
  frequencyPenalty?: number;
  presencePenalty?: number;
  stopSequences?: string[];
  functions?: any[];
}

export async function createChatCompletion({
  messages,
  temperature = 0.7,
  maxTokens = 2000,
  topP = 0.95,
  frequencyPenalty = 0,
  presencePenalty = 0,
  stopSequences = [],
  functions = [],
}: ChatOptions) {
  try {
    const options: ChatCompletionsOptions = {
      temperature,
      maxTokens,
      topP,
      frequencyPenalty,
      presencePenalty,
    };

    if (stopSequences.length > 0) {
      options.stop = stopSequences;
    }

    if (functions.length > 0) {
      options.functions = functions;
    }

    const response = await openaiClient.getChatCompletions(
      deploymentName,
      messages,
      options
    );

    return {
      message: response.choices[0].message,
      usage: {
        promptTokens: response.usage.promptTokens,
        completionTokens: response.usage.completionTokens,
        totalTokens: response.usage.totalTokens,
      },
    };
  } catch (error) {
    console.error("Error creating chat completion:", error);
    throw error;
  }
}
```

### Image Generation with DALL-E

```typescript
// lib/azure-openai/generate-image.ts
import { openaiClient } from "./client";

// Note: Use your DALL-E deployment name, which is different from the GPT deployment
const dalleDeploymentName = process.env.AZURE_OPENAI_DALLE_DEPLOYMENT_NAME!;

interface GenerateImageOptions {
  prompt: string;
  n?: number;
  size?: "256x256" | "512x512" | "1024x1024" | "1792x1024" | "1024x1792";
  quality?: "standard" | "hd";
  style?: "vivid" | "natural";
}

export async function generateImage({
  prompt,
  n = 1,
  size = "1024x1024",
  quality = "standard",
  style = "vivid",
}: GenerateImageOptions) {
  try {
    const response = await openaiClient.getImages(dalleDeploymentName, prompt, {
      n,
      size,
      quality,
      style,
    });

    return {
      images: response.data.map((img) => img.url || ""),
    };
  } catch (error) {
    console.error("Error generating image:", error);
    throw error;
  }
}
```

### Creating Embeddings

```typescript
// lib/azure-openai/embeddings.ts
import { openaiClient } from "./client";

// Use your embedding model deployment name
const embeddingDeploymentName = process.env.AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME!;

export async function createEmbeddings(texts: string[]) {
  try {
    const response = await openaiClient.getEmbeddings(
      embeddingDeploymentName,
      texts
    );

    return {
      embeddings: response.data.map((item) => item.embedding),
      usage: response.usage.totalTokens,
    };
  } catch (error) {
    console.error("Error creating embeddings:", error);
    throw error;
  }
}
```

## Implementation Examples

### AI-Powered Customer Support Bot

```typescript
// pages/api/support-bot.ts
import type { NextApiRequest, NextApiResponse } from 'next';
import { ChatRequestMessage } from "@azure/openai";
import { createChatCompletion } from '@/lib/azure-openai/chat';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { messages, userId } = req.body;

    if (!messages || !Array.isArray(messages)) {
      return res.status(400).json({ error: 'Invalid messages format' });
    }

    // Create a system message for the bot
    const systemMessage: ChatRequestMessage = {
      role: "system",
      content: `You are a helpful customer support assistant for VibeStack, a SaaS platform for building web applications. 
      Be concise, friendly, and focus on solving the user's problem. If you don't know the answer, 
      suggest escalating to a human support agent. Current date: ${new Date().toISOString().split('T')[0]}`
    };

    // Prepare the messages array with the system message first
    const formattedMessages: ChatRequestMessage[] = [
      systemMessage,
      ...messages.map((msg: any) => ({
        role: msg.role,
        content: msg.content,
      })),
    ];

    const response = await createChatCompletion({
      messages: formattedMessages,
      temperature: 0.5, // More deterministic responses
      maxTokens: 500,   // Keep responses concise
    });

    return res.status(200).json({
      message: response.message,
      usage: response.usage,
    });
  } catch (error: any) {
    console.error('Support bot error:', error);
    return res.status(500).json({ 
      error: 'Error processing request',
      details: error.message 
    });
  }
}
```

### Content Generation for Marketing

```typescript
// pages/api/generate-content.ts
import type { NextApiRequest, NextApiResponse } from 'next';
import { generateText } from '@/lib/azure-openai/generate-text';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { topic, contentType, tone, targetAudience, length } = req.body;

    if (!topic || !contentType) {
      return res.status(400).json({ error: 'Missing required parameters' });
    }

    const prompt = `
      Generate ${contentType} about ${topic}.
      Tone: ${tone || 'professional'}
      Target audience: ${targetAudience || 'general'}
      Length: ${length || 'medium'}
      
      The content should be well-structured, engaging, and provide valuable information.
      Focus on clarity and actionable insights.
    `;

    const result = await generateText({
      prompt,
      temperature: 0.7,
      maxTokens: length === 'long' ? 2000 : length === 'short' ? 500 : 1000,
    });

    return res.status(200).json({
      content: result.text,
      usage: result.usage,
    });
  } catch (error: any) {
    console.error('Content generation error:', error);
    return res.status(500).json({ 
      error: 'Error generating content',
      details: error.message 
    });
  }
}
```

### Product Feature Visualization

```typescript
// pages/api/visualize-feature.ts
import type { NextApiRequest, NextApiResponse } from 'next';
import { generateImage } from '@/lib/azure-openai/generate-image';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { featureName, description, style } = req.body;

    if (!featureName || !description) {
      return res.status(400).json({ error: 'Missing feature details' });
    }

    const prompt = `
      Create a professional visualization of a software feature called "${featureName}" 
      for a SaaS application. ${description}. The image should be clean, modern, 
      and suitable for a product website or marketing materials.
    `;

    const result = await generateImage({
      prompt,
      size: "1024x1024",
      quality: "standard",
      style: style === 'natural' ? 'natural' : 'vivid',
    });

    return res.status(200).json({
      images: result.images,
    });
  } catch (error: any) {
    console.error('Image generation error:', error);
    return res.status(500).json({ 
      error: 'Error generating image',
      details: error.message 
    });
  }
}
```

## AI-Powered Features for VibeStack

### Semantic Search with Embeddings

```typescript
// lib/azure-openai/semantic-search.ts
import { createEmbeddings } from './embeddings';
import { createClient } from '@/lib/supabase/server';

interface SearchOptions {
  query: string;
  collection: string;
  limit?: number;
  threshold?: number;
}

export async function semanticSearch({
  query,
  collection,
  limit = 5,
  threshold = 0.7,
}: SearchOptions) {
  try {
    // 1. Generate embedding for the search query
    const { embeddings } = await createEmbeddings([query]);
    const queryEmbedding = embeddings[0];
    
    // 2. Search in Supabase using vector similarity
    const supabase = createClient();
    const { data, error } = await supabase
      .rpc('match_documents', {
        query_embedding: queryEmbedding,
        match_threshold: threshold,
        match_count: limit,
        collection_name: collection
      });
    
    if (error) throw error;
    
    return {
      results: data,
    };
  } catch (error) {
    console.error('Semantic search error:', error);
    throw error;
  }
}
```

### AI-Generated Product Descriptions

```typescript
// components/ProductDescriptionGenerator.tsx
'use client'

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Input } from '@/components/ui/input';
import { Loader2 } from 'lucide-react';

export default function ProductDescriptionGenerator() {
  const [productName, setProductName] = useState('');
  const [keyFeatures, setKeyFeatures] = useState('');
  const [targetAudience, setTargetAudience] = useState('');
  const [generatedDescription, setGeneratedDescription] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  async function generateDescription() {
    if (!productName || !keyFeatures) {
      setError('Please provide product name and key features');
      return;
    }

    setIsLoading(true);
    setError('');

    try {
      const response = await fetch('/api/generate-description', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          productName,
          keyFeatures,
          targetAudience,
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to generate description');
      }

      const data = await response.json();
      setGeneratedDescription(data.description);
    } catch (err: any) {
      setError(err.message || 'An error occurred');
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <div className="space-y-4 p-4 border rounded-lg">
      <h2 className="text-xl font-bold">AI Product Description Generator</h2>
      
      <div className="space-y-2">
        <label className="block text-sm font-medium">Product Name</label>
        <Input
          value={productName}
          onChange={(e) => setProductName(e.target.value)}
          placeholder="E.g., VibeStack Pro"
        />
      </div>
      
      <div className="space-y-2">
        <label className="block text-sm font-medium">Key Features</label>
        <Textarea
          value={keyFeatures}
          onChange={(e) => setKeyFeatures(e.target.value)}
          placeholder="List key features, one per line"
          rows={3}
        />
      </div>
      
      <div className="space-y-2">
        <label className="block text-sm font-medium">Target Audience</label>
        <Input
          value={targetAudience}
          onChange={(e) => setTargetAudience(e.target.value)}
          placeholder="E.g., Small Business Owners, Developers"
        />
      </div>
      
      <Button 
        onClick={generateDescription}
        disabled={isLoading}
        className="w-full"
      >
        {isLoading ? (
          <>
            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            Generating...
          </>
        ) : (
          'Generate Description'
        )}
      </Button>
      
      {error && <p className="text-red-500 text-sm">{error}</p>}
      
      {generatedDescription && (
        <div className="mt-4 p-3 bg-gray-50 rounded border">
          <h3 className="text-sm font-medium mb-2">Generated Description:</h3>
          <p className="text-sm whitespace-pre-wrap">{generatedDescription}</p>
        </div>
      )}
    </div>
  );
}
```

## Best Practices

### Cost Management

1. **Monitor Usage**: Use Azure Cost Management to track spending
2. **Set Budget Alerts**: Create alerts when approaching budget thresholds
3. **Optimize Tokens**: Minimize prompt length and use efficient prompts
4. **Caching**: Cache responses for identical or similar requests
5. **Model Selection**: Use smaller models for simpler tasks

### Security Considerations

1. **Content Filtering**: Enable Azure OpenAI content filtering
2. **Input Validation**: Sanitize user inputs to prevent prompt injection
3. **Output Review**: Validate model outputs before displaying to users
4. **Access Control**: Use Azure RBAC to limit who can access the service
5. **Logging**: Enable diagnostic logging for audit and troubleshooting

### Rate Limiting

Implement client-side rate limiting to avoid excessive API calls:

```typescript
// lib/azure-openai/rate-limiter.ts
import { RateLimiter } from 'limiter';

// Create a rate limiter: 20 requests per minute
const limiter = new RateLimiter({ tokensPerInterval: 20, interval: 'minute' });

export async function acquireRateLimit() {
  const remainingRequests = await limiter.removeTokens(1);
  return remainingRequests >= 0;
}
```

Usage:

```typescript
// In your API endpoint
const canProceed = await acquireRateLimit();
if (!canProceed) {
  return res.status(429).json({ error: 'Rate limit exceeded' });
}
// Continue with the request...
```

## Prompt Engineering

Effective prompts yield better results from Azure OpenAI:

### Techniques for Better Prompts

1. **Be Specific**: Clearly state what you want the model to do
2. **Provide Context**: Include relevant background information
3. **Use Examples**: Demonstrate the desired output format
4. **Control Temperature**: Lower values (0.1-0.4) for factual tasks, higher (0.7-1.0) for creative tasks
5. **Structured Output**: Request specific formats like JSON when needed

### Example Prompts

For summarization:
```
Summarize the following text in 3-5 bullet points, focusing on the key actionable insights:

{text}
```

For data extraction:
```
Extract the following information from this resume in JSON format:
- name
- email
- skills (as an array)
- work experience (array of objects with company, position, duration)

Resume text:
{resume_text}
```

## Error Handling

Implement robust error handling for Azure OpenAI API calls:

```typescript
// lib/azure-openai/error-handler.ts
export class OpenAIError extends Error {
  status: number;
  type: string;
  
  constructor(message: string, status: number, type: string) {
    super(message);
    this.name = 'OpenAIError';
    this.status = status;
    this.type = type;
  }
  
  static handleError(error: any) {
    console.error('Azure OpenAI API Error:', error);
    
    // Extract details from the error response
    const status = error.status || 500;
    const type = error.type || 'api_error';
    const message = error.message || 'An error occurred while calling Azure OpenAI';
    
    return new OpenAIError(message, status, type);
  }
}
```

Usage:

```typescript
try {
  const result = await openaiClient.getChatCompletions(/* params */);
  return result;
} catch (error) {
  throw OpenAIError.handleError(error);
}
```

## Resources

- [Azure OpenAI Service Documentation](https://learn.microsoft.com/en-us/azure/cognitive-services/openai/)
- [Azure OpenAI Studio](https://oai.azure.com/)
- [OpenAI Cookbook](https://github.com/openai/openai-cookbook) - Examples and guides
- [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/) - Estimate costs
- [Azure OpenAI REST API Reference](https://learn.microsoft.com/en-us/azure/cognitive-services/openai/reference)
- [Azure OpenAI Samples Repository](https://github.com/Azure/azure-openai-samples)
