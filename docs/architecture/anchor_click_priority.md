# Anchor Click Priority

## Overview

This document consolidates the changes across **ClickHandler** and **ArrowManager** that ensure clicking and dragging on an anchor dot always initiates a new arrow creation, never selects an existing arrow whose endpoint occupies the same screen position. The change reorders detection priority and introduces a drag threshold delay to prevent accidental arrow creation.

## Problem

When an anchor dot and an arrow endpoint share the same screen position (which is common since arrow endpoints are placed at anchors), a user clicking near that position could select the existing arrow instead of initiating a new arrow drag from the anchor dot. This ambiguous click priority was resolved by making anchor dots take precedence.

## Design Decisions

### Decision 1: Reorder detection, do not modify hit areas

**Choice**: Reverse the order of secondary hit tests in ClickHandler so anchor dot detection runs **before** arrow body detection.

**Rationale**: Changing the order of secondary hit tests is a minimal, localized change that enforces priority without altering arrow endpoint collision logic or selection behavior. Arrow endpoints remain in the bezier point cache used for hit testing — they are simply deprioritized by detection order. This avoids unintended side effects on arrow body selection.

### Decision 2: Drag threshold delay for arrow initiation

**Choice**: Arrow drag does not begin immediately on anchor dot mousedown. Instead, a pending state is registered, and drag activates only after the pointer moves past a 5px threshold.

**Rationale**: This reuses the existing drag threshold pattern (`DRAG_THRESHOLD` = 5px) already present in the system for element dragging. It prevents accidental arrow creation on simple clicks while maintaining consistent input behavior. The same threshold value is used for both element drags and arrow drags.

### Decision 3: Keep arrow endpoint hit areas unchanged

**Choice**: Arrow hit testing (`get_arrow_near`) continues to include endpoints. Priority from reordered detection ensures endpoints are never selected when an anchor dot is present at the same position.

**Rationale**: Simplifies the change and keeps arrow selection via its body unchanged. Only detection order enforces priority.

## Affected Systems

### ClickHandler

- **Secondary hit detection order**: Reversed from (arrow → anchor dot) to (anchor dot → arrow).
- **Pointer motion routing**: On pointer motion events, ClickHandler notifies ArrowManager via `handle_dot_mousemove(world_pos)` when a pending anchor dot drag exists.

### ArrowManager

- **Two-phase arrow drag initiation**:
  - **Phase 1 — Registration** (`handle_dot_mousedown`): Records the anchor target but does not create a preview line or enter drag state. A new pending state flag and variables track the potential drag.
  - **Phase 2 — Activation** (`handle_dot_mousemove` after threshold): When pointer motion exceeds `ARROW_DRAG_THRESHOLD` (5px), ArrowManager begins the drag, creates the preview line, and enters the drag state.
- **New constant**: `ARROW_DRAG_THRESHOLD = 5.0`.

## Data Flow

```
1. Pointer down on empty canvas
   → ClickHandler physics query finds no Area2D
   → Secondary hit detection: anchor dot check FIRST
     → ArrowManager.handle_dot_mousedown(world_pos)
       → If over anchor dot (within hover radius):
         → Register pending drag (element, label, origin)
         → Return true (hit handled)
       → Else: return false
   → If anchor dot NOT hit: arrow hit detection SECOND
     → ArrowManager.get_arrow_near(world_pos)
       → If arrow found: select it
       → Else: emit empty_canvas_clicked

2. Pointer motion while held
   → ClickHandler._unhandled_input receives InputEventMouseMotion
   → If pending anchor drag exists:
     → ClickHandler calls ArrowManager.handle_dot_mousemove(world_pos)
       → If distance from origin >= ARROW_DRAG_THRESHOLD (5px):
         → begin_arrow_drag(pending_element, pending_label)
         → Start preview line, enter drag state
       → Else: ignore (below threshold)
   → Else: normal drag processing for selected elements

3. Pointer release
   → ClickHandler emits pointer_up(world_pos)
   → ArrowManager.handle_dot_mouseup()
     → If pending drag exists (never activated):
       → Clear pending state, no arrow created
     → If drag is active:
       → end_arrow_drag()
         → If snapped to valid target: create arrow
         → Else: discard
     → Reset all drag state
```

## Key Interactions

- **Anchor dot hover vs. drag**: Dot hover detection (showing anchor dots on mouse proximity) continues to use `ANCHOR_HOVER_RADIUS` (20px) and is unaffected. Only the drag initiation is delayed.
- **Arrow selection via body click**: The curved bezier path hit test in `get_arrow_near()` is unchanged. Clicking on an arrow body (away from anchor dots) still selects the arrow.
- **Arrow endpoint clickability**: Arrow endpoints remain selectable via `get_arrow_near()`, but only when no anchor dot occupies the same screen position. Since anchor dots are only visible on hover (for the nearest element) or during a drag, in practice arrow endpoints on non-hovered elements remain selectable.

## Files Changed

| File | Change |
|------|--------|
| `docs/architecture/input_handling.md` | Documented reordered secondary hit detection (anchor dot before arrow). Added drag threshold delay for arrow initiation. Noted arrow endpoints remain in hit testing but are deprioritized by detection order. |
| `docs/architecture/arrow_system.md` | Documented two-phase arrow drag initiation (pending → activation). Added `ARROW_DRAG_THRESHOLD` constant. Clarified anchor dot hover detection still uses same radius. |
| `docs/architecture/anchor_click_priority.md` | New summary document consolidating changes across systems. |

## Out of Scope

- Visual changes to anchor dots, arrows, or any UI elements.
- Changes to arrow rendering (bezier path, arrowhead, line width).
- Changes to arrow selection via body click.
- Modifier key behaviors (Shift, Ctrl) for anchor clicks.
- Changes to element selection (LabelShape, CanvasNode) or handle interactions.
- Arrow serialization or persistence.
