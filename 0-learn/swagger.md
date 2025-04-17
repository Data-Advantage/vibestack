# Swagger in VibeStack

## What is Swagger?

Swagger (now known as the OpenAPI Specification) is a powerful set of tools for documenting and consuming RESTful APIs. It provides a standardized way to describe API endpoints, request parameters, responses, authentication methods, and more.

## Why Use Swagger?

- **Interactive Documentation**: Creates human-readable documentation that allows developers to test API endpoints directly from the browser
- **Code Generation**: Automatically generates client libraries in various languages
- **API Design-First Approach**: Enables designing APIs before implementation
- **Consistency**: Enforces consistent API design across your organization
- **Testing & Validation**: Simplifies API testing and request validation

## Key Components

### 1. OpenAPI Specification

The OpenAPI Specification (formerly Swagger Specification) is a JSON or YAML file that describes your API:

```yaml
openapi: 3.0.0
info:
  title: VibeStack API
  version: 1.0.0
  description: API for the VibeStack platform
paths:
  /api/users:
    get:
      summary: Get all users
      responses:
        '200':
          description: A list of users
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/User'
components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: string
        name:
          type: string
        email:
          type: string
```

### 2. Swagger UI

Swagger UI is a collection of HTML, JavaScript, and CSS assets that dynamically generate beautiful documentation from an OpenAPI Specification:

- Interactive documentation
- Request builder with a try-it-out feature
- Response visualization

### 3. Swagger Editor

Online editor that helps you design and document APIs according to the OpenAPI Specification.

## Integration with Next.js and VibeStack

### Installation

```bash
npm install swagger-ui-react swagger-jsdoc
```

### Setting Up Swagger in Your Next.js App

1. Create an API route for your Swagger documentation:

```typescript
// pages/api/docs.ts
import { NextApiRequest, NextApiResponse } from 'next';
import swaggerJsdoc from 'swagger-jsdoc';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'VibeStack API Documentation',
      version: '1.0.0',
      description: 'Documentation for the VibeStack API',
    },
    servers: [
      {
        url: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000',
        description: 'Development server',
      },
    ],
  },
  apis: ['./pages/api/**/*.ts'], // Path to the API docs
};

const specs = swaggerJsdoc(options);

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  res.status(200).json(specs);
}
```

2. Create a Swagger UI page:

```typescript
// pages/api-docs.tsx
import { useEffect, useState } from 'react';
import dynamic from 'next/dynamic';
import 'swagger-ui-react/swagger-ui.css';

const SwaggerUI = dynamic(
  () => import('swagger-ui-react').then((mod) => mod.default),
  { ssr: false }
);

export default function ApiDocs() {
  const [isClient, setIsClient] = useState(false);

  useEffect(() => {
    setIsClient(true);
  }, []);

  return (
    <div className="swagger-container">
      {isClient && <SwaggerUI url="/api/docs" />}
    </div>
  );
}
```

3. Document your API endpoints using JSDoc comments:

```typescript
// pages/api/users/index.ts

/**
 * @swagger
 * /api/users:
 *   get:
 *     summary: Returns a list of users
 *     tags: [Users]
 *     responses:
 *       200:
 *         description: List of users
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/User'
 */
export default function handler(req: NextApiRequest, res: NextApiResponse) {
  // Handler implementation
}

/**
 * @swagger
 * components:
 *   schemas:
 *     User:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *         name:
 *           type: string
 *         email:
 *           type: string
 */
```

## Best Practices

### 1. Design-First Approach

Start by designing your API with the OpenAPI specification before implementing it.

### 2. Use Tags for Grouping

Group related endpoints using tags for better organization:

```yaml
tags:
  - name: Users
    description: User management endpoints
  - name: Products
    description: Product management endpoints
```

### 3. Document Authentication

Clearly document authentication methods:

```yaml
components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
```

### 4. Provide Examples

Include request and response examples:

```yaml
paths:
  /api/users:
    post:
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UserInput'
            example:
              name: John Doe
              email: john@example.com
```

### 5. Versioning

Include version information in your API paths or headers.

## Alternative Tools and Libraries

- **SwaggerHub**: Cloud-based API design and documentation platform
- **Redoc**: Alternative to Swagger UI with a different UI design
- **Stoplight Studio**: Visual API designer with OpenAPI support
- **NestJS Swagger**: If using NestJS for your backend

## Resources

- [OpenAPI Specification](https://spec.openapis.org/oas/latest.html)
- [Swagger UI](https://swagger.io/tools/swagger-ui/)
- [Swagger Editor](https://editor.swagger.io/)
- [Swagger Tools](https://swagger.io/tools/)
- [Next-Swagger-Doc](https://github.com/jellydn/next-swagger-doc) - A library specifically designed for Next.js applications

## Troubleshooting

### Common Issues

1. **CORS Issues**: Ensure proper CORS configuration when accessing Swagger UI from a different domain
2. **Schema References Not Resolving**: Check that your schema references (`$ref`) are properly formatted
3. **UI Not Loading**: Verify that swagger-ui-react is properly imported and the CSS is included

### Performance Considerations

For large APIs, consider:
- Splitting your specification into multiple files
- Lazy loading Swagger UI only when needed
- Caching the generated OpenAPI specification

## Integration with VibeStack Architecture

When integrating Swagger with the broader VibeStack architecture:

1. Consider using an API gateway to route requests and handle authentication before they reach your API endpoints
2. Implement consistent error handling throughout your API and document error responses in your OpenAPI spec
3. Use middleware for request validation based on your OpenAPI specifications
4. Ensure your CI/CD pipeline validates your OpenAPI specification for correctness
