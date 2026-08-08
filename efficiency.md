# Efficiency notes

Reflections on the toolbar-submenu fix (PR #15). It took many turns mostly
because of measurement/debugging loops. Each lesson below is a concrete change
that would have made this type of task faster next time, followed by the
**actionable** step (tool to add/change, skill, or doc note) that turns it into
a repeatable improvement.

---

1. **Measure the real thing first — don't guess the root cause.**
   I assumed the oversized menus were caused by the theme font (34px) and spent
   a full iteration applying font/separator overrides that did nothing. The
   actual cause was the icons rendering at their native 192×192.

   **Actionable — new dev tool:** add a reusable `scripts/geometry_dump.gd`
   (a `Node` you attach to any scene) that walks the subtree and prints every
   `Control`/`PopupMenu`/`Window` rect plus any `Texture2D.icon.get_size()` used
   by the inspected nodes. Running it once on `toolbar.tscn` would have shown
   `220×400` and `192×192` in a single read. Have the toolbar review scene
   instantiate it by default.

2. **Read the shared `.tres` theme and asset import sizes before editing.**
   The theme is global and the tool icons are imported at 192px — both were
   visible in the repo before any code change.

   **Actionable — agents.md note:** add a "UI sizing pre-flight" checklist item
   to `AGENTS.md`: *before changing UI sizes, check (a) `resources/theme.tres`
   `PopupMenu`/`Button` font & separation constants, (b) the asset import size
   via `icon.get_size()` / `.import`, since imported-at-large assets are the
   usual hidden culprit.* Tag this task `needs: ui-pre-flight`.

3. **Tighten the verify loop: keep the debug measurement on by default in the
   dev review scene.**
   I added an instrumentation dump, removed it, re-added it, then removed it
   again — repeatedly.

   **Actionable — tool change:** update `godot_capture` to (a) forward the
   scene's `print()`/`push_warning()` output to its return value, and (b) accept
   a flag (e.g. `--dump-geometry`) that enables debug prints in the scanned
   scene. That lets an agent get pixel geometry *with* the screenshot instead of
   re-instrumenting. Failing that, make `menu_review.gd` print geometry by
   default (one line) rather than removing it.

4. **Ask which "fix" is wanted up front — size, content, or both.**
   I guessed "fix the oversized size" and left the popups icon-only.

   **Actionable — new skill / process:** before implementing a UI "fix", use the
   `ask()` tool once to confirm scope: *fix size only, or also show item labels?
   apply the same treatment to the hamburger menu too?* One question avoids
   downstream TODO follow-ups and rework. Add this to the agent habits section
   of `AGENTS.md`.

5. **Prefer authoritative measurements over a vision model's subjective size
   reports.**
   The vision model said the popups were "~400px tall" and later "compact" —
   imprecise and even contradictory.

   **Actionable — agents.md note + tool wiring:** codify the rule: *for UI size
   questions, source numbers from a geometry dump (#1) / `print()` (#3); use the
   vision model only for qualitative checks (overlap, alignment, clipping).*
   Reference it in the `godot_capture` flow so reviewers default to measurements.

---

### Quick reference (who / where)
- **New tool:** `scripts/geometry_dump.gd` (reusable subtree geometry + asset
  size printer).
- **Tool change:** `godot_capture` — return scene stdout; add `--dump-geometry`
  flag; or default `menu_review.gd` to print geometry.
- **New skill:** clarify UI-fix scope via `ask()` before implementing; measure,
  don't guess.
- **agents.md note:** UI sizing pre-flight checklist; "measure over vision"
  guideline.
