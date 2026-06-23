# AGENTS.md — For human and AI agents working on The Organizer

Expert Godot 4 developer. Write clean, strongly typed GDScript following official style guide.

## Keep design docs in sync

Design documentation lives in `docs/APP_DESIGN.md` (index), `docs/*.md` (per-subject files), and `docs/user_experience/*.md` (user experience docs).

Any implementation change that:
- modifies a documented behavior
- adds or removes a feature
- changes how an element works (Nodes, Labels, Arrows, Keys)
- alters the user interface or interaction model

**must also update** the relevant design doc(s) to match the new reality. These files are the canonical contract between design and implementation.

### User experience docs level of detail

`docs/user_experience/*.md` describes the feel and behavior of interactions from the player's perspective — not how they're implemented in Godot. Use qualitative, human-readable descriptions rather than precise numeric values.
- ✅ "A small buffer between the two elements"
- ✅ "The block settles with a satisfying thud"
- ❌ "3px spacing between elements"
- ❌ "0.2s fade-in animation"

Save exact numbers, thresholds, and implementation-specific values for inline comments or the implementation-focused design docs under `docs/*.md`.

**Scope rules for `docs/user_experience/*.md`:**
- **Audience:** Written for both designers and developers.
- **Boundary:** Player-facing interactions only. How it's built in Godot belongs in `docs/*.md`.
- **Edge cases & errors:** Include in the same doc (or a companion file under `docs/user_experience/`), not a separate directory.
- **Rationale:** Include full rationale for why an interaction works a certain way. This helps designers evaluate trade-offs and developers make consistent decisions.

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