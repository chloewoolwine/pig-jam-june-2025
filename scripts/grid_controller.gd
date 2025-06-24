extends Node2D
class_name GridController

signal update_gui(reset: bool)
signal done()

const NOTE_PLAYER = preload("res://scenes/note.tscn")

const ENV_NOTE_A = preload("res://sfx/env/notes v1/env_note_a.wav")
const ENV_NOTE_A_HIGH = preload("res://sfx/env/notes v1/env_note_a_high.wav")
const ENV_NOTE_B = preload("res://sfx/env/notes v1/env_note_b.wav")
const ENV_NOTE_B_HIGH = preload("res://sfx/env/notes v1/env_note_b_high.wav")
const ENV_NOTE_C_HIGH = preload("res://sfx/env/notes v1/env_note_c_high.wav")
const ENV_NOTE_C_LOW = preload("res://sfx/env/notes v1/env_note_c_low.wav")
const ENV_NOTE_D = preload("res://sfx/env/notes v1/env_note_d.wav")
const ENV_NOTE_D_HIGH = preload("res://sfx/env/notes v1/env_note_d_high.wav")
const ENV_NOTE_E = preload("res://sfx/env/notes v1/env_note_e.wav")
const ENV_NOTE_E_HIGH = preload("res://sfx/env/notes v1/env_note_e_high.wav")
const ENV_NOTE_F = preload("res://sfx/env/notes v1/env_note_f.wav")
const ENV_NOTE_F_HIGH = preload("res://sfx/env/notes v1/env_note_f_high.wav")
const ENV_NOTE_G = preload("res://sfx/env/notes v1/env_note_g.wav")
const ENV_NOTE_G_HIGH = preload("res://sfx/env/notes v1/env_note_g_high.wav")

@export var level_size: Vector2i
@export var total_notes: int
@export var note_order: Array[NOTE]
@export var color_order: Array[COLOR]	

@onready var player: Player = $Player
@onready var objects: Node2D = $Objects
@onready var note_holder: Node2D = $Notes

var won_level: bool
var current_loc: int # 0 indexed baby!

var live_objects: Array[Node2D]
var note_players: Array[AudioStreamPlayer2D]

enum NOTE{
	c,
	d,
	e,
	f,
	g,
	a,
	b,
	high_c,
	high_d,
	high_e,
	high_f,
	high_g,
	high_a,
	high_b
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
	
	# lol my throat hurts.
	var children = note_holder.get_children()
	for child in children:
		child.free()
	
	make_note_player(ENV_NOTE_C_LOW)
	make_note_player(ENV_NOTE_D)
	make_note_player(ENV_NOTE_E)
	make_note_player(ENV_NOTE_F)
	make_note_player(ENV_NOTE_G)
	make_note_player(ENV_NOTE_A)
	make_note_player(ENV_NOTE_B)
	make_note_player(ENV_NOTE_C_HIGH)
	make_note_player(ENV_NOTE_D_HIGH)
	make_note_player(ENV_NOTE_E_HIGH)
	make_note_player(ENV_NOTE_F_HIGH)
	make_note_player(ENV_NOTE_G_HIGH)
	make_note_player(ENV_NOTE_A_HIGH)
	make_note_player(ENV_NOTE_B_HIGH)

func make_note_player(env) -> void:
	var lc = NOTE_PLAYER.instantiate()
	note_holder.add_child(lc)
	lc.stream = env
	note_players.append(lc)

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
	for i in range(note_order.size()):
		await get_tree().create_timer(.2).timeout
		play_note(note_order[i], Vector2i.MIN);
	await get_tree().create_timer(.4).timeout
	player.play_win()

func play_note(note: NOTE, _location: Vector2i) -> void: 
	note_players[note].play()
	if _location != Vector2i.MIN:
		# cute animation 
		pass
