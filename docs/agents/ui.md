# Working on UI — The Organizer (Godot 4)

Everything useful to know before touching UI in this project: how UI is
organized, how the theme works, and the gotchas that have already cost time.

Table of contents:

- [Scene layout & conventions](#scene-layout--conventions)
- [The theme (`resources/theme.tres`)](#the-theme)
- [When to use theme.tres vs per-node overrides](#theme-vs-overrides)
- [PopupMenu (submenus) — special rules](#popupmenu)
- [Icons & buttons](#icons--buttons)
- [Anchoring & screen placement](#anchoring--screen-placement)
- [Input actions](#input-actions)
- [Signal conventions](#signal-conventions)
- [Known issues / open items](#known-issues--open-items)
- [Testing UI](#testing-ui)
- [Colors](#colors)

---

## Scene layout & conventions

- The window is **1728×1117** with `window/stretch/aspect="expand"`
  (`project.godot`). UI is anchored to the viewport edges and must hold up when
  the window grows — never hard-size a panel that has anchored children.
- All game UI lives under the `UI` **CanvasLayer** in `scenes/main/main.tscn`:
  `HamburgerMenu`, `ConfirmDialog`, `Toolbar`, `ZoomControls`, `GridToggle`,
  `SelectionMenu`. Canvas elements live under `Canvas`, separate from UI.
- UI scenes live in `scenes/ui/*` (one directory per widget) and are *instances*
  in `main.tscn`. Two exceptions are instantiated from code in
  `main.gd _ready()`: the legend panel and the text-edit overlay.
- Naming: `camelCase` nodes, `snake_case` scripts, one class per file.
- Widgets never call `Main` directly — they **emit signals** that `main.gd`
  connects (see [Signal conventions](#signal-conventions)).

<a name="the-theme"></a>

## The theme (`resources/theme.tres`)

- uid: `uid://djjxeedxnscap` · path: `res://resources/theme.tres`
- It is a **dark, neutral-chrome** family of styles: Button, Label, Panel,
  PopupMenu, TooltipLabel. It is **not** a project-wide theme (nothing is set
  under `gui/theme/custom` in `project.godot`).

### What it styles

| Type (theme category) | Values |
|---|---|
| `Button/styles` | `StyleBoxFlat` normal `0.18` / hover `0.25` / pressed `0.2,0.4,0.8` (blue) / disabled `0.12`; 1px `0.3` borders; corner radius 6 |
| `Button/font_sizes/font_size` | **40** (large, chunky buttons) |
| `Button/colors` | font 0.85 → white on hover/pressed |
| `Label/font_sizes/font_size` | **35** |
| `Panel/styles/panel` | translucent `0.12` @ 0.9 alpha, radius 8 |
| `PopupMenu` | font_size **24**, h/v separation **8/4**, icon_max_width **40** |
| `TooltipLabel/font_sizes/font_size` | **28** |

### Where it's applied

Each UI scene **loads the theme explicitly** on its root node:

- `scenes/tools/toolbar.tscn`
- `scenes/ui/hamburger_menu/hamburger_menu.tscn`
- `scenes/ui/zoom_controls/zoom_controls.tscn`
- `scenes/ui/grid_toggle/grid_toggle.tscn`

Because a root `theme =` propagates to descendants, everything under those
roots is styled. Scenes that do **not** load it (`selection_menu`,
`legend_panel`, `text_edit_overlay`, `confirm_dialog`, `color_palette`) get the
Godot default theme and are styled with node-level `theme_override_*` instead.

<a name="theme-vs-overrides"></a>

## When to use theme.tres vs per-node overrides

- **theme.tres** = "all controls of this type should look like this" (e.g., the
  app font sizes, or the compact PopupMenu styling).
- **`theme_override_*` on a node** = "this one control deviates" (e.g., a
  single panel with a custom background).
- Rule of thumb for existing UI: when *every* control of a type should match,
  put it in **theme.tres** and let each scene inherit it (the compact PopupMenu
  sizes are a theme-level decision — see below). Reach for a per-node override
  only for a genuine one-off that shouldn't touch other controls of the same
  type.
- Common override keys you'll see: `theme_override_font_sizes/font_size`,
  `theme_override_constants/{h_separation,v_separation,margin_*}`,
  `theme_override_styles/background`, `theme_override_colors/*`, and for
  containers `theme_override_constants/separation`.

<a name="popupmenu"></a>

## PopupMenu — special rules

PopupMenu is the #1 source of confusion. Unlike Buttons/Labels it derives from
**Window, not Control**:

- **No typed theme members.** `popup.font_size` / `popup.icon_max_width` are
  *parse errors* under this project's strict warnings (even though 4.x surfaces
  the theme items in IDE property lists), and `popup.get("font_size")` returns
  `null`. There is no `get_theme_constant()` on a popup.
- **Compact styling lives in the shared theme** (`theme.tres`, `PopupMenu/*`):
  font_size 24, h_separation 8, v_separation 4, icon_max_width 40. This is an
  app-wide decision — toolbar submenus and the hamburger menu all inherit it
  with **no per-node overrides**. Read the values from the theme resource:
  ```gdscript
  var size: int = theme.get_font_size("font_size", "PopupMenu")       # 24
  var h: int = theme.get_constant("h_separation", "PopupMenu")        # 8
  var v: int = theme.get_constant("v_separation", "PopupMenu")        # 4
  var cap: int = theme.get_constant("icon_max_width", "PopupMenu")    # 40
  ```
- **`oversampling_override = 1.0` stays per-popup** in the `.tscn` — it's a
  Window property, not themeable.
- **Adding items:** `popup.add_icon_item(tool.icon, "")` + a per-item tooltip.
  Do **not** call `set_item_icon_max_width()` per item — the theme's
  `icon_max_width` caps the big 192px source icons (an unset per-item value of
  0 means "follow the theme").
- **Popups are separate windows** and only open on a button press, so a plain
  screenshot of the running app never shows them. The dev-only
  `scenes/tools/menu_review.tscn` instantiates the real toolbar and pops both
  submenus open for `godot_capture` review.

<a name="icons--buttons"></a>

## Icons & buttons

- Icons are SVGs under `res://assets/` (`ellipse.svg`, `circle-small.svg`,
  `triangle.svg`, `mouse-pointer.svg`, `menu.svg`, `grid-3x3.svg`, `plus.svg`,
  `minus.svg`, `chevron-up.svg`).
- Tool icons are typed **`DPITexture`** (a Godot 4.4+ high-DPI wrapper), not
  plain `Texture2D` — see `resources/tool.gd`. Don't cast them casually.
- The SVG sources are large (~192px). Buttons use **`expand_icon = true`** to
  squeeze them into the button; the shared theme caps popup item icon width via
  `PopupMenu/constants/icon_max_width` (above).
- Buttons are deliberately **chunky touch targets**: 80×80 (zoom, grid,
  hamburger) or **100×80** (toolbar). Keep `icon_alignment = 1` (center) and
  don't shrink these below their declared minimum.
- Toggle buttons: toolbar Select/Shape/Node use `toggle_mode = true` and the
  pressed state is driven by `ToolContext` (only the active tool has
  `button_pressed = true`).

<a name="anchoring--screen-placement"></a>

## Anchoring & screen placement

| Widget | Screen position | Notes |
|---|---|---|
| `HamburgerMenu` | top-left (16,16) | 80×80 button |
| `GridToggle` | top-right (-68 → -16) | 80×80 button |
| `ZoomControls` | bottom-right (VBox of 80×80) | ZoomIn above ZoomOut |
| `Toolbar` | bottom-center (PanelContainer) | 100×80 buttons in an HBox |
| `LegendPanel` | bottom-left | added at runtime by `main.gd` |
| `SelectionMenu` | floats near selection | added statically, repositioned by Main |
| `TextEditOverlay` | fullscreen overlay | added at runtime by `main.gd` |

`main.tscn` overrides toolbar offsets (`offset_top = -40`, `offset_bottom = 0`)
inside the UI layer — the standalone `toolbar.tscn` uses `-80`/`-20`. Keep them
consistent when editing.

<a name="input-actions"></a>

## Input actions

Defined in `project.godot` `[input]` — UI buttons show the shortcut in their
tooltips (e.g. tooltip_text `"Zoom in (Ctrl+=)"`):

- `grid_toggle` — G
- `zoom_in` — Ctrl+=  / Ctrl+KP+
- `zoom_out` — Ctrl+−  / Ctrl+KP−
- `zoom_reset` — Ctrl+0 / Ctrl+KP0

Don't hardcode keys in scripts; use `Input.is_action_pressed(...)` and the
actions above (as `main.gd` does for `ui_cancel` and `grid_toggle`).

<a name="signal-conventions"></a>

## Signal conventions

UI widgets own their visuals; `main.gd` owns the logic. Widgets expose signals
and `main.tscn` wires them (`[connection]` lines at the bottom of the scene
file). Examples: `clear_requested`, `zoom_in_requested`/`zoom_out_requested`,
`grid_toggle_requested`, `shape_sub_mode_changed`/`node_sub_mode_changed`/
`select_mode_toggled` (toolbar), `delete_requested`/`color_selected`
(selection menu), `text_committed`/`text_cancelled` (overlay), `name_changed`
(legend). If your widget needs something from the app, **add a signal**, don't
call into Main.

<a name="known-issues--open-items"></a>

## Known issues / open items

From `TODO.md` — do not "fix" silently, they're explicit follow-ups:

- **Toolbar popup items are icon-only** (names live only in tooltips). Decided
  keep minimal or add item text — if adding text, re-check the compact
  font/separation values in the shared theme still size the menu sensibly.

<a name="testing-ui"></a>

## Testing UI

- Tests live in `tests/unit/` (e.g. `tests/unit/tools/test_toolbar.gd`) and run
  with GdUnit4: `bash addons/gdUnit4/runtest.sh -a res://tests/...` (the `-a`
  argument wants a **res:// path**, not an absolute one).
- **Instantiate the `.tscn`, not the script.** Widgets often set `@export`
  resources (tool lists, tools) in their scene, so `Widget.new()` is missing
  them. Start from `preload("res://.../widget.tscn").instantiate()`.
- Preloaded shared resources (e.g. `ToolContext`) persist across tests — call
  `.reset()` in `before_test()`.
- `project.godot` promotes many warnings to **errors**: avoid unsafe access,
  don't `await` non-coroutines (e.g. `simulate_frames()`), and use
  `assert_that(x).is_equal(true)` (there is no usable `is_true()`).
  The full, hard-won list is in **`gofast.md`** at the repo root.
- For **visual** checks (sizes, alignment, popups) use `godot_capture` on the
  scene (or `menu_review.tscn` for the toolbar popups) and review the screenshot
  — sharing numeric + visual assertions is the pattern the toolbar suite uses.

<a name="colors"></a>

## Colors

UI chrome is the dark neutral gray family from `theme.tres`. The **content**
palette (blue, red, green, amber, purple, white, black) is documented in
`docs/user_experience/colors.md` — it belongs to canvas shapes, not the UI
chrome. Don't add new accent colors to UI without checking that doc first.