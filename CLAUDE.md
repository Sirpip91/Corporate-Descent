# Corporate-Descent — Project Brain

This is the real game. Story and levels are being fully rewritten from
scratch on top of the systems below, which are staying as the core
mechanics. Treat this file as a technical reference to the current
codebase, not a running journal — update it when the architecture
actually changes (new autoload, new rule, new convention), not after
every session.

---

## Working With Claude Here — Ground Rules

This project is being built with Claude's help, but the finished codebase
must read exactly like a solo human developer wrote every line of it.
That means:

- **No AI-attribution comments.** Never write `# added by Claude`,
  `// AI-generated`, `# TODO(claude): ...`, or anything that references
  Claude, an AI, or this tool. If a comment wouldn't make sense coming
  from a human dev working alone, don't write it.
- **No AI-only bookkeeping inside this repo.** No sentinel hashes, no
  IDs, no metadata files, no `.claude-*` tracking files whose only
  purpose is to help an AI re-identify or re-locate something later.
  If something needs tracking across sessions, it goes in the separate
  `ai-workspace` tracker (`L:\Repos\ai-workspace\gamedev\corporate-descent.md`),
  never inside this game's own files.
- **Match existing conventions exactly** — naming, formatting, comment
  density (sparse — see the existing scripts). Don't introduce a new
  style just because it's convenient in the moment.
- **Comments explain non-obvious WHY, never WHAT.** If removing a
  comment wouldn't confuse a future reader, don't write it.
- **In, edit, out.** Come in for a specific script/scene/system change,
  make it, leave. Don't restructure things that weren't asked for,
  don't leave scaffolding "for next time," don't add speculative
  abstractions for features that don't exist yet.
- **Story/level content lives in `Design/`, actual line/subtitle text
  lives in `Dialogue/`** (see below), not scattered as comments or
  hardcoded strings inside gameplay scripts.

## Current Status

- Core systems (player, interact/examine, pause, HUD, dev console) are
  done and stable — see below. Not up for redesign unless something
  is actually broken.
- Story and level layout are being rewritten. The old narrative
  content (monologue data, old level scripts) does not carry over —
  build new levels using the systems below, don't port old level logic.

---

## Autoloads (always available by name in any script)

| Name | File | Purpose |
|------|------|---------|
| `GameState` | `Scripts/game_state.gd` | Settings (`mouse_sensitivity`, `master_volume`, `volumetric_fog_enabled`) + bare `inventory` array. `apply_graphics_settings()` re-derives the active level's `WorldEnvironment` fog from (level's own authored value) AND (player's preference) — downgrade-only, never turns an effect on for a level that wasn't built with it. Add floor/story state here as real levels need it. |
| `UI` | `UI/hud.gd` | Crosshair (`hide_crosshair(reason)` / `show_crosshair(reason)`), examine hints (`show_examine_hints`/`hide_examine_hints`), FPS counter (`set_fps_visible`). Dialogue is Dialogic's job now — see the `Dialogic` row below. |
| `Dev` | `UI/dev_console.gd` | `Dev.msg("[color=yellow]text[/color]")` — never use raw `print()` in gameplay scripts. Backtick key to open in-game. |
| `ExamineController` | `Scripts/examine_controller.gd` | `begin(Node3D)`, `end(bool collect)`, `rotate(Vector2)`, `is_collectible()` — drives the pick-up/hold/rotate/zoom/drop behavior for `Examinable`. |
| `Dialogic` | `addons/dialogic` (third-party) | Dialogue engine. `Dialogic.start(timeline_id)` runs a `.dtl` timeline. NPCs trigger this via `NPCBase.timeline_id`/`interact()` — see `Dialogue/README.md`. `UI/hud.gd` connects to `Dialogic.timeline_started`/`timeline_ended` once, globally, to lock player movement and show the mouse cursor for the duration. |

## Key Classes

- **`Interactable`** (`Interact/interactable.gd`) — base for anything the
  player can press F on. `@export var interact_message`. Override
  `interact(_body)` for custom behavior (switches, doors, levers).
- **`Examinable`** (`Interact/examinable.gd`, extends `Interactable`) —
  hold in front of camera, rotate with mouse, scroll to zoom, optionally
  collect. Exports: `display_name`, `hold_rotation`, `collect_item_id`
  (leave blank for examine-and-drop items like a flashlight; set it for
  things that should actually enter `GameState.inventory`).
- **`NPCBase`** (`Scripts/npc_base.gd`, extends `Interactable`) — shared
  base for every NPC scene. Owns the animation state machine over the
  character pack's baked clips (`play_idle`/`play_walk`/`play_turn`/
  `play_stop`/`play_sit`/`play_typing`/`play_pacing_phone`, with TURN/STOP
  auto-chaining to the next state when their clip finishes) and the
  `timeline_id` export that starts a Dialogic timeline on interact.
  Per-pack scripts (`Assets/Characters/<Pack>/npc.gd`) extend it and only
  supply their own Look enum/texture swap. Movement/animation is driven by
  one of two mutually exclusive built-in behaviors: a `patrol_enabled`
  demo (straight-line back-and-forth walk/idle, off by default) or, once
  `destinations_array` (an `Array[Marker3D]`) is populated, a real
  waypoint patrol that walks to each marker in order, looping back to the
  first after the last, idling a random 1–5s at each stop — the array
  takes over from the demo automatically when non-empty. On `interact()`,
  a `LookAtModifier3D` on the head bone (`mixamorig_Head`) turns to face
  the player's camera for the duration of the conversation, layered on
  top of whatever animation is playing — no per-NPC setup needed, it's
  automatic for any pack sharing that bone name.

## Critical Architecture Rules

- Player is always in the `"player"` group →
  `get_tree().get_first_node_in_group("player")`.
- Every level's `WorldEnvironment` runs `Scripts/world_environment.gd`,
  which joins the `"world_environment"` group and caches the level's
  authored settings (e.g. `base_volumetric_fog`) as node metadata before
  any runtime override touches them — same lookup pattern as the player
  group, used by both `GameState.apply_graphics_settings()` and the dev
  console's fullbright toggle.
- `movement_locked = true` on the player → do NOT call `move_and_slide()`
  anywhere else while it's true; physics will push the locked player.
- Before reparenting any object to camera space (see `ExamineController`),
  zero `collision_layer`/`collision_mask` on its `CollisionObject3D`
  children first — prevents a physics launch.
- Mouse sensitivity lives in `GameState.mouse_sensitivity`, read live
  each frame in `player.gd` — never hardcode a sensitivity constant.
- `Dev.msg()` only for any debug/status output — never `print()`.

## Player Flags (`Scripts/player.gd`)

```gdscript
var movement_locked: bool = false   # freezes movement — no move_and_slide when true
var examining: bool = false          # routes mouse to ExamineController instead of camera
```

---

## Asset Pipeline

Full workflow, folder convention, and Inspector field reference:
`Assets/README.md`. Short version: one folder per prop under `Assets/`,
copy the right template out of `Assets/_Templates/`
(`EnvProp`/`Interactable`/`Examinable`), swap in the real model, fill in
the exported fields. Once real props exist under `Assets/<Category>/`,
match their structure rather than inventing a new one per prop.

## Where Story/Level Content Lives

- `Design/` — story bible, level list, character notes, whatever the
  new narrative needs. Plain docs, not code.
- `Dialogue/` — Dialogic content: a `.dch` character + one or more `.dtl`
  timelines per NPC that talks. This is the actual line text — unlike
  `Design/`, it's read by the game at runtime. See `Dialogue/README.md`.
- Level scenes go under `Levels/<LevelName>/` (mirrors the old project's
  convention) once the first real level starts — `TestArea/` was a
  systems-check scene only, not a real level; retire it once the first
  actual level exists.
- Gameplay scripts reference story content through one lookup point —
  `NPCBase.timeline_id` → `Dialogic.start()` — rather than hardcoding
  strings per-level.

## Project History

Session-by-session progress log lives outside this repo, in
`L:\Repos\ai-workspace\gamedev\corporate-descent.md`. Don't duplicate
that log in here.
