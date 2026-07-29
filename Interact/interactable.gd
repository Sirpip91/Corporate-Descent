extends Node3D
class_name Interactable

@export var interact_message: String = ""

func get_interact_text():
	if interact_message != "":
		return interact_message
	return "Interact with " + name

func interact(body):
	Dev.msg("[color=#888888]%s interacted with %s[/color]" % [body.name, name])
