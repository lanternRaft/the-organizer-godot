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

## User Experience Documentation

Player-facing interaction descriptions in qualitative, human-readable terms:

| Subject | File |
|---|---|
| Canvas navigation (pan, zoom, grid) | [docs/user_experience/navigating_the_canvas.md](docs/user_experience/navigating_the_canvas.md) |
| Creating elements (shapes, nodes, arrows) | [docs/user_experience/creating_elements.md](docs/user_experience/creating_elements.md) |
| Selecting and manipulating (selection, drag, resize, bump, delete) | [docs/user_experience/selecting_and_manipulating.md](docs/user_experience/selecting_and_manipulating.md) |
| Text editing on shapes | [docs/user_experience/editing_text.md](docs/user_experience/editing_text.md) |
| Colors and legend | [docs/user_experience/colors_and_legend.md](docs/user_experience/colors_and_legend.md) |
| Managing your work (copy/paste, auto-save, clear, export) | [docs/user_experience/managing_your_work.md](docs/user_experience/managing_your_work.md) |

## Syncing

This is the canonical contract between design and implementation. Any implementation change that modifies a documented behavior, adds/removes a feature, or alters the user interface **must also update** the relevant file under `docs/` (or `APP_DESIGN.md` if the subject spans multiple docs).