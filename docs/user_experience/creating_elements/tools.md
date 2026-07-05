# Tools

A toolbar sits at the bottom center of the screen. It's always visible and shows which tool is active. The active tool changes what happens when the user clicks or drags on the canvas. Tools are the entry point for creating elements on the canvas.

## How it works

There are three tool categories:

- **Select tool** — the default. Click to pick things up, drag to move them. This is the mode users come back to between every other action.
- **Shape tool** — click the canvas to drop a new shape. A dropdown on this button lets the user choose between Oval and Circle before placing.
- **Node tool** — click the canvas to drop a small fixed-size marker. A dropdown on this button lets the user choose between Circle Node and Triangle Node before placing.

The user is never stuck in a tool they don't want. Every element placement automatically returns them to Select mode. If they accidentally enter a tool, Escape gets them out.

## Behavior

- **Tool deactivation:** Pressing Escape while in any creation tool deactivates it without placing anything, returning to Select mode with a clean slate.
- **Switching tools mid-placement:** Switching from Shape tool to Node tool (or vice versa) while in placement mode is safe — the old tool deactivates and the new one activates. No partial placement state persists.

---

Parent feature: [Creating Elements](README.md)