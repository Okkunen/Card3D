# GitHub Copilot Instructions for Card3D

## Project scope

- This repository is a Godot 4 addon/library for 3D card interactions, not just a single game.
- Treat `addons/card_3d/` as the core product.
- Treat `example/` and `example_battle/` as reference implementations that show intended usage patterns.

## Architecture to preserve

- `Card3D` is the base interactive card node. Extend it for custom visuals and card-specific data instead of rewriting the base drag behavior.
- `CardCollection3D` owns card ordering, insertion/removal, hover state, and layout application.
- `DragController` coordinates dragging across one or more `CardCollection3D` children.
- `CardLayout` resources define card positioning/rotation logic.
- `DragStrategy` resources define selection, removal, insertion, and reorder rules.
- Prefer adding new layouts or drag strategies over branching core logic inside `CardCollection3D` or `DragController`.

## Safe change patterns

- When adding a new card type, create a scene/script that inherits from `Card3D`.
- When changing placement behavior, implement or extend a `CardLayout` resource.
- When changing move permissions, implement or extend a `DragStrategy` resource.
- Keep signal lifecycle patterns intact: cards are connected on insert and disconnected on removal.
- Preserve current public API names unless the change is an intentional refactor across the whole repo. In particular, `card_indicies` is misspelled in the current API and is used throughout the codebase.

## Scene and node-path contracts

- Do not casually rename scene children that core scripts depend on.
- `Card3D` expects paths like `$CardMesh` and `$StaticBody3D/CollisionShape3D`.
- `CardCollection3D` expects `$DropZone/CollisionShape3D`.
- If a scene structure changes, update every dependent script and example scene together.

## GDScript conventions

- Match the existing typed GDScript style and continue using `class_name` for reusable classes/resources.
- Follow `.gdlintrc` rules:
  - use tabs, not spaces, for indentation;
  - use `snake_case` for functions, variables, and signals;
  - use `PascalCase` for class names;
  - keep the existing member ordering style used across addon scripts.
- Keep `.uid` files in sync when scripts are moved or renamed.

## Validation checklist

- Lint GDScript before finishing changes:

```bash
find . -name "*.gd" -type f | xargs gdlint
```

- Run the sample scenes in Godot when behavior changes:
  - `res://example/table.tscn`
  - `res://example_battle/scenes/battle.tscn`
- If drag or layout logic changes, manually verify:
  - hover highlighting;
  - drag start threshold behavior;
  - reorder within the same collection;
  - dropping into another collection;
  - preview positioning while dragging;
  - signal-driven side effects such as `card_clicked`, `card_added`, and `card_moved`.

## Version and repo-specific caveats

- `project.godot` currently advertises Godot feature `4.6`, but CI runs on Godot `4.4`. Avoid introducing APIs that require a newer runtime unless the project is updated consistently.
- The working tree may contain unrelated user changes. Do not restore deleted examples or revert edits unless explicitly asked.
- This repo tracks generated Godot metadata like `.uid` files, so changes that affect scripts/scenes often need companion metadata updates.
