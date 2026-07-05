# Moving Elements

Moving elements is how the user rearranges their diagram. Elements can be moved individually or in groups, with subtle snap guidance on release.

## How it works

### Single drag

Clicking and dragging a shape or node moves it freely across the canvas. The element follows the cursor with no lag.

When the user releases, the element snaps to a coarse grid (20px increments). The snap is subtle — it may not even be visible at normal zoom, but it helps keep things aligned when building structured diagrams. The snap only applies on release, not during the drag, so the movement feels fluid.

### Multi-drag

When multiple elements are selected, dragging any one of them moves the entire set by the same amount. They all slide together, maintaining their relative positions. Mixed selections of shapes and nodes behave identically — both element types move in lockstep.

This is the primary way to rearrange a diagram. The user selects a cluster of related elements, drags it to a new area of the canvas, and the whole group moves in lockstep.

### What moves in a multi-drag

- All selected shapes and nodes move by the same pixel delta
- Arrows connected to moving elements automatically stretch and curve to follow their endpoints
- Free-floating arrows (arrows selected as part of the set, without their endpoint elements) also move by the same delta

## Behavior

- **Arrows that connect two selected elements:** The arrow updates its path as both of its endpoints move. It stretches, bends, and stays connected throughout the drag.

---

Parent feature: [Selecting and Manipulating](README.md)