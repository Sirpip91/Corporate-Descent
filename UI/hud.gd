extends CanvasLayer
# Autoloaded as "UI".
#
# Trimmed for the systems-only rebuild: crosshair, examine hints, FPS counter.
# The original project's inner_monologue.gd also drives a dialogue queue
# (say/say_ambient) and an inventory HUD — narrative-specific, not part of
# "basic player mechanics," left out until real levels/story come back in.

var _fps_label: Label
var _examine_hints: VBoxContainer
var _examine_name_label: Label
var _examine_name_bg: ColorRect
var _crosshair_outer: ColorRect
var _crosshair_inner: ColorRect
var _crosshair_hidden: Array[String] = []  # reasons crosshair is hidden — visible only when empty


func _ready() -> void:
	layer = 10

	# FPS counter — top-right, hidden until toggled from pause menu
	_fps_label = Label.new()
	_fps_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_fps_label.offset_left   = -120
	_fps_label.offset_right  = -10
	_fps_label.offset_top    = 10
	_fps_label.offset_bottom = 36
	_fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fps_label.visible = false
	var fps_settings := LabelSettings.new()
	fps_settings.font_size   = 16
	fps_settings.font_color  = Color(0.9, 0.9, 0.9, 0.85)
	fps_settings.shadow_color  = Color(0, 0, 0, 0.9)
	fps_settings.shadow_size   = 2
	fps_settings.shadow_offset = Vector2(1, 1)
	_fps_label.label_settings = fps_settings
	add_child(_fps_label)

	# Crosshair dot — dark outline behind white dot for visibility on any background
	_crosshair_outer = ColorRect.new()
	_crosshair_outer.color = Color(0.0, 0.0, 0.0, 0.6)
	_crosshair_outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crosshair_outer.anchor_left   = 0.5; _crosshair_outer.anchor_top    = 0.5
	_crosshair_outer.anchor_right  = 0.5; _crosshair_outer.anchor_bottom = 0.5
	_crosshair_outer.offset_left   = -3;  _crosshair_outer.offset_top    = -3
	_crosshair_outer.offset_right  =  3;  _crosshair_outer.offset_bottom =  3
	add_child(_crosshair_outer)

	_crosshair_inner = ColorRect.new()
	_crosshair_inner.color = Color(1.0, 1.0, 1.0, 0.9)
	_crosshair_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crosshair_inner.anchor_left   = 0.5; _crosshair_inner.anchor_top    = 0.5
	_crosshair_inner.anchor_right  = 0.5; _crosshair_inner.anchor_bottom = 0.5
	_crosshair_inner.offset_left   = -2;  _crosshair_inner.offset_top    = -2
	_crosshair_inner.offset_right  =  2;  _crosshair_inner.offset_bottom =  2
	add_child(_crosshair_inner)

	# ── EXAMINE HINTS CONTAINER ──────────────────────────────────────────────
	# Left-side HUD hints: [F], [Esc], [Scroll] — kept out of the center so
	# they don't overlap the examined object.
	_examine_hints = VBoxContainer.new()
	_examine_hints.anchor_left   = 0.0
	_examine_hints.anchor_right  = 0.0
	_examine_hints.anchor_top    = 1.0
	_examine_hints.anchor_bottom = 1.0
	_examine_hints.offset_left   = 30
	_examine_hints.offset_right  = 360
	_examine_hints.offset_top    = -190
	_examine_hints.offset_bottom = -30
	_examine_hints.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	_examine_hints.visible = false
	add_child(_examine_hints)

	# ── EXAMINE DISPLAY NAME — top-center bar ────────────────────────────────
	_examine_name_bg = ColorRect.new()
	_examine_name_bg.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_examine_name_bg.offset_top    = 0
	_examine_name_bg.offset_bottom = 72
	_examine_name_bg.color = Color(0.0, 0.0, 0.0, 0.55)
	_examine_name_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_examine_name_bg.modulate.a = 0.0
	add_child(_examine_name_bg)

	_examine_name_label = Label.new()
	_examine_name_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_examine_name_label.offset_top    = 0
	_examine_name_label.offset_bottom = 72
	_examine_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_examine_name_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_examine_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_examine_name_label.modulate.a = 0.0
	var name_ls := LabelSettings.new()
	name_ls.font_size     = 32
	name_ls.font_color    = Color(1.0, 1.0, 1.0)
	name_ls.shadow_color  = Color(0.0, 0.0, 0.0, 1.0)
	name_ls.shadow_size   = 2
	name_ls.shadow_offset = Vector2(1, 1)
	_examine_name_label.label_settings = name_ls
	add_child(_examine_name_label)


func _process(_delta: float) -> void:
	if _fps_label.visible:
		_fps_label.text = "FPS: %d" % Engine.get_frames_per_second()


func set_fps_visible(visible: bool) -> void:
	_fps_label.visible = visible


# ── CROSSHAIR ────────────────────────────────────────────────────────────────
# Use named reasons so multiple systems can hide the crosshair independently.
# Examples: "examine", "hover". Crosshair is visible only when no reasons remain.

func hide_crosshair(reason: String) -> void:
	if reason not in _crosshair_hidden:
		_crosshair_hidden.append(reason)
	_crosshair_outer.visible = false
	_crosshair_inner.visible = false


func show_crosshair(reason: String) -> void:
	_crosshair_hidden.erase(reason)
	if _crosshair_hidden.is_empty():
		_crosshair_outer.visible = true
		_crosshair_inner.visible = true


# ── EXAMINE HINTS ────────────────────────────────────────────────────────────

func show_examine_hints(can_collect: bool, item_name: String = "") -> void:
	for child in _examine_hints.get_children():
		child.queue_free()
	if can_collect:
		_add_hint("[F]", "Put in inventory")
		_add_hint("[Esc]", "Stop examining")
	else:
		_add_hint("[F]", "Stop examining")
	_add_hint("[Scroll]", "Zoom in / out")
	_examine_hints.visible = true
	_examine_hints.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_examine_hints, "modulate:a", 1.0, 0.2)

	if item_name != "":
		_examine_name_label.text = item_name
		_examine_name_label.modulate.a = 0.0
		_examine_name_bg.modulate.a = 0.0
		var t2 := create_tween()
		t2.tween_property(_examine_name_label, "modulate:a", 1.0, 0.2)
		var t3 := create_tween()
		t3.tween_property(_examine_name_bg, "modulate:a", 1.0, 0.2)
	else:
		_examine_name_label.modulate.a = 0.0
		_examine_name_bg.modulate.a = 0.0


func hide_examine_hints() -> void:
	if not _examine_hints.visible:
		return
	var t := create_tween()
	t.tween_property(_examine_hints, "modulate:a", 0.0, 0.15)
	t.tween_callback(func(): _examine_hints.visible = false)
	var t2 := create_tween()
	t2.tween_property(_examine_name_label, "modulate:a", 0.0, 0.15)
	var t3 := create_tween()
	t3.tween_property(_examine_name_bg, "modulate:a", 0.0, 0.15)


func _add_hint(key: String, action: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var key_lbl := Label.new()
	key_lbl.text = key
	key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var key_ls := LabelSettings.new()
	key_ls.font_size     = 18
	key_ls.font_color    = Color(0.90, 0.80, 0.40)
	key_ls.shadow_color  = Color(0.0, 0.0, 0.0, 0.95)
	key_ls.shadow_size   = 2
	key_ls.shadow_offset = Vector2(1, 1)
	key_lbl.label_settings = key_ls
	hbox.add_child(key_lbl)

	var action_lbl := Label.new()
	action_lbl.text = "  " + action
	action_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var action_ls := LabelSettings.new()
	action_ls.font_size     = 18
	action_ls.font_color    = Color(0.80, 0.80, 0.80)
	action_ls.shadow_color  = Color(0.0, 0.0, 0.0, 0.95)
	action_ls.shadow_size   = 2
	action_ls.shadow_offset = Vector2(1, 1)
	action_lbl.label_settings = action_ls
	hbox.add_child(action_lbl)

	_examine_hints.add_child(hbox)
