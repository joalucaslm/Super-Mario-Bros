extends Enemy

class_name Koopa

const KOOPA_FULL_SHAPE = preload("res://Resources/CollisionShapes/koopa_full.tres")
const KOOPA_SHELL_SHAPE = preload("res://Resources/CollisionShapes/koopa_shell.tres")
const KOOPA_SHELL_POSITION = Vector2(0, 5)
@onready var collision_shape_2d = $CollisionShape2D
@export var slide_speed = 200
var in_a_shell = false

func _ready():
	collision_shape_2d.shape = KOOPA_FULL_SHAPE

func die():
	if !in_a_shell:
		super.die()
	
	collision_shape_2d.set_deferred("shape", KOOPA_SHELL_SHAPE)
	collision_shape_2d.set_deferred("position", KOOPA_SHELL_POSITION)
	in_a_shell = true
	

func on_stomp(player_position: Vector2):
	set_collision_layer_value(3, false)
	set_collision_mask_value(1, false)
	set_collision_layer_value(3, false)
	
	var movement_direction = 1 if player_position.x <= global_position.x else -1
	horizontal_speed = -movement_direction * slide_speed
