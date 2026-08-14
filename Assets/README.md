# Assets — Import & Prop Workflow

One folder per asset, same convention the original Corporate-Descent project
already used (`Assets/AlarmClock/`, `Assets/Badge/`, etc.):

```
Assets/
  _Templates/         ← copy from here, never edit these directly
    EnvProp.tscn        — decoration/collision only, not interactive
    Interactable.tscn   — press F, something happens (no pickup)
    Examinable.tscn      — press F to pick up, hold, rotate, zoom, maybe collect
    LightBlocker.tscn   — invisible box that still casts shadows, for plugging light leaks
    Moon.tscn           — small unshaded white sphere, for a plain-color night sky
    ModularWall.tscn     — resizable wall panel, texture re-tiles automatically
    ModularFloor.tscn    — resizable floor patch, same auto-tiling
    ModularCeiling.tscn  — resizable ceiling patch, same auto-tiling
  Chair/
    Chair.glb
    Chair_texture.png
    Chair.tscn          ← the usable scene, built from a template + this model
  Flashlight/
    Flashlight.glb
    Flashlight.tscn
  ...
```

Every real prop gets its own folder holding the model, its textures, and the
`.tscn` you actually drop into a level. Never instance a raw `.glb` straight
into a level scene — always go through a `.tscn` wrapper, even a bare one.

**Exception — small multi-variant clutter sets** get grouped under one
category folder instead of sitting flat at the `Assets/` root, e.g.
`Assets/KitchenProducts/Bottle003/`, `Assets/BathProducts/Shampoo001/`. Use
this only when there are many near-duplicate scatter props from the same
source (a shelf of a dozen bottles, a rack of ramen packets) — each item
still gets its own folder and `.tscn` underneath, this only changes where
that folder sits. Everything else stays flat at the `Assets/` root.

## Which template for which prop

| You're making... | Use | Why |
|---|---|---|
| Wall, chair, table, shelf, floor clutter — anything just standing there | **EnvProp** | Player walks around/on it. No script, no interact prompt. |
| Light switch, button, lever, door, elevator panel | **Interactable** | Player presses F, something happens once. No pickup — usually needs a small custom script (see below). |
| Phone, flashlight, picture, note, badge, any handheld item | **Examinable** | Player presses F to pick it up, hold it in front of the camera, rotate with the mouse, scroll to zoom, and either drop it or (if `collect_item_id` is set) pocket it. |
| Light leaking through a wall/door seam that `shadow_enabled` didn't fix | **LightBlocker** | Invisible box (`cast_shadow = SHADOWS_ONLY`) — renders nothing but still occludes light in the shadow pass. No script, no collision. Scale and place directly over the leak. |

## Workflow 0 — modular level shell (walls, floors, ceilings)

For blocking out a level's architecture — not props — instance
`ModularWall`, `ModularFloor`, or `ModularCeiling` from `_Templates/`
directly into the level scene, one per wall run / floor patch / ceiling
patch. Each one is a single resizable, double-sided textured plane with
matching collision:

1. Instance the template into the level.
2. Select it → Inspector → **Mesh → Size** — set it to however long/wide
   this piece needs to be, in meters. Collision and texture tiling update
   automatically (a `@tool` script on the root does this live, no manual
   `uv1_scale` math).
3. Position/rotate the node to place it. `ModularWall`'s two Size axes are
   (width, height); `ModularFloor`/`ModularCeiling`'s are (width, depth).
4. To reskin a piece, drag a different texture onto its **Texture** export
   field (any `Assets/OfficeSurfaces/*_*.png`, or a new one). If that
   texture's native tile isn't 1m (Wall pieces are 1m × 2.5m by default),
   adjust **Meters Per Tile X/Y** to match so it doesn't stretch.

Build a room by placing walls edge-to-edge around a floor patch and a
ceiling patch sized to match — nothing needs to line up to a fixed grid,
size and position freely. This is the standard way to block out a level's
shell now; reach for Workflow A/B below for actual furniture and props,
not architecture.

## Workflow A — quick greybox (no model yet)

1. Copy the right template out of `_Templates/` into a new folder under
   `Assets/`, rename both the folder and the file to the prop's name.
2. Open it, resize the `BoxShape3D` and `BoxMesh` to roughly the right
   dimensions (they're linked by name but not by reference — resize both).
3. Fill in the Inspector fields on the root node (see reference below).
4. Instance it into a level. Swap the box for a real model later without
   touching anything else in the level — same script, same export values.

## Workflow B — real imported model (Blender → Godot)

This is the pipeline the original project used and it's proven — same steps
here:

1. In Blender: Smart UV Project, then `Ctrl+A` → Average Island Scale, pixel
   snap the UVs, paint/bake a texture (64×64 kept the original's PS1 look —
   go bigger if you're not chasing that aesthetic anymore).
2. Export as `.glb` into the prop's `Assets/<Name>/` folder.
3. On import in Godot: select the `.glb` → Import tab → set **Filter:
   Nearest, Mipmaps: Off** if you want the same low-fi pixel look as the
   original assets. Skip this if you want normal filtering.
4. Right-click the `.glb` in the FileSystem dock → **New Inherited Scene**.
5. Select the mesh → **Mesh → Create Single Convex Collision Sibling** (or
   `Create Trimesh Collision Sibling` for static geometry that's never
   walked through, like a wall).
6. Attach `Interact/interactable.gd` or `Interact/examinable.gd` to the
   scene's root node (skip for a plain EnvProp — no script needed).
7. Fill in the Inspector fields (below), save as `<Name>.tscn` in the same
   folder. Never overwrite the raw `.glb`-derived inherited scene name —
   give it the prop's real name.
8. Instance `<Name>.tscn` into a level.

## Inspector field reference

**Interactable** (and Examinable, which extends it):
- `Interact Message` — text shown in the crosshair prompt, e.g. `"Turn on"`,
  `"Pick up"`. Leave blank and it defaults to `"Interact with <node name>"`.

**Examinable** adds:
- `Display Name` — shown in the name bar across the top of the screen while
  examining, e.g. `"Old Flashlight"`.
- `Hold Rotation` — only needed if the mesh doesn't face the camera
  correctly at rotation zero when held. Leave `(0,0,0)` first, pick the item
  up in-game, and if it's facing the wrong way, open the dev console
  (backtick) and adjust in small increments — or eyeball it in the editor by
  rotating the mesh under the Body node until it looks right at rest, then
  copy that rotation here and zero out the mesh's own rotation.
- `Collect Item Id` — leave **blank** for things like a flashlight or a
  phone that should just examine-and-drop back into place. Set it to a
  short id string (e.g. `"note.map"`) only for things that should actually
  go into `GameState.inventory` and disappear from the world.

## When a prop needs more than pickup-and-look

A light switch that also turns on a light, a phone that rings, a flashlight
that toggles a beam — none of that is generic enough to belong in the shared
`interactable.gd` / `examinable.gd` scripts. For those, write a small script
that `extends Interactable` (or `extends Examinable`) next to the prop's
`.tscn` in its own folder, override `interact()` (or add your own exported
signal/behavior), and attach that instead of the base script. That's exactly
how `BadgeScanner` works in the original project — same pattern, just a
new script per special case instead of piling logic into the shared base.

## Batch-importing many props at once

For a whole Blender collection at a time (not one prop by hand), Claude
can drive both `blender.exe --background --python <script>` and
`godot.exe --headless --script <script>` directly — export every object
in a collection to its own `.glb` (origin recentered to floor level,
modifiers baked before the recenter so Mirror/Boolean modifiers referencing
outside objects don't break), then generate real per-mesh convex collision
in Godot the same way the editor's Mesh menu does. Ask for it by name
("batch export the X collection") rather than doing ~40 props one at a
time through Workflow A/B. Verify results by parsing the actual glTF JSON
(mesh counts, node transforms) rather than trusting either tool's own
success log — selection/visibility state in Blender's headless mode is
unreliable enough that it has silently produced wrong exports before.
