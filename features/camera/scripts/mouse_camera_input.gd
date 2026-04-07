class_name MouseCameraInput
extends RefCounted

var sensitivity: float

func _init(mouse_sensitivity: float = 0.0035) -> void:
	sensitivity = mouse_sensitivity

func handle_mouse_motion(camera_controller: ThirdPersonCameraController, event: InputEventMouseMotion) -> void:
	var yaw_delta := -event.relative.x * sensitivity
	var pitch_delta := -event.relative.y * sensitivity
	camera_controller.add_rotation(yaw_delta, pitch_delta)