---
applyTo: '**/*.gd'
---
# Copilot Instructions for GDScript

Use these instructions for GDScript files in this repository. Keep them aligned with the repo-specific guidance in `.github/copilot-instructions.md`, especially where the addon's existing architecture and public API shape matter more than generic style preferences.

## Code Style

### Indentation
- Use tabs for indentation, not spaces.

### Type System
- Prefer explicit static types for new code.
- Always add explicit types for exported variables, `@onready` node references, function parameters, and return values unless there is a strong reason not to.
- Prefer typed local variables when they improve readability or API clarity.
- Avoid churn-only refactors whose only purpose is converting already-working inferred types to explicit ones.
- Use const declarations instead of repeating magic numbers and strings when the value has shared meaning.

### Node References
- Use `@onready` with explicit type annotations and node path syntax for local node references.
- Example: `@onready var collision_shape: CollisionShape3D = $CollisionShape3D`
- Prefer the full concrete type name instead of leaving node references inferred.

### Naming Conventions
- Use `snake_case` for functions, variables, and signals.
- Use `PascalCase` for classes, enums, and types.
- Prefix private helper functions with `_`.
- Preserve existing public API names unless a repo-wide refactor is intentional.

### Comments and Documentation
- Use `#` comments for inline explanations and multi-line documentation blocks.
- Keep comments short and focused on behavior, assumptions, or non-obvious intent.
- Preserve existing triple-quoted file header blocks when they already exist in addon scripts; do not rewrite them just to normalize comment style.

## Code Organization

### Declaration Order
- Prefer the common GDScript order of signals, enums, consts, exports, vars, then `@onready` vars.
- Follow the surrounding file's existing member ordering when working in established addon scripts.

### Function Order
- Keep related functions grouped together in a way that matches the surrounding file.
- Do not reorder large existing scripts purely to enforce a preferred style.

## Control Flow

### Conditionals
- Prefer early returns and guard clauses over deeply nested branches.
- Keep null checks explicit when they improve safety and readability.

### Error Handling
- Prefer explicit error handling over silent failures.
- Print errors or emit signals when an invalid state needs to be surfaced.

## Repo Fit

### Architecture
- Preserve the existing Card3D addon architecture instead of introducing generic framework patterns.
- Extend the current `Card3D`, `CardCollection3D`, `CardLayout`, `DragStrategy`, and `DragController` model rather than inventing parallel systems.
- Prefer small, focused changes that fit the surrounding addon code over abstract reorganizations.

### Existing Style
- Match the style already used in the file you are editing.
- Favor consistency with the current addon codebase over generic best-practice rewrites.
- Preserve scene and node-path contracts used by the core scripts unless the change intentionally updates all dependents.

### UID Files
- Do not manually create or hand-edit Godot `.uid` files such as `*.tscn.uid` or `*.gd.uid`.
- If Godot regenerates or updates `.uid` files as part of a real script or scene change, keep those generated changes in sync with the corresponding source changes.