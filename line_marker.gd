@tool
extends Marker3D

signal position_changed(new_position: Vector3)

var last_position: Vector3 = Vector3.ZERO

func _process(delta: float) -> void:
	if position != last_position:
		last_position = position
		position_changed.emit(position)
