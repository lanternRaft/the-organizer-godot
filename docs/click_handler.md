# ClickHandler Architecture

All pointer input (mouse and touch) is unified through a single **ClickHandler** node (plain `Node`, child of `Main`). It replaces the previous split handling where `Main._unhandled_input` and `LabelShape._on_area_2d_input_event` each partially owned pointer logic.

## Pipeline

1. **`_unhandled_input`** catches `InputEventMouseButton` and `InputEventMouseMotion` (touch is emulated as mouse by Godot on desktop).
2. **On pointer down**: Runs a physics point query (`PhysicsPointQueryParameters2D`) on `ElementLayer`'s space to find the topmost `Area2D`.
3. **Walks up** from the `Area2D` to the owning element node (e.g., `LabelShape`).
4. **Calls `handle_click(event)`** on the target. Returns `true` if the click is consumed.
5. **Calls `handle_drag_begin(event)`** on the target. Returns `true` if a drag should start.
6. **On pointer move** (past a 5px drag threshold): calls `handle_drag_move(event)`.
7. **On pointer up**: calls `handle_drag_end(event)` and resets drag state.
8. **On empty canvas**: emits `empty_canvas_clicked(world_pos)` signal that `Main` connects to for placement / selection clearing.

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

## Current Implementors

| Node | Methods |
|---|---|
| `LabelShape` | `handle_click`, `handle_drag_begin`, `handle_drag_move`, `handle_drag_end` |