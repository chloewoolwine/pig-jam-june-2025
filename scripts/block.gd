extends StaticBody2D
class_name Block

signal block_hit_note(note: Vector2i, location: Vector2i)

## IN PIXELS per delta, as in slide_speed * delta
@export var slide_speed: int
@export var walk_speed: float
@onready var left_area: Area2D = $LeftArea
@onready var up_area: Area2D = $UpArea
@onready var right_area: Area2D = $RightArea
@onready var down_area: Area2D = $DownArea
@onready var floor_detector: Area2D = $FloorDetector

var moving: bool
var direction: Vector2i

var start_position: Vector2

func _ready() -> void:
	start_position = global_position
	
func _physics_process(delta: float) -> void:
	if !moving:
		global_position = global_position.snapped(Vector2(20,20))
	else:
		var collision = self.move_and_collide(direction * slide_speed * delta)

func _on_left_area_body_entered(body: Node2D) -> void:
	handle_move(Vector2i(-1, 0), body)


func _on_up_area_body_entered(body: Node2D) -> void:
	handle_move(Vector2i(0, -1), body)


func _on_right_area_body_entered(body: Node2D) -> void:
	handle_move(Vector2i(1, 0), body)


func _on_down_area_body_entered(body: Node2D) -> void:
	handle_move(Vector2i(0, 1), body)

func handle_move(collision_dir: Vector2i, body: Node2D) -> void: 
	#print("im a block. and this. is my name: ", self.name)
	if body is Player:
		#print("collided with player in direction: ", collision_dir)
		if is_valid_dir_to_move(body.block_push_direction, collision_dir):
			direction = body.block_push_direction
			moving = true
			#print("moving direction ", direction)
			body.input_timer(.5)
	if body is TileMapLayer:
		#print("collided with tilemap in direction: ", collision_dir)
		if (direction == collision_dir): #validate we are moving to the right
			#print("stopping moving, collision dir equals moving dir")
			moving = false
			direction = Vector2i.ZERO
	if body is Block:
		if (direction == collision_dir):
			## TODO: inertia !
			moving = false
			direction = Vector2i.ZERO
			
func is_valid_dir_to_move(move_dir: Vector2i, collision_dir: Vector2i) -> bool:
	#print("requested move direction: ", move_dir)
	if (move_dir * -1) != collision_dir:
		#print("requested move direction does not equal collision dir: ", collision_dir)
		return false
	var bodies:Array[Node2D]
	match move_dir:
		Vector2i(1, 0):
			bodies = right_area.get_overlapping_bodies()
		Vector2i(-1, 0):
			bodies = left_area.get_overlapping_bodies()
		Vector2i(0, -1):
			bodies = up_area.get_overlapping_bodies()
		Vector2i(0, 1):
			bodies = down_area.get_overlapping_bodies()
	if bodies.size() > 1:
		#print("false, overlapping bodies:", bodies)
		return false
	#print("begining move")
	return true


func _on_floor_detector_body_entered(body: Node2D) -> void:
	print("collision")
	if body is TileMapLayer: # it always is
		# get floor type, match floor type
		var floor_pos:Vector2 = normalized_global()/Globals.TILE_SIZE
		var floor:Vector2i= body.get_cell_atlas_coords(normalized_global()/Globals.TILE_SIZE)
		match floor:
			Vector2i.ZERO:
				pass
			Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0), Vector2i(5,0), Vector2i(6,0), Vector2i(7,0),  Vector2i(6,1), Vector2i(6,2), Vector2i(6,3), Vector2i(6,4), Vector2i(7,1), Vector2i(7,2), Vector2i(7,3), Vector2i(7,4):
				block_hit_note.emit(floor, normalized_global()/Globals.TILE_SIZE)
				pass
			Vector2i(0,1), Vector2i(0,2), Vector2i(0,3), Vector2i(1,1), Vector2i(1,2), Vector2i(1,3), Vector2i(2,1), Vector2i(2,2), Vector2i(2,3), Vector2i(2,4), Vector2i(3,1), Vector2i(3,2), Vector2i(3,3), Vector2i(3,4),Vector2i(4,1), Vector2i(4,2), Vector2i(4,3), Vector2i(4,4), Vector2i(5,1), Vector2i(5,2), Vector2i(5,3), Vector2i(5,4):
				# snow tile!!
				# stop sliding !!
				var movement_tween := create_tween()
				var target:Vector2 
				if(direction.x > 0 || direction.y > 0) || !moving:
					target = (body.local_to_map(Vector2i(global_position)) + direction) * Globals.TILE_SIZE
				else:
					target = body.local_to_map(Vector2i(global_position)) * Globals.TILE_SIZE
				movement_tween.tween_property(self, "global_position", target, walk_speed)
				moving = false
				direction = Vector2.ZERO

func normalized_global() -> Vector2:
	return global_position + Vector2(10, 10) # should always be the exact center of the block

func resent() -> void: 
	global_position = start_position 
	moving = false
	direction = Vector2i.ZERO
