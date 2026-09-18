# Dialogue

NPC dialogue runs on [Dialogic](https://dialogic.pro/) (`addons/dialogic`).
This folder holds the actual content: one `.dch` (character) and one or more
`.dtl` (timeline) files per NPC that talks. The older hand-rolled
`Dialogue`-autoload/JSON system is gone — this is a full replacement, not a
layer on top of it.

## Files here

- `<id>.dch` — a Dialogic character resource (display name, portraits,
  color, etc.).
- `<id>.dtl` — a Dialogic timeline: plain text, one event per line/block.

**Create both through Dialogic's own editor UI (Godot editor → Dialogic
dock → Character / Timeline → New), not by hand-writing the files.**
Dialogic caches its character/timeline registry in memory
(`Engine.meta`) and only refreshes/re-saves `project.godot`'s `[dialogic]`
directory entries when you save through its own UI — a hand-authored file
dropped in from outside won't reliably show up in the editor or resolve
by identifier until Dialogic notices it, which isn't guaranteed. Creating
through the UI sidesteps that entirely. `interview_candidate` (used by
`NPCFemaleInterview` in Level 2) is the current worked example — a couple
of lines plus one branching choice that converges back to a shared line;
open it from the Dialogic dock to see the actual structure. For the full
timeline mini-language (conditions, variables, choices, jumps, portraits,
etc.) see Dialogic's own docs at https://docs.dialogic.pro — not
re-documented here.

It doesn't matter which folder Dialogic saves the files into (its default
location is fine) — what matters is the identifier (the name you give the
character/timeline when creating it), since that's what `NPCBase.timeline_id`
references, not a file path.

## Registering a new character/timeline

Dialogic resolves a `.dch`/`.dtl` by a short identifier (not by full path),
looked up in `project.godot`'s `[dialogic]` section — this is maintained by
Dialogic's editor UI automatically when you create/save through it; you
shouldn't need to hand-edit this section.

## Wiring an NPC to a timeline

`Scripts/npc_base.gd` (`NPCBase`, shared by every NPC scene) exports
`timeline_id: String`. Leave it blank for an NPC that doesn't talk yet;
set it to a registered `.dtl` identifier and `interact()` calls
`Dialogic.start(timeline_id)` — nothing else needed per-NPC.
`interact()` also no-ops while `Dialogic.current_timeline` is already
non-null, so spamming the interact key can't restart/stack timelines —
that guard also means `interact_ray.gd` hides the interact prompt and
ignores the key entirely for anything else in the world while a timeline
is playing.

`NPCBase` also exports `dialogue_skippable` (default `true`). Right before
starting a timeline, `interact()` copies it into `UI.dialogue_skippable` —
`player.gd`'s Escape handling checks that to decide whether to call
`Dialogic.end_timeline()` early. Set it `false` on an NPC whose
conversation needs to actually finish (hands over an item, flips a flag
the game depends on) so the player can't dodge the consequence by
bailing out mid-line.

`UI/hud.gd` connects to `Dialogic.timeline_started` / `timeline_ended` once,
globally, to hand control to/from the player around any timeline: hides the
crosshair (`hide_crosshair("dialogue")`, same named-reason pattern as
examine), sets `player.movement_locked = true` (which also suppresses
mouse-look in `player.gd`, same as it already does during Examine), and
switches `Input.mouse_mode` to `MOUSE_MODE_VISIBLE` so choice buttons are
clickable — mirroring how `PauseMenu` and `ExamineController` already hand
off player control. All of that is generic; it doesn't need touching
per-NPC or per-timeline.

## Story state

Timelines can call into `GameState` directly (inventory, and whatever
story flags real levels need — see `Scripts/game_state.gd`) via Dialogic's
variable/condition system rather than a separate flag store — there's no
parallel "dialogue flags" dictionary anymore.
