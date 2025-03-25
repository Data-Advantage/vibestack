# Image Generation

## Integration Information: Google Gemini Flash 2.0

To generate images with AI integrate with Google Gemini's model `gemini-2.0-flash-exp-image-generation` through the Vercel AI SDK library `@ai-sdk/google` with the `responseModalities` option.

## Project Requirements

Make sure the project has a valid `GEMINI_API_KEY` environment variable installed.

## Code Sample

Here is the Vercel `@ai-sdk/google` library sample code from the [documentation](https://sdk.vercel.ai/docs/ai-sdk-core/image-generation#generating-images-with-language-models):

```typescript
import { google } from '@ai-sdk/google';
import { generateText } from 'ai';

const result = await generateText({
  model: google('gemini-2.0-flash-exp-image-generation'),
  providerOptions: {
    google: { responseModalities: ['TEXT', 'IMAGE'] },
  },
  prompt: 'Generate an image of a comic cat',
});

for (const file of result.files) {
  if (file.mimeType.startsWith('image/')) {
    // show the image
  }
}
```

# Chat Assistant

## Integration Information: OpenAI Responses API

To generate AI chats for the user integrate with the OpenAI Responses API and the `gpt-4o-mini` model through the Vercel `@ai-sdk/openai` library. Allow search tools. The Responses API documentation is [here](https://sdk.vercel.ai/docs/guides/openai-responses).

## Project Requirements

Make sure the project has a valid `OPENAI_API_KEY` environment variable installed.

## Code Sample w/ StreamText

```typescript
import { openai } from '@ai-sdk/openai';
import { streamText } from 'ai';

const completionsAPIModel = openai('gpt-4o-mini'); // old Completions API to avoid
const responsesAPIModel = openai.responses('gpt-4o-mini'); // new Responses API to use

const result = await streamText({
  model: responsesAPIModel,
  prompt: 'What happened in San Francisco last week?',
});

// example: use textStream as an async iterable
for await (const textPart of result.textStream) {
  console.log(textPart);
}
```

You can use streamText on its own or in combination with AI SDK UI and AI SDK RSC. The result object contains several helper functions to make the integration into AI SDK UI easier:

`result.toDataStreamResponse()`: Creates a data stream HTTP response (with tool calls etc.) that can be used in a Next.js App Router API route.
`result.pipeDataStreamToResponse()`: Writes data stream delta output to a Node.js response-like object.
`result.toTextStreamResponse()`: Creates a simple text stream HTTP response.
`result.pipeTextStreamToResponse()`: Writes text delta output to a Node.js response-like object.
`streamText` is using backpressure and only generates tokens as they are requested. You need to consume the stream in order for it to finish.

It also provides several promises that resolve when the stream is finished:

`result.text`: The generated text.
`result.reasoning`: The reasoning text of the model (only available for some models).
`result.sources`: Sources that have been used as input to generate the response (only available for some models).
`result.finishReason`: The reason the model finished generating text.
`result.usage`: The usage of the model during text generation.

Using the `onError` callback:

```typescript
import { streamText } from 'ai';

const result = streamText({
  model: yourModel,
  prompt: 'Invent a new holiday and describe its traditions.',
  onError({ error }) {
    console.error(error); // your error logging logic here
  },
});
```

Using the `onChunk` callback with the following chunks:

- `text-delta`
- `reasoning`
- `source`
- `tool-call`
- `tool-result`
- `tool-call-streaming-start` (when `toolCallStreaming` is enabled)
- `tool-call-delta` (when `toolCallStreaming` is enabled)

```typescript
import { streamText } from 'ai';

const result = streamText({
  model: yourModel,
  prompt: 'Invent a new holiday and describe its traditions.',
  onChunk({ chunk }) {
    // implement your own logic here, e.g.:
    if (chunk.type === 'text-delta') {
      console.log(chunk.text);
    }
  },
});
```

Using the `onFinish` callback:

```typescript
import { streamText } from 'ai';

const result = streamText({
  model: yourModel,
  prompt: 'Invent a new holiday and describe its traditions.',
  onFinish({ text, finishReason, usage, response }) {
    // your own logic, e.g. for saving the chat history or recording usage

    const messages = response.messages; // messages that were generated
  },
});
```

### Web Search

```typescript
import { openai } from '@ai-sdk/openai';
import { streamText } from 'ai';

const result = await streamText({
  model: openai.responses('gpt-4o-mini'),
  prompt: 'What happened in San Francisco last week?',
  tools: {
    web_search_preview: openai.tools.webSearchPreview(),
  },
});

// example: use textStream as an async iterable
for await (const textPart of result.textStream) {
  console.log(result.text);
}
```

### Generating Structured Data

Use the `gpt-4o` model. Include all raw data in the prompt.

```typescript
import { generateObject } from 'ai';
import { openai } from '@ai-sdk/openai';
import { z } from 'zod';

const { object } = await generateObject({
  model: openai.responses('gpt-4o'),
  schema: z.object({
    recipe: z.object({
      name: z.string(),
      ingredients: z.array(z.object({ name: z.string(), amount: z.string() })),
      steps: z.array(z.string()),
    }),
  }),
  prompt: 'Generate a lasagna recipe.',
});
```

### Persistence

Send just the user's last message and OpenAI can access the entire chat history.

```typescript
import { openai } from '@ai-sdk/openai';
import { generateText } from 'ai';

const result1 = await generateText({
  model: openai.responses('gpt-4o-mini'),
  prompt: 'Invent a new holiday and describe its traditions.',
});

const result2 = await generateText({
  model: openai.responses('gpt-4o-mini'),
  prompt: 'Summarize in 2 sentences',
  providerOptions: {
    openai: {
      previousResponseId: result1.providerMetadata?.openai.responseId as string,
    },
  },
});
```