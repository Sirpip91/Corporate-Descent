extends NPCBase

## --- Appearance --------------------------------------------------------
## Swaps between the 6 skin/clothing pairs that ship with the character
## pack. Rename this NPC's own node in the Scene tree for identification
## (e.g. "Denise") — this only controls which of the 6 premade looks it
## wears.
enum Look { VARIANT_1, VARIANT_2, VARIANT_3, VARIANT_4, VARIANT_5, VARIANT_6 }

const TEXTURES = {
	Look.VARIANT_1: {"clothing": "res://Assets/Characters/Textures/clothing-female1.png", "skin": "res://Assets/Characters/Textures/skin-female1.png"},
	Look.VARIANT_2: {"clothing": "res://Assets/Characters/Textures/clothing-female2.png", "skin": "res://Assets/Characters/Textures/skin-female2.png"},
	Look.VARIANT_3: {"clothing": "res://Assets/Characters/Textures/clothing-female3.png", "skin": "res://Assets/Characters/Textures/skin-female3.png"},
	Look.VARIANT_4: {"clothing": "res://Assets/Characters/Textures/clothing-female4.png", "skin": "res://Assets/Characters/Textures/skin-female4.png"},
	Look.VARIANT_5: {"clothing": "res://Assets/Characters/Textures/clothing-female5.png", "skin": "res://Assets/Characters/Textures/skin-female5.png"},
	Look.VARIANT_6: {"clothing": "res://Assets/Characters/Textures/clothing-female6.png", "skin": "res://Assets/Characters/Textures/skin-female6.png"},
}

@export var look: Look = Look.VARIANT_1:
	set(value):
		look = value
		_apply_look()

@onready var mesh_instance: MeshInstance3D = find_child("character1", true, false)


func _apply_look() -> void:
	if not mesh_instance:
		return
	var data = TEXTURES.get(look)
	if not data:
		return
	_set_surface_texture("clothing-female1", data.clothing)
	_set_surface_texture("skin-female1", data.skin)


func _set_surface_texture(material_name: String, texture_path: String) -> void:
	var surface = _find_surface(mesh_instance, material_name)
	if surface == -1:
		return
	# duplicate before editing — the base material is shared by every
	# NPCFemale1 instance, so mutating it directly would recolor all of
	# them at once
	var mat = mesh_instance.mesh.surface_get_material(surface).duplicate()
	mat.albedo_texture = load(texture_path)
	mesh_instance.set_surface_override_material(surface, mat)


func _find_surface(mi: MeshInstance3D, material_name: String) -> int:
	for i in mi.mesh.get_surface_count():
		var mat = mi.mesh.surface_get_material(i)
		if mat and mat.resource_name == material_name:
			return i
	return -1
