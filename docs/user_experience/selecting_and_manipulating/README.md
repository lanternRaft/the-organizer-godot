# Selecting and Manipulating

World building on the canvas is an iterative process. The user moves things around, changes their size, repositions clusters, and removes things that don't fit. This feature covers how the user grabs, adjusts, and cleans up their elements after they've been placed on the canvas.

## File Map

| File | When to read |
|---|---|
| [selecting_elements.md](selecting_elements.md) | Single click, shift+click additive, Ctrl+A select-all, primary vs secondary selection |
| [moving_elements.md](moving_elements.md) | Single drag, multi-drag, snap behavior, arrow reconnection during drag |
| [resizing_shapes.md](resizing_shapes.md) | Four-handle resize, circle constraint, size limits, text reflow on resize |
| [deleting_elements.md](deleting_elements.md) | Delete/Backspace key, selection menu delete, arrow cleanup, safety considerations |

## Cross-Feature Edge Cases

- **Selection while a text overlay is open:** The selection menu hides while the text editor is active (only shapes support text editing; nodes have no text overlay). This prevents the menu from overlapping with the editing interface.
- **Resizing in a multi-select set:** Only the primary (last-clicked) shape can be resized via its handles. Nodes never show handles and can't be resized — even if a node is the primary selection in a mixed set, no resize handles appear.
- **Deleting the primary selection:** If the deleted element was the primary, and other selected elements remain, the next element in the set becomes the new primary. If nothing remains, the selection clears.

---

See also: [Creating Elements](../creating_elements/README.md) for how elements get onto the canvas in the first place.