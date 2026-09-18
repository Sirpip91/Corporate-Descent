extends Interactable

@onready var anim: AnimationPlayer = $AnimationPlayer

var is_open := false


func get_interact_text():
	if is_open:
		return "Close Door"
	return "Open Door"


func interact(_body):
	toggle()


func open() -> void:
	if is_open:
		return
	is_open = true
	anim.play("door_open")


func close() -> void:
	if not is_open:
		return
	is_open = false
	anim.play("door_open", -1, -1.0, true)


func toggle() -> void:
	if is_open:
		close()
	else:
		open()
