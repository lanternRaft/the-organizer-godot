# Managing Your Work

**Audience:** Designers + developers | **Scope:** Player-facing interactions for copy/paste, persistence, clear, export, and the hamburger menu

## Overview

The user works on their canvas over multiple sessions. They copy elements they like, paste them elsewhere, save automatically, clear the board to start fresh, and export finished diagrams as images. These operations form the lifecycle of working with a canvas — from a blank slate to a shareable artifact.

---

## Copy and Paste

### How it works

1. Select one or more elements
2. Press **Ctrl/Cmd + C** — the selected elements are copied to an in-memory clipboard
3. Press **Ctrl/Cmd + V** — copies of the copied elements appear on the canvas, offset slightly from their originals
4. The pasted copies are automatically selected, ready to be moved into position

### What gets copied

All information about the selected elements is preserved:

- **Shapes:** Position, dimensions (rx/ry), fill color, text content, shape mode (oval/circle)
- **Arrows:** Path points, color, connection anchors (if both endpoints are in the selection)

### The paste offset

Pasted elements appear shifted by a small buffer relative to the originals — just enough to make it clear they're new copies and not duplicates that need to be moved out of each other's way. The offset is consistent: every paste applies the same shift, so repeated paste operations create a cascading line of copies.

### How paste feels

Paste is like a duplication tool. The user copies one well-configured shape — right color, right size, right text — and pastes it multiple times, then drags each copy to its intended spot. The offset ensures the new copy doesn't overlap precisely with the original, but it's small enough that the user doesn't have to hunt for where the paste landed.

### Edge cases

- **Paste with nothing copied:** Nothing happens. The clipboard is empty, and the paste operation is silently ignored.
- **Copying arrows without their endpoint shapes:** The arrow is copied, but since the copied arrow's endpoints reference the originals (not the copies), the pasted arrow may appear disconnected. The user can re-anchor it to the desired shapes after paste.
- **Copying both shapes and the arrow between them:** If the user selects a shape, the arrow connecting it to another shape, and that other shape, then copies and pastes the whole set, the pasted arrow reconnects to the pasted shapes. This creates a self-contained copy of a sub-diagram.
- **Clipboard replacement:** Each new copy operation replaces the previous clipboard contents. Multiple copy operations don't accumulate.

---

## Auto-Save

### How it works

The canvas saves itself automatically after every meaningful action. The user never has to think about saving:

- Placing a shape → save
- Deleting an element → save
- Dragging an element to a new position → save (on release, not during the drag)
- Changing a color → save
- Committing text → save
- Pasting → save

The save goes to a file stored in the application's persistent data directory. It happens silently in the background — no progress bar, no "saving" indicator, no confirmation dialog.

### How auto-save feels

The canvas remembers everything. The user can close the application at any moment, and when they come back, everything is exactly as they left it. There's no implicit trust required — the save happens so frequently that losing work is essentially impossible under normal use.

### What's saved

Every element on the canvas, with all of its properties:
- Shapes: type, position, dimensions, color, text, shape mode
- Arrows: points, endpoints (by reference), direction, color
- Legend: color-to-name mappings
- Grid state and theme preference are saved to a separate config file

### When saving doesn't happen

- During a drag (only on release)
- While text is being edited (only on commit or cancel)
- During view-only actions like panning, zooming, or selecting

### Edge cases

- **Save failure:** If the save file can't be written (permissions, disk full), an error is logged but the user isn't interrupted. The in-memory canvas is preserved, and the user can manually export their work as a PNG backup.
- **Corrupted save file:** If the save file is corrupted, the application starts with an empty canvas. The corrupted file is left in place for potential recovery but isn't loaded.
- **First launch:** No save file exists. The user starts with a clean, empty canvas. Auto-save kicks in as soon as they place their first element.

---

## Clearing the Canvas

### How it works

1. Open the hamburger menu (top-left corner)
2. Select **Clear**
3. A confirmation dialog appears with the message: "This will delete everything on the canvas. This cannot be undone."
4. The user can either confirm (clear everything) or cancel (return to the canvas)

### The confirmation dialog

This is the only destructive action that requires a confirmation. Individual deletions (Delete key) don't ask for confirmation — but wiping the entire board does. The dialog makes it clear what will happen and that there's no undo. Two buttons: **Cancel** dismisses the dialog, and the Clear button executes the wipe.

### How clearing feels

Wiping the canvas should feel decisive. Everything vanishes — shapes, arrows, text, legend — and the canvas returns to its pristine blank state. The auto-save immediately records the empty state, so closing and reopening shows the blank canvas. There's no going back without redoing work, which is why the confirmation dialog exists.

### Edge cases

- **Cancel mid-dialog:** The user can close the dialog via Cancel, the window close button, or Escape. The canvas is untouched, and the user continues working.
- **Empty canvas + Clear:** The dialog still appears. Confirming on an already-empty canvas is a no-op but isn't an error — it just saves the empty state again.
- **Auto-save after clear:** The cleared state is saved immediately, preventing recovery by reopening.

---

## Exporting to PNG

### How it works

1. Open the hamburger menu (top-left corner)
2. Select **Export PNG**
3. The application computes the bounding box of all elements, adds padding, and renders a high-resolution (2×) image
4. The image is saved to `user://exports/the-organizer-YYYY-MM-DD.png`

The export captures everything on the canvas — shapes, text, arrows, colors — but not the grid. The exported image is a clean representation of the diagram.

### How export feels

Export is fire-and-forget. There's no dialog asking for a file name or location (the filename is auto-generated with the current date). The user clicks Export PNG, and a moment later the image exists in the exports directory. They can then open that directory to get the file.

The export uses the full canvas extent, not the current viewport. This means the user doesn't have to frame the shot — they get the entire diagram regardless of where the camera was pointed.

### Why auto-named export files

Asking for a file path in a dialog would break the flow. The user wants to capture their work quickly, not navigate a file picker. The auto-named file with date stamps means the user can export multiple times in a session and each export produces a distinct file.

### Edge cases

- **Empty canvas export:** The export produces a small image containing just the padding area — effectively a blank image. This is technically correct but unlikely to be useful. The menu doesn't disable the export option for empty canvases.
- **Export with hidden elements:** There's no way to hide elements (not yet implemented), so exports always include everything.
- **High-resolution rendering:** The 2× resolution means the exported image looks crisp even on retina displays. The trade-off is a slightly larger file and a brief render pause for very complex canvases.

---

## The Hamburger Menu

A button in the top-left corner of the screen (three horizontal lines, the classic "hamburger" icon) opens a dropdown menu with two items:

| Item | Action |
|---|---|
| **Export PNG** | Exports the full canvas as a high-resolution PNG image |
| **Clear** | Opens the confirmation dialog to wipe the canvas |

The menu closes automatically after selecting an item or clicking outside it.

### How the hamburger menu feels

It's tucked away in the corner — visible when needed, unobtrusive when not. The two actions it contains are infrequent enough that they don't need toolbar buttons, but important enough that they should be reachable in a click or two. The hamburger icon is universally recognized as "more options" so new users know to look there.

### Edge cases

- **Export while editing text:** The hamburger menu is available during text editing. If the user exports while the text overlay is open, the export captures the canvas state as-is (the overlay isn't rendered in the export).
- **Multiple rapid exports:** Each export creates a new file with a timestamp. Rapid successive exports within the same second may overwrite each other (same filename). In practice, users rarely export more than once per session.