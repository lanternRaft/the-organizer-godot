# Placing Shapes

Shapes (ovals and circles) are the primary labeled elements on the canvas. They hold text, can be resized and recolored, and serve as the anchor points for arrow connections. Placing a shape is the most common creation action.

## How it works

1. The user clicks the **Oval** or **Circle** button in the toolbar
2. The cursor changes to a crosshair — the canvas is waiting
3. The info bar reads "Click the canvas to place a (oval/circle)"
4. The user clicks anywhere on the canvas
5. A shape appears at that exact spot, already selected, with resize handles visible
6. The tool automatically switches back to Select mode

### Shape sub-mode dropdown

The Shape button in the toolbar has a small triangle next to it (or in some designs, clicking it opens a menu). This reveals two options: Oval and Circle.

- **Oval** places a horizontally-oriented ellipse (80px wide, 50px tall). Good for labels, names, short descriptions.
- **Circle** places a round shape (80px in both dimensions). Good for emphasis, categorical markers, or nodes in a flow.

When the user switches from Oval to Circle, any shape they place from that point on is a circle. The toolbar button text updates to show the current sub-mode so there's no ambiguity about what will appear.

## How it feels

Placing a shape should feel as simple as dropping a pin on a map. The user points, clicks, and the shape is there — no configuration dialog, no sizing step, no dragging. The shape arrives at a reasonable default size with a friendly blue color. Fine-tuning (resize, color, text) comes after placement.

One click, and the canvas has something new on it. The user is immediately in control — they can drag it somewhere else, resize it, color it, or leave it and place another one.

## Edge cases

- **Placing on top of existing elements:** New shapes can overlap existing shapes or nodes if placed on top of them. The user can freely position elements anywhere on the canvas, including on top of other elements.
- **Rapid placement:** The user can click multiple times quickly to drop several shapes in sequence — but only if they re-enter Shape mode each time. Each placement returns to Select mode, which is a deliberate trade-off: it prevents accidental mass placement while letting the user build up a canvas quickly through repetition.
- **Tool deactivation:** Pressing Escape while in shape mode deactivates the tool without placing anything. The user returns to Select mode with a clean slate.

---

Parent feature: [Creating Elements](README.md)