extends CharacterBody2D


const SPEED = 140.0
const DECELERATION = 500.0  # Units per second when slowing to a stop


func _physics_process(delta: float) -> void:
	# 4-directional input (WASD / arrow keys via ui_* actions)
	var direction := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		velocity.x = direction.x * SPEED
		velocity.y = direction.y * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
		velocity.y = move_toward(velocity.y, 0, DECELERATION * delta)

	move_and_slide()
