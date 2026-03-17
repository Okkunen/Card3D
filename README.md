# Card3D

This is a simple and handy library for managing 3D cards in Godot. With drag-and-drop support, you can easily move and reorder cards within and between collections. Look and feel inspired by Hearthstone.

This library is designed to be flexible and extendable for any card game. It offers a basic framework that you can easily adapt to suit your specific needs.

## Features

- **Card3D**: Represents an individual card node.
- **CardCollection3D**: Manages a collection of Card3D objects, supporting adding, removing, and reordering of cards.
  - optional different layouts (pile, fan, line)
  - configurable dropzone settings
- **DragController**: Handles the drag-and-drop operations across multiple card collections.

## Usage

1. Create a new scene that inherits from `Card3D` and extend the `Card3D` script. This allows you to create your own card meshes and textures. (You can also use the example textures included.)
2. Add an instance of `DragController` to your scene.
3. Add one or more instances of `CardCollection3D` as children of the `DragController`.
4. Configure the drop settings for the card collections.
5. Add a script that instantiates `Card3D` nodes and adds them to the collections.

## MCP Workflow

This repository is set up to work with two MCP servers:

- `godot`: use this for editor-driven scene changes, node operations, saving scenes, UID-safe metadata updates, and validating that the project still starts after structural or behavior changes.
- `godot-docs`: use this to look up Godot classes, nodes, resources, properties, and signals before making engine-specific changes.

Recommended workflow:

1. Use the docs MCP server to read the relevant Godot documentation before changing unfamiliar engine features.
2. Use the Godot MCP server and editor tools for scene and node changes when possible instead of hand-editing `.tscn` files.
3. After behavior, scene, or workflow changes, run the project to confirm it still starts.
4. Re-check `.github/copilot-instructions.md` and `.github/instructions/godot.instructions.md` after behavior or workflow changes and update them if the codebase has made either instruction file stale.
