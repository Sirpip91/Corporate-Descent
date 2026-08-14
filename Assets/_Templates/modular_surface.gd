@tool
extends MeshInstance3D

## Resize this node's mesh (Mesh > Size in the Inspector) to whatever span
## this wall/floor/ceiling piece needs to cover. Texture tiling and collision
## follow automatically. Assign a different texture below to reskin it.
@export var texture: Texture2D:
	set(value):
		texture = value
		_dirty = true

## How many meters one texture repeat covers, per axis of the plane's own
## Size — e.g. the Wall texture is authored 1m wide x 2.5m tall per tile.
@export var meters_per_tile_x: float = 1.0:
	set(value):
		meters_per_tile_x = value
		_dirty = true
@export var meters_per_tile_y: float = 1.0:
	set(value):
		meters_per_tile_y = value
		_dirty = true

var _mat: StandardMaterial3D
var _last_size := Vector2.ZERO
var _dirty := true


func _ready() -> void:
	_sync()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if mesh is PlaneMesh and (mesh.size != _last_size or _dirty):
		_sync()


func _sync() -> void:
	if not (mesh is PlaneMesh):
		return
	var plane: PlaneMesh = mesh
	_last_size = plane.size
	_dirty = false

	var shape_node := get_node_or_null("StaticBody3D/CollisionShape3D")
	if shape_node and shape_node.shape is BoxShape3D:
		shape_node.shape.size = Vector3(plane.size.x, 0.1, plane.size.y)

	if not _mat:
		_mat = StandardMaterial3D.new()
		material_override = _mat
	_mat.albedo_texture = texture
	_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.uv1_scale = Vector3(plane.size.x / meters_per_tile_x, plane.size.y / meters_per_tile_y, 1.0)
