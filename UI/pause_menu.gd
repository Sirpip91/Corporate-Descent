extends ColorRect

@onready var animator:          AnimationPlayer = $AnimationPlayer
@onready var resume_button:     Button          = find_child("Resume")
@onready var quit_button:       Button          = find_child("Quit")
@onready var fps_counter_check: CheckBox        = find_child("FpsCounter")

# Active panels
var _main_panel:     Control  # the scene's existing VBoxContainer
var _options_panel:  Control
var _graphics_panel: Control
var _sound_panel:    Control
var _controls_panel: Control

# Graphics panel refs (needed for Apply)
var _res_option: OptionButton
var _fs_check:   CheckBox

# Sound panel refs
var _master_vol_label: Label
var _music_vol_label:  Label

# Controls panel refs
var _sens_label: Label

const _RESOLUTIONS: Array = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]


func _ready() -> void:
	resume_button.pressed.connect(_unpause)
	quit_button.pressed.connect(get_tree().quit)
	fps_counter_check.toggled.connect(_on_fps_toggled)

	_main_panel = find_child("VBoxContainer") as VBoxContainer
	_add_options_button_to_main()

	_options_panel  = _build_options_panel()
	_graphics_panel = _build_graphics_panel()
	_sound_panel    = _build_sound_panel()
	_controls_panel = _build_controls_panel()

	add_child(_options_panel.get_parent())
	add_child(_graphics_panel.get_parent())
	add_child(_sound_panel.get_parent())
	add_child(_controls_panel.get_parent())

	_show_panel(_main_panel)


# Injects Options button into the scene VBoxContainer and pins Quit to the bottom.
func _add_options_button_to_main() -> void:
	fps_counter_check.visible = false
	_main_panel.custom_minimum_size.y = 480

	var sep := HSeparator.new()
	var options_btn := Button.new()
	options_btn.text = "Options"
	options_btn.add_theme_font_size_override("font_size", 28)
	options_btn.pressed.connect(func(): _show_panel(_options_panel))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var quit_sep := HSeparator.new()

	# Insert each node just before Quit, re-reading the index each time
	for node in [sep, options_btn, spacer, quit_sep]:
		_main_panel.add_child(node)
		_main_panel.move_child(node, quit_button.get_index())


# ── Panel factory helpers ──────────────────────────────────────────────────────

# Returns the inner VBoxContainer. Call get_parent() on it to get the full-rect
# CenterContainer wrapper that should be added to self.
func _make_panel() -> VBoxContainer:
	var wrapper := CenterContainer.new()
	wrapper.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrapper.mouse_filter = Control.MOUSE_FILTER_PASS

	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(420, 480)
	panel.add_theme_constant_override("separation", 8)
	wrapper.add_child(panel)
	return panel


func _add_back_button(panel: VBoxContainer, to: Control) -> void:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(spacer)
	panel.add_child(HSeparator.new())
	var btn := Button.new()
	btn.text = "< Back"
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(func(): _show_panel(to))
	panel.add_child(btn)


func _add_section_label(panel: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(lbl)
	panel.add_child(HSeparator.new())


# ── Options root panel ─────────────────────────────────────────────────────────

func _build_options_panel() -> VBoxContainer:
	var panel := _make_panel()

	_add_section_label(panel, "Options")

	for label_text in ["Graphics", "Sound", "Controls"]:
		var btn := Button.new()
		btn.text = label_text
		btn.custom_minimum_size = Vector2(0, 48)
		btn.add_theme_font_size_override("font_size", 26)
		btn.pressed.connect(func(): _show_panel(_panel_for(label_text)))
		panel.add_child(btn)

	_add_back_button(panel, _main_panel)
	return panel


func _panel_for(label_text: String) -> Control:
	match label_text:
		"Graphics": return _graphics_panel
		"Sound":    return _sound_panel
		"Controls": return _controls_panel
	return _options_panel


# ── Graphics panel ─────────────────────────────────────────────────────────────

func _build_graphics_panel() -> VBoxContainer:
	var panel := _make_panel()

	_add_section_label(panel, "Graphics")

	# FPS counter
	var fps_row := fps_counter_check.duplicate() as CheckBox
	fps_row.text = "Show FPS Counter"
	fps_row.add_theme_font_size_override("font_size", 22)
	fps_row.button_pressed = fps_counter_check.button_pressed
	fps_row.toggled.connect(_on_fps_toggled)
	panel.add_child(fps_row)

	panel.add_child(HSeparator.new())

	var is_fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN \
		or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

	# Resolution
	var res_lbl := Label.new()
	res_lbl.text = "Resolution"
	res_lbl.add_theme_font_size_override("font_size", 22)
	panel.add_child(res_lbl)

	var screen_size  := DisplayServer.screen_get_size()
	# In fullscreen show the monitor's native res; windowed show the actual window size
	var current_size := screen_size if is_fullscreen else DisplayServer.window_get_size()
	_res_option = OptionButton.new()
	_res_option.custom_minimum_size = Vector2(0, 36)
	_res_option.add_theme_font_size_override("font_size", 20)
	var current_idx := 0
	var added := 0
	for i in _RESOLUTIONS.size():
		var r: Vector2i = _RESOLUTIONS[i]
		if r.x <= screen_size.x and r.y <= screen_size.y:
			_res_option.add_item("%d × %d" % [r.x, r.y], i)
			if r == current_size:
				current_idx = added
			added += 1
	_res_option.selected = current_idx
	_res_option.disabled = is_fullscreen
	panel.add_child(_res_option)

	# Fullscreen
	_fs_check = CheckBox.new()
	_fs_check.text = "Fullscreen"
	_fs_check.add_theme_font_size_override("font_size", 22)
	_fs_check.button_pressed = is_fullscreen
	_fs_check.toggled.connect(func(on: bool) -> void:
		_res_option.disabled = on
		if on:
			var native := DisplayServer.screen_get_size()
			for i in _res_option.item_count:
				if _RESOLUTIONS[_res_option.get_item_id(i)] == native:
					_res_option.selected = i
					break
	)
	panel.add_child(_fs_check)

	panel.add_child(HSeparator.new())

	# Apply
	var apply_btn := Button.new()
	apply_btn.text = "Apply"
	apply_btn.custom_minimum_size = Vector2(0, 40)
	apply_btn.add_theme_font_size_override("font_size", 22)
	apply_btn.pressed.connect(_on_apply_pressed)
	panel.add_child(apply_btn)

	_add_back_button(panel, _options_panel)
	return panel


# ── Sound panel ────────────────────────────────────────────────────────────────

func _build_sound_panel() -> VBoxContainer:
	var panel := _make_panel()

	_add_section_label(panel, "Sound")

	# Master volume
	_master_vol_label = Label.new()
	_master_vol_label.text = "Master Volume: %.0f%%" % (GameState.master_volume * 100.0)
	_master_vol_label.add_theme_font_size_override("font_size", 22)
	panel.add_child(_master_vol_label)

	var master_slider := HSlider.new()
	master_slider.min_value = 0.0
	master_slider.max_value = 1.0
	master_slider.step      = 0.05
	master_slider.value     = GameState.master_volume
	master_slider.custom_minimum_size = Vector2(0, 32)
	master_slider.value_changed.connect(_on_master_volume_changed)
	panel.add_child(master_slider)

	panel.add_child(HSeparator.new())

	# Music volume (placeholder — wire up when music bus exists)
	_music_vol_label = Label.new()
	_music_vol_label.text = "Music Volume: 100%"
	_music_vol_label.add_theme_font_size_override("font_size", 22)
	panel.add_child(_music_vol_label)

	var music_slider := HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step      = 0.05
	music_slider.value     = 1.0
	music_slider.custom_minimum_size = Vector2(0, 32)
	music_slider.value_changed.connect(_on_music_volume_changed)
	panel.add_child(music_slider)

	_add_back_button(panel, _options_panel)
	return panel


# ── Controls panel ─────────────────────────────────────────────────────────────

func _build_controls_panel() -> VBoxContainer:
	var panel := _make_panel()

	_add_section_label(panel, "Controls")

	# Mouse sensitivity
	_sens_label = Label.new()
	_sens_label.text = "Mouse Sensitivity: %.0f%%" % (GameState.mouse_sensitivity / 0.01 * 100.0)
	_sens_label.add_theme_font_size_override("font_size", 22)
	panel.add_child(_sens_label)

	var sens_slider := HSlider.new()
	sens_slider.min_value = 0.001
	sens_slider.max_value = 0.010
	sens_slider.step      = 0.0005
	sens_slider.value     = GameState.mouse_sensitivity
	sens_slider.custom_minimum_size = Vector2(0, 32)
	sens_slider.value_changed.connect(_on_sensitivity_changed)
	panel.add_child(sens_slider)

	_add_back_button(panel, _options_panel)
	return panel


# ── Navigation ─────────────────────────────────────────────────────────────────

func _show_panel(panel: Control) -> void:
	_main_panel.visible                    = false
	_options_panel.get_parent().visible    = false
	_graphics_panel.get_parent().visible   = false
	_sound_panel.get_parent().visible      = false
	_controls_panel.get_parent().visible   = false
	if panel == _main_panel:
		_main_panel.visible = true
	else:
		panel.get_parent().visible = true


# ── Callbacks ──────────────────────────────────────────────────────────────────

func _on_fps_toggled(on: bool) -> void:
	UI.set_fps_visible(on)


func _on_master_volume_changed(value: float) -> void:
	GameState.master_volume = value
	_master_vol_label.text = "Master Volume: %.0f%%" % (value * 100.0)
	var db := linear_to_db(value) if value > 0.0 else -80.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)


func _on_music_volume_changed(value: float) -> void:
	_music_vol_label.text = "Music Volume: %.0f%%" % (value * 100.0)
	# TODO: wire to Music bus when added


func _on_sensitivity_changed(value: float) -> void:
	GameState.mouse_sensitivity = value
	_sens_label.text = "Mouse Sensitivity: %.0f%%" % (value / 0.01 * 100.0)


func _on_apply_pressed() -> void:
	if _fs_check.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var item_id := _res_option.get_item_id(_res_option.selected)
		var res: Vector2i = _RESOLUTIONS[item_id]
		DisplayServer.window_set_size(res)
		var screen_size := DisplayServer.screen_get_size()
		DisplayServer.window_set_position((screen_size - res) / 2)


# ── Pause / Unpause ────────────────────────────────────────────────────────────

func _unpause() -> void:
	_show_panel(_main_panel)
	animator.play("Unpause")
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _pause() -> void:
	_show_panel(_main_panel)
	animator.play("Pause")
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
