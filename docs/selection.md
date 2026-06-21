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

A floating `Control` that appears below a single selected element containing:

| Button | Action |
|---|---|
| Delete (trash icon) | Delete the selected element(s) |
| Color palette (palette icon) | Toggle an 8-color popup |
| Separator | — |
| Direction: None | Remove arrowheads |
| Direction: Mono | Single arrowhead at end (default) |
| Direction: Dual | Arrowheads at both ends |

Direction buttons are only visible for arrow elements.

## Color Palette

8 swatches: `#3b82f6` (blue), `#ef4444` (red), `#22c55e` (green), `#f59e0b` (amber), `#a855f7` (purple), `#ec4899` (pink), `#ffffff` (white), `#1e293b` (dark). Applies to all selected elements.