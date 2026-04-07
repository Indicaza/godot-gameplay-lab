@tool
class_name CharacterVisualController
extends Node3D

@export_group("Juice")
@export var air_stretch_amount: float = 0.08
@export var land_squash_amount: float = 0.16
@export var jump_squash_amount: float = 0.08
@export var visual_return_speed: float = 14.0
@export var landing_bob_return_speed: float = 10.0
@export var rotation_speed: float = 10.0

@export_group("Material")
@export var mesh_path: NodePath = NodePath("MeshInstance3D")
@export var shader_path: String = "res://shaders/dev_pearl.gdshader"

var scale_target: Vector3 = Vector3.ONE
var visual_position_target: Vector3 = Vector3.ZERO

@onready var mesh_instance: MeshInstance3D = get_node_or_null(mesh_path)

func _ready() -> void:
	_apply_dev_material()

func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		_apply_dev_material()

func physics_update(velocity: Vector3, on_floor: bool) -> void:
	if not on_floor:
		var fall_factor: float = clampf(absf(velocity.y) / 14.0, 0.0, 1.0)
		var stretch_y: float = 1.0 + air_stretch_amount * fall_factor
		var squash_xz: float = 1.0 - (air_stretch_amount * 0.5) * fall_factor
		scale_target = Vector3(squash_xz, stretch_y, squash_xz)

func frame_update(delta: float, on_floor: bool) -> void:
	scale = scale.lerp(scale_target, visual_return_speed * delta)
	position = position.lerp(visual_position_target, landing_bob_return_speed * delta)

	if on_floor:
		scale_target = Vector3.ONE
		visual_position_target = Vector3.ZERO

func on_jump() -> void:
	scale_target = Vector3(1.0 + jump_squash_amount, 1.0 - jump_squash_amount, 1.0 + jump_squash_amount)
	visual_position_target = Vector3(0.0, -0.03, 0.0)

func on_landed(impact: float) -> void:
	var squash: float = land_squash_amount * impact
	scale_target = Vector3(1.0 + squash, 1.0 - squash, 1.0 + squash)
	visual_position_target = Vector3(0.0, impact * 0.10, 0.0)

func face_direction(direction: Vector3, delta: float) -> void:
	if direction.length() <= 0.001:
		return

	var target_yaw: float = atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, rotation_speed * delta)

func _apply_dev_material() -> void:
	mesh_instance = get_node_or_null(mesh_path)

	if mesh_instance == null:
		return

	var shader: Shader = load(shader_path)
	if shader == null:
		return

	var material := ShaderMaterial.new()
	material.shader = shader
	mesh_instance.material_override = material