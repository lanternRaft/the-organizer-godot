# State Management

## File: `res://scenes/main/main.gd`

State is managed locally in `Main.gd`, not via autoload singletons. There is no `State.gd` or `EventBus.gd` — the design docs reference these, but the implementation keeps everything in the root controller.

## Relevant State Variables in Main.gd

| Variable | Type | Purpose |
|---|---|---|
| `shape_tool_active` | `bool` | Whether shape-placement mode is active |
| `shape_sub_mode` | `String` | `"oval"` or `"circle"` |
| `select_mode_active` | `bool` | Whether select mode is active |
| `last_placed` | `Node2D` | Reference to the last placed shape |
| `current_zoom` | `float` | Most recent zoom level (cached from `camera_controller.zoom_changed`) |
| `grid_enabled` | `bool` | Whether the grid is currently visible |
| `selected_set` | `Array[Node]` | All currently selected elements (CanvasElement subclasses + Arrow) |
| `primary_selection` | `Node` | Last-clicked element; determines stronger visual highlight |

## Communication Patterns

Since there are no autoloads, communication follows a strict parent-child signal pattern.

### Base-Class Signals from CanvasElement

All `CanvasElement` subclasses (`LabelShape`, `CanvasNode`) emit the same set of standardized signals, defined on the base class. `Main.gd` connects to these signals uniformly, eliminating per‑type connection patterns.

| Signal | Arguments | When |
|---|---|---|
| `clicked` | `event: Dictionary, element: CanvasElement` | Element is clicked (not already selected). |
| `double_clicked` | `element: CanvasElement` | Double-click detected on element. |
| `selected_changed` | `element: CanvasElement, selected: bool` | Selection state changed. |
| `primary_changed` | `element: CanvasElement, primary: bool` | Primary state changed. |
| `dragged` | `delta: Vector2, element: CanvasElement` | Element is being dragged each frame. |
| `drag_ended` | `element: CanvasElement` | Drag finished; caller should snap positions. |
| `anchor_changed` | `element: CanvasElement` | Anchor positions changed (move or resize). |
| `delete_requested` | `element: CanvasElement` | Element requested deletion. |

### Signals from Other Children (connected in `Main._ready()`)

| Emitter | Signal | Receiver | Purpose |
|---|---|---|---|
| `ClickHandler` | `empty_canvas_clicked(world_pos)` | `Main._on_empty_canvas_clicked` | Routes placement / selection clear |
| `ClickHandler` | `pointer_up(world_pos)` | `Main._on_pointer_up` | Ends arrow drag in ArrowManager |
| `CanvasElement` (any subclass) | `clicked(event, element)` | `Main._on_element_clicked` | Selection on element click |
| `CanvasElement` | `double_clicked(element)` | `Main._on_element_double_clicked` | Opens text editor (LabelShape) or no-op (CanvasNode) |
| `CanvasElement` | `anchor_changed(element)` | `Main._on_element_anchor_changed` | Updates connected arrows |
| `CanvasElement` | `dragged(delta, element)` | `Main._on_dragged` | Broadcasts drag delta to siblings |
| `CanvasElement` | `drag_ended(element)` | `Main._on_drag_ended` | Snaps all selected elements to grid |
| `Arrow` | `multi_drag_moved(delta)` | `Main._on_multi_drag_moved(delta, arrow)` | Broadcasts drag delta to siblings |
| `CameraController` | `zoom_changed(level)` | `Main._on_zoom_changed` | Updates InfoBar |
| `Toolbar` | `shape_sub_mode_changed(sub_mode)` | `Main._on_shape_sub_mode_changed` | Activates shape mode |
| `Toolbar` | `select_mode_toggled(active)` | `Main._on_select_mode_toggled` | Activates/deactivates select mode |
| `SelectionMenu` | `delete_requested()` | `Main._on_menu_delete_requested` | Deletes selected element |
| `SelectionMenu` | `color_selected(color)` | `Main._on_menu_color_selected` | Applies color to shape |
| `HamburgerMenu` | `clear_requested()` | `Main._on_hamburger_clear_requested` | Shows confirmation dialog |
| `ConfirmDialog` | `confirmed` | `Main._on_confirm_dialog_confirmed` | Clears canvas |
| `GridToggle` | `grid_toggle_requested` | `Main.toggle_grid()` | Toggles grid |
| `ZoomControls` | `zoom_in_requested` | `Main._on_zoom_in_requested` | Relays to CameraController |
| `ZoomControls` | `zoom_out_requested` | `Main._on_zoom_out_requested` | Relays to CameraController |
| `ZoomControls` | `zoom_reset_requested` | `Main._on_zoom_reset_requested` | Relays to CameraController |

### Cross-Element Coordination via Main

When multiple elements are selected, `Main` acts as a relay:

1. A dragged `CanvasElement` emits `dragged(delta, self)` (or `Arrow` emits `multi_drag_moved(delta)`)
2. `Main._on_dragged()` receives the delta and applies it to every other element in `selected_set`
3. On drag end, `Main._on_drag_ended()` snaps all `CanvasElement` positions to their respective `grid_snap_size`

This avoids direct coupling between sibling elements while keeping coordination logic in one place.

### Method-Based Dispatch

Because `selected_set` can contain both `CanvasElement` subclasses and `Arrow` nodes (which share no common base class), `Main` uses duck-typing and method-based dispatch:

- `element.has_method(&"set_selected")` to check selection capability
- `element.is_in_group("arrows")` to identify arrows
- `element.is_in_group("clickable_element")` to identify CanvasElement subclasses
- `element.call("method_name", args)` for signal/dispatch calls

## Why No Autoloads?

The current design deliberately avoids autoloads for simplicity. At this stage, all state is owned by a single root controller with clear signal paths. If the app grows complex enough to need cross-cutting state access (tool mode queries from deep UI components), extracting a `State` autoload and an `EventBus` autoload is the intended refactor path.