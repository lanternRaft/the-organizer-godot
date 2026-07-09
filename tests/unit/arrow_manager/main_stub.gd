extends Node

## Minimal stub replacing Main.gd for arrow manager tests.
## Only provides the properties that ArrowManager and the test assertions rely on.

## Whether select mode is active. ArrowManager._process() reads this from its parent.
var select_mode_active: bool = false
