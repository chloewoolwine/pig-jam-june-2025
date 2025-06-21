extends Node2D
class_name GridController

signal update_gui(reset: bool)
signal done()

@export var level_size: Vector2i
@export var total_notes: int
@export var note_order: Array[NOTES]

@onready var player: Player = $Player
@onready var objects: Node2D = $Objects

@onready var c: AudioStreamPlayer2D = $Notes/C
@onready var d: AudioStreamPlayer2D = $Notes/D
@onready var e: AudioStreamPlayer2D = $Notes/E
@onready var f: AudioStreamPlayer2D = $Notes/F
@onready var g: AudioStreamPlayer2D = $Notes/G
@onready var a: AudioStreamPlayer2D = $Notes/A
@onready var b: AudioStreamPlayer2D = $Notes/B
@onready var c_high: AudioStreamPlayer2D = $Notes/C_high


var won_level: bool
var running_num: int # this is not 0 indexed. RIP

var live_objects: Array[Node2D]

enum NOTES{
	low_c,
	d,
	e,
	f,
	g,
	a,
	b,
	high_c
}

# every object in the level finds its own position in _start (including player?)
# tile location is unneccesary- hitboxes will be assigned in the tilemap and onBodyEnter will be written here

func _ready() -> void:
	running_num = 1
	player.player_died.connect(reset_all)
	player.player_hit_note.connect(hit_note)
	for o in objects.get_children(): 
		live_objects.append(o)
		if o is Block:
			o.block_hit_note.connect(hit_note)
	player.done_celebrating.connect(done.emit)

func get_object_at_space(global_pos: Vector2) -> Node2D:
	for o in live_objects:
		if o.global_position == global_pos:
			return o
	return null

func _unhandled_key_input(_event: InputEvent) -> void:
	if(Input.is_action_pressed("reset")):
		reset_all()

func hit_note(note: Vector2i, location: Vector2i) -> void:
	play_note(note.x, location)
	print("note: ", note, " location: ", location)
	if !won_level:
		check_for_win(note) 

func play_note(note: int, _location: Vector2i) -> void:
	if note_order.is_empty():
		c.play()
		return
	# maybe do a cute animation here inthe future, thats why location is here
	# dont have the sounds yet at all 
	# there IS a better way to do this but i didn't do that. So. 
	print("note_order: ", note_order, " at: ", note-1, " is ", note_order[note-1])
	
	match note_order[note-1]: 
		0:
			c.play() # TODO: im gonna need confirmation on how high vs low c is gon work
		1:
			d.play()
		2:
			e.play()
		3:
			f.play()
		4:
			g.play()
		5:
			a.play()
		6: 
			b.play()
		7:
			c_high.play()
			
	if _location != Vector2i.MIN:
		# cute animation 
		pass
# THIS DOES NOT WORK WITH > 7 NOTES
func check_for_win(note: Vector2i) -> bool:
	update_gui.emit(note.x != running_num)
	if(note.x == running_num): #correct
		running_num = running_num + 1
	else:
		running_num = 1
	# check for win
	if running_num == (total_notes + 1):
		print("you win!!")
		play_win()
		return true
	return false

func play_win() -> void:
	await get_tree().create_timer(.5).timeout
	won_level = true
	player.idle()
	# TODO: if they supply me with melodies i can play those here
	# otherwise, play each note with a little delay between
	for i in range(note_order.size()):
		await get_tree().create_timer(.2).timeout
		play_note(i+1, Vector2i.MIN);
	await get_tree().create_timer(.4).timeout
	player.play_win()

func reset_all():
	player.reset()   
	running_num = 1
	for o in live_objects:
		if o is Block:
			o.resent()
