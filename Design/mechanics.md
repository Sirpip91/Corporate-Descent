# Mechanics

What the player actually does, minute to minute. Story is in
`story.md`, level breakdowns in `levels.md`.

Everything here runs on systems that already exist — first-person
movement, interact, examine/hold/rotate, inventory. No combat.

---

## Core Loop

**Every floor, the official way down is unavailable. Find the
unofficial one and make it work.**

Elevators and stairwells read badges, and his is dead. So each floor
becomes: *what else goes through a floor?* Freight elevators, service
corridors, elevator shafts, renovation gaps, chutes, fire escapes,
atrium voids. One route per floor, never repeated — see the routes
table in `levels.md`.

The puzzle is always the same shape with different content: **find the
route, then make it usable.** Power it, clear it, open it, reach it.

The information layer feeds the physical one — you read desks, notes,
clipboards and terminals to work out what's wrong and where the fix is.

**An earlier version made badge tiers the progression** — steal a Tier
2, unlock Tier 2 doors, repeat. It was cut. Lock-and-key is a fetch
quest no matter how it's dressed, and the story reasons for a
convenient badge were always contrivances.

## Badges

Badges are the *reason official routes fail*, not a collectible.

His badge dies at 9:05 and he keeps carrying it. Every elevator panel
and stairwell door in the building reads one. That's it — the player
never farms them.

The company's security model is worth knowing when writing floors:
**nothing is physically guarded.** Nobody checks a face. Everything is
process, badges and forms. Which is exactly why back-of-house — service
corridors, utility closets, freight — isn't secured at all. Nobody
thought to.

## Terminals and the Password Puzzle

The standout mechanic. Computers need a username and a password.

- **Usernames are easy** — nameplates, email signatures, the directory.
- **Passwords are the puzzle**, and they're solved by examining
  someone's desk. A dog photo. A marathon medal, 2019. A kid's drawing
  signed "Maya." A concert stub. An anniversary card.
- The player guesses: `Biscuit2019`, `Maya2016`, `Boston19!`
- **Three wrong attempts locks the account and pings security.** The
  player has to actually read the person before typing.

To get anywhere, he has to pay more attention to these people than
anyone has ever paid to him.

Terminals give information, never access: what's broken and why, who's
out this week, calendar routines, and story documents.

**Keep terminals off the critical path.** They're the reward for
paying attention, not a gate. Floor 9 does this correctly — the
terminal is a second route to a clue the maintenance clipboard already
gives you.

## People Are Doors

Badge doors open for people, and people don't look at him. He rides the
elevator down from 10 by getting in with a coworker who badges it.

Taught on Floor 10, then largely retired — the descent goes off the
official path from Floor 9 onward, and back-of-house has no readers.
Worth bringing back once, later, when it means something different.

He is briefly, completely dependent on the drones he spent fifteen
years resenting, and not one of them notices.

## Failure — Open

There is no fail state yet, and that's a real hole rather than a
decision.

A heat/security system was drafted and cut along with badge farming —
it only existed to punish stealing badges, and there's no stealing
anymore. Whatever replaces it has to punish something the player
actually does now.

## The Clock — Set Dressing Only

**Not a mechanic.** There is no timer, no countdown, and the game never
asks the player to stand and wait.

The funeral is at 6:00, four hours away. That's narrative weight — the
player feels where the day is going. Nothing counts it.

Clocks stay as dressing: wall clocks, the break room microwave, the
light through the windows getting later between floors, so the descent
has a sense of time passing. Because the player is never *spending*
time, the clocks can start disagreeing later without it feeling like a
broken mechanic — one runs backwards, an hour goes missing between
floors, and it reads as dread instead of a bug.

**A speeding clock as a set piece on one floor is fine.** A clock the
player has to budget is not.

## One-Way Descent

**You can always go down. You can never go back up.**

- Thematically it's the whole game — you don't get to return to who you
  were.
- Missed content is missed permanently, which makes players thorough
  instead of objective-chasing.
- For a solo dev it's an enormous scope win: no revisitable floors, no
  preserved state, no reactive old areas.

The *method* of travel tells the story. Early on the building moves him
— elevator, badge, authorized descent, one floor at a time, like a
ticket in a queue. Later the official routes stop working and he's in
stairwells, service corridors and crawlspaces, going places nobody sent
him. He gets his agency back exactly when the building stops being
legible.

## The Doubt Monologue

Approaching any exit escalates internal monologue — rent, savings,
fifteen years of unusable experience. Nothing blocks the player. The
game just makes them feel why they won't walk out.

This is the actual lock on the front door, and without it the ending is
a cheap gotcha.

## PSX as Horror Language

The visual limits are the vocabulary, not an obstacle:

- **Nobody's face moves in this building.** One flat texture per
  person. That's the world. The one character whose face *does*
  something lands like a jumpscare.
- **NPCs don't turn to look at you.** They talk facing their monitors.
  The ones that turn are the wrong ones.
- **Fog is level design.** Corridors fade to nothing; you never see the
  far wall of a floor.
- **Subtitles are unlimited fidelity.** Polygons cap the visuals;
  nothing caps the writing. Spend there.
- **Take audio away rather than adding it.** Silence beats stingers at
  this fidelity. Floor 10 has HVAC, keyboards, a distant printer. Lower
  down, half those layers are gone and the player notices without
  knowing why.
- **Let vertex jitter and affine warping worsen as he descends.** Free
  reality-degradation from the artifacts of the aesthetic already
  chosen.
