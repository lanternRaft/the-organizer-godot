# TODO

Follow-ups and deferred work. See also `docs/` for product decisions.

## UI / Toolbar
- [x] **Hamburger menu popup is still oversized.** Resolved in PR #15 — the
  compact PopupMenu values (24px font, h/v separation 8/4, `icon_max_width`
  40) were moved from per-node overrides into the shared `theme.tres`, so the
  hamburger popup inherits the same compact styling as the toolbar submenus.
  (Keep an eye on readability of text items like "Clear".)

- [ ] **Toolbar popup items are icon-only (names live in tooltips).** In
  `scenes/tools/toolbar.gd`, `_setup_tools()` adds items via
  `add_icon_item(tool.icon, "")`, so the Shape/Node submenus show only icons
  with no text labels. Decide whether to add the tool name as the item text
  (better discoverability / screenshot readability) or keep the minimal
  icon-only look. If adding text, re-check the compact font/separation values
  in the shared theme still size the menu sensibly.
