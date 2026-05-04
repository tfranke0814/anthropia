extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -275.0
var direction: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

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

	move_and_slide()


func _on_animation_finished() -> void:
	if is_on_floor() and not direction:
		if randf() < 0.2:
			animated_sprite.play("idle-blink")
		else: 
			animated_sprite.play("idle-no-blink")
