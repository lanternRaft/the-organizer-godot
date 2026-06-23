# Selecting and Manipulating

**Audience:** Designers + developers | **Scope:** Player-facing interactions for selection, drag, resize, bumping, and deletion

## Overview

World building on the canvas is an iterative process. The user moves things around, changes their size, repositions clusters, and removes things that don't fit. This document describes how the user grabs, adjusts, and cleans up their elements.

---

## Selecting Elements

Every interaction starts with selection. The user picks what they want to act on.

### Single click (no modifier)

Clicking an element selects it and deselects everything else. The clicked element becomes the **primary selection** — it gets the strongest visual highlight (a brightened stroke). Selected elements show resize handles (shapes) and a bright connecting line (arrows).

Clicking empty canvas deselects everything.

### Shift+click (additive)

Holding Shift while clicking adds the element to the current selection set, or removes it if it's already selected. This lets the user curate a custom set — maybe three shapes in a cluster that should all move together.

Shift+click never clears the existing selection. It's strictly additive or subtractive.

### Ctrl+A / Cmd+A

Selects every shape and arrow on the canvas. The last element added becomes the primary selection.

### How selection feels

Selection should feel crisp and unambiguous. The visual feedback is immediate: a shape's stroke brightens and thickens the moment it's selected. The handles appear, the info bar updates, and if it's the only selection a floating menu appears below it with actions.

The difference between primary and secondary selection is subtle but noticeable. The primary selection has the most prominent highlight because that's where the user's attention is — it's the thing they just clicked. The secondary elements are visibly part of the set but clearly subordinate.

### Why primary vs secondary

In a multi-select set, some actions only apply to the primary element (resizing, text editing, the selection menu). The distinction lets the user work on one thing without losing the multi-drag capability of the whole set.

### Edge cases

- **Clicking an element that's already selected:** Unless the user holds Shift, clicking a selected element doesn't deselect it — it keeps it selected and makes it the primary selection. This feels natural: the user might click the same shape again just to bring the selection menu into view.
- **Shift+click on an already-selected primary:** Removes it from the set. The next-most-recently-clicked element becomes the new primary.
- **Empty selection:** When nothing is selected, the info bar shows a neutral hint and the selection menu is hidden. The canvas is quiet — ready for the user's next action.
- **Selection while a text overlay is open:** The selection menu hides while the text editor is active. This prevents the menu from overlapping with the editing interface.

---

## Moving Elements

### Single drag

Clicking and dragging a shape moves it freely across the canvas. The shape follows the cursor with no lag.

When the user releases, the shape snaps to a coarse grid (20px increments). The snap is subtle — it may not even be visible at normal zoom, but it helps keep things aligned when building structured diagrams. The snap only applies on release, not during the drag, so the movement feels fluid.

### Multi-drag

When multiple elements are selected, dragging any one of them moves the entire set by the same amount. They all slide together, maintaining their relative positions.

This is the primary way to rearrange a diagram. The user selects a cluster of related shapes, drags it to a new area of the canvas, and the whole group moves in lockstep.

### How multi-drag feels

The set moves as a single unit. There's no jitter, no lag between the dragged element and the others — they all arrive at the same time. On release, every shape in the set snaps to the grid, keeping the group internally consistent.

### What moves in a multi-drag

- All selected shapes move by the same pixel delta
- Arrows connected to moving shapes automatically stretch and curve to follow their endpoints
- Free-floating arrows (arrows selected as part of the set, without their endpoint shapes) also move by the same delta

### Edge cases

- **Resizing in a multi-select set:** Only the primary (last-clicked) shape can be resized via its handles. The other selected shapes don't show handles and can't be resized in this mode. This prevents accidentally warping multiple shapes when trying to adjust just one.
- **Arrows that connect two selected shapes:** The arrow updates its path as both of its endpoints move. It stretches, bends, and stays connected throughout the drag.

---

## Resizing Shapes

Every shape has four resize handles — small squares at the top-left, top-right, bottom-left, and bottom-right corners of the shape's bounding box. The handles only appear when the shape is selected.

### How it works

Dragging a handle resizes the shape. The handle the user grabs determines which corner moves:

- **Bottom-right handle:** Drag down-right to make the shape bigger, up-left to make it smaller
- **Each handle follows its corner:** The opposite corner stays fixed

The resize snaps to 10px increments. This is a tighter grid than the movement snap (20px), because resize adjustments are often finer-grained than position adjustments.

### Circle mode constraint

When a shape is in Circle mode, both dimensions grow together. Dragging any handle changes the radius equally in all directions. The shape remains a perfect circle at every size.

### Size limits

Shapes can't be smaller than 20px in either dimension, or larger than 500px. At minimum size, a shape is just large enough to see and click. At maximum size, it can fill a good portion of the viewport — useful for a central concept that everything connects to.

### How resize feels

Resizing should feel like stretching a rubber band. The shape expands or contracts immediately under the cursor. The 10px snap provides gentle guidance toward round numbers without fighting the user's intent.

### Edge cases

- **Resize past minimum/maximum:** The shape stops at the limit. The handle keeps following the cursor, but the shape doesn't shrink or grow beyond the bounds. There's no pushback or stuttering — it simply stops.
- **Resize while text is inside:** The text reflows to fit the new dimensions. If the shape gets smaller, the text font size scales down (down to a minimum of 8px). If the shape gets bigger, the text scales up to match (up to 20px max).
- **Resizing doesn't trigger bumping:** Unlike dragging, resizing doesn't push overlapping shapes out of the way. This deliberate choice prevents chaos when expanding a shape that's surrounded by other elements.
- **Cursor changes** to a resize pointer when hovering over a handle, making it clear that the user is about to resize rather than drag.

---

## Bumping (Overlap Push)

When a shape is dragged into another shape, it pushes the other shape out of the way — like two physical objects that can't occupy the same space. This makes the canvas feel alive and responsive.

### How it works

1. The user drags shape A into shape B
2. When they overlap (their collision circles touch), shape B is pushed away from shape A along the line between their centers
3. The push distance is exactly enough to separate them — no more, no less
4. If shape B was itself touching shape C, pushing B into C causes C to be pushed as well
5. This chain reaction propagates up to five steps deep, then stops

### How bumping feels

Bumping should feel physical but not violent. Pushed shapes glide away with the same smooth movement as a dragged shape. The chain reaction propagates quickly — the whole cascade resolves in a single frame, so it looks like everything settled at once rather than a domino effect in slow motion.

The effect is most noticeable with multiple shapes close together. Dragging a new shape into a dense cluster causes a gentle ripple as shapes rearrange to make room.

### When bumping happens

- **Dragging a shape** into another shape triggers bumping during the drag, as the shape moves
- **Placing a new shape** on top of existing shapes triggers bumping on placement
- **Multi-drag:** When several shapes are dragged together, they also bump into each other during the move

### When bumping does NOT happen

- **Resizing** a shape never pushes other shapes away
- **Arrows are never affected** by bumping — they're visual-only and have no collision
- **Resize handles** don't trigger bumping, even if they overlap another shape's area

### Connected arrows update automatically

When a shape gets pushed, any arrows connected to it immediately recalculate their path to follow the new position. The arrow stays attached to the right anchor and curves correctly.

### Why bumping exists

Without bumping, shapes would freely overlap, creating visual clutter and making it hard to read a diagram. Bumping keeps the canvas organized without requiring the user to manually reposition every collision. It's an invisible hand that maintains spatial order.

### Edge cases

- **Pushed into a third shape:** The chain reaction handles this. Deep chains (more than 5 hops) are limited to prevent infinite loops in tight clusters. In practice, five iterations is enough for any reasonable arrangement.
- **Simultaneous pushes:** If two shapes are both pushing the same third shape from different directions, the push vectors are accumulated and applied together. The shape moves diagonally away from both.
- **Frame-level deduplication:** If a shape gets processed by bumping once in a frame, it won't be processed again. This prevents redundant pushes when multi-drag and bumping interact.

---

## Deleting Elements

### How it works

- **Delete / Backspace key** removes all currently selected elements
- **The selection menu's Delete button** (visible when exactly one element is selected) does the same

### What gets deleted

- Selected shapes are removed, and any arrows connected to them are also removed
- Selected arrows are removed directly
- After deletion, the selection is cleared

### How deletion feels

Deletion is immediate and complete. The element vanishes, and if it was a shape with connected arrows, those arrows vanish too — no orphan lines left floating on the canvas. The user doesn't have to hunt down every arrow that pointed to a deleted shape.

### Safety

There's no undo yet (planned for future), so deletion is a permanent action. The auto-save system records the deletion as the new canvas state. The confirmation dialog for clearing the entire canvas provides a safety net for the nuclear option, but individual deletions are intentionally one-step — requiring a confirmation on every delete would be tedious.

### Edge cases

- **Delete key while typing text:** The text editor handles the delete key internally. It doesn't delete the shape. Only when the text editor is closed does the delete key revert to element deletion.
- **All elements deleted:** The canvas is now empty, and the legend panel (if implemented) disappears since no colors are in use.
- **Deleting the primary selection:** If the deleted element was the primary, and other selected elements remain, the next element in the set becomes the new primary. If nothing remains, the selection clears.