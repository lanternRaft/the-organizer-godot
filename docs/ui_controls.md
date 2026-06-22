# UI Controls

## Grid Toggle

Button (top-right, next to theme toggle) with grid icon. Toggles a shader-based `GridBackground` (ColorRect) that draws an infinite grid via a CanvasItem shader (40px world-space spacing, 1px screen-space lines via `fwidth`). Persisted to `ConfigFile` as `grid`.

Keyboard shortcut: `G` toggles grid on/off (without Ctrl/Shift/Alt modifiers).

Grid starts **on** by default. Theme-aware: uses white lines at 6% opacity in dark mode, black lines at 7% opacity in light mode.

## Theme Toggle

Button (top-right corner) with sun/moon icons. Toggles between `"dark"` and `"light"` themes. Implemented via `Theme` resources and/or `modulate` on UI elements. Persisted to `ConfigFile` as `theme`.

## Info Bar

A `Label` at the bottom center showing contextual hints based on current tool and selection state. During zoom operations, displays `Zoom: NNN%`.