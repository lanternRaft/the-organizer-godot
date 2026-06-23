# UI Components

All UI elements are children of the `UI` CanvasLayer in `Main` and are therefore rendered in screen-space, unaffected by camera transforms.

## Selection Menu

**File**: `res://scenes/ui/selection_menu/selection_menu.gd`

A floating `PanelContainer` that appears below a single selected element.

### Scene Structure

```
SelectionMenu (PanelContainer)
├── HBox (HBoxContainer)
│   ├── DeleteButton (Button)       — "Del"
│   └── ColorButton (Button)        — "Color"
└── ColorPalette (SelectionColorPalette)
```

### Positioning (`_reposition()`)

1. Get the target element's world position and visual extents (rx, ry for shapes; bounding box of bezier points for arrows)
2. Convert world center to screen-space using `camera.get_canvas_transform()`
3. Compute screen-space half-height: `half_height * zoom.y`
4. Position menu centered below element bottom: `screen_center.y + screen_half_h + BELOW_PADDING` (12px)
5. Clamp to viewport edges

### Refresh

Menu repositions on:
- Element move/resize (connected via `anchor_changed` signal)
- Camera zoom changes (via `zoom_changed` signal)
- Manual `refresh_position()` call

### Visibility Rules

- Shown when exactly 1 element selected and Select mode active and text overlay closed
- Hidden when 0 or >1 elements, Select mode inactive, or text overlay open
- Connected to element's `anchor_changed` for position tracking; disconnected on dismiss

### Delete Action

Emits `delete_requested` → Main calls `_delete_selected_elements()`.

### Color Action

Toggles `ColorPalette` popup visibility. The palette is positioned to the right of the Color button, clamped to viewport edges. Emits `color_selected(color)` → Main applies `fill_color` to the primary shape and saves.

## Color Palette

**File**: `res://scenes/ui/selection_menu/color_palette.gd`

8 swatches in a 2×4 grid, built dynamically in `_ready()`.

### Swatch Colors

| Name | Hex | Position |
|---|---|---|
| Blue | `#3b82f6` | (0, 0) |
| Red | `#ef4444` | (1, 0) |
| Green | `#22c55e` | (2, 0) |
| Amber | `#f59e0b` | (3, 0) |
| Purple | `#a855f7` | (0, 1) |
| Pink | `#ec4899` | (1, 1) |
| White | `#ffffff` | (2, 1) |
| Dark | `#1e293b` | (3, 1) |

### Implementation

- Each swatch is a `ColorRect` with `mouse_filter = MOUSE_FILTER_STOP`
- `gui_input` on each swatch emits `color_selected` and closes via `close()`
- Mouse filter `STOP` prevents clicks from passing through to canvas

## Zoom Controls

**File**: `res://scenes/ui/zoom_controls/zoom_controls.gd`

3-button vertical stack anchored to the bottom-right corner.

| Button | Signal | Text | Tooltip |
|---|---|---|---|
| Zoom In | `zoom_in_requested` | + | Zoom in (Ctrl+=) |
| Zoom Out | `zoom_out_requested` | − | Zoom out (Ctrl+-) |
| Reset | `zoom_reset_requested` | ⟳ | Reset zoom (Ctrl+0) |

Signals are connected in `main.tscn` to `Main._on_zoom_in/out/reset_requested`, which relay to `CameraController.zoom_by_factor()` / `reset_zoom()`.

### Position in main.tscn

```gdscript
anchors_preset = 3  # Bottom-right
offset_left = -132
offset_top = -130
offset_right = 0
offset_bottom = 0
```

## InfoBar

A `Label` at bottom center showing contextual hints. Updated via `Main.update_info_bar()`.

### Position

```gdscript
anchors_preset = 7  # Bottom-center
offset_left = -196
offset_top = -78
offset_right = 204
offset_bottom = -50
```

See [tool_modes.md](tool_modes.md) for the full table of info bar states.

## Grid Toggle

**File**: `res://scenes/ui/grid_toggle/grid_toggle.gd`

Top-right button with `⊞` icon. Emits `grid_toggle_requested` when pressed. Connected to `Main.toggle_grid()`.

- Tooltip: "Toggle grid (G)"
- Visual state synced via `set_grid_visible(visible_state)` — button appearance toggles
- The `Main._unhandled_input` G key handler calls `toggle_grid()` directly

## Hamburger Menu

**File**: `res://scenes/ui/hamburger_menu/hamburger_menu.gd`

Top-left ☰ button with a `PopupMenu`.

### Menu Items

| Index | Label | Action |
|---|---|---|
| 0 | Clear | Emits `clear_requested` → opens ConfirmDialog |

### `_on_button_pressed()`: Toggles popup below the button. Popup appears at the button's bottom-left corner.

### Not Yet Implemented

The design docs describe a second menu item: **Export PNG**. This is not yet implemented. The export flow (compute bounding box, render at 2× via temporary Viewport, save to `user://exports/the-organizer-YYYY-MM-DD.png`) is described but not coded.

## Confirm Dialog

**File**: `res://scenes/ui/confirm_dialog/confirm_dialog.gd`

An `AcceptDialog` with:
- Title: `"Clear Canvas"`
- Message: `"This will delete everything on the canvas. This cannot be undone."`
- Cancel button (added via `add_cancel_button("Cancel")`)
- Clear/Confirm button (default AcceptDialog behavior) → emits `confirmed` → `Main._on_confirm_dialog_confirmed()` → `clear_all_elements()` + `save_canvas()`

## Legend Panel

**File**: `res://scenes/ui/legend_panel/legend_panel.gd`

A compact panel anchored to the bottom-left corner of the screen listing every color currently in use on the canvas, each with an editable label.

### Scene Structure

```
LegendPanel (PanelContainer)
└── EntryList (VBoxContainer)
    ├── LegendEntry (HBoxContainer)     — one per color in use
    │   ├── Swatch (ColorRect)          — 16×16 colored square
    │   └── NameField (LineEdit)        — editable label, flat style
    └── ...
```

### Position

Anchored to bottom-left corner of the viewport, with small padding from edges. Sized snugly to content — grows vertically as entries are added.

### Visibility Rules

- Shown when at least one color is in use on the canvas
- Hidden when no colors are in use

### Data Ownership

LegendPanel owns its state internally (color-to-name mapping) and exposes a simple API:

| Method | Purpose |
|---|---|
| `set_colors_in_use(colors)` | Sync entries with the given set of unique colors |
| `get_legend_data()` | Returns Dictionary for serialization |
| `load_legend_data(data)` | Restores custom names from saved data |
| `clear_all()` | Clears all entries and resets group counter |

Emits `name_changed(color, new_name)` when the user edits a label.

See [legend_panel.md](legend_panel.md) for full architecture details.

## UI Component Status Summary

| Component | File | Status |
|---|---|---|
| Toolbar | `scenes/ui/.../toolbar.tscn` | ✅ Built |
| SelectionMenu | `scenes/ui/selection_menu/` | ✅ Built |
| ColorPalette | `scenes/ui/selection_menu/color_palette.gd` | ✅ Built |
| ZoomControls | `scenes/ui/zoom_controls/` | ✅ Built |
| GridToggle | `scenes/ui/grid_toggle/` | ✅ Built |
| InfoBar | Inline in main.tscn | ✅ Built |
| HamburgerMenu | `scenes/ui/hamburger_menu/` | ✅ Built (Clear only) |
| ConfirmDialog | `scenes/ui/confirm_dialog/` | ✅ Built |
| TextEditOverlay | `scenes/ui/text_edit_overlay/` | ✅ Built |
| LegendPanel | `scenes/ui/legend_panel/` | ✅ Built |
| Export PNG | — | 🚧 Planned |
| ThemeToggle | — | 🚧 Planned |