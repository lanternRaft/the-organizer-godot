# Canvas Elements

Two element types exist on the canvas: **LabelShape** (text-bearing ellipses), **CanvasNode** (fixed-size circle/triangle nodes), and **Arrow** (bezier curve connectors between elements). All shape-like elements inherit from the `CanvasElement` base class.

---

## Class Hierarchy

```
Node2D
└── CanvasElement (script-only base class)
    ├── LabelShape — ellipse shapes with text, resize handles, legend entry
    └── CanvasNode — fixed-size circle/triangle nodes, no text, no legend entry
```

`Arrow` remains a standalone `Node2D` subclass (not a `CanvasElement`), since arrows are connectors, not independently interactable canvas elements with anchors and selection state.

---

## CanvasElement (Base Class)

**File**: `res://scenes/canvas_elements/canvas_element.gd`

All common behaviors are consolidated in this base class:

- **Selection state**: `is_selected`, `is_primary` properties with redraw triggers
- **Drag lifecycle**: `handle_click()`, `handle_drag_begin()`, `handle_drag_move()`, `handle_drag_end()` methods called by ClickHandler
- **Grid snapping**: `grid_snap_size = 20.0` applied on drag release
- **Anchor point system**: `get_anchor_positions()` returns an array of `{label, offset}` dictionaries
- **Deletion cascade**: `delete_requested` signal triggers ArrowManager to remove connected arrows
- **Signals**: `clicked`, `double_clicked`, `selected_changed`, `primary_changed`, `dragged`, `drag_ended`, `anchor_changed`, `delete_requested`
- **Group membership**: Auto-registers in `"clickable_element"` group for ClickHandler discovery

See [shared_element_base.md](shared_element_base.md) for the full API.

---

## LabelShape

**File**: `res://scenes/tools/label_shape/label_shape.gd`
**Extends**: `CanvasElement`

### Class Hierarchy

```
CanvasElement (LabelShape)
├── Area2D                   — Hit detection + overlap detection
│   └── CollisionShape2D     — CircleShape2D with radius = max(rx, ry)
├── HandleTL (ColorRect)     — Top-left resize handle
├── HandleTR (ColorRect)     — Top-right resize handle
├── HandleBL (ColorRect)     — Bottom-left resize handle
├── HandleBR (ColorRect)     — Bottom-right resize handle
└── TextLabel (Label)        — Centered, auto-scaling text display
```

All handles have `mouse_filter = MOUSE_FILTER_IGNORE` so clicks pass through to the Area2D beneath.

### Exported Properties (in addition to CanvasElement)

| Property | Type | Default | Description |
|---|---|---|---|
| `shape_mode` | String | `"oval"` | `"oval"` or `"circle"`. Setter constrains rx/ry on circle mode |
| `rx` | float | 80.0 | Horizontal radius. Triggers redraw, collision update, handle positions, text rescale |
| `ry` | float | 50.0 | Vertical radius. Same triggers as rx |
| `text_content` | String | `""` | Label text displayed on shape |

### CanvasElement Overrides

| Property/Method | Value |
|---|---|
| `supports_text_editing` | `true` |
| `shows_in_legend` | `true` |
| `get_element_type()` | `"LabelShape"` |
| `get_anchor_positions()` | 4 cardinal points at ellipse edge |
| `on_drag_move(delta)` | Detects handle vs. body drag. Handle drag resizes rx/ry. Body drag moves position. |
| `on_drag_end()` | Inherits grid snap. Resize snaps to 10px. |

### Custom Drawing (`_draw()`)

The shape draws itself each frame via `draw_ellipse()`:

- **Fill**: Ellipse filled with `fill_color`, opacity 0.9
- **Stroke**: Ellipse outline. When not selected, stroke is `fill_color.darkened(0.4)` at width 2. When selected as primary, stroke is `fill_color.lightened(0.4)` at width 3. When selected as secondary, stroke is `fill_color.lightened(0.25)` at width 2.5.

Selection highlight parameters come from the base class's `_draw()` convention — subclasses apply `is_primary` / `is_selected` to their own stroke rendering.

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
- **20px snap on release**: `position = position.snapped(Vector2(20.0, 20.0))` — inherited from CanvasElement.
- **Multi-drag broadcast**: During body drag, emits `dragged(incremental_delta, self)` each frame so Main can shift sibling elements.

### Text Display

- **Label child**: `TextLabel` is positioned inside the shape with 10px padding
- **Word-wrap**: Text wraps at width = `rx * 2 - 2 * pad`
- **Auto-scale font**: Starts at 20px, decreases to minimum 8px to fit text vertically within `ry * 2 - 2 * pad`
- **Greedy line estimation**: `_estimate_line_count()` uses simple word-wrap to count lines for font sizing
- **Live preview**: Text updates in real-time when editing via TextEditOverlay (connected to `text_content` property)

### Shape Mode Conversion

When `shape_mode` transitions:
- **oval → circle**: `new_r = max(rx, ry)`, both set to that value
- **circle → oval**: `ry` resets to 50.0

---

## CanvasNode

**File**: `res://scenes/canvas_elements/canvas_node.gd`
**Extends**: `CanvasElement`

### Class Hierarchy

```
CanvasElement (CanvasNode)
├── Area2D
│   └── CollisionShape2D (circle) or CollisionPolygon2D (triangle)
└── (no other children — fixed size, no text, no legend entry)
```

### Exported Properties (in addition to CanvasElement)

| Property | Type | Default | Description |
|---|---|---|---|
| `node_type` | String | `"circle"` | `"circle"` or `"triangle"` |
| `radius` | float | 40.0 | Fixed radius. Not resizable via handles. |

### CanvasElement Overrides

| Property/Method | Value |
|---|---|
| `supports_text_editing` | `false` |
| `shows_in_legend` | `false` |
| `get_element_type()` | `"CanvasNode"` |
| `get_anchor_positions()` | 4 anchors (circle) or 3 anchors (triangle) |
| `on_drag_move(delta)` | Body drag only (no resize handles). Moves position by delta. |
| `on_drag_end()` | Inherits grid snap (position snapped to 20px). |

### Custom Drawing (`_draw()`)

- **Circle**: Filled circle with `fill_color`, stroke outline based on selection state.
- **Triangle**: Filled equilateral triangle (pointing up) with `fill_color`, stroke outline based on selection state.

Selection visual parameters follow the base class convention (same lightening/darkening pattern as LabelShape).

### Behavior

- **Fixed size**: Nodes cannot be resized. No resize handles are created.
- **No text editing**: `supports_text_editing = false` disables the text overlay.
- **No legend entry**: `shows_in_legend = false` excludes node colors from the legend panel.
- **Body drag only**: Clicks anywhere on the body initiate a body drag.

---

## Arrow

**File**: `res://scenes/tools/arrow/arrow.gd`
**Extends**: `Node2D` (not CanvasElement)

### Class Hierarchy

```
Node2D (Arrow)
├── VisLine (Line2D)     — Visible stroke, width=2, white by default
└── HitLine (Line2D)     — Invisible hit zone, width=14, Color.TRANSPARENT
```

### Data Model

Arrows store references to their connected elements via `NodePath`:

```gdscript
var start_element_path: NodePath
var end_element_path: NodePath
var start_anchor_label: String  # e.g., "top", "bottom", "left", "right"
var end_anchor_label: String
```

Paths are set relative to the arrow node at creation time (`arrow.get_path_to(element)`).

### Bezier Path Computation (`rebuild_path()`)

Called whenever either endpoint element moves or resizes:

1. Resolve `start_element_path` and `end_element_path` to actual `CanvasElement` nodes
2. Get edge positions via `get_anchor_world_positions()` on each element
3. Find the anchor position matching the stored label
4. Compute outward normals: derived from anchor label (e.g., `"top"` → `Vector2(0, -1)`)
5. Compute control points with Catmull-Rom-style tangents:
   - Control-point reach: `clamp(segment_len * 0.35, 30.0, 100.0)` along the outward normal
   - p1 = p0 + outward_start * reach
   - p2 = p3 + outward_end * reach
6. Sample the cubic bezier at 40 points (`CURVE_SAMPLES`)
7. Cache bezier points, arrowhead tip position, and arrowhead direction for `_draw()`
8. Update both `vis_line.points` and `hit_line.points`

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

Emits `multi_drag_moved(delta)` during body drags. Main relays the delta to all other selected elements. Arrows are discovered through the secondary arrow-hit path in ClickHandler.

### Drag Behavior

- **Body drag**: Moves arrow node's position by delta, snapping to 20px grid on release
- **No handle drag**: Arrows cannot be resized; they have fixed visual properties

---

## Anchor Positions (via CanvasElement.get_anchor_positions())

Anchor data is now data-driven via the base class. ArrowManager calls `get_anchor_positions()` generically — no per-type conditional logic.

### LabelShape (4 cardinal points)

| Label | Offset (from center) |
|---|---|
| `top` | `Vector2(0, -ry)` |
| `bottom` | `Vector2(0, ry)` |
| `left` | `Vector2(-rx, 0)` |
| `right` | `Vector2(rx, 0)` |

### CanvasNode — Circle (4 points)

| Label | Offset (from center) |
|---|---|
| `top` | `Vector2(0, -radius)` |
| `bottom` | `Vector2(0, radius)` |
| `left` | `Vector2(-radius, 0)` |
| `right` | `Vector2(radius, 0)` |

### CanvasNode — Triangle (3 points)

| Label | Offset (from center) |
|---|---|
| `top` | `Vector2(0, -radius)` |
| `bottom_left` | `Vector2(-radius * 0.866, radius * 0.5)` |
| `bottom_right` | `Vector2(radius * 0.866, radius * 0.5)` |

### Anchor Dot Nodes

Dots are managed by `ArrowManager`, not embedded in element scenes. Dot positions are offset 5px outward from the anchor edge position. See [arrow_system.md](arrow_system.md) for full dot management details.

---

## Arrow Creation Flow (Drag from Anchor)

Managed by `ArrowManager` — see [arrow_system.md](arrow_system.md). The flow is identical for both element types since ArrowManager now uses the generic `CanvasElement` anchor interface.

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

### CanvasNode serialization:

```gdscript
{
    "type": "CanvasNode",
    "position_x": float, "position_y": float,
    "node_type": String,  # "circle" or "triangle"
    "radius": float,
    "fill_r": float, "fill_g": float, "fill_b": float, "fill_a": float,
}
```

### Arrow serialization (design doc, not yet implemented):

Anchor references use element-index pointers (the index of the referenced element in the serialized array). Arrows are currently not serialized/deserialized due to the need for two-pass loading (first pass: elements; second pass: arrows resolving indices).