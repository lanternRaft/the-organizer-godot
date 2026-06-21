# Auto-Save / Persistence

The full canvas state is automatically persisted to a file at `user://canvas.save` on any mutation.

| Setting | File | Location |
|---|---|---|
| Canvas state | `canvas.save` | `user://` (Godot's persistent data directory) |
| Grid state | `config.cfg` | `user://` |
| Theme | `config.cfg` | `user://` |

## Save Triggers

`notify_canvas_changed()` (emits `EventBus.canvas_changed`) is called after every user-initiated mutation:

- Shape / node / arrow creation
- Deletion (selection menu, keyboard Delete/Backspace)
- Single and multi-element drag (on mouseup)
- Color change (via palette swatch)
- Arrow direction change (none/mono/dual)
- Waypoint insertion/drag
- Text commit
- Legend name edit (`LineEdit.text_changed`)
- Paste from clipboard

The `EventBus.canvas_changed` signal is connected to `SaveManager.gd` which calls `save_to_file()`.

## Serialization Format

The `serialize_canvas()` function produces a `Dictionary`:

```gdscript
{
  "elements": [
    { "type": "LabelShape", "position": Vector2, "rx": float, "ry": float, "fill": Color, "text": String },
    { "type": "CircleNode", "position": Vector2, "fill": Color },
    { "type": "TriangleNode", "position": Vector2, "fill": Color },
    {
      "type": "Arrow",
      "points": PackedVector2Array,
      "anchors": [{"end": "start"|"end", "element_index": int, "anchor_label": String}],
      "direction": "mono"|"dual"|"none",
      "color": Color
    }
  ],
  "legend": [[Color, {"custom_name": String}], ...]
}
```

Anchor references use element-index pointers (the index of the referenced shape/node in the serialized array).

## Deserialization

`load_from_file()` runs on scene start:
1. Reads the Dictionary from `user://canvas.save`
2. **First pass**: creates all LabelShapes, CircleNodes, and TriangleNodes (arrows need element references)
3. **Second pass**: creates all arrows, resolving anchor element indices to the actual nodes
4. Restores arrow direction, colors, and waypoints
5. Restores the legend (colors and custom names)

## Clear Canvas

The hamburger menu → **Clear** button shows a confirmation dialog (`AcceptDialog`). On confirmation, `clear_and_save()` removes all canvas elements, clears the legend, and saves the empty state.