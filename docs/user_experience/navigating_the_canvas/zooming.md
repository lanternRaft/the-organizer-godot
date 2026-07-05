# Zooming

The user can zoom from very far out (10% zoom) to extremely close in (2000% zoom). There's no "correct" zoom — just the one that fits what the user is working on.

## How it works

1. **Ctrl/Cmd + scroll-wheel** — the most common zoom method. Scroll up to zoom in, scroll down to zoom out. The zoom centers on wherever the cursor is pointing, so the user can zoom into a specific detail without having to pan first.
2. **Zoom buttons** — a vertical stack of three buttons in the bottom-right corner of the screen:
   - **+** button zooms in by a step, centered on the viewport middle
   - **−** button zooms out by a step, centered on the viewport middle
   - **⟳** button resets zoom to 100% and recenters the canvas at the origin
3. **Keyboard shortcuts:**
   - **Ctrl/Cmd + =** (or +) — zoom in
   - **Ctrl/Cmd + −** — zoom out
   - **Ctrl/Cmd + 0** — reset zoom and recenter
1. **Trackpad pinch-to-zoom** — two fingers pinching in or out on a trackpad. The zoom centers on the pinch gesture's focus point.

## Why this approach

Cursor-centered zoom is critical: it means zooming and panning are often a single motion. The user points at something, zooms in, and it's right there — no need to pan afterward. The button stack exists as a fallback and for discoverability (new users look for buttons before trying shortcuts).

## Behavior

- **Zoom clamp at extremes:** If the user is already at 10% zoom and tries to zoom out, nothing happens. Same at 2000% zooming in. The buttons and shortcuts are simply ignored — no error, no flash.
- **Zoom while editing text:** Zoom controls work even while the text editor is open. The user might want to zoom in to read small text as they type.
- **Reset after extreme zoom:** The reset button (and Ctrl+0) is the safety net — one action gets the user back to a known state regardless of how far they've zoomed or panned.

---

Parent feature: [Navigating the Canvas](README.md)