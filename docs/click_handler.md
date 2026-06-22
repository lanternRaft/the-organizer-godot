# ClickHandler Architecture

All pointer input (mouse and touch) is unified through a single **ClickHandler** node (plain `Node`, child of `Main`). It replaces the previous split handling where `Main._unhandled_input` and `LabelShape._on_area_2d_input_event` each partially owned pointer logic.

## Pipeline

1. **`_unhandled_input`** catches `InputEventMouseButton` and `InputEventMouseMotion` (touch is emulated as mouse by Godot on desktop).
2. **On pointer down**: Runs a physics point query (`PhysicsPointQueryParameters2D`) on `ElementLayer`'s space to find the topmost `Area2D`.
3. **Walks up** from the `Area2D` to the owning element node (e.g., `LabelShape`).
4. **Calls `handle_drag_begin(event)`** on the target. **If it returns `true`** (element was already selected), skips `handle_click` to preserve multi-selection and enters drag mode immediately.
5. **If drag did not start** (element was not selected), **calls `handle_click(event)`** on the target to select it, then calls `handle_drag_begin(event)` again.
6. **On pointer move** (past a 5px drag threshold): calls `handle_drag_move(event)`.
7. **On pointer up**: calls `handle_drag_end(event)` and resets drag state.
8. **On empty canvas**: emits `empty_canvas_clicked(world_pos)` signal that `Main` connects to for placement / selection clearing.

## Multi-Drag Dispatch

When a drag begins on an element that is part of a multi-selection set, the dragged element broadcasts the movement delta to all other selected elements:

1. The dragged element computes its own position change in `handle_drag_move()`.
2. It emits a `multi_drag_moved(delta: Vector2)` signal.
3. **Main** receives this signal via `_on_multi_drag_moved()` and applies the same delta to every other element in `selected_set`.
4. On drag-end, the dragged element emits `multi_drag_ended()` so Main can snap all selected LabelShapes to the 20px grid.

Only **body drags** broadcast the delta. Handle resizing is per-element only.

## Clickable Interface

Any element node that implements `handle_click(event: Dictionary) -> bool` is auto-discovered by ClickHandler via `has_method("handle_click")`. A fallback group `"clickable"` is checked for nodes that need group-based discovery.

## PointerEvent Dictionary

Events are normalised into a common dictionary:

| Key | Type | Description |
|---|---|---|
| `world_pos` | Vector2 | Pointer position in world space |
| `local_pos` | Vector2 | Position relative to the hit element's local space |
| `pressed` | bool | Whether the pointer is down |
| `dragged` | bool | Whether this is a drag move event |
| `button_index` | int | Mouse button index |
| `original_event` | InputEvent | The raw Godot input event |

## Secondary Hit Detection

When the physics query finds no Area2D hit, ClickHandler falls through to two secondary paths:

1. **Arrow hit detection**: Calls `Main._on_arrow_clicked_at(world_pos)` which checks `arrow_manager.get_arrow_near()` against the arrow's invisible hit-line (Line2D width=14).
2. **Anchor dot hit detection**: Calls `Main._on_anchor_dot_mousedown(world_pos)` to begin arrow drags.

## Current Implementors

| Node | Methods | Multi-Drag |
|---|---|---|
| `LabelShape` | `handle_click`, `handle_drag_begin`, `handle_drag_move`, `handle_drag_end` | Emits `multi_drag_moved(delta)` and `multi_drag_ended()` |
| `Arrow` | `handle_drag_begin`, `handle_drag_move`, `handle_drag_end` | Emits `multi_drag_moved(delta)` for free-floating offset |

Arrows do not implement `handle_click` because they are detected through the secondary physics-query fallback path rather than Area2D collision.
