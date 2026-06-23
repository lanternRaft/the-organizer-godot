# Colors and Legend

**Audience:** Designers + developers | **Scope:** Player-facing color interactions and the legend panel

## Overview

Color gives meaning to shapes beyond their text and position. A red oval might represent a hostile faction, a green one a safe location, a blue one a neutral character. The color palette and legend panel work together to create a visual coding system that the user defines.

---

## Changing a Shape's Color

### How to do it

1. Select a single shape
2. The selection menu appears below it with two buttons: Del and Color
3. Click the **Color** button
4. A small palette pops up with eight color swatches in a 2×4 grid
5. Click a swatch — the shape changes color instantly, the palette closes, and the canvas auto-saves

### The palette

Eight colors, chosen for readability and distinctiveness:

- **Blue** — the default. Neutral, friendly, good for general-purpose use.
- **Red** — urgency, danger, opposition.
- **Green** — safety, nature, allies.
- **Amber** — warning, resources, neutral factions.
- **Purple** — magic, mystery, royalty.
- **Pink** — affection, intrigue, distinctiveness.
- **White** — blank, empty, unaffiliated, or paper-like.
- **Dark** — shadow, background, void, or contrast.

### How it feels

Color changes are instant and vivid. Clicking a swatch is like dipping the shape in paint — the fill changes immediately, and the stroke updates to a darkened version of the new color. The palette pops up right next to the color button so the user's eye doesn't have to travel far.

The palette is small and focused — eight colors, no more. This is intentional: too many choices would slow down the workflow. The user can always distinguish these eight at a glance, and they cover a broad enough spectrum for most world-building coding systems.

### Why only eight colors

A palette with more colors would require scrolling, searching, or a complex picker. For a world-building tool where colors are used as categorical signals (this faction is red, that faction is blue), a limited, carefully-chosen set encourages the user to think in terms of categories rather than shades. Eight is enough to represent distinct groups without overwhelming.

### The selection menu

The menu that holds the Color button only appears when exactly one element is selected. It positions itself below the selected element, following it if the element moves or the camera zooms. It's always just out of the way — accessible but not intrusive.

### Edge cases

- **Color change on arrows:** Arrows don't have a fill color property. The Color button is only available for shapes. Arrows have a default white stroke that highlights on selection.
- **Color change on a multi-select:** The selection menu hides when more than one element is selected. To change colors of multiple shapes, the user must do them one at a time (planned: batch color change for multi-select).
- **Color closes the palette:** Selecting a swatch closes the palette. This keeps the UI clean — no lingering popups after an action is taken.
- **Palette click prevention:** Clicks on the palette don't pass through to the canvas behind it. The palette captures the click and uses it only for swatch selection.

---

## The Legend (Planned)

A panel in the bottom-left corner of the screen automatically lists every color currently in use on the canvas. Next to each colored circle is an editable name — "Group 1", "Group 2", etc. by default, but the user can click any name and retype it to something meaningful: "The Rebellion", "Neutral Zones", "Ancient Ruins."

### How it would feel

The legend builds itself. As the user adds colored shapes to the canvas, new entries appear silently in the legend. No configuration, no registration — the user just starts using red shapes, and suddenly the legend shows red with a name they can customize.

Editing a legend name is as simple as clicking it and typing. The name persists even if the user removes all red shapes (in case they add more later) — it only disappears from the legend when the color is genuinely unused across the entire canvas.

### Why a legend

In a complex world-building diagram with a dozen colored factions, the user needs a reference. The legend is that reference — a key that maps colors to concepts. Without it, the user would have to remember that "amber means resources" every time they look at the canvas.

### Edge cases

- **No colors in use:** The legend panel hides entirely. An empty legend is just dead space.
- **Multiple shapes with the same color:** The legend shows the color once, with one name. The name applies to all shapes of that color.
- **Renaming a color:** The name is stored persistently. If the user renames "Red" to "Danger" and later deletes all red shapes, then adds a new red shape next session, the name "Danger" is still there — it only resets if the user explicitly clears it.
- **Auto-generated default names:** When a new color first appears, its default name is "Group N" where N increments. This avoids two colors both defaulting to "Group 1".