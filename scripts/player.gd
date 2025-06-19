extends CharacterBody2D
class_name Player

signal player_hit_note(note: Vector2i, location: Vector2i)

@onready var grid_controller: GridController = $".."
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_map: TileMapLayer = $"../Floor"
@onready var wall_map: TileMapLayer = $"../Wall"

# sounds
@onready var skate: AudioStreamPlayer2D = $SoundEffects/skate
@onready var step: AudioStreamPlayer2D = $SoundEffects/step

@onready var left_area: Area2D = $LeftArea
@onready var up_area: Area2D = $UpArea
@onready var right_area: Area2D = $RightArea
@onready var down_area: Area2D = $DownArea
@onready var floor_detector: Area2D = $FloorDetector

## IN PIXELS per delta, as in slide_speed * delta
@export var slide_speed: int
## IN SECONDS, how long it takes to walk between snow blocks
@export var walk_speed: float 

var accepting_input: bool

var start_position: Vector2
var moving: bool
var prev_direction: Vector2i
var direction : Vector2i
var target_position: Vector2 # often inf

var block_push_direction: Vector2

var movement_tween: Tween

func _ready() -> void:
	start_position = global_position
	target_position = Vector2.INF
	accepting_input = true

func reset() -> void: 
	print("start position: ", start_position)
	global_position = start_position
	moving = false
	direction = Vector2i.ZERO
	target_position = Vector2.INF
	input_timer(.2)

func _physics_process(delta: float) -> void:
	_play_anim()
	if !moving:
		global_position = global_position.snapped(Vector2(20,20))
		if skate.playing:
			skate.stop()
		var input := get_input()
		block_push_direction = input
		if input.x != 0 || input.y != 0:
			prev_direction = input
			direction = input
			var floor_dir := get_floor_type_still()
			skate.play()
			moving = true
			# align self with center
	else: 
		if target_position == Vector2.INF:
			var collision = self.move_and_collide(direction * slide_speed * delta)
			#print("before ollision!! ")
			if collision:
				moving = false
				target_position = Vector2.INF
				prev_direction = direction
				direction = Vector2i.ZERO
			#	print("collision")
		else: # we have a target position, move to it
			if not movement_tween: # this is kinda hacky but this is a jam whatever
				movement_tween = create_tween()
				movement_tween.tween_property(self, "position", target_position, walk_speed)
			if position == target_position:
				#print("target achieved")
				moving = false
				target_position = Vector2.INF
				prev_direction = direction
				direction = Vector2i.ZERO
				movement_tween = null
			#print("after ocvlisions!!")

func play_step() -> void: #TODO this is dumb just sync it up to the walk when we have it 
	await get_tree().create_timer(.1).timeout 
	step.play()

# INPUT VALIDATORS
func get_input() -> Vector2:
	if grid_controller.won_level || !accepting_input:
		return Vector2i.ZERO
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

func input_timer(time:float) -> void: 
	accepting_input = false
	await get_tree().create_timer(time).timeout
	accepting_input = true

func immovable_block_at_space(targ: Vector2) -> bool:
	var node := grid_controller.get_object_at_space(targ) 
	if node != null:
		if node is Block:
			return !node.is_valid_dir_to_move((targ-global_position),((targ-global_position) * -1).normalized())
	return false
	
##animation section
func _play_anim() -> void: 
	if grid_controller.won_level:
		return
	if moving:
		if movement_tween:
			match direction:
				Vector2i(1,0):
					animated_sprite_2d.play("walk_right")
				Vector2i(-1,0):
					animated_sprite_2d.play("walk_left")
				Vector2i(0,1):
					animated_sprite_2d.play("skate_down")
				Vector2i(0,-1):
					animated_sprite_2d.play("skate_up")
		else:
			match direction:
				Vector2i(1,0):
					animated_sprite_2d.play("walk_right")
				Vector2i(-1,0):
					animated_sprite_2d.play("walk_left")
				Vector2i(0,1):
					animated_sprite_2d.play("skate_down")
				Vector2i(0,-1):
					animated_sprite_2d.play("skate_up")
	else:
		match prev_direction:
			Vector2i(1,0):
				animated_sprite_2d.play("idle_right")
			Vector2i(-1,0):
				animated_sprite_2d.play("idle_left")
			Vector2i(0,1):
				animated_sprite_2d.play("default")
			Vector2i(0,-1):
				animated_sprite_2d.play("idle_up")

func play_win() -> void: 
	animated_sprite_2d.play("win")

## helpers 

## Gets the floor type IN THE DIRECTION player is facing 
func get_floor_type_moving() -> Vector2i:
	#print(tile_loc, " ", curr_position)
	return floor_map.get_cell_atlas_coords(get_floor_loc_moving())

func get_floor_loc_moving() -> Vector2i:
	return (normalized_global()) /Globals.TILE_SIZE
	
func get_floor_type_still() -> Vector2i:
	var curr_position:Vector2i = normalized_global()/Globals.TILE_SIZE
	return floor_map.get_cell_atlas_coords(curr_position + direction)

func move_to_center() -> void: 
	var tile_loc:Vector2i
	if(direction.x > 0 || direction.y > 0) || !moving:
		tile_loc = floor_map.local_to_map(normalized_global()) + direction
	else:
		tile_loc = floor_map.local_to_map(normalized_global())
	#check if there is a block living there!!! 
	if !immovable_block_at_space(tile_loc * Globals.TILE_SIZE):
		target_position = tile_loc * Globals.TILE_SIZE
	#print("target_pos in move_to_center:", target_position)

#returns true if v1 is Close Enough to v2 (within 3)
func is_close_enough(v1: Vector2, v2:Vector2) -> bool:
	if(v1 == v2):
		return true
	var sub:Vector2 = abs(v1 - v2)
	if(sub.x < .1 || sub.y < .1):
		return true
	return false

func is_snowy_floor(floor_loc: Vector2i) -> bool:
	return floor_loc == Vector2i(1,4) || floor_loc == Vector2i(0,5) || floor_loc == Vector2i(0,6) || floor_loc == Vector2i(0,7) || floor_loc == Vector2i(2,6) || floor_loc == Vector2i(2,7) 

func normalized_global() -> Vector2:
	return global_position + Vector2(10, 10)


func _on_left_area_body_entered(body: Node2D) -> void:
	handle_move(Vector2i(-1, 0), body)


func _on_up_area_body_entered(body: Node2D) -> void:
	handle_move(Vector2i(0, -1), body)


func _on_right_area_body_entered(body: Node2D) -> void:
	handle_move(Vector2i(1, 0), body)


func _on_down_area_body_entered(body: Node2D) -> void:
	handle_move(Vector2i(0, 1), body)

func handle_move(collision_dir: Vector2i, body: Node2D) -> void: 
	if body is Block:
		print("bloooock")
	# collided with wall
	if body is TileMapLayer:
		#print("collided with tilemap in direction: ", collision_dir)
		if (direction == collision_dir): #validate we are moving to the right
			#print("stopping moving, collision dir equals moving dir")
			moving = false
			direction = Vector2i.ZERO


func _on_floor_detector_body_entered(body: Node2D) -> void:
	#print("hit music node")
	if body is TileMapLayer: 
		var floor_type := get_floor_type_moving()
		#print(floor_type)
		match floor_type:
			Vector2i.ZERO:
				pass
			Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0), Vector2i(5,0), Vector2i(6,0), Vector2i(7,0):
				player_hit_note.emit(floor_type, get_floor_loc_moving())
				pass
			Vector2i(1,4), Vector2i(0,5), Vector2i(0,6), Vector2i(0,7), Vector2i(2,6), Vector2i(2,7):
				var movement_tween := create_tween()
				var target:Vector2 
				if(direction.x > 0 || direction.y > 0) || !moving:
					target = (body.local_to_map(Vector2i(global_position)) + direction) * Globals.TILE_SIZE
				else:
					target = body.local_to_map(Vector2i(global_position)) * Globals.TILE_SIZE
				movement_tween.tween_property(self, "global_position", target, walk_speed)
				moving = false
				play_step()
				prev_direction = direction
				direction = Vector2.ZERO
