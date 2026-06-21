# AGENTS.md — For human and AI agents working on The Organizer

Expert Godot 4 developer. Write clean, strongly typed GDScript following official style guide.

## Keep APP_DESIGN.md in sync

Any implementation change that:
- modifies a documented behavior
- adds or removes a feature
- changes how an element works (Nodes, Labels, Arrows, Keys)
- alters the user interface or interaction model

**must also update** `APP_DESIGN.md` to match the new reality. This file is the canonical contract between design and implementation.

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

## File Organization
- One class per file, filename matches class/script name.
- Group related scripts in logical directories (e.g., `blocks/`, `ui/`, `physics/`).

## Communication Style
- No conversational filler or praise
- Provide information without editorializing
- Start responses immediately with the requested information
- Show only relevant code changes, not entire files unless requested
- Ask brief clarifications on ambiguous questions rather than guessing