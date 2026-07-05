# Selecting Elements

Every interaction starts with selection. The user picks what they want to act on. Selection determines which elements are affected by moves, resizes, deletions, and color changes.

## How it works

### Single click (no modifier)

Clicking an element selects it and deselects everything else. The clicked element becomes the **primary selection** — it gets the strongest visual highlight (a brightened stroke). Selected elements show resize handles (only shapes) and a bright connecting line (arrows).

Clicking empty canvas deselects everything.

### Shift+click (additive)

Holding Shift while clicking adds the element to the current selection set, or removes it if it's already selected. This lets the user curate a custom set — maybe three shapes and two nodes in a cluster that should all move together.

Shift+click never clears the existing selection. It's strictly additive or subtractive.

### Ctrl+A / Cmd+A

Selects every shape, node, and arrow on the canvas. The last element added becomes the primary selection.

### Why primary vs secondary

In a multi-select set, some actions only apply to the primary element (resizing, text editing, the selection menu). The distinction lets the user work on one thing without losing the multi-drag capability of the whole set.

## How it feels

Selection should feel crisp and unambiguous. The visual feedback is immediate: a selected element's stroke brightens and thickens the moment it's clicked. Handles appear (only for shapes), the info bar updates, and if it's the only selection a floating menu appears below it with actions.

The difference between primary and secondary selection is subtle but noticeable. The primary selection has the most prominent highlight because that's where the user's attention is — it's the thing they just clicked. The secondary elements are visibly part of the set but clearly subordinate.

## Edge cases

- **Clicking an element that's already selected:** Unless the user holds Shift, clicking a selected element doesn't deselect it — it keeps it selected and makes it the primary selection. This feels natural: the user might click the same shape again just to bring the selection menu into view.
- **Shift+click on an already-selected primary:** Removes it from the set. The next-most-recently-clicked element becomes the new primary.
- **Empty selection:** When nothing is selected, the info bar shows a neutral hint and the selection menu is hidden. The canvas is quiet — ready for the user's next action.

---

Parent feature: [Selecting and Manipulating](README.md)