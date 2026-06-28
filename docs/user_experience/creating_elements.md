# Creating Elements

**Audience:** Designers + developers | **Scope:** Player-facing interactions for placing shapes, nodes, and arrows

## Overview

The user populates the canvas with three kinds of things: **shapes** (ovals and circles that hold text), **arrows** (curved connectors between shapes), and **nodes** (small fixed-size circle and triangle markers). Each element is placed using a distinct interaction.

---

## Tools

A toolbar sits at the bottom center of the screen. It's always visible and shows which tool is active. The active tool changes what happens when the user clicks or drags on the canvas.

There are three tool categories:

- **Select tool** — the default. Click to pick things up, drag to move them. This is the mode users come back to between every other action.
- **Shape tool** — click the canvas to drop a new shape. A dropdown on this button lets the user choose between Oval and Circle before placing.
- **Node tool** — click the canvas to drop a small fixed-size marker. A dropdown on this button lets the user choose between Circle Node and Triangle Node before placing.

The user is never stuck in a tool they don't want. Every shape placement automatically returns them to Select mode. If they accidentally enter a tool, Escape gets them out.

### How tool switching feels

Buttons in the toolbar are toggle-style — when Select is active, the Select button looks pressed in. Switching to a shape tool or node tool pops the Select button back up. There's a quiet, mechanical finality to it: tools snap into place.

The info bar at the bottom of the screen shows a brief hint for the current tool, so the user always knows what will happen if they click. In Select mode it says "Click to select an oval"; in Shape mode it says "Click the canvas to place a (oval/circle)"; in Node mode it says "Click the canvas to place a (circle/triangle) node".

---

## Placing Shapes

### How it works

1. The user clicks the **Oval** or **Circle** button in the toolbar
2. The cursor changes to a crosshair — the canvas is waiting
3. The info bar reads "Click the canvas to place a (oval/circle)"
4. The user clicks anywhere on the canvas
5. A shape appears at that exact spot, already selected, with resize handles visible
6. The tool automatically switches back to Select mode

### How it feels

Placing a shape should feel as simple as dropping a pin on a map. The user points, clicks, and the shape is there — no configuration dialog, no sizing step, no dragging. The shape arrives at a reasonable default size with a friendly blue color. Fine-tuning (resize, color, text) comes after placement.

One click, and the canvas has something new on it. The user is immediately in control — they can drag it somewhere else, resize it, color it, or leave it and place another one.

### The shape sub-mode dropdown

The Shape button in the toolbar has a small triangle next to it (or in some designs, clicking it opens a menu). This reveals two options: Oval and Circle.

- **Oval** places a horizontally-oriented ellipse (80px wide, 50px tall). Good for labels, names, short descriptions.
- **Circle** places a round shape (80px in both dimensions). Good for emphasis, categorical markers, or nodes in a flow.

When the user switches from Oval to Circle, any shape they place from that point on is a circle. The toolbar button text updates to show the current sub-mode so there's no ambiguity about what will appear.

### Edge cases

- **Placing on top of existing shapes:** New shapes can overlap existing shapes if placed on top of them. The user can freely position shapes anywhere on the canvas, including on top of other elements.
- **Rapid placement:** The user can click multiple times quickly to drop several shapes in sequence — but only if they re-enter Shape mode each time. Each placement returns to Select mode, which is a deliberate trade-off: it prevents accidental mass placement while letting the user build up a canvas quickly through repetition.
- **Tool deactivation:** Pressing Escape while in shape mode deactivates the tool without placing anything. The user returns to Select mode with a clean slate.

---

## Creating Arrows

Arrows connect shapes to each other. They represent relationships — dependencies, influences, flows, hierarchies.

### How it works

Arrows are created by dragging from one shape's anchor point to another, all within Select mode:

1. The user is in Select mode with at least one shape on the canvas
2. As the user moves the cursor near a shape (within a comfortable proximity), four small anchor dots appear at the shape's cardinal points: top, bottom, left, right
3. Moving the cursor directly over an anchor dot makes it grow larger and turn blue — it's ready to grab
4. The user clicks and holds on that anchor dot, then drags toward another shape
5. A dashed preview line stretches from the start anchor to the cursor, showing the path the arrow will take
6. As the cursor nears another shape's anchor (within a forgiving snap radius), the nearest anchor highlights — a valid landing zone
7. Releasing the mouse over a highlighted anchor creates the arrow: a curved line from start anchor to end anchor, with an arrowhead at the end
8. Releasing anywhere else (empty space, back on the starting shape) cancels the creation — nothing happens

### How it feels

Arrow creation should feel like connecting two points with invisible string. The user reaches out from one shape, the anchor dots appear automatically when they're near — no button toggling, no mode switching. The preview line shows what the connection will look like, so there's no guesswork.

The snap radius is generous: the arrow doesn't need to land exactly on the anchor, just close to it. This makes quick connections between densely-packed shapes easy — the user can build up an entire diagram without precise aiming.

### Why drag-from-anchor instead of click-drag-release on the canvas

The anchor-based approach makes the relationship explicit: arrows connect things, they don't float in space. By starting from an anchor and requiring a second anchor as the destination, every arrow is guaranteed to have two connected endpoints. This prevents orphan arrows and keeps the diagram meaningful.

### The preview line

During the drag, a dashed line shows the arrow-to-be. The line curves naturally from the start anchor outward, following the cursor. If the cursor snaps to a valid anchor, the preview line adjusts to show the final curved path. The preview helps the user know exactly what they're creating before they commit.

### Anchor dots

Each shape has four anchors at its cardinal points. The dots sit just outside the shape's edge — a small buffer so they're visually distinct from the shape itself.

- **Default state:** Small white dots with a blue border
- **Hover state (nearby):** Dots become visible only when the cursor is near the shape. They fade into awareness rather than cluttering the canvas constantly
- **Active state (grabbing):** The dot being dragged from stays highlighted
- **Snap target (valid landing):** The nearest anchor under the cursor during a drag grows larger and turns solid blue

### Why four anchors

Four cardinal points (top, bottom, left, right) cover the most common connection directions without overwhelming the user with choices. More anchors would create visual noise; fewer would force awkward arrow paths. Four is the sweet spot for diagrams, flowcharts, and relationship maps.

### Edge cases

- **Connecting a shape to itself:** The system prevents this. If the user drags from a shape back to the same shape, the preview shows the connection won't land (no snap highlight), and releasing cancels the arrow. This enforces meaningful connections.
- **Dragging over existing arrows:** The preview line renders above other elements so the user always sees what they're creating. Existing arrows are ignored during the drag — they're not valid targets.
- **Accidental release on empty space:** Nothing happens. The user can continue dragging, or release and try again. No penalty for a missed connection.
- **Arrow starts from any anchor, ends at any anchor:** The user can connect top-to-bottom, left-to-right, or any combination. The arrow path adjusts automatically.
- **If a connected shape moves or is deleted:** Arrows attached to that shape update their path to follow (or are destroyed if the shape is gone).

---

## Placing Nodes

Nodes are small fixed-size markers — useful for labeling connection points, representing entities in a network, or highlighting specific locations without the visual weight of a full shape.

### How it works

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
- **Arrow connections** — each node has its own set of anchor points for creating arrows
  - **Circle Node anchors:** 4 cardinal points (top, bottom, left, right) — identical to shapes
  - **Triangle Node anchors:** 3 vertex points (top, bottom-left, bottom-right)
- **Selection and dragging** — nodes can be clicked, shift+clicked, and dragged like shapes (20px snap)

### What nodes don't support

- **Resize handles** — nodes are fixed-size; no resize interaction appears on selection
- **Text editing** — nodes have no text overlay; they're purely visual markers
- **Appearing in the legend** — nodes are not included in the legend panel (they are decoration, not categories)

### How it feels

Placing a node should feel even lighter than placing a shape — a quick tap to leave a small visual marker. Where a shape says "this is a labeled thing," a node says "this spot matters." The small size makes them suitable for dense, detailed diagrams where full shapes would be too heavy.

### Edge cases

- **Placing on top of existing elements:** Nodes can overlap shapes and other nodes if placed on top of them.
- **Rapid placement:** Each placement returns to Select mode (same trade-off as shapes). The user can click, return to Node mode, click again — no mass-placement risk.
- **Tool deactivation:** Escape exits Node mode without placing, returning to Select.
- **Arrow connections from/to nodes:** Arrows can originate from a node's anchor and land on a shape's anchor (or vice versa). Nodes can connect to other nodes. The same anchor-based drag interaction applies.
- **Deleting a node with connected arrows:** Arrows attached to the node are destroyed when the node is removed (consistent with shape deletion).
- **Copy/paste:** Nodes can be copied and pasted following the same rules as shapes (paste offset, same-layer placement).

---

## Transitioning Between Modes

The flow between creation and manipulation should feel seamless:

1. User places a shape → auto-selects it → is ready to move/resize/color/text
2. User creates an arrow → stays in Select mode → arrow is now part of the diagram
3. User finishes editing a shape's text → Enter commits → back to Select mode with the shape still selected
4. User places a node → auto-selects it → is ready to move/color/connect

The auto-return to Select is a deliberate choice: creation is a single action, but manipulation (moving, resizing, connecting) is where the user spends most of their time. Defaulting to Select mode means they never have to switch tools just to pick up what they just put down.