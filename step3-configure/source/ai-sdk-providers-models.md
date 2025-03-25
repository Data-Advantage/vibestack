# AI SDK Providers

```
import { openai } from '@ai-sdk/openai';
import { streamText } from 'ai';
```

- xAI Grok Provider (`@ai-sdk/xai`)
- OpenAI Provider (`@ai-sdk/openai`)
- Azure OpenAI Provider (`@ai-sdk/azure`)
- Anthropic Provider (`@ai-sdk/anthropic`)
- Amazon Bedrock Provider (@ai`-sdk/amazon-bedrock`)
- Google Generative AI Provider (`@ai-sdk/google`)
- Google Vertex Provider (@ai`-sdk/google-vertex`)
- Mistral Provider (`@ai-sdk/mistral`)
- Together.ai Provider (`@ai-sdk/togetherai`)
- Cohere Provider (`@ai-sdk/cohere`)
- Fireworks Provider (`@ai-sdk/fireworks`)
- DeepInfra Provider (`@ai-sdk/deepinfra`)
- DeepSeek Provider (`@ai-sdk/deepseek`)
- Cerebras Provider (`@ai-sdk/cerebras`)
- Groq Provider (`@ai-sdk/groq`)
- Perplexity Provider (`@ai-sdk/perplexity`)

# Image Generation

```
import { experimental_generateImage as generateImage } from 'ai';
import { replicate } from '@ai-sdk/replicate';

const { image } = await generateImage({
  model: replicate.image('black-forest-labs/flux-1.1-pro-ultra'),
  prompt: 'A futuristic cityscape at sunset',
});
```

- OpenAI Provider (`@ai-sdk/openai`)
  - `model = openai.image('dall-e-3')`
- Google Generative AI Provider (`@ai-sdk/google`)
  - `model = google('gemini-2.0-flash-exp-image-generation')` with the `responseModalities` option:
```
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
- Google Vertex Provider (`@ai-sdk/google-vertex`)
  - `model: vertex.image('imagen-3.0-generate-001')`
  - `model: vertex.image('imagen-3.0-fast-generate-001')`
- Replicate Provider (`@ai-sdk/replicate`)
  - `model: replicate.image('black-forest-labs/flux-1.1-pro-ultra')`
  - `model: replicate.image('black-forest-labs/flux-1.1-pro-ultra')`
  - `model: replicate.image('black-forest-labs/flux-1.1-pro')`
  - `model: replicate.image('black-forest-labs/flux-dev')`
  - `model: replicate.image('black-forest-labs/flux-pro')`
  - `model: replicate.image('black-forest-labs/flux-schnell')`
  - `model: replicate.image('ideogram-ai/ideogram-v2-turbo')`
  - `model: replicate.image('ideogram-ai/ideogram-v2')`
  - `model: replicate.image('luma/photon-flash')`
  - `model: replicate.image('luma/photon')`
  - `model: replicate.image('recraft-ai/recraft-v3-svg')`
  - `model: replicate.image('recraft-ai/recraft-v3')`
  - `model: replicate.image('stability-ai/stable-diffusion-3.5-large-turbo')`
  - `model: replicate.image('stability-ai/stable-diffusion-3.5-large')`
  - `model: replicate.image('stability-ai/stable-diffusion-3.5-medium')`
- Fireworks Provider (`@ai-sdk/fireworks`)
  - `model: fireworks.image('accounts/fireworks/models/playground-v2-5-1024px-aesthetic')`
  - `model: fireworks.image('accounts/fireworks/models/SSD-1B')`
  - `model: fireworks.image('accounts/fireworks/models/stable-diffusion-xl-1024-v1-0')`
- Fal Provider (`@ai-sdk/fal`)
  - `model: fal.image('fal-ai/fast-sdxl')`
  - `model: fal.image('fal-ai/flux-lora')`
  - `model: fal.image('fal-ai/flux-pro/v1.1-ultra')`
  - `model: fal.image('fal-ai/ideogram/v2')`
  - `model: fal.image('fal-ai/recraft-v3')`
  - `model: fal.image('fal-ai/stable-diffusion-3.5-large')`
  - `model: fal.image('fal-ai/hyper-sdxl')`
- Together.ai Provider (`@ai-sdk/togetherai`)
  - `model: togetherai.image('stabilityai/stable-diffusion-xl-base-1.0')`
  - `model: togetherai.image('black-forest-labs/FLUX.1-dev')`
  - `model: togetherai.image('black-forest-labs/FLUX.1-dev-lora')`
  - `model: togetherai.image('black-forest-labs/FLUX.1-schnell')`
  - `model: togetherai.image('black-forest-labs/FLUX.1-canny')`
  - `model: togetherai.image('black-forest-labs/FLUX.1-depth')`
  - `model: togetherai.image('black-forest-labs/FLUX.1-redux')`
  - `model: togetherai.image('black-forest-labs/FLUX.1.1-pro')`
  - `model: togetherai.image('black-forest-labs/FLUX.1-pro')`
  - `model: togetherai.image('black-forest-labs/FLUX.1-schnell-Free')`
- xAI Grok Provider (`@ai-sdk/xai`)
  - `model: xai.image('grok-2-image')`