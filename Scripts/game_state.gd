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
var volumetric_fog_enabled: bool = true


# Re-derives the active WorldEnvironment's volumetric fog from (the level's own
# authored setting) AND (the player's preference) — this can only turn a
# level's fog off, never turn it on for a level that wasn't built with it.
func apply_graphics_settings() -> void:
	var world_env := get_tree().get_first_node_in_group("world_environment")
	if world_env and world_env.environment and world_env.has_meta("base_volumetric_fog"):
		world_env.environment.volumetric_fog_enabled = \
			world_env.get_meta("base_volumetric_fog") and volumetric_fog_enabled


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
