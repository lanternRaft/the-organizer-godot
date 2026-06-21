# Keys / Legend

An auto-generated legend panel in the bottom-left corner that lists colors currently in use on the canvas. Each entry has:

- A colored circle swatch (`ColorRect`)
- An editable label (`LineEdit` node) — click to rename
- Default names: `Group 1`, `Group 2`, etc.
- Custom names are stored in `State.legend_colors` Dictionary and persist until the color is no longer in use
- Hidden when no colors are in use