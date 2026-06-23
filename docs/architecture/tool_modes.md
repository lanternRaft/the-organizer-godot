# Tool Modes and Toolbar

## File: `res://scenes/tools/toolbar.gd`

A toolbar at the bottom center of the screen provides tool modes. After placing an element, the app auto-switches back to **Select** mode.

## Toolbar Scene Structure

```
Toolbar (Control) — Toolbar.gd
└── HBox (HBoxContainer)
    ├── SelectButton (Button, toggle)     — Select mode
    └── ShapeMenuButton (MenuButton)      — Oval/Circle dropdown
```

Only two tools exist: **Select** and **Shape**. Node (Circle/Triangle) modes are planned but not implemented.

## Tool Modes

| Mode | Button | Behavior |
|---|---|---|
| **Select** | SelectButton (toggle) | Click/drag to select and move elements. Also used for arrow creation (drag from anchor dots). Default mode. |
| **Shape** | ShapeMenuButton (MenuButton) | Dropdown button; click to toggle between Oval and Circle sub-modes. Click canvas to place the shape. |

## State Variables in Main.gd

```gdscript
var shape_tool_active: bool = false
var shape_sub_mode: String = "oval"    # "oval" or "circle"
var select_mode_active: bool = false
```

Tools are mutually exclusive: activating one deactivates the other.

## Toolbar Signals

| Signal | Arguments | Emitted When |
|---|---|---|
| `shape_sub_mode_changed` | `sub_mode: String` | User selects Oval or Circle from dropdown |
| `select_mode_toggled` | `active: bool` | SelectButton is toggled on/off |

These are connected to `Main.gd` in `main.tscn`:

```gdscript
shape_sub_mode_changed → Main._on_shape_sub_mode_changed
select_mode_toggled    → Main._on_select_mode_toggled
```

## Shape Tool Dropdown

The `ShapeMenuButton` opens a `PopupMenu` with two items:

| Item (ID 0) | Item (ID 1) |
|---|---|
| Oval | Circle |

Selecting an item updates the button label and emits `shape_sub_mode_changed`. The button text shows the current sub-mode with a dropdown indicator: `"Oval ▾"` or `"Circle ▾"`.

## Tool Activation Flow

### Select to Shape

```
Main._on_shape_sub_mode_changed(sub_mode)
  → deactivate_select_mode() if active    — clears selection, deselects button
  → activate_shape_mode(sub_mode)
    → shape_tool_active = true
    → shape_sub_mode = sub_mode
    → CURSOR_CROSS
    → update_info_bar()
```

### Shape to Select (auto after placement)

```
Main.place_shape(world_pos)
  → deactivate_shape_mode()           — resets cursor, hides info
  → activate_select_mode()            — restores cursor, selects button
  → select_element(shape, false)
  → set_primary_selection(shape)
```

### Escape deactivates shape mode

```
Main._unhandled_input — "ui_cancel" action
  → if shape_tool_active:
    → deactivate_shape_mode()
```

## Info Bar Context

The info bar shows contextual hints based on active tool:

| State | Info Bar Text |
|---|---|
| Shape mode (oval) | "Click the canvas to place a oval" |
| Shape mode (circle) | "Click the canvas to place a circle" |
| Select mode, no selection | "Click to select an oval" |
| Select mode, 1 selected | "Enter to edit text   Drag handles to resize" |
| Select mode, multi selected | "Drag to move N selected elements" |
| Text overlay open | "Type your text   Enter to confirm   Escape to cancel" |

When zoom is not at 100%, all hint texts are suffixed with `"   |   Zoom: NNN%"`.

## How Tool Switching Feels

- Buttons are toggle-style — when Select is active, the SelectButton looks pressed in
- Switching to a shape tool pops the SelectButton back up via `button_pressed = false`
- Escape returns to neutral (deactivates shape mode, or clears selection in select mode)
- Every shape placement auto-returns to Select mode — the user never stays trapped in placement mode

## Future Tool Modes (Planned)

The design docs describe a Node tool with Circle/Triangle sub-modes. This would follow the same pattern as the Shape tool: a `MenuButton` with dropdown, activating a placement mode, clicking canvas to place, auto-return to Select.