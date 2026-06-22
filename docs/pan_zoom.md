# Pan & Zoom

The canvas implements a **Camera2D-based** pan and zoom system. Rather than manipulating a viewBox, the camera node's `position`, `zoom`, and `transform` are adjusted.

## State (State.gd)

- `camera: Camera2D` — reference to `MainCamera`
- `zoom_level: float` — current zoom factor (1.0 = 100%)
- `MIN_ZOOM: float = 0.1` — 10% minimum
- `MAX_ZOOM: float = 20.0` — 2000% maximum

## Zoom Controls (UI)

A vertical button stack in the **bottom-right corner** (Godot `VBoxContainer`, anchored to bottom-right via layout) provides three buttons:

| Button | Action | Tooltip |
|---|---|---|
| + (plus) | Zoom in by factor 1.25×, centered on viewport center | Zoom in (Ctrl+=) |
| − (minus) | Zoom out by factor 0.8×, centered on viewport center | Zoom out (Ctrl+-) |
| ⟳ (reset) | Reset to 100% zoom, camera position to (0,0) | Reset zoom (Ctrl+0) |

## Zoom Implementation

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

## Scroll-Wheel / Trackpad Zoom & Pan

The main viewport's `_input(event)` distinguishes:

| Gesture | Detection | Behaviour |
|---|---|---|
| **Mouse wheel zoom** | `event is InputEventMouseButton` with `button_index == MOUSE_BUTTON_WHEEL_UP`/`DOWN` + `Ctrl` / `Cmd` | Zoom centered on cursor position. Factor = 1.25 or 0.8 |
| **Mouse wheel pan** | `event is InputEventMouseButton` with `button_index == MOUSE_BUTTON_WHEEL_*` | Pan camera by 60px scaled by zoom. (Shift modifies axis) |
| **Trackpad pinch-to-zoom** | `event is InputEventMagnifyGesture` | Zoom by `event.factor`, centered on gesture focus |
| **Trackpad two-finger pan** | `event is InputEventPanGesture` | Pan camera by `event.delta * zoom * PAN_SPEED` |
| **Middle-click drag pan** | `MOUSE_BUTTON_MIDDLE` held + `_input()` mouse motion | Pan camera position |

## Touch Pinch-to-Zoom

Handled via `InputEventScreenDrag` / `InputEventScreenTouch` / `InputEventMagnifyGesture` — Godot provides built-in magnify gesture detection.

## Keyboard Shortcuts

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

## Coordinate Transforms

All pointer coordinate conversions use `get_global_mouse_position()` (automatically accounts for camera transform) and `to_local()` / `to_global()` for element-local coordinates.

## Resize Handle Interaction Fix

The 4 corner `ColorRect` resize handles previously did not respond to click-and-drag because Control nodes process input via `_gui_input` (GUI phase) **before** `_unhandled_input` reaches the `ClickHandler`. With the default `mouse_filter = MOUSE_FILTER_STOP`, handles absorbed mouse events in the GUI phase, preventing them from reaching `ClickHandler._unhandled_input`.

**Fix**: All 4 handle `ColorRect` nodes have `mouse_filter = MOUSE_FILTER_IGNORE`, which passes mouse events straight through to the `Area2D` child beneath, allowing the ClickHandler's physics query to find the `LabelShape` and dispatch the click/drag pipeline normally.

## Resize Behaviour

On window resize, Godot's layout system automatically adjusts Control nodes. The camera's zoom remains unchanged.

## Export PNG Interaction

When exporting to PNG (Export PNG from hamburger menu), the export computation uses the **logical bounding box** of all elements + padding, not the current camera viewport. A `Viewport` is temporarily rendered at 2× resolution with a camera positioned to frame the bounding box.