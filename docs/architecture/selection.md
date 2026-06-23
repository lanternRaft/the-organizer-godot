# Selection System

## File: `res://scenes/main/main.gd`

Selection uses a unified data model: a single `selected_set: Array[Node]` containing both `LabelShape` and `Arrow` nodes. There is no split state.

## Key Variables in Main.gd

| Variable | Type | Purpose |
|---|---|---|
| `selected_set` | `Array[Node]` | All currently selected elements |
| `primary_selection` | `Node` | Last-clicked element; determines stronger visual highlight |

## Click-to-Select Logic

All selection logic flows through `_handle_element_clicked(element: Node)`:

| Action | Behavior |
|---|---|
| **Click (no Shift)** on element | Calls `clear_selection()`, then `select_element(element, false)`, then `set_primary_selection(element)` |
| **Shift+Click** on element | If already in set: `_deselect_element(element)`. If not: `select_element(element, true)` (additive), then `set_primary_selection(element)` |
| **Click on empty canvas** (Select mode, no Shift) | `clear_selection()` via `_on_empty_canvas_clicked` |
| **Escape** (Select mode) | `clear_selection()` via `_unhandled_input` |

The `handle_drag_begin` early-return in ClickHandler is critical: if the clicked element is already selected, `handle_click` is skipped. This preserves multi-selection when starting a drag on an already-selected element.

### Flow: ClickHandler → Main

1. ClickHandler detects an Area2D hit on a LabelShape
2. If element is already selected → `handle_drag_begin` returns true → drag starts immediately, no click processing
3. If element is not selected → `handle_click` is called → emits `clicked` signal → Main selects it → `handle_drag_begin` called again → drag starts

For arrows (no Area2D), the secondary hit path calls `Main._on_arrow_clicked_at()` → `_handle_element_clicked()` directly.

## Selection Methods

### `select_element(element, additive)`
- If not additive, calls `clear_selection()` first
- Appends element to `selected_set`
- Calls `element.set_selected(true)` (duck-typed — both LabelShape and Arrow implement this)
- Refreshes primary visuals and updates selection menu

### `_deselect_element(element)`
- Calls `element.set_selected(false)`
- Removes from `selected_set`
- If the deselected element was primary, promotes the next element in the set (or null)

### `set_primary_selection(element)`
- Sets `primary_selection`
- Calls `_refresh_primary_visuals()` which sets `is_primary = (elem == primary_selection)` on every element in the set
- Updates selection menu

### `clear_selection()`
- Calls `set_selected(false)` on every element
- Clears `selected_set` and `primary_selection`
- Dismisses selection menu

## Primary vs Secondary Visual Feedback

Defined in each element's `_draw()` or property setter:

| Element | Primary (last-clicked) | Secondary (other selected) |
|---|---|---|
| **LabelShape** | `stroke_color = fill_color.lightened(0.4)`, `stroke_width = 3.0` | `stroke_color = fill_color.lightened(0.25)`, `stroke_width = 2.5` |
| **Arrow** | `vis_line.default_color = Color(0.6, 0.8, 1.0)` (solid) | `vis_line.default_color = Color(0.6, 0.8, 1.0, 0.7)` (semi-transparent) |

## Multi-Drag Coordination

When multiple elements are selected, dragging any one moves all of them by the same delta. `Main.gd` acts as the coordinator.

### Flow

1. Dragged element (LabelShape or Arrow) computes incremental delta in `handle_drag_move()`
2. Emits `multi_drag_moved(incremental_delta)`
3. `Main._on_multi_drag_moved(delta, emitter)` applies the delta to every other element in `selected_set`:
   - **LabelShape siblings**: `shape.position += delta`, emits `anchor_changed()`, calls `resolve_overlaps()`
   - **Arrow siblings**: `arrow.position += delta`
4. On drag end, dragged element emits `multi_drag_ended()`
5. `Main._on_multi_drag_ended(emitter)` snaps all LabelShape siblings to 20px grid and emits `anchor_changed()` on each

### What moves in a multi-drag

- All selected LabelShapes move by the same pixel delta
- Arrows connected to moving shapes update automatically via `anchor_changed` signal → `ArrowManager.update_arrows_for_shape()`
- Free-floating arrows in the set also move by the same delta (sibling dispatch)
- Handle resizing is per-element only — only the primary shape can be resized

### Multi-Drag Bumping

During multi-drag, bump resolution runs on all moved shapes. The dragged shape calls `resolve_overlaps()` after moving. Sibling shapes (moved by Main) also call `resolve_overlaps()`. Static frame tracking (`_bump_frame`, `_bump_processed`) prevents double-processing shapes in the same frame.

## Select All (Ctrl+A / Cmd+A)

`Main._select_all_elements()`:
- Iterates all `ElementLayer` children
- Selects every `LabelShape` and arrow (checked via `is_in_group("arrows")`)
- Sets the last element found as primary_selection

## Multi-Delete

`Main._delete_selected_elements()`:
1. Duplicates `selected_set` to avoid modification during iteration
2. For each element: if `LabelShape`, calls `_delete_shape()` which removes connected arrows via `ArrowManager.delete_arrows_for_shape()`; if arrow, calls `ArrowManager.delete_arrow()`
3. Clears selection and saves

## Selection Menu Visibility

`Main._update_selection_menu()`:
- Hidden when 0 or >1 elements selected
- Hidden when text overlay is open
- Hidden when not in Select mode
- Shown for single element only

## Corner Cases

- **Clicking an already-selected element without Shift**: It stays selected and becomes the new primary. This feels natural — the user might click the same shape again just to access the selection menu.
- **Shift+click on an already-selected primary**: Removes it. The next-most-recently-clicked element becomes primary.
- **Resize while multi-selected**: Only the primary shape shows handles. Other selected shapes don't show handles and can't be resized.
- **Arrows connected to two selected shapes**: The arrow updates its path as both endpoints move, via `anchor_changed` emission from each moved shape.