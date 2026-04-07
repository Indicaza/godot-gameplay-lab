class_name PlayerController
extends CharacterBody3D

const MouseCameraInputScript = preload("res://features/camera/scripts/mouse_camera_input.gd")
const GamepadCameraInputScript = preload("res://features/camera/scripts/gamepad_camera_input.gd")

@export_group("Input")
@export var mouse_camera_sensitivity: float = 0.0035

@onready var visual_root: CharacterVisualController = $VisualRoot
@onready var camera_pivot: ThirdPersonCameraController = $CameraPivot
@onready var movement_motor: LocomotionMotor = $MovementMotor

var mouse_camera_input: MouseCameraInput
var gamepad_camera_input: GamepadCameraInput

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera_pivot.setup()
	movement_motor.setup(self, camera_pivot)

	mouse_camera_input = MouseCameraInputScript.new(mouse_camera_sensitivity)
	gamepad_camera_input = GamepadCameraInputScript.new()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_camera_input.handle_mouse_motion(camera_pivot, event)
		gamepad_camera_input.reset()

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var move_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	var input_state := {
		"move_vector": move_vector,
		"jump_pressed": Input.is_action_just_pressed("jump"),
		"jump_held": Input.is_action_pressed("jump"),
		"sprint_held": Input.is_action_pressed("sprint")
	}

	var move_state: Dictionary = movement_motor.physics_update(delta, input_state)

	gamepad_camera_input.update(camera_pivot, delta, velocity, move_vector)

	if move_state["jumped"]:
		visual_root.on_jump()
		camera_pivot.on_jump()

	if move_state["landed"]:
		visual_root.on_landed(move_state["landing_impact"])
		camera_pivot.on_landed(move_state["landing_impact"])

	visual_root.face_direction(move_state["facing_direction"], delta)
	visual_root.physics_update(velocity, move_state["on_floor"])
	camera_pivot.physics_update(delta, velocity, move_state["is_sprinting"], move_state["on_floor"])

func _process(delta: float) -> void:
	visual_root.frame_update(delta, is_on_floor())
	camera_pivot.frame_update(delta, velocity, is_on_floor())
