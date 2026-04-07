class_name MovementConfig
extends Resource

@export_group("Movement")
@export var walk_speed: float = 8.0
@export var sprint_speed: float = 13.5
@export var acceleration: float = 30.0
@export var deceleration: float = 26.0
@export var air_acceleration: float = 10.0
@export var air_drag: float = 0.0
@export var rotation_speed: float = 10.0

@export_group("Jumping")
@export var jump_velocity: float = 10.5
@export var double_jump_velocity: float = 9.5
@export var gravity_up: float = 24.0
@export var gravity_down: float = 38.0
@export var jump_cut_gravity_multiplier: float = 1.8
@export var max_jumps: int = 2
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

@export_group("Slope")
@export var max_floor_angle_degrees: float = 46.0
@export var uphill_speed_penalty: float = 0.3
@export var downhill_speed_boost: float = 0.12
@export var slope_acceleration_multiplier: float = 0.9