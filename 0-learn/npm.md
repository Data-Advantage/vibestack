# npm (Node Package Manager)

[npm](https://www.npmjs.com/) is the default package manager for Node.js, enabling developers to install, share, and manage dependencies in JavaScript projects.

## Introduction to npm

npm consists of three main components:
- **Website**: Discover packages, set up profiles, and manage access
- **CLI**: Terminal tool for installing and managing packages
- **Registry**: Public and private package database

As the world's largest software registry, npm plays a crucial role in the JavaScript ecosystem and in VibeStack development.

## Basic Commands

### Installation & Setup

npm is installed automatically with Node.js:

```bash
# Check npm version
npm --version

# Update npm
npm install -g npm@latest
```

### Package Installation

```bash
# Install package locally (in current project)
npm install package-name

# Install package globally (accessible from anywhere)
npm install -g package-name

# Install as development dependency
npm install --save-dev package-name

# Install specific version
npm install package-name@1.2.3

# Install packages listed in package.json
npm install
```

### Package Management

```bash
# Update packages
npm update

# Remove package
npm uninstall package-name

# List installed packages
npm list

# List outdated packages
npm outdated
```

### Project Initialization

```bash
# Create a new package.json interactively
npm init

# Create a default package.json
npm init -y
```

## Package.json Explained

The `package.json` file is the heart of any Node.js project:

```json
{
  "name": "my-vibestack-app",
  "version": "1.0.0",
  "description": "A VibeStack application",
  "main": "index.js",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "^15.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "eslint": "^8.56.0",
    "typescript": "^5.3.3"
  },
  "engines": {
    "node": ">=18.0.0"
  },
  "private": true
}
```

### Key Fields

- **name**: Package name (must be lowercase, no spaces)
- **version**: Semantic version number
- **description**: Package description
- **main**: Entry point file
- **scripts**: Custom scripts to run with `npm run <script-name>`
- **dependencies**: Production dependencies
- **devDependencies**: Development-only dependencies
- **peerDependencies**: Required peer packages
- **engines**: Node.js version requirements
- **private**: Prevents accidental publishing to npm registry

## npm Scripts

Scripts provide a powerful way to run commands and automate workflows:

```bash
# Run a defined script
npm run script-name

# Common built-in scripts
npm start
npm test
npm run build
```

Example script usage in VibeStack:

```json
"scripts": {
  "dev": "next dev",
  "build": "next build",
  "start": "next start",
  "format": "prettier --write .",
  "lint": "eslint . --ext .js,.jsx,.ts,.tsx",
  "typecheck": "tsc --noEmit",
  "validate": "npm run lint && npm run typecheck"
}
```

## Dependency Management

### Dependency Types

- **dependencies**: Required for production
- **devDependencies**: Required for development only
- **peerDependencies**: Expected to be provided by the consumer
- **optionalDependencies**: Optional packages

### Version Specifications

- **Exact**: `1.2.3` (only this version)
- **Patch updates**: `~1.2.3` (1.2.x)
- **Minor updates**: `^1.2.3` (1.x.x)
- **Any version**: `*` (not recommended)
- **Version ranges**: `>=1.0.0 <2.0.0` or `1.0.0 - 1.9.9`

## Lock Files

`package-lock.json` ensures consistent installations across environments:

- Records exact version installed
- Locks dependencies of dependencies
- Ensures reproducible builds
- Should be committed to version control

## npm in VibeStack

### Core Dependencies

Typical VibeStack applications use these npm packages:

```bash
# Core packages
npm install next react react-dom

# UI components
npm install @radix-ui/react-dialog lucide-react
npx shadcn-ui@latest init

# Database connectivity
npm install @supabase/supabase-js @supabase/ssr

# Development tools
npm install --save-dev typescript @types/react @types/node eslint
```

### Workspace Setup

For monorepo management, npm workspaces allow managing multiple packages:

```json
{
  "name": "vibestack-monorepo",
  "private": true,
  "workspaces": [
    "apps/*",
    "packages/*"
  ]
}
```

## Best Practices

1. **Use exact versions** for critical dependencies
2. **Commit lock files** to ensure consistent installations
3. **Audit regularly** with `npm audit` to find vulnerabilities
4. **Keep dependencies updated** but test thoroughly
5. **Use .npmrc files** for organization-wide settings
6. **Set up scoped packages** for internal libraries

## Resources

- [npm Documentation](https://docs.npmjs.com/)
- [npm Blog](https://blog.npmjs.org/)
- [Semantic Versioning](https://semver.org/)
- [package.json Guide](https://nodejs.dev/learn/the-package-json-guide)
