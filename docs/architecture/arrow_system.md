# Arrow System

## File: `res://scenes/arrow_manager/arrow_manager.gd`

The ArrowManager is the central controller for all arrow-related functionality: anchor dot management, arrow drag creation, arrow deletion, and connected-arrow path updates.

## ArrowManager Responsibilities

- **Shape tracking**: Maintains a list of all LabelShape instances in ElementLayer
- **Anchor dots**: Creates, positions, shows, hides, and highlights anchor dot nodes
- **Arrow drag**: Manages the drag-from-anchor creation flow with bezier preview
- **Arrow storage**: Maintains `_arrows: Array[Node]` of all active arrows
- **Hit testing**: `get_arrow_near()` checks if a world-space point is near any arrow's bezier path
- **Deletion**: Single arrow deletion and bulk deletion for connected shapes

## Shape Tracking

```gdscript
var _shapes: Array[Node] = []     # All LabelShape instances
var _arrows: Array[Node] = []     # All Arrow instances
```

- `_refresh_shape_list()` scans ElementLayer on ready
- `_on_element_child_added()` / `_on_element_child_removed()` maintain the lists dynamically via `child_entered_tree` / `child_exiting_tree` signals

## Anchor Dot System

### Dot Data Structure

```gdscript
var _dot_nodes: Dictionary = {}  # shape_instance_id -> {label: Node2D}
```

Dots are created on demand and cached. Each shape can have up to 4 dot nodes (top, bottom, left, right).

### Dot Visibility (per-frame in `_process`)

1. Get mouse position in world space
2. For each shape, check distance from mouse to each anchor dot position
3. If any dot is within `ANCHOR_HOVER_RADIUS` (20px), show all dots for that shape
4. If an arrow drag is active, show all dots for all shapes
5. Otherwise, hide dots for that shape

### Dot Highlighting

The nearest dot (across all shapes) within hover radius gets highlighted:
- Normal: radius 4, fill white `#ffffff`
- Hover: radius 7, fill blue `#3b82f6`

Highlighting also updates `_drag_snapped_shape` / `_drag_snapped_label` for arrow drag snapping.

## Arrow Creation (Drag from Anchor)

### Flow

```
handle_dot_mousedown(mouse_pos)
  → Check each shape's dot positions against mouse (within DOT_RADIUS_HOVER)
  → begin_arrow_drag(shape, anchor_label)

begin_arrow_drag(shape, anchor_label)
  → Set _arrow_drag_active, _drag_start_shape, _drag_start_label, _drag_start_pos
  → Create preview Line2D (if not exists), add to ElementLayer
  → Show all anchors (_show_all_anchors)

_process() (while drag active)
  → _update_drag_preview(mouse_pos)
    → Compute bezier from start anchor to mouse (or snapped anchor)
    → Update preview line points

handle_dot_mouseup()  (called from Main._on_pointer_up)
  → end_arrow_drag()

end_arrow_drag()
  → Remove preview line
  → If _drag_snapped_shape != null and != _drag_start_shape → _create_arrow()
  → Reset drag state
```

### Preview Line

- `Line2D` node with `width = 2.0`, `default_color = Color(0.6, 0.8, 1.0)`
- Uses same bezier computation as arrows but with fewer samples (20 for performance)
- Color becomes more opaque when snapped to a valid target
- Destroyed (queue_free) on drag end

### Arrow Creation (`_create_arrow`)

1. Instantiate from `res://scenes/tools/arrow/arrow.tscn`
2. Add to ElementLayer at index 0 (renders below shapes)
3. Set start/end shape paths: `arrow.get_path_to(shape)` for both endpoints
4. Set start/end anchor labels
5. Call `rebuild_path()`
6. Append to `_arrows` array
7. Connect `multi_drag_moved` to `Main._on_multi_drag_moved`

### Creation Rules

- Arrow must connect two different shapes (self-connection prevented)
- Both endpoints must be valid anchors
- Arrow is discarded if released on empty space or the same shape

## Connected Arrow Updates

When a shape moves or resizes (`anchor_changed` signal):

```
Main._on_shape_anchor_changed(shape)
  → ArrowManager.update_arrows_for_shape(shape)
    → For each arrow in _arrows:
      → Resolve start/end shape paths
      → If either matches the changed shape:
        → arrow.rebuild_path()
```

## Arrow Deletion

### Single Arrow

```gdscript
delete_arrow(arrow):
  → Remove from _arrows array
  → Remove from parent
  → queue_free()
```

### Bulk Deletion (for shape deletion)

```gdscript
delete_arrows_for_shape(shape):
  → Find all arrows connected to shape (check both endpoints)
  → Call delete_arrow() on each
```

### Delete All

```gdscript
delete_all_arrows():
  → Iterate _arrows, queue_free each, clear array
```

## Arrow Hit Testing

```gdscript
get_arrow_near(pos, radius = 7.0):
  → Iterate _arrows in reverse (topmost first for z-order)
  → For each arrow, check _cached_bezier_points segments
  → _closest_point_on_segment() against each bezier segment
  → Return first arrow within radius
```

Uses the cached bezier points (not the HitLine Line2D directly) for hit testing. The HitLine (width=14) is an additional invisible visual for click detection, but the primary hit path uses the cached points.

## Constants

| Constant | Value | Purpose |
|---|---|---|
| `ANCHOR_HOVER_RADIUS` | 20.0 | Distance for showing anchor dots |
| `SNAP_RADIUS` | 15.0 | Snap distance for arrow endpoint attachment |
| `ARROW_CLICK_DISTANCE` | 7.0 | Distance threshold for clicking an arrow |
| `ANCHOR_OFFSET` | 5.0 | Offset of anchor dots from ellipse edge |
| `DOT_RADIUS_NORMAL` | 4.0 | Normal anchor dot radius |
| `DOT_RADIUS_HOVER` | 7.0 | Hovered/highlighted anchor dot radius |

## Not Yet Implemented

- **Waypoint insertion (Curve Mode)**: Design docs describe clicking on an arrow path to insert waypoints for custom routing. Not implemented.
- **Direction toggle**: Design docs describe mono/dual/none arrowhead direction control. Not implemented — all arrows are mono-directional with a single arrowhead at the end.
- **Arrow serialization**: Arrows are not saved/loaded. See [persistence.md](persistence.md).