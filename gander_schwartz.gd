extends CharacterBody2D

@onready var animated = $AnimatedSprite2D

const SPEED = 150.0
const ANIM_DEADZONE = 0.3

func _physics_process(delta):
	var vec2 = Vector2()
	if Input.is_action_pressed("Left"):
		vec2.x = -1.0
	elif Input.is_action_pressed("Right"):
		vec2.x = 1.0
	if Input.is_action_pressed("Up"):
		vec2.y = -1.0
	elif Input.is_action_pressed("Down"):
		vec2.y = 1.0
	
	if vec2.length() > 0.1:
		vec2 = vec2.normalized()
	else:
		vec2.x = 0.0
		vec2.y = 0.0
	
	if vec2.x > ANIM_DEADZONE:
		animated.play("walking_right")
	elif vec2.x < -ANIM_DEADZONE:
		animated.play("walking_left")
	elif vec2.y > ANIM_DEADZONE:
		animated.play("walking_front")
	elif vec2.y < -ANIM_DEADZONE:
		animated.play("walking_back")
	else:
		match animated.animation:
			"walking_right":
				animated.play("facing_right")
			"walking_left":
				animated.play("facing_left")
			"walking_front":
				animated.play("facing_front")
			"walking_back":
				animated.play("facing_back")
			_:
				pass
		
	velocity = vec2 * SPEED

	move_and_slide()
