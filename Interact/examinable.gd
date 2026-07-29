extends Interactable
class_name Examinable

# Shown on screen while examining, and as the label if it's collected.
@export var display_name: String = ""

# Override if the mesh doesn't naturally face the camera at rotation zero.
# Example: Vector3(-PI/2, 0, 0) tilts a flat card so its face shows.
@export var hold_rotation: Vector3 = Vector3.ZERO

# If set, the item goes to inventory (and hides from the scene) when the player drops it.
# Leave empty for non-collectible items that always return to their world position.
@export var collect_item_id: String = ""


func _ready() -> void:
	if interact_message == "":
		interact_message = "examine"


func interact(_body) -> void:
	ExamineController.begin(self)
