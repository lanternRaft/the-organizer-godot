# Copy and Paste

Copy and paste lets the user duplicate elements on the canvas. It's the primary way to reuse a well-configured shape — right color, right size, right text — across multiple locations.

## How it works

1. Select one or more elements
2. Press **Ctrl/Cmd + C** — the selected elements are copied
3. Press **Ctrl/Cmd + V** — copies of the copied elements appear on the canvas, offset slightly from their originals
4. The pasted copies are automatically selected, ready to be moved into position

### What gets copied

All information about the selected elements is preserved:

- **Shapes:** Position, dimensions, fill color, text content, shape mode (oval/circle)
- **Arrows:** Path points, color, connection anchors (if both endpoints are in the selection)

### The paste offset

Pasted elements appear shifted by **20px** (world-space) relative to the originals — just enough to make it clear they're new copies and not duplicates that need to be moved out of each other's way. The offset is consistent: every paste applies the same shift, so repeated paste operations create a cascading line of copies.
## Behavior

- **Paste with nothing copied:** Nothing happens. The clipboard is empty, and the paste operation is silently ignored.
- **Copying arrows without their endpoint shapes:** The arrow is copied, but since the copied arrow's endpoints reference the originals (not the copies), the pasted arrow may appear disconnected. The user can re-anchor it to the desired shapes after paste.
- **Copying both shapes and the arrow between them:** If the user selects a shape, the arrow connecting it to another shape, and that other shape, then copies and pastes the whole set, the pasted arrow reconnects to the pasted shapes. This creates a self-contained copy of a sub-diagram.
- **Clipboard replacement:** Each new copy operation replaces the previous clipboard contents. Multiple copy operations don't accumulate.

---

Parent feature: [Managing Your Work](README.md)