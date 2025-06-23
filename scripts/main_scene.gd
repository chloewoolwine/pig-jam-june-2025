extends Node2D
class_name MainScene

@export var all_levels: Array[String]

var level_curr: int
var live_level: Level

func _ready() -> void: 
	# do initial! loading stuff here ! 
	load_level(all_levels[level_curr])

func load_level(level: String) -> void: 
	if(live_level != null):
		self.remove_child(live_level)
		live_level.call_deferred("free")
	live_level = load(level).instantiate()
	self.add_child(live_level)
	
	live_level.next_scene_please.connect(handle_transition)

func handle_transition() -> void: 
	level_curr = level_curr + 1
	load_level(all_levels[level_curr])
	pass
