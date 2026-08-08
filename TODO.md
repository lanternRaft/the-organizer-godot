# TODO

Follow-ups and deferred work. See also `docs/` for product decisions.

## UI / Toolbar
- [ ] **Hamburger menu popup is still oversized.** The `PopupMenu` in
  `scenes/ui/hamburger_menu/hamburger_menu.tscn` inherits the app theme's large
  `PopupMenu` font (34px), so it is tall relative to its 80px menu button. It
  wasn't part of the toolbar-submenu fix (PR #15). Apply the same treatment as
  the toolbar popups — a smaller font + tighter separations, and cap item icon
  width — for consistency, once verified it doesn't hurt readability.

- [ ] **Toolbar popup items are icon-only (names live in tooltips).** In
  `scenes/tools/toolbar.gd`, `_setup_tools()` adds items via
  `add_icon_item(tool.icon, "")`, so the Shape/Node submenus show only icons
  with no text labels. Decide whether to add the tool name as the item text
  (better discoverability / screenshot readability) or keep the minimal
  icon-only look. If adding text, re-check the compact font/separation
  overrides applied in PR #15 still size the menu sensibly.
