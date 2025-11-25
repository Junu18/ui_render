# CLAUDE.md - AI Assistant Guide for ui_render

**Last Updated:** 2025-11-25
**Repository:** ui_render
**Purpose:** UI rendering library/framework

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Current Repository State](#current-repository-state)
3. [Recommended Project Structure](#recommended-project-structure)
4. [Development Workflow](#development-workflow)
5. [Coding Conventions](#coding-conventions)
6. [Git Conventions](#git-conventions)
7. [Testing Guidelines](#testing-guidelines)
8. [Documentation Standards](#documentation-standards)
9. [Common Tasks](#common-tasks)
10. [AI Assistant Guidelines](#ai-assistant-guidelines)

---

## Project Overview

### Purpose
The `ui_render` project is designed for UI rendering functionality. The specific implementation details, target framework, and rendering approach are to be determined based on project requirements.

### Technology Stack
*To be determined - recommended stacks:*
- **Frontend Framework:** React, Vue, Svelte, or vanilla JavaScript/TypeScript
- **Build Tool:** Vite, Webpack, or Rollup
- **Language:** TypeScript (recommended for type safety)
- **Testing:** Jest/Vitest + Testing Library
- **Linting:** ESLint + Prettier

### Key Features (Planned)
- UI component rendering
- Performance optimization
- Cross-browser compatibility
- Responsive design support
- Accessibility (a11y) compliance

---

## Current Repository State

### Status: Initial Setup
- ✅ Git repository initialized
- ✅ README.md created
- ✅ CLAUDE.md created (this file)
- ⏳ No source code yet
- ⏳ No package.json or dependencies
- ⏳ No build configuration
- ⏳ No test setup

### Active Branch
- **Development Branch:** `claude/claude-md-mieg1ylpp7bvnhsv-01PckK4AF4HEXUeGUV23DP1s`

---

## Recommended Project Structure

```
ui_render/
├── .github/                 # GitHub Actions, issue templates, etc.
│   └── workflows/          # CI/CD workflows
├── src/                    # Source code
│   ├── components/         # UI components
│   ├── core/              # Core rendering logic
│   ├── utils/             # Utility functions
│   ├── types/             # TypeScript type definitions
│   └── index.ts           # Main entry point
├── tests/                 # Test files
│   ├── unit/             # Unit tests
│   ├── integration/      # Integration tests
│   └── e2e/              # End-to-end tests
├── examples/             # Usage examples
├── docs/                 # Documentation
├── dist/                 # Build output (gitignored)
├── node_modules/         # Dependencies (gitignored)
├── .gitignore           # Git ignore rules
├── .eslintrc.js         # ESLint configuration
├── .prettierrc          # Prettier configuration
├── tsconfig.json        # TypeScript configuration
├── vite.config.ts       # Build tool configuration
├── package.json         # Project metadata and dependencies
├── README.md            # User-facing documentation
└── CLAUDE.md            # This file - AI assistant guide
```

---

## Development Workflow

### Initial Setup

When setting up the project for the first time:

```bash
# Install dependencies (once package.json exists)
npm install

# Run development server
npm run dev

# Run tests
npm test

# Build for production
npm run build
```

### Feature Development Process

1. **Understand Requirements**
   - Read existing code and documentation
   - Identify affected components/modules
   - Consider edge cases and backwards compatibility

2. **Plan Implementation**
   - Use TodoWrite tool to track tasks
   - Break down complex features into smaller steps
   - Identify dependencies and potential blockers

3. **Implementation**
   - Write clean, readable code
   - Follow existing patterns and conventions
   - Add appropriate error handling
   - Write tests alongside implementation

4. **Testing**
   - Write unit tests for new functions/components
   - Update integration tests if needed
   - Manual testing in development environment
   - Verify no regressions

5. **Documentation**
   - Update inline code comments where necessary
   - Update README.md for user-facing changes
   - Update this CLAUDE.md for architectural changes

6. **Commit and Push**
   - Write clear, descriptive commit messages
   - Push to designated branch
   - Ensure CI passes

---

## Coding Conventions

### General Principles

- **Simplicity First:** Avoid over-engineering
- **YAGNI:** You Aren't Gonna Need It - don't add speculative features
- **DRY (Carefully):** Don't Repeat Yourself, but avoid premature abstraction
- **Readable > Clever:** Code should be self-documenting

### TypeScript/JavaScript Style

```typescript
// Use TypeScript for type safety
interface RenderOptions {
  container: HTMLElement;
  props?: Record<string, unknown>;
  immediate?: boolean;
}

// Prefer named exports over default exports
export function render(element: Component, options: RenderOptions): void {
  // Implementation
}

// Use meaningful variable names
const containerElement = document.getElementById('root');
const isRendered = false;

// Prefer const over let, avoid var
const CONFIG = { timeout: 3000 };
let counter = 0;
```

### Code Organization

- **One component per file** (generally)
- **Co-locate related files** (component + styles + tests)
- **Keep functions small and focused** (single responsibility)
- **Limit file length** (aim for < 300 lines)

### Naming Conventions

- **Files:** `kebab-case.ts` or `PascalCase.tsx` for components
- **Functions:** `camelCase`
- **Classes/Components:** `PascalCase`
- **Constants:** `UPPER_SNAKE_CASE` or `camelCase`
- **Private members:** `_prefixedWithUnderscore` or `#privateFields`

### Comments

- **Don't comment what, comment why**
- **Remove commented-out code** (use git history)
- **Use JSDoc for public APIs**

```typescript
/**
 * Renders a component into the specified container.
 *
 * @param element - The component to render
 * @param options - Rendering options including container and props
 * @returns void
 * @throws {Error} If container is not found in the DOM
 */
export function render(element: Component, options: RenderOptions): void {
  // Complex logic explanation only if needed
}
```

### Error Handling

```typescript
// Validate at system boundaries
export function render(element: Component, options: RenderOptions): void {
  if (!options.container) {
    throw new Error('Container element is required');
  }

  // Don't add unnecessary validation for internal code
  // Trust that internal functions are called correctly
}

// Use custom error types for specific error cases
export class RenderError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'RenderError';
  }
}
```

---

## Git Conventions

### Branch Naming

- **Feature branches:** `claude/claude-md-<session-id>`
- **Main branch:** `main` or `master`
- **CRITICAL:** Always push to the correct branch specified at the start of the session

### Commit Messages

Follow conventional commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(render): add support for async components

Implement async component rendering with loading states
and error boundaries. Components can now return Promises
that resolve to rendered elements.

Closes #123
```

```
fix(core): prevent memory leak in event listeners

Event listeners were not being cleaned up when components
were unmounted, causing memory leaks in long-running apps.
Added proper cleanup in unmount lifecycle.
```

### Git Operations

**Pushing:**
```bash
# Always use -u flag for first push
git push -u origin <branch-name>

# Branch must start with 'claude/' and end with session ID
# If network errors occur, retry up to 4 times with exponential backoff
```

**Fetching:**
```bash
# Prefer fetching specific branches
git fetch origin <branch-name>

# For pulls
git pull origin <branch-name>
```

**Important Rules:**
- ✅ Commit only when explicitly requested by user
- ✅ Use descriptive commit messages
- ✅ Push to designated branch only
- ❌ Never run `git commit --amend` on other developers' commits
- ❌ Never force push to main/master
- ❌ Never skip hooks (--no-verify) unless explicitly requested

---

## Testing Guidelines

### Test Structure

```typescript
// unit test example: render.test.ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { render } from './render';

describe('render', () => {
  let container: HTMLElement;

  beforeEach(() => {
    container = document.createElement('div');
    document.body.appendChild(container);
  });

  afterEach(() => {
    document.body.removeChild(container);
  });

  it('should render component into container', () => {
    const component = { type: 'div', props: { text: 'Hello' } };
    render(component, { container });

    expect(container.textContent).toBe('Hello');
  });

  it('should throw error if container is not provided', () => {
    expect(() => {
      render(component, { container: null });
    }).toThrow('Container element is required');
  });
});
```

### Testing Principles

- **Test behavior, not implementation**
- **Write tests alongside code** (TDD when appropriate)
- **Aim for high coverage on critical paths** (not 100% everywhere)
- **Mock external dependencies**
- **Keep tests fast and isolated**

### Test Coverage Goals

- **Core rendering logic:** 90%+ coverage
- **Utility functions:** 80%+ coverage
- **UI components:** 70%+ coverage (focus on interactions)

---

## Documentation Standards

### README.md
- **Target audience:** End users and developers using the library
- **Contents:** Installation, quick start, API overview, examples
- **Keep updated:** Update whenever public API changes

### CLAUDE.md (This File)
- **Target audience:** AI assistants and maintainers
- **Contents:** Architecture, conventions, workflows, internal details
- **Keep updated:** Update when structure or conventions change

### Inline Documentation
- **JSDoc for public APIs:** Required
- **Comments for complex logic:** When code isn't self-explanatory
- **Examples in JSDoc:** For non-obvious usage

### Examples Directory
- **Provide working examples** for common use cases
- **Keep examples simple** and focused on one feature
- **Ensure examples are tested** and work with current version

---

## Common Tasks

### Adding a New Component

1. Create component file in `src/components/`
2. Implement component logic
3. Add TypeScript types/interfaces
4. Write unit tests
5. Add example usage in `examples/`
6. Export from main entry point if public API
7. Update documentation

### Adding a New Utility Function

1. Create function in `src/utils/`
2. Add comprehensive unit tests
3. Export from utils index
4. Document with JSDoc
5. Use in codebase where applicable

### Fixing a Bug

1. Write a failing test that reproduces the bug
2. Fix the bug
3. Verify test passes
4. Check for similar bugs elsewhere
5. Commit with `fix:` prefix

### Refactoring

1. Ensure existing tests pass
2. Make incremental changes
3. Run tests after each change
4. Avoid mixing refactoring with feature additions
5. Commit with `refactor:` prefix

---

## AI Assistant Guidelines

### When Working on This Repository

1. **Always read before writing**
   - Never propose changes to code you haven't read
   - Understand existing patterns before adding new code

2. **Use TodoWrite for complex tasks**
   - Break down multi-step tasks
   - Track progress for user visibility
   - Mark tasks completed immediately when done

3. **Follow the principle of least change**
   - Only modify what's necessary
   - Don't add "improvements" that weren't requested
   - Don't refactor code adjacent to your changes unless asked

4. **Respect the existing codebase**
   - Follow established patterns and conventions
   - Match existing code style
   - Don't introduce new dependencies without discussion

5. **Security awareness**
   - Avoid XSS, injection vulnerabilities
   - Validate at system boundaries (user input, external APIs)
   - Don't trust external data

6. **Be explicit about uncertainty**
   - If requirements are unclear, ask questions
   - Don't make assumptions about desired behavior
   - Propose options when multiple approaches are valid

7. **Tool usage efficiency**
   - Use parallel tool calls when operations are independent
   - Use Task tool for complex exploration
   - Prefer Read/Edit/Write over bash for file operations

### What to Avoid

- ❌ Creating files without explicit need
- ❌ Adding comments to unchanged code
- ❌ Over-engineering solutions
- ❌ Adding error handling for impossible scenarios
- ❌ Creating abstractions for single-use code
- ❌ Backwards-compatibility hacks for new code
- ❌ Using bash commands for file operations (use dedicated tools)

### Communication Style

- Be concise and direct
- Focus on technical accuracy
- Use markdown formatting for readability
- Don't use emojis unless requested
- Explain the "why" behind decisions
- Reference specific files and line numbers

---

## Project-Specific Notes

### Current Development Phase: Initialization

This repository is in its initial setup phase. The following decisions need to be made:

1. **Technology Stack Selection**
   - Frontend framework (if any)
   - Build tooling
   - Testing framework
   - Language (TypeScript recommended)

2. **Project Scope**
   - Define specific rendering targets (web, canvas, SVG, etc.)
   - Identify core features vs. nice-to-have
   - Determine if library or framework

3. **Architecture Decisions**
   - Component model (if applicable)
   - State management approach
   - Rendering strategy (virtual DOM, direct manipulation, etc.)
   - Performance optimization strategy

### Next Steps

When beginning development:

1. Initialize package.json with `npm init`
2. Install and configure TypeScript
3. Set up build tooling (Vite recommended)
4. Configure ESLint and Prettier
5. Set up testing framework
6. Create initial project structure
7. Implement core rendering functionality
8. Add comprehensive tests
9. Update README.md with usage instructions
10. Update this CLAUDE.md with architectural decisions

---

## Changelog

### 2025-11-25
- Initial CLAUDE.md creation
- Documented repository state
- Established conventions and guidelines
- Added recommended project structure

---

## Questions or Clarifications Needed

If you're an AI assistant working on this codebase and encounter ambiguity:

1. Check this CLAUDE.md first
2. Read existing code for patterns
3. If still unclear, ask the user explicitly
4. Document decisions in commit messages
5. Update this file with new conventions

---

**Remember:** This document should evolve with the project. Keep it updated as architectural decisions are made and conventions are established.
