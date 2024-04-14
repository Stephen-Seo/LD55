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

@onready var parry_area = $ParryArea2D
@onready var hit_area = $HitArea2D

@onready var animated = $AnimatedSprite2D

var battle_started = false

var max_health = 30
var health = 30
var health_dirty = true

var summon_item = null
var summon_item_angle = 0.0
var summon_item_summoned = false
var summon_tween

var parry_tween = null

var parry_active = false
var parry_body = null
var hit_active = false
var parry_success = false
var parry_success_checked = false

enum AttackType {
	SWORD,
	HAMMER,
}

var attack_target = null
var attack_tween = null
var attack_type = AttackType.SWORD

const SPEED = 150.0
const ANIM_DEADZONE = 0.3
const SUMMON_ITEM_DIST = 100.0
const SUMMON_ITEM_Y_OFFSET = -30.0

func parry_entered(node):
	parry_active = true
	parry_success_checked = false
	parry_body = node
func parry_exited(node):
	parry_active = false
	parry_body = null
	if battle_started:
		if parry_success:
			print("Successful parry")
			parry_success = false
		else:
			print("Failed to parry")
			var rng = RandomNumberGenerator.new()
			health -= rng.randi_range(1, 5)
			health_dirty = true

func hit_entered(node):
	hit_active = true
func hit_exited(node):
	hit_active = false

func _ready():
	parry_area.area_entered.connect(parry_entered)
	parry_area.area_exited.connect(parry_exited)
	hit_area.area_entered.connect(hit_entered)
	hit_area.area_exited.connect(hit_exited)

func _process(delta):
	if parry_tween == null and attack_target == null:
		summon_item_angle += delta
		if summon_item_angle > TAU:
			summon_item_angle -= TAU
		if summon_item != null and not parry_success:
			summon_item.position.x = cos(-summon_item_angle) * SUMMON_ITEM_DIST
			summon_item.position.y = sin(-summon_item_angle) * SUMMON_ITEM_DIST + SUMMON_ITEM_Y_OFFSET
		elif parry_success and not parry_success_checked and parry_body != null:
			parry_success_checked = true
			parry_tween = get_tree().create_tween()
			parry_tween.set_parallel()
			parry_tween.set_trans(Tween.TRANS_SPRING)
			var between = parry_body.get_parent().position - self.position
			parry_tween.tween_property(summon_item, "position", between, 0.2)
			parry_tween.set_trans(Tween.TRANS_EXPO)
			parry_tween.tween_property(summon_item, "rotation", TAU * 10, 0.3)
			parry_tween.set_parallel(false)
			var old_x = cos(-summon_item_angle) * SUMMON_ITEM_DIST
			var old_y = sin(-summon_item_angle) * SUMMON_ITEM_DIST + SUMMON_ITEM_Y_OFFSET
			parry_tween.set_trans(Tween.TRANS_EXPO)
			parry_tween.tween_property(summon_item, "position", Vector2(old_x, old_y), 0.4)
			parry_tween.tween_callback(func():
				parry_tween = null
				summon_item.rotation = 0.0
			)
	elif attack_target != null and summon_item != null:
		attack_tween = get_tree().create_tween()
		var prev_x = cos(-summon_item_angle) * SUMMON_ITEM_DIST
		var prev_y = sin(-summon_item_angle) * SUMMON_ITEM_DIST + SUMMON_ITEM_Y_OFFSET
		attack_tween.set_parallel()
		attack_tween.tween_property(summon_item, "position", attack_target.position - self.position, 0.2)
		attack_tween.tween_property(summon_item, "rotation", -PI / 2.0, 0.2)
		attack_tween.set_parallel(false)
		var parent = get_parent()
		attack_tween.tween_callback(func():
			match attack_type:
				AttackType.SWORD:
					parent.play_attack_sfx_type = "sword"
				AttackType.HAMMER:
					parent.play_attack_sfx_type = "hammer"
		)
		attack_tween.set_parallel()
		attack_tween.tween_property(summon_item, "position", Vector2(prev_x, prev_y), 0.4)
		attack_tween.tween_property(summon_item, "rotation", 0.0, 0.4)
		attack_tween.set_parallel(false)
		attack_tween.tween_callback(func():
			attack_target = null
		)
		
	if summon_item_summoned:
		summon_item_summoned = false
		var summon_overlay = Sprite2D.new()
		summon_overlay.set_name(&"SummonOverlay")
		summon_overlay.set_texture(summon_item.get_texture())
		add_child(summon_overlay, true)
		summon_overlay.set_owner(self)
		summon_overlay.set_scale(Vector2(5.0, 5.0))
		summon_overlay.self_modulate = Color(1.0, 1.0, 1.0, 0.4)
		summon_tween = get_tree().create_tween()
		summon_tween.set_parallel()
		summon_tween.set_trans(Tween.TRANS_EXPO)
		summon_tween.tween_property(summon_overlay, "rotation", -TAU * 50.0, 2.0)
		summon_tween.set_trans(Tween.TRANS_QUAD)
		summon_tween.tween_property(summon_overlay, "self_modulate", Color(1.0, 1.0, 1.0, 0.0), 2.0)
		summon_tween.set_parallel(false)
		summon_tween.tween_callback(func(): self.remove_child(summon_overlay))
	if health_dirty:
		health_dirty = false
		var hp_label = find_child("PlayerHPLabel")
		if hp_label == null:
			hp_label = Label.new()
			hp_label.set_name(&"PlayerHPLabel")
			add_child(hp_label, true)
			hp_label.set_owner(self)
			hp_label.position.y += 10.0
			hp_label.position.x -= 18.0
		hp_label.text = "%d HP" % health

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
