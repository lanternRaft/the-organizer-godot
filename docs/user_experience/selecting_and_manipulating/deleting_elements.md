# Deleting Elements

Deletion is how the user removes elements they no longer need. It's immediate and permanent — no undo is available for individual deletions.

## How it works

- **Delete / Backspace key** removes all currently selected elements
- **The selection menu's Delete button** (visible when exactly one element is selected) does the same

### What gets deleted

- Selected shapes and nodes are removed, and any arrows connected to them are also removed
- Selected arrows are removed directly
- After deletion, the selection is cleared

## How it feels

Deletion is immediate and complete. The element vanishes, and if it was a shape or node with connected arrows, those arrows vanish too — no orphan lines left floating on the canvas. The user doesn't have to hunt down every arrow that pointed to a deleted element.

## Safety

Deletion is permanent — there's no undo. The confirmation dialog for clearing the entire canvas provides a safety net for the nuclear option, but individual deletions are intentionally one-step — requiring a confirmation on every delete would be tedious.

## Edge cases

- **Delete key while typing text:** The text editor handles the delete key internally. It doesn't delete the shape. Only when the text editor is closed does the delete key revert to element deletion.
- **All elements deleted:** The canvas is now empty, and the legend panel disappears since no colors are in use.
- **Deleting the primary selection:** If the deleted element was the primary, and other selected elements remain, the next element in the set becomes the new primary. If nothing remains, the selection clears.

---

Parent feature: [Selecting and Manipulating](README.md)