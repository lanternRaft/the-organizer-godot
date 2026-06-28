# Canvas Elements

Two element types exist on the canvas: **LabelShape** (text-bearing ellipses) and **Arrow** (bezier curve connectors between shapes). Nodes (CircleNode, TriangleNode) are planned but not implemented.

---

## LabelShape

**File**: `res://scenes/tools/label_shape/label_shape.gd`

### Class Hierarchy

```
Node2D (LabelShape)
├── Area2D                   — Hit detection + overlap detection
│   └── CollisionShape2D     — CircleShape2D with radius = max(rx, ry)
├── HandleTL (ColorRect)     — Top-left resize handle
├── HandleTR (ColorRect)     — Top-right resize handle
├── HandleBL (ColorRect)     — Bottom-left resize handle
├── HandleBR (ColorRect)     — Bottom-right resize handle
└── TextLabel (Label)        — Centered, auto-scaling text display
```

All handles have `mouse_filter = MOUSE_FILTER_IGNORE` so clicks pass through to the Area2D beneath.

### Exported Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `shape_mode` | String | `"oval"` | `"oval"` or `"circle"`. Setter constrains rx/ry on circle mode |
| `rx` | float | 80.0 | Horizontal radius. Triggers redraw, collision update, handle positions, text rescale |
| `ry` | float | 50.0 | Vertical radius. Same triggers as rx |
| `text_content` | String | `""` | Label text displayed on shape |
| `fill_color` | Color | `#3b82f6` | Fill color; stroke is darkened/lightened version |

### Custom Drawing (`_draw()`)

The shape draws itself each frame via `draw_ellipse()`:

- **Fill**: Ellipse filled with `fill_color`, opacity 0.9
- **Stroke**: Ellipse outline. When not selected, stroke is `fill_color.darkened(0.4)` at width 2. When selected as primary, stroke is `fill_color.lightened(0.4)` at width 3. When selected as secondary, stroke is `fill_color.lightened(0.25)` at width 2.5.

### Drag Modes

LabelShape supports two drag modes, detected in `handle_click()`:

1. **Handle drag** (`_drag_mode = "handle"`): When click is within a handle's rect. Resizes the shape via the handle's corner.
2. **Body drag** (`_drag_mode = "body"`): When click is within the shape body (not on a handle). Moves the shape.

### Resize Behavior

- **All handles**: Each handle moves its corner. Bottom-right handle sets both rx and ry from local position. Opposite corner stays fixed.
- **10px snap**: Resize increments snap to 10px.
- **Clamp**: `[20.0, 500.0]` bounds on both axes.
- **Circle mode**: Both dimensions locked together. `dominant = max(new_rx, new_ry)`, then both set to dominant.

### Move (Body Drag) Behavior

- **Free movement**: Drag follows cursor with no snap during movement.
- **20px snap on release**: `position = position.snapped(Vector2(20.0, 20.0))`
- **Multi-drag broadcast**: During body drag, emits `multi_drag_moved(incremental_delta)` each frame so Main can shift sibling elements.

### Text Display

- **Label child**: `TextLabel` is positioned inside the shape with 10px padding
- **Word-wrap**: Text wraps at width = `rx * 2 - 2 * pad`
- **Auto-scale font**: Starts at 20px, decreases to minimum 8px to fit text vertically within `ry * 2 - 2 * pad`
- **Greedy line estimation**: `_estimate_line_count()` uses simple word-wrap to count lines for font sizing
- **Live preview**: Text updates in real-time when editing via TextEditOverlay (connected to `text_content` property)

### Shape Mode Conversion

When `shape_mode` transitions:
- **oval → circle**: `new_r = max(rx, ry)`, both set to that value
- **circle → oval`: `ry` resets to 50.0

---

## Arrow

**File**: `res://scenes/tools/arrow/arrow.gd`

### Class Hierarchy

```
Node2D (Arrow)
├── VisLine (Line2D)     — Visible stroke, width=2, white by default
└── HitLine (Line2D)     — Invisible hit zone, width=14, Color.TRANSPARENT
```

### Data Model

Arrows store references to their connected shapes via `NodePath` rather than direct references. This prevents dangling pointers when shapes are deleted:

```gdscript
var start_shape_path: NodePath
var end_shape_path: NodePath
var start_anchor_label: String  # "top", "bottom", "left", "right"
var end_anchor_label: String
```

Paths are set relative to the arrow node at creation time (`arrow.get_path_to(shape)`).

### Bezier Path Computation (`rebuild_path()`)

Called whenever either endpoint shape moves or resizes:

1. Resolve `start_shape_path` and `end_shape_path` to actual nodes
2. Get edge positions: `get_anchor_edge_position_static(shape, label)` returns the point on the ellipse boundary for the given cardinal anchor
3. Get outward normals: `get_anchor_outward_normal_static(label)` returns the direction from anchor (e.g., `"top"` → `Vector2(0, -1)`)
4. Compute control points with Catmull-Rom-style tangents:
   - Control-point reach: `clamp(segment_len * 0.35, 30.0, 100.0)` along the outward normal
   - p1 = p0 + outward_start * reach
   - p2 = p3 + outward_end * reach
5. Sample the cubic bezier at 40 points (`CURVE_SAMPLES`)
6. Cache bezier points, arrowhead tip position, and arrowhead direction for `_draw()`
7. Update both `vis_line.points` and `hit_line.points`

### Arrowhead Rendering (`_draw()`)

A filled triangle drawn at the endpoint:
- Tip: `_cached_arrowhead_tip` (p3, the end anchor edge position)
- Direction: `_cached_arrowhead_dir` (p3 - p2, normalized; falls back to p3 - p0)
- Half-width: `arrowhead_size * tan(ARROWHEAD_HALF_ANGLE)` where half-angle is ~23°
- Base points: tip - dir * size ± perp * half_width
- Color: matches `vis_line.default_color`

### Selection Visuals

- **Not selected**: `vis_line.default_color = Color(1, 1, 1)` (white)
- **Selected as primary**: `Color(0.6, 0.8, 1.0)` (solid blue)
- **Selected as secondary**: `Color(0.6, 0.8, 1.0, 0.7)` (semi-transparent blue)

### Multi-Drag Support

Emits `multi_drag_moved(delta)` during body drags. Main relays the delta to all other selected elements. Arrows do not implement `handle_drag_begin` returning true based on click detection — they are discovered through the secondary arrow-hit path in ClickHandler.

### Drag Behavior

- **Body drag**: Moves arrow node's position by delta, snapping to 20px grid on release
- **No handle drag**: Arrows cannot be resized; they have fixed visual properties

---

## Anchors

Every LabelShape has 4 cardinal anchor points. Anchor dots are managed by `ArrowManager`, not embedded in the shape scene.

### Edge Positions (for arrow endpoints)

Relative to shape center:

| Label | Position |
|---|---|
| `top` | `Vector2(0, -ry)` |
| `bottom` | `Vector2(0, ry)` |
| `left` | `Vector2(-rx, 0)` |
| `right` | `Vector2(rx, 0)` |

### Dot Positions (for visual markers)

Offset 5px outward from ellipse edge:

| Label | Position |
|---|---|
| `top` | `Vector2(0, -ry - 5)` |
| `bottom` | `Vector2(0, ry + 5)` |
| `left` | `Vector2(-rx - 5, 0)` |
| `right` | `Vector2(rx + 5, 0)` |

### Anchor Dot Nodes

Dots are lightweight `Node2D` nodes with `anchor_dot.gd` script, dynamically created/destroyed by `ArrowManager`. Visual properties are stored as node meta:

- `dot_radius`: 4px normal, 7px hover
- `dot_fill`: `Color(1, 1, 1)` normal, `Color(0.23, 0.51, 0.965)` hover
- `dot_stroke`: `Color(0.23, 0.51, 0.965)`
- `parent_shape`: reference to the owning LabelShape
- `anchor_label`: `"top"`, `"bottom"`, `"left"`, or `"right"`

### Visibility Rules

- Hidden by default
- Shown when cursor is within 20px (`ANCHOR_HOVER_RADIUS`) of any dot on a shape
- All anchors shown when an arrow drag is in progress
- All anchors hidden when not in Select mode

### Highlighting

The nearest anchor within hover radius gets highlighted: radius 7px, filled `#3b82f6` (same as default shape color). This is the snap target for arrow creation.

---

## Arrow Creation Flow (Drag from Anchor)

Managed by `ArrowManager`:

1. **Detection**: `handle_dot_mousedown()` checks if mouse is over any anchor dot (within `DOT_RADIUS_HOVER`)
2. **Begin**: `begin_arrow_drag()` sets drag state, creates preview Line2D, shows all anchors
3. **During**: `_update_drag_preview()` computes bezier from start anchor to mouse/snapped position
4. **Snap**: `_highlight_dot()` sets `_drag_snapped_shape`/`_drag_snapped_label` when cursor is within `SNAP_RADIUS` (15px) of a dot
5. **End**: `end_arrow_drag()` checks validity (different shapes), creates arrow via `_create_arrow()`, or discards

### Arrow Preview

- Dashed `Line2D` child of `ElementLayer` during drag
- 20 sample points for real-time preview
- Color: `Color(0.6, 0.8, 1.0, 0.8)` when free, `Color(0.6, 0.8, 1.0, 1.0)` when snapped

### Arrow Creation

- Instantiated from `res://scenes/tools/arrow/arrow.tscn`
- Parented to ElementLayer at index 0 (below shapes)
- Paths set via `arrow.get_path_to(shape)` for each endpoint
- `rebuild_path()` called immediately
- `multi_drag_moved` signal connected to Main
- Arrow added to `_arrows` array in ArrowManager

---

## Serialization

### LabelShape serialization:

```gdscript
{
    "type": "LabelShape",
    "position_x": float, "position_y": float,
    "rx": float, "ry": float,
    "fill_r": float, "fill_g": float, "fill_b": float, "fill_a": float,
    "text": String,
    "shape_mode": String,
}
```

### Arrow serialization (design doc, not yet implemented):

Anchor references use element-index pointers (the index of the referenced shape in the serialized array). Arrows are currently not serialized/deserialized due to the need for two-pass loading (first pass: shapes; second pass: arrows resolving indices).