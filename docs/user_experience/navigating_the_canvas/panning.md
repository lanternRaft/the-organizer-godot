# Panning

The canvas pans in any direction. The user never hits an edge — the board is effectively infinite. Panning is how the user moves to different areas of their diagram.

## How it works

There are four ways to pan:

1. **Scroll-wheel** (no modifier) pans vertically. Scroll up to go up, scroll down to go down.
2. **Shift + scroll-wheel** pans horizontally instead of vertically. This feels natural to anyone who's used a spreadsheet or design tool — holding Shift swaps the axis.
3. **Middle-click drag** — clicking and holding the middle mouse button while moving the mouse lets the user "grab" the canvas and pull it around. The canvas follows the mouse motion directly: drag right, the canvas slides right; drag left, it slides left.
4. **Trackpad two-finger drag** — on a laptop, two fingers sliding across the trackpad pans the canvas smoothly.

## How it feels

Panning should feel direct and immediate — no lag, no acceleration curves, no easing. The canvas is heavy but frictionless: it stays exactly where the user puts it and doesn't drift.

## Why this approach

Offering multiple pan methods acknowledges that different users work in different environments. A designer with a mouse reaches for middle-click. A writer on a laptop uses two-finger gestures. A power user who's already scrolling through a document uses the wheel — and Shift feels natural for axis switching because it's the standard convention across creative tools.

## Edge cases

- **Trackpad cleanup:** After a two-finger pan, the canvas doesn't lurch or jump — it settles exactly where the user left it.
- **Middle-click on elements:** Middle-click pans through everything — shapes, selections, arrows. It never triggers a selection, drag, or tool action. The middle button is reserved exclusively for canvas navigation.

---

Parent feature: [Navigating the Canvas](README.md)