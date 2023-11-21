@tool
class_name Vector2ArrayResource
extends Resource

@export var polygon: PackedVector2Array

var active_index: int = -1

var active_vertex: Vector2:
	get:
		return polygon[active_index]


func init_polygon():
	if polygon.is_empty():
		polygon = PackedVector2Array([Vector2(32.0, 0.0), Vector2(-32.0, 32.0), Vector2(-32.0, -32.0)])


func add(index: int, vertex: Vector2):
	polygon.insert(index, vertex)
	active_index = index


func remove(index: int):
	polygon.remove_at(index)
	active_index = -1


func update(index: int, vertex: Vector2):
	polygon[index] = vertex
