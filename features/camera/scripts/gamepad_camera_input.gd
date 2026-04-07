class_name GamepadCameraInput
extends RefCounted

var controller_index: int = 0

var deadzone: float = 0.10
var outer_deadzone: float = 0.95
var curve_exponent: float = 2.2

var max_yaw_speed: float = 0.14
var max_pitch_speed: float = 0.10

var yaw_acceleration: float = 2.2
var yaw_deceleration: float = 8.5
var pitch_acceleration: float = 1.8
var pitch_deceleration: float = 7.5

var neutral_brake_zone: float = 0.06
var neutral_brake_strength: float = 12.0

var assist_enabled: bool = false
var recenter_enabled: bool = true
var recenter_delay: float = 0.18
var recenter_yaw_strength: float = 1.2
var recenter_pitch_strength: float = 1.0
var recenter_pitch_degrees: float = -12.0

var yaw_velocity: float = 0.0
var pitch_velocity: float = 0.0
var neutral_time: float = 0.0

func update(camera_controller: ThirdPersonCameraController, delta: float, velocity: Vector3, move_input: Vector2) -> void:
	var stick_input := _get_stick_input()
	var stick_strength := stick_input.length()

	if stick_strength <= 0.001:
		neutral_time += delta
	else:
		neutral_time = 0.0

	_update_velocity(delta, stick_input)
	_apply_neutral_brake(delta, stick_strength)
	_apply_velocity(camera_controller, delta)
	_apply_recentering(camera_controller, delta, stick_strength)

func reset() -> void:
	yaw_velocity = 0.0
	pitch_velocity = 0.0
	neutral_time = 0.0

func _get_stick_input() -> Vector2:
	var raw := Vector2(
		Input.get_joy_axis(controller_index, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(controller_index, JOY_AXIS_RIGHT_Y)
	)

	var length_raw := raw.length()
	if length_raw <= deadzone:
		return Vector2.ZERO

	var normalized := raw / maxf(length_raw, 0.0001)

	var t := (length_raw - deadzone) / (outer_deadzone - deadzone)
	t = clampf(t, 0.0, 1.0)
	t = pow(t, curve_exponent)

	return normalized * t

func _update_velocity(delta: float, stick_input: Vector2) -> void:
	var target_yaw_velocity := -stick_input.x * max_yaw_speed
	var target_pitch_velocity := -stick_input.y * max_pitch_speed

	var yaw_lerp := yaw_acceleration if absf(target_yaw_velocity) > absf(yaw_velocity) else yaw_deceleration
	var pitch_lerp := pitch_acceleration if absf(target_pitch_velocity) > absf(pitch_velocity) else pitch_deceleration

	yaw_velocity = lerpf(yaw_velocity, target_yaw_velocity, yaw_lerp * delta)
	pitch_velocity = lerpf(pitch_velocity, target_pitch_velocity, pitch_lerp * delta)

func _apply_neutral_brake(delta: float, stick_strength: float) -> void:
	if stick_strength > neutral_brake_zone:
		return

	yaw_velocity = lerpf(yaw_velocity, 0.0, neutral_brake_strength * delta)
	pitch_velocity = lerpf(pitch_velocity, 0.0, neutral_brake_strength * delta)

func _apply_velocity(camera_controller: ThirdPersonCameraController, delta: float) -> void:
	camera_controller.add_rotation(
		yaw_velocity * delta * 60.0,
		pitch_velocity * delta * 60.0
	)

func _apply_recentering(camera_controller: ThirdPersonCameraController, delta: float, stick_strength: float) -> void:
	if not recenter_enabled:
		return

	if stick_strength > neutral_brake_zone:
		return

	if neutral_time < recenter_delay:
		return

	var current_pitch := camera_controller.get_pitch()
	var target_pitch := deg_to_rad(recenter_pitch_degrees)
	var next_pitch := lerpf(current_pitch, target_pitch, recenter_pitch_strength * delta)

	var current_yaw := camera_controller.get_yaw()
	var next_yaw := lerpf(current_yaw, current_yaw - yaw_velocity * 0.08, recenter_yaw_strength * delta)

	camera_controller.set_rotation_values(next_yaw, next_pitch)