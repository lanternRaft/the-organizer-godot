# Legend Panel

**File**: `res://scenes/ui/legend_panel/legend_panel.gd`

A compact panel anchored to the bottom-left corner of the screen that lists every color currently in use on the canvas with an editable name for each.

---

## Scene Structure

```
UI (CanvasLayer)
└── LegendPanel (PanelContainer) — anchored bottom-left, sized to content
    └── EntryList (VBoxContainer)
        ├── LegendEntry (HBoxContainer)     — one per color in use
        │   ├── Swatch (ColorRect)          — 16×16 colored square
        │   └── NameField (LineEdit)        — editable label, flat style
        └── ...
```

The panel is a child of the `UI` CanvasLayer in `Main`, so it renders in screen-space, unaffected by camera transforms. The `PanelContainer` gives it a subtle background to visually separate it from the canvas.

## Data Model

LegendPanel owns its state internally:

```gdscript
## Color-to-custom-name mapping. Persisted and restored across sessions.
var _color_names: Dictionary  # Dictionary[Color, String]

## Current row entry nodes, keyed by Color for O(1) lookup.
var _entry_rows: Dictionary  # Dictionary[Color, VBoxContainer]

## Global counter for default "Group N" names.
var _group_counter: int = 0
```

## Public API

| Method | Signature | Purpose |
|---|---|---|
| `set_colors_in_use` | `(colors: Array[Color]) | Diff the given colors against current entries. Add rows for new colors (auto-naming them "Group N"). Remove rows for colors no longer in use. Preserve custom names for colors that persist. Cached custom names for removed colors survive in case they return. |
| `get_legend_data` | `() -> Dictionary` | Returns `{color_hash: custom_name}` for persistence. |
| `load_legend_data` | `(data: Dictionary)` | Restores custom names from saved data. Colors not in the data get default names. |
| `clear_all` | `()` | Clears all entries and resets the group counter. |

## Signals

| Signal | Arguments | When |
|---|---|---|
| `name_changed` | `color: Color, new_name: String` | User finishes editing a LineEdit (on focus loss or Enter key). Focus loss is triggered by ClickHandler releasing focus on canvas clicks, or naturally when another Control receives focus. |

## Color Tracking Flow

`Main._refresh_legend()` is called after every color-affecting mutation:

1. Scan `element_layer` children for unique `fill_color` values
   - Current: `LabelShape` instances
   - Extensible: adds `CircleNode`, `TriangleNode` (future), Arrow stroke colors
2. Collect into an `Array[Color]` of unique values
3. Call `legend_panel.set_colors_in_use(unique_colors)`

**Triggers for `_refresh_legend()`:**

| Trigger | Caller Method |
|---|---|
| Shape placed | `place_shape()` |
| Color changed via palette | `_on_menu_color_selected()` |
| Shape deleted | `_delete_selected_elements()` |
| Canvas cleared | `clear_all_elements()` |
| Canvas loaded | `load_canvas()` |

The legend does NOT refresh during drag operations or text editing — only on mutation commit.

## Default Name Generation

When a new color first appears, its default label is `"Group {N}"` where `N` is a global incrementing counter (`_group_counter`). This means the first color seen gets "Group 1", the second new color "Group 2", etc. The counter persists across `set_colors_in_use()` calls but resets on `clear_all()`.

## Persistence

### Serialization (in `serialize_canvas()`)

```gdscript
"legend": [
    [Color(0.231, 0.51, 0.965, 1.0), "The Rebellion"],
    [Color(0.937, 0.267, 0.267, 1.0), "Danger"]
]
```

Stored as an array of `[Color, String]` pairs. The array format (vs. Dictionary) ensures deterministic ordering for consistent display.

### Deserialization (in `load_canvas()`)

1. Check if `data` has `"legend"` key
2. If present, iterate the array and call `legend_panel.load_legend_data()`
3. After all elements are loaded, call `_refresh_legend()` to reconcile legend entries with actual shapes on the canvas

### Backward Compatibility

Save files from before the legend feature don't have a `"legend"` key. `load_canvas()` checks `data.has("legend")` and skips legend loading if absent. The legend panel initializes empty from the canvas scan.

## Visibility

The `PanelContainer` is hidden when no colors are in use (`set_colors_in_use([])` empties all rows and hides the panel). It shows automatically when the first color appears.

## Edge Cases

- **Multiple shapes with the same color:** The legend shows one entry per color, regardless of how many shapes share it.
- **Color reappears after being removed:** If a color's last shape is deleted, the row is removed but the custom name is cached in `_color_names`. If a new shape with that same color is added, the row reappears with the cached name.
- **Palette colors only:** The legend supports exactly the 8 palette colors. Colors outside the palette (set programmatically) are technically supported but won't normally occur since the palette is the only color input.
- **Empty canvas:** Legend panel is hidden, `_color_names` is cleared.
- **LineEdit appearance:** The LineEdit has a flat (no border) style in disabled state, and gains a subtle border on focus for editing. This keeps the legend looking clean when not being edited.
- **Clicking away from a LineEdit:** Canvas clicks release focus via ClickHandler, triggering `focus_exited`. If the LineEdit text is empty, it reverts to the cached name from `_color_names`. If non-empty, the change is applied and persisted. Both `_on_name_focus_exited` and `_on_name_submitted` share a helper that handles the revert-on-empty logic.
