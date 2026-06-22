# UI Controls

## Grid Toggle

Button (top-right corner, 40×40px) with `⊞` icon. Tooltip shows "Toggle grid (G)".

Toggles a shader-based `GridBackground` (ColorRect) that draws an infinite grid via a CanvasItem shader (40px world-space spacing, 1px screen-space lines via `fwidth`). Persisted to `ConfigFile` as `grid`.

Keyboard shortcut: `G` toggles grid on/off (without Ctrl/Shift/Alt modifiers).

Grid starts **on** by default. Theme-aware: uses white lines at 6% opacity in dark mode, black lines at 7% opacity in light mode.

### Implementation

- Scene: `scenes/ui/grid_toggle/grid_toggle.tscn`
- Script: `scenes/ui/grid_toggle/grid_toggle.gd`
- Instance parent: `UI` CanvasLayer in `main.tscn`
- Signal: `grid_toggle_requested` → connected to `Main.toggle_grid()`
- Grid state synced via `set_grid_visible()` method on the button control.

## Theme Toggle

Button (top-right corner) with sun/moon icons. Toggles between `"dark"` and `"light"` themes. Implemented via `Theme` resources and/or `modulate` on UI elements. Persisted to `ConfigFile` as `theme`.

## Info Bar

A `Label` at the bottom center showing contextual hints based on current tool and selection state. When zoom is not at 100%, appends `   |   Zoom: NNN%` to the mode-specific hint text.

## Zoom Controls

A `Control` with a `VBoxContainer` of three buttons anchored to the **bottom-right** of the viewport, just above the toolbar:

| Button | Text | Tooltip | Action |
|---|---|---|---|
| Zoom In | `+` | Zoom in (Ctrl+=) | Relays to `CameraController.zoom_by_factor(1.25, viewport_center)` |
| Zoom Out | `−` | Zoom out (Ctrl+-) | Relays to `CameraController.zoom_by_factor(0.8, viewport_center)` |
| Reset | `⟳` | Reset zoom (Ctrl+0) | Relays to `CameraController.reset_zoom()` |

The buttons emit signals (`zoom_in_requested`, `zoom_out_requested`, `zoom_reset_requested`) that `Main.gd` relays to `CameraController` methods.

### Position

- Anchored: bottom-right (`anchor_left=1.0`, `anchor_top=1.0`, `anchor_right=1.0`, `anchor_bottom=1.0`)
- Offsets: left=-144, top=-180, right=-12, bottom=-50 (sits above the toolbar)