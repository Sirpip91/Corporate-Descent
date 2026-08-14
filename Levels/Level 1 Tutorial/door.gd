extends Interactable

@export var open_angle: float = -90.0
@export var swing_time: float = 0.6

@onready var _closed_y: float = rotation.y

var _open: bool = false
var _tween: Tween


func get_interact_text():
	return "Close" if _open else "Open"


func interact(_body):
	_open = not _open

	# retarget mid-swing rather than letting two tweens fight over rotation
	if _tween and _tween.is_running():
		_tween.kill()

	var target: float = _closed_y
	if _open:
		target += deg_to_rad(open_angle)

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "rotation:y", target, swing_time)
