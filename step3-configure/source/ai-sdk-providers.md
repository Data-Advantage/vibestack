# AI SDK Providers

## Language or Multi-modal Models

```
import { openai } from '@ai-sdk/openai';
import { streamText } from 'ai';
```

- xAI Grok Provider (`@ai-sdk/xai`)
  - `model: xai('grok-2')`
  - `model: xai('grok-beta')`
- OpenAI Provider (`@ai-sdk/openai`)
  - `model: openai.responses('gpt-4o')`
  - `model: openai.responses('gpt-4o-mini')`
- Azure OpenAI Provider (`@ai-sdk/azure`)
  - `model: azure('gpt-4o')`
  - `model: azure('gpt-4o-mini')`
- Anthropic Provider (`@ai-sdk/anthropic`)
  - `model: anthropic('claude-3-7-sonnet-20250219')`
  - `model: anthropic('claude-3-5-haiku-20241022')`
- Amazon Bedrock Provider (@ai`-sdk/amazon-bedrock`)
  - `model: bedrock('anthropic.claude-3-sonnet-20240229-v1:0')`
  - `model: bedrock('anthropic.claude-3-haiku-20240307-v1:0')`
- Google Generative AI Provider (`@ai-sdk/google`)
  - `model: google('gemini-2.0-pro-exp-02-05')`
  - `model: google('gemini-2.0-flash')`
  - `model: google('gemini-2.0-flash-lite')`
- Google Vertex Provider (@ai`-sdk/google-vertex`)
  - `model: vertex('gemini-2.0-pro-exp-02-05')`
  - `model: vertex('gemini-2.0-flash')`
  - `model: vertex('gemini-2.0-flash-lite')`
- Mistral Provider (`@ai-sdk/mistral`)
  - `model: mistral('mistral-large-latest')`
  - `model: mistral('mistral-small-latest')`
  - `model: mistral('pixtral-large-latest')`
- Together.ai Provider (`@ai-sdk/togetherai`)
  - `model: togetherai('mistralai/Mixtral-8x22B-Instruct-v0.1')`
  - `model: togetherai('meta-llama/Meta-Llama-3.3-70B-Instruct-Turbo')`
  - `model: togetherai('deepseek-ai/DeepSeek-V3')`
  - `model: togetherai('Qwen/Qwen2.5-72B-Instruct-Turbo')`
  - `model: togetherai('databricks/dbrx-instruct')`
- Cohere Provider (`@ai-sdk/cohere`)
  - `model: cohere('command-a-03-2025')`
  - `model: cohere('command-r-plus')`
  - `model: cohere('command-r')`
- Fireworks Provider (`@ai-sdk/fireworks`)
  - `model: fireworks('accounts/fireworks/models/deepseek-r1')`
  - `model: fireworks('accounts/fireworks/models/deepseek-v3')`
  - `model: fireworks('accounts/fireworks/models/llama-v3p1-405b-instruct')`
  - `model: fireworks('accounts/fireworks/models/llama-v3p3-70b-instruct')`
  - `model: fireworks('accounts/fireworks/models/yi-large')`
- DeepInfra Provider (`@ai-sdk/deepinfra`)
  - `model: deepinfra('meta-llama/Llama-3.3-70B-Instruct-Turbo')`
  - `model: deepinfra('meta-llama/Meta-Llama-3.1-405B-Instruct')`
- DeepSeek Provider (`@ai-sdk/deepseek`)
  - `model: deepseek('deepseek-chat')`
  - `model: deepseek('deepseek-reasoner')`
- Cerebras Provider (`@ai-sdk/cerebras`)
  - `model: cerebras('llama3.1-8b')`
  - `model: cerebras('llama3.1-70b')`
  - `model: cerebras('llama3.3-70b')`
- Groq Provider (`@ai-sdk/groq`)
  - `model: groq('gemma2-9b-it')`
  - `model: groq('llama-3.3-70b-versatile')`
  - `model: groq('llama-3.1-8b-instant')`
  - `model: groq('llama-guard-3-8b')`
  - `model: groq('deepseek-r1-distill-llama-70b')`
- Perplexity Provider (`@ai-sdk/perplexity`)
  - `model: perplexity('sonar-pro')`
  - `model: perplexity('sonar')`

## Image Generation Models

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
- Luma Provider (`@ai-sdk/luma`)
  - `model: luma.image('photon-1')`
  - `model: luma.image('photon-flash-1')`