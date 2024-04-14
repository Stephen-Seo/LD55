extends CharacterBody2D

class_name MainCharacter

var player_controlled = false
enum GanderSceneT {
	Introduction,
	Gameplay,
	Battle,
}
var current_scene_type = GanderSceneT.Introduction
var auto_control_action = "facing_front"

var last_collided_id = null

@onready var animated = $AnimatedSprite2D

var summon_item = null
var summon_item_angle = 0.0

const SPEED = 150.0
const ANIM_DEADZONE = 0.3
const SUMMON_ITEM_DIST = 100.0
const SUMMON_ITEM_Y_OFFSET = -30.0

func _process(delta):
	summon_item_angle += delta
	if summon_item != null:
		summon_item.position.x = cos(summon_item_angle) * SUMMON_ITEM_DIST
		summon_item.position.y = sin(summon_item_angle) * SUMMON_ITEM_DIST + SUMMON_ITEM_Y_OFFSET

func _physics_process(delta):
	var vec2 = Vector2()
	if player_controlled:
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
	elif animated.animation != auto_control_action:
		animated.play(auto_control_action)

	if current_scene_type != GanderSceneT.Battle:
		move_and_slide()
		var last_collision = get_last_slide_collision()
		if last_collision != null:
			last_collided_id = last_collision.get_collider_id()
		else:
			last_collided_id = null
