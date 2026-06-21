# State Management

A singleton autoload `State` (global.gd) holds all shared state:

| Variable | Type | Purpose |
|---|---|---|
| `tool_mode` | String (`select`/`label`/`shape`/`node`) | Current active tool |
| `shape_mode` | String (`oval`/`circle`) | Selected shape variant |
| `node_mode` | String (`circle`/`triangle`) | Selected node variant |
| `selected_set` | Array[Node] | All currently selected elements |
| `primary_selection` | Node | Primary (last-clicked) element |
| `selection_types` | Dictionary[Node, String] | Maps element → `"LabelShape"`/`"CircleNode"`/`"TriangleNode"`/`"Arrow"` |
| `camera` | Camera2D | Reference to the main camera |
| `element_layer` | Node2D | Container for all canvas elements |
| `anchor_layer` | Node2D | Container for anchor dots |
| `legend_colors` | Dictionary[String, String] | Color → custom name mapping |
| `clipboard` | Array[Dictionary] | Serialized copied elements |

## EventBus

The `EventBus` autoload relays signals:

| Signal | Arguments | Emitted When |
|---|---|---|
| `canvas_changed` | — | Any mutation occurs (trigger save) |
| `tool_changed` | new_tool: String | Tool mode switches |
| `selection_changed` | — | Selection set changes |
| `element_created` | element: Node | New element added |
| `element_deleted` | element: Node | Element removed |
| `text_edit_requested` | shape: Node | Enter key on selected shape |
| `anchor_interaction_started` | shape: Node, anchor: String | Mousedown on anchor dot |
| `anchor_interaction_ended` | — | Mouseup after anchor drag |