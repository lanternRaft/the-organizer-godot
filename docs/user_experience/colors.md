# Colors

Color gives meaning to shapes beyond their text and position. A red oval might represent a hostile faction, a green one a safe location, a blue one a neutral character. The color palette (documented here) and the [legend panel](legend.md) work together to create a visual coding system that the user defines.

## How it works

### Changing a shape's color

1. Select a single shape
2. The selection menu appears below it with two buttons: Del and Color
3. Click the **Color** button
4. A small palette appears above the button with eight color swatches in a 2×4 grid
5. Click a swatch — the shape changes color instantly, the palette closes, and the canvas auto-saves

### The palette

Eight colors, chosen for readability and distinctiveness: blue, red, green, amber, purple, white, black

### The selection menu

The menu that holds the Color button only appears when exactly one element is selected. It positions itself below the selected element, following it if the element moves or the camera zooms. It's always just out of the way — accessible but not intrusive.
## Why this approach

A palette with more colors would require scrolling, searching, or a complex picker. For a world-building tool where colors are used as categorical signals (this faction is red, that faction is blue), a limited, carefully-chosen set encourages the user to think in terms of categories rather than shades. Eight is enough to represent distinct groups without overwhelming.

## Behavior

- **Color change on a multi-select:** The selection menu hides when more than one element is selected. To change colors of multiple shapes, the user must do them one at a time.
- **Color closes the palette:** Selecting a swatch closes the palette. This keeps the UI clean — no lingering popups after an action is taken.
- **Palette click prevention:** Clicks on the palette don't pass through to the canvas behind it. The palette captures the click and uses it only for swatch selection.

---

Once colors are applied to shapes, the [legend panel](legend.md) automatically lists them with editable names.