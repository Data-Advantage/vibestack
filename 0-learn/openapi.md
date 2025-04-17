# OpenAPI

The OpenAPI Specification (formerly known as Swagger) is a standardized format for describing, producing, consuming, and visualizing RESTful APIs. In VibeStack applications, OpenAPI provides a structured approach to API documentation and integration.

## Introduction to OpenAPI

OpenAPI offers several key advantages:

- **Standardized Documentation**: A language-agnostic format for describing REST APIs
- **Machine-Readable**: Can be parsed by tools to generate code, documentation, and tests
- **Human-Readable**: Uses JSON or YAML format that's accessible to humans
- **Ecosystem Support**: Wide range of tools for validation, documentation, and code generation
- **Contract-First Development**: Enables API-first design approaches

The current version is OpenAPI 3.0, though some tools still support the legacy Swagger 2.0 format.

## Core Components of OpenAPI

An OpenAPI document consists of several key sections:

### 1. Info Section

Basic information about the API:

```yaml
openapi: 3.0.0
info:
  title: VibeStack API
  description: API for managing VibeStack resources
  version: 1.0.0
  contact:
    name: VibeStack Support
    url: https://vibestack.example.com/support
    email: support@vibestack.example.com
```

### 2. Servers

Defines server URLs for the API:

```yaml
servers:
  - url: https://api.vibestack.example.com/v1
    description: Production server
  - url: https://staging-api.vibestack.example.com/v1
    description: Staging server
  - url: http://localhost:3000/api/v1
    description: Local development
```

### 3. Paths

Endpoints and operations available in the API:

```yaml
paths:
  /users:
    get:
      summary: Retrieve a list of users
      description: Returns a paginated list of users
      parameters:
        - name: limit
          in: query
          description: Maximum number of users to return
          schema:
            type: integer
            format: int32
            minimum: 1
            maximum: 100
            default: 20
      responses:
        '200':
          description: A list of users
          content:
            application/json:
              schema:
                type: object
                properties:
                  users:
                    type: array
                    items:
                      $ref: '#/components/schemas/User'
                  pagination:
                    $ref: '#/components/schemas/Pagination'
    post:
      summary: Create a new user
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UserInput'
      responses:
        '201':
          description: User created successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
```

### 4. Components

Reusable schemas, parameters, responses, and more:

```yaml
components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: string
          format: uuid
          readOnly: true
        name:
          type: string
        email:
          type: string
          format: email
        role:
          type: string
          enum: [user, admin]
          default: user
        created_at:
          type: string
          format: date-time
          readOnly: true
      required:
        - name
        - email
    
    UserInput:
      type: object
      properties:
        name:
          type: string
          minLength: 2
          maxLength: 100
        email:
          type: string
          format: email
        role:
          type: string
          enum: [user, admin]
          default: user
      required:
        - name
        - email
    
    Pagination:
      type: object
      properties:
        total:
          type: integer
        page:
          type: integer
        limit:
          type: integer
        has_next:
          type: boolean

  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
    ApiKeyAuth:
      type: apiKey
      in: header
      name: x-api-key
```

### 5. Security

Security requirements for the API:

```yaml
security:
  - BearerAuth: []
```

## Implementing OpenAPI in VibeStack

### Generate API Documentation Endpoint

Expose your OpenAPI specification as an endpoint:

```typescript
// app/api/docs/route.ts
import { NextResponse } from 'next/server';
import openApiDocument from '@/lib/openapi/specification.json';

export function GET() {
  return NextResponse.json(openApiDocument);
}
```

### Document-Driven Development

1. **Write OpenAPI Spec First**: Define your API contract before implementation
2. **Generate Types**: Use tools to create TypeScript interfaces from schemas
3. **Validate Requests/Responses**: Ensure API calls match the specification
4. **Automated Testing**: Generate tests based on the OpenAPI document

### Organizing Large OpenAPI Documents

For complex APIs, split your specification into manageable files:

```typescript
// lib/openapi/index.ts
import { OpenAPIObject } from 'openapi3-ts';
import info from './info.json';
import servers from './servers.json';
import userPaths from './paths/users.json';
import projectPaths from './paths/projects.json';
import schemas from './schemas/index.json';
import securitySchemes from './security-schemes.json';

const openApiDocument: OpenAPIObject = {
  openapi: '3.0.0',
  info,
  servers,
  paths: {
    ...userPaths,
    ...projectPaths,
  },
  components: {
    schemas,
    securitySchemes,
  },
  security: [
    { BearerAuth: [] }
  ]
};

export default openApiDocument;
```

## Generating Types from OpenAPI

Use tools like `openapi-typescript` to generate TypeScript types:

```bash
# Install generator
npm install --save-dev openapi-typescript

# Generate types
npx openapi-typescript ./lib/openapi/specification.json -o ./lib/types/api.ts
```

Example usage:

```typescript
// lib/types/api.ts (generated)
export interface components {
  schemas: {
    User: {
      id: string;
      name: string;
      email: string;
      role?: 'user' | 'admin';
      created_at?: string;
    };
    UserInput: {
      name: string;
      email: string;
      role?: 'user' | 'admin';
    };
    // ...other schemas
  };
  // ...other components
}

// Using the generated types
import { components } from '@/lib/types/api';

type User = components['schemas']['User'];
type UserInput = components['schemas']['UserInput'];

async function createUser(userData: UserInput): Promise<User> {
  // Implementation...
}
```

## API Validation with OpenAPI

Validate request and response data against your schema:

```typescript
// lib/openapi/validation.ts
import Ajv from 'ajv';
import addFormats from 'ajv-formats';
import openApiDocument from './specification.json';

const ajv = new Ajv({ strict: false });
addFormats(ajv);

// Extract schemas from OpenAPI document
const schemas = openApiDocument.components.schemas;

// Compile validators for each schema
const validators = Object.fromEntries(
  Object.entries(schemas).map(([name, schema]) => [
    name,
    ajv.compile(schema)
  ])
);

// Validate data against a schema
export function validate(schemaName: string, data: unknown) {
  const validator = validators[schemaName];
  if (!validator) {
    throw new Error(`Schema ${schemaName} not found`);
  }
  
  const valid = validator(data);
  return { 
    valid, 
    errors: validator.errors 
  };
}
```

Usage in an API route:

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { validate } from '@/lib/openapi/validation';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    
    // Validate request body against OpenAPI schema
    const validation = validate('UserInput', body);
    
    if (!validation.valid) {
      return NextResponse.json(
        { 
          error: 'Validation failed', 
          details: validation.errors 
        }, 
        { status: 400 }
      );
    }
    
    // Process validated data
    // ...
    
    return NextResponse.json({ success: true }, { status: 201 });
  } catch (error) {
    return NextResponse.json({ error: 'Bad request' }, { status: 400 });
  }
}
```

## Swagger UI Integration

Provide interactive documentation using Swagger UI:

```typescript
// app/api/swagger/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { readFileSync } from 'fs';
import path from 'path';

export function GET(request: NextRequest) {
  const url = new URL(request.url);
  const htmlPath = path.join(process.cwd(), 'public', 'swagger-ui', 'index.html');
  let html = readFileSync(htmlPath, 'utf-8');
  
  // Replace placeholder with actual URL to OpenAPI document
  const apiUrl = `${url.protocol}//${url.host}/api/docs`;
  html = html.replace('__OPENAPI_URL__', apiUrl);
  
  return new NextResponse(html, {
    headers: {
      'Content-Type': 'text/html',
    },
  });
}
```

Setup in `public/swagger-ui/index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>VibeStack API Documentation</title>
  <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@5.1.0/swagger-ui.css">
  <style>
    body { margin: 0; }
    .swagger-ui .topbar { display: none; }
  </style>
</head>
<body>
  <div id="swagger-ui"></div>
  
  <script src="https://unpkg.com/swagger-ui-dist@5.1.0/swagger-ui-bundle.js"></script>
  <script>
    window.onload = function() {
      window.ui = SwaggerUIBundle({
        url: "__OPENAPI_URL__",
        dom_id: '#swagger-ui',
        deepLinking: true,
        presets: [
          SwaggerUIBundle.presets.apis,
          SwaggerUIBundle.SwaggerUIStandalonePreset
        ],
        layout: "BaseLayout",
        withCredentials: true,
      });
    };
  </script>
</body>
</html>
```

## Request Parameters

Document different parameter types:

```yaml
paths:
  /projects/{id}:
    get:
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            format: uuid
          description: Project unique identifier
        - name: include
          in: query
          schema:
            type: array
            items:
              type: string
              enum: [members, tasks, comments]
          style: form
          explode: false
          description: Related resources to include
        - name: x-request-id
          in: header
          schema:
            type: string
            format: uuid
          description: Request ID for tracing
      responses:
        '200':
          description: Project details
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Project'
```

## Authentication & Authorization

Define security schemes and requirements:

```yaml
components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: JWT token obtained from the /login endpoint
    ApiKeyAuth:
      type: apiKey
      in: header
      name: x-api-key
      description: API key for external service integration

paths:
  /public-data:
    get:
      security: []  # No auth required
      responses:
        '200':
          description: Publicly available data
  
  /users/me:
    get:
      security:
        - BearerAuth: []  # JWT auth required
      responses:
        '200':
          description: Current user information
  
  /webhooks:
    post:
      security:
        - ApiKeyAuth: []  # API key required
      responses:
        '200':
          description: Webhook received
```

## Best Practices

1. **Keep Schemas DRY**: Use `$ref` to reuse schema components
2. **Document Examples**: Provide realistic example values for faster comprehension
3. **Use Semantic Versioning**: Clearly indicate API versions
4. **Include Error Responses**: Document all possible error responses
5. **Add Descriptions**: Provide clear descriptions for all paths, parameters, and schemas
6. **Authentication**: Clearly document security requirements
7. **Tag Operations**: Organize endpoints logically with tags

## Common Patterns

### Pagination

```yaml
components:
  parameters:
    Pagination:
      in: query
      name: pagination
      schema:
        type: object
        properties:
          page:
            type: integer
            minimum: 1
            default: 1
          limit:
            type: integer
            minimum: 1
            maximum: 100
            default: 20
  schemas:
    PaginatedResponse:
      type: object
      properties:
        data:
          type: array
          items:
            type: object
        pagination:
          type: object
          properties:
            total:
              type: integer
            page:
              type: integer
            limit:
              type: integer
            totalPages:
              type: integer
```

### Filtering and Sorting

```yaml
paths:
  /products:
    get:
      parameters:
        - name: category
          in: query
          schema:
            type: string
        - name: min_price
          in: query
          schema:
            type: number
            format: float
        - name: max_price
          in: query
          schema:
            type: number
            format: float
        - name: sort_by
          in: query
          schema:
            type: string
            enum: [price, name, created_at]
            default: created_at
        - name: sort_order
          in: query
          schema:
            type: string
            enum: [asc, desc]
            default: desc
```

## Resources

- [OpenAPI Specification](https://spec.openapis.org/oas/latest.html)
- [Swagger Editor](https://editor.swagger.io/)
- [Swagger UI](https://swagger.io/tools/swagger-ui/)
- [OpenAPI Tools](https://openapi.tools/)
- [OpenAPI Generator](https://github.com/OpenAPITools/openapi-generator)
- [openapi-typescript](https://github.com/drwpow/openapi-typescript)
