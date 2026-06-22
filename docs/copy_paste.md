# Copy / Paste

In-memory clipboard stores serialized copies of selected elements:

- **Shapes**: `{ type, position.x, position.y, rx, ry, fill, text }`
- **Nodes**: `{ type, position.x, position.y, fill, node_shape }` — `node_shape` is `"circle"` or `"triangle"`
- **Arrows**: `{ type, points: PackedVector2Array, color }`

Pasted elements are offset by +20px from original and become selected.

## Related Keyboard Shortcuts

- **Ctrl+A / Cmd+A**: Selects all elements on the canvas (LabelShapes + Arrows). See [Selection System](selection.md).
- **Delete / Backspace**: Deletes all elements in the current selection set, including connected arrows. See [Selection System](selection.md).