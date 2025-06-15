extends Node2D
class_name GridController

@export var level_size: Vector2i
@export var correct_order: Array[int]
@onready var player: Player = $Player

# every object in the level finds its own position in _start (including player?)
# tile location is unneccesary- hitboxes will be assigned in the tilemap and onBodyEnter will be written here

func _ready() -> void:
	player.player_hit_note.connect(hit_note)
	
func hit_note(note: Vector2i, location: Vector2i) -> void:
	print("note: ", note, " location: ", location)
