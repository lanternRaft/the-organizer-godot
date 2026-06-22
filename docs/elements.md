# Elements

## Shapes (Labels)

`LabelShape` scene (Node2D with custom `_draw()`):

- **Two shape modes** (set via `@export var shape_mode: String`):
  - **Oval**: Default size `rx=80`, `ry=50`
  - **Circle**: Default size `rx=80`, `ry=80`
- **Colorable**: Default fill `#3b82f6` (stored as `Color(0.231, 0.51, 0.965)`)
- **Opacity**: 0.9
- **Resize**: 4 corner handles (ColorRect children) appear on selection; drag to resize (snaps to 10px increments)
  - In Circle mode, handles constrain to equal `rx`/`ry` (distance from center)
  - In Oval mode, handles allow independent `rx`/`ry`
- **Drag to move**: Smooth free movement while dragging; snaps to 20px increments on release
- **Placement**: Initial placement via click (no snap)
- **Stroke**: Darkened version of fill color (40% darker) at `width=2`; on selection, lightened version (40% lighter) at `width=3`
- **Text**:
  - Press **Enter** on a selected shape to open a `TextEdit` overlay centered over the shape
  - **Enter** (without Shift) commits text, **Escape** cancels
  - Text is word-wrapped to fit within `rx * 1.4` width
  - Font size auto-scales to fit vertically within `ry * 1.6` (minimum 8px)
  - Rendered as a `Label` child node, centered, color `#ffffff`
  - Stored as `shape.text_content: String`
- **Hit testing**: `Area2D` child with `CollisionShape2D` sized to the ellipse bounding box

### Implementation Outline (LabelShape.gd)

```gdscript
extends Node2D

@export var fill_color: Color = Color(0.231, 0.51, 0.965)
@export var shape_mode: String = "oval"  # "oval" or "circle"
@export var rx: float = 80.0
@export var ry: float = 50.0
@export var text_content: String = ""
@export var text_node: Label = null

func _draw():
    # Draw ellipse using draw_ellipse() or draw_circle()
    # Draw stroke outline
    # If highlighted/selected, draw selection stroke
    pass
```

## Nodes

Two node modes (selected via dropdown):

**Circle Node** — `CircleNode` scene (Area2D with CollisionShape2D):
- **Fixed size**: `NODE_RADIUS = 8` (radius 8px)
- **Colorable**: Default fill `#3b82f6`
- **No resize handles** on selection
- **Stroke**: Same rules as shapes (darkened/lightened fill)
- **4 cardinal anchor points** at N/S/E/W
- `node_mode = "circle"` stored as a property

**Triangle Node** — `TriangleNode` scene (Area2D with CollisionPolygon2D):
- **Fixed size**: `NODE_SIZE = 8` (circumradius)
- **Colorable**: Default fill `#3b82f6`
- **No resize handles** on selection
- **Stroke**: Same rules as shapes (darkened/lightened fill)
- **3 vertex anchor points** at top, bottomLeft, bottomRight
- `node_mode = "triangle"` stored as a property

Both modes share the same click/drag/select/color/delete behavior.

## Arrows

`Arrow` scene (Node2D with Line2D children):

- **Two Line2D children**: `vis_line` (visible stroke) and `hit_line` (wider invisible stroke for easier clicking, `width=14`)
- **Waypoint-based data model**: `points` is a `PackedVector2Array` (minimum 2 points)
- **Path computation**: Cubic bezier curves using **Catmull-Rom tangents** for C1 continuity through every waypoint, combined with `ARROWHEAD_ANCHOR_EXT=15px` straight extensions from anchors. The path draws to the exact ellipse edge; the arrowhead tip is placed at that endpoint.
  - Anchored endpoints: the arrow extends 15px straight out from each anchor before curving.
  - Intermediate waypoints: the tangent at node *i* is `(nodes[i+1] − nodes[i-1]).normalized()` (Catmull-Rom).
  - Control-point reach: `clamp(segLen * 0.35, 30, 100)` px along the tangent direction.
- **Direction** (controlled via selection menu buttons):
  - `mono` (default): Single arrowhead at end
  - `dual`: Arrowheads at both start and end
  - `none`: No arrowheads
  - Arrowheads rendered via `draw_triangle()` at line endpoints in `_draw()`
- **Waypoint insertion (Curve Mode)**: Waypoints can only be added when **Curve Mode** is active. Curve mode is toggled via the curve button in the selection menu. When active, clicking/dragging on the arrow path inserts a new waypoint and enters a drag loop. Curve mode deactivates on deselection.
- **Curve mode state**: Tracked in `State.curve_mode_arrows: Array[Node]`.
- **Hit testing**: `hit_line` has `width=14` and `default_color=Color.TRANSPARENT`

### Arrow Creation (Drag from Anchor)

Arrows are created by clicking and dragging from an anchor point to another anchor point. This works in **Select** mode.

**Flow:**
1. **Hover** near a shape (within 20px of any anchor point) — the shape's 4 anchor dots appear
2. **Hover** directly over an anchor dot — the dot highlights (larger, filled blue)
3. **Mousedown** on an anchor dot → arrow drag begins
   - A dashed preview line appears from the start anchor, following the cursor
   - All shapes' anchor dots become visible
   - The start anchor remains highlighted
4. **Drag** the cursor — the preview line snaps to the nearest anchor within 15px
   - The nearest anchor highlights as a valid drop target
5. **Mouseup** over a different shape's anchor → arrow is created, anchored on both ends
6. **Mouseup** not over a valid anchor (same shape, or empty space) → arrow is discarded

**Key rules:**
- Arrows **must** be anchored on both ends — unanchored arrows are discarded
- You cannot connect a shape to itself (start and end must be different shapes)
- Existing arrows can still be re-anchored via endpoint handles

### Arrow Preview

During drag, a dashed `Line2D` preview shows the intended curve.

### Arrow Drag State (in ArrowManager.gd)

```gdscript
var arrow_drag_active: bool = false
var drag_start_anchor: Dictionary = {}  # { "shape": Node, "label": String, "pos": Vector2 }
var drag_preview_line: Line2D = null
var drag_snapped_end: Dictionary = {}  # { "shape": Node, "pos": Vector2, "label": String } or empty
```

## Anchors

Every shape/node has anchor points. Two sets of positions are maintained:

**Edge positions** (for arrow endpoints) — returned by `get_anchor_points()`:

**Ellipses** (4 cardinal points):
- `top`: `Vector2(cx, cy - ry)`
- `left`: `Vector2(cx - rx, cy)`
- `bottom`: `Vector2(cx, cy + ry)`
- `right`: `Vector2(cx + rx, cy)`

**Triangle nodes** (3 vertex points):
- `top`: top vertex of the equilateral triangle
- `bottom_left`: bottom-left vertex
- `bottom_right`: bottom-right vertex

**Dot positions** — each offset `ANCHOR_OFFSET = 5` px outward:

**Ellipses**:
- `top`: `Vector2(cx, cy - ry - 5)`
- `left`: `Vector2(cx - rx - 5, cy)`
- `bottom`: `Vector2(cx, cy + ry + 5)`
- `right`: `Vector2(cx + rx + 5, cy)`

**Triangle nodes** (not yet implemented): Each dot is offset 5px outward from the vertex along the direction from center to that vertex.

`find_anchor_near(pos: Vector2, radius: float = 15.0)` snaps based on dot positions but returns the edge position.

Anchor dots are small `ColorRect` or `Node2D` with `draw_circle()` elements, white fill, blue stroke, radius 4. Dots have `input_pickable = true` and store references via meta properties (`set_meta("parent_shape", shape)`, `set_meta("anchor_label", "top")`).

**Visibility**: Anchors are shown when:
- The cursor is near a shape (within 20px radius `ANCHOR_HOVER_RADIUS`)
- An arrow is in the selected set (for endpoint re-attachment)
- An arrow drag is in progress (all shapes' anchors visible)

**Highlighting**: The nearest anchor gets highlighted (radius 7, filled blue `#3b82f6`).

**Snap**: Arrow endpoints snap to nearest anchor within 15px radius.

**Endpoint attachment**: Arrow stores anchor references: `arrow.set_meta("anchors", [{"end": "start", "shape": Node, "label": "top"}, {"end": "end", "shape": Node, "label": "bottom"}])`. When a connected shape moves, `update_anchored_arrows()` updates the arrow endpoint.