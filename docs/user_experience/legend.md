# Legend

A compact panel anchored to the bottom-left corner of the screen automatically lists every color currently in use on the canvas. Next to each colored circle is an editable name — "Group 1", "Group 2", etc. by default, but the user can click any name and retype it to something meaningful: "The Rebellion", "Neutral Zones", "Ancient Ruins."

The legend depends on the [color palette](colors.md) — every color that appears in the legend is one of the eight palette colors applied to shapes on the canvas.

## The panel layout

The panel is fixed in the bottom-left corner, sized snugly around its contents. Each entry is a single row with a small colored circle swatch followed by the editable name text. Entries stack vertically as colors are used. The panel never scrolls — there are at most eight entries (one per palette color), so everything fits at a glance.

## How it feels

The legend builds itself. As the user changes a shape's color (via the [color palette](colors.md)), the legend updates immediately — no delay, no save trigger. The user just starts using red shapes, and suddenly the legend shows red with a name they can click to customize.

Editing a legend name is as simple as clicking it and typing. The name persists even if the user removes all red shapes (in case they add more later) — it only disappears from the legend when the color is genuinely unused across the entire canvas.

## Why a legend

In a complex world-building diagram with a dozen colored factions, the user needs a reference. The legend is that reference — a key that maps colors to concepts. Without it, the user would have to remember that "amber means resources" every time they look at the canvas.

## How names work

- **Default names:** When a color first appears on the canvas, its default label is "Group 1", "Group 2", etc. in order of first appearance. This avoids two colors both defaulting to "Group 1".
- **Editing a name:** Click any label to edit it inline. The change is saved as part of the canvas state.
- **Name survival:** If the user renames "Red" to "Danger" and later deletes all red shapes, the name "Danger" is still stored. If they add a new red shape next session, the legend shows "Danger" again — it only resets if the color is genuinely unused and they clear the canvas.

## Clicking away from an edit

When the user clicks a legend label to edit it and then clicks anywhere outside the legend panel — on the canvas, a shape, the toolbar, or any other UI element — the label exits editing mode immediately. If the text is non-empty, it saves automatically. If the text is empty, it reverts to the previous name. This feels natural and quick — like renaming a file in a folder — no extra Enter press needed.

## Edge cases

- **No colors in use:** The legend panel hides entirely. An empty legend is just dead space.
- **Multiple shapes with the same color:** The legend shows the color once, with one name. The name applies to all shapes of that color — changing a shape's color to one already in the legend doesn't create a duplicate entry.
- **Last shape of a color removed:** The legend entry remains (preserving the custom name) in case the user adds that color back. It only disappears when no shapes of that color exist anywhere on the canvas.
- **Auto-generated default names count:** The "Group N" counter for default names uses a global increment so no two entries ever share the same default name by coincidence.

---

For how to apply a color to a shape in the first place, see [Colors](colors.md).