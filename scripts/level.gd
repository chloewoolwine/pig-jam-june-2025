extends Node2D
class_name Level

@export var level_name: String 
@onready var grid_controller: GridController = $GridController
@onready var control: GUI = $Control


func _ready() -> void:
	control.set_total(grid_controller.total_notes)
	grid_controller.update_gui.connect(control.update)
