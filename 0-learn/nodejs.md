# Node.js

[Node.js](https://nodejs.org/) is a JavaScript runtime built on Chrome's V8 JavaScript engine that allows you to run JavaScript on the server-side and is a foundational technology for VibeStack applications.

## Introduction to Node.js

Node.js enables building scalable network applications with an event-driven, non-blocking I/O model that makes it efficient and lightweight. Key features include:

- **JavaScript Everywhere**: Use the same language for front-end and back-end
- **Asynchronous & Event-Driven**: Non-blocking operations for enhanced performance
- **Single-Threaded**: Event loop handles concurrency through callbacks
- **Cross-Platform**: Runs on Windows, macOS, and Linux
- **Large Ecosystem**: Vast library of open-source packages via npm

## Installation & Setup

For VibeStack development, it's recommended to use the latest LTS (Long Term Support) version:

```bash
# Using Node Version Manager (nvm) - recommended
nvm install --lts
nvm use --lts

# Or download directly from nodejs.org
# https://nodejs.org/en/download/
```

Verify your installation:

```bash
node --version
npm --version
```

## Core Concepts

### The Event Loop

Node.js operates on a single-threaded event loop model, which efficiently processes asynchronous operations through:

1. **Event Queue**: Operations are queued and processed sequentially
2. **Non-Blocking I/O**: File operations, network requests, etc. don't block execution
3. **Callbacks**: Functions executed after operations complete
4. **Promises & Async/Await**: Modern patterns for handling asynchronous code

### CommonJS Modules

Traditional Node.js module system:

```javascript
// Exporting in moduleA.js
const myFunction = () => console.log('Hello from moduleA');
module.exports = { myFunction };

// Importing in another file
const { myFunction } = require('./moduleA');
myFunction(); // "Hello from moduleA"
```

### ES Modules

Modern JavaScript module system (supported in newer Node.js versions):

```javascript
// Exporting in moduleB.js
export const myFunction = () => console.log('Hello from moduleB');

// Importing in another file
import { myFunction } from './moduleB.js';
myFunction(); // "Hello from moduleB"
```

## Node.js in VibeStack

Within the VibeStack architecture, Node.js serves several crucial roles:

1. **Next.js Server Runtime**: Powers server-side rendering and API routes
2. **Build System**: Compiles and bundles application assets
3. **Development Server**: Provides hot-reloading during development
4. **Serverless Functions**: Runs on-demand functions in production
5. **Script Execution**: Powers development workflows and utilities

## Working with Files

Node.js provides powerful APIs for file system operations:

```javascript
const fs = require('fs');
const path = require('path');

// Reading files
const content = fs.readFileSync(path.join(__dirname, 'file.txt'), 'utf8');

// Writing files
fs.writeFileSync(path.join(__dirname, 'output.txt'), 'Content to write');

// Asynchronous alternatives
fs.readFile(path.join(__dirname, 'file.txt'), 'utf8', (err, data) => {
  if (err) throw err;
  console.log(data);
});

// Promises API (modern)
const fsPromises = require('fs/promises');

async function readAndWriteFiles() {
  try {
    const content = await fsPromises.readFile(path.join(__dirname, 'file.txt'), 'utf8');
    await fsPromises.writeFile(path.join(__dirname, 'output.txt'), content.toUpperCase());
  } catch (error) {
    console.error('Error handling files:', error);
  }
}
```

## HTTP Server Basics

Creating a simple HTTP server with Node.js:

```javascript
const http = require('http');

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end('Hello World');
});

server.listen(3000, '127.0.0.1', () => {
  console.log('Server running at http://127.0.0.1:3000/');
});
```

## Environment Variables

Managing configuration with environment variables:

```javascript
// Access environment variables
const port = process.env.PORT || 3000;
const nodeEnv = process.env.NODE_ENV || 'development';

console.log(`Running in ${nodeEnv} mode on port ${port}`);

// In VibeStack projects, environment variables are typically
// loaded from .env files using dotenv or Next.js built-in support
```

## Common Node.js Patterns

### Error Handling

```javascript
// Try/catch with async/await
async function fetchData() {
  try {
    const result = await someAsyncOperation();
    return result;
  } catch (error) {
    console.error('Error fetching data:', error);
    // Handle specific errors or rethrow
    throw error;
  }
}

// Error-first callbacks
function traditionalNodeCallback(err, data) {
  if (err) {
    return console.error('An error occurred:', err);
  }
  
  console.log('Operation completed successfully:', data);
}
```

### Streams

For efficiently handling large data:

```javascript
const fs = require('fs');

// Reading a large file as a stream
const readStream = fs.createReadStream('large-file.txt');
const writeStream = fs.createWriteStream('output-file.txt');

readStream.pipe(writeStream);

readStream.on('error', (error) => console.error('Read error:', error));
writeStream.on('error', (error) => console.error('Write error:', error));
writeStream.on('finish', () => console.log('File processing completed'));
```

## Resources

- [Node.js Official Documentation](https://nodejs.org/en/docs/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [MDN JavaScript Reference](https://developer.mozilla.org/en-US/docs/Web/JavaScript)
- [Next.js with Node.js](https://nextjs.org/docs/pages/building-your-application/upgrading/from-nodejs)
