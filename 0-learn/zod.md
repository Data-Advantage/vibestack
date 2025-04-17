# Zod

[Zod](https://zod.dev/) is a TypeScript-first schema validation library with static type inference that helps ensure data integrity in your VibeStack applications.

## Introduction to Zod

Zod provides a way to define schemas that validate and parse data at runtime while automatically generating TypeScript types. Key benefits include:

- **TypeScript Integration**: Automatic type inference from schema definitions
- **Zero Dependencies**: Lightweight with no external dependencies
- **Immutability**: All methods return new instances for safe schema composition
- **Concise API**: Intuitive, chainable methods for schema creation
- **Rich Validation**: Extensive built-in validation capabilities

## Installation & Setup

```bash
# Install Zod
npm install zod

# For TypeScript configuration (tsconfig.json)
# Ensure "strict" mode is enabled for best experience
```

## Basic Usage

### Simple Schemas

```typescript
import { z } from 'zod';

// Define a schema
const userSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(2).max(100),
  email: z.string().email(),
  age: z.number().positive().int().optional(),
  createdAt: z.date()
});

// Extract TypeScript type (no need to define interfaces separately)
type User = z.infer<typeof userSchema>;

// Validate data
function processUserData(data: unknown): User {
  // Will throw an error if validation fails
  return userSchema.parse(data);
}

// Validate data with graceful error handling
function safeProcessUserData(data: unknown) {
  const result = userSchema.safeParse(data);
  if (result.success) {
    // TypeScript knows result.data is a valid User
    return { success: true, data: result.data };
  } else {
    // Handle validation errors
    return { success: false, errors: result.error.format() };
  }
}
```

## Form Validation in VibeStack

Zod excels at form validation in Next.js applications:

```typescript
// app/actions.ts
'use server'

import { z } from 'zod';

const signupSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters')
    .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
    .regex(/[0-9]/, 'Password must contain at least one number'),
  confirmPassword: z.string()
}).refine(data => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ["confirmPassword"]
});

export async function signup(formData: FormData) {
  // Parse and validate form data
  const validatedFields = signupSchema.safeParse({
    name: formData.get('name'),
    email: formData.get('email'),
    password: formData.get('password'),
    confirmPassword: formData.get('confirmPassword')
  });

  if (!validatedFields.success) {
    // Return validation errors
    return {
      success: false,
      errors: validatedFields.error.flatten()
    };
  }

  // Proceed with signup (validated data is available in validatedFields.data)
  // ...

  return { success: true };
}
```

## Common Zod Types and Methods

### Primitive Types

```typescript
// Basic types
const stringSchema = z.string();
const numberSchema = z.number();
const booleanSchema = z.boolean();
const dateSchema = z.date();

// Optional types
const optionalString = z.string().optional(); // string | undefined
const nullableString = z.string().nullable(); // string | null
const nullishString = z.string().nullish(); // string | null | undefined

// Default values
const defaultedString = z.string().default("default value");
```

### Objects and Nested Structures

```typescript
const addressSchema = z.object({
  street: z.string(),
  city: z.string(),
  zipCode: z.string().regex(/^\d{5}$/),
  country: z.string()
});

const userWithAddressSchema = z.object({
  name: z.string(),
  email: z.string().email(),
  address: addressSchema
});

// Partial objects (all fields optional)
const partialAddressSchema = addressSchema.partial();

// Pick specific fields
const locationSchema = addressSchema.pick({ city: true, country: true });

// Omit specific fields
const streetlessAddressSchema = addressSchema.omit({ street: true });
```

### Arrays and Collections

```typescript
// Array of strings
const stringArraySchema = z.array(z.string());

// Non-empty array
const nonEmptyArraySchema = z.array(z.number()).nonempty();

// Array with specific length
const tupleSchema = z.tuple([
  z.string(), // first element must be string
  z.number(), // second element must be number
  z.boolean() // third element must be boolean
]);
```

### Unions and Enums

```typescript
// Union types
const stringOrNumber = z.union([z.string(), z.number()]);
// Shorthand
const stringOrNumber2 = z.string().or(z.number());

// Enums
const RoleEnum = z.enum(["admin", "user", "guest"]);
type Role = z.infer<typeof RoleEnum>; // "admin" | "user" | "guest"

// Native enums
enum NativeRole { ADMIN = "admin", USER = "user" }
const roleSchema = z.nativeEnum(NativeRole);
```

## Integration with Supabase

Zod can validate data coming from Supabase:

```typescript
import { createClient } from '@supabase/supabase-js';
import { z } from 'zod';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

// Define schema matching database table
const dbUserSchema = z.object({
  id: z.string().uuid(),
  created_at: z.string().transform(str => new Date(str)),
  name: z.string(),
  email: z.string().email(),
  profile_complete: z.boolean().default(false)
});

type DbUser = z.infer<typeof dbUserSchema>;

async function getUser(userId: string): Promise<DbUser | null> {
  const { data, error } = await supabase
    .from('users')
    .select('*')
    .eq('id', userId)
    .single();
  
  if (error || !data) return null;
  
  // Validate and transform data
  try {
    return dbUserSchema.parse(data);
  } catch (error) {
    console.error('Invalid user data from database:', error);
    return null;
  }
}
```

## Best Practices

1. **Define schemas close to data usage**: Keep schema definitions near where they're used
2. **Reuse schema components**: Break down complex schemas into reusable parts
3. **Use refinements for complex validations**: Go beyond simple type checking
4. **Add meaningful error messages**: Improve user experience with clear errors
5. **Transform data when appropriate**: Use `.transform()` to convert or normalize data
6. **Extract types with z.infer**: Use Zod for both validation and type definitions

## Resources

- [Zod Documentation](https://zod.dev/)
- [GitHub Repository](https://github.com/colinhacks/zod)
- [Zod with React Hook Form](https://react-hook-form.com/get-started#SchemaValidation)
- [Zod with tRPC](https://trpc.io/docs/client/react/nextjs)
- [Zod Playground](https://zod.dev/playground)
