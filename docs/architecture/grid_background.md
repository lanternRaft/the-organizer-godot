# Grid Background

## File: `res://scenes/main/grid/grid_background.gd`

The grid background is a full-screen `ColorRect` with a custom `CanvasItem` shader that renders an infinite grid. It is not a tilemap or procedural geometry — the shader computes grid lines entirely in the fragment shader based on camera position and zoom.

## Scene Structure

```
Canvas (Node2D)
└── GridLayer (CanvasLayer, layer = -1)
    └── GridBackground (ColorRect) — ShaderMaterial
```

`GridLayer` uses `layer = -1` to render behind the world-space canvas content (which is at default layer 0). The ColorRect is anchored to fill the entire viewport.

## Shader-Based Grid

The shader receives three uniforms each frame from `_update_shader_uniforms()`:

| Shader Parameter | Source | Description |
|---|---|---|
| `camera_position` | `cam.global_position` | World-space position of the camera center |
| `camera_zoom` | `cam.zoom.x` | Current zoom level (uniform X/Y) |
| `grid_spacing` | `grid_spacing` | 40px world-space grid spacing |
| `theme_dark` | `set_theme_dark()` | Boolean: true for dark mode, false for light mode |

### Grid Rendering

In the fragment shader (approximate logic):

1. Convert UV coordinates to world space: `world_pos = (uv - 0.5) * viewport_size * zoom + camera_position`
2. Compute grid lines: `fract(world_pos / spacing)` to get cell-relative position
3. Draw lines at cell boundaries using `fwidth` for 1px screen-space-width lines
4. Opacity: 6% white in dark mode, 7% black in light mode

This ensures the grid appears as infinitely extending 40px-spaced lines that remain exactly 1 screen-pixel wide at any zoom level.

## Per-Frame Update

`_update_shader_uniforms()` runs in `_process(delta)` — every frame. This is necessary because the camera position changes on every frame during pan/drag operations.

## Persistence

Grid state is persisted to `user://config.cfg`:

```gdscript
const CONFIG_PATH: String = "user://config.cfg"
const CONFIG_SECTION: String = "grid"
const CONFIG_KEY_ENABLED: String = "enabled"
```

- `_load_state()`: Called in `_ready()`. Reads from config, defaults to `true` if no config exists
- `_save_state()`: Called in the `grid_enabled` setter. Merges with existing config values rather than overwriting

## Grid State Flow

```
G key press → Main._unhandled_input → Main.toggle_grid()
  → grid_background.grid_enabled = !grid_background.grid_enabled
    → setter: updates visible, calls _save_state(), emits grid_toggled(enabled)

GridToggle button → grid_toggle_requested → Main.toggle_grid()
  [same path as above]
```

## Theme Awareness

`grid_background.set_theme_dark(true)` is called once in `Main._ready()`. The theme toggle button (dark/light) is planned but not implemented — the grid currently stays in dark mode permanently.

## Edge Cases

- **Grid starts on**: Default state is enabled. New users see the grid immediately.
- **Toggle is instant**: No animation. The grid is either visible or not.
- **Zoom affects grid appearance**: At extreme zoom levels, the grid lines remain 1px screen-space wide but the spacing in world-space may make individual cells very large or very small. The shader handles this naturally via the world-space computation.
- **Performance**: The shader runs per-pixel but the grid line calculation is simple. No measurable performance impact on modern GPUs even at high resolutions.