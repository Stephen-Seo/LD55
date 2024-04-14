extends Node2D

@onready var main_label = $Camera2D/MainLabel
@onready var lower_label = $Camera2D/LowerLabel

@onready var fire_diamond = $FireDiamond
@onready var water_diamond = $WaterDiamond
@onready var wind_diamond = $WindDiamond
@onready var earth_diamond = $EarthDiamond

@onready var music_player = $MusicPlayer
@onready var sfx_player = $SFXPlayer
var sfx_select
var sfx_confirm
var sfx_cancel

@onready var camera = $Camera2D

const camera_move_speed = 1.5

const text_speed = 0.08

const start_text = "You seek the elementals?\nProve your worth!\nShow the elements your mastery over summoning, and they are yours!"

const intro_text_00 = "The name's Gander Schwartz.\nBut my friends call me the \"Wandering Gander\"."
const intro_text_01 = "I'm what most would call a \"third-rate summoner\",\nbut there's a reason for that.\nI summon \"items\", not \"beasts\"."
const intro_text_02 = "Most summoners summon beasts to fight for them.\nI summon items to fight with, or even tools to solve puzzles in dungeons."
const intro_text_03 = "There is one dungeon I've been itching to conquer.\nThe Elemental Dungeon!"
const intro_text_04 = "If I beat the Elemental Dungeon,\nI'll be able to enhance my summons with elemental properties!"
const intro_text_05 = "No longer would I need to light an oil lantern with flint and steel,\nor keep lugging around leather skins for water!"
const intro_text_06 = "But the dungeon is a challenge.\nA challenge I hope to best with my wits and my item summoning!"

const diamond_angle_rate = 1.2
const diamond_dist_rate = 50.0
const diamond_start_dist = 800.0
const diamond_min_dist = 150.0

enum StateT {
	Start,
	Start_TextRendered,
	Start_Stopping,
	MainMenu,
	Introduction_00,
	Introduction_00_post,
	Introduction_01,
	Introduction_01_post,
	Introduction_02,
	Introduction_02_post,
	Introduction_03,
	Introduction_03_post,
	Introduction_04,
	Introduction_04_post,
	Introduction_05,
	Introduction_05_post,
	Introduction_06,
	Introduction_06_post,
	Dungeon_Entrance_pre,
	Dungeon_Entrance_loading,
	Dungeon_Entrance,
	Dungeon_Entrance_Battle,
}

enum BattleState {
	MainMenu,
	SummonMenu,
	SummonSword,
	SummonHammer,
	EnemyAttack,
}

static var state_dict = {}

var tween_volume
var tween_text
var tween_scene

var diamonds_gone = false

var gander

var level
var level_guard = null

var level_cached_pos = null

var viewport_size

# Called when the node enters the scene tree for the first time.
func _ready():
	if not state_dict.has("state"):
		state_dict["state"] = StateT.Start
		state_dict["timer"] = 0.0
		state_dict["text_idx"] = 0
		state_dict["start_diamonds"] = {
			"dist": diamond_start_dist,
			"angle" : 0.0
		}
		music_player.play()
		viewport_size = get_viewport().size
		get_viewport().size_changed.connect(func():
			viewport_size = get_viewport().size
			state_dict["battle_refresh_gui"] = true
		)
		sfx_select = load("res://audio/LD55_sfx_select.mp3")
		sfx_confirm = load("res://audio/LD55_sfx_confirm.mp3")
		sfx_cancel = load("res://audio/LD55_sfx_cancel.mp3")

func update_text(text, next_state):
	if state_dict["timer"] > text_speed:
		main_label.text += text[state_dict["text_idx"]]
		state_dict["text_idx"] += 1
		state_dict["timer"] = 0.0
		if state_dict["text_idx"] >= text.length():
			state_dict["state"] = next_state
			state_dict["text_idx"] = 0
			state_dict["timer"] = 0.0
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	state_dict["timer"] += delta
	match state_dict["state"]:
		StateT.Start:
			update_text(start_text, StateT.Start_TextRendered)
			update_start_diamonds(delta)
		StateT.Start_TextRendered:
			update_start_diamonds(delta)
			lower_label.text = "(Press \"Confirm\" to continue! Z, Enter, Space, or A on gamepad.)"
		StateT.Start_Stopping:
			update_stop_diamonds(delta)
		StateT.MainMenu:
			update_stop_diamonds(delta)
			state_dict["state"] = StateT.Introduction_00
			state_dict["timer"] = 0.0
			state_dict["text_idx"] = 0
			main_label.text = ""
			lower_label.text = ""
			music_player.volume_db = 0.0
			music_player.stream = load("res://audio/LD55_1.mp3")
			music_player.stream.loop = true
			music_player.play()
			var gander_scene = preload("res://gander_schwartz.tscn")
			gander = gander_scene.instantiate()
			add_child(gander)
			gander.position.x = 800
			gander.position.y = 50
			gander.velocity.x = -gander.SPEED
			gander.auto_control_action = "walking_left"
			tween_scene = get_tree().create_tween()
			tween_scene.tween_method(func(c): RenderingServer.set_default_clear_color(c), Color(0.13, 0.13, 0.13, 1.0), Color(0.3, 0.4, 0.1, 1.0), 4)
		StateT.Introduction_00:
			update_stop_diamonds(delta)
			update_text(intro_text_00, StateT.Introduction_00_post)
		StateT.Introduction_00_post:
			if not diamonds_gone:
				state_dict["start_diamonds"]["dist"] = diamond_start_dist
				diamonds_gone = true
				fire_diamond.get_parent().remove_child(fire_diamond)
				water_diamond.get_parent().remove_child(water_diamond)
				wind_diamond.get_parent().remove_child(wind_diamond)
				earth_diamond.get_parent().remove_child(earth_diamond)
		StateT.Introduction_01:
			update_text(intro_text_01, StateT.Introduction_01_post)
		StateT.Introduction_01_post:
			pass
		StateT.Introduction_02:
			update_text(intro_text_02, StateT.Introduction_02_post)
		StateT.Introduction_02_post:
			pass
		StateT.Introduction_03:
			update_text(intro_text_03, StateT.Introduction_03_post)
		StateT.Introduction_03_post:
			pass
		StateT.Introduction_04:
			update_text(intro_text_04, StateT.Introduction_04_post)
		StateT.Introduction_04_post:
			pass
		StateT.Introduction_05:
			update_text(intro_text_05, StateT.Introduction_05_post)
		StateT.Introduction_05_post:
			pass
		StateT.Introduction_06:
			update_text(intro_text_06, StateT.Introduction_06_post)
		StateT.Introduction_06_post:
			pass
		StateT.Dungeon_Entrance_loading:
			gander.player_controlled = true
			gander.current_scene_type = gander.GanderSceneT.Gameplay
			var dungeon_scene = load("res://DungeonEntrance.tscn")
			level = dungeon_scene.instantiate()
			add_child(level)
			state_dict["state"] = StateT.Dungeon_Entrance
			lower_label.text = "Arrow keys/WASD/Left-Stick to move."
			tween_text = get_tree().create_tween()
			tween_text.tween_property(lower_label, "self_modulate", Color(1, 1, 1, 0), 5)
			tween_text.tween_callback(func():
				lower_label.text = ""
				lower_label.self_modulate = Color(1, 1, 1, 1)
			)
			music_player.volume_db = 0.0
			music_player.stream = load("res://audio/LD55_2.mp3")
			music_player.stream.loop = true
			music_player.play()
		StateT.Dungeon_Entrance:
			camera_to_gander(delta)
			if level_guard == null:
				level_guard = level.find_child("DungeonGuardStaticBody")
			if level_guard != null and gander.last_collided_id == level_guard.get_instance_id():
				print("collided with guard.")
				gander.last_collided_id = null
				music_player.stop()
				music_player.stream = preload("res://audio/LD55_3.mp3")
				music_player.stream.loop = true
				music_player.play()
				level.find_child("DungeonGuardCollider").set_deferred("disabled", true)
				gander.find_child("CollisionShape2D").set_deferred("disabled", true)
				gander.player_controlled = false
				gander.current_scene_type = gander.GanderSceneT.Battle
				tween_scene = get_tree().create_tween()
				level_cached_pos = level.find_child("DungeonEntrance").position
				var battle_pos = level_cached_pos + Vector2(0.0, 500.0)
				tween_scene.set_parallel()
				tween_scene.tween_property(level.find_child("DungeonGuard"), "position", battle_pos - Vector2(200.0, 30.0), 2.0)
				tween_scene.tween_property(gander, "position", battle_pos + Vector2(200.0, 0.0), 2.0)
				gander.auto_control_action = "walking_right"
				tween_scene.set_parallel(false)
				tween_scene.tween_callback(func():
					gander.auto_control_action = "facing_left"
					state_dict["state"] = StateT.Dungeon_Entrance_Battle
					state_dict["battle_state"] = BattleState.MainMenu
					state_dict["battle_menu_setup"] = false
					state_dict["battle_refresh_gui"] = false
					state_dict["battle_item"] = null
					var indicator_arrow = Sprite2D.new()
					indicator_arrow.texture = load("res://gimp/arrow.png")
					indicator_arrow.position.x = (indicator_arrow.get_rect().size.x - viewport_size.x) / 2.0
					indicator_arrow.position.y = (viewport_size.y - indicator_arrow.get_rect().size.y) / 2.0
					camera.add_child(indicator_arrow)
					indicator_arrow.set_owner(camera)
					tween_text = get_tree().create_tween()
					tween_text.set_parallel()
					tween_text.tween_property(indicator_arrow, "scale", Vector2(20.0, 20.0), 1.5)
					tween_text.tween_property(indicator_arrow, "self_modulate", Color(1, 1, 1, 0), 1.5)
					tween_text.set_parallel(false)
					tween_text.tween_callback(func():
						camera.remove_child(indicator_arrow)
					)
				)
		StateT.Dungeon_Entrance_Battle:
			camera_to_target(delta, level_cached_pos + Vector2(0.0, 500.0))
			setup_battle_menu()
		_:
			pass
	if gander is MainCharacter and not gander.player_controlled and gander.current_scene_type == gander.GanderSceneT.Introduction:
		if gander.velocity.x < 0.0:
			if gander.position.x <= 0.0:
				gander.velocity.x = 0.0
				gander.auto_control_action = "facing_front"
		

func _unhandled_input(event):
	if state_dict["state"] == StateT.Dungeon_Entrance_Battle:
		handle_battle_input(event)
	elif event.is_pressed() and event.is_action("Confirm"):
		match state_dict["state"]:
			StateT.Start:
				main_label.text = start_text
				state_dict["state"] = StateT.Start_TextRendered
				state_dict["text_idx"] = 0
				state_dict["timer"] = 0.0
			StateT.Start_TextRendered:
				state_dict["state"] = StateT.Start_Stopping
				tween_volume = get_tree().create_tween()
				tween_volume.tween_property(music_player, "volume_db", -80.0, 4.0)
				tween_volume.tween_callback(func():
					music_player.stop()
					state_dict["state"] = StateT.MainMenu
				)
				main_label.text = ""
				lower_label.text = ""
			StateT.Introduction_00:
				main_label.text = intro_text_00
				state_dict["text_idx"] = 0
				state_dict["timer"] = 0.0
				state_dict["state"] = StateT.Introduction_00_post
			StateT.Introduction_00_post:
				state_dict["state"] = StateT.Introduction_01
				state_dict["timer"] = 0.0
				state_dict["text_idx"] = 0
				main_label.text = ""
			StateT.Introduction_01:
				state_dict["state"] = StateT.Introduction_01_post
				state_dict["timer"] = 0.0
				state_dict["text_idx"] = 0
				main_label.text = intro_text_01
			StateT.Introduction_01_post:
				state_dict["state"] = StateT.Introduction_02
				state_dict["timer"] = 0.0
				state_dict["text_idx"] = 0
				main_label.text = ""
			StateT.Introduction_02:
				state_dict["state"] = StateT.Introduction_02_post
				state_dict["timer"] = 0.0
				state_dict["text_idx"] = 0
				main_label.text = intro_text_02
			StateT.Introduction_02_post:
				state_dict["state"] = StateT.Introduction_03
				state_dict["timer"] = 0.0
				state_dict["text_idx"] = 0
				main_label.text = ""
			StateT.Introduction_03:
				state_dict["state"] = StateT.Introduction_03_post
				state_dict["timer"] = 0.0
				state_dict["text_idx"] = 0
				main_label.text = intro_text_03
			StateT.Introduction_03_post:
				state_dict["state"] = StateT.Introduction_04
				state_dict["timer"] = 0.0
				state_dict["text_idx"] = 0
				main_label.text = ""
			StateT.Introduction_04:
				state_dict["state"] = StateT.Introduction_04_post
				state_dict["timer"] = 0.0
				state_dict["text_idx"] = 0
				main_label.text = intro_text_04
			StateT.Introduction_04_post:
				state_dict["state"] = StateT.Introduction_05
				state_dict["timer"] = 0.0
				state_dict["text_idx"] = 0
				main_label.text = ""
			StateT.Introduction_05:
				state_dict["state"] = StateT.Introduction_05_post
				state_dict["timer"] = 0.0
				state_dict["text_idx"] = 0
				main_label.text = intro_text_05
			StateT.Introduction_05_post:
				state_dict["state"] = StateT.Introduction_06
				state_dict["timer"] = 0.0
				state_dict["text_idx"] = 0
				main_label.text = ""
			StateT.Introduction_06:
				state_dict["state"] = StateT.Introduction_06_post
				state_dict["timer"] = 0.0
				state_dict["text_idx"] = 0
				main_label.text = intro_text_06
			StateT.Introduction_06_post:
				state_dict["state"] = StateT.Dungeon_Entrance_pre
				state_dict["timer"] = 0.0
				state_dict["text_idx"] = 0
				main_label.text = ""
				tween_volume = get_tree().create_tween()
				tween_volume.tween_property(music_player, "volume_db", -80.0, 4.0)
				tween_volume.tween_callback(func():
					music_player.stop()
					state_dict["state"] = StateT.Dungeon_Entrance_loading
					music_player.volume_db = 0.0
				)
			_:
				pass
	
func diamond_position_update():
	fire_diamond.position.x = cos(state_dict["start_diamonds"]["angle"]) * state_dict["start_diamonds"]["dist"]
	fire_diamond.position.y = sin(state_dict["start_diamonds"]["angle"]) * state_dict["start_diamonds"]["dist"]
	water_diamond.position.x = cos(state_dict["start_diamonds"]["angle"] - PI / 2.0) * state_dict["start_diamonds"]["dist"]
	water_diamond.position.y = sin(state_dict["start_diamonds"]["angle"] - PI / 2.0) * state_dict["start_diamonds"]["dist"]
	wind_diamond.position.x = cos(state_dict["start_diamonds"]["angle"] - PI) * state_dict["start_diamonds"]["dist"]
	wind_diamond.position.y = sin(state_dict["start_diamonds"]["angle"] - PI) * state_dict["start_diamonds"]["dist"]
	earth_diamond.position.x = cos(state_dict["start_diamonds"]["angle"] - PI * 3.0 / 2.0) * state_dict["start_diamonds"]["dist"]
	earth_diamond.position.y = sin(state_dict["start_diamonds"]["angle"] - PI * 3.0 / 2.0) * state_dict["start_diamonds"]["dist"]

func update_start_diamonds(delta):
	state_dict["start_diamonds"]["dist"] -= delta * diamond_dist_rate
	if state_dict["start_diamonds"]["dist"] < diamond_min_dist:
		state_dict["start_diamonds"]["dist"] = diamond_min_dist
	state_dict["start_diamonds"]["angle"] += delta * diamond_angle_rate
	
	if state_dict["start_diamonds"]["angle"] > TAU:
		state_dict["start_diamonds"]["angle"] -= TAU
	
	diamond_position_update()

func update_stop_diamonds(delta):
	if diamonds_gone:
		return
	state_dict["start_diamonds"]["dist"] += delta * diamond_dist_rate * 1.8
	if state_dict["start_diamonds"]["dist"] > diamond_start_dist:
		state_dict["start_diamonds"]["dist"] = diamond_start_dist
		diamonds_gone = true
		fire_diamond.get_parent().remove_child(fire_diamond)
		water_diamond.get_parent().remove_child(water_diamond)
		wind_diamond.get_parent().remove_child(wind_diamond)
		earth_diamond.get_parent().remove_child(earth_diamond)
	state_dict["start_diamonds"]["angle"] += delta * diamond_angle_rate
	
	if state_dict["start_diamonds"]["angle"] > TAU:
		state_dict["start_diamonds"]["angle"] -= TAU
	
	diamond_position_update()

func camera_to_gander(delta):
	camera_to_target(delta, gander.position)

func camera_to_target(delta, vec2):
	var diff = vec2 - camera.position
	camera.position += diff * delta * camera_move_speed

func setup_battle_menu():
	match state_dict["battle_state"]:
		BattleState.MainMenu:
			if not state_dict["battle_menu_setup"] or state_dict["battle_refresh_gui"]:
				state_dict["battle_menu_setup"] = true
				state_dict["battle_refresh_gui"] = false
				var battle_arrow = camera.find_child("BattleArrow")
				if battle_arrow == null:
					battle_arrow = Sprite2D.new()
					battle_arrow.set_name(&"BattleArrow")
					battle_arrow.texture = load("res://gimp/arrow.png")
					camera.add_child(battle_arrow, true)
					battle_arrow.set_owner(camera)
				battle_arrow.self_modulate = Color(1, 1, 1, 1)
				var battle_menu_item_0 = camera.find_child("BattleMenuItem0")
				if battle_menu_item_0 == null:
					battle_menu_item_0 = Label.new()
					battle_menu_item_0.set_name(&"BattleMenuItem0")
					camera.add_child(battle_menu_item_0, true)
					battle_menu_item_0.set_owner(camera)
				var battle_menu_item_1 = camera.find_child("BattleMenuItem1")
				if battle_menu_item_1 == null:
					battle_menu_item_1 = Label.new()
					battle_menu_item_1.set_name(&"BattleMenuItem1")
					camera.add_child(battle_menu_item_1, true)
					battle_menu_item_1.set_owner(camera)
				if state_dict["battle_item"] == null:
					battle_menu_item_0.text = "Summon Item"
					battle_menu_item_1.text = ""
					var arrow_rect = battle_arrow.get_rect()
					battle_arrow.position.x = (arrow_rect.size.x - viewport_size.x) / 2.0
					battle_arrow.position.y = (viewport_size.y - arrow_rect.size.y) / 2.0
					battle_menu_item_0.position.x = arrow_rect.size.x - viewport_size.x / 2.0
					battle_menu_item_0.position.y = battle_arrow.position.y
					state_dict["battle_selection"] = 0
					state_dict["battle_options"] = ["summon"]
				else:
					battle_menu_item_0.text = "Attack with Item"
					battle_menu_item_1.text = "Summon new Item"
					var arrow_rect = battle_arrow.get_rect()
					battle_arrow.position.x = (arrow_rect.size.x - viewport_size.x) / 2.0
					battle_arrow.position.y = (viewport_size.y - arrow_rect.size.y * 3.0) / 2.0
					battle_menu_item_0.position.x = arrow_rect.size.x - viewport_size.x / 2.0
					battle_menu_item_0.position.y = battle_arrow.position.y
					battle_menu_item_1.position.x = arrow_rect.size.x - viewport_size.x / 2.0
					battle_menu_item_1.position.y = battle_arrow.position.y + arrow_rect.size.y
					state_dict["battle_selection"] = 0
					state_dict["battle_options"] = ["attack", "summon"]
		BattleState.SummonMenu:
			if not state_dict["battle_menu_setup"] or state_dict["battle_refresh_gui"]:
				state_dict["battle_menu_setup"] = true
				state_dict["battle_refresh_gui"] = false
				var battle_arrow = camera.find_child("BattleArrow")
				var battle_menu_item_0 = camera.find_child("BattleMenuItem0")
				var battle_menu_item_1 = camera.find_child("BattleMenuItem1")
				battle_arrow.self_modulate = Color(1, 1, 1, 1)
				battle_menu_item_0.text = "Summon Sword"
				battle_menu_item_1.text = "Summon Hammer"
				var arrow_rect = battle_arrow.get_rect()
				battle_arrow.position.x = (arrow_rect.size.x - viewport_size.x) / 2.0
				battle_arrow.position.y = (viewport_size.y - arrow_rect.size.y * 3.0) / 2.0
				battle_menu_item_0.position.x = arrow_rect.size.x - viewport_size.x / 2.0
				battle_menu_item_0.position.y = battle_arrow.position.y
				battle_menu_item_1.position.x = arrow_rect.size.x - viewport_size.x / 2.0
				battle_menu_item_1.position.y = battle_arrow.position.y + arrow_rect.size.y
				state_dict["battle_selection"] = 0
				state_dict["battle_options"] = ["summon_sword", "summon_hammer"]
		BattleState.SummonSword:
			var summon_node = find_child("SummonAttempt")
			if summon_node.success_count >= summon_node.MAX_SUCCESS:
				camera.remove_child(summon_node)
				var summon_item = find_child("SummonItem")
				if summon_item == null:
					summon_item = Sprite2D.new()
					summon_item.texture = load("res://gimp/sword.png")
					summon_item.set_name(&"SummonItem")
					gander.add_child(summon_item, true)
					summon_item.set_owner(gander)
				else:
					summon_item.texture = load("res://gimp/sword.png")
				gander.summon_item = summon_item
				state_dict["battle_state"] = BattleState.EnemyAttack
			elif summon_node.error_count >= summon_node.MAX_ERRORS:
				tween_scene = get_tree().create_tween()
				tween_scene.tween_method(func(c): for i in range(8): summon_node.summon_arrows_arr[i].self_modulate = c, Color(1.0, 0.0, 0.0), Color(1.0, 0.0, 0.0, 0.0), 1.0)
				tween_scene.tween_callback(func(): camera.remove_child(summon_node))
				state_dict["battle_state"] = BattleState.EnemyAttack
		BattleState.SummonHammer:
			var summon_node = find_child("SummonAttempt")
			if summon_node.success_count >= summon_node.MAX_SUCCESS:
				camera.remove_child(summon_node)
				var summon_item = find_child("SummonItem")
				if summon_item == null:
					summon_item = Sprite2D.new()
					summon_item.texture = load("res://gimp/hammer.png")
					summon_item.set_name(&"SummonItem")
					gander.add_child(summon_item, true)
					summon_item.set_owner(gander)
				else:
					summon_item.texture = load("res://gimp/hammer.png")
				gander.summon_item = summon_item
				state_dict["battle_state"] = BattleState.EnemyAttack
			elif summon_node.error_count >= summon_node.MAX_ERRORS:
				tween_scene = get_tree().create_tween()
				tween_scene.tween_method(func(c): for i in range(8): summon_node.summon_arrows_arr[i].self_modulate = c, Color(1.0, 0.0, 0.0), Color(1.0, 0.0, 0.0, 0.0), 1.0)
				tween_scene.tween_callback(func(): camera.remove_child(summon_node))
				state_dict["battle_state"] = BattleState.EnemyAttack
		BattleState.EnemyAttack:
			var battle_arrow = camera.find_child("BattleArrow")
			var battle_menu_item_0 = camera.find_child("BattleMenuItem0")
			var battle_menu_item_1 = camera.find_child("BattleMenuItem1")
			battle_arrow.self_modulate = Color(1, 1, 1, 0)
			battle_menu_item_0.text = ""
			battle_menu_item_1.text = ""

func handle_battle_input(event: InputEvent):
	if state_dict["battle_state"] == BattleState.SummonSword or state_dict["battle_state"] == BattleState.SummonHammer:
		return
	if event.is_pressed():
		if event.is_action("Down"):
			state_dict["battle_selection"] += 1
			if state_dict["battle_selection"] >= state_dict["battle_options"].size():
				state_dict["battle_selection"] = 0
			battle_arrow_positioning()
		elif event.is_action("Up"):
			state_dict["battle_selection"] -= 1
			if state_dict["battle_selection"] < 0:
				state_dict["battle_selection"] = state_dict["battle_options"].size() - 1
			battle_arrow_positioning()
		elif event.is_action("Confirm"):
			handle_battle_action(state_dict["battle_options"][state_dict["battle_selection"]])
		elif event.is_action("Cancel"):
			handle_battle_action("cancel")

func handle_battle_action(action):
	match action:
		"attack":
			sfx_player.stream = sfx_confirm
			sfx_player.play()
		"summon":
			state_dict["battle_state"] = BattleState.SummonMenu
			state_dict["battle_menu_setup"] = false
			sfx_player.stream = sfx_confirm
			sfx_player.play()
		"summon_sword":
			#var summon_item = find_child("SummonItem")
			#if summon_item == null:
				#summon_item = Sprite2D.new()
				#summon_item.texture = load("res://gimp/sword.png")
				#summon_item.set_name(&"SummonItem")
				#gander.add_child(summon_item, true)
				#summon_item.set_owner(gander)
			#else:
				#summon_item.texture = load("res://gimp/sword.png")
			#gander.summon_item = summon_item
			#state_dict["battle_state"] = BattleState.EnemyAttack
			#state_dict["battle_menu_setup"] = false
			state_dict["battle_state"] = BattleState.SummonSword
			state_dict["battle_menu_setup"] = false
			var summon_scene = load("res://summoning.tscn")
			var summon_node = summon_scene.instantiate()
			summon_node.set_name(&"SummonAttempt")
			camera.add_child(summon_node, true)
			summon_node.set_owner(camera)
			sfx_player.stream = sfx_confirm
			sfx_player.play()
		"summon_hammer":
			#var summon_item = find_child("SummonItem")
			#if summon_item == null:
				#summon_item = Sprite2D.new()
				#summon_item.texture = load("res://gimp/hammer.png")
				#summon_item.set_name(&"SummonItem")
				#gander.add_child(summon_item, true)
				#summon_item.set_owner(gander)
			#else:
				#summon_item.texture = load("res://gimp/hammer.png")
			#gander.summon_item = summon_item
			#state_dict["battle_state"] = BattleState.EnemyAttack
			#state_dict["battle_menu_setup"] = false
			state_dict["battle_state"] = BattleState.SummonHammer
			state_dict["battle_menu_setup"] = false
			var summon_scene = load("res://summoning.tscn")
			var summon_node = summon_scene.instantiate()
			summon_node.set_name(&"SummonAttempt")
			camera.add_child(summon_node, true)
			summon_node.set_owner(camera)
			sfx_player.stream = sfx_confirm
			sfx_player.play()
		"cancel":
			state_dict["battle_state"] = BattleState.MainMenu
			state_dict["battle_menu_setup"] = false
			sfx_player.stream = sfx_cancel
			sfx_player.play()
		_:
			pass

func battle_arrow_positioning():
	var battle_arrow: Sprite2D = camera.find_child("BattleArrow")
	if battle_arrow != null:
		var arrow_rect = battle_arrow.get_rect()
		battle_arrow.position.y = (viewport_size.y + arrow_rect.size.y) / 2.0 - (arrow_rect.size.y * (state_dict["battle_options"].size() - state_dict["battle_selection"]))
		sfx_player.stream = sfx_select
		sfx_player.play()
