# Arrow System

## File: `res://scenes/arrow_manager/arrow_manager.gd`

The ArrowManager is the central controller for all arrow-related functionality: anchor dot management, arrow drag creation, arrow deletion, and connected-arrow path updates.

## ArrowManager Responsibilities

- **Element tracking**: Maintains a list of all `CanvasElement` instances in ElementLayer (both LabelShape and CanvasNode)
- **Anchor dots**: Creates, positions, shows, hides, and highlights anchor dot nodes via the generic `CanvasElement.get_anchor_positions()` interface
- **Arrow drag**: Manages the drag-from-anchor creation flow with bezier preview, using a two-phase initiation (pending registration then activation on threshold)
- **Arrow storage**: Maintains `_arrows: Array[Node]` of all active arrows
- **Hit testing**: `get_arrow_near()` checks if a world-space point is near any arrow's bezier path
- **Deletion**: Single arrow deletion and bulk deletion for connected elements

## Element Tracking

```gdscript
var _elements: Array[CanvasElement] = []  # All CanvasElement instances (LabelShape + CanvasNode)
var _arrows: Array[Node] = []             # All Arrow instances
```

- `_refresh_element_list()` scans ElementLayer on ready, collecting all `CanvasElement` nodes
- `_on_element_child_added()` / `_on_element_child_removed()` maintain the lists dynamically via `child_entered_tree` / `child_exiting_tree` signals
- Unlike the previous design (separate `_shapes` list for LabelShape only), a single `_elements` list holds all `CanvasElement` subclasses generically

## Anchor Dot System

### Dot Data Structure

```gdscript
var _dot_nodes: Dictionary = {}  # element_instance_id -> {label: Node2D}
```

Dots are created on demand and cached. Each element can have up to N dot nodes (4 for LabelShape, 4 for circle node, 3 for triangle node), determined by `element.get_anchor_positions()`.

### Dot Visibility (per-frame in `_process`)

1. Get mouse position in world space
2. For each element, check distance from mouse to each anchor dot position
3. If any dot is within `ANCHOR_HOVER_RADIUS` (20px), show all dots for that element
4. If an arrow drag is active, show all dots for all elements
5. Otherwise, hide dots for that element

### Dot Positioning

Dot positions are computed from `element.get_anchor_positions()`:

```gdscript
func _update_dot_positions(element: CanvasElement) -> void:
    var anchors = element.get_anchor_positions()
    var world_anchor_offset = 5.0  # ANCHOR_OFFSET — outward from edge
    var eid = element.get_instance_id()
    for anchor in anchors:
        var label = anchor.label
        var offset = anchor.offset
        var world_pos = element.global_position + offset
        # Outward offset for dot visual
        var outward_dir = offset.normalized() if offset.length() > 0 else Vector2.DOWN
        var dot_pos = world_pos + outward_dir * world_anchor_offset
        # Position the dot node
        if _dot_nodes.has(eid) and _dot_nodes[eid].has(label):
            _dot_nodes[eid][label].global_position = dot_pos
```

### Dot Highlighting

The nearest dot (across all elements) within hover radius gets highlighted:
- Normal: radius 4, fill white `#ffffff`
- Hover: radius 7, fill blue `#3b82f6`

Highlighting also updates `_drag_snapped_element` / `_drag_snapped_label` for arrow drag snapping.

## Arrow Creation (Drag from Anchor)

### Two-Phase Drag Initiation

Arrow drag creation uses a **two-phase initiation** to avoid accidental arrow creation on simple clicks while maintaining priority of anchor dots over arrow endpoints.

#### Phase 1: Registration (on pointer down)

When ClickHandler detects a pointer down on an anchor dot (via secondary hit detection), it calls `handle_dot_mousedown(mouse_pos)`. This method does **not** immediately begin the drag. Instead, it records a pending drag state:

```gdscript
handle_dot_mousedown(mouse_pos)
  → Check each element's dot positions against mouse (within DOT_RADIUS_HOVER)
  → If a dot is hit, register pending drag:
    → Set _pending_drag_element, _pending_drag_label, _pending_drag_origin
    → Do NOT create preview line yet
    → Do NOT set _arrow_drag_active yet
```

#### Phase 2: Activation (on pointer move past threshold)

ClickHandler routes pointer motion events to ArrowManager via `handle_dot_mousemove(mouse_pos)`. ArrowManager checks whether a pending drag exists and whether the pointer has moved past `ARROW_DRAG_THRESHOLD` (5px) from the origin:

```gdscript
handle_dot_mousemove(mouse_pos)
  → If _pending_drag_element != null:
    → If mouse_pos.distance_to(_pending_drag_origin) >= ARROW_DRAG_THRESHOLD:
      → Call begin_arrow_drag(_pending_drag_element, _pending_drag_label)
      → Clear pending state
    → Else: ignore the motion (below threshold)
```

Once activated, the standard drag flow runs:

```gdscript
begin_arrow_drag(element, anchor_label)
  → Set _arrow_drag_active, _drag_start_element, _drag_start_label, _drag_start_pos
  → Create preview Line2D (if not exists), add to ElementLayer
  → Show all anchors (_show_all_anchors)
```

#### Phase 3: Update (during drag)

```gdscript
_process() (while drag active)
  → _update_drag_preview(mouse_pos)
    → Compute bezier from start anchor to mouse (or snapped anchor)
    → Update preview line points
```

#### Phase 4: End (on pointer up)

```gdscript
handle_dot_mouseup()  (called from Main._on_pointer_up)
  → If pending drag exists (pointer released before threshold):
    → Clear pending state (no arrow created, no preview shown)
  → If drag is active:
    → end_arrow_drag()

end_arrow_drag()
  → Remove preview line
  → If _drag_snapped_element != null and != _drag_start_element → _create_arrow()
  → Reset drag state
```

### Threshold Constant

| Constant | Value | Purpose |
|---|---|---|
| `ARROW_DRAG_THRESHOLD` | 5.0 | Minimum pointer movement (in px) before arrow drag activates. Reuses the same value as `DRAG_THRESHOLD` in ClickHandler. |

### Preview Line

- `Line2D` node with `width = 2.0`, `default_color = Color(0.6, 0.8, 1.0)`
- Uses same bezier computation as arrows but with fewer samples (20 for performance)
- Color becomes more opaque when snapped to a valid target
- Destroyed (queue_free) on drag end

### Arrow Creation (`_create_arrow`)

1. Instantiate from `res://scenes/tools/arrow/arrow.tscn`
2. Add to ElementLayer at index 0 (renders below elements)
3. Set start/end element paths: `arrow.get_path_to(element)` for both endpoints
4. Set start/end anchor labels
5. Call `rebuild_path()`
6. Append to `_arrows` array
7. Connect `multi_drag_moved` to `Main._on_multi_drag_moved`

### Creation Rules

- Arrow must connect two different elements (self-connection prevented)
- Both endpoints must be valid anchors
- Arrow is discarded if released on empty space or the same element

## Connected Arrow Updates

When an element moves or resizes (`anchor_changed` signal):

```
Main._on_element_anchor_changed(element)
  → ArrowManager.update_arrows_for_element(element)
    → For each arrow in _arrows:
      → Resolve start/end element paths
      → If either matches the changed element:
        → arrow.rebuild_path()
```

Arrow's `rebuild_path()` reads anchor positions from the `CanvasElement` via `get_anchor_positions()`, so no per‑type conditional logic is needed.

## Arrow Deletion

### Single Arrow

```gdscript
delete_arrow(arrow):
  → Remove from _arrows array
  → Remove from parent
  → queue_free()
```

### Bulk Deletion (for element deletion)

```gdscript
delete_arrows_for_element(element):
  → Find all arrows connected to element (check both endpoints)
  → Call delete_arrow() on each
```

When a `CanvasElement` emits `delete_requested`, ArrowManager listens and calls `delete_arrows_for_element()` before the element is freed.

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

**Arrow endpoints are part of the cached bezier point set**, so clicking near an arrow endpoint can select the arrow. However, because ClickHandler's secondary hit detection checks anchor dots **before** arrow bodies, an arrow endpoint at the same screen position as an anchor dot will never be selected — the anchor dot takes priority.

## Constants

| Constant | Value | Purpose |
|---|---|---|
| `ANCHOR_HOVER_RADIUS` | 20.0 | Distance for showing anchor dots |
| `SNAP_RADIUS` | 15.0 | Snap distance for arrow endpoint attachment |
| `ARROW_CLICK_DISTANCE` | 7.0 | Distance threshold for clicking an arrow |
| `ARROW_DRAG_THRESHOLD` | 5.0 | Minimum movement to activate arrow drag from anchor dot |
| `ANCHOR_OFFSET` | 5.0 | Offset of anchor dots from element edge |
| `DOT_RADIUS_NORMAL` | 4.0 | Normal anchor dot radius |
| `DOT_RADIUS_HOVER` | 7.0 | Hovered/highlighted anchor dot radius |

## Not Yet Implemented

- **Waypoint insertion (Curve Mode)**: Design docs describe clicking on an arrow path to insert waypoints for custom routing. Not implemented.
- **Direction toggle**: Design docs describe mono/dual/none arrowhead direction control. Not implemented — all arrows are mono-directional with a single arrowhead at the end.
- **Arrow serialization**: Arrows are not saved/loaded. See [persistence.md](persistence.md).