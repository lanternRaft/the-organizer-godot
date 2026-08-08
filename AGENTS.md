# AGENTS.md — Working on The Organizer (Godot 4)

Guidance for human and AI agents. Expert Godot 4 developer; write clean,
strongly typed GDScript following the official style guide.

## Start here

| Concern | Read this first |
|---|---|
| North star / what the app is | `docs/intent.md` |
| Hard technical constraints | `docs/constraints.md` |
| Player-facing behavior | `docs/user_experience/` |
| **Working on UI / theme / widgets** | **`docs/agents/ui.md`** |
| Writing tests | `gofast.md` (lessons + GdUnit4 gotchas) and `tests/unit/` |
| Product follow-ups | `TODO.md` |

## Documentation hierarchy

| Layer | Location | What goes there |
|---|---|---|
| Intent | `docs/intent.md` | One-line north star — what the app is for |
| Constraints | `docs/constraints.md` | Hard technical and platform boundaries |
| User experience | `docs/user_experience/*.md` | Player-facing feel — qualitative, not numeric |
| Architecture | `docs/architecture/` | High-level implementation design (create if missing) |
| Agent guides | `docs/agents/ui.md` | Working knowledge for specific subsystems |
| Specifics | gdUnit4 tests | Precise numeric thresholds, per-function contracts |

**Compliance chain:** architecture must fit the user experience docs; UX docs
must comply with `docs/intent.md`; both must comply with `docs/constraints.md`.

Rule of thumb: what the player feels → `docs/user_experience/`. How code is
structured at a high level → `docs/architecture/`. Exact behavior at the
function/class level → a gdUnit4 test. How a subsystem is *worked on* (theme
usage, gotchas, conventions) → `docs/agents/`.

## Code standards

- **GDScript rules:** explicit static types on all vars/params/returns; tabs for
  indentation; `snake_case` files (`label_shape.gd`); `##` doc comments above
  exported vars, public functions, and complex logic; signals over direct node
  references for decoupling.
- **Structure:** one class per file, filename matches the class; keep scripts
  small (target < 200 lines, functions < 20 lines, ≤ 3 nesting levels) and
  extract repeated logic into private helpers immediately.
- **`@export` for anything likely to be tweaked** during playtesting; one-off
  deviations go in `theme_override_*` in the scene, not edits to shared
  resources (see `docs/agents/ui.md`).
- **Warnings are errors.** `project.godot` promotes many GDScript warnings to
  hard errors — don't rely on unsafe access, dynamic calls, or untyped
  declarations slipping through. CI runs `gdformat --check .` and `gdlint .`.

## Testing (GdUnit4)

- Run everything: `bash addons/gdUnit4/runtest.sh` (needs `GODOT_BIN`).
- Run one suite: `bash addons/gdUnit4/runtest.sh -a res://tests/unit/<area>/test_<thing>.gd`
  — the `-a` argument takes a **`res://` path**, not an absolute path.
- Tests live under `tests/unit/`, mirrored by area (`tests/unit/tools/`,
  `tests/unit/main/`, `tests/unit/camera_controller/`, …).
- UI tests: instantiate the `.tscn` (script `new()` drops scene-defined exports),
  reset shared preloaded resources in `before_test()`, and check sizes visually
  with `godot_capture` when display dimensions matter.
- Read **`gofast.md`** before writing new tests — it records the GdUnit4 API
  traps and test fixtures that already cost time in this repo.

## Communication style

- No conversational filler or praise; start responses with the requested info.
- Show only relevant code changes, not entire files unless asked.
- Ask brief clarifying questions on genuinely ambiguous requests rather than
  guessing.
- Notes: `AGENTS_OLD.md` is the archived predecessor of this file — don't edit
  it.