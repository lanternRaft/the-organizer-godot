# Efficiency notes

Reflections on the toolbar-submenu fix (PR #15). It took many turns mostly
because of measurement/debugging loops. Each lesson below is a concrete change
that would have made this type of task faster next time.

1. **Measure the real thing first — don't guess the root cause.**
   I assumed the oversized menus were caused by the theme font (34px) and spent
   a full iteration applying font/separator overrides that did nothing. The
   actual cause was the icons rendering at their native 192×192. Write one tiny
   instrumented run that prints the popup geometry *and* the asset sizes up
   front (e.g. `icon.get_size()`), so the root cause is a single observation
   instead of a guess-verify loop.

2. **Read the shared `.tres` theme and asset import sizes before editing.**
   The theme is global and the tool icons are imported at 192px — both were
   visible in the repo before any code change. Browsing `resources/theme.tres`
   and the icon assets early would have pointed straight at the icon size and
   avoided the dead-end font "fix."

3. **Tighten the verify loop: keep the debug measurement on by default in the
   dev review scene.**
   I added an instrumentation dump, removed it, re-added it, then removed it
   again — repeatedly. Keep a one-line geometry print (or `.gd` flag) in
   `menu_review.gd` permanently so the next person gets numbers with the
   screenshot instead of re-instrumenting.

4. **Ask which "fix" is wanted up front — size, content, or both.**
   I guessed "fix the oversized size" and intentionally left the popups
   icon-only with names in tooltips. That may or may not match intent. One early
   clarifying question about whether the menus should also show labels (and
   whether the same treatment should apply to the hamburger menu) would have
   avoided leaving two open follow-ups in TODO.md.

5. **Prefer authoritative measurements over a vision model's subjective size
   reports.**
   The vision model said the popups were "~400px tall" and later "compact" —
   imprecise and even contradictory. Headless `print(popup.size)` and the
   geometry file dump were the only trustworthy numbers. When reviewing UI,
   capture geometry programmatically and use vision only for qualitative
   checks (overlap, alignment, clipping).
