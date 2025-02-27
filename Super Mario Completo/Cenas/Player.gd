extends CharacterBody2D

class_name Player

enum PlayerMode{
	SMALL,
	BIG,
	SHOOTING
}

const PIPE_ENTER_THRESHOLD = 10

signal points_scored(points: int)

const POINTS_LABEL_SCENE = preload("res://Cenas/PointsLabel.tscn")
const BIG_MARIO_COLLISION_SHAPE = preload("res://Resources/CollisionShapes/big_mario_collision_shape.tres")
const SMALL_MARIO_COLLISION_SHAPE = preload("res://Resources/CollisionShapes/small_mario.tres")
const FIREBALL_SCENE = preload("res://Cenas/Fireball.tscn")

@onready var animated_sprite_2d = $AnimatedSprite2D as PlayerAnimatedSprite
@onready var area_collision_shape = $Area2D/AreaCollisionShape2D
@onready var body_collision_shape = $BodyCollisionShape2D
@onready var area_2d = $Area2D
@onready var shooting_point = $ShootingPoint

@export_group("Locomotion")
@export var run_speed_damping = 0.5
@export var speed = 180.0
@export var jump_velocity = -370
@export_group("")

@export_group("Stopimg Enemies")
@export var min_stomp_degree = 35
@export var max_stomp_degree = 145
@export var stomp_y_velocity = -150
@export_group("")

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var player_mode = PlayerMode.SMALL
var is_dead = false

func _physics_process(delta):
	
	if not is_on_floor():
		velocity.y += gravity * delta 
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	if Input.is_action_just_pressed("jump") and velocity.y < 0:
		velocity.y *= 1
	
	var direction = Input.get_axis("left", "right")
	
	if direction:
		velocity.x = lerp(velocity.x, speed * direction, run_speed_damping * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta)
	
	if Input.is_action_just_pressed("Shoot") && player_mode == PlayerMode.SHOOTING:
		shoot()
	else:
		animated_sprite_2d.trigger_animation(velocity, direction, player_mode)
	
	var collision = get_last_slide_collision()
	if collision != null:
		handle_movement_collision(collision)
	
	move_and_slide()

func _on_area_2d_area_entered(area):
	if area is Enemy:
		handle_enemy_collision(area)
	if area is Shroom:
		handle_shroom_collision(area)
		area.queue_free()
	if area is ShootingFlower:
		handle_flower_collision()
		area.queue_free()

func set_collision_shapes(is_small: bool):
	var collision_shape = SMALL_MARIO_COLLISION_SHAPE if is_small else BIG_MARIO_COLLISION_SHAPE
	area_collision_shape.set_deferred("shape", collision_shape)
	body_collision_shape.set_deferred("shape", collision_shape)

func handle_enemy_collision(enemy: Enemy):
	if enemy == null && is_dead:
		return
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	if is_instance_of(enemy, Koopa) and (enemy as Koopa).in_a_shell:
		(enemy as Koopa).on_stomp(global_position)
		spawn_points_label(enemy)
		level_manager.on_points_scored(100)
	else:
		var angle_of_collision = rad_to_deg(position.angle_to_point(enemy.position))
		
		if angle_of_collision > min_stomp_degree && max_stomp_degree > angle_of_collision:
			enemy.die()
			on_enemy_stomped()
			spawn_points_label(enemy)
			level_manager.on_points_scored(100)
		else:
			die()

func handle_shroom_collision(area: Node2D):
	if player_mode == PlayerMode.SMALL:
		set_physics_process(false)
		animated_sprite_2d.play("small_to_big")	
		set_collision_shapes(false)

func handle_flower_collision():
	set_physics_process(false)
	var animation_name = "small_to_shooting" if player_mode == PlayerMode.SMALL else "big_to_shooting"
	animated_sprite_2d.play(animation_name)
	set_collision_shapes(false)

func on_enemy_stomped():
	velocity.y = stomp_y_velocity

func spawn_points_label(enemy):
	var points_label = POINTS_LABEL_SCENE.instantiate()
	points_label.position = enemy.position + Vector2(-20, -20)
	get_tree().root.add_child(points_label)
	points_scored.emit(100)

func die():
	if player_mode == PlayerMode.SMALL:
		is_dead = true
		animated_sprite_2d.play("small_death")

		area_2d.set_collision_mask_value(3, false)
		set_collision_layer_value(1, false)

		set_physics_process(false)
		
		var death_tween = get_tree().create_tween()
		death_tween.tween_property(self, "position", position + Vector2(0, -48), .5)
		death_tween.chain().tween_property(self, "position", position + Vector2(0, 256), 1)
		death_tween.tween_callback(func (): get_tree().reload_current_scene())
		
	else:
		big_to_small()

func big_to_small():
	set_collision_layer_value(1, false)
	set_physics_process(false)
	var animation_name = "small_to_big" if player_mode == PlayerMode.BIG else "small_to_shooting"
	animated_sprite_2d.play(animation_name, 1.0, true)
	set_collision_shapes(true)

func shoot():
	animated_sprite_2d.play("shoot")
	set_physics_process(false)
	
	var fireball = FIREBALL_SCENE.instantiate()
	fireball.direction = sign(animated_sprite_2d.scale.x)
	fireball.global_position = shooting_point.global_position
	get_tree().root.add_child(fireball)

#Function to bump the brick and go down in pipe 
func handle_movement_collision(collision: KinematicCollision2D):
	if collision.get_collider() is Block:
		var collision_angle = rad_to_deg(collision.get_angle())
		if roundf(collision_angle) == 180:
			(collision.get_collider() as Block).bump(player_mode)
	
	if collision.get_collider() is Pipe:
		var collision_angle = rad_to_deg(collision.get_angle())
		if roundf(collision_angle) == 0 && Input.is_action_just_pressed("down") && absf(collision.get_collider().position.x - position.x < PIPE_ENTER_THRESHOLD && collision.get_collider().is_traversable):
			print("GO DOWN")
			handle_pipe_collision()
			

#make the collision of pipe 
func handle_pipe_collision():
	set_physics_process(false)
	z_index = -3
	var pipe_tween = get_tree().create_tween()
	pipe_tween.tween_property(self, "position", position + Vector2(0, 32), 1)
	pipe_tween.tween_callback(switch_to_underground)

#make the collision of underground pipe
func handle_pipe_connector_entrance_collision():
	set_physics_process(false)
	var pipe_tween = get_tree().create_tween()
	pipe_tween.tween_property(self, "position", position + Vector2(32, 0), 1)
	pipe_tween.tween_callback(switch_to_final)

#change to underground
func switch_to_underground():
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	SceneData.player_mode = player_mode
	SceneData.coins = level_manager.coins
	SceneData.points = level_manager.points 
	get_tree().change_scene_to_file("res://Cenas/Underground.tscn")

#change to tela final
func switch_to_final():
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	SceneData.player_mode = player_mode
	SceneData.coins = level_manager.coins
	SceneData.points = level_manager.points 
	get_tree().change_scene_to_file("res://Cenas/TelaFinal.tscn")
