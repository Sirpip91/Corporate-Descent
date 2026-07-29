extends RayCast3D

const DWELL_THRESHOLD: float = 2.0

@onready var InteractText = $Label
var default_color = Color.WHITE

var _dwell_target = null
var _dwell_time: float = 0.0

func _physics_process(delta):
	if is_colliding():
		var target = get_collider()

		# climb up until we find Interactable
		while target and not (target is Interactable):
			target = target.get_parent()

		if target is Interactable:
			UI.hide_crosshair("hover")
			InteractText.text = target.get_interact_text()
			InteractText.modulate = default_color

			# dwell tracking — reserved for future use (e.g. auto-fire on long look)
			if target == _dwell_target:
				_dwell_time += delta
			else:
				_dwell_target = target
				_dwell_time = 0.0

			if Input.is_action_just_pressed("commit_choice") and not ExamineController.active:
				target.interact(owner)
				clear_text()
			return

	# looked away — reset dwell and restore crosshair
	UI.show_crosshair("hover")
	_dwell_target = null
	_dwell_time = 0.0
	clear_text()


func clear_text():
	InteractText.text = ""
	InteractText.modulate = default_color
