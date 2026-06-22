# Selection System

## Single Click

Click an element to select it. A floating **selection menu** appears below the element.

## Shift+Click (Additive)

Toggle an element in/out of the current selection set.

- `State.selected_set` (Array[Node]) tracks all selected items
- `State.selection_types` (Dictionary[Node, String]) maps element → type
- `State.primary_selection` holds the **primary** element (used for handles and drag)

## Marquee (Selection Box)

Drag on empty canvas (Select tool only) to draw a dashed selection rectangle (Control node with `draw_rect()`). Any element whose center point (shapes) or endpoints (arrows) fall within the box becomes selected.

## Multi-Drag

When multiple elements are selected, dragging any one moves all of them:
- Shapes/nodes: Offsets their `position` by the drag delta, snapping to 10px increments
- Arrows: Updates anchored endpoints to follow connected nodes; moves free-floating waypoints by the delta
- Anchor dots update in real-time

## Selection Menu

A floating `PanelContainer` that appears below a single selected element, auto-positioned in screen-space via `CanvasLayer`. Contains:

| Button | Action |
|---|---|
| Delete (text: "Del") | Delete the selected element |
| Color (text: "Color") | Opens an inline 8-color palette popup |

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
- Also triggered by Delete/Backspace keyboard shortcut (now works for both shapes and arrows)

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