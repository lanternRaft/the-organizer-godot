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
| `selected_set` | `Array[Node]` | All currently selected elements (LabelShape + Arrow) |
| `primary_selection` | `Node` | Last-clicked element; determines stronger visual highlight |

## Communication Patterns

Since there are no autoloads, communication follows a strict parent-child signal pattern:

### Signals from Children (connected in `Main._ready()`)

| Emitter | Signal | Receiver | Purpose |
|---|---|---|---|
| `ClickHandler` | `empty_canvas_clicked(world_pos)` | `Main._on_empty_canvas_clicked` | Routes placement / selection clear |
| `ClickHandler` | `pointer_up(world_pos)` | `Main._on_pointer_up` | Ends arrow drag in ArrowManager |
| `LabelShape` | `clicked(event, shape)` | `Main._on_shape_clicked` | Selection on shape click |
| `LabelShape` | `double_clicked(shape)` | `Main._on_shape_double_clicked` | Opens text editor |
| `LabelShape` | `anchor_changed()` | `Main._on_shape_anchor_changed(shape)` | Updates connected arrows |
| `LabelShape` | `multi_drag_moved(delta)` | `Main._on_multi_drag_moved(delta, shape)` | Broadcasts drag delta to siblings |
| `LabelShape` | `multi_drag_ended()` | `Main._on_multi_drag_ended(shape)` | Snaps all selected shapes to grid |
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

1. A dragged `LabelShape` or `Arrow` emits `multi_drag_moved(delta)`
2. `Main._on_multi_drag_moved()` receives the delta and applies it to every other element in `selected_set`
3. On drag end, `Main._on_multi_drag_ended()` snaps all `LabelShape` positions to the 20px grid

This avoids direct coupling between sibling elements while keeping coordination logic in one place.

### Method-Based Dispatch

Because `selected_set` can contain both `LabelShape` and `Arrow` nodes (which share no common base class), `Main` uses duck-typing and method-based dispatch:

- `element.has_method(&"set_selected")` to check selection capability
- `element.is_in_group("arrows")` to identify arrows
- `element.call("method_name", args)` for signal/dispatch calls

## Why No Autoloads?

The current design deliberately avoids autoloads for simplicity. At this stage, all state is owned by a single root controller with clear signal paths. If the app grows complex enough to need cross-cutting state access (tool mode queries from deep UI components), extracting a `State` autoload and an `EventBus` autoload is the intended refactor path.