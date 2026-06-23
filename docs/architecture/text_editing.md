# Text Editing

## File: `res://scenes/ui/text_edit_overlay/text_edit_overlay.gd`

Text editing uses a screen-space `TextEdit` overlay that appears centered over the selected shape. The overlay is a child of the `UI` CanvasLayer, so it's unaffected by camera transforms.

## TextEditOverlay Scene Structure

```
TextEditOverlay (Control) — TextEditOverlay.gd
└── Panel
    └── MarginContainer
        └── TextEdit
```

## Opening the Editor

**Two entry points:**

1. **Enter key**: `Main._unhandled_input` detects `KEY_ENTER` when a single shape is selected and no modifier keys are held. Calls `Main.open_text_editor(shape)`.
2. **Double-click**: ClickHandler detects two clicks on the same element within 400ms, calls `LabelShape.handle_double_click()` which emits `double_clicked(shape)` → `Main._on_shape_double_clicked()` → `open_text_editor()`.

### `Main.open_text_editor(shape)`:

1. Guard: shape must be valid and in the scene tree
2. Compute shape center in world space: `shape.global_position`
3. Convert to screen space: `camera.get_canvas_transform() * shape_center`
4. Calculate overlay size from shape visual bounds × current zoom, with minimums:
   - `overlay_width = max(160.0, shape.rx * 2.0 * current_zoom)`
   - `overlay_height = max(80.0, shape.ry * 2.0 * current_zoom)`
5. Compute screen Rect2 centered on the shape's screen position
6. Call `_text_overlay.call("open", shape, screen_rect)`

### `TextEditOverlay.open(shape, screen_rect)`:

1. Store reference to `editing_shape`
2. Set `is_open = true`
3. Position and size the overlay Control to `screen_rect`
4. Pre-populate `text_edit.text` with existing shape text
5. Make visible and grab focus

## Editing Behavior

- **Real-time preview**: `_on_text_changed()` updates `editing_shape.text_content` on every keystroke, so the shape's text label updates live
- **Word-wrap**: TextEdit handles word-wrapping internally; the overlay width constrains it
- **Font scaling**: The shape's `_update_text_display()` recalculates font size to fit the shape bounds on every text change

## Committing or Canceling

### Enter (commit) — no Shift

`TextEditOverlay._input()` catches `KEY_ENTER` without Shift:
1. Emit `text_committed(editing_shape, text_edit.text)`
2. `Main._on_text_committed()`: sets `shape.text_content = text` and saves
3. `_close()`: hide, clear state

### Escape (cancel)

`TextEditOverlay._input()` catches `KEY_ESCAPE`:
1. Emit `text_cancelled(editing_shape)`
2. `Main._on_text_cancelled()`: no save, just update UI
3. `_close()`: hide, clear state. **Note**: Because `text_content` was updated in real-time via `_on_text_changed()`, cancel does NOT revert the shape's text. The live preview has already modified the shape. This is a known gap — cancel should restore the previous text.

### Escape during text editing (from Main)

`Main._unhandled_input` checks `_text_overlay.is_open` before handling Escape for tool deactivation or selection clear. If the overlay is open, it calls `_text_overlay.cancel()` instead.

### Click-away commit (focus loss)

When the TextEdit loses focus — either via a canvas click (ClickHandler releases focus) or by clicking another UI Control — `focus_exited` fires and calls `commit()`. This saves the current text (even empty) and closes the overlay.

Edge cases:
- **Escape still cancels:** The `_input` handler fires before `focus_exited`. Escape calls `cancel()`, which sets `is_open = false`. When `focus_exited` fires next, the handler checks `is_open` and becomes a no-op.
- **Enter + focus_exited:** Enter triggers both `text_submitted` (which calls `commit()`) and `focus_exited` (which also calls `commit()`). The second call is a no-op because `_close()` already cleared state and `editing_shape` is null.

### Shift+Enter (newline)

Shift+Enter inserts a newline in the TextEdit. Only bare Enter (no Shift) commits. This is handled in `TextEditOverlay._input()` by checking `ke.shift_pressed`.

## Signals

| Signal | Arguments | Emitted When |
|---|---|---|
| `text_committed` | `shape: Node, text: String` | Enter pressed (no Shift) |
| `text_cancelled` | `shape: Node` | Escape pressed |

## Edge Cases

- **Delete key while editing**: The TextEdit handles Delete internally. `Main._unhandled_input` checks `_text_overlay.is_open` and skips Delete-key element removal.
- **Escape during text editing**: Cancels the overlay first, then stops propagation. The Escape key does not also clear selection or deactivate the tool.
- **Selection menu hidden**: The selection menu is dismissed while text editing is active. It would overlap with the overlay.
- **Zoom while editing**: CameraController's zoom controls remain active. The overlay scales with zoom (its position/size is computed from shape bounds × zoom on open, but does not update on zoom changes — the overlay stays at the size it was opened at).
- **Cancel reverts text?**: Currently, cancel does NOT revert text because `_on_text_changed()` modifies `shape.text_content` in real time. This is a bug — a snapshot of the original text should be saved on open and restored on cancel.