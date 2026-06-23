# Navigating the Canvas

**Audience:** Designers + developers | **Scope:** Player-facing canvas navigation interactions only

## Overview

The canvas is an infinite whiteboard. The user moves around it the same way they'd move around a physical desk covered in papers — they scoot their chair left or right, lean in to see details, lean back to see the big picture. The navigation system should feel transparent, never demanding attention or getting in the way.

---

## Panning (Scrolling)

The canvas pans in any direction. The user never hits an edge — the board is effectively infinite.

### How the user does it

There are three ways to pan:

1. **Scroll-wheel** (no modifier) pans vertically. Scroll up to go up, scroll down to go down.
2. **Shift + scroll-wheel** pans horizontally instead of vertically. This feels natural to anyone who's used a spreadsheet or design tool — holding Shift swaps the axis.
3. **Middle-click drag** — clicking and holding the middle mouse button while moving the mouse lets the user "grab" the canvas and pull it around. The canvas follows the mouse motion directly: drag right, the canvas slides right; drag left, it slides left.
4. **Trackpad two-finger drag** — on a laptop, two fingers sliding across the trackpad pans the canvas smoothly.

### How it feels

Panning should feel direct and immediate — no lag, no acceleration curves, no easing. The canvas is heavy but frictionless: it stays exactly where the user puts it and doesn't drift.

### Why these choices

Offering multiple pan methods acknowledges that different users work in different environments. A designer with a mouse reaches for middle-click. A writer on a laptop uses two-finger gestures. A power user who's already scrolling through a document uses the wheel — and Shift feels natural for axis switching because it's the standard convention across creative tools.

### Edge cases

- **Trackpad gesture suppression:** When a user finishes a two-finger pan, some trackpads generate a synthetic scroll-wheel event. The system ignores wheel events that arrive within a short window after a trackpad gesture. Without this, the canvas would lurch an extra step after every pan.
- **Middle-click on elements:** Middle-click pans through everything — shapes, selections, arrows. It never triggers a selection, drag, or tool action. The middle button is reserved exclusively for canvas navigation.

---

## Zooming

The user can zoom from very far out (10% zoom) to extremely close in (2000% zoom). There's no "correct" zoom — just the one that fits what the user is working on.

### How the user does it

1. **Ctrl/Cmd + scroll-wheel** — the most common zoom method. Scroll up to zoom in, scroll down to zoom out. The zoom centers on wherever the cursor is pointing, so the user can zoom into a specific detail without having to pan first.
2. **Zoom buttons** — a vertical stack of three buttons in the bottom-right corner of the screen:
   - **+** button zooms in by a step, centered on the viewport middle
   - **−** button zooms out by a step, centered on the viewport middle
   - **⟳** button resets zoom to 100% and recenters the canvas at the origin
3. **Keyboard shortcuts:**
   - **Ctrl/Cmd + =** (or +) — zoom in
   - **Ctrl/Cmd + −** — zoom out
   - **Ctrl/Cmd + 0** — reset zoom and recenter
4. **Trackpad pinch-to-zoom** — two fingers pinching in or out on a trackpad. The zoom centers on the pinch gesture's focus point.

### How it feels

Zooming should feel smooth and responsive. When zooming with the scroll wheel (cursor-centered), the point under the cursor stays fixed — the user is effectively "pulling" the canvas toward them or pushing it away. The 1.25× per step ratio is aggressive enough to feel like rapid progress without being jerky.

At maximum zoom-out (10%), individual shapes are small dots. At maximum zoom-in (2000%), the user can see fine details of a single shape's text. Most work happens between 50% and 200%.

### Why these choices

Cursor-centered zoom is critical: it means zooming and panning are often a single motion. The user points at something, zooms in, and it's right there — no need to pan afterward. The button stack exists as a fallback and for discoverability (new users look for buttons before trying shortcuts).

### Edge cases

- **Zoom clamp at extremes:** If the user is already at 10% zoom and tries to zoom out, nothing happens. Same at 2000% zooming in. The buttons and shortcuts are simply ignored — no error, no flash.
- **Zoom while editing text:** Zoom controls work even while the text editor is open. The user might want to zoom in to read small text as they type.
- **Reset after extreme zoom:** The reset button (and Ctrl+0) is the safety net — one action gets the user back to a known state regardless of how far they've zoomed or panned.

---

## The Grid

A grid overlays the canvas to provide spatial reference. It starts on by default.

### How the user controls it

- **G key** toggles the grid on and off
- A **⊞ button** in the top-right corner of the screen does the same thing, with a tooltip reading "Toggle grid (G)"

### How it feels

The grid is subtle — thin lines at low opacity — present enough to guide the eye but quiet enough to ignore when it's not needed. It's like the lines on graph paper: useful for alignment but not part of the drawing.

### Why grid is on by default

World building often involves organizing ideas spatially — clusters, hierarchies, timelines. The grid provides an implicit spatial framework that makes it easier to arrange shapes at consistent intervals and spot misalignments.

### Edge cases

- **Grid state is remembered:** If a user turns off the grid, closes the app, and comes back the next day, the grid is still off. This respects the user's working preference.
- **Grid toggles instantly:** No animation, no fade — it's either there or it's not. Deliberate: the grid is a reference tool, not a visual effect.