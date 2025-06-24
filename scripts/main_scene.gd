extends Node2D
class_name MainScene

@export var all_levels: Array[String]
@export var start_with: int

const MUS_BGM_1 = preload("res://other/mus_bgm1.ogg")
const MUS_BGM_2 = preload("res://other/mus_bgm2.ogg")
const MUS_TUTORIAL = preload("res://other/mus_tutorial.ogg")
@onready var backgroundmusic: AudioStreamPlayer2D = $backgroundmusic

var level_curr: int
var live_level: Level

func _ready() -> void: 
	# do initial! loading stuff here ! 
	backgroundmusic.stream = MUS_TUTORIAL
	backgroundmusic.play()
	#print(backgroundmusic.stream)
	if OS.has_feature("editor") :
		load_level(all_levels[start_with])
		level_curr = start_with
	else:
		load_level(all_levels[level_curr])

func load_level(level: String) -> void: 
	if(live_level != null):
		self.remove_child(live_level)
		live_level.call_deferred("free")
	live_level = load(level).instantiate()
	self.add_child(live_level)
	if level_curr == 3:
		print("changing background music to bg1")
		backgroundmusic.stream = MUS_BGM_1
		backgroundmusic.play()
	elif level_curr == 8:
		print("changing background music to bg2")
		backgroundmusic.stream = MUS_BGM_2
		backgroundmusic.play()
	#print('enxt level plz')
	live_level.next_scene_please.connect(handle_transition)

func handle_transition() -> void: 
	level_curr = level_curr + 1
	load_level(all_levels[level_curr])
	pass
