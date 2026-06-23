# AGENTS.md — For human and AI agents working on The Organizer

Expert Godot 4 developer. Write clean, strongly typed GDScript following official style guide.

## Documentation hierarchy

The project's documentation follows a layered structure, each with a distinct purpose:

| Layer | Location | What goes there |
|---|---|---|
| Intent | `docs/intent.md` | One-line north star — what the app is for |
| Constraints | `docs/constraints.md` | Hard technical and platform boundaries (engine, target, minimum specs) |
| User experience | `docs/user_experience/*.md` | Player-facing feel and behavior — qualitative, not numeric |
| Architecture | `docs/architecture/` | High-level implementation details — systems, patterns, module boundaries |
| Specifics | gdUnit4 test definitions | Precise numeric thresholds, edge-case behavior, and per-function contracts |

**Compliance chain:** Architecture must fit the user experience docs. User experience docs must comply with `docs/intent.md`. Both architecture and user experience must comply with `docs/constraints.md`.

**Rule of thumb:** If a piece of knowledge describes what the player feels or does → `docs/user_experience/`. If it describes how the code is structured at a high level → `docs/architecture/`. If it describes exact behavior at the function/class level → a gdUnit4 test.

### User experience docs level of detail

`docs/user_experience/*.md` describes the feel and behavior of interactions from the player's perspective — not how they're implemented in Godot. Use qualitative, human-readable descriptions rather than precise numeric values.
- ✅ "A small buffer between the two elements"
- ✅ "The block settles with a satisfying thud"
- ❌ "3px spacing between elements"
- ❌ "0.2s fade-in animation"

**Scope rules for `docs/user_experience/*.md`:**
- **Audience:** Written for both designers and developers.
- **Boundary:** Player-facing interactions only. How it's built in Godot belongs in `docs/architecture/` or gdUnit4 tests.
- **Edge cases & errors:** Include in the same doc (or a companion file under `docs/user_experience/`), not a separate directory.
- **Rationale:** Include full rationale for why an interaction works a certain way. This helps designers evaluate trade-offs and developers make consistent decisions.

### Architecture docs level of detail

`docs/architecture/*.md` describes high-level implementation design — systems, responsibilities, data flow, and module boundaries. Focus on what a developer needs to understand before reading the code, not the code itself.
- ✅ "The InputManager delegates pointer events to the active ToolHandler via a strategy pattern"
- ✅ "Block creation flows ToolHandler → BlockFactory → BlockRegistry, with undo snapshots taken at the ToolHandler boundary"
- ✅ "SceneTreeManager owns the graph root; all element Nodes are children of that root"
- ❌ "The _input(event) function calls get_viewport().get_mouse_position()"
- ❌ "A small buffer between the two elements"

**Scope rules for `docs/architecture/*.md`:**
- **Audience:** Developers making implementation decisions.
- **Boundary:** System-level design only. Per-function logic belongs in inline comments or gdUnit4 tests.
- **Edge cases & errors:** Noted at the module boundary (e.g., "ToolHandler returns an error result when no tool is active"), not per-line.
- **Rationale:** Include why one architecture was chosen over alternatives — this preserves design context for future changes.

## Code Standards

### Script Structure
- **Maximum 200 lines per script.** Refactor into components if approaching this limit
- **Single Responsibility:** One concern per script (e.g., `BlockGrabbing`, `TowerStability`)
- **Functions under 20 lines.** Break complex logic into private helpers
- **Maximum 3 levels of nesting.** Use early returns and guard clauses
- **Prefer composition:** Child nodes with focused scripts over monolithic controllers


### Input Setup
- Input actions are defined in the `[input]` section of `project.godot`

### GDScript Rules
- Always use explicit static types for variables and function returns.
- Use `##` descriptions above:
  - Exported variables
  - Public variables/functions
  - Complex internal logic
- Extract repeated logic into private helper functions immediately.
- Use signals for decoupling over direct node references.
- Default to @export for anything likely to be tweaked during playtesting.
- File names us lowercase with underscores. Example: `label_shape.gd`
- Use tabs for indentation

## File Organization
- One class per file, filename matches class/script name.
- Group related scripts in logical directories (e.g., `blocks/`, `ui/`, `physics/`).

## Communication Style
- No conversational filler or praise
- Provide information without editorializing
- Start responses immediately with the requested information
- Show only relevant code changes, not entire files unless requested
- Ask brief clarifications on ambiguous questions rather than guessing