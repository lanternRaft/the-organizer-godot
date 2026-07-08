# Input and Click Handling

## File: `res://scenes/main/click_handler/click_handler.gd`

All pointer input (mouse and touch) is unified through a single `ClickHandler` node (plain `Node`, child of `Main`). It replaces split handling where `Main._unhandled_input` and `LabelShape._on_area_2d_input_event` each partially owned pointer logic.

## Pipeline

1. **`_unhandled_input`** catches `InputEventMouseButton` and `InputEventMouseMotion` (touch is emulated as mouse by Godot on desktop). Keyboard events (Escape, Delete, G, Ctrl+A, Enter) are handled by `Main._unhandled_input`, not ClickHandler.

2. **On pointer down**: Runs a physics point query (`PhysicsPointQueryParameters2D`) on `ElementLayer`'s space to find the topmost `Area2D`. The query uses `collide_with_areas = true` and `collision_mask = 1`.

3. **Walks up** from the `Area2D` to the owning element node by checking for group membership in `"clickable_element"`. This replaces the previous duck‑typing approach that checked for `handle_click` method existence.

4. **Double-click detection**: If the clicked element matches the last-clicked element within 400ms, calls `handle_double_click` on it (opens text editor on LabelShape). This takes priority over other processing.

5. **Already-selected shortcut**: If the element was already selected (determined by `handle_drag_begin` returning `true`), skips `handle_click` to preserve multi-selection and enters drag mode immediately.

6. **Normal flow**: If not already selected, calls `handle_click(event)` to select it, then calls `handle_drag_begin(event)` to start drag tracking.

7. **Drag threshold**: On mouse move, drag movement only begins after the pointer has moved at least 5px from the click origin (`DRAG_THRESHOLD`). Below this threshold, motion is ignored.

8. **On pointer up**: calls `handle_drag_end(event)` on the drag target and resets drag state. Also emits `pointer_up(world_pos)` so ArrowManager can end arrow drags.

9. **On empty canvas (no hit)**: Falls through to secondary hit detection, then emits `empty_canvas_clicked(world_pos)`.

## PointerEvent Dictionary

Events are normalised into a common dictionary by ClickHandler before dispatching to element methods:

| Key | Type | Description |
|---|---|---|
| `world_pos` | Vector2 | Pointer position in world space |
| `local_pos` | Vector2 | Position relative to the hit element's local space |
| `pressed` | bool | Whether the pointer is down |
| `dragged` | bool | Whether this is a drag move event (past threshold) |
| `button_index` | int | Mouse button index |
| `original_event` | InputEvent | The raw Godot input event |

## Secondary Hit Detection

When the physics query finds no Area2D hit, ClickHandler falls through to two secondary paths. The order of these checks determines click priority when an anchor dot and an arrow endpoint occupy the same screen position.

1. **Anchor dot hit detection (first)**: Calls `Main._on_anchor_dot_mousedown(world_pos)` which delegates to `arrow_manager.handle_dot_mousedown()` to register a pending arrow drag from an anchor dot. If the pointer is over an anchor dot (within hover radius), this check succeeds and arrow hit detection is skipped entirely. This ensures anchor dots always take priority over arrow endpoints at the same position.

2. **Arrow hit detection (second)**: Calls `Main._on_arrow_clicked_at(world_pos)` which checks `arrow_manager.get_arrow_near()` against the arrow's cached bezier points (the invisible `HitLine` Line2D has width=14). This is only reached when no anchor dot was hit. Arrow endpoints are part of the bezier point cache used for hit testing, so they continue to be selectable — but only when no anchor dot exists at the same position.

### Drag Threshold Delay for Arrow Initiation

When an anchor dot is hit on pointer down, ClickHandler does **not** immediately begin an arrow drag. Instead, it records a pending drag state. On subsequent pointer motion events, ClickHandler notifies ArrowManager via `handle_dot_mousemove(world_pos)`. ArrowManager checks whether the pointer has moved past a threshold (`ARROW_DRAG_THRESHOLD`, 5px) from the original click position. Only when the threshold is exceeded does ArrowManager activate the drag, creating the preview line and entering the drag state.

If the pointer is released without moving past the threshold, no arrow drag is started — the click is effectively ignored. This prevents accidental arrow creation when the user clicks an anchor dot without intending to drag.

### Arrow Endpoints in Hit Testing

Arrow endpoints remain part of the bezier point cache used by `get_arrow_near()`. They are not removed from hit testing. The deprioritization of arrow endpoints relative to anchor dots is enforced purely by the **order of detection** in ClickHandler's secondary hit path, not by modifying hit shapes or radii. This keeps arrow body selection via click on the bezier path unchanged.

## Clickable Interface (Group-Based Discovery)

All `CanvasElement` subclasses automatically add themselves to the `"clickable_element"` group in their `_ready()` method. ClickHandler uses this group to discover elements, eliminating the previous duck‑typing approach.

```gdscript
# In CanvasElement._ready()
add_to_group("clickable_element")
```

The group replaces the earlier method‑name discovery pattern (`has_method("handle_click")`). Any node in this group is automatically treated as a clickable element.

### Current Implementors

| Node | Clickable Group | `handle_click` | `handle_double_click` | `handle_drag_begin` | `handle_drag_move` | `handle_drag_end` | Multi-Drag Signal |
|---|---|---|---|---|---|---|---|
| `LabelShape` (CanvasElement) | `"clickable_element"` | ✅ Inherited from CanvasElement; detects handle vs. body hit | ✅ Emits `double_clicked` | ✅ Returns true if selected | ✅ Handle resize or body drag | ✅ Snaps to grid (20px) | `dragged(delta, self)` (inherited) |
| `CanvasNode` (CanvasElement) | `"clickable_element"` | ✅ Inherited from CanvasElement; body drag only | ❌ (not supported) | ✅ Returns true if selected | ✅ Body drag only | ✅ Snaps to grid (20px) | `dragged(delta, self)` (inherited) |
| `Arrow` | `"arrows"` | ❌ (detected via secondary path) | ❌ | ✅ Returns true if selected | ✅ Moves by delta | ✅ Snaps to 20px grid | `multi_drag_moved(delta)` |

## Resize Handle Interaction Fix

The 4 corner `ColorRect` resize handles (LabelShape only) have `mouse_filter = MOUSE_FILTER_IGNORE`. This passes mouse events straight through to the `Area2D` child beneath, allowing the ClickHandler's physics query to find the `LabelShape` and dispatch the click/drag pipeline normally. Without this, Control nodes would absorb mouse events in the GUI phase before they reach `_unhandled_input`.

## Edge Cases

- **Middle-click panning**: `CameraController` handles `MOUSE_BUTTON_MIDDLE` in its own `_unhandled_input`. It never reaches ClickHandler. Middle-click on elements never triggers selection or drag.
- **Synthetic trackpad events**: After a trackpad gesture, some trackpads generate synthetic scroll-wheel events. `CameraController` ignores wheel events within 200ms of a gesture to prevent double-movement.
- **Keyboard shortcuts**: Handled entirely in `Main._unhandled_input`. ClickHandler does not process keyboard events.
- **Focus release on canvas click**: `_handle_pointer_down()` releases GUI focus from any focused Control before dispatching. This ensures Control edit modes (legend labels, text overlay) close promptly when the user returns to the canvas. Focus release is unconditional because GUI-captured Control clicks never reach `_unhandled_input` — only canvas clicks (Node2D/Area2D, empty space) trigger it. This is safe: clicking a legend LineEdit is absorbed by GUI, so `_handle_pointer_down` doesn't fire; clicking on a canvas shape passes through GUI, reaches `_handle_pointer_down`, and correctly releases focus.