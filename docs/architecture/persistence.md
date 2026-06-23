# Persistence

## File: `res://scenes/main/main.gd`

Canvas state is persisted to a file at `user://canvas.save` on every user mutation. There is no `SaveManager.gd` autoload — save/load is handled directly by `Main.gd`.

## Save Path

```gdscript
const SAVE_PATH: String = "user://canvas.save"
```

Uses `FileAccess.store_var()` / `FileAccess.get_var()` for serialization (Godot's built-in Variant serialization).

## Save Triggers

`save_canvas()` is called after every user mutation:

- Shape placement (`place_shape()`)
- Deletion (`_delete_selected_elements()`, `_on_confirm_dialog_confirmed()`)
- Text commit (`_on_text_committed()`)
- Color change (`_on_menu_color_selected()`)

Auto-save does NOT trigger during:
- Active drags (only on release, but currently no save-on-drag-end for body moves)
- Text editing (only on commit)
- View-only actions (pan, zoom, select)

**Note on body-drag saving**: Body drags on LabelShape currently do not trigger `save_canvas()` on drag end. This is a gap — position changes from dragging are not persisted until another mutation triggers a save. The design docs describe save on drag-release, but this is not yet implemented.

## Serialization Format

```gdscript
{
    "elements": [
        {
            "type": "LabelShape",
            "position_x": float, "position_y": float,
            "rx": float, "ry": float,
            "fill_r": float, "fill_g": float, "fill_b": float, "fill_a": float,
            "text": String,
            "shape_mode": String,
        },
        # ... more elements
    ]
}
```

### Not Yet Serialized

- **Arrows**: The serialization format only handles LabelShape. Arrows are not saved or loaded — they are lost on restart. The planned format uses element-index pointers:
  ```gdscript
  {
      "type": "Arrow",
      "points": PackedVector2Array,
      "anchors": [{"end": "start"|"end", "element_index": int, "anchor_label": String}],
      "direction": "mono"|"dual"|"none",
      "color": Color
  }
  ```
- **Legend colors**: Not implemented in code (no LegendPanel exists)
- **Arrow direction**: Not implemented in code (no direction toggle in selection menu)
- **Arrow color**: Not implemented
- **Waypoints**: Not implemented (no curve mode)

## Load Flow

`load_canvas()` is called in `Main._ready()`:

1. Check if `user://canvas.save` exists (`FileAccess.file_exists`)
2. Open for reading, get the Variant dictionary
3. Iterate `data["elements"]` array
4. For each element with `"type": "LabelShape"`, call `_load_label_shape(data)`
5. Other types are currently ignored (arrows not loaded)

### `_load_label_shape(data)`:
1. Instantiate LabelShape from scene
2. Set position, rx, ry, fill_color, shape_mode, text_content from dictionary data
3. Add to `element_layer`
4. Connect signals: `clicked`, `double_clicked`, `anchor_changed`, `multi_drag_moved`, `multi_drag_ended`

## Grid State Persistence

Grid visibility is persisted separately in `user://config.cfg`:

```gdscript
const CONFIG_PATH: String = "user://config.cfg"
const CONFIG_SECTION: String = "grid"
const CONFIG_KEY_ENABLED: String = "enabled"
```

- Stored in `GridBackground.gd`
- `_load_state()` reads from config on `_ready()`
- `_save_state()` writes on toggle
- Preserves other config sections when writing (loads existing config first, merges changes)

## Clear Canvas

`Main.clear_all_elements()`:
1. Cancels text overlay if open
2. Calls `ArrowManager.delete_all_arrows()`
3. Iterates ElementLayer children, calling `queue_free()` on non-arrow elements
4. Clears selection
5. Saves empty state

The hamburger menu → Clear button shows an `AcceptDialog` confirmation first. Only on confirmation does the clear execute.

## Save Limitations

- **File format**: Uses Godot's `store_var()` which is binary Variant serialization — not human-readable or cross-version compatible
- **Error handling**: If save file can't be written, `push_error` is logged but no user-facing feedback is provided
- **Corrupted save**: If the loaded file is corrupt (e.g., wrong format), `FileAccess.get_var()` returns null and the loop silently iterates nothing. The user sees an empty canvas.
- **No undo/redo**: Deletion and clear are permanent after save. No undo stack exists.
- **Throttling**: No save debouncing — rapid operations (e.g., color cycling) trigger a save each time.