# Architecture — Document Index

Quick-reference index for agents to find the architecture doc they need. Each file covers internal implementation details only (not player-facing interactions).

| File | When to read |
|---|---|
| [`arrow_system.md`](arrow_system.md) | Anchor dot management, arrow drag creation/deletion, bezier path updates, hit testing against arrows, shape tracking |
| [`camera_viewport.md`](camera_viewport.md) | Camera2D pan/zoom implementation, CameraController responsibilities, zoom configuration constants, programmatic zoom/pan methods |
| [`canvas_elements.md`](canvas_elements.md) | LabelShape and Arrow class hierarchy, exported properties, node structure (Area2D, handles, text label), shape modes (oval/circle) |
| [`grid_background.md`](grid_background.md) | Shader-based infinite grid, GridLayer with layer=-1, shader uniforms (camera position/zoom, grid spacing, theme), grid toggle |
| [`input_handling.md`](input_handling.md) | ClickHandler pipeline (pointer down/move/up), physics point query hit detection, double-click detection, drag threshold, empty canvas flow |
| [`legend_panel.md`](legend_panel.md) | Legend panel scene structure, color-to-name data model, auto-population from canvas colors, inline name editing, persistence of color names |
| [`persistence.md`](persistence.md) | Save/load via `FileAccess.store_var()`/`get_var()`, save path (`user://canvas.save`), save triggers on mutation, known gap (body-drag not persisted) |
| [`scene_tree.md`](scene_tree.md) | Full scene tree under `Main (Node)`, Canvas vs UI CanvasLayer separation, all child nodes and their roles |
| [`selection.md`](selection.md) | Unified `selected_set` data model, primary vs secondary selection, click-to-select logic (Shift, Ctrl+A, Escape), deselection behavior |
| [`state_management.md`](state_management.md) | State variables in Main.gd (tool state, zoom, grid, selection), parent-child signal communication patterns, no autoloads |
| [`text_editing.md`](text_editing.md) | TextEditOverlay scene structure, entry points (Enter key, double-click), screen-space positioning calculation, commit vs cancel, live preview |
| [`tool_modes.md`](tool_modes.md) | Toolbar scene structure, Select/Shape mode behavior, auto-switch after placement, state variables in Main.gd |
| [`ui_components.md`](ui_components.md) | Selection menu (delete/color buttons, color palette), positioning logic (world-to-screen conversion), viewport clamping |

## Quick topic lookup

| Topic | File |
|---|---|
| Anchor dots | `arrow_system.md` |
| Arrow creation / deletion | `arrow_system.md` |
| Arrow hit testing | `arrow_system.md` |
| Auto-switch after placement | `tool_modes.md` |
| Bezier path updates | `arrow_system.md` |
| Camera2D pan / zoom | `camera_viewport.md` |
| Canvas vs UI layers | `scene_tree.md` |
| Click pipeline (pointer down/move/up) | `input_handling.md` |
| Color palette | `ui_components.md` |
| Color-to-name mapping | `legend_panel.md` |
| Communication patterns (signals) | `state_management.md` |
| Double-click detection | `input_handling.md` |
| Drag threshold | `input_handling.md` |
| Empty canvas click | `input_handling.md` |
| Grid shader / toggle | `grid_background.md` |
| Hit detection (physics query) | `input_handling.md` |
| LabelShape properties | `canvas_elements.md` |
| Legend panel auto-population | `legend_panel.md` |
| Persistence (save/load) | `persistence.md` |
| Save triggers / gap | `persistence.md` |
| Scene tree (full hierarchy) | `scene_tree.md` |
| Select / multi-select / deselect | `selection.md` |
| Selection menu positioning | `ui_components.md` |
| State variables (Main.gd) | `state_management.md` |
| Text editing (Enter / double-click) | `text_editing.md` |
| Text overlay positioning | `text_editing.md` |
| Tool modes (Select / Shape) | `tool_modes.md` |
| Zoom configuration | `camera_viewport.md` |