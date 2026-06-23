# Editing Text

**Audience:** Designers + developers | **Scope:** Player-facing text editing interactions on shapes

## Overview

Shapes hold labels. A shape without text is just a colored blob — adding text gives it meaning: a character's name, a location, a system, a note. Text is the core of what makes the canvas a world-building tool rather than just a drawing board.

---

## Entering Text Mode

### How to start

There are two ways to open the text editor:

1. **Select a shape and press Enter** — the most direct method. With the shape selected (its handles visible), pressing Enter opens a text overlay centered on the shape.
2. **Double-click a shape** — a more discoverable method for users who aren't familiar with keyboard shortcuts. Double-clicking any shape opens the same text editor.

### How it feels

The shape doesn't go anywhere or change appearance — instead, a semi-transparent text input area appears right over the shape, matching its position and size (scaled to the current zoom). The cursor blinks inside, ready for input. The shape's existing text (if any) appears in the input, editable from the start. It feels like the shape has opened up to accept words.

The info bar updates to show: "Type your text — Enter to confirm — Escape to cancel"

---

## Editing

### The text editor

The overlay looks and behaves like a simple text box:
- Text is centered horizontally
- Width is constrained to roughly the shape's width (with comfortable padding)
- The user can type, delete, paste, and modify text freely
- Line breaks happen automatically via word wrapping

The shape updates in real time as the user types — the text appears on the shape immediately, scaled to fit. This live preview lets the user see exactly how the label will look.

### Font sizing

Text auto-scales to fit within the shape:
- Starts at a comfortable reading size (20px)
- Shrinks as needed to fit longer text, down to a minimum of 8px
- Grows back up if text is shortened or the shape is enlarged

This means a shape can hold anything from a single character to a short paragraph, and the text always fills the shape attractively.

### Deleting text

Clearing all text is valid — a shape can exist without text. The user backspaces everything out and commits, and the shape becomes a purely visual element (colored oval or circle with no label).

---

## Committing or Canceling

### Enter (commit)

Pressing Enter (without Shift) closes the editor and saves the text. The text appears on the shape permanently, rendered in a crisp white font. The canvas auto-saves, so the text persists across sessions.

### Escape (cancel)

Pressing Escape closes the editor and discards any changes made since opening. The shape reverts to its previous text. This is the safety net: if the user started editing by accident or decided the text doesn't work, one key gets them out with no consequences.

### How commit vs cancel feels

Enter feels like sealing a decision — the text is locked in, the overlay closes, the user is back to selecting and arranging. Escape feels like stepping back — nothing changed, no harm done. The distinction is important because editing text requires focus, and knowing you can bail out at any time makes the user more willing to experiment.

### Edge cases

- **Shift+Enter:** Does not commit. Shift+Enter inserts a newline instead. Only a bare Enter (no Shift) commits. This matches standard text editor behavior across most applications.
- **Clicking outside the overlay:** Currently, the overlay only responds to keyboard commands. Clicking outside doesn't close it. The user must press Enter or Escape.
- **Very long text:** The text scales down to 8px minimum. If the text is still too long at 8px (very rare for most world-building notes), it's simply clipped or runs past the shape edge. The shape doesn't resize to accommodate text — the text fits the shape, not the other way around.
- **Zoom-induced overlay sizing:** The overlay scales with the camera zoom so it always covers the shape correctly on screen. At high zoom, the overlay is large; at low zoom, it shrinks proportionally.
- **Opening text editor on an already-selected shape:** If the shape is already selected and the user presses Enter again, the editor opens again with the existing text pre-populated. This is how the user edits existing text.
- **Double-click opens text editor even if the shape wasn't selected:** The double-click handler selects the shape and opens the editor in one action. This is the fastest path from "looking at a shape" to "editing its text."
- **Empty text on an empty shape:** Opening the editor on a shape that has no existing text shows a blank input. The user starts typing fresh.