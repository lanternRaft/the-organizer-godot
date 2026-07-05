# Shared Element Base

## What This Document Covers

`LabelShape` (ovals and circles with text) and `CanvasNode` (small fixed‑size circle/triangle markers) share a common set of behaviors inherited from a single base class. This document describes those shared behaviors — what works identically for both element types and what each subclass customizes.

---

## Design Principle

Every draggable, anchor‑capable element on the canvas behaves consistently. Whether the user selects a large oval or a tiny triangle node, the mechanics of clicking, dragging, snapping, and connecting arrows are the same. The base class owns that consistency; subclasses only add what makes them visually or functionally distinct.

---

## Behaviors Inherited From the Base Class

The following behaviors are **identical** for both shapes and nodes and are implemented in the shared base.

### Selection Lifecycle

| Aspect | Behavior |
|---|---|
| **Single click (no modifier)** | Selects the element, deselects everything else. The clicked element becomes the **primary selection** with a strong visual highlight. |
| **Shift+click (additive)** | Adds the element to the current selection set, or removes it if already selected. Never clears the existing selection. |
| **Ctrl+A / Cmd+A** | Selects every element (shapes, nodes, arrows) on the canvas. The last element added becomes the primary. |
| **Primary vs secondary** | The primary element (most recently clicked in the set) gets the strongest highlight. Secondary elements have a subordinate highlight. Some actions (resize, text editing, selection menu) only apply to the primary. |
| **Clicking a selected element** | Unless Shift is held, clicking an already‑selected element keeps it selected and promotes it to primary. |
| **Shift+click on primary** | Removes it from the set. The next‑most‑recently‑clicked element becomes the new primary. |
| **Empty selection** | Info bar shows a neutral hint; selection menu is hidden. |
| **Selection while text overlay is open** | Selection menu hides while the text editor is active (applies only to LabelShape, which supports text). |

### Drag and Multi‑Drag

| Aspect | Behavior |
|---|---|
| **Single drag** | Clicking and dragging a shape or node moves it freely across the canvas. The element follows the cursor with no lag. |
| **Multi‑drag** | When multiple elements are selected, dragging any one of them moves the entire set by the same pixel delta. All elements maintain their relative positions. |
| **What moves** | All selected shapes and nodes move by the same delta. Arrows connected to moving elements automatically stretch and curve to follow their endpoints. Free‑floating arrows selected as part of the set also move by the same delta. |
| **Resize in multi‑select** | Only the primary element can be resized (if it supports resize). The base class enforces that only elements with resize capability show handles. Nodes — which do not support resize — never show handles even if primary. |

### Grid Snap

| Aspect | Behavior |
|---|---|
| **Movement snap** | On release after a drag, every moved element snaps to a 20px‑increment grid. The snap applies on release, not during the drag, so movement feels fluid. |
| **Resize snap** | On release after a resize, dimensions snap to a 10px‑increment grid (applies only to elements that support resize). |
| **Multi‑select snap** | When multiple elements are moved and released, every element in the set snaps independently to the 20px grid, keeping the group internally consistent. |
| **Consistency across types** | The same snap radius and grid alignment logic is used for both shapes and nodes — no accidental differences. |

### Anchor Points

| Aspect | Behavior |
|---|---|
| **Purpose** | Anchor dots serve as connection points for arrows. Every element derived from the base class can be a source and/or target of arrows. |
| **Configurable count/positions** | The number of anchors and their positions are **not** hardcoded to 4 cardinal points. The base class accepts a list of positions (in element‑local coordinates) that each subclass provides. |
| **Cardinal anchors (4)** | Used by LabelShape (oval/circle) and CircleNode — top, bottom, left, right. |
| **Vertex anchors (3)** | Used by TriangleNode — top, bottom‑left, bottom‑right. |
| **Visibility** | Anchor dots appear when the cursor is near an element. They fade into awareness rather than cluttering the canvas constantly. |
| **Hover state** | When the cursor is directly over an anchor dot, it grows larger and turns blue — ready to grab. |
| **Snap radius** | During arrow creation, the cursor snaps to valid anchors within a forgiving radius. The snap radius is identical for all element types. |
| **Preventing self‑connection** | Dragging from an anchor back to the same element does not create an arrow. This logic lives in the base class and applies universally. |

### Deletion

| Aspect | Behavior |
|---|---|
| **Trigger** | Delete / Backspace key removes all currently selected elements. The selection menu's Delete button (visible when exactly one element is selected) does the same. |
| **Arrow cascade** | When any base‑class element is deleted, all arrows connected to it are also removed. No orphan lines are left on the canvas. |
| **Post‑deletion selection** | If the deleted element was the primary, and other selected elements remain, the next element in the set becomes the new primary. If nothing remains, the selection clears. |
| **Safety** | Deletion is immediate and permanent (undo is planned for a future release). The auto‑save system records the deletion as the new canvas state. |

### Multi‑Select Participation

- Shapes and nodes can be selected together in any combination.
- Multi‑drag moves both types uniformly.
- Resize only applies to a shape if it is the primary selection; nodes never show resize handles regardless of selection state.
- Text editing is never triggered on nodes (see subclass‑specific overrides below).

---

## Behaviors Overridden by Subclasses

The base class provides virtual hooks that subclasses use to customize behavior while retaining the shared infrastructure.

| Behavior | LabelShape (Oval / Circle) | CanvasNode (Circle / Triangle) |
|---|---|---|
| **Resize handles** | Shows 4 corner handles when selected (or a single radius handle in Circle mode). Supports 10px snap. Min 20px, max 500px. | **None.** Nodes are fixed‑size. The base class suppresses handle display and resize logic for this subclass. |
| **Text editing** | Double‑click or Enter opens a text overlay. Font scales between 8px and 20px to fit the shape. | **None.** Nodes have no text overlay. The base class virtual method for text activation returns a no‑op for CanvasNode. |
| **Legend appearance** | Appears in the legend panel under the color name. | **Excluded.** Nodes do not appear in the legend. The base class allows opt‑in/out; CanvasNode opts out. |
| **Anchor count / positions** | 4 anchors at cardinal points (top, bottom, left, right). | CircleNode: 4 cardinal anchors. TriangleNode: 3 vertex anchors (top, bottom‑left, bottom‑right). |
| **Circle‑mode constraint** | In Circle mode, both dimensions grow equally preserving aspect ratio. | N/A — nodes are fixed size and not resizable. |

---

## Axes That Are Unified vs. Specialized

| Axis | Unified (base class) | Specialized (subclass) |
|---|---|---|
| **Selection** | Click, Shift+click, Ctrl+A, primary/secondary distinction, visual highlight ordering | — |
| **Drag** | Single drag, multi‑drag, arrow follow | — |
| **Grid snap** | 20px movement snap on release | Resize snap (10px) only for shapes |
| **Anchor generation** | Configurable list of positions, visibility, hover states, snap radius | Each subclass provides its own list (4 cardinal vs. 3 vertex) |
| **Deletion** | Delete key, arrow cascade, post‑deletion primary selection | — |
| **Resize** | — | Handles, constraints, circle‑mode (LabelShape only) |
| **Text** | — | Overlay, font scaling, commit/cancel (LabelShape only) |
| **Legend** | — | Appears (LabelShape) vs. excluded (CanvasNode) |

---

## Edge Cases Handled by the Base Class

- **Mixed selection of shapes and nodes:** Multi‑drag moves both types uniformly. Resize only applies to a shape primary; nodes never show handles.
- **Arrow across types:** Arrows can connect any combination of shape and node anchors (shape→node, node→shape, node→node) using the same base‑class anchor infrastructure.
- **Deletion cascade across types:** Deleting a shape removes its connected arrows; deleting a node removes its connected arrows. The cascade logic is identical.
- **Anchor snap radius consistency:** The snap radius for arrow creation is defined once in the base class, so shapes and nodes always behave identically when the user is aiming for an anchor.