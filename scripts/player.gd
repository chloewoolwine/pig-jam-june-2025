extends CharacterBody2D
class_name Player

signal player_hit_note(note: Vector2i, location: Vector2i)
signal player_died()

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

var block_push_direction: Vector2

var skating: bool # two modes- skating and walking

var movement_tween: Tween

func _ready() -> void:
	start_position = global_position
	accepting_input = true

func reset() -> void: 
	print("player start position: ", start_position)
	global_position = start_position
	moving = false
	direction = Vector2i.ZERO
	input_timer(.2)

func _physics_process(delta: float) -> void:
	if !movement_tween:
		play_skate_or_idle_anim()
	if !moving:
		global_position = global_position.snapped(Vector2(20,20))
		if skate.playing:
			skate.stop()
		var input := get_input()
		block_push_direction = input
		if input.x != 0 || input.y != 0:
			prev_direction = input
			direction = input
			#print("floor type still ",get_floor_type_still())
			#print("current pos: ", normalized_global()/Globals.TILE_SIZE)
			skating = is_ice(get_floor_type_still())
			if !skating:
				#for snow->snow collisions
				make_tween(floor_map)
			moving = true
	else: 
		var collision = self.move_and_collide(direction * slide_speed * delta)
		#print("before ollision!! ")
		#this should really only hit blocks
		if collision:
			moving = false
			skating = false
			prev_direction = direction
			direction = Vector2i.ZERO

func die() -> void:
	input_timer(1)
	player_died.emit()
	reset()

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

##animation and sounds
func make_tween(body: TileMapLayer) -> void: 
	if (immovable_block_at_space(get_floor_type_still())):
		moving = false
		return
	moving = true
	skate.stop()
	animated_sprite_2d.stop()
	skating = false
	movement_tween = create_tween()
	var target:Vector2 = (body.local_to_map(Vector2i(global_position)) + direction) * Globals.TILE_SIZE
	#print("target tile: ", target)
	movement_tween.tween_property(self, "global_position", target, walk_speed)
	play_step_anim()
	play_step()
	#print('tweein')
	await movement_tween.finished
	print('tween done')
	prev_direction = direction
	direction = Vector2.ZERO
	movement_tween = null
	moving = false
	animated_sprite_2d.stop()
	input_timer(.2)
	
func play_skate_or_idle_anim() -> void: 
	if grid_controller.won_level:
		return
	if moving:
		if skating:
			if !skate.playing:
				skate.play()
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

func play_step_anim() -> void: 
	match direction:
		Vector2i(1,0):
			animated_sprite_2d.play("walk_right")
		Vector2i(-1,0):
			animated_sprite_2d.play("walk_left")
		Vector2i(0,1):
			animated_sprite_2d.play("skate_down")
		Vector2i(0,-1):
			animated_sprite_2d.play("skate_up")

func play_win() -> void: 
	animated_sprite_2d.play("win")

func play_step() -> void: #TODO this is dumb just sync it up to the walk when we have it 
	await get_tree().create_timer(.1).timeout 
	step.play()
	
## AREAS 
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
		pass
	# collided with wall
	if body is TileMapLayer:
		#print("collided with tilemap in direction: ", collision_dir)
		if body.name == "Wall":
			if (direction == collision_dir): #validate we are moving to the right
				#print("stopping moving, collision dir equals moving dir")
				moving = false
				direction = Vector2i.ZERO
		elif body.name == "Floor":
			if(!is_ice(get_floor_type_moving()) && !movement_tween):
				#for ice->snow collisions
				make_tween(body)

func _on_floor_detector_body_entered(body: Node2D) -> void:
	#print("hit music node")
	if body is TileMapLayer: 
		var floor_type := get_floor_type_moving()
		#print(floor_type)
		match floor_type:
			Vector2i.ZERO:
				pass
			Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0), Vector2i(5,0), Vector2i(6,0), Vector2i(7,0),  Vector2i(6,1), Vector2i(6,2), Vector2i(6,3), Vector2i(6,4), Vector2i(7,1), Vector2i(7,2), Vector2i(7,3), Vector2i(7,4):
				player_hit_note.emit(floor_type, get_floor_loc_moving())
				pass
			Vector2i(0,1), Vector2i(0,2), Vector2i(0,3), Vector2i(1,1), Vector2i(1,2), Vector2i(1,3), Vector2i(2,1), Vector2i(2,2), Vector2i(2,3), Vector2i(2,4), Vector2i(3,1), Vector2i(3,2), Vector2i(3,3), Vector2i(3,4),Vector2i(4,1), Vector2i(4,2), Vector2i(4,3), Vector2i(4,4), Vector2i(5,1), Vector2i(5,2), Vector2i(5,3), Vector2i(5,4):
				#this should rarely, if ever, happen
				if !movement_tween:
					make_tween(body)
			Vector2i(9,4):
				## DIE 
				die()
				pass
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

func normalized_global() -> Vector2:
	return global_position + Vector2(10, 10)

func is_ice(floor_type: Vector2i) -> bool: # ice or snow
	match floor_type:
		Vector2i(0,1), Vector2i(0,2), Vector2i(0,3), Vector2i(1,1), Vector2i(1,2), Vector2i(1,3), Vector2i(2,1), Vector2i(2,2), Vector2i(2,3), Vector2i(2,4), Vector2i(3,1), Vector2i(3,2), Vector2i(3,3), Vector2i(3,4),Vector2i(4,1), Vector2i(4,2), Vector2i(4,3), Vector2i(4,4), Vector2i(5,1), Vector2i(5,2), Vector2i(5,3), Vector2i(5,4):
			return false
	return true

func is_hole(floor_type: Vector2i) -> bool:
	return floor_type == Vector2i(9,4)

func input_timer(time:float) -> void: 
	accepting_input = false
	await get_tree().create_timer(time).timeout
	accepting_input = true

func immovable_block_at_space(targ: Vector2) -> bool:
	var node := grid_controller.get_object_at_space(targ) 
	if node != null:
		if node is Block:
			print("node is block")
			return !node.is_valid_dir_to_move((targ-global_position),((targ-global_position) * -1).normalized())
	return false
