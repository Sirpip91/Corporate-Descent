extends CharacterBody3D

var speed
const WALK_SPEED = 2.5
const CROUCH_SPEED = 2
const SPRINT_SPEED = 4.5
const DEV_SPEED = 30.0
const STEP_HEIGHT = 0.18
const STEP_PROBE = 0.2
var dev_fast: bool = false
# Sensitivity is set in GameState.mouse_sensitivity and read live each frame.
const CROUNCH_DEPTH = -0.75
const lerp_speed = 10

#bob variables
const BOB_FREQ = 2.4
const BOB_AMP = 0.05
var t_bob = 0.0

#fov variables
const BASE_FOV = 75.0
const FOV_CHANGE = .5

var _shake_offset: Vector2 = Vector2.ZERO
var _fov_override: bool = false

var movement_locked: bool = false
var examining: bool = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8

var crouched : bool = false        # true  → crouched
const CROUCH_HEIGHT = 0.5          # ← optional, used later for camera & collision


@onready var head = $Head
@onready var camera = $Head/Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Godot's defaults here (0.001 margin, 4 slide iterations) are too tight
	# against the batch-generated prop collision in this project — those hulls
	# (from create_multiple_convex_collisions()) aren't always clean, and with
	# no recovery buffer and few slide iterations the player can end up stuck
	# still overlapping geometry, especially off a jump's fast vertical motion.
	safe_margin = 0.04
	max_slides = 6


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if examining:
			ExamineController.rotate(event.relative)
			return
		head.rotate_y(-event.relative.x * GameState.mouse_sensitivity)
		camera.rotate_x(-event.relative.y * GameState.mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		return
	if event.is_action_pressed("commit_choice") and examining:
		ExamineController.end(ExamineController.is_collectible())
		get_viewport().set_input_as_handled()
		return
	if Input.is_action_pressed("escape"):
		if examining:
			ExamineController.end(false)
			return
		if get_tree().paused:
			$PauseMenu._unpause()
		else:
			$PauseMenu._pause()
	if event is InputEventKey and event.pressed and event.keycode == KEY_APOSTROPHE:
		dev_fast = !dev_fast
		Dev.msg("[color=yellow][Dev] Fast mode: %s[/color]" % ("ON" if dev_fast else "OFF"))

func _physics_process(delta):
	if movement_locked:
		velocity = Vector3.ZERO
		return

	# ── Gravity -----------------------------------------
	if not is_on_floor():
		velocity.y -= gravity * delta

	# ── Crouch / Sprint / Walk ------------------------------------
	# 1) Toggle crouch on a key press
	if Input.is_action_just_pressed("crouch"):
		crouched = !crouched

	# 2) If sprint is active, *always* leave crouch
	if crouched and Input.is_action_pressed("sprint"):
		crouched = false

	# 3) Decide speed and head height
	if dev_fast:
		speed = DEV_SPEED
		head.position.y = lerp(head.position.y, 2.344, delta * lerp_speed)
	elif crouched:
		speed = CROUCH_SPEED
		head.position.y = lerp(head.position.y, 2.344 + CROUNCH_DEPTH, delta * lerp_speed)
	elif Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
		head.position.y = lerp(head.position.y, 2.344, delta * lerp_speed)
	else:
		speed = WALK_SPEED
		head.position.y = lerp(head.position.y, 2.344, delta * lerp_speed)

	# ── Movement ---------------------------------------------
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * transform.basis *
					 Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	# ── Apply physics --------------------------------------
	_try_step_up()
	move_and_slide()

	# ── Head‑bob & FOV ------------------------------------------
	# Read AFTER move_and_slide() resolves collisions, not before — otherwise
	# this reflects requested velocity (e.g. holding sprint into a wall) rather
	# than what actually happened, and the FOV ramps up while fully stuck.
	t_bob += delta * velocity.length() * float(is_on_floor())
	_shake_offset = _shake_offset.lerp(Vector2.ZERO, delta * 15.0)
	camera.transform.origin = _headbob(t_bob) + Vector3(_shake_offset.x, _shake_offset.y, 0.0)

	if not _fov_override:
		var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
		var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
		camera.fov = lerp(camera.fov, target_fov, delta * 8.0)


# CharacterBody3D has no step handling of its own — without this the player
# catches on door thresholds and floor transitions and has to jump them.
func _try_step_up() -> void:
	if not is_on_floor():
		return

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if horizontal.length() < 0.01:
		return

	var probe := horizontal.normalized() * STEP_PROBE
	var from := global_transform

	if not test_move(from, probe):
		return

	var lifted := from.translated(Vector3.UP * STEP_HEIGHT)
	if test_move(lifted, probe):
		return  # solid all the way up — a wall, not a step

	# only rise as far as the step actually is, so a small lip doesn't pop the
	# camera the full STEP_HEIGHT
	var hit := KinematicCollision3D.new()
	var lift := STEP_HEIGHT
	if test_move(lifted.translated(probe), Vector3.DOWN * STEP_HEIGHT, hit):
		lift -= hit.get_travel().length()
	lift = max(lift, 0.0)
	if lift < 0.001:
		return

	# an angled hit (a corner, or an imprecise convex hull on a generated prop)
	# can pass both checks above but still overlap something at the exact
	# computed height — confirm it's actually clear before committing, or the
	# player ends up half-embedded and stuck rather than blocked normally
	var candidate := from.translated(Vector3.UP * lift)
	if test_move(candidate, probe):
		return

	global_position.y += lift


func shake(intensity: float) -> void:
	_shake_offset = Vector2(
		randf_range(-intensity, intensity),
		randf_range(-intensity, intensity)
	)


# Quick jolt up then back — used for sudden scares
func spike_fov(target: float, duration_in: float, duration_out: float) -> void:
	_fov_override = true
	var tween := create_tween()
	tween.tween_property(camera, "fov", target, duration_in).set_ease(Tween.EASE_IN)
	tween.tween_property(camera, "fov", BASE_FOV, duration_out).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): _fov_override = false)


# One-way expansion — used for dread build, no return (scene will change)
func warp_fov(target: float, duration: float) -> void:
	_fov_override = true
	var tween := create_tween()
	tween.tween_property(camera, "fov", target, duration).set_ease(Tween.EASE_IN)


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
