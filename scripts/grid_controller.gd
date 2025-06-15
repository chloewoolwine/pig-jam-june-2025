extends Node2D
class_name GridController

@export var level_size: Vector2i
@export var correct_order: Array[int]

@onready var player: Player = $Player

@onready var c: AudioStreamPlayer2D = $Notes/C
@onready var d: AudioStreamPlayer2D = $Notes/D
@onready var e: AudioStreamPlayer2D = $Notes/E
@onready var f: AudioStreamPlayer2D = $Notes/F
@onready var g: AudioStreamPlayer2D = $Notes/G
@onready var a: AudioStreamPlayer2D = $Notes/A
@onready var b: AudioStreamPlayer2D = $Notes/B

var won_level: bool
var running_order: Array[int]

# every object in the level finds its own position in _start (including player?)
# tile location is unneccesary- hitboxes will be assigned in the tilemap and onBodyEnter will be written here

func _ready() -> void:
	player.player_hit_note.connect(hit_note)
	
func hit_note(note: Vector2i, location: Vector2i) -> void:
	print("note: ", note, " location: ", location)
	play_note(note.x, location)
	if !won_level:
		check_for_win(note) 

func play_note(note: int, _location: Vector2i) -> void:
	# maybe do a cute animation here inthe future, thats why location is here
	# dont have the sounds yet at all 
	# there IS a better way to do this but i didn't do that. So. 
	match note: 
		1:
			c.play()
		2:
			d.play()
		3:
			e.play()
		4:
			f.play()
		5:
			g.play()
		6:
			a.play()
		7: 
			b.play()

func check_for_win(note: Vector2i) -> bool:
	running_order.append(note.x)
	for i in range(running_order.size()):
		if(running_order[i] != correct_order[i]):
			running_order.clear()
			break
	# check for win
	if running_order.size() == correct_order.size():
		won_level = true
		print("you win!!")
		return true
	return false
