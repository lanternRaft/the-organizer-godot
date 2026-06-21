# UI Controls

## Grid Toggle

Button (top-right, next to theme toggle) with grid icon. Toggles a `GridOverlay` Node2D that draws a grid in `_draw()` (40px spacing). Persisted to `ConfigFile` as `grid`.

## Theme Toggle

Button (top-right corner) with sun/moon icons. Toggles between `"dark"` and `"light"` themes. Implemented via `Theme` resources and/or `modulate` on UI elements. Persisted to `ConfigFile` as `theme`.

## Info Bar

A `Label` at the bottom center showing contextual hints based on current tool and selection state. During zoom operations, displays `Zoom: NNN%`.