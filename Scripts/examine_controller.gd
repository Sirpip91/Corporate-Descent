extends Node
# Autoloaded as "ExamineController".
# Handles picking up objects, displaying them in camera space, spinning, and dropping.

var active: bool = false

var _target: Node3D = null
var _original_parent: Node = null
var _original_global_transform: Transform3D = Transform3D()
var _camera: Node3D = null
var _player: Node3D = null

# Saved collision data for each CollisionObject3D found in the target's direct children.
# Cleared and restored on end() so the item returns to normal physics after dropping.
var _saved_collision: Array = []  # Array of {node, layer, mask}

# Where the item rests in front of the camera. Z = distance from face (less negative = closer to screen).
const HOLD_POSITION  := Vector3(0.0, 0.0, -0.60)
# Item starts below and slides up to HOLD_POSITION — gives the pickup a lift-up feel.
const ENTRY_POSITION := Vector3(0.0, -1.20, -0.60)

const ROTATE_SPEED := 0.006
const ZOOM_STEP    := 0.05
const ZOOM_NEAR    := -0.30  # closest the item can get to the screen
const ZOOM_FAR     := -0.90  # furthest the item can be from the screen

var _hold_z: float = -0.60
var _zoom_tween: Tween


func begin(target: Node3D) -> void:
	if active:
		return

	_player = get_tree().get_first_node_in_group("player")
	if not _player:
		return
	_camera = _player.get_node_or_null("Head/Camera3D")
	if not _camera:
		return

	_target                    = target
	_original_parent           = target.get_parent()
	_original_global_transform = target.global_transform

	active                   = true
	_player.movement_locked  = true
	_player.examining        = true

	# Disable collision on all direct CollisionObject3D children before reparenting.
	# Without this, the StaticBody3D ends up inside the player capsule and physics
	# launches the player across the room.
	_saved_collision.clear()
	for child in target.get_children():
		if child is CollisionObject3D:
			_saved_collision.append({"node": child, "layer": child.collision_layer, "mask": child.collision_mask})
			child.collision_layer = 0
			child.collision_mask  = 0

	# Reparent to camera without preserving transform, then snap to entry position.
	# The snap happens before the first rendered frame, so it's invisible.
	target.reparent(_camera, false)

	# Honor a per-object held rotation if the Examinable exports one.
	target.rotation = target.get("hold_rotation") if "hold_rotation" in target else Vector3.ZERO
	target.position = ENTRY_POSITION

	var tween := _camera.create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.tween_property(target, "position", HOLD_POSITION, 0.30)

	_hold_z = HOLD_POSITION.z

	UI.hide_crosshair("examine")
	var can_collect: bool = ("collect_item_id" in target) and target.collect_item_id != ""
	var display_name: String = target.get("display_name") if "display_name" in target else ""
	UI.show_examine_hints(can_collect, display_name)
	Dev.msg("[color=cyan][Examine] Began: %s[/color]" % target.name)


func is_collectible() -> bool:
	if not is_instance_valid(_target): return false
	var item_id: String = _target.get("collect_item_id") if "collect_item_id" in _target else ""
	return item_id != ""


func end(collect: bool = true) -> void:
	if not active:
		return
	active = false

	if is_instance_valid(_player):
		_player.movement_locked = false
		_player.examining       = false

	if not is_instance_valid(_target):
		_target = null
		return

	# Capture locals — _target gets cleared before the tween callback fires.
	var target         := _target
	var orig_parent    := _original_parent
	var orig_transform := _original_global_transform
	var item_id: String = target.get("collect_item_id") if "collect_item_id" in target else ""
	var item_display_name: String = target.get("display_name") if "display_name" in target else ""
	_target = null
	UI.hide_examine_hints()
	UI.show_crosshair("examine")
	if _zoom_tween:
		_zoom_tween.kill()
	_zoom_tween = null

	var tween := _camera.create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "position", ENTRY_POSITION, 0.18)

	var saved := _saved_collision.duplicate()
	_saved_collision.clear()

	if item_id != "" and collect:
		# Collectible and player chose to pocket — remove from world.
		tween.tween_callback(func() -> void:
			GameState.add_item(item_id, item_display_name)
			if is_instance_valid(target) and is_instance_valid(orig_parent):
				target.reparent(orig_parent, false)
				target.global_transform = orig_transform
				target.visible = false
			Dev.msg("[color=green][Examine] Pocketed: %s[/color]" % item_id)
		)
	else:
		# Non-collectible OR player chose to drop — restore collision and return.
		tween.tween_callback(func() -> void:
			for entry in saved:
				var col := entry["node"] as CollisionObject3D
				if is_instance_valid(col):
					col.collision_layer = entry["layer"]
					col.collision_mask  = entry["mask"]
			if is_instance_valid(target) and is_instance_valid(orig_parent):
				target.reparent(orig_parent, false)
				target.global_transform = orig_transform
		)

	Dev.msg("[color=cyan][Examine] Ended[/color]")


func rotate(delta: Vector2) -> void:
	if not active or not is_instance_valid(_target):
		return
	if abs(delta.x) >= abs(delta.y):
		_target.global_rotate(_camera.global_basis.y, -delta.x * ROTATE_SPEED)
	else:
		_target.global_rotate(_camera.global_basis.x, -delta.y * ROTATE_SPEED)


func _unhandled_input(event: InputEvent) -> void:
	if not active or not is_instance_valid(_target):
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_hold_z = clamp(_hold_z + ZOOM_STEP, ZOOM_FAR, ZOOM_NEAR)
			_zoom_to(_hold_z)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_hold_z = clamp(_hold_z - ZOOM_STEP, ZOOM_FAR, ZOOM_NEAR)
			_zoom_to(_hold_z)
			get_viewport().set_input_as_handled()


func _zoom_to(z: float) -> void:
	if _zoom_tween:
		_zoom_tween.kill()
	_zoom_tween = _camera.create_tween()
	_zoom_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	_zoom_tween.tween_property(_target, "position", Vector3(0.0, 0.0, z), 0.12)
