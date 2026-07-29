# Corporate-Descent

Godot 4.7 project, Forward+ renderer. This is the real project going
forward — story and levels are being rewritten from scratch on top of
the core systems below, which are staying as-is.

See `CLAUDE.md` for the full technical reference (autoloads, key
classes, architecture rules) before making changes.

## What's here

- **Player** (`Scripts/player.gd`, `Player/player.tscn`) — first-person
  movement, mouse look, jump, crouch, sprint, head-bob, dynamic FOV.
- **Interact system** (`Interact/`) — `Interactable` (base class, press
  to interact) and `Examinable` (pick up, hold in front of camera,
  rotate with mouse, scroll to zoom, optionally collect).
- **Pause menu** (`UI/pause_menu.gd` + `.tscn`, `UI/blur.gdshader`) —
  resume/quit, plus Graphics/Sound/Controls sub-panels (resolution,
  fullscreen, FPS toggle, master volume, mouse sensitivity).
- **HUD** (`UI/hud.gd`, autoloaded as `UI`) — crosshair (reason-based
  show/hide), examine hints, FPS counter.
- **Dev console** (`UI/dev_console.gd`, autoloaded as `Dev`) — backtick
  (`` ` ``) to open.
- **GameState** (`Scripts/game_state.gd`, autoloaded) — settings
  (`mouse_sensitivity`, `master_volume`) + a bare inventory array.
- **ExamineController** (`Scripts/examine_controller.gd`, autoloaded) —
  drives the pick-up/hold/rotate/zoom/drop behavior for `Examinable`.
- **Grid test area** (`TestArea/test_area.tscn`) — a greyboxed sanity
  check scene (floor, walls, stepped platforms, two test interactables).
  Not a real level — retire it once the first actual level exists.
- **Asset import pipeline** (`Assets/`) — folder convention + three
  template scenes (`EnvProp`, `Interactable`, `Examinable`) to copy for
  new props. See `Assets/README.md`.
- **Design docs** (`Design/`) — story/level content goes here as plain
  docs, not in code.

## Controls

WASD move · Mouse look · Space jump · Shift sprint · Ctrl/C crouch ·
F interact / examine-drop · Esc pause or exit examine · Scroll wheel
zoom while examining · `` ` `` dev console.
