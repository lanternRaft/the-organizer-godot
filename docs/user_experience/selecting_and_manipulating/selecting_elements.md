# Selecting Elements

Every interaction starts with selection. The user picks what they want to act on. Selection determines which elements are affected by moves, resizes, deletions, and color changes.

## How it works

### Single click (no modifier)

Clicking an element selects it and deselects everything else. The clicked element becomes the **primary selection** — it gets the strongest visual highlight (a brightened stroke). Selected elements show resize handles (only shapes) and a bright connecting line (arrows).

Arrows are selected by clicking on their curved body. Arrow endpoints are not valid selection targets — they coincide with anchor dots, and anchors always have priority over arrows at those positions.

Clicking empty canvas deselects everything.

### Shift+click (additive)

Holding Shift while clicking adds the element to the current selection set, or removes it if it's already selected. This lets the user curate a custom set — maybe three shapes and two nodes in a cluster that should all move together.

Shift+click never clears the existing selection. It's strictly additive or subtractive.

### Ctrl+A / cmd+A

Selects every shape, node, and arrow on the canvas. The last element added becomes the primary selection.

### Why primary vs secondary

In a multi-select set, some actions only apply to the primary element (resizing, text editing, the selection menu). The distinction lets the user work on one thing without losing the multi-drag capability of the whole set.

## Behavior

- **Clicking an element that's already selected:** Unless the user holds Shift, clicking a selected element doesn't deselect it — it keeps it selected and makes it the primary selection. This feels natural: the user might click the same shape again just to bring the selection menu into view.
- **Shift+click on an already-selected primary:** Removes it from the set. The next-most-recently-clicked element becomes the new primary.
- **Selecting an arrow:** Clicking the curved body of an arrow selects it. Clicking near an arrow's endpoint (where it meets an anchor dot) is treated as a click on the anchor, not on the arrow — the anchor has priority. This ensures the user always starts an arrow drag when intending to.
- **Empty selection:** When nothing is selected, the info bar shows a neutral hint and the selection menu is hidden. The canvas is quiet — ready for the user's next action.

---

Parent feature: [Selecting and Manipulating](README.md)