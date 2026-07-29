# Assets — Import & Prop Workflow

One folder per asset, same convention the original Corporate-Descent project
already used (`Assets/AlarmClock/`, `Assets/Badge/`, etc.):

```
Assets/
  _Templates/         ← copy from here, never edit these directly
    EnvProp.tscn        — decoration/collision only, not interactive
    Interactable.tscn   — press F, something happens (no pickup)
    Examinable.tscn      — press F to pick up, hold, rotate, zoom, maybe collect
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

## Which template for which prop

| You're making... | Use | Why |
|---|---|---|
| Wall, chair, table, shelf, floor clutter — anything just standing there | **EnvProp** | Player walks around/on it. No script, no interact prompt. |
| Light switch, button, lever, door, elevator panel | **Interactable** | Player presses F, something happens once. No pickup — usually needs a small custom script (see below). |
| Phone, flashlight, picture, note, badge, any handheld item | **Examinable** | Player presses F to pick it up, hold it in front of the camera, rotate with the mouse, scroll to zoom, and either drop it or (if `collect_item_id` is set) pocket it. |

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
