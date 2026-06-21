# The Organizer — App Design

The canonical design document for The Organizer whiteboarding tool. Each subject has its own file under `docs/`.

## Table of Contents

| Subject | File |
|---|---|
| Project overview, implementation status, tech stack | [docs/overview.md](docs/overview.md) |
| Scene tree architecture (current + planned) | [docs/scene_tree.md](docs/scene_tree.md) |
| Tool modes and toolbar | [docs/tool_modes.md](docs/tool_modes.md) |
| State management (State autoload, EventBus) | [docs/state_management.md](docs/state_management.md) |
| Canvas elements (shapes, nodes, arrows, anchors) | [docs/elements.md](docs/elements.md) |
| Selection system (single, marquee, multi-drag, menu) | [docs/selection.md](docs/selection.md) |
| Keys / legend panel | [docs/legend.md](docs/legend.md) |
| ClickHandler architecture | [docs/click_handler.md](docs/click_handler.md) |
| Pan & zoom, keyboard shortcuts, resize | [docs/pan_zoom.md](docs/pan_zoom.md) |
| Copy / paste | [docs/copy_paste.md](docs/copy_paste.md) |
| UI controls (grid, theme, info bar) | [docs/ui_controls.md](docs/ui_controls.md) |
| Auto-save / persistence | [docs/persistence.md](docs/persistence.md) |
| Hamburger menu | [docs/hamburger_menu.md](docs/hamburger_menu.md) |
| Confirmation dialog | [docs/confirm_dialog.md](docs/confirm_dialog.md) |

## Syncing

This is the canonical contract between design and implementation. Any implementation change that modifies a documented behavior, adds/removes a feature, or alters the user interface **must also update** the relevant file under `docs/` (or `APP_DESIGN.md` if the subject spans multiple docs).