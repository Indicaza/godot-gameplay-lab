class_name ThirdPersonCameraController
extends Node3D

@export_group("Pitch Limits")
@export var min_pitch_degrees: float = -65.0
@export var max_pitch_degrees: float = 20.0

@export_group("Camera Feel")
@export var camera_base_height: float = 1.6
@export var camera_lag_amount: float = 0.12
@export var camera_lag_speed: float = 10.0
@export var camera_tilt_amount: float = 4.0
@export var camera_tilt_speed: float = 8.0
@export var camera_fov_base: float = 75.0
@export var camera_fov_sprint: float = 82.0
@export var camera_fov_speed: float = 6.0
@export var stop_bob_amount: float = 0.12
@export var stop_bob_speed: float = 10.0
@export var landing_camera_bump: float = 0.18
@export var sprint_reference_speed: float = 13.5

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

var yaw: float = 0.0
var pitch: float = deg_to_rad(-20.0)

var camera_offset_current: Vector3 = Vector3.ZERO
var camera_offset_target: Vector3 = Vector3.ZERO
var camera_roll_current: float = 0.0
var camera_roll_target: float = 0.0
var camera_vertical_bob_current: float = 0.0
var camera_vertical_bob_target: float = 0.0

func setup() -> void:
	position = Vector3(0.0, camera_base_height, 0.0)
	camera.fov = camera_fov_base
	apply_rotation()

func add_rotation(yaw_delta: float, pitch_delta: float) -> void:
	yaw += yaw_delta
	pitch += pitch_delta
	pitch = clampf(pitch, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))
	apply_rotation()

func set_rotation_values(new_yaw: float, new_pitch: float) -> void:
	yaw = new_yaw
	pitch = clampf(new_pitch, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))
	apply_rotation()

func get_yaw() -> float:
	return yaw

func get_pitch() -> float:
	return pitch

func get_pitch_limits_radians() -> Vector2:
	return Vector2(deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))

func physics_update(delta: float, velocity: Vector3, is_sprinting: bool, on_floor: bool) -> void:
	var local_velocity := global_transform.basis.inverse() * velocity

	var side_lag := -local_velocity.x * camera_lag_amount * 0.04
	var back_lag := clampf(local_velocity.z * camera_lag_amount * 0.06, -0.35, 0.25)
	var sprint_push := -0.10 if is_sprinting else 0.0

	camera_offset_target.x = clampf(side_lag, -0.30, 0.30)
	camera_offset_target.y = 0.0
	camera_offset_target.z = clampf(back_lag + sprint_push, -0.45, 0.25)

	var strafe_amount := clampf(local_velocity.x / maxf(local_velocity.length(), 0.001), -1.0, 1.0)
	camera_roll_target = -strafe_amount * camera_tilt_amount

	if on_floor and Vector2(velocity.x, velocity.z).length() < 0.1:
		camera_vertical_bob_target = lerpf(camera_vertical_bob_target, stop_bob_amount * 0.25, delta * 6.0)

func frame_update(delta: float, velocity: Vector3, on_floor: bool) -> void:
	camera_offset_current = camera_offset_current.lerp(camera_offset_target, camera_lag_speed * delta)
	camera_roll_current = lerpf(camera_roll_current, camera_roll_target, camera_tilt_speed * delta)
	camera_vertical_bob_current = lerpf(camera_vertical_bob_current, camera_vertical_bob_target, stop_bob_speed * delta)

	position = Vector3(0.0, camera_base_height + camera_vertical_bob_current, 0.0) + camera_offset_current

	var spring_basis := Basis.from_euler(Vector3(pitch, 0.0, deg_to_rad(camera_roll_current)))
	spring_arm.transform.basis = spring_basis

	var horiz_speed := Vector2(velocity.x, velocity.z).length()
	var sprint_alpha := clampf(inverse_lerp(0.0, sprint_reference_speed, horiz_speed), 0.0, 1.0)
	var target_fov := lerpf(camera_fov_base, camera_fov_sprint, sprint_alpha)
	camera.fov = lerpf(camera.fov, target_fov, camera_fov_speed * delta)

	if on_floor:
		camera_vertical_bob_target = 0.0

func on_jump() -> void:
	camera_vertical_bob_target = -0.05

func on_landed(impact: float) -> void:
	camera_vertical_bob_target = landing_camera_bump * impact

func apply_rotation() -> void:
	rotation.y = yaw