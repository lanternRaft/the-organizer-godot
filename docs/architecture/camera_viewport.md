# Camera and Viewport

## File: `res://scenes/main/camera_controller/camera_controller.gd`

The canvas implements a **Camera2D-based** pan and zoom system. Rather than manipulating individual node transforms or a viewBox, the camera node's `position`, `zoom`, and `transform` are adjusted.

## Architecture

`CameraController` (plain `Node`, child of `Main`) owns all pan/zoom logic:

```
Main
├── CameraController (Node)     — input handling + zoom/pan methods
└── MainCamera (Camera2D)       — positioned at origin, zoom = Vector2(1, 1)
```

`MainCamera` is referenced via `%MainCamera` (unique name). `CameraController` holds a `@onready var camera: Camera2D` reference to it.

## CameraController Responsibilities

- **Input handling**: All pan/zoom input is handled in `CameraController._unhandled_input()`. This includes scroll-wheel, trackpad gestures, middle-click drag, and keyboard shortcuts.
- **Programmatic control**: Exposes `zoom_by_factor()`, `reset_zoom()`, and `pan_by()` methods called by ZoomControls and Main.
- **Signal emission**: Emits `zoom_changed(level)` to update InfoBar and SelectionMenu.

## Zoom Configuration

| Constant | Value | Meaning |
|---|---|---|
| `MIN_ZOOM` | 0.1 | 10% minimum zoom-out |
| `MAX_ZOOM` | 20.0 | 2000% maximum zoom-in |
| `ZOOM_IN_FACTOR` | 1.25 | Multiplier per zoom-in step |
| `ZOOM_OUT_FACTOR` | 0.8 | Multiplier per zoom-out step (1/1.25) |
| `PAN_SPEED` | 100.0 | Trackpad pan speed multiplier |

## Zoom State

```gdscript
var zoom_level: float = 1.0:
    set(value):
        zoom_level = clampf(value, MIN_ZOOM, MAX_ZOOM)
        camera.zoom = Vector2(zoom_level, zoom_level)
        zoom_changed.emit(zoom_level)
```

The setter clamps, applies uniform zoom, and emits the change signal. Camera position is adjusted separately when zooming toward a focus point.

## Zoom Implementation (Cursor-Centered)

```gdscript
func zoom_by_factor(factor: float, focus_pos: Vector2 = Vector2.INF) -> void:
    var old_zoom: float = zoom_level
    zoom_level *= factor
    var applied: float = zoom_level / old_zoom
    if applied == 1.0:
        return  # Clamped to min/max
    if focus_pos != Vector2.INF:
        var vp_center: Vector2 = _viewport.get_visible_rect().size / 2.0
        var offset: Vector2 = focus_pos - vp_center
        camera.position += offset * (1.0 - 1.0 / applied)
```

The focus position (screen-space cursor position) determines where the zoom centers. The camera offsets so the world point under the cursor stays at the same screen position.

## Input Handling

### Zoom Inputs

| Input | Detection | Action |
|---|---|---|
| Ctrl/Cmd + Scroll wheel | `MOUSE_BUTTON_WHEEL_UP/DOWN` + `is_command_or_control_pressed()` | Zoom by factor, centered on cursor |
| Zoom buttons (+ / − / ⟳) | Signal from ZoomControls | zoom_by_factor(1.25 or 0.8, viewport_center) or reset_zoom() |
| Ctrl/Cmd + = / - / 0 | Keyboard shortcut | Same as buttons |
| Trackpad pinch | `InputEventMagnifyGesture` | Zoom by `event.factor`, centered on gesture focus |

### Pan Inputs

| Input | Detection | Action |
|---|---|---|
| Scroll wheel (no modifier) | `MOUSE_BUTTON_WHEEL_*` | Pan by 60px × zoom (Shift = horizontal axis) |
| Middle-click drag | `MOUSE_BUTTON_MIDDLE` held + mouse motion | Pan by `-mm.relative × camera.zoom` |
| Trackpad two-finger pan | `InputEventPanGesture` | Pan by `event.delta × zoom × PAN_SPEED` |

### Trackpad Gesture Suppression

Some trackpads generate a synthetic scroll-wheel event after a two-finger gesture ends. `CameraController` stores the timestamp of the last gesture event and ignores wheel events within 200ms of it.

### Middle-Click Panning

Middle-click panning is handled in `CameraController`'s `_unhandled_input()` and never reaches `ClickHandler`. This means middle-click on elements (shapes, arrows) never triggers selection or drag — it always pans.

## Keyboard Shortcuts

| Key | Action |
|---|---|
| Ctrl/Cmd + = (or +) | Zoom in by 1.25×, centered on viewport center |
| Ctrl/Cmd + - (or −) | Zoom out by 0.8×, centered on viewport center |
| Ctrl/Cmd + 0 | Reset zoom to 100%, camera to origin |

These are handled in `CameraController._unhandled_input()` under the `event.ctrl_pressed` branch.

## Coordinate Transforms

- **`get_global_mouse_position()`**: Returns mouse position in world coordinates, automatically accounting for camera transform. Used by ClickHandler and most input logic.
- **`camera.get_canvas_transform() * world_pos`**: Converts world position to screen-space. Used by SelectionMenu positioning and TextEditOverlay.
- **`element.to_local(world_pos)`**: Converts world position to element-local coordinates. Used by ClickHandler for handle hit-testing.
- **Zoom-agnostic position storage**: All element positions are stored in world-space coordinates. Screen-space is computed on demand for UI positioning.

## Edge Cases

- **Zoom clamp at extremes**: If already at 10% zoom and zooming out, the applied factor becomes 1.0 and the function returns early. No jitter, no error.
- **Reset after extreme zoom**: `reset_zoom()` sets `zoom_level = 1.0` and `camera.position = Vector2.ZERO` — one action returns to a known state.
- **Zoom while editing text**: CameraController's input handling remains active while TextEditOverlay is open. This is intentional — users may want to zoom in to read small text.
- **Window resize**: Godot's layout system adjusts Control nodes automatically. Camera zoom remains unchanged.