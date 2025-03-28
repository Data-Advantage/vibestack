# Step 1: Create a Project in OpenAI Platform

Get an OpenAI API Secret Key and install into the Project Environment Variables as `OPENAI_API_KEY`.

# Step 2: Create the Assistant in Open AI Platform

Configure the entire assistant, create any filestores and tools and store the `ASSISTANT_ID` environment variable in the Project Environment Variables.

# Step 3: Create a route.ts for api/assistant:

This will create a server that communicates with the OpenAI Assistant API.

```typescript
import { AssistantResponse } from 'ai';
import OpenAI from 'openai';

console.log('Server OpenAI API Key (remove this soon):', process.env.OPENAI_API_KEY2)

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY2 || '',
});

// Allow streaming responses up to 30 seconds
export const maxDuration = 30;

export async function POST(req: Request) {
  console.log('Assistant API called');
  
  // Parse the request body
  const input: {
    threadId: string | null;
    message: string;
  } = await req.json();
  
  console.log('Request payload:', input);

  // Create a thread if needed
  const threadId = input.threadId ?? (await openai.beta.threads.create({})).id;
  console.log('Using thread ID:', threadId);

  // Add a message to the thread
  const createdMessage = await openai.beta.threads.messages.create(threadId, {
    role: 'user',
    content: input.message,
  });
  console.log('Created message:', createdMessage.id);

  return AssistantResponse(
    { threadId, messageId: createdMessage.id },
    async ({ forwardStream, sendDataMessage }) => {
      console.log('Starting assistant run on thread:', threadId);
      
      // Run the assistant on the thread
      const runStream = openai.beta.threads.runs.stream(threadId, {
        assistant_id:
          process.env.ASSISTANT_ID ??
          (() => {
            throw new Error('ASSISTANT_ID is not set');
          })(),
      });

      // forward run status would stream message deltas
      let runResult = await forwardStream(runStream);
      console.log('Run status:', runResult?.status);

      // status can be: queued, in_progress, requires_action, cancelling, cancelled, failed, completed, or expired
      while (
        runResult?.status === 'requires_action' &&
        runResult.required_action?.type === 'submit_tool_outputs'
      ) {
        console.log('Action required:', runResult.required_action.submit_tool_outputs.tool_calls);
        
        const tool_outputs =
          runResult.required_action.submit_tool_outputs.tool_calls.map(
            (toolCall: any) => {
              const parameters = JSON.parse(toolCall.function.arguments);
              console.log('Tool call:', toolCall.function.name, parameters);

              switch (toolCall.function.name) {
                // configure your tool calls here

                default:
                  throw new Error(
                    `Unknown tool call function: ${toolCall.function.name}`,
                  );
              }
            },
          );

        runResult = await forwardStream(
          openai.beta.threads.runs.submitToolOutputsStream(
            threadId,
            runResult.id,
            { tool_outputs },
          ),
        );
        console.log('Tool outputs submitted, new status:', runResult?.status);
      }
      
      console.log('Assistant run completed with status:', runResult?.status);
      
      // After the run completes, we need to fetch the assistant's messages
      if (runResult?.status === 'completed') {
        // Get the latest assistant message
        const messages = await openai.beta.threads.messages.list(threadId, {
          order: 'desc',
          limit: 1,
        });
        
        const latestMessage = messages.data[0];
        if (latestMessage && latestMessage.role === 'assistant') {
          console.log('Retrieved assistant response (full object):', latestMessage.id);
          
          // Process annotations if they exist
          if (latestMessage.content[0].type === 'text' && latestMessage.content[0].text.annotations.length > 0) {
            const annotations = latestMessage.content[0].text.annotations;
            console.log('Processing annotations:', annotations);
            
            try {
              // Process annotations and create citation references
              const citations: string[] = [];
              
              for (let i = 0; i < annotations.length; i++) {
                const annotation = annotations[i];
                
                // Handle file citations
                if ('file_citation' in annotation) {
                  try {
                    // Retrieve the file information
                    const fileInfo = await openai.files.retrieve(annotation.file_citation.file_id);
                    citations.push(`[${i+1}] ${annotation.text}: ${fileInfo.filename}`);
                  } catch (error) {
                    console.error('Error retrieving file:', error);
                    citations.push(`[${i+1}] ${annotation.text}: Reference to file ${annotation.file_citation.file_id}`);
                  }
                }
                
                // Handle file paths
                if ('file_path' in annotation) {
                  citations.push(`[${i+1}] ${annotation.text}: File ${annotation.file_path.file_id}`);
                }
              }
              
              // If we have any citations, send them to the client
              if (citations.length > 0) {
                await sendDataMessage({
                  role: 'data',
                  data: {
                    type: 'citations',
                    citations: citations
                  }
                });
                console.log('Sent citations to client:', citations);
              }
            } catch (error) {
              console.error('Error processing annotations:', error);
            }
          }
        } else {
          console.error('No assistant message found after completed run');
        }
      } else if (runResult?.status === 'failed') {
        console.error('Run failed:', runResult.last_error);
      }
    },
  );
}
```

# Step 4: Create a web Assistant that users can interact with.

```
'use client';

import { Message, useAssistant } from '@ai-sdk/react';
import { Inter } from 'next/font/google';
import { useTheme } from 'next-themes';
import { useState, useEffect } from 'react';
import { 
  Send, 
  Loader2, 
  Plus, 
  StopCircle, 
  Bot, 
  User,
  FileText
} from 'lucide-react';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { 
  Card, 
  CardContent 
} from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";

const inter = Inter({ subsets: ['latin'] });

// Interface for citations
interface Citation {
  messageId: string;
  citations: string[];
}

export default function Chat() {
  const { resolvedTheme, setTheme } = useTheme();
  const [citations, setCitations] = useState<Citation[]>([]);
  
  const { 
    status, 
    messages, 
    input, 
    submitMessage, 
    handleInputChange,
    threadId,
    setThreadId,
    error,
    stop
  } = useAssistant({ 
    api: '/api/assistant',
    onError: (err) => console.error('Assistant error:', err),
    onDataMessage: (message) => {
      console.log('Data message received:', message);
      
      // Handle citation data messages
      if (message.data?.type === 'citations') {
        setCitations(prev => [...prev, {
          messageId: message.id,
          citations: message.data.citations
        }]);
      }
    }
  });

  // Reset citations when starting a new thread
  useEffect(() => {
    if (!threadId) {
      setCitations([]);
    }
  }, [threadId]);

  // Wrap submitMessage to add logging
  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    console.log('Submitting user input:', input);
    submitMessage(e);
  };

  // Get citations for a specific message
  const getCitationsForMessage = (messageId: string) => {
    return citations.find(c => c.messageId === messageId)?.citations || [];
  };

  return (
    <div className={`min-h-screen flex flex-col ${inter.className}`}>
      {/* Header with theme toggle */}
      <header className="border-b py-4 px-6 flex justify-between items-center backdrop-blur-md bg-white/50 dark:bg-black/50 sticky top-0 z-10">
        <h1 className="text-xl font-semibold">AI Assistant</h1>
        <div className="flex items-center gap-2">
          <Label htmlFor="theme-mode">Dark Mode</Label>
          <Switch 
            id="theme-mode" 
            checked={resolvedTheme === 'dark'}
            onCheckedChange={() => setTheme(resolvedTheme === 'dark' ? 'light' : 'dark')}
          />
        </div>
      </header>

      <main className="flex-1 p-4 max-w-4xl w-full mx-auto">
        {/* Thread info */}
        {threadId && (
          <div className="mb-4 text-sm text-neutral-500 dark:text-neutral-400 flex items-center">
            <span>Thread: {threadId.substring(0, 8)}...</span>
            <Button 
              variant="outline" 
              size="sm" 
              onClick={() => setThreadId(undefined)}
              className="ml-2"
            >
              <Plus className="mr-2 h-3 w-3" />
              New Conversation
            </Button>
          </div>
        )}

        {/* Messages */}
        <div className="space-y-4 mb-4 overflow-auto">
          {messages.map((m: Message) => {
            const messageCitations = getCitationsForMessage(m.id);
            const hasCitations = messageCitations.length > 0;
            
            return (
              <Card key={m.id} className="overflow-hidden">
                <div className={`py-2 px-4 font-medium flex items-center gap-2 
                  ${m.role === 'user' 
                    ? 'bg-blue-100 dark:bg-blue-950 text-blue-800 dark:text-blue-300' 
                    : m.role === 'assistant' 
                      ? 'bg-emerald-100 dark:bg-emerald-950 text-emerald-800 dark:text-emerald-300' 
                      : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-800 dark:text-neutral-300'
                  }`}>
                  {m.role === 'user' && <User className="h-4 w-4" />}
                  {m.role === 'assistant' && <Bot className="h-4 w-4" />}
                  {m.role.charAt(0).toUpperCase() + m.role.slice(1)}
                  {hasCitations && (
                    <span className="ml-auto flex items-center text-xs">
                      <FileText className="h-3 w-3 mr-1" />
                      {messageCitations.length} citations
                    </span>
                  )}
                </div>
                <CardContent className="p-4">
                  {m.role === 'assistant' ? (
                    <div className="whitespace-pre-wrap">{m.content}</div>
                  ) : (
                    m.content
                  )}
                  {m.role === 'data' && (
                    <pre className="mt-2 p-2 rounded bg-neutral-100 dark:bg-neutral-800 overflow-auto text-xs">
                      {JSON.stringify(m.data, null, 2)}
                    </pre>
                  )}
                  
                  {/* Display citations if available */}
                  {hasCitations && (
                    <div className="mt-4 pt-4 border-t text-sm">
                      <h4 className="font-medium mb-2 flex items-center gap-1">
                        <FileText className="h-4 w-4" /> Citations
                      </h4>
                      <ul className="list-none space-y-2">
                        {messageCitations.map((citation, index) => (
                          <li key={index} className="text-neutral-700 dark:text-neutral-300">
                            {citation}
                          </li>
                        ))}
                      </ul>
                    </div>
                  )}
                </CardContent>
              </Card>
            );
          })}
        </div>

        {/* Error display */}
        {error && (
          <Card className="mb-4 bg-red-50 dark:bg-red-950 border-red-200 dark:border-red-800">
            <CardContent className="p-3 text-red-700 dark:text-red-300">
              Error: {error.message}
            </CardContent>
          </Card>
        )}

        {/* Assistant thinking indicator */}
        {status === 'in_progress' && (
          <div className="p-3 mb-4 flex justify-between items-center rounded-lg bg-neutral-50 dark:bg-neutral-900">
            <div className="flex items-center gap-2">
              <Loader2 className="h-4 w-4 animate-spin" />
              <span>Assistant is thinking...</span>
            </div>
            <Button 
              variant="outline" 
              size="sm" 
              onClick={stop} 
              className="text-red-500 hover:text-red-700 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-950"
            >
              <StopCircle className="mr-2 h-3 w-3" />
              Stop
            </Button>
          </div>
        )}

        {/* Input form */}
        <form onSubmit={handleSubmit} className="flex gap-2">
          <Input
            disabled={status !== 'awaiting_message'}
            value={input}
            placeholder="Ask something..."
            onChange={handleInputChange}
            className="flex-1"
          />
          <Button 
            type="submit" 
            disabled={status !== 'awaiting_message' || !input.trim()}
            className="transition-all"
          >
            <Send className="mr-2 h-4 w-4" />
            Send
          </Button>
        </form>
      </main>
    </div>
  );
}
```