# Corporate-Descent — Game Overview

Quick-reference doc — the flow (what playing it actually feels like
moment to moment) and the reason (why this game exists, what it's
about). Fill in as the rewrite takes shape. Deeper story content goes
in `story.md`, level-by-level breakdown in `levels.md` — this file
stays a one-page summary, not the full bible.

---

## What This Is

_Placeholder — one or two sentences, the pitch._

## Genre & Tone

_Placeholder — confirm if this is still first-person psychological
horror like the original, or something else now._

## Core Loop (the flow)

Systems already built and staying (see `CLAUDE.md`):
- First-person movement (walk/sprint/crouch/jump)
- Interact/examine system (press F, pick things up, inspect, read notes)
- Pause menu with settings

_Placeholder — what does the player actually spend their time doing?
What's the moment-to-moment loop across a level?_

## Story / Premise (the reason)

_Placeholder — the rewrite. How much of the original carries over
(descending a corporate tower, a time-loop structure, a "Supervisor"
threat, badge/keycard progression) vs. what's new is still open._

## Setting

_Placeholder._

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

- [ ] Story direction — what carries over from the original, what's new
- [ ] Protagonist — who, what do they want
- [ ] Antagonist / core threat
- [ ] Level list and progression
- [ ] What the player should feel by the end
