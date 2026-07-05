# Grid

A grid overlays the canvas to provide spatial reference. It starts on by default. The grid is subtle — present enough to guide the eye but quiet enough to ignore when it's not needed.

## How it works

- **G key** toggles the grid on and off
- A **⊞ button** in the top-right corner of the screen does the same thing, with a tooltip reading "Toggle grid (G)"

The grid toggles instantly — no animation, no fade. It's either there or it's not. Deliberate: the grid is a reference tool, not a visual effect.

Grid state is remembered across sessions. If a user turns off the grid, closes the app, and comes back the next day, the grid is still off.
## Why this approach

World building often involves organizing ideas spatially — clusters, hierarchies, timelines. The grid provides an implicit spatial framework that makes it easier to arrange shapes at consistent intervals and spot misalignments. Having it on by default means new users benefit immediately, and one keystroke (G) is all it takes to turn it off.

## Behavior

- **Grid toggle during a drag:** Toggling the grid while dragging an element works. The state change is visual only — it doesn't affect the drag or snap behavior.
- **Grid is not exported:** The grid is a canvas-only reference. PNG exports always exclude the grid, producing a clean diagram.

---

Parent feature: [Navigating the Canvas](README.md)