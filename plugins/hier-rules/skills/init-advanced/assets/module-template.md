# Module Rules File Template

Used for any directory that has content in it.
Examples: `components/`, `api/`, `lib/`, `hooks/`, `store/`, `types/`, `utils/`, `services/`

## Path Scoping

At the top of this type of file a YAML frontmatter entry needs to be made that restricts the file to a path. THIS IS HOW THE WHOLE SYSTEM WORKS

For example:

```YAML
---
    paths:
        - 'src/path/to/directory/**/*'
        or
        - - 'src/path/to/directory/**/*.ts'
---
```

---

## Structure of template

Everyone one of these templates will have 1 or 2 sections. Either section can be omitted if it is not neccessary.

Section Tne will contain all of the coding pattern rules and details and anything of that sort.

Section Two will contain an entry of all the indexable content. Examples of indexable content are components, hooks, providers, etc.

## Section One

```markdown
# <Directory Name>

<3–6 sentences. What this module does, its role in the architecture, what
concerns it owns, and anything an agent must know before touching files here.
Focus on decisions made, constraints that exist, and non-obvious relationships
to other parts of the codebase.>

### Patterns & Conventions

<Coding patterns, naming conventions, and rules specific to this directory.
Only include what is NOT available to an agents training data. For example, all agents know how to program in react, and common react prinicples, since the agent will already know that this is a react project, common react paradigms do not need to be explained beyond mentioning the name for quick and easy recall.

Examples of what belongs here:

-   "All async functions must handle errors at the call site — do not swallow errors silently."
-   "Route handlers must not contain business logic — delegate to service functions."
-   "Utility functions must be pure — no side effects, no direct imports from store."

Examples of what does NOT belong here:

-   "Functions are named in camelCase." (obvious)
-   "Files use TypeScript." (obvious from tsconfig)>
```

---

### Rules for This File

-   If there are no meaningful patterns or conventions beyond what is obvious
    from reading the code, omit the Patterns & Conventions section entirely.
-   If there are no subdirectories, omit the Subdirectories section.
-   Subdirectory entries must answer "when", not "what".
    -   ❌ "Contains auth-related files"
    -   ✅ "Modifying login, session management, or token handling"
-   Do not describe the implementation of individual functions or files here.
    That level of detail belongs in source code comments or a deeper rules file.

## Section Two

This will display any indexable content within a directory

Directories that get entries:

-   `components/` and any subdirectory of it
-   `hooks/`
-   `context/` or `providers/`
-   `store/` — document the state shape and available actions, not internal implementation
-   Any other directory where an agent might want to reuse something

Directories that do NOT get entries (module context only):

-   `lib/`, `utils/`, `helpers/` — note what categories of utilities live here,
    but do not list individual functions. Exception: if flagged as architecturally
    significant, write a thorough Module Context section instead.
-   `types/` — document naming and organization conventions, not individual types
-   `config/`, `constants/` — document structure and conventions only

---

## Indexable Entry Types by Category

### Component

```markdown
### ButtonPrimary

**File:** `ButtonPrimary.tsx`
**Purpose:** Standard CTA button used for all primary user actions.
**Interface:**

-   `label: string` — button text
-   `onClick: () => void`
-   `variant?: 'solid' | 'outline'` — (default: `'solid'`)
-   `disabled?: boolean` — (default: `false`)
-   `loading?: boolean` — shows spinner, disables interaction (default: `false`)
    **Usage:** Use for every primary action. Do not use raw `<button>` elements.
    Use `ButtonSecondary` for non-destructive secondary actions.
```

### Hook

```markdown
### useAuth

**File:** `useAuth.ts`
**Purpose:** Exposes current user session and auth actions to any component.
**Interface:**

-   Returns `{ user: User | null, signIn: (creds) => Promise<void>, signOut: () => void, isLoading: boolean }`
    **Usage:** Use anywhere you need the current user or auth actions. Do not read
    auth state from the store directly — always go through this hook.
```

### Context Provider

```markdown
### ThemeProvider

**File:** `ThemeProvider.tsx`
**Purpose:** Distributes the active theme and toggle function to the component tree.
**Interface:**

-   `children: ReactNode`
-   Exposes via `useTheme()`: `{ theme: 'light' | 'dark', toggleTheme: () => void }`
    **Usage:** Already mounted at the app root. Do not nest a second ThemeProvider.
    Use the `useTheme()` hook to consume — do not import ThemeContext directly.
```

### Store Slice

```markdown
### cartSlice

**File:** `cartSlice.ts`
**Purpose:** Manages shopping cart state: items, quantities, and totals.
**Interface:**

-   State shape: `{ items: CartItem[], total: number, itemCount: number }`
-   Actions: `addItem(product)`, `removeItem(id)`, `clearCart()`
    **Usage:** Access via `useCartStore()`. Do not manipulate cart state outside
    this slice — all cart mutations go through these actions.
```

### Architecturally Significant Non-Inventoriable Directory

```markdown
---
paths:
    - src/lib/graphql
---

# GraphQL

<Explain the architecture: how queries are organized, how the client is
configured, what the fragment strategy is, how codegen works if applicable,
and what a new agent must know before adding or modifying anything here.
Be thorough — this directory was flagged as architecturally significant.>

## Conventions

-   <Non-obvious patterns specific to this GraphQL setup>
-   <Common mistakes to avoid>
```
