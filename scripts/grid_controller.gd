extends Node2D
class_name GridController

signal update_gui(reset: bool)
signal done()

@export var level_size: Vector2i
@export var total_notes: int
@export var note_order: Array[NOTE]
@export var color_order: Array[COLOR]

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
var current_loc: int # 0 indexed baby!

var live_objects: Array[Node2D]

enum NOTE{
	low_c,
	d,
	e,
	f,
	g,
	a,
	b,
	high_c
}

enum COLOR{
	red,
	orange,
	yellow,
	green,
	blue,
	purple,
	pink
}

# every object in the level finds its own position in _start (including player?)
# tile location is unneccesary- hitboxes will be assigned in the tilemap and onBodyEnter will be written here

func _ready() -> void:
	current_loc = 0
	player.player_died.connect(reset_all)
	player.player_hit_note.connect(hit_note)
	for o in objects.get_children(): 
		live_objects.append(o)
		if o is Block:
			o.block_hit_note.connect(hit_note)
	player.done_celebrating.connect(done.emit)
	
	if color_order.size() == 0:
		for i in total_notes:
			color_order.append(i % 7)

func reset_all():
	player.reset()   
	current_loc = 0
	update_gui.emit(true)
	for o in live_objects:
		if o is Block:
			o.resent()

func get_object_at_space(global_pos: Vector2) -> Node2D:
	for o in live_objects:
		if o.global_position == global_pos:
			return o
	return null

func _unhandled_key_input(_event: InputEvent) -> void:
	if(Input.is_action_pressed("reset")):
		reset_all()

func hit_note(tile_loc: Vector2i, location: Vector2i) -> void:
	print("tile_loc: ", tile_loc, " location: ", location)
	if is_correct(tile_loc.x):
		print("corect")
		if note_order.size() > current_loc:
			play_note(note_order[current_loc], location)
		else:
			play_note(current_loc % 7, location)
		current_loc = current_loc + 1 
		update_gui.emit(false)
		if !won_level:
			check_for_win(tile_loc)
	else:
		update_gui.emit(true)
		current_loc = 0

func is_correct(note: int) -> bool: 
	return (note - 1) == color_order[current_loc] # minus one because they aint 0 indexed on the sheet

# THIS DOES NOT WORK WITH > 7 NOTES
func check_for_win(note: Vector2i) -> bool:
	# check for win
	if current_loc == total_notes:
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

func play_note(note: NOTE, _location: Vector2i) -> void: 
	match note:
		NOTE.low_c:
			c.play()
		NOTE.d:
			d.play()
		NOTE.e:
			e.play()
		NOTE.f:
			f.play()
		NOTE.g:
			g.play()
		NOTE.a:
			a.play()
		NOTE.b:
			b.play()
		NOTE.high_c:
			c_high.play()
	if _location != Vector2i.MIN:
		# cute animation 
		pass
