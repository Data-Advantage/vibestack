# AI SDK 5 + AI Elements + Vercel AI Gateway

Use AI SDK 5 for model-agnostic AI features with streaming and object generation, AI Elements for prebuilt AI-native UI components, and Vercel AI Gateway for provider routing and observability.

Docs:
- AI SDK: https://ai-sdk.dev/
- AI Elements: https://ai-sdk.dev/elements/overview

## Install

```
npm i ai zod
```

## Default Model

Set the default to gpt-5-mini via the AI Gateway. Override per feature as needed.

## Basic Usage (Object Generation)

```
import { generateObject } from "ai";
import { z } from "zod";

const schema = z.object({ title: z.string(), tags: z.array(z.string()) });

export async function createSummary(input: string) {
  const { object } = await generateObject({
    model: "gpt-5-mini",
    schema,
    prompt: `Summarize and extract tags: ${input}`,
  });
  return object;
}
```

## UI with AI Elements

Use Elements to compose chat, messages, loader, sources, suggestions, etc. See the full component catalog and examples:
- https://ai-sdk.dev/elements/overview

## Gateway

Configure the AI Gateway key and route requests through it for provider abstraction and analytics.
