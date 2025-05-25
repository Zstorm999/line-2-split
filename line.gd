@tool
extends Node3D

var a_position = Vector3.ZERO;
var b_position = Vector3.FORWARD;

func _on_A_position_changed(new_position: Vector3) -> void:
	print("A moved", new_position)
	a_position = new_position
	_draw_line()


func _on_B_position_changed(new_position: Vector3) -> void:
	print("B moved", new_position)
	b_position = new_position
	_draw_line()

func _draw_line():
	var a = Vector2(a_position.x, a_position.z)
	var b = Vector2(b_position.x, b_position.z)
	RenderingServer.global_shader_parameter_set("split_position", a)
	RenderingServer.global_shader_parameter_set("split_direction", (b - a).normalized())
