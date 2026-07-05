# Clearing the Canvas

Clearing the canvas removes all elements at once. It's the nuclear option for starting fresh and is protected by a confirmation dialog.

## How it works

1. Open the hamburger menu (top-left corner)
2. Select **Clear**
3. A confirmation dialog appears with the message: "This will delete everything on the canvas. This cannot be undone."
4. The user can either confirm (clear everything) or cancel (return to the canvas)

### The confirmation dialog

This is the only destructive action that requires a confirmation. Individual deletions (Delete key) don't ask for confirmation — but wiping the entire board does. The dialog makes it clear what will happen and that there's no undo. Two buttons: **Cancel** dismisses the dialog, and the Clear button executes the wipe.
## Behavior

- **Cancel mid-dialog:** The user can close the dialog via Cancel, the window close button, or Escape. The canvas is untouched, and the user continues working.
- **Empty canvas + Clear:** The dialog still appears. Confirming on an already-empty canvas is a no-op but isn't an error — it just saves the empty state again.
- **Auto-save after clear:** The cleared state is saved immediately, preventing recovery by reopening.

---

Parent feature: [Managing Your Work](README.md)