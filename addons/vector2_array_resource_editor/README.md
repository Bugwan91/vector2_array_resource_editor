# Vector2 Array Resource Editor
Godot plugin that allows to edit PackedVector2Array as a polygon in the 2D scene view. 

- [Installation](#installation)
- [Usage](#usage)
- [Buy Me A Coffee](#buy-me-a-coffee)

![editing_preview](images/editing_preview.gif)

## Installation

- Manual: Download the source code and move only the addons folder into your project addons folder then enable plugin in Project -> Project Settings -> Plugins.

## Usage

This plugin provides a new resource `Vector2ArrayResource` which contains a property `data` of `PackedVector2Array` type.
The `Vector2ArrayResource` is a wrapper for `PackedVector2Array`.
When this resource is added to a node, and it is active, the plugin will provide functionality for easy editing data of the array.

### Example
- Add a property of `Vector2ArrayResource` to your node
```
@export var polygon: Vector2ArrayResource
```
- Then you can get `PackedVector2Array` from like this:
```
func _ready():
    # setuping polygon for CollisionPolygon2D node
    collision_polygon_2d.polygon = polygon.data
```

There is a example scene in the `example` folder.

### Controls

|Action|Key|
|-|-|
|Add vertex|left mouse click|
|Remove vertex|right mouse click|
|Move vertex|left mouse klick on vertex and drag|
|Undo|Ctrl + Z|
|Redo|Ctrl + Shift + Z|

## Buy Me A Coffee

If you find this tool useful consider buying me a coffee:

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/romanmovchan)
