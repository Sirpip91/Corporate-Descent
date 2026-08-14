extends Interactable

const EMIT_SURFACE_NAME := "light emit"  # matched by name, not index — different
# lamp props order their surfaces differently (some have it at 0, some at 1)

@export var lights: Array[Light3D] = []

# NodePaths (relative to this switch), each pointing at a lamp mesh whose
# "light emit" surface this switch controls. For a separate wall switch
# pointing at a sibling lamp, prefix with "../" (e.g. "../ceiling lamp_005").
# For a script sitting directly on the lamp itself (e.g. StandingLamp), just
# the child's name with no prefix (e.g. "standing lamp").
@export var lamp_names: Array[String] = []

@export var glow_meshes: Array[MeshInstance3D] = []
@export var starts_on: bool = false

# a small always-on glow so the switch itself is findable in the dark,
# independent of whatever light it controls. Size and position are derived
# from the switch mesh's own bounding box rather than a hardcoded guess, so
# it self-centers on any switch regardless of its scale or authored axes.
@export var show_indicator: bool = true
@export var indicator_color: Color = Color(0.3, 0.65, 1.0)
@export var indicator_size: float = 0.12  # fraction of the plate's face size
# nudges the dot off the plate's surface along whichever axis is thinnest
# (the plate's depth) — flip the sign if it ends up poking into the wall
# instead of out toward the player
@export var indicator_forward_offset: float = 0.01

var _on: bool
var _glow: Array[Dictionary] = []


func _ready():
	_cache_glow_materials()
	_on = starts_on
	_apply()
	if show_indicator:
		_add_indicator()


# always emissive regardless of _on — this is a "find the switch" aid, not a
# power-state indicator, so it doesn't toggle with the light
func _add_indicator() -> void:
	var dot := MeshInstance3D.new()
	var sphere := SphereMesh.new()

	var radius := 0.01
	var center := Vector3.ZERO
	var self_node: Node = self
	var self_mesh := self_node as MeshInstance3D
	if self_mesh and self_mesh.mesh:
		var aabb := self_mesh.mesh.get_aabb()
		center = aabb.get_center()
		var size := aabb.size
		# whichever axis is thinnest is the plate's depth — push the dot out
		# along it, and size the dot relative to the other two (the face)
		var face_size: float
		if size.x <= size.y and size.x <= size.z:
			center.x += indicator_forward_offset
			face_size = min(size.y, size.z)
		elif size.y <= size.x and size.y <= size.z:
			center.y += indicator_forward_offset
			face_size = min(size.x, size.z)
		else:
			center.z += indicator_forward_offset
			face_size = min(size.x, size.y)
		radius = max(face_size * indicator_size, 0.004)

	sphere.radius = radius
	sphere.height = radius * 2.0
	dot.mesh = sphere
	dot.position = center
	dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = indicator_color
	mat.emission_enabled = true
	mat.emission = indicator_color
	mat.emission_energy_multiplier = 2.0
	dot.material_override = mat

	add_child(dot)


func _collect_glow_meshes() -> Array:
	var found := []
	for mesh in glow_meshes:
		if mesh and not found.has(mesh):
			found.append(mesh)
	for lamp_name in lamp_names:
		var node = get_node_or_null(lamp_name)
		if node is MeshInstance3D and not found.has(node):
			found.append(node)
		elif node == null:
			Dev.msg("[color=red]%s: no node at '%s'[/color]" % [name, lamp_name])
	return found


# each fixture needs its own copy of the imported material, or switching one
# lamp off dims every other mesh sharing it
func _cache_glow_materials() -> void:
	var meshes := _collect_glow_meshes()

	for mesh in meshes:
		if not mesh.mesh:
			continue
		var surface_idx := -1
		for i in mesh.mesh.get_surface_count():
			if mesh.mesh.surface_get_name(i) == EMIT_SURFACE_NAME:
				surface_idx = i
				break
		if surface_idx == -1:
			Dev.msg("[color=red]%s: no '%s' surface on %s[/color]" % [name, EMIT_SURFACE_NAME, mesh.name])
			continue
		var mat = mesh.get_active_material(surface_idx)
		if not (mat is BaseMaterial3D):
			continue
		var copy: BaseMaterial3D = mat.duplicate()
		mesh.set_surface_override_material(surface_idx, copy)
		_glow.append({
			"mat": copy,
			"energy": copy.emission_energy_multiplier,
			"emissive": copy.emission_enabled,
		})

	Dev.msg("[color=yellow]%s: %d lights, %d glow meshes, %d glow surfaces[/color]"
			% [name, lights.size(), meshes.size(), _glow.size()])


func get_interact_text():
	return "Turn off" if _on else "Turn on"


func interact(_body):
	_on = not _on
	_apply()


func _apply() -> void:
	for light in lights:
		if light:
			light.visible = _on

	for g in _glow:
		var mat: BaseMaterial3D = g["mat"]
		mat.emission_enabled = g["emissive"] and _on
		mat.emission_energy_multiplier = g["energy"] if _on else 0.0
