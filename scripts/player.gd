extends CharacterBody2D
class_name Player

signal player_hit_note(note: Vector2i, location: Vector2i)

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_map: TileMapLayer = $"../Floor"
## IN PIXELS per delta, as in slide_speed * delta
@export var slide_speed: int
## IN SECONDS, how long it takes to walk between snow blocks
@export var walk_speed: float 

var start_position: Vector2i
var moving: bool
var direction : Vector2i
var target_position: Vector2 # often inf

var movement_tween: Tween

func _init() -> void:
	target_position = Vector2.INF
	start_position = global_position/Globals.TILE_SIZE

func reset() -> void: 
	global_position = start_position * Globals.TILE_SIZE

func _physics_process(delta: float) -> void:
	_play_anim()
	if !moving:
		var input := get_input()
		if input.x != 0 || input.y != 0:
			direction = input
			var floor_dir := get_floor_type_still()
			if floor_dir == Vector2i(8,0):
				move_to_center()
			moving = true
	else: 
		if target_position == Vector2.INF:
			var collision = self.move_and_collide(direction * slide_speed * delta)
			#print("before ollision!! ")
			if collision:
				moving = false
				target_position = Vector2.INF
				direction = Vector2i.ZERO
			#	print("collision")
		else: # we have a target position, move to it
			if not movement_tween: # this is kinda hacky but this is a jam whatever
				movement_tween = create_tween()
				movement_tween.tween_property(self, "position", target_position, walk_speed)
			if position == target_position:
				print("target achieved")
				moving = false
				target_position = Vector2.INF
				direction = Vector2i.ZERO
				movement_tween = null
			#print("after ocvlisions!!")
		
	
func get_input() -> Vector2:
	var input: Vector2
	if Input.is_action_pressed('down'):
		input.y = 1
		return input
	elif Input.is_action_pressed('up'):
		input.y = -1
		return input
	else:
		input.y = 0 
	if Input.is_action_pressed('right'):
		input.x = 1
		return input
	elif Input.is_action_pressed('left'):
		input.x = -1
		return input
	else:
		input.x = 0 
	
	return input

##tilemap collision section 
@onready var tile_detector: Area2D = $TileDetector

func _on_area_2d_body_entered(body: Node2D) -> void:
	#print("hit music node")
	if body is TileMapLayer: # it always is
		var floor_type := get_floor_type_moving()
		#print(floor_type)
		match floor_type:
			Vector2i.ZERO:
				pass
			Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0), Vector2i(5,0), Vector2i(6,0), Vector2i(7,0):
				player_hit_note.emit(floor_type, get_floor_loc_moving())
				pass
			Vector2i(8,0):
				# snow tile!!
				# stop sliding !!
				move_to_center()
				pass


##animation section
func _play_anim() -> void: 
	if moving:
		animated_sprite_2d.play("skate_down")
	else:
		animated_sprite_2d.play("default")


## helpers 

## Gets the floor type IN THE DIRECTION player is facing 
func get_floor_type_moving() -> Vector2i:
	var curr_position:Vector2i = (tile_detector.global_position) /Globals.TILE_SIZE
	var tile_loc 
	if(direction.x > 0 || direction.y > 0):
		tile_loc = curr_position + direction
	else:
		tile_loc = curr_position
	return floor_map.get_cell_atlas_coords(tile_loc)

func get_floor_type_still() -> Vector2i:
	var curr_position:Vector2i = (tile_detector.global_position) /Globals.TILE_SIZE
	var tile_loc = curr_position + direction
	return floor_map.get_cell_atlas_coords(tile_loc)

func get_floor_loc_moving() -> Vector2i:
	var curr_position:Vector2i = (tile_detector.global_position) /Globals.TILE_SIZE
	var tile_loc 
	if(direction.x > 0 || direction.y > 0):
		tile_loc = curr_position + direction
	else:
		tile_loc = curr_position
	return tile_loc

func move_to_center() -> void: 
	var tile_loc:Vector2i
	if(direction.x > 0 || direction.y > 0) || !moving:
		tile_loc = floor_map.local_to_map(Vector2i(tile_detector.global_position)) + direction
	else:
		tile_loc = floor_map.local_to_map(Vector2i(tile_detector.global_position))
	target_position = tile_loc * Globals.TILE_SIZE
	print("target_pos in move_to_center:", target_position)

#returns true if v1 is Close Enough to v2 (within 3)
func is_close_enough(v1: Vector2, v2:Vector2) -> bool:
	if(v1 == v2):
		return true
	var sub:Vector2 = abs(v1 - v2)
	if(sub.x < .1 || sub.y < .1):
		return true
	return false
