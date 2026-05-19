extends Area2D

enum State { FLY, STOP }
var current_state = State.STOP

var velocity: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D

func _physics_process(delta: float) -> void:
	match current_state:
		State.FLY:
			velocity.y += gravity * delta
			global_position += velocity * delta
			global_rotation = velocity.angle()
			
			if velocity.x < 0:
				sprite.flip_v = true
			else: 
				sprite.flip_v = false
		State.STOP:
			pass

func launch(init_velocity: Vector2) -> void:
	velocity = init_velocity
	current_state = State.FLY
	
# Collision with solid terrain
func _on_body_entered(_body: Node2D) -> void:
	current_state = State.STOP
