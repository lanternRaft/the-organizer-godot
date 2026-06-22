# Selection System

## Unified Data Model

Selection uses a single `selected_set: Array[Node]` containing both LabelShape and Arrow nodes.
The old split state (`selected_set` for shapes + `selected_arrow` for arrows) has been replaced.

- `primary_selection: Node` — the last-clicked element; determines which gets the stronger visual highlight.

## Click Behavior

| Action | Behavior |
|---|---|
| **Click (no Shift)** on an element | Clears the set, selects just that element. |
| **Shift+Click** on an element | Toggles the element in/out of the selection set (additive). |
| **Click on empty canvas** (Select mode, no Shift) | Clears the entire set. |
| **Escape** (Select mode) | Clears the entire set. |

## Multi-Drag

When multiple elements are selected, dragging any one moves all of them by the same delta:

- **LabelShapes**: `position` offset by the drag delta, snapping to 20px grid on release.
- **Arrows connected to moved shapes**: Update automatically via `anchor_changed` signal → `rebuild_path()`.
- **Free-floating arrows in the set**: Also move by delta (via multi-drag dispatch).
- **Handle resizing**: Only the dragged shape resizes; other selected elements are unaffected.

**Implementation**: The dragged element emits `multi_drag_moved(delta)` which Main receives and applies to all other elements in `selected_set`.

## Primary vs Secondary Visual Feedback

| Element | Primary (last-clicked) | Secondary (other selected) |
|---|---|---|
| **LabelShape** | `stroke_color = fill_color.lightened(0.4)`, `stroke_width = 3.0` | `stroke_color = fill_color.lightened(0.25)`, `stroke_width = 2.5` |
| **Arrow** | `vis_line.default_color = Color(0.6, 0.8, 1.0)` (solid) | `vis_line.default_color = Color(0.6, 0.8, 1.0, 0.7)` (transparent) |

## Ctrl+A (Select All)

Ctrl+A (or Cmd+A on macOS) selects all LabelShapes and Arrows on the canvas. The last element added becomes `primary_selection`.

## Multi-Delete

Delete/Backspace deletes **all** elements in the selection set:
- Shapes: `queue_free()` + connected arrow removal via `arrow_manager.delete_arrows_for_shape()`
- Arrows: `arrow_manager.delete_arrow()`
- Selection is cleared after deletion.

## Selection Menu

A floating `PanelContainer` that appears below a **single** selected element. Hides when 0 or >1 elements are selected.

| Button | Action |
|---|---|
| Delete (text: "Del") | Delete the selected element |
| Color (text: "Color") | Opens an inline 8-color palette popup (shapes only) |

### Menu Trigger / Dismissal

- **Auto-show** when exactly 1 element is selected and Select mode is active
- **Auto-hide** when 0 or >1 elements selected, Select mode inactive, or text overlay is open
- No modal overlay; visibility is purely selection-driven

### Menu Positioning

- Converts the element's world bounding box to screen-space using `Camera2D.get_canvas_transform()`
- Positions the menu centered below the element's bottom edge, plus 12px padding
- Clamped to viewport edges to stay on-screen
- Repositions on element move/resize (via `anchor_changed` signal) and camera zoom changes

### Delete Action

- Calls `arrow_manager.delete_arrow()` for arrows, or `queue_free()` + `delete_arrows_for_shape()` for shapes
- Persists via `save_canvas()`
- Also triggered by Delete/Backspace keyboard shortcut (now deletes entire selection set)

### Color Action

- Toggles the `ColorPalette` popup positioned next to the color button
- Choosing a swatch applies `fill_color` to the selected shape and persists
- Does not apply to arrows (no fill_color property currently)

## Color Palette

8 swatches displayed in a 2×4 grid popup, positioned adjacent to the color button:

| Name  | Hex        | Color               |
|-------|------------|----------------------|
| Blue  | `#3b82f6`  | Default fill         |
| Red   | `#ef4444`  | —                    |
| Green | `#22c55e`  | —                    |
| Amber | `#f59e0b`  | —                    |
| Purple| `#a855f7`  | —                    |
| Pink  | `#ec4899`  | —                    |
| White | `#ffffff`  | —                    |
| Dark  | `#1e293b`  | —                    |

- Self-closes when a swatch is clicked
- Mouse filter set to `STOP` to prevent clicks passing through to canvas