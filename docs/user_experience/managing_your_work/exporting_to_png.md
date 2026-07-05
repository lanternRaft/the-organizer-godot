# Exporting to PNG

Exporting captures the entire canvas as a high-resolution PNG image. It's how the user shares their diagram outside the application.

## How it works

1. Open the hamburger menu (top-left corner)
2. Select **Export PNG**
3. The application computes the bounding box of all elements, adds padding, and renders a high-resolution (2×) image
4. The image is saved with a date-stamped filename (e.g., `the-organizer-YYYY-MM-DD.png`)

The export captures everything on the canvas — shapes, text, arrows, colors — but not the grid. The exported image is a clean representation of the diagram.

The export uses the full canvas extent, not the current viewport. This means the user doesn't have to frame the shot — they get the entire diagram regardless of where the camera was pointed.

### Why auto-named export files

Asking for a file path in a dialog would break the flow. The user wants to capture their work quickly, not navigate a file picker. The auto-named file with date stamps means the user can export multiple times in a session and each export produces a distinct file.
## Behavior

- **Empty canvas export:** The export produces a small image containing just the padding area — effectively a blank image. This is technically correct but unlikely to be useful. The menu doesn't disable the export option for empty canvases.
- **Export with hidden elements:** Exports always include everything on the canvas.
- **High-resolution rendering:** The 2× resolution means the exported image looks crisp even on retina displays. The trade-off is a slightly larger file and a brief render pause for very complex canvases.

---

Parent feature: [Managing Your Work](README.md)