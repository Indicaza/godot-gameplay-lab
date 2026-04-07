class_name LocomotionMotor
extends Node

@export var config: MovementConfig

var body: CharacterBody3D
var camera_pivot: Node3D

var jumps_used: int = 0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var last_vertical_velocity: float = 0.0
var was_on_floor_last_frame: bool = false
var was_on_floor_before_move: bool = false
var last_move_direction: Vector3 = Vector3.ZERO
var current_move_direction: Vector3 = Vector3.ZERO
var is_sprinting: bool = false
var floor_angle_degrees: float = 0.0
var last_landing_impact: float = 0.0
var airborne_speed_cap: float = 0.0

func setup(body_ref: CharacterBody3D, camera_pivot_ref: Node3D) -> void:
	body = body_ref
	camera_pivot = camera_pivot_ref
	if config == null:
		config = MovementConfig.new()
	body.floor_max_angle = deg_to_rad(config.max_floor_angle_degrees)
	was_on_floor_last_frame = body.is_on_floor()
	was_on_floor_before_move = body.is_on_floor()

func physics_update(delta: float, input_state: Dictionary) -> Dictionary:
	var on_floor_now: bool = body.is_on_floor()
	was_on_floor_before_move = on_floor_now

	if on_floor_now:
		coyote_timer = config.coyote_time
		jumps_used = 0
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

	if jump_buffer_timer > 0.0:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

	if input_state["jump_pressed"]:
		jump_buffer_timer = config.jump_buffer_time

	current_move_direction = _get_camera_relative_input(input_state["move_vector"])
	if current_move_direction.length() > 0.001:
		last_move_direction = current_move_direction

	is_sprinting = input_state["sprint_held"] and input_state["move_vector"].length() > 0.1 and on_floor_now

	var target_speed: float = config.sprint_speed if is_sprinting else config.walk_speed
	var slope_multiplier: float = _get_slope_speed_multiplier(current_move_direction)
	var target_velocity: Vector3 = current_move_direction * target_speed * slope_multiplier

	if on_floor_now:
		var accel: float = config.acceleration * _get_slope_acceleration_multiplier(current_move_direction)

		body.velocity.x = move_toward(body.velocity.x, target_velocity.x, accel * delta)
		body.velocity.z = move_toward(body.velocity.z, target_velocity.z, accel * delta)

		if input_state["move_vector"].length() <= 0.05:
			body.velocity.x = move_toward(body.velocity.x, 0.0, config.deceleration * delta)
			body.velocity.z = move_toward(body.velocity.z, 0.0, config.deceleration * delta)

		airborne_speed_cap = maxf(Vector2(body.velocity.x, body.velocity.z).length(), target_speed)
	else:
		_apply_air_control(delta, current_move_direction)

		if input_state["move_vector"].length() <= 0.05 and config.air_drag > 0.0:
			body.velocity.x = move_toward(body.velocity.x, 0.0, config.air_drag * delta)
			body.velocity.z = move_toward(body.velocity.z, 0.0, config.air_drag * delta)

	var did_jump: bool = false
	var used_double_jump: bool = false

	if jump_buffer_timer > 0.0:
		if on_floor_now or coyote_timer > 0.0:
			_capture_airborne_speed_cap(target_speed)
			_do_jump(config.jump_velocity)
			jump_buffer_timer = 0.0
			coyote_timer = 0.0
			did_jump = true
		elif jumps_used < config.max_jumps:
			_capture_airborne_speed_cap_from_current_velocity()
			_do_jump(config.double_jump_velocity)
			jump_buffer_timer = 0.0
			did_jump = true
			used_double_jump = true

	if not body.is_on_floor():
		if body.velocity.y > 0.0:
			body.velocity.y -= config.gravity_up * delta
			if not input_state["jump_held"]:
				body.velocity.y -= config.gravity_up * (config.jump_cut_gravity_multiplier - 1.0) * delta
		else:
			body.velocity.y -= config.gravity_down * delta

	last_vertical_velocity = body.velocity.y
	body.move_and_slide()

	var on_floor_after_move: bool = body.is_on_floor()
	var landed: bool = not was_on_floor_last_frame and on_floor_after_move
	var just_left_floor: bool = was_on_floor_last_frame and not on_floor_after_move

	if just_left_floor and not did_jump:
		_capture_airborne_speed_cap_from_current_velocity()

	was_on_floor_last_frame = on_floor_after_move

	if on_floor_after_move:
		floor_angle_degrees = rad_to_deg(body.get_floor_angle())
	else:
		floor_angle_degrees = 0.0

	last_landing_impact = 0.0
	if landed:
		last_landing_impact = clampf(absf(last_vertical_velocity) / 20.0, 0.0, 1.0)

	return {
		"landed": landed,
		"landing_impact": last_landing_impact,
		"jumped": did_jump,
		"double_jumped": used_double_jump,
		"move_direction": current_move_direction,
		"facing_direction": get_facing_direction(),
		"is_sprinting": is_sprinting,
		"on_floor": on_floor_after_move,
		"floor_angle_degrees": floor_angle_degrees
	}

func get_facing_direction() -> Vector3:
	if current_move_direction.length() > 0.001:
		return current_move_direction
	return last_move_direction

func _get_camera_relative_input(input_dir: Vector2) -> Vector3:
	if input_dir.length() <= 0.001:
		return Vector3.ZERO

	var forward: Vector3 = -camera_pivot.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var right: Vector3 = camera_pivot.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()

	var direction: Vector3 = (right * input_dir.x) - (forward * input_dir.y)
	return direction.normalized()

func _apply_air_control(delta: float, move_dir: Vector3) -> void:
	if move_dir.length() <= 0.001:
		return

	var air_target_speed: float = maxf(airborne_speed_cap, config.walk_speed)
	var horizontal_velocity: Vector3 = Vector3(body.velocity.x, 0.0, body.velocity.z)
	var desired_air_velocity: Vector3 = move_dir * air_target_speed
	var velocity_delta: Vector3 = desired_air_velocity - horizontal_velocity
	var air_step: float = config.air_acceleration * delta

	if velocity_delta.length() <= air_step:
		horizontal_velocity = desired_air_velocity
	else:
		horizontal_velocity += velocity_delta.normalized() * air_step

	body.velocity.x = horizontal_velocity.x
	body.velocity.z = horizontal_velocity.z

func _do_jump(power: float) -> void:
	body.velocity.y = power
	jumps_used += 1

func _capture_airborne_speed_cap(target_speed: float) -> void:
	var current_horizontal_speed: float = Vector2(body.velocity.x, body.velocity.z).length()
	airborne_speed_cap = maxf(current_horizontal_speed, target_speed)

func _capture_airborne_speed_cap_from_current_velocity() -> void:
	airborne_speed_cap = maxf(Vector2(body.velocity.x, body.velocity.z).length(), config.walk_speed)

func _get_slope_speed_multiplier(move_dir: Vector3) -> float:
	if move_dir.length() <= 0.001 or not body.is_on_floor():
		return 1.0

	var floor_normal: Vector3 = body.get_floor_normal()
	var downhill: Vector3 = Vector3.DOWN.slide(floor_normal).normalized()
	if downhill.length() <= 0.001:
		return 1.0

	var slope_alpha: float = clampf(rad_to_deg(body.get_floor_angle()) / config.max_floor_angle_degrees, 0.0, 1.0)
	var downhill_dot: float = move_dir.dot(downhill)

	if downhill_dot < 0.0:
		return 1.0 - (absf(downhill_dot) * config.uphill_speed_penalty * slope_alpha)

	if downhill_dot > 0.0:
		return 1.0 + (downhill_dot * config.downhill_speed_boost * slope_alpha)

	return 1.0

func _get_slope_acceleration_multiplier(move_dir: Vector3) -> float:
	if move_dir.length() <= 0.001 or not body.is_on_floor():
		return 1.0

	var floor_normal: Vector3 = body.get_floor_normal()
	var downhill: Vector3 = Vector3.DOWN.slide(floor_normal).normalized()
	if downhill.length() <= 0.001:
		return 1.0

	var uphill_dot: float = move_dir.dot(-downhill)
	if uphill_dot <= 0.0:
		return 1.0

	var slope_alpha: float = clampf(rad_to_deg(body.get_floor_angle()) / config.max_floor_angle_degrees, 0.0, 1.0)
	return 1.0 - (uphill_dot * (1.0 - config.slope_acceleration_multiplier) * slope_alpha)