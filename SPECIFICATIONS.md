# The Organizer — Godot Implementation

A canvas-based whiteboarding tool for world building — notes, flow charts, and relational diagrams. Built in **Godot 4.7** using GDScript and the built-in rendering engine.

This document is a translation of the canonical SVG DOM specification (`../SPECIFICATIONS.md`) into Godot terms. It is the **canonical contract** for the Godot implementation.

---

## Technology Stack

- **Godot 4.7** — Open-source game engine with built-in 2D rendering, input handling, signals, and scene system
- **GDScript** — All game logic scripts
- **`editor` export mode** for development; runs natively on macOS, Windows, Linux

---

## Scene Tree Architecture

The main scene structure:

```
Main (Node)
├── Canvas (Node2D)
│   ├── GridOverlay (Node2D)            — background grid
│   ├── ElementLayer (Node2D)           — all shapes, nodes, arrows
│   │   ├── LabelShape (Node2D)*        — ellipse labels
│   │   ├── CircleNode (Area2D)*        — small circle nodes
│   │   ├── TriangleNode (Area2D)*      — small triangle nodes
│   │   └── Arrow (Node2D)*             — arrow curves
│   ├── AnchorLayer (Node2D)            — anchor dot markers
│   └── PreviewLine (Line2D)            — dashed arrow preview during drag
├── UI (CanvasLayer)                    — pinned to screen
│   ├── Toolbar (Control)               — bottom-center tool buttons
│   ├── SelectionMenu (Control)         — floating menu below selection
│   ├── ColorPalette (Control)          — 8-swatch popup
│   ├── LegendPanel (Control)           — bottom-left color legend
│   ├── ZoomControls (Control)          — bottom-right zoom buttons
│   ├── InfoBar (Label)                 — centered bottom hint text
│   ├── HamburgerMenu (Control)         — top-left menu button + dropdown
│   ├── ConfirmDialog (AcceptDialog)    — Clear Canvas confirmation
│   └── TextEditOverlay (TextEdit)      — inline text editor for labels
├── MainCamera (Camera2D)               — pan/zoom via camera transforms
└── EventBus (Node)                     — signal relay for cross-system events
```

### Key Godot Concepts

| SVG DOM Concept | Godot Equivalent |
|---|---|
| SVG `<ellipse>` element | `Node2D` with `draw_circle()` / `draw_ellipse()` via `_draw()` |
| SVG `<polygon>` element | `Node2D` with `draw_colored_polygon()` via `_draw()` |
| SVG `<path>` element | `Line2D` node or `draw_polyline()` via `_draw()` |
| SVG `<text>` / `<tspan>` | `RichTextLabel` or `Label` node as child |
| SVG `<marker>` defs | Custom `_draw()` arrowhead rendering at line endpoints |
| SVG `<g>` group | `Node2D` parent |
| SVG `viewBox` | `Camera2D` position and zoom |
| CSS styles / selectors | `.theme` files or `@export` variables |
| `mousedown` / `mousemove` / `mouseup` | `_input()` / `_unhandled_input()` / `Area2D` signals |
| `localStorage` | `ConfigFile` or `ResourceSaver` to `user://` |
| `getBoundingClientRect()` | `get_viewport().get_camera_2d()` + `get_global_mouse_position()` |
| `createSVGPoint()` + `getScreenCTM()` | `get_global_mouse_position()` (automatic camera transform) |
| JS `Set` / `Map` | GDScript `Array` / `Dictionary` |

---

## Tool Modes

A toolbar at the bottom center of the screen provides tool modes. After placing an element (label or node), the app auto-switches back to **Select** mode.

| Tool | Button Label | Behavior |
|---|---|---|
| Select | Select | Click/drag to select and move elements. Default mode. Also used for arrow creation — see Arrow section below. |
| Shape | Oval / Circle | Dropdown button; click to toggle between Oval and Circle. Click canvas to place the shape. |
| Node | Circle / Triangle | Dropdown button; click to toggle between Circle and Triangle. Click canvas to place the node. |

### Shape Tool Dropdown

The Oval/Circle button opens a small popup (`PopupMenu`) above it. Selecting a mode updates the button label and the info text. The dropdown closes on outside click.

### Node Tool Dropdown

The Circle/Triangle button (Node tool) opens a small popup above it, following the same UX pattern as the Shape dropdown. Selecting a mode updates the button label and the info text.

---

## State Management

A singleton autoload `State` (global.gd) holds all shared state:

| Variable | Type | Purpose |
|---|---|---|
| `tool_mode` | String (`select`/`label`/`shape`/`node`) | Current active tool |
| `shape_mode` | String (`oval`/`circle`) | Selected shape variant |
| `node_mode` | String (`circle`/`triangle`) | Selected node variant |
| `selected_set` | Array[Node] | All currently selected elements |
| `primary_selection` | Node | Primary (last-clicked) element |
| `selection_types` | Dictionary[Node, String] | Maps element → `"LabelShape"`/`"CircleNode"`/`"TriangleNode"`/`"Arrow"` |
| `camera` | Camera2D | Reference to the main camera |
| `element_layer` | Node2D | Container for all canvas elements |
| `anchor_layer` | Node2D | Container for anchor dots |
| `legend_colors` | Dictionary[String, String] | Color → custom name mapping |
| `clipboard` | Array[Dictionary] | Serialized copied elements |

The `EventBus` autoload relays signals:

| Signal | Arguments | Emitted When |
|---|---|---|
| `canvas_changed` | — | Any mutation occurs (trigger save) |
| `tool_changed` | new_tool: String | Tool mode switches |
| `selection_changed` | — | Selection set changes |
| `element_created` | element: Node | New element added |
| `element_deleted` | element: Node | Element removed |
| `text_edit_requested` | shape: Node | Enter key on selected shape |
| `anchor_interaction_started` | shape: Node, anchor: String | Mousedown on anchor dot |
| `anchor_interaction_ended` | — | Mouseup after anchor drag |

---

## Elements

### Shapes (Labels)

`LabelShape` scene (Node2D with custom `_draw()`):

- **Two shape modes** (set via `@export var shape_mode: String`):
  - **Oval**: Default size `rx=40`, `ry=25`
  - **Circle**: Default size `rx=40`, `ry=40`
- **Colorable**: Default fill `#3b82f6` (stored as `Color(0.231, 0.51, 0.965)`)
- **Opacity**: 0.9
- **Resize**: 4 corner handles (ColorRect children) appear on selection; drag to resize (snaps to 10px increments)
  - In Circle mode, handles constrain to equal `rx`/`ry` (distance from center)
  - In Oval mode, handles allow independent `rx`/`ry`
- **Drag to move**: Snaps to 10px increments
- **Placement**: Initial placement via click snaps to 10px increments
- **Stroke**: Darkened version of fill color (40% darker) at `width=2`; on selection, lightened version (40% lighter) at `width=3`
- **Text**:
  - Press **Enter** on a selected shape to open a `TextEdit` overlay centered over the shape
  - **Enter** (without Shift) commits text, **Escape** cancels
  - Text is word-wrapped to fit within `rx * 1.4` width
  - Font size auto-scales to fit vertically within `ry * 1.6` (minimum 8px)
  - Rendered as a `Label` child node, centered, color `#ffffff`
  - Stored as `shape.text_content: String`
- **Hit testing**: `Area2D` child with `CollisionShape2D` sized to the ellipse bounding box

#### Implementation Outline (LabelShape.gd)

```gdscript
extends Node2D

@export var fill_color: Color = Color(0.231, 0.51, 0.965)
@export var shape_mode: String = "oval"  # "oval" or "circle"
@export var rx: float = 40.0
@export var ry: float = 25.0
@export var text_content: String = ""
@export var text_node: Label = null

func _draw():
    # Draw ellipse using draw_ellipse() or draw_circle()
    # Draw stroke outline
    # If highlighted/selected, draw selection stroke
    pass
```

### Nodes

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

### Arrows

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

#### Arrow Creation (Drag from Anchor)

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

#### Arrow Preview

During drag, a dashed `Line2D` preview shows the intended curve.

#### Arrow Drag State (in ArrowManager.gd)

```gdscript
var arrow_drag_active: bool = false
var drag_start_anchor: Dictionary = {}  # { "shape": Node, "label": String, "pos": Vector2 }
var drag_preview_line: Line2D = null
var drag_snapped_end: Dictionary = {}  # { "shape": Node, "pos": Vector2, "label": String } or empty
```

### Anchors

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

**Triangle nodes**: Each dot is offset 5px outward from the vertex along the direction from center to that vertex.

`find_anchor_near(pos: Vector2, radius: float = 15.0)` snaps based on dot positions but returns the edge position.

Anchor dots are small `ColorRect` or `Node2D` with `draw_circle()` elements, white fill, blue stroke, radius 4. Dots have `input_pickable = true` and store references via meta properties (`set_meta("parent_shape", shape)`, `set_meta("anchor_label", "top")`).

**Visibility**: Anchors are shown when:
- The cursor is near a shape (within 20px radius `ANCHOR_HOVER_RADIUS`)
- An arrow is in the selected set (for endpoint re-attachment)
- An arrow drag is in progress (all shapes' anchors visible)

**Highlighting**: The nearest anchor gets highlighted (radius 7, filled blue `#3b82f6`).

**Snap**: Arrow endpoints snap to nearest anchor within 15px radius.

**Endpoint attachment**: Arrow stores anchor references: `arrow.set_meta("anchors", [{"end": "start", "shape": Node, "label": "top"}, {"end": "end", "shape": Node, "label": "bottom"}])`. When a connected shape moves, `update_anchored_arrows()` updates the arrow endpoint.

---

## Selection System

### Single Click

Click an element to select it. A floating **selection menu** appears below the element.

### Shift+Click (Additive)

Toggle an element in/out of the current selection set.

- `State.selected_set` (Array[Node]) tracks all selected items
- `State.selection_types` (Dictionary[Node, String]) maps element → type
- `State.primary_selection` holds the **primary** element (used for handles and drag)

### Marquee (Selection Box)

Drag on empty canvas (Select tool only) to draw a dashed selection rectangle (Control node with `draw_rect()`). Any element whose center point (shapes) or endpoints (arrows) fall within the box becomes selected.

### Multi-Drag

When multiple elements are selected, dragging any one moves all of them:
- Shapes/nodes: Offsets their `position` by the drag delta, snapping to 10px increments
- Arrows: Updates anchored endpoints to follow connected nodes; moves free-floating waypoints by the delta
- Anchor dots update in real-time

### Selection Menu

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

### Color Palette

8 swatches: `#3b82f6` (blue), `#ef4444` (red), `#22c55e` (green), `#f59e0b` (amber), `#a855f7` (purple), `#ec4899` (pink), `#ffffff` (white), `#1e293b` (dark). Applies to all selected elements.

---

## Keys / Legend

An auto-generated legend panel in the bottom-left corner that lists colors currently in use on the canvas. Each entry has:

- A colored circle swatch (`ColorRect`)
- An editable label (`LineEdit` node) — click to rename
- Default names: `Group 1`, `Group 2`, etc.
- Custom names are stored in `State.legend_colors` Dictionary and persist until the color is no longer in use
- Hidden when no colors are in use

---

## Pan & Zoom

The canvas implements a **Camera2D-based** pan and zoom system. Rather than manipulating a viewBox, the camera node's `position`, `zoom`, and `transform` are adjusted.

### State (State.gd)

- `camera: Camera2D` — reference to `MainCamera`
- `zoom_level: float` — current zoom factor (1.0 = 100%)
- `MIN_ZOOM: float = 0.1` — 10% minimum
- `MAX_ZOOM: float = 20.0` — 2000% maximum

### Zoom Controls (UI)

A vertical button stack in the **bottom-right corner** (Godot `VBoxContainer`, anchored to bottom-right via layout) provides three buttons:

| Button | Action | Tooltip |
|---|---|---|
| + (plus) | Zoom in by factor 1.25×, centered on viewport center | Zoom in (Ctrl+=) |
| − (minus) | Zoom out by factor 0.8×, centered on viewport center | Zoom out (Ctrl+-) |
| ⟳ (reset) | Reset to 100% zoom, camera position to (0,0) | Reset zoom (Ctrl+0) |

### Zoom Implementation

```gdscript
func zoom_by_factor(factor: float, focus_pos: Vector2 = Vector2.INF):
    var new_zoom = camera.zoom * factor
    new_zoom = Vector2(
        clamp(new_zoom.x, MIN_ZOOM, MAX_ZOOM),
        clamp(new_zoom.y, MIN_ZOOM, MAX_ZOOM)
    )
    camera.zoom = new_zoom
    # If focus_pos provided, adjust camera position to zoom around that point
    if focus_pos != Vector2.INF:
        var viewport_center = get_viewport_rect().size / 2.0
        var offset = focus_pos - viewport_center
        camera.position += offset * (1.0 - 1.0 / factor)
```

### Scroll-Wheel / Trackpad Zoom & Pan

The main viewport's `_input(event)` distinguishes:

| Gesture | Detection | Behaviour |
|---|---|---|
| **Mouse wheel** (notch) | `event is InputEventMouseButton` with `button_index == MOUSE_BUTTON_WHEEL_UP`/`DOWN` | Zoom centered on cursor position. Factor = 1.25 or 0.8 |
| **Trackpad pinch-to-zoom** | `event is InputEventMagnifyGesture` | Zoom by `event.factor`, centered on gesture focus |
| **Trackpad two-finger pan** | `event is InputEventPanGesture` | Pan camera by `event.delta * zoom` |
| **Middle-click drag pan** | `MOUSE_BUTTON_MIDDLE` held + `_input()` mouse motion | Pan camera position |

### Touch Pinch-to-Zoom

Handled via `InputEventScreenDrag` / `InputEventScreenTouch` / `InputEventMagnifyGesture` — Godot provides built-in magnify gesture detection.

### Keyboard Shortcuts

| Key | Action |
|---|---|
| **Ctrl/Cmd + =** (or **+**) | Zoom in by 1.25×, centered on viewport center |
| **Ctrl/Cmd + -** | Zoom out by 0.8×, centered on viewport center |
| **Ctrl/Cmd + 0** | Reset zoom to 100% |
| **Escape** | Hide context menu, cancel arrow placement, hide text input |
| **Enter** | Open text editor on selected shape |
| **Ctrl/Cmd + C** | Copy selected element(s) to clipboard |
| **Ctrl/Cmd + V** | Paste from clipboard |
| **Ctrl/Cmd + A** | Select all elements |
| **Delete / Backspace** | Delete selected element(s) (Select tool only, not in text input) |

### Coordinate Transforms

All pointer coordinate conversions use `get_global_mouse_position()` (automatically accounts for camera transform) and `to_local()` / `to_global()` for element-local coordinates.

### Resize Behaviour

On window resize, Godot's layout system automatically adjusts Control nodes. The camera's zoom remains unchanged.

### Export PNG Interaction

When exporting to PNG (Export PNG from hamburger menu), the export computation uses the **logical bounding box** of all elements + padding, not the current camera viewport. A `Viewport` is temporarily rendered at 2× resolution with a camera positioned to frame the bounding box.

---

## Copy / Paste

In-memory clipboard stores serialized copies of selected elements:

- **Shapes**: `{ type, position.x, position.y, rx, ry, fill, text }`
- **Nodes**: `{ type, position.x, position.y, fill, node_shape }` — `node_shape` is `"circle"` or `"triangle"`
- **Arrows**: `{ type, points: PackedVector2Array, color }`

Pasted elements are offset by +20px from original and become selected.

---

## UI Controls

### Grid Toggle

Button (top-right, next to theme toggle) with grid icon. Toggles a `GridOverlay` Node2D that draws a grid in `_draw()` (40px spacing). Persisted to `ConfigFile` as `grid`.

### Theme Toggle

Button (top-right corner) with sun/moon icons. Toggles between `"dark"` and `"light"` themes. Implemented via `Theme` resources and/or ` modulate` on UI elements. Persisted to `ConfigFile` as `theme`.

### Info Bar

A `Label` at the bottom center showing contextual hints based on current tool and selection state. During zoom operations, displays `Zoom: NNN%`.

---

## Auto-Save / Persistence

The full canvas state is automatically persisted to a file at `user://canvas.save` on any mutation.

| Setting | File | Location |
|---|---|---|
| Canvas state | `canvas.save` | `user://` (Godot's persistent data directory) |
| Grid state | `config.cfg` | `user://` |
| Theme | `config.cfg` | `user://` |

### Save Triggers

`notify_canvas_changed()` (emits `EventBus.canvas_changed`) is called after every user-initiated mutation:

- Shape / node / arrow creation
- Deletion (selection menu, keyboard Delete/Backspace)
- Single and multi-element drag (on mouseup)
- Color change (via palette swatch)
- Arrow direction change (none/mono/dual)
- Waypoint insertion/drag
- Text commit
- Legend name edit (`LineEdit.text_changed`)
- Paste from clipboard

The `EventBus.canvas_changed` signal is connected to `SaveManager.gd` which calls `save_to_file()`.

### Serialization Format

The `serialize_canvas()` function produces a `Dictionary`:

```gdscript
{
  "elements": [
    { "type": "LabelShape", "position": Vector2, "rx": float, "ry": float, "fill": Color, "text": String },
    { "type": "CircleNode", "position": Vector2, "fill": Color },
    { "type": "TriangleNode", "position": Vector2, "fill": Color },
    {
      "type": "Arrow",
      "points": PackedVector2Array,
      "anchors": [{"end": "start"|"end", "element_index": int, "anchor_label": String}],
      "direction": "mono"|"dual"|"none",
      "color": Color
    }
  ],
  "legend": [[Color, {"custom_name": String}], ...]
}
```

Anchor references use element-index pointers (the index of the referenced shape/node in the serialized array).

### Deserialization

`load_from_file()` runs on scene start:
1. Reads the Dictionary from `user://canvas.save`
2. **First pass**: creates all LabelShapes, CircleNodes, and TriangleNodes (arrows need element references)
3. **Second pass**: creates all arrows, resolving anchor element indices to the actual nodes
4. Restores arrow direction, colors, and waypoints
5. Restores the legend (colors and custom names)

### Clear Canvas

The hamburger menu → **Clear** button shows a confirmation dialog (`AcceptDialog`). On confirmation, `clear_and_save()` removes all canvas elements, clears the legend, and saves the empty state.

---

## Hamburger Menu

A hamburger button in the top-left corner toggles a `PopupMenu` with:

| Item | Action |
|---|---|
| **Export PNG** | Exports the canvas as a PNG image. Computes bounding box of all elements, adds 40px padding, renders at 2× resolution via a temporary `Viewport`. Saves to `user://exports/the-organizer-YYYY-MM-DD.png`. |
| **Clear** | Opens the confirmation dialog to clear the canvas |

The dropdown closes on outside click and on `PopupMenu.index_pressed`.

---

## Confirmation Dialog

An `AcceptDialog` (`#confirm_dialog`) with:
- Title: `"Clear Canvas"`
- Message: `"This will delete everything on the canvas. This cannot be undone."`
- Cancel button (dismisses)
- Clear button (executes `clear_and_save()` and closes)

Closable via: Cancel button, dialog close button, or Escape key.

---

## File Structure (Godot)

| File | Role |
|---|---|
| `project.godot` | Godot project configuration |
| `icon.svg` | Project icon |
| `export_presets.cfg` | Export settings |
| `autoload/State.gd` | Shared state singleton (tool mode, selection sets, references) |
| `autoload/EventBus.gd` | Signal relay for cross-system communication |
| `scenes/main.tscn` | Main scene — assembles all nodes |
| `scenes/main.gd` | Main script — top-level event wiring, keyboard shortcuts, toolbar |
| `scripts/SaveManager.gd` | Serialization, deserialization, clear canvas |
| `scripts/LabelShape.gd` | Shape (ellipse) creation, `_draw()`, text edit, resize handles |
| `scripts/CircleNode.gd` | Circle node creation, `_draw()` |
| `scripts/TriangleNode.gd` | Triangle node creation, `_draw()` |
| `scripts/Arrow.gd` | Arrow creation, waypoints, direction, `_draw()` with bezier curves |
| `scripts/ArrowManager.gd` | Arrow drag-from-anchor logic, preview, snap |
| `scripts/AnchorManager.gd` | Anchor dot creation, visibility, highlighting, `find_anchor_near()` |
| `scripts/SelectionManager.gd` | Click-to-select, Shift+click, marquee, multi-drag, handles |
| `scripts/SelectionMenu.gd` | Floating menu: delete, color palette, direction buttons |
| `scripts/ZoomManager.gd` | Pan & zoom logic, scroll wheel, pinch, middle-click pan |
| `scripts/GridOverlay.gd` | Background grid `_draw()` |
| `scripts/LegendPanel.gd` | Color legend panel in bottom-left |
| `scripts/ExportManager.gd` | PNG export via temporary Viewport |
| `scripts/ColorPalette.gd` | 8-swatch color popup |
| `scripts/TextEditOverlay.gd` | Inline text editor for label shapes |
| `scenes/label_shape.tscn` | LabelShape scene template |
| `scenes/circle_node.tscn` | CircleNode scene template |
| `scenes/triangle_node.tscn` | TriangleNode scene template |
| `scenes/arrow.tscn` | Arrow scene template |
| `themes/` | Theme resource files (light/dark) |
| `SPECIFICATIONS.md` | **Canonical specification for Godot implementation** |
| `GAME_DESIGN.md` | Game design document (separate project if applicable) |

---

## Signals and Communication

Godot's signal system replaces the SVG DOM's event delegation:

| Source | Signal | Connected To | Purpose |
|---|---|---|---|
| `LabelShape` / `CircleNode` / `TriangleNode` | `input_event` | `SelectionManager` | Detect clicks on elements |
| `AnchorManager` anchors | `input_event` | `ArrowManager` | Detect anchor dot clicks for arrow creation |
| `SelectionManager` | `selection_changed` | `SelectionMenu`, `LegendPanel`, `InfoBar` | Update UI on selection change |
| `EventBus` | `canvas_changed` | `SaveManager` | Trigger auto-save |
| `Toolbar` buttons | `pressed` | `Main` | Switch tool modes |
| `HamburgerMenu` | `id_pressed` | `Main` | Export PNG, Clear |
| `ColorPalette` | `color_selected` | `SelectionManager` | Apply color change |
| `TextEditOverlay` | `text_submitted` / `text_changed` | `LabelShape` | Commit/cancel text edit |
| `Main` (zoom buttons) | `pressed` | `ZoomManager` | Zoom in/out/reset |

---

## `_`-prefixed Properties / Metadata

In the Godot implementation, element-specific data is stored using `set_meta()` / `get_meta()` instead of attaching JS properties to DOM nodes:

| Meta Key | Node Type | Purpose |
|---|---|---|
| `"node_shape"` | CircleNode, TriangleNode | `"circle"` or `"triangle"` |
| `"text_content"` | LabelShape | Label text string |
| `"shape_mode"` | LabelShape | `"oval"` or `"circle"` |
| `"points"` | Arrow | `PackedVector2Array` waypoints |
| `"anchors"` | Arrow | `Array[{"end": String, "shape": Node, "label": String}]` |
| `"direction"` | Arrow | `"mono"`, `"dual"`, or `"none"` |
| `"vis_line"` | Arrow | Reference to visible Line2D child |
| `"hit_line"` | Arrow | Reference to invisible hit-test Line2D child |
| `"parent_shape"` | Anchor dot | The shape/node this anchor belongs to |
| `"anchor_label"` | Anchor dot | `"top"`, `"left"`, `"bottom"`, `"right"` |
| `"fill_color"` | LabelShape, CircleNode, TriangleNode, Arrow | Base color |
| `"ignore_next_input"` | Any selectable | Suppress the next input event after a drag |

---

## Constants (Global)

```gdscript
# In State.gd or a separate Constants.gd autoload
const NODE_RADIUS: float = 8.0
const NODE_SIZE: float = 8.0
const ANCHOR_OFFSET: float = 5.0
const ANCHOR_SNAP_RADIUS: float = 15.0
const ANCHOR_HOVER_RADIUS: float = 20.0
const ANCHOR_DOT_RADIUS: float = 4.0
const ANCHOR_HIGHLIGHT_RADIUS: float = 7.0
const ARROWHEAD_ANCHOR_EXT: float = 15.0
const SNAP_INCREMENT: float = 10.0
const MIN_ZOOM: float = 0.1
const MAX_ZOOM: float = 20.0
const GRID_SPACING: float = 40.0
const EXPORT_PADDING: float = 40.0
const EXPORT_SCALE: float = 2.0
const SAVE_PATH: String = "user://canvas.save"
const CONFIG_PATH: String = "user://config.cfg"
```

---

## Development Workflow

1. Open the project in the Godot Editor
2. Run the main scene (`scenes/main.tscn`) via **F5** (Play)
3. Use `--editor` export for testing with debug features
4. For distribution, export via Godot's Export dialog → macOS/Windows/Linux

---

## SVG `_`-prefixed Properties Reference (For Migration Understanding)

The following SVG DOM properties from the original implementation have Godot equivalents:

| SVG Property | Godot Equivalent |
|---|---|
| `_nodeShape` | `set_meta("node_shape", value)` |
| `_text` | `set_meta("text_content", value)` or `text_node.text` |
| `_textEl` | `text_node` (Label child) |
| `_textLines` | Computed at draw time from `text_node` dimensions |
| `_ignoreNextClick` | `set_meta("ignore_next_input", true)` |
| `_points` | `set_meta("points", PackedVector2Array)` |
| `_x1, _y1, _x2, _y2` | `points[0]` and `points[-1]` |
| `_offset` | Computed from bezier control points, not stored directly |
| `_anchors` | `set_meta("anchors", Array)` |
| `_arrowDirection` | `set_meta("direction", "mono"\|"dual"\|"none")` |
| `_visPath` | `vis_line` (Line2D child) |
| `_hitPath` | `hit_line` (Line2D child) |
| `_arrowGroup` | Arrow node itself |
| `_anchorEllipse` | `get_meta("parent_shape")` |
| `_anchorLabel` | `get_meta("anchor_label")` |