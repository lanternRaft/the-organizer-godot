# Scene Tree Architecture

## Current Scene Tree

```
Main (Node) — Main.gd
├── Canvas (Node2D)
│   ├── GridBackground (ColorRect)     — shader-based infinite grid
│   ├── ElementLayer (Node2D)          — shapes and arrows parented here
│   │   ├── LabelShape (Node2D)        — ellipse labels
│   │   └── Arrow (Node2D)             — arrow curves (rendered below shapes)
│   └── AnchorLayer (Node2D)           — anchor dot markers
├── ClickHandler (Node)                — unified pointer input dispatch
├── UI (CanvasLayer)                   — screen-space, not affected by camera
│   ├── Toolbar (Control) — Toolbar.gd
│   │   └── HBox (HBoxContainer)
│   │       ├── SelectButton (Button, toggle)
│   │       └── OvalButton (Button, toggle)
│   ├── ZoomControls (Control)        — bottom-right zoom buttons
│   ├── InfoBar (Label)              — centered bottom hint text
│   ├── GridToggle (Control)         — top-right ⊞ grid toggle button
│   ├── HamburgerMenu (Control)      — top-left ☰ button + PopupMenu
│   ├── ConfirmDialog (AcceptDialog) — Clear Canvas confirmation dialog
│   └── SelectionMenu (PanelContainer) — contextual menu below single selection
│       ├── HBox (HBoxContainer)
│       │   ├── DeleteButton (Button)
│       │   └── ColorButton (Button)
│       └── ColorPalette (Control)     — 8-swatch color picker popup
├── ArrowManager (Node)               — hover, drag, creation, deletion
├── CameraController (Node)            — camera pan/zoom logic
│   └── (references MainCamera)
└── MainCamera (Camera2D)             — positioned at origin, controlled by CameraController
```

## Planned Scene Tree

```
Main (Node)
├── Canvas (Node2D)
│   ├── GridBackground (ColorRect)       — shader-based infinite grid
│   ├── ElementLayer (Node2D)            — all shapes, nodes, arrows
│   │   ├── LabelShape (Node2D)          — ellipse labels
│   │   ├── CircleNode (Area2D)          — small circle nodes
│   │   ├── TriangleNode (Area2D)        — small triangle nodes
│   │   └── Arrow (Node2D)               — arrow curves
│   ├── AnchorLayer (Node2D)             — anchor dot markers
│   └── PreviewLine (Line2D)             — dashed arrow preview during drag
├── UI (CanvasLayer)                     — pinned to screen
│   ├── Toolbar (Control)                — bottom-center tool buttons
│   ├── SelectionMenu (Control)          — floating menu below selection
│   ├── ColorPalette (Control)           — 8-swatch popup
│   ├── LegendPanel (Control)            — bottom-left color legend
│   ├── ZoomControls (Control)           — bottom-right zoom buttons
│   ├── InfoBar (Label)                  — centered bottom hint text
│   ├── GridToggle (Control)             — top-right ⊞ grid toggle button
│   ├── HamburgerMenu (Control)          — top-left menu button + dropdown
│   ├── ConfirmDialog (AcceptDialog)     — Clear Canvas confirmation
│   └── TextEditOverlay (TextEdit)       — inline text editor for labels
├── MainCamera (Camera2D)                — pan/zoom via camera transforms
└── EventBus (Node)                      — signal relay for cross-system events
```