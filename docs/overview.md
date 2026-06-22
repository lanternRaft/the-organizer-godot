# The Organizer — Godot Implementation

A canvas-based whiteboarding tool for world building — notes, flow charts, and relational diagrams. Built in **Godot 4.7** using GDScript

## Current Implementation Status

The following are the features currently built vs. those documented in the design docs:

| Feature | Status | Notes |
|---|---|---|
| Oval placement via toolbar | ✅ Built | First canvas feature. Click Shape button → click canvas. Supports Oval (rx=80, ry=50) and Circle (rx=80, ry=80) sub-modes via dropdown. |
| Toolbar with Shape dropdown | ✅ Built | Bottom-center MenuButton with PopupMenu for Oval/Circle toggle. |
| Circle shape + resize constraint | ✅ Built | shape_mode property on LabelShape; circle resize constrains ry=rx. |
| Select tool + click-to-select | ✅ Built | Select button, click shape to select, Shift+click additive, Escape deselects. |
| Resize handles on selection | ✅ Built | 4 corner ColorRect handles; drag to resize with 10px snap, [20, 500] clamp. |
| Auto-switch to Select after placement | ✅ Built | Placing a shape switches to Select mode and selects the new shape. |
| InfoBar hints | ✅ Built | Contextual: shape mode (oval/circle), select mode, selection active, zoom. |
| Escape deactivates tool / clears selection | ✅ Built | Shape mode: deactivates tool. Select mode: clears selection. |
| Canvas scene structure | ✅ Built | Main → Canvas(ElementLayer) + UI(Toolbar, InfoBar) + Camera2D |
| Camera2D at origin | ✅ Built | Enables scrolling, no pan/zoom controls yet. |
| All other features | 🚧 Planned | See the respective docs below. |

### Differences from Planned Architecture

- **No autoloads** (`State`, `EventBus`) exist yet — state is local to `Main.gd`.
- **`Area2D` on `LabelShape`** — ✅ Built. CollisionShape2D sized to rx/ry. Emits `clicked` signal.
- **`ClickHandler`** — ✅ Built. Child of Main that unifies all pointer input (mouse+ touch) into a single dispatch pipeline.
- **No `GridOverlay`**, **`AnchorLayer`**, **`PreviewLine`**, **`SelectionMenu`**, **`ColorPalette`**, **`LegendPanel`**, **`ZoomControls`**, or **`TextEditOverlay`** exist yet.

## Technology Stack

- **Godot 4.7** — Open-source game engine with built-in 2D rendering, input handling, signals, and scene system
- **GDScript** — All game logic scripts