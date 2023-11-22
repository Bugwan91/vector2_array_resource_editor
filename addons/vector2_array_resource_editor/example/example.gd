@tool
extends Node2D

## Most of code in the example are redundant.
## I did it to visualize any schanges of the resource.

## The `Vector2ArrayResource` is handled by the plugin.
## To get a PackedVector2Array data from the resource use `data` property (`polygon.data`)
@export var polygon: Vector2ArrayResource:
	set(new_polygon):
		polygon = new_polygon
		_subscribe_on_polygon_cghanged()
		_apply_polygon_data()


@onready var polygon_2d = %Polygon2D

@onready var collision_polygon_2d = %CollisionPolygon2D


func _subscribe_on_polygon_cghanged():
	if is_instance_valid(polygon) and not polygon.changed.is_connected(_apply_polygon_data):
		polygon.changed.connect(_apply_polygon_data)


func _apply_polygon_data():
	## IF resource is invalid
	## THEN get polygon data (`Packedvector2Array`) from the `Vector2ArrayResource`
	## ELSE create empty `PackedVector2Array`
	var polygon_data = polygon.data if is_instance_valid(polygon) else PackedVector2Array()
	if is_instance_valid(polygon_2d):
		## setuping Polygon2D node with polygon data
		polygon_2d.polygon = polygon_data
	if is_instance_valid(collision_polygon_2d):
		## setuping CollisionPolygon2D node with polygon data
		collision_polygon_2d.polygon = polygon_data
