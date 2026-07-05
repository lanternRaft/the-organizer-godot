# Auto-Save

The canvas saves itself automatically after every meaningful action. The user never has to think about saving.

## How it works

The canvas saves after every meaningful action:

- Placing a shape → save
- Deleting an element → save
- Dragging an element to a new position → save (on release, not during the drag)
- Changing a color → save
- Committing text → save
- Pasting → save

It happens silently in the background — no progress bar, no "saving" indicator, no confirmation dialog.

### What's saved

Every element on the canvas, with all of its properties:
- Shapes: type, position, dimensions, color, text, shape mode
- Arrows: points, endpoints, direction, color
- Legend: color-to-name mappings
- Grid state and theme preference are remembered across sessions

### When saving doesn't happen

- During a drag (only on release)
- While text is being edited (only on commit or cancel)
- During view-only actions like panning, zooming, or selecting

## How it feels

The canvas remembers everything. The user can close the application at any moment, and when they come back, everything is exactly as they left it. There's no implicit trust required — the save happens so frequently that losing work is essentially impossible under normal use.

## Edge cases

- **Save failure:** If the save file can't be written (permissions, disk full), the user isn't interrupted. Their work on the canvas is preserved, and the user can manually export their work as a PNG backup.
- **Corrupted save file:** If the save file is corrupted, the application starts with an empty canvas. The corrupted file is left in place for potential recovery but isn't loaded.
- **First launch:** No save file exists. The user starts with a clean, empty canvas. Auto-save kicks in as soon as they place their first element.

---

Parent feature: [Managing Your Work](README.md)