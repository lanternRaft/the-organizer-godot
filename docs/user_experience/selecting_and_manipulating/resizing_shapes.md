# Resizing Shapes

Every shape has four resize handles — small squares at the top-left, top-right, bottom-left, and bottom-right corners of the shape's bounding box. The handles only appear when the shape is selected. Resizing is how the user adjusts the visual weight and layout of their diagram.

## How it works

Dragging a handle resizes the shape. The handle the user grabs determines which corner moves:

- **Bottom-right handle:** Drag down-right to make the shape bigger, up-left to make it smaller
- **Each handle follows its corner:** The opposite corner stays fixed

The resize snaps to 10px increments. This is a tighter grid than the movement snap (20px), because resize adjustments are often finer-grained than position adjustments.

### Circle mode constraint

When a shape is in Circle mode, both dimensions grow together. Dragging any handle changes the radius equally in all directions. The shape remains a perfect circle at every size.

### Size limits

Shapes can't be smaller than 20px in either dimension, or larger than 500px. At minimum size, a shape is just large enough to see and click. At maximum size, it can fill a good portion of the viewport — useful for a central concept that everything connects to.

## How it feels

Resizing should feel like stretching a rubber band. The shape expands or contracts immediately under the cursor. The 10px snap provides gentle guidance toward round numbers without fighting the user's intent.

## Edge cases

- **Resize past minimum/maximum:** The shape stops at the limit. The handle keeps following the cursor, but the shape doesn't shrink or grow beyond the bounds. There's no pushback or stuttering — it simply stops.
- **Resize while text is inside:** The text reflows to fit the new dimensions. If the shape gets smaller, the text font size scales down (down to a minimum of 8px). If the shape gets bigger, the text scales up to match (up to 20px max).
- **Cursor changes** to a resize pointer when hovering over a handle, making it clear that the user is about to resize rather than drag.

---

Parent feature: [Selecting and Manipulating](README.md)