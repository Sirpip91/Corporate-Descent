# Corporate-Descent — Game Overview

Quick-reference doc — the flow (what playing it actually feels like
moment to moment) and the reason (why this game exists, what it's
about). Deeper story content goes in `story.md`, systems in
`mechanics.md`, level-by-level breakdown in `levels.md` — this file
stays a one-page summary, not the full bible.

---

## What This Is

You've worked the same corporate job for fifteen years. This morning
you resign, and it's accepted in ninety seconds — which deactivates
your badge. Every door in the building reads a badge, including the way
out.

Your mother's funeral is at six, four hours away. You are standing
inside a building that no longer has any record of you.

## Genre & Tone

First-person psychological horror carried by inner monologue, sound
design and subtitles. Corporate resentment turned into dread. Nothing
supernatural is ever confirmed — everything stays legible as burnout
and dissociation, which is worse, because the player can't file it
under "ghosts" and stop recognising their own job in it.

## Core Loop (the flow)

Systems already built and staying (see `CLAUDE.md`):
- First-person movement (walk/sprint/crouch/jump)
- Interact/examine system (press F, pick things up, inspect, read notes)
- Pause menu with settings

Every elevator and stairwell in the building reads a badge and yours is
dead. So each floor becomes the same question in a different shape:
**what else goes through a floor?** Freight elevators, service
corridors, elevator shafts, renovation gaps, chutes. Find the route,
then make it usable — power it, clear it, open it, reach it. One route
per floor, never repeated.

Feeding that: reading the building and the people in it. Maintenance
clipboards, breaker panels, notes, and terminals you open by examining
a stranger's desk closely enough to guess their password — the boat
photo and the sales plaque give you `SecondWind2021`.

No combat, no timer. Full breakdown in `mechanics.md`.

## Story / Premise (the reason)

The building doesn't attack him — it stops registering him, and the
longer he's unregistered the less he's there. Coworkers stop reacting.
His reflection stops appearing. The HUD degrades. The monologue drifts
from *"I need to get out"* to *"he needs to get out."* The people still
working are the ones who exist; he's the one who stopped, which inverts
the resentment the opening spent an hour building.

The real lock isn't the turnstile. It's the internal arithmetic that
gets louder near every exit — rent, savings, fifteen years of
experience in something nobody outside this building does.

And the lobby turnstiles only read badges on the way **in.** They never
needed one to let you out. In fifteen years he never once tried to
leave without permission.

Full narrative in `story.md`.

## Setting

Cold open at the company Christmas party. Tutorial in the protagonist's
apartment (Japanese-style, small, neglected). The rest of the game is a
single office tower, descended one-way — you can always go down, never
back up.

## Art Direction

- **Base style:** PSX/PS1-era low-poly look.
- **Source:** purchased/free asset packs (itch.io), retextured and
  modified to fit — not used stock.
- **Custom work:** Blender for anything the packs don't cover — full
  custom modeling when needed.
- Matches the existing import pipeline in `Assets/README.md` (Nearest
  filter, mipmaps off, for that same low-fi pixel look).

## Technical Approach

- Godot 4.7, Forward+ renderer.
- Core systems (player, interact/examine, pause, dev console) already
  built — see `CLAUDE.md` for the technical reference.
- Prop pipeline (templates + workflow) already established in `Assets/`.

## Open Questions

- [x] Story direction — resign successfully, get locked in by your own
	  offboarding, race a clock you can't win by asking permission
- [x] Protagonist — fifteen-year employee; wants to reach his mother's
	  funeral
- [x] Core threat — administrative erasure, never confirmed as
	  supernatural
- [x] Core mechanic — find the unofficial route down, one per floor
- [x] Floors 8 and below — Floors 8 through 5 + Lobby specced, see
	  `levels.md`
- [x] Fail state — getting spotted by the suit re-files him; see
	  `mechanics.md`
- [x] Secondary antagonist — the suit, seeded by Halloran's phone call
	  on Floor 10, never named or voiced; see `story.md`
- [ ] The abandoned thing (camera / guitar / knife roll) — pick one
- [ ] Where the surveillance-metrics documents surface
- [ ] Whether there's a predecessor who tried this before
