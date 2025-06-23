extends Control
class_name GUI 

# small panel
@onready var panel_container: PanelContainer = $PanelContainer

@onready var little: TextureRect = $PanelContainer/MarginContainer/LittleContainer/LITTLE
@onready var little_container: HBoxContainer = $PanelContainer/MarginContainer/LittleContainer
#@onready var big: TextureRect = $PanelContainer2/HBoxContainer/MarginContainer/HBoxContainer/BIG
#@onready var big_container: HBoxContainer = $PanelContainer2/HBoxContainer/MarginContainer/BigContainer

## big panel
#@onready var timer: RichTextLabel = $PanelContainer2/HBoxContainer/MarginContainer3/timer
#@onready var levelname: RichTextLabel = $PanelContainer2/HBoxContainer/MarginContainer2/levelname

@export var empty_boxes: Array[Texture]
@export var filled_boxes: Array[Texture]
#
#@export var big_empty_boxes: Array[Texture]
#@export var big_filled_boxes: Array[Texture]

var note_textures: Array[TextureRect]
#var big_textures: Array[TextureRect]

var total_notes: int
var curr_note: int 

var total_seconds: int
var start_secs: int 

func _ready() -> void:
	print(little)
	total_seconds = 0
	start_secs = Time.get_ticks_msec()

#func set_level_name(new:String) -> void:
	#if levelname:
		#levelname.text = new
#
#func _process(delta: float) -> void:
	#if timer:
		#timer.text = calculate_curr_time()

func calculate_curr_time() -> String:
	var miliseconds := Time.get_ticks_msec() - start_secs
	var minutes = (miliseconds/1000)/60
	var seconds = (miliseconds/1000)%60
	return "%02d:%02d" % [minutes,seconds]

func set_total(total: int, color_order: Array[GridController.COLOR]) -> void:
	print("gui total notes recieved: ", total)
	print(little)
	little.texture = empty_boxes[color_order[0]]
	total_notes = total
	note_textures.append(little)
	for x in range(1, total_notes):
		var new = little.duplicate()
		new.texture = empty_boxes[color_order[x]]
		little_container.add_child(new)
		note_textures.append(new)
	panel_container.size.x = 7 + (8 * (total-1))

func update(reset: bool) -> void: 
	if reset:
		_reset()
	else:
		_hit_note()

func _reset() -> void: 
	curr_note = 0
	for x in note_textures.size():
		note_textures[x].texture = empty_boxes[x] 

func _hit_note() -> void: 
	if curr_note < note_textures.size():
		note_textures[curr_note].texture = filled_boxes[curr_note]
	curr_note = curr_note + 1
