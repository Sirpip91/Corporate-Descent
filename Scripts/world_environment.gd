extends WorldEnvironment
# Groups itself so Dev.msg-driven tools (fullbright toggle) can find whichever
# level's environment is active without a per-scene reference.

func _ready() -> void:
	add_to_group("world_environment")
	if environment:
		set_meta("base_volumetric_fog", environment.volumetric_fog_enabled)
	GameState.apply_graphics_settings()
