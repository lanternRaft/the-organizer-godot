# Hamburger Menu

A button in the top-left corner of the screen (three horizontal lines, the classic "hamburger" icon) opens a dropdown menu with two infrequent-but-important actions.

## How it works

### Menu items

| Item | Action |
|---|---|
| **Export PNG** | Exports the full canvas as a high-resolution PNG image |
| **Clear** | Opens the confirmation dialog to wipe the canvas |

The menu closes automatically after selecting an item or clicking outside it.

## How it feels

It's tucked away in the corner — visible when needed, unobtrusive when not. The two actions it contains are infrequent enough that they don't need toolbar buttons, but important enough that they should be reachable in a click or two. The hamburger icon is universally recognized as "more options" so new users know to look there.

## Edge cases

- **Export while editing text:** The hamburger menu is available during text editing. If the user exports while the text overlay is open, the export captures the canvas state as-is (the overlay isn't rendered in the export).
- **Multiple rapid exports:** Each export creates a new file with a timestamp. Rapid successive exports within the same second may overwrite each other (same filename). In practice, users rarely export more than once per session.

---

Parent feature: [Managing Your Work](README.md)