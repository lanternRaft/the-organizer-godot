# gofast.md

Lessons from adding the toolbar test suite (`tests/unit/tools/test_toolbar.gd`).
Each item is an actionable change that would have cut wasted cycles next time,
and most should live permanently as agent notes / helpers for this repo.

## 1. Write a `tests/README` GdUnit quirk sheet before touching assertions

The biggest time sink was rediscovering GdUnit4's API against this project's
strict warnings config (`project.godot` promotes many warnings to errors).

- There is **no `assert_true()`/`assert_false()`/`assert_that(...).is_true()`**.
  `is_true()` only exists on `GdUnitBoolAssert`, a *subtype* of the
  `GdUnitAssert` that `assert_that()` is inferred to return — under this
  project's `unsafe_method_access` warning it's a **parse error**.

  Working pattern (base `GdUnitAssert` methods only):
  ```gdscript
  assert_that(popup.is_visible()).is_equal(true)
  assert_that(button.button_pressed).is_equal(false)
  ```
- `await` on non-coroutines (e.g. `runner.simulate_frames(2)`) is also a
  parse error here. `simulate_frames()` is sync — **don't await it**; only
  `await get_tree().process_frame` / `await _helper()`.
- `scene_runner()` accepts a **`res://` path or an instantiated node**; passing
  a bare/absolute path makes the runner silently report "0 tests ran".

**Action:** commit a short `tests/README.md` with these exact patterns so the
next session never re-derives them. Also note: prefer `.is_equal()` over
`is_true()/is_false()` everywhere in this repo.

## 2. Note: instantiate the `.tscn`, not `Toolbar.new()`

`Toolbar.new()` has **empty** `shape_tools`/`node_tools` because those exports
are populated in `toolbar.tscn` (preloaded `Tool` resources), not in the script.
The pre-existing `test_arrow_layer` uses `Toolbar.new()` and thus tests a toolbar
with no tools — I nearly copied that pattern into submenu/size tests.

**Action:** for any UI with scene-defined `@export` resources, start from
`preload("...tscn").instantiate()`. Add an agent note: *"if a node's exports are
set in its .tscn, instantiate the scene, not the script."*
Also `tool_context` is a **preloaded shared resource** — call
`toolbar.tool_context.reset()` in `before_test()` or state leaks between tests.

## 3. Add a tiny shared test fixture for popup+toolbar interactions

Writing layout/popup plumbing per-test was repetitive and each `await` step was
a chance for a timing bug.

**Action:** add `tests/helpers/toolbar_fixture.gd` exposing:
- `spawn_toolbar() -> Toolbar` (instantiates scene, resets context, runs
  `scene_runner` + `simulate_frames(2)` so sizes are settled).
- `open_popup(button, popup)` (emit pressed, `await process_frame`, assert
  visible) — the helper used in the toolbar suite.

Then behavioral tests are one-liners and sizing tests can assert immediately
without re-writing the settle boilerplate.

## 4. Reading PopupMenu styling (non-Control nodes)

Verifying the "compact submenu" display sizes took several failed iterations.
PopupMenu derives from `Window`, not `Control`, so:

- `popup.font_size` / `popup.h_separation` / `popup.icon_max_width` — **not**
  typed members on `PopupMenu` → `unsafe_property_access` parse error (even
  though 4.x lists these as theme items in the IDE).
- `popup.get("font_size")` → runtime `null` (plain property name).
- Per-node overrides worked at first (`popup.get("theme_override_...")`), but
  review moved the compact sizing into the **shared theme** for consistency, so
  display-size checks now read the theme resource directly:
  ```gdscript
  var theme: Theme = preload("res://resources/theme.tres")
  assert_int(theme.get_font_size("font_size", "PopupMenu")).is_equal(24)
  assert_int(theme.get_constant("h_separation", "PopupMenu")).is_equal(8)
  assert_int(theme.get_constant("v_separation", "PopupMenu")).is_equal(4)
  assert_int(theme.get_constant("icon_max_width", "PopupMenu")).is_equal(40)
  ```

**Action:** put the theme-resource snippet in the `tests/README` (item 1)
under a "reading PopupMenu styling" section so display-size checks are
copy-paste.

## 5. Verify visual display sizes with `godot_capture` + `godot_vision` early

"Things display at expected sizes" is ultimately a visual claim. I wired up all
assertions first and only screenshotted at the end; the vision pass instantly
confirmed ~100×80 buttons, popups not overlapping, and compact menu heights,
which would have caught the *reason* behind size assertions earlier.

**Action / tips:**
- Run `godot_capture res://scenes/tools/toolbar.tscn` (bare toolbar) **and**
  `res://scenes/tools/menu_review.tscn` (dev-only scene that auto-opens both
  popups side-by-side) at the start of any toolbar task.
- Feed both PNGs to `godot_vision` with a concrete checklist prompt
  (button w×h, row alignment, popup overlap, compactness relative to button)
  before finalizing numeric assertions.
- Keep a reusable "size checklist" vision prompt in agent notes so the loop is
  one call instead of writing a new prompt each time.