extends Interactable
class_name NPCBase
# Shared base for the reusable NPC scenes. Per-pack scripts
# (Assets/Characters/<Pack>/npc.gd) extend this and only supply their own
# Look enum/TEXTURES and override _apply_look() — talking and animation are
# identical across packs, so they live here instead of being copy-pasted.

## --- Dialogue ------------------------------------------------------------
## Dialogic timeline identifier (matches a directories/dtl_directory entry
## in project.godot, normally "res://Dialogue/<timeline_id>.dtl") — leave
## blank for NPCs that don't talk yet. See Dialogue/README.md.
@export var timeline_id: String = ""
## Whether the player can back out of this one early with Escape (see
## player.gd). Off for a conversation the game needs to actually finish —
## e.g. one that flips a flag/hands over an item the player needs to
## progress — so they can't dodge the consequence by bailing out.
@export var dialogue_skippable: bool = true

## --- Animation -------------------------------------------------------------
## State machine over the character pack's baked clips (idle, walk,
## walk_turn_180, stop_walking, sit, typing, pacing_phone, plus the extras
## below). TURN and STOP are one-shots that auto-advance to their "next"
## state when the clip finishes — e.g. calling play_turn() mid-walk plays
## walk_turn_180 then drops back into WALK on its own. Drive this from
## movement/AI code later (e.g. call play_turn() when a patrol raycast hits
## a wall).
enum AnimState {
	IDLE, WALK, TURN, STOP, SIT, TYPING, PACE_PHONE,
	IDLE_ALT, SIT_ALT, TALKING_ON_PHONE, RUNNING, ASCENDING_STAIRS,
	DESCENDING_STAIRS, RIGHT_HAND_INTERACT,
}

const ANIM_CLIPS := {
	AnimState.IDLE:              {"clip": "idle"},
	AnimState.WALK:              {"clip": "walk"},
	AnimState.TURN:              {"clip": "walk_turn_180", "next": AnimState.WALK},
	AnimState.STOP:              {"clip": "stop_walking",  "next": AnimState.IDLE},
	AnimState.SIT:               {"clip": "sit"},
	AnimState.TYPING:            {"clip": "typing"},
	AnimState.PACE_PHONE:        {"clip": "pacing_phone"},
	AnimState.IDLE_ALT:          {"clip": "idle_alt"},
	AnimState.SIT_ALT:           {"clip": "sit_alt"},
	AnimState.TALKING_ON_PHONE:  {"clip": "talking_on_phone"},
	AnimState.RUNNING:           {"clip": "running"},
	AnimState.ASCENDING_STAIRS:  {"clip": "ascending_stairs"},
	AnimState.DESCENDING_STAIRS: {"clip": "descending_stairs"},
	AnimState.RIGHT_HAND_INTERACT: {"clip": "right_hand_interact", "next": AnimState.IDLE},
}

## Which state this NPC boots into — pick Sit/Typing/Pacing Phone here for
## an NPC that should just hold one pose with no movement at all (leave
## patrol_enabled off and destinations_array empty for those). Ignored in
## practice if patrol/waypoints are also enabled, since those call
## play_walk() on their own first tick regardless.
@export var initial_state: AnimState = AnimState.IDLE

## Drives the shared state machine (npc_state_machine.tres). No
## root_motion_track is set on this — clips with real baked hip translation
## (pacing_phone, running, the stair clips) visibly move the character when
## looped, same as their source Mixamo animation; root_motion_track was
## tried and rejected as a fix since it strips a bone's whole baseline pose,
## not just excess motion, which broke the retargeted clips outright.
@onready var anim_tree: AnimationTree = $AnimationTree

var _anim_playback: AnimationNodeStateMachinePlayback
var _anim_state: AnimState = AnimState.IDLE


func _ready() -> void:
	_apply_look()
	_anim_playback = anim_tree.get("parameters/playback")
	# AnimationNodeStateMachinePlayback.state_finished only fires for a state
	# reached via an authored graph transition — our state machine has none
	# (see npc_state_machine.tres), so TURN/STOP would never auto-chain on
	# that signal. AnimationMixer.animation_finished (shared by AnimationTree
	# and AnimationPlayer alike) fires reliably regardless of the graph.
	anim_tree.animation_finished.connect(_on_anim_state_finished)
	# start(), not set_anim_state() — _anim_state already equals initial_state
	# below, so the dedupe guard would swallow the very first play.
	_anim_state = initial_state
	_anim_playback.start(ANIM_CLIPS[initial_state].clip)
	if patrol_enabled:
		_patrol_waiting = true
		_patrol_wait_timer = patrol_wait_time
	_setup_head_look_at()
	if not destinations_array.is_empty():
		nav_agent.path_desired_distance = waypoint_arrive_distance
		nav_agent.target_desired_distance = waypoint_arrive_distance
		# The NavigationServer map needs a physics frame to sync a
		# freshly-entered region/agent before a path request resolves to
		# anything meaningful — request the first leg after that, not here.
		await get_tree().physics_frame
		_start_navigating_to(destinations_array[_dest_index])


func set_anim_state(state: AnimState) -> void:
	if state == _anim_state or not ANIM_CLIPS.has(state):
		return
	_anim_state = state
	_anim_playback.travel(ANIM_CLIPS[state].clip)


func play_idle() -> void:
	set_anim_state(AnimState.IDLE)


func play_walk() -> void:
	set_anim_state(AnimState.WALK)


func play_turn() -> void:
	set_anim_state(AnimState.TURN)


func play_stop() -> void:
	set_anim_state(AnimState.STOP)


func play_sit() -> void:
	set_anim_state(AnimState.SIT)


func play_typing() -> void:
	set_anim_state(AnimState.TYPING)


func play_pacing_phone() -> void:
	set_anim_state(AnimState.PACE_PHONE)


func play_idle_alt() -> void:
	set_anim_state(AnimState.IDLE_ALT)


func play_sit_alt() -> void:
	set_anim_state(AnimState.SIT_ALT)


func play_talking_on_phone() -> void:
	set_anim_state(AnimState.TALKING_ON_PHONE)


func play_running() -> void:
	set_anim_state(AnimState.RUNNING)


func play_ascending_stairs() -> void:
	set_anim_state(AnimState.ASCENDING_STAIRS)


func play_descending_stairs() -> void:
	set_anim_state(AnimState.DESCENDING_STAIRS)


func play_right_hand_interact() -> void:
	set_anim_state(AnimState.RIGHT_HAND_INTERACT)


func _on_anim_state_finished(state_name: StringName) -> void:
	var data: Dictionary = ANIM_CLIPS.get(_anim_state, {})
	if data.get("clip", "") == String(state_name) and data.has("next"):
		set_anim_state(data.next as AnimState)


## --- Patrol (optional demo) --------------------------------------------
## Off by default. When enabled, walks patrol_distance along local +Z, idles,
## snaps around, walks back, forever — a worked example of driving the state
## machine above from actual movement rather than a real AI. Superseded by
## the waypoint patrol below whenever destinations_array isn't empty; kept
## around as the simplest possible example for NPCs that don't need it.
@export var patrol_enabled: bool = false
@export var patrol_distance: float = 4.0
@export var patrol_speed: float = 1.0
@export var patrol_wait_time: float = 2.0

var _patrol_waiting := false
var _patrol_started := false
var _patrol_wait_timer := 0.0
var _patrol_walked := 0.0


## --- Waypoint patrol -----------------------------------------------------
## Walks to each Marker3D in destinations_array in order, looping back to
## the first after the last, idling for a random stretch at each stop.
## Routing goes through NavigationAgent3D (a child node here) against
## whatever NavigationRegion3D is baked into the level, so it paths around
## obstacles instead of walking straight through them — you only need to
## drop Marker3D nodes and assign them here, not carve a clear line of
## sight. Turning is a continuous face-the-target lerp while walking rather
## than the fixed walk_turn_180 one-shot above, since waypoints (and the
## intermediate path corners the agent produces) can be at any angle, not
## just a 180-degree reversal.
@export var destinations_array: Array[Marker3D]
@export var waypoint_speed: float = 1.5
@export var waypoint_turn_speed: float = 4.0
@export var waypoint_arrive_distance: float = 0.15
@export var waypoint_idle_time_min: float = 1.0
@export var waypoint_idle_time_max: float = 5.0
## How far off (degrees) the NPC's facing can be from the next path point
## before it starts walking forward again. Without this, turning and moving
## forward happen every frame regardless of heading, so if something yanks
## the facing away mid-walk (e.g. turning to face the player for a
## conversation, or the path bending sharply around a corner), the NPC
## corrects by curving/orbiting instead of turning to face it cleanly —
## this pirouettes in place first instead.
@export var waypoint_move_angle_threshold_deg: float = 45.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var _dest_index := 0
var _dest_waiting := false
var _dest_wait_timer := 0.0


func _start_navigating_to(target: Node3D) -> void:
	nav_agent.target_position = target.global_position


func _process(delta: float) -> void:
	if _in_conversation:
		_process_face_player(delta)
		return
	if not destinations_array.is_empty():
		_process_waypoint_patrol(delta)
	elif patrol_enabled:
		_process_straight_patrol(delta)


func _process_waypoint_patrol(delta: float) -> void:
	if _dest_waiting:
		_dest_wait_timer -= delta
		if _dest_wait_timer <= 0.0:
			_dest_waiting = false
			_dest_index = (_dest_index + 1) % destinations_array.size()
			_start_navigating_to(destinations_array[_dest_index])
			play_walk()
		return
	var target := destinations_array[_dest_index]
	if not target:
		return
	# Route through the nav agent when it actually has a usable path to
	# offer; otherwise (no NavigationRegion3D in the level, or the target
	# isn't resolvable on one) just walk straight at the marker — the same
	# direct steering this used before NavigationAgent3D was wired in, so
	# a disabled/missing region never leaves the NPC stuck.
	var next_point: Vector3 = target.global_position
	if nav_agent.is_target_reachable():
		next_point = nav_agent.get_next_path_position()
	var to_next := next_point - global_position
	to_next.y = 0.0
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	if to_target.length() <= waypoint_arrive_distance:
		play_idle()
		_dest_waiting = true
		_dest_wait_timer = randf_range(waypoint_idle_time_min, waypoint_idle_time_max)
		return
	if _anim_state != AnimState.WALK:
		play_walk()
	var target_yaw := atan2(to_next.x, to_next.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(waypoint_turn_speed * delta, 0.0, 1.0))
	var angle_to_target := absf(wrapf(target_yaw - rotation.y, -PI, PI))
	if angle_to_target <= deg_to_rad(waypoint_move_angle_threshold_deg):
		translate(Vector3(0, 0, waypoint_speed * delta))


func _process_straight_patrol(delta: float) -> void:
	if _patrol_waiting:
		_patrol_wait_timer -= delta
		if _patrol_wait_timer <= 0.0:
			_patrol_waiting = false
			if _patrol_started:
				rotate_y(PI)
			_patrol_started = true
			play_walk()
		return
	if _anim_state != AnimState.WALK:
		return
	translate(Vector3(0, 0, patrol_speed * delta))
	_patrol_walked += patrol_speed * delta
	if _patrol_walked >= patrol_distance:
		_patrol_walked = 0.0
		play_stop()
		_patrol_waiting = true
		_patrol_wait_timer = patrol_wait_time


## --- Head look-at (talking) --------------------------------------------
## Turns just the head bone toward the player's camera while a conversation
## with this NPC is active. LookAtModifier3D runs after the AnimationTree
## each frame, so it layers on top of idle/sit/typing/walk without fighting
## whatever pose is currently playing.
const HEAD_BONE_NAME := "mixamorig_Head"
const HEAD_LOOK_ANGLE_LIMIT := 60.0  # degrees off center before it stops turning further

var _look_at_modifier: LookAtModifier3D


func _setup_head_look_at() -> void:
	var skeleton: Skeleton3D = find_child("Skeleton3D", true, false)
	if not skeleton or skeleton.find_bone(HEAD_BONE_NAME) == -1:
		return
	_look_at_modifier = LookAtModifier3D.new()
	_look_at_modifier.bone_name = HEAD_BONE_NAME
	_look_at_modifier.forward_axis = LookAtModifier3D.BONE_AXIS_PLUS_Z
	_look_at_modifier.use_angle_limitation = true
	_look_at_modifier.primary_limit_angle = deg_to_rad(HEAD_LOOK_ANGLE_LIMIT)
	_look_at_modifier.secondary_limit_angle = deg_to_rad(HEAD_LOOK_ANGLE_LIMIT)
	_look_at_modifier.active = false
	skeleton.add_child(_look_at_modifier)


func _start_looking_at_player() -> void:
	if not _look_at_modifier or not _conversation_player:
		return
	var camera := _conversation_player.get_node_or_null("Head/Camera3D")
	if not camera:
		return
	_look_at_modifier.target_node = _look_at_modifier.get_path_to(camera)
	_look_at_modifier.active = true


func _stop_looking_at_player() -> void:
	if _look_at_modifier:
		_look_at_modifier.active = false


## --- Talking ---------------------------------------------------------------
## Freezes patrol movement (either flavor above) for the duration of a
## conversation (see the _in_conversation guard in _process()) so an NPC
## doesn't walk away mid-dialogue — it settles into idle via the existing
## STOP->IDLE chain if it was mid-walk, then resumes patrol where it left
## off once the timeline ends. Also turns the whole body to face the player
## (the head look-at above only swivels the head/neck, which clamps at
## HEAD_LOOK_ANGLE_LIMIT and looks wrong if the player's well off to the
## side or behind) — but only for the states checked here. Per-NPC, so a
## typing/sit pose can stay put (chair/desk don't turn with it) while idle
## still turns to face whoever walked up. Add a name here for every future
## AnimState so it stays controllable per-instance without code changes.
@export_flags("Idle", "Walk", "Turn", "Stop", "Sit", "Typing", "Pace Phone",
		"Idle Alt", "Sit Alt", "Talking On Phone", "Running", "Ascending Stairs",
		"Descending Stairs", "Right Hand Interact")
var face_player_states: int = (1 << AnimState.IDLE) | (1 << AnimState.WALK) \
		| (1 << AnimState.TURN) | (1 << AnimState.STOP) | (1 << AnimState.PACE_PHONE) \
		| (1 << AnimState.IDLE_ALT) | (1 << AnimState.TALKING_ON_PHONE) \
		| (1 << AnimState.RUNNING) | (1 << AnimState.ASCENDING_STAIRS) \
		| (1 << AnimState.DESCENDING_STAIRS)
@export var face_player_turn_speed: float = 6.0

var _in_conversation := false
var _conversation_player: Node3D


func get_interact_text():
	return "Talk"


func interact(body) -> void:
	if timeline_id == "" or Dialogic.current_timeline != null:
		return
	UI.dialogue_skippable = dialogue_skippable
	_in_conversation = true
	_conversation_player = get_tree().get_first_node_in_group("player")
	if _anim_state == AnimState.WALK:
		# Straight to idle, not play_stop() — the stop_walking clip is a
		# multi-second deceleration meant for a natural patrol arrival, which
		# reads as sluggish for a player-initiated "stop and talk to me" —
		# this should cut instantly. Body still turns to face them smoothly
		# via _process_face_player() below regardless.
		play_idle()
	_start_looking_at_player()
	if not Dialogic.timeline_ended.is_connected(_on_conversation_ended):
		Dialogic.timeline_ended.connect(_on_conversation_ended, CONNECT_ONE_SHOT)
	Dialogic.start(timeline_id)


func _process_face_player(delta: float) -> void:
	if not is_instance_valid(_conversation_player):
		return
	if not (face_player_states & (1 << _anim_state)):
		return
	var to_player := _conversation_player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() < 0.01:
		return
	var target_yaw := atan2(to_player.x, to_player.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(face_player_turn_speed * delta, 0.0, 1.0))


func _on_conversation_ended() -> void:
	_in_conversation = false
	_conversation_player = null
	_stop_looking_at_player()


func _apply_look() -> void:
	pass
