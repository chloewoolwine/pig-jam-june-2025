extends Control
class_name GUI 

@onready var panel_container: PanelContainer = $PanelContainer

@onready var red: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/red
@onready var orange: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/orange
@onready var yellow: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/yellow
@onready var green: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/green
@onready var blue: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/blue
@onready var purple: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/purple
@onready var pink: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/pink

@export var empty_boxes: Array[Texture]
@export var filled_boxes: Array[Texture]

var note_textures: Array[TextureRect]

var total_notes: int
var curr_note: int 

func _ready() -> void:
	note_textures = [ red, orange, yellow, green, blue, purple, pink ]

func set_total(total: int) -> void:
	print("gui total notes recieved: ", total)
	total_notes = total
	for x in range(note_textures.size()):
		if x < total: 
			note_textures[x].texture = empty_boxes[x]
		else:
			note_textures[x].visible = false
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
