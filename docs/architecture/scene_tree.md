# Scene Tree Architecture

## File: `res://scenes/main/main.tscn`

The scene is the root of the app. All game systems are children of a single `Node` with `Main.gd` attached. No autoloads (singletons) are used — state lives in `Main.gd`.

## Current Scene Tree

```
Main (Node) — Main.gd
├── Canvas (Node2D)                                   — World-space canvas container
│   ├── GridLayer (CanvasLayer, layer=-1)              — Renders behind everything
│   │   └── GridBackground (ColorRect)                 — Shader-based infinite grid
│   ├── ElementLayer (Node2D)                          — All shapes and arrows
│   │   ├── LabelShape (Node2D)                        — Ellipse labels (area-based)
│   │   ├── Arrow (Node2D)                             — Bezier arrows (below shapes)
│   │   └── AnchorLayer (Node2D)*                      — Dynamic anchor dot markers
│   └── AnchorLayer (Node2D)                           — Persistent anchor container
├── ClickHandler (Node)                                — Unified pointer input dispatch
├── UI (CanvasLayer)                                   — Screen-space, unaffected by camera
│   ├── HamburgerMenu (Control)                        — Top-left ☰ button + PopupMenu
│   ├── ConfirmDialog (AcceptDialog)                   — Clear Canvas confirmation
│   ├── Toolbar (Control) — Toolbar.gd                 — Bottom-center tool buttons
│   │   └── HBox (HBoxContainer)
│   │       ├── SelectButton (Button, toggle)
│   │       └── ShapeMenuButton (MenuButton)           — Oval/Circle dropdown
│   ├── ZoomControls (Control)                         — Bottom-right zoom buttons (+ / − / ⟳)
│   ├── InfoBar (Label)                                — Centered bottom hint text
│   ├── GridToggle (Control)                           — Top-right grid toggle
│   └── SelectionMenu (PanelContainer)                 — Contextual menu below single selection
│       ├── HBox (HBoxContainer)
│       │   ├── DeleteButton (Button)
│       │   └── ColorButton (Button)
│       └── ColorPalette (SelectionColorPalette)       — 8-swatch color picker popup
├── CameraController (Node)                            — Pan/zoom input handling + logic
├── MainCamera (Camera2D)                              — Positioned at origin, controlled by CameraController
└── ArrowManager (Node)                                — Anchor dots, hover, drag, creation, deletion
```

* Anchor dot nodes (type `Node2D` with `anchor_dot.gd`) are dynamically created as children of `AnchorLayer` by `ArrowManager`.

## Key Design Decisions

### No Autoloads / Singletons

All state lives in `Main.gd` and is passed via direct references (`@onready`), signals, and `Callable` bindings. There is no `State.gd` or `EventBus.gd` — these were described in design docs but not implemented. Communication patterns:

- **Parent → child**: Direct method calls via `@onready` references or `call()`
- **Child → parent**: Signals emitted, connected in `Main._ready()`
- **Cross-element**: `Main.gd` relays signals between subsystems (e.g., multi-drag coordination)

### CanvasLayer Separation

- `Canvas` (Node2D) contains all world-space elements affected by camera transforms
- `UI` (CanvasLayer) contains all screen-space controls unaffected by camera
- `GridLayer` (CanvasLayer, layer=-1) renders the background grid behind all world-space content

### Element Layer Z-Order

Arrows are placed at index 0 (bottom) of `ElementLayer` so they render below shapes. Shapes are added above arrows. This ensures arrow lines don't visually overlap shape fills.

### Dynamic Anchor Dots

Anchor dots are not part of any shape scene. Instead, `ArrowManager` creates lightweight `Node2D` nodes with `anchor_dot.gd` script at runtime, parenting them to `AnchorLayer`. Dots are shown/hidden based on cursor proximity and arrow-drag state.