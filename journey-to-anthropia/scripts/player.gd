extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -275.0
var direction: float = 0.0

@export var arrow_scene: PackedScene
@export var has_bow: bool = true:
	set(value):
		has_bow = value
# arrow params
var max_speed: float = 300.0
var min_speed_pct: float = 0.1
var max_pull_distance: float = 100.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var trajectory_line: Line2D = $Line2D

func _physics_process(delta: float) -> void:
	direction = Input.get_axis("move_left", "move_right")
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif is_on_floor() and direction:
		animated_sprite.play("running")
	elif animated_sprite.animation not in ["idle-blink", "idle-no-blink"]:
		animated_sprite.play("idle-no-blink")
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		animated_sprite.play("jump")	
	
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Bow and arrow functionality
	if has_bow:
		trajectory_line.visible = true
		update_trajectory(delta)
		
		if Input.is_action_just_pressed("shoot"):
			shoot_arrow()
	else:
		trajectory_line.visible = false

	move_and_slide()

func _on_animation_finished() -> void:
	if is_on_floor() and not direction:
		if randf() < 0.2:
			animated_sprite.play("idle-blink")
		else: 
			animated_sprite.play("idle-no-blink")

func calculate_arrow_velocity() -> Vector2:
	var mouse_pos = get_global_mouse_position()
	var distance = global_position.distance_to(mouse_pos)
	var aim_angle = global_position.angle_to_point(mouse_pos)
	var force_pct = clamp(distance / max_pull_distance, min_speed_pct, 1.0)
	
	return Vector2.RIGHT.rotated(aim_angle) * force_pct * max_speed

func shoot_arrow() -> void:
	if not arrow_scene:
		print("Warning: No arrow scene assigned to the player!")
		return	
		
	var mouse_pos = get_global_mouse_position()
	var arrow_instance = arrow_scene.instantiate()
	
	arrow_instance.global_position = global_position 
	arrow_instance.rotation = global_position.angle_to_point(mouse_pos) 
	get_tree().current_scene.add_child(arrow_instance)
	arrow_instance.launch(calculate_arrow_velocity())
	

func update_trajectory(delta: float) -> void:
	trajectory_line.clear_points()
	
	var temp_arrow = arrow_scene.instantiate()  
	var arrow_gravity = temp_arrow.gravity
	temp_arrow.queue_free()
	
	var sim_velocity = calculate_arrow_velocity()
	var sim_pos = Vector2.ZERO
	var max_steps = 15 
	
	for i in range(max_steps):
		if i > 1:
			trajectory_line.add_point(sim_pos)
		sim_velocity.y += arrow_gravity * delta
		sim_pos += sim_velocity * delta
