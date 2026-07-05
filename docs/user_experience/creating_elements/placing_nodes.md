# Placing Nodes

Nodes are small fixed-size markers — useful for labeling connection points, representing entities in a network, or highlighting specific locations without the visual weight of a full shape. They are purely visual markers and do not support text editing or resizing.

## How it works

1. The user clicks the **Node** button in the toolbar
2. A dropdown reveals two options: **Circle Node** and **Triangle Node**
3. The user selects one — the toolbar button text updates to show the current sub-mode
4. The cursor changes to a crosshair — the canvas is waiting
5. The info bar reads "Click the canvas to place a (circle/triangle) node"
6. The user clicks anywhere on the canvas
7. A node appears at that exact spot, already selected
8. The tool automatically switches back to Select mode

### Node sizes and appearance

- **Circle Node:** 16px diameter (8px radius). Drawn as a filled circle.
- **Triangle Node:** Pointing upward, ~16px inscribed in a bounding circle. Drawn as a filled equilateral triangle.

Both default to the same friendly blue fill color as shapes, configurable via the selection menu color palette.

### What nodes support

- **Color changes** — same palette and flow as shapes (via selection menu)
- **Arrow connections** — each node has its own set of anchor points for creating arrows, following the same pattern as shapes
  - **Circle Node anchors:** 4 cardinal points (top, bottom, left, right) — identical to shapes
  - **Triangle Node anchors:** 3 vertex points (top, bottom-left, bottom-right)
- **Selection and dragging** — nodes can be clicked, shift+clicked, and dragged like shapes (20px snap)

### What nodes don't support

- **Resize handles** — nodes are fixed-size; no resize interaction appears on selection
- **Text editing** — nodes have no text overlay; they're purely visual markers
- **Appearing in the legend** — nodes are not included in the legend panel (they are decoration, not categories)

## How it feels

Placing a node should feel even lighter than placing a shape — a quick tap to leave a small visual marker. Where a shape says "this is a labeled thing," a node says "this spot matters." The small size makes them suitable for dense, detailed diagrams where full shapes would be too heavy.

## Edge cases

- **Placing on top of existing elements:** Nodes can overlap shapes and other nodes if placed on top of them.
- **Rapid placement:** Each placement returns to Select mode (same trade-off as shapes). The user can click, return to Node mode, click again — no mass-placement risk.
- **Tool deactivation:** Escape exits Node mode without placing, returning to Select.
- **Arrow connections from/to nodes:** Arrows can originate from a node's anchor and land on a shape's anchor (or vice versa). Nodes can connect to other nodes. The same anchor-based drag interaction applies.
- **Deleting a node with connected arrows:** Arrows attached to the node are destroyed when the node is removed (consistent with shape deletion).
- **Copy/paste:** Nodes can be copied and pasted following the same rules as shapes (paste offset, same-layer placement).

---

Parent feature: [Creating Elements](README.md)