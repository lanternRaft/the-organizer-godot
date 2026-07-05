# Creating Arrows

Arrows connect elements to each other. They represent relationships — dependencies, influences, flows, hierarchies. Shapes and nodes both work the same way — arrows can connect any combination of element types.

## How it works

Arrows are created by dragging from one element's anchor point to another, all within Select mode:

1. The user is in Select mode with at least one shape or node on the canvas
2. As the user moves the cursor near an element (within a comfortable proximity), small anchor dots appear at the element's anchor positions
3. Moving the cursor directly over an anchor dot makes it grow larger and turn blue — it's ready to grab
4. The user clicks and holds on that anchor dot, then drags toward another element
5. A dashed preview line stretches from the start anchor to the cursor, showing the path the arrow will take
6. As the cursor nears another element's anchor (within a forgiving snap radius), the nearest anchor highlights — a valid landing zone
7. Releasing the mouse over a highlighted anchor creates the arrow: a curved line from start anchor to end anchor, with an arrowhead at the end
8. Releasing anywhere else (empty space, back on the starting element) cancels the creation — nothing happens

### The preview line

During the drag, a dashed line shows the arrow-to-be. The line curves naturally from the start anchor outward, following the cursor. If the cursor snaps to a valid anchor, the preview line adjusts to show the final curved path. The preview helps the user know exactly what they're creating before they commit.

### Anchor dots

Each element has anchors at specific positions depending on its type — 4 cardinal points for shapes and circle nodes, 3 vertex points for triangle nodes. The dots sit just outside the element's edge — a small buffer so they're visually distinct from the element itself.

- **Default state:** Small white dots with a blue border
- **Hover state (nearby):** Dots become visible only when the cursor is near the element. They fade into awareness rather than cluttering the canvas constantly
- **Active state (grabbing):** The dot being dragged from stays highlighted
- **Snap target (valid landing):** The nearest anchor under the cursor during a drag grows larger and turns solid blue

### Why per-element anchor counts

- **4 cardinal points (top, bottom, left, right):** Used by shapes (oval/circle) and circle nodes. Four directions cover the most common connection paths without overwhelming the user.
- **3 vertex points (top, bottom-left, bottom-right):** Used by triangle nodes. The vertices provide natural attachment points that follow the triangle's geometry.

## Why this approach

The anchor-based approach makes the relationship explicit: arrows connect things, they don't float in space. By starting from an anchor and requiring a second anchor as the destination, every arrow is guaranteed to have two connected endpoints. This prevents orphan arrows and keeps the diagram meaningful.

The drag-from-anchor method (rather than click-drag-release on the canvas) ensures arrows are never floating in space. Every arrow has two connected endpoints, keeping the diagram meaningful.

## How it feels

Arrow creation should feel like connecting two points with invisible string. The user reaches out from one element, the anchor dots appear automatically when they're near — no button toggling, no mode switching. The preview line shows what the connection will look like, so there's no guesswork.

The snap radius is generous: the arrow doesn't need to land exactly on the anchor, just close to it. This makes quick connections between densely-packed elements easy — the user can build up an entire diagram without precise aiming.

## Edge cases

- **Connecting an element to itself:** The system prevents this. If the user drags from an anchor back to the same element, the preview shows the connection won't land (no snap highlight), and releasing cancels the arrow. This enforces meaningful connections.
- **Cross-type connections:** Arrows can connect shape→node, node→shape, node→node, or shape→shape. The same anchor-based drag interaction applies regardless of type.
- **Dragging over existing arrows:** The preview line renders above other elements so the user always sees what they're creating. Existing arrows are ignored during the drag — they're not valid targets.
- **Accidental release on empty space:** Nothing happens. The user can continue dragging, or release and try again. No penalty for a missed connection.
- **Arrow starts from any anchor, ends at any anchor:** The user can connect top-to-bottom, left-to-right, or any combination. The arrow path adjusts automatically.
- **If a connected element moves or is deleted:** Arrows attached to that element update their path to follow (or are destroyed if the element is gone).

---

Parent feature: [Creating Elements](README.md)