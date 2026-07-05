# Creating Elements

The user populates the canvas with three kinds of things: **shapes** (ovals and circles that hold text), **arrows** (curved connectors between elements), and **nodes** (small fixed-size circle and triangle markers). Each element is placed using a distinct interaction. Creation and manipulation alternate fluidly — every placement returns to Select mode so the user can immediately move, resize, or edit what they just placed.

## File Map

| File | When to read |
|---|---|
| [tools.md](tools.md) | Toolbar layout, tool switching, cursor changes, info bar hints |
| [placing_shapes.md](placing_shapes.md) | Placing ovals and circles, sub-mode dropdown, default sizes |
| [creating_arrows.md](creating_arrows.md) | Anchor dots, drag-to-connect, preview line, snap behavior |
| [placing_nodes.md](placing_nodes.md) | Placing circle and triangle nodes, supported vs unsupported features |

## Cross-Feature Behavior

- **Transitioning between modes:** Placing a shape auto-selects it → ready to move/resize/color/text. Creating an arrow stays in Select mode → arrow is now part of the diagram. Finishing text editing returns to Select mode with the shape still selected. Placing a node auto-selects it → ready to move/color/connect.
- **Tool deactivation:** Pressing Escape while in any creation tool deactivates it without placing anything, returning to Select mode with a clean slate.
- **Escape during creation:** If the user switches to Shape or Node tool and presses Escape, they return to Select mode without placing anything. No accidental elements are created.

---

See also: [Selecting and Manipulating](../selecting_and_manipulating/README.md) for what happens after an element is placed.