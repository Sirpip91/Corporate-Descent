extends CanvasLayer
# Autoloaded as "Dev". Toggle with the backtick/tilde key (`).
# Trimmed for the systems-only rebuild — no dialogue mute commands since
# there's no dialogue system yet. Add commands here as real systems land.

var _panel: Panel
var _output: RichTextLabel
var _input_line: LineEdit
var _open: bool = false

var _fullbright: bool = false
var _cached_ambient_energy: float = 0.0
var _cached_tonemap: int = 0


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	msg("[color=cyan]Dev console ready. Type [b]help[/b] for commands.[/color]")


func _build_ui() -> void:
	_panel = Panel.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_panel.offset_bottom = 350.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.04, 0.88)
	style.border_color = Color(0.2, 0.2, 0.2, 1.0)
	style.set_border_width_all(1)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	_output = RichTextLabel.new()
	_output.bbcode_enabled = true
	_output.scroll_following = true
	_output.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_output.offset_left = 6
	_output.offset_right = -6
	_output.offset_top = 4
	_output.offset_bottom = -36
	_output.add_theme_font_size_override("normal_font_size", 13)
	_output.add_theme_color_override("default_color", Color.WHITE)
	_panel.add_child(_output)

	_input_line = LineEdit.new()
	_input_line.placeholder_text = "command..."
	_input_line.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_input_line.offset_top = -30
	_input_line.offset_bottom = -4
	_input_line.offset_left = 4
	_input_line.offset_right = -4
	_input_line.text_submitted.connect(_on_command)
	_panel.add_child(_input_line)

	_panel.hide()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_QUOTELEFT:
			_open = !_open
			_panel.visible = _open
			if not _open:
				_input_line.release_focus()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_F9:
			_toggle_fullbright()


func _on_command(text: String) -> void:
	var cmd := text.strip_edges().to_lower()
	_input_line.clear()
	_input_line.release_focus()
	if cmd == "":
		return

	msg("[color=#555555]> %s[/color]" % cmd)

	match cmd:
		"inventory":
			msg("[color=cyan]Inventory: %s[/color]" % str(GameState.inventory))
		"fullbright":
			_toggle_fullbright()
		"help":
			msg("[color=cyan]  inventory — show GameState.inventory[/color]")
			msg("[color=cyan]  fullbright — crank ambient light for dev viewing (or press F9 anytime)[/color]")
		_:
			msg("[color=red]Unknown command '%s' — type help[/color]" % cmd)


func msg(text: String) -> void:
	print(text)
	var re := RegEx.new()
	re.compile("\\[.+?\\]")
	_output.append_text(re.sub(text, "", true) + "\n")


func _toggle_fullbright() -> void:
	var world_env = get_tree().get_first_node_in_group("world_environment")
	if not world_env or not world_env.environment:
		msg("[color=red][Dev] No WorldEnvironment in this scene[/color]")
		return

	var env: Environment = world_env.environment
	_fullbright = !_fullbright

	if _fullbright:
		_cached_ambient_energy = env.ambient_light_energy
		_cached_tonemap = env.tonemap_mode
		env.ambient_light_energy = 4.0
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	else:
		env.ambient_light_energy = _cached_ambient_energy
		env.tonemap_mode = _cached_tonemap

	msg("[color=yellow][Dev] Fullbright %s[/color]" % ("ON" if _fullbright else "OFF"))
