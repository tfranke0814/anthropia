extends CharacterBody2D

const SPEED = 85.0
const JUMP_VELOCITY = -275.0
var direction: float = 0.0

# Hardcoded frame based on arm sprite sheet
const AIM_FRAME_STRAIGHT: int = 32
const AIM_FRAME_UP: int = 33
const AIM_FRAME_DOWN: int = 34

@export var arrow_scene: PackedScene
@export var has_bow: bool = true:
	set(value):
		has_bow = value
# arrow params
var max_speed: float = 300.0
var min_speed_pct: float = 0.1
var max_pull_distance: float = 100.0

@onready var body_sprite: Sprite2D = $BodySprite
@onready var arms_sprite: Sprite2D = $ArmsSprite
@onready var animation_player: AnimationPlayer = $BodyAnimationPlayer
@onready var trajectory_line: Line2D = $Line2D

@onready var bow_pivot: Node2D = $BowPivot
@onready var bow_sprite: Sprite2D = $BowPivot/BowSprite
const HAND_OFFSET_STRAIGHT: Vector2 = Vector2(5, 0)
const HAND_OFFSET_UP: Vector2 = Vector2(5, -3)
const HAND_OFFSET_DOWN: Vector2 = Vector2(4, 3)
const LEFT_FACING_NUDGE: Vector2 = Vector2(0, -2)

func _physics_process(delta: float) -> void:
	direction = Input.get_axis("move_left", "move_right")
	
	# Movement
	if not is_on_floor():
		velocity += get_gravity() * delta
		if velocity.y > 0 and animation_player.current_animation not in ["", "jump", "fall"]:
			animation_player.play("fall")
	elif is_on_floor() and direction:
		animation_player.play("running")
	elif animation_player.current_animation not in ["idle-blink", "idle-no-blink"]:
		animation_player.play("idle-no-blink")
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		animation_player.play("jump")	
		
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if has_bow and Input.is_action_pressed("aim"):
			if Input.is_action_just_pressed("shoot"):
				shoot_arrow()
	
	move_and_slide()

func _process(delta: float) -> void:
	if has_bow and Input.is_action_pressed("aim"):
		trajectory_line.visible = true
		bow_pivot.visible = true
		update_trajectory(delta)
		
		var facing_left = get_global_mouse_position().x < global_position.x
		body_sprite.flip_h = facing_left
		arms_sprite.flip_h = facing_left
		
		if animation_player.current_animation in ["idle-no-blink", "idle-blink"]:
			animation_player.play("idle-aim-default")
			
		var arrow_vel: Vector2 = calculate_arrow_velocity()
		var current_hand_offset: Vector2
		if facing_left:
			arrow_vel.x = -arrow_vel.x
		var deg: float = rad_to_deg(arrow_vel.angle())
		
		if deg < -20.0 and deg > -90.0:
			arms_sprite.frame = AIM_FRAME_UP
			current_hand_offset = HAND_OFFSET_UP
		elif deg > 20.0 and deg < 90.0:
			arms_sprite.frame = AIM_FRAME_DOWN
			current_hand_offset = HAND_OFFSET_DOWN
		else:
			arms_sprite.frame = AIM_FRAME_STRAIGHT
			current_hand_offset = HAND_OFFSET_STRAIGHT
		
		if facing_left:
			current_hand_offset.x = -current_hand_offset.x
			current_hand_offset += LEFT_FACING_NUDGE
		bow_pivot.position = current_hand_offset
		bow_pivot.rotation = global_position.angle_to_point(get_global_mouse_position())
		bow_sprite.flip_v = facing_left

	else:
		trajectory_line.visible = false
		bow_pivot.visible = false
		if direction > 0:
			body_sprite.flip_h = false
			arms_sprite.flip_h = false
		elif direction < 0:
			body_sprite.flip_h = true
			arms_sprite.flip_h = true
		arms_sprite.frame = body_sprite.frame

func _on_animation_finished() -> void:
	if is_on_floor() and not direction:
		if randf() < 0.2:
			animation_player.play("idle-blink")
		else: 
			animation_player.play("idle-no-blink")

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
	
	arrow_instance.global_position = bow_pivot.global_position 
	arrow_instance.rotation = global_position.angle_to_point(mouse_pos) 
	get_tree().current_scene.add_child(arrow_instance)
	arrow_instance.launch(calculate_arrow_velocity())
	

func update_trajectory(delta: float) -> void:
	trajectory_line.clear_points()
	
	var temp_arrow = arrow_scene.instantiate()  
	var arrow_gravity = temp_arrow.gravity
	temp_arrow.queue_free()
	
	var sim_velocity = calculate_arrow_velocity()
	var sim_pos = bow_pivot.position
	var max_steps = 15 
	
	for i in range(max_steps):
		if i > 1:
			trajectory_line.add_point(sim_pos)
		sim_velocity.y += arrow_gravity * delta
		sim_pos += sim_velocity * delta
