# Hamburger Menu

A hamburger button in the top-left corner toggles a `PopupMenu` with:

| Item | Action |
|---|---|
| **Export PNG** | Exports the canvas as a PNG image. Computes bounding box of all elements, adds 40px padding, renders at 2× resolution via a temporary `Viewport`. Saves to `user://exports/the-organizer-YYYY-MM-DD.png`. |
| **Clear** | Opens the confirmation dialog to clear the canvas |

The dropdown closes on outside click and on `PopupMenu.index_pressed`.