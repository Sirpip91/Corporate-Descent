extends Node
# Autoloaded as "GameState".
# Trimmed for the systems-only rebuild: just settings + a bare inventory.
# Level/story-specific state (floor tracking, keycards, loop counter) lives
# in the original Corporate-Descent project and gets re-added here per-feature
# as real levels come back in.

signal item_added(item_id: String, display_name: String)
signal item_removed(item_id: String)

var inventory: Array[String] = []

# ── Settings (persist across scenes) ─────────────────────────────────────────
var mouse_sensitivity: float = 0.004
var master_volume: float = 1.0


func has_item(id: String) -> bool:
	return id in inventory


func add_item(id: String, display_name: String = "") -> void:
	if not has_item(id):
		inventory.append(id)
		item_added.emit(id, display_name)
		Dev.msg("[color=green][GameState] Item added: %s | inventory: %s[/color]" % [id, str(inventory)])


func remove_item(id: String) -> void:
	inventory.erase(id)
	item_removed.emit(id)
	Dev.msg("[color=yellow][GameState] Item removed: %s | inventory: %s[/color]" % [id, str(inventory)])
