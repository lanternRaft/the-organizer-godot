# Shared Element Base (CanvasElement)

## File: `res://scenes/canvas_elements/canvas_element.gd`

`CanvasElement` is a script-only `Node2D` base class that consolidates all common behaviors shared by `LabelShape` and `CanvasNode`: selection state, drag logic, grid snapping, anchor point generation, deletion with arrow cascade, and multi‑select participation.

---

## Class Hierarchy

```
Node2D
└── CanvasElement (script-only, no .tscn)
    ├── LabelShape (extends CanvasElement)
    │   ├── Area2D + CollisionShape2D
    │   ├── HandleTL (ColorRect)
    │   ├── HandleTR (ColorRect)
    │   ├── HandleBL (ColorRect)
    │   ├── HandleBR (ColorRect)
    │   └── TextLabel (Label)
    └── CanvasNode (extends CanvasElement)
        ├── Area2D + CollisionShape2D (circle or triangle)
        └── (no children — fixed size, no text editing)
```

A script-only base (no associated `.tscn` scene file) is used because a scene file would force a shared child node hierarchy (Area2D, collision shape) that doesn't match the divergent needs of LabelShape (resize handles, TextLabel, ellipse collision) and CanvasNode (no children, triangle/circle collision). Each subclass retains full control over its own scene tree.

---

## Exported Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `fill_color` | Color | `#3b82f6` | Fill color; stroke is derived from this. |
| `is_selected` | bool | false | Whether this element is in the selection set. Setter calls `queue_redraw()`. |
| `is_primary` | bool | false | Whether this element is the primary (last-clicked) selection. Setter calls `queue_redraw()`. |
| `element_name` | String | `""` | Optional user-facing name for legend/UI display. |
| `supports_text_editing` | bool | false | Whether this element can host inline text editing. Overridden by LabelShape (`true`) and CanvasNode (`false`). |
| `shows_in_legend` | bool | true | Whether this element contributes a color entry to the legend. Overridden by CanvasNode (`false`). |
| `grid_snap_size` | float | 20.0 | Grid snap increment applied on drag release. |
| `resize_snap_size` | float | 10.0 | Grid snap increment for resize operations. |

---

## Signals

All lifecycle signals are defined on the base class, so `Main.gd` connects to these uniformly. Subclasses emit them via the inherited methods.

| Signal | Arguments | When |
|---|---|---|
| `clicked` | `event: Dictionary, element: CanvasElement` | Element is clicked (not already selected). |
| `double_clicked` | `element: CanvasElement` | Double-click detected on element. |
| `selected_changed` | `element: CanvasElement, selected: bool` | Selection state changed via `set_selected()`. |
| `primary_changed` | `element: CanvasElement, primary: bool` | Primary state changed via `set_is_primary()`. |
| `dragged` | `delta: Vector2, element: CanvasElement` | Element is being dragged (each frame). Main relays this to siblings. |
| `drag_ended` | `element: CanvasElement` | Drag finished; caller should snap positions. |
| `anchor_changed` | `element: CanvasElement` | Anchor positions changed (move or resize). ArrowManager listens via Main. |
| `delete_requested` | `element: CanvasElement` | Element requested deletion. |

---

## Virtual Methods (Override in Subclasses)

Subclasses may override these to customize behavior:

| Method | Signature | Default Behavior | Override Purpose |
|---|---|---|---|
| `get_anchor_positions()` | `-> Array[Dictionary]` | Returns `[]` (empty array) | Define anchor points for arrow connections. |
| `get_element_type()` | `-> String` | Returns `"CanvasElement"` | Return `"LabelShape"` or `"CanvasNode"` for serialization. |
| `get_collision_shape()` | `-> Shape2D` | Returns `null` | Return a `CircleShape2D` or other shape for the Area2D. |
| `on_drag_begin()` | `(event: Dictionary) -> void` | No-op | Called when drag starts; subclass can store pre-drag state. |
| `on_drag_move()` | `(delta: Vector2) -> void` | `position += delta` | Override to handle resize vs. body drag. |
| `on_drag_end()` | `() -> void` | `position = position.snapped(...)` | Called on drag release; subclass can add post-drag logic. |
| `on_selection_changed()` | `(selected: bool) -> void` | `queue_redraw()` | Override to update resize handles, text editor, etc. |
| `on_primary_changed()` | `(primary: bool) -> void` | `queue_redraw()` | Override to update visual highlight strength. |

---

## Clickable Interface

`CanvasElement` adds itself to the `"clickable_element"` group in `_ready()`. This replaces the previous duck‑typing approach where ClickHandler checked for `handle_click` method existence.

```gdscript
func _ready() -> void:
    add_to_group("clickable_element")
    # Subclasses should call super._ready() if they override
```

The `"clickable_element"` group is the single discovery mechanism used by ClickHandler.

---

## Selection State Management

```gdscript
func set_selected(val: bool) -> void:
    if _selected == val:
        return
    _selected = val
    queue_redraw()
    on_selection_changed(val)
    selected_changed.emit(self, val)

func set_is_primary(val: bool) -> void:
    if _is_primary == val:
        return
    _is_primary = val
    queue_redraw()
    on_primary_changed(val)
    primary_changed.emit(self, val)
```

- `Main` calls `set_selected(true/false)` on each element in the selection set.
- `Main` calls `set_is_primary(true/false)` only on the primary element.
- Selection state is read-only externally via `is_selected` and `is_primary` (exported properties with no setter exposed to the inspector).

---

## Drag Lifecycle

The drag lifecycle is managed by `ClickHandler` calling methods on the `CanvasElement`:

```
ClickHandler detects pointer-down on a CanvasElement (via group)
  → If element is already selected:
      → handle_drag_begin(event) returns true → drag starts immediately
  → If element is not selected:
      → handle_click(event) → emits clicked signal → Main selects it
      → handle_drag_begin(event) called again → drag starts
```

### Methods Called by ClickHandler

| Method | Signature | Behavior |
|---|---|---|
| `handle_click` | `(event: Dictionary) -> void` | Emits `clicked` signal. Subclasses override to detect handle vs. body hit. |
| `handle_double_click` | `(event: Dictionary) -> void` | Emits `double_clicked` signal. |
| `handle_drag_begin` | `(event: Dictionary) -> bool` | Stores start position. Returns `true` if element is selected (enables drag). Subclass `on_drag_begin()` called. |
| `handle_drag_move` | `(event: Dictionary) -> void` | Computes incremental delta, calls `on_drag_move(delta)`, emits `dragged(delta, self)`. |
| `handle_drag_end` | `(event: Dictionary) -> void` | Calls `on_drag_end()`, snaps position to `grid_snap_size`, emits `drag_ended(self)` and `anchor_changed()`. |

### Multi-Drag Coordination

1. During `handle_drag_move()`, the element emits `dragged(delta, self)`.
2. `Main._on_dragged(delta, emitter)` applies the delta to every other element in `selected_set` by calling `other_element.position += delta`.
3. On drag end, `Main._on_drag_ended(emitter)` snaps all sibling elements to grid and emits `anchor_changed()` on each.

This is identical to the previous pattern but uses the standardized `dragged` and `drag_ended` signals from the base class instead of per‑type signals.

---

## Grid Snapping

On drag end, the base class applies grid snapping:

```gdscript
func _snap_position() -> void:
    position = position.snapped(Vector2(grid_snap_size, grid_snap_size))
```

- Default `grid_snap_size = 20.0` for body drags.
- Resize snapping uses `resize_snap_size = 10.0` (handled in `LabelShape.on_drag_move()`).
- Subclasses can override `on_drag_end()` to customize snapping behavior.

---

## Anchor Point System

Anchors are defined as an array of dictionaries, returned by the `get_anchor_positions()` method:

```gdscript
func get_anchor_positions() -> Array[Dictionary]:
    # Returns array of {label: String, offset: Vector2}
    return []
```

Each dictionary has:
| Key | Type | Description |
|---|---|---|
| `label` | String | Anchor identifier (e.g., `"top"`, `"bottom"`, `"left"`, `"right"`) |
| `offset` | Vector2 | Offset from element's `position` in world space |

### World Position Calculation

```gdscript
func get_anchor_world_positions() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for anchor in get_anchor_positions():
        result.append({
            "label": anchor.label,
            "position": global_position + anchor.offset,
            "offset": anchor.offset
        })
    return result
```

### LabelShape Anchors

```gdscript
# In LabelShape.gd
func get_anchor_positions() -> Array[Dictionary]:
    return [
        {"label": "top",    "offset": Vector2(0, -ry)},
        {"label": "bottom", "offset": Vector2(0, ry)},
        {"label": "left",   "offset": Vector2(-rx, 0)},
        {"label": "right",  "offset": Vector2(rx, 0)},
    ]
```

### CanvasNode Anchors

```gdscript
# In CanvasNode.gd (circle variant)
func get_anchor_positions() -> Array[Dictionary]:
    if _node_type == "circle":
        return [
            {"label": "top",    "offset": Vector2(0, -radius)},
            {"label": "bottom", "offset": Vector2(0, radius)},
            {"label": "left",   "offset": Vector2(-radius, 0)},
            {"label": "right",  "offset": Vector2(radius, 0)},
        ]
    else:  # triangle
        return [
            {"label": "top",     "offset": Vector2(0, -radius)},
            {"label": "bottom_left",  "offset": Vector2(-radius * 0.866, radius * 0.5)},
            {"label": "bottom_right", "offset": Vector2(radius * 0.866, radius * 0.5)},
        ]
```

### ArrowManager Integration

ArrowManager stores a list of `CanvasElement` references (instead of separate `LabelShape` and `CanvasNode` lists). It calls `get_anchor_world_positions()` on each element to:

1. Position anchor dot nodes (with 5px outward offset)
2. Compute arrow endpoint positions
3. Determine snap targets during arrow drag creation

This eliminates all per‑type conditional logic in ArrowManager.

---

## Deletion Cascade

When `Main` deletes a `CanvasElement`, the base class ensures all connected arrows are removed first:

```gdscript
func delete_with_arrows() -> void:
    delete_requested.emit(self)
    # ArrowManager listens for this signal and removes connected arrows
    queue_free()
```

`Main._delete_element(element)`:
1. Emits `delete_requested` on the element
2. ArrowManager handles `delete_requested` by finding and removing all arrows connected to this element
3. Removes element from scene tree and calls `queue_free()`

---

## Visual Feedback (Selection Highlight)

The base class provides a default `_draw()` that subclasses can extend via `super._draw()`:

```gdscript
func _draw() -> void:
    if is_selected:
        # Draw selection highlight
        var stroke_color = fill_color.lightened(0.3 if is_primary else 0.2)
        var stroke_width = 3.0 if is_primary else 2.5
        # Subclasses draw their own shape outline with these parameters
```

Subclasses override `_draw()` to draw their specific shape (ellipse, circle, triangle) and call `super._draw()` to get the selection highlight parameters. Each subclass is responsible for applying the stroke color and width to its own shape geometry.

---

## Subclass Contracts

### LabelShape (extends CanvasElement)

| Property/Method | Value |
|---|---|
| `supports_text_editing` | `true` |
| `shows_in_legend` | `true` |
| `get_element_type()` | `"LabelShape"` |
| `get_anchor_positions()` | 4 cardinal points at ellipse edge |
| `on_drag_move(delta)` | Detects handle vs. body drag. Handle drag resizes rx/ry. Body drag moves position. |
| `on_drag_end()` | Snaps position to 20px grid (inherited). Resize snaps to 10px. |
| Scene tree | Area2D with CircleShape2D, 4 corner ColorRect handles, TextLabel child |

### CanvasNode (extends CanvasElement)

| Property/Method | Value |
|---|---|
| `supports_text_editing` | `false` |
| `shows_in_legend` | `false` |
| `get_element_type()` | `"CanvasNode"` |
| `get_anchor_positions()` | 4 anchors (circle) or 3 anchors (triangle) |
| `on_drag_move(delta)` | Body drag only (no resize handles). Moves position by delta. |
| `on_drag_end()` | Snaps position to 20px grid (inherited behavior). |
| Scene tree | Area2D with CircleShape2D or CollisionPolygon2D for triangle. No children besides collision. |

---

## Serialization

```gdscript
# Base class serialization contract
func serialize() -> Dictionary:
    return {
        "type": get_element_type(),
        "position_x": position.x,
        "position_y": position.y,
        "fill_r": fill_color.r,
        "fill_g": fill_color.g,
        "fill_b": fill_color.b,
        "fill_a": fill_color.a,
    }
```

Subclasses extend this dictionary with their own properties (e.g., `rx`, `ry`, `text`, `shape_mode` for LabelShape; `node_type`, `radius` for CanvasNode).