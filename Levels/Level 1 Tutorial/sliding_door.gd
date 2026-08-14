extends Interactable

@export var slide_axis: Vector3 = Vector3.RIGHT
@export var slide_distance: float = 0.8
@export var slide_time: float = 0.7

# set on both halves of a pair so either one drives the other
@export var partner_path: NodePath

@onready var _closed_pos: Vector3 = position
@onready var _offset: Vector3 = (transform.basis * slide_axis.normalized()) * slide_distance

var _open: bool = false
var _tween: Tween


func get_interact_text():
	return "Close" if _open else "Open"


func interact(_body):
	set_open(not _open)

	var partner := get_node_or_null(partner_path)
	if partner and partner.has_method("set_open"):
		partner.set_open(_open)


func set_open(value: bool) -> void:
	_open = value

	# retarget mid-slide rather than letting two tweens fight over position
	if _tween and _tween.is_running():
		_tween.kill()

	var target: Vector3 = _closed_pos
	if _open:
		target += _offset

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "position", target, slide_time)
