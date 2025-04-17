# JSON in VibeStack

JSON (JavaScript Object Notation) is a lightweight data-interchange format that's easy for humans to read and write and easy for machines to parse and generate. In VibeStack, JSON is used extensively for configuration, API communication, data storage, and more.

## What is JSON?

JSON is a text-based data format that uses human-readable syntax to store and transmit structured data. It was derived from JavaScript but is language-independent, making it ideal for data interchange between different programming languages and systems.

Key characteristics:
- **Lightweight**: Minimal syntax with simple rules
- **Text-based**: Uses plain text, making it easy to read and edit
- **Self-describing**: Data objects contain field names alongside values
- **Language-independent**: Can be used with virtually any programming language

## JSON Syntax

### Basic Structure

JSON data is built on two structures:
- A collection of name/value pairs (objects)
- An ordered list of values (arrays)

### JSON Objects

Objects are enclosed in curly braces `{}` and contain key-value pairs separated by commas:

```json
{
  "name": "John Doe",
  "age": 30,
  "isActive": true,
  "address": {
    "street": "123 Main St",
    "city": "Anytown",
    "zipCode": "12345"
  }
}
```

### JSON Arrays

Arrays are enclosed in square brackets `[]` and contain values separated by commas:

```json
[
  "apple",
  "banana",
  "orange"
]
```

Arrays can also contain objects:

```json
[
  {
    "id": 1,
    "name": "Product A",
    "price": 19.99
  },
  {
    "id": 2,
    "name": "Product B",
    "price": 29.99
  }
]
```

### Data Types

JSON supports the following data types:

- **String**: Text enclosed in double quotes `"Hello, world!"`
- **Number**: Integer or floating-point numbers without quotes `42` or `3.14159`
- **Boolean**: `true` or `false` (without quotes)
- **Object**: Collection of key-value pairs `{"key": "value"}`
- **Array**: Ordered list of values `[1, 2, 3]`
- **null**: Represents no value `null`

Example with multiple data types:

```json
{
  "name": "Jane Smith",
  "age": 28,
  "isMarried": false,
  "hobbies": ["reading", "hiking", "photography"],
  "address": {
    "street": "456 Oak Avenue",
    "city": "Metropolis",
    "zipCode": "54321"
  },
  "phoneNumber": null
}
```

## JSON vs. JavaScript Objects

While JSON syntax looks similar to JavaScript object literals, there are important differences:

1. **Keys must be strings** in JSON and require double quotes
2. **No functions** or methods allowed in JSON
3. **No comments** allowed in JSON
4. **No trailing commas** allowed in JSON
5. **No undefined value** in JSON (use `null` instead)

## Working with JSON in TypeScript/JavaScript

### Parsing JSON

Convert a JSON string to a JavaScript object:

```typescript
// Parse JSON string to object
const jsonString = '{"name": "Alice", "age": 25}';
const data = JSON.parse(jsonString);

console.log(data.name); // Output: Alice
console.log(data.age);  // Output: 25
```

### Stringifying JavaScript Objects

Convert a JavaScript object to a JSON string:

```typescript
// Convert object to JSON string
const user = {
  name: "Bob",
  age: 30,
  isActive: true
};

const jsonString = JSON.stringify(user);
console.log(jsonString); // Output: {"name":"Bob","age":30,"isActive":true}

// Pretty print with indentation
const prettyJson = JSON.stringify(user, null, 2);
console.log(prettyJson);
// Output:
// {
//   "name": "Bob",
//   "age": 30,
//   "isActive": true
// }
```

## JSON in VibeStack Applications

### API Requests and Responses

In VibeStack, JSON is the standard format for API communication:

```typescript
// Making a POST request with JSON data
async function createUser(userData: User) {
  const response = await fetch('/api/users', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(userData)
  });
  
  return response.json(); // Parse JSON response
}

// Usage
const newUser = await createUser({
  name: 'Charlie',
  email: 'charlie@example.com'
});
```

### Configuration Files

JSON is commonly used for configuration files in VibeStack projects:

```json
// example-config.json
{
  "apiEndpoint": "https://api.example.com/v1",
  "defaultTheme": "light",
  "features": {
    "darkMode": true,
    "multiLanguage": false
  },
  "limits": {
    "maxUploadSize": 5242880,
    "maxItemsPerPage": 50
  }
}
```

Loading the configuration:

```typescript
import config from './example-config.json';

function initializeApp() {
  console.log(`Connecting to API: ${config.apiEndpoint}`);
  // Application initialization code
}
```

### Database Storage

JSON data can be stored in PostgreSQL using the JSONB type in Supabase:

```typescript
// Example of storing JSON data in Supabase
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

async function saveUserPreferences(userId: string, preferences: object) {
  const { data, error } = await supabase
    .from('user_settings')
    .upsert({
      user_id: userId,
      preferences: preferences // Stored as JSONB in PostgreSQL
    });
    
  if (error) throw error;
  return data;
}

// Later, query for specific JSON properties
async function getUsersWithDarkMode() {
  const { data, error } = await supabase
    .from('user_settings')
    .select('user_id, preferences')
    .contains('preferences', { darkMode: true });
    
  if (error) throw error;
  return data;
}
```

## Type-Safe JSON with TypeScript

Define types for your JSON data to gain type safety:

```typescript
// Define interfaces for type checking
interface UserProfile {
  id: string;
  displayName: string;
  email: string;
  preferences: {
    theme: 'light' | 'dark' | 'system';
    notifications: boolean;
    language: string;
  };
  metadata?: Record<string, unknown>;
}

// Parse JSON with type assertion
function loadUserProfile(jsonString: string): UserProfile {
  return JSON.parse(jsonString) as UserProfile;
}

// Use the typed data
const profileJson = '{"id":"123","displayName":"DevUser","email":"dev@example.com","preferences":{"theme":"dark","notifications":true,"language":"en"}}';
const profile = loadUserProfile(profileJson);

console.log(profile.preferences.theme); // TypeScript knows this is 'light' | 'dark' | 'system'
```

## JSON Schema

JSON Schema is a vocabulary that allows you to validate JSON documents:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Product",
  "type": "object",
  "required": ["id", "name", "price"],
  "properties": {
    "id": {
      "type": "integer",
      "description": "The product identifier"
    },
    "name": {
      "type": "string",
      "description": "Name of the product"
    },
    "price": {
      "type": "number",
      "minimum": 0,
      "exclusiveMinimum": true
    },
    "tags": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "uniqueItems": true
    }
  }
}
```

Using JSON Schema for validation in TypeScript:

```typescript
import Ajv from 'ajv';
import productSchema from './product-schema.json';

const ajv = new Ajv();
const validate = ajv.compile(productSchema);

function validateProduct(data: unknown) {
  const valid = validate(data);
  if (!valid) {
    throw new Error(`Invalid product data: ${ajv.errorsText(validate.errors)}`);
  }
  return data;
}

// Usage
try {
  const product = validateProduct({
    id: 101,
    name: "Keyboard",
    price: 49.99,
    tags: ["electronics", "computer"]
  });
  // Process valid product
} catch (error) {
  console.error(error);
}
```

## Common JSON Patterns in VibeStack

### Configuration Objects

```json
{
  "environment": "production",
  "logging": {
    "level": "error",
    "format": "json",
    "destination": "stdout"
  },
  "database": {
    "host": "db.example.com",
    "port": 5432,
    "ssl": true
  }
}
```

### API Responses

```json
{
  "data": [...],
  "meta": {
    "page": 1,
    "perPage": 20,
    "total": 157,
    "totalPages": 8
  },
  "links": {
    "self": "/api/resources?page=1",
    "next": "/api/resources?page=2",
    "prev": null
  }
}
```

### Error Objects

```json
{
  "error": {
    "code": "AUTH_REQUIRED",
    "message": "Authentication is required to access this resource",
    "details": {
      "requiredScope": "read:users"
    }
  }
}
```

## Best Practices

1. **Validate JSON data**: Always validate JSON input before processing it
2. **Use consistent naming conventions**: Either camelCase or snake_case, but be consistent
3. **Keep it simple**: Avoid deeply nested structures where possible
4. **Include version information**: For configuration and schema files
5. **Provide useful error messages**: When JSON parsing or validation fails
6. **Be careful with floating-point numbers**: JSON doesn't guarantee precision
7. **Secure sensitive data**: Never include passwords or tokens in client-side JSON
8. **Handle large JSON efficiently**: Use streaming parsers for very large JSON files

## Tools for Working with JSON

- **JSON Formatter & Validator**: Online tools for formatting and validating JSON
- **VS Code JSON Tools**: Built-in JSON validation and formatting
- **Postman**: Testing API requests and responses with JSON
- **JSONLint**: Online JSON validator
- **JSON Schema Validator**: Validate JSON against a schema
- **TypeScript**: For type-safe JSON handling
- **Zod**: Runtime validation library for TypeScript

## Resources

- [JSON.org](https://www.json.org/): Official JSON website
- [MDN Web Docs: JSON](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON)
- [JSON Schema](https://json-schema.org/): The home of JSON Schema
- [TypeScript Documentation](https://www.typescriptlang.org/docs/): For type-safe JSON handling
- [Ajv Validator](https://ajv.js.org/): JSON Schema validator for JavaScript
