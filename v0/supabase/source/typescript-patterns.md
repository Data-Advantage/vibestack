# TypeScript Patterns

This document outlines TypeScript patterns and best practices for your Next.js and Supabase application.

## Type System Organization

Organize your TypeScript types in a clear hierarchical structure:

### Database Types
- Generate and maintain Supabase database types using the Supabase CLI
- Store generated types in `types/supabase.ts`
- Re-export these types from a central location for easier imports
- Update these types whenever your database schema changes

```
# Example command to generate types
npx supabase gen types typescript --project-id your-project-id --schema public,api,reference > types/supabase.ts
```

### Domain Types
- Create domain-specific type definitions that extend database types
- Add application-specific properties and methods
- Organize by domain in the `types/[domain]/` directory
- Use interfaces for extensibility where appropriate

### API Types
- Define request/response types for API endpoints
- Store in `types/api/requests.ts` and `types/api/responses.ts`
- Create consistent patterns for success and error responses
- Consider using discriminated unions for different response types

### Form Types
- Create specialized types for form state and validation
- Integrate with Zod schemas for runtime validation
- Store domain-specific form types in `types/forms/[domain].ts`
- Include field validation rules and error message types

## Type Safety Patterns

### String Literal Unions for Enums
Instead of traditional TypeScript enums, use string literal unions for better type safety:

```typescript
// Prefer this:
type UserRole = 'admin' | 'moderator' | 'user';

// Over traditional enums:
enum UserRoleEnum { Admin, Moderator, User }
```

### Type Guards
- Implement type guards for runtime type checking
- Use `is` keyword for custom type predicates
- Create domain-specific type guards for complex objects

### Utility Types
- Leverage TypeScript utility types like `Pick`, `Omit`, `Partial`, etc.
- Create custom utility types for common patterns in your application
- Use mapped types to transform existing types

## Supabase Type Integration

### Database Schema Types
- Generate TypeScript types from your Supabase database schema
- Create a central export for these types in `lib/supabase/types.ts`
- Update types regularly to keep in sync with database changes

### Query Return Types
- Define proper return types for all Supabase queries
- Use `PostgrestSingleResponse<T>` and `PostgrestResponse<T>` from Supabase
- Create helper types for common query patterns

### Row Level Security Awareness
- Design types with awareness of row-level security implications
- Include ownership and permission-related fields in entity types
- Consider creating different types for different user roles

## Form Validation with Zod

- Use Zod for runtime form validation with TypeScript integration
- Define schemas that can be used to generate TypeScript types
- Create reusable validation patterns for common fields

```typescript
// Example pattern (not code to implement):
// 1. Define schema
// 2. Extract type from schema
// 3. Use type for form state
```

## Type Organization Strategies

### File Structure
```
types/
├── supabase.ts             # Generated Supabase database types
├── api/                    # API-related types
│   ├── requests.ts         # Request types for API endpoints
│   └── responses.ts        # Response types for API endpoints
├── forms/                  # Form-related types
│   └── [domain].ts         # Domain-specific form types
└── [domain]/               # Domain-specific types
    └── index.ts            # Domain type exports
```

### Importing Patterns
- Use consistent import patterns for types
- Create barrel files (index.ts) to simplify imports
- Consider using TypeScript path aliases for cleaner imports

## Best Practices

1. **Strict Type Checking**
   - Enable `strict: true` in tsconfig.json
   - Avoid using `any` type whenever possible
   - Use `unknown` instead of `any` for values of unknown type

2. **Nullable Types**
   - Be explicit about nullable properties using union types with `null` or `undefined`
   - Use optional chaining (`?.`) and nullish coalescing (`??`) operators
   - Consider using the Maybe pattern: `type Maybe<T> = T | null | undefined`

3. **Generic Types**
   - Create reusable generic types for common patterns
   - Use constraints with `extends` to limit generic parameters
   - Leverage key remapping with `as` for sophisticated type transformations

4. **Documentation**
   - Add JSDoc comments to interfaces, types, and functions
   - Include examples in comments for complex types
   - Document edge cases and potential type limitations

5. **Type Inference**
   - Leverage TypeScript's type inference where it makes code cleaner
   - Be explicit with types for function parameters and return values
   - Use type assertions sparingly and only when necessary

By following these patterns, you'll create a type system that enhances code quality, improves developer experience, and catches errors at compile time rather than runtime.