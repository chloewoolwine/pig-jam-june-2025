extends Node2D
class_name GridController

@export var level_size: Vector2i
@export var correct_order: Array[int]

@onready var player: Player = $Player
@onready var objects: Node2D = $Objects

@onready var c: AudioStreamPlayer2D = $Notes/C
@onready var d: AudioStreamPlayer2D = $Notes/D
@onready var e: AudioStreamPlayer2D = $Notes/E
@onready var f: AudioStreamPlayer2D = $Notes/F
@onready var g: AudioStreamPlayer2D = $Notes/G
@onready var a: AudioStreamPlayer2D = $Notes/A
@onready var b: AudioStreamPlayer2D = $Notes/B
#@onready var c_low: AudioStreamPlayer2D = $Notes/C_low

var won_level: bool
var running_order: Array[int]

var live_objects: Array[Node2D]

# every object in the level finds its own position in _start (including player?)
# tile location is unneccesary- hitboxes will be assigned in the tilemap and onBodyEnter will be written here

func _ready() -> void:
	player.player_died.connect(reset_all)
	player.player_hit_note.connect(hit_note)
	for o in objects.get_children(): 
		live_objects.append(o)
		if o is Block:
			o.block_hit_note.connect(hit_note)

func get_object_at_space(global_pos: Vector2) -> Node2D:
	for o in live_objects:
		if o.global_position == global_pos:
			return o
	return null

func _unhandled_key_input(event: InputEvent) -> void:
	if(Input.is_action_pressed("reset")):
		reset_all()

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
			c.play() # TODO: im gonna need confirmation on how high vs low c is gon work
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
			
	if _location != Vector2i.MIN:
		# cute animation 
		pass

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
		play_win()
		return true
	return false

func play_win() -> void:
	await get_tree().create_timer(.5).timeout
	player.play_win()
	# TODO: if they supply me with melodies i can play those here
	# otherwise, play each note with a little delay between
	for i in range(correct_order.size()):
		await get_tree().create_timer(.2).timeout
		play_note(correct_order[i], Vector2i.MIN);

func reset_all():
	player.reset()   
	running_order.clear()
	for o in live_objects:
		if o is Block:
			o.resent()
