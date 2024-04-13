extends Node2D

@onready var main_label = $Camera2D/MainLabel
@onready var lower_label = $Camera2D/LowerLabel

@onready var fire_diamond = $FireDiamond
@onready var water_diamond = $WaterDiamond
@onready var wind_diamond = $WindDiamond
@onready var earth_diamond = $EarthDiamond

@onready var music_player = $MusicPlayer

@onready var camera = $Camera2D

const camera_move_speed = 80.0

const text_speed = 0.08

const start_text = "You seek the elementals?\nProve your worth!\nShow the elements your mastery over summoning, and they are yours!"

const intro_text_00 = "The name's Gander Schwartz.\nBut my friends call me the \"Wandering Gander\"."
const intro_text_01 = "I'm what most would call a \"third-rate summoner\",\nbut there's a reason for that.\nI summon \"items\", not \"beasts\"."
const intro_text_02 = "Most summoners summon beasts to fight for them.\nI summon items to fight with, or even tools to solve puzzles in dungeons."
const intro_text_03 = "There is one dungeon I've been itching to conquer.\nThe elemental dungeon!"
const intro_text_04 = "If I beat the elemental dungeon,\nI'll be able to enhance my summons with elemental properties!"
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

static var state_dict = {}

var tween_volume
var tween_text

var diamonds_gone = false

var music_file

var gander

var level
var level_guard = null

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
			music_player.stream = AudioStreamMP3.new()
			music_file = FileAccess.open("res://audio/LD55_1.mp3", FileAccess.READ)
			music_player.stream.data = music_file.get_buffer(music_file.get_length())
			music_player.stream.loop = true
			music_player.play()
			var gander_scene = preload("res://gander_schwartz.tscn")
			gander = gander_scene.instantiate()
			add_child(gander)
			gander.position.x = 800
			gander.position.y = 50
			gander.velocity.x = -gander.SPEED
			gander.auto_control_action = "walking_left"
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
		StateT.Dungeon_Entrance:
			camera_to_gander(delta)
			if level_guard == null:
				level_guard = level.find_child("DungeonGuardStaticBody")
			if level_guard != null and gander.last_collided_id == level_guard.get_instance_id():
				print("collided with guard.")
				gander.last_collided_id = null
		_:
			pass
	if gander is MainCharacter and not gander.player_controlled and gander.current_scene_type == gander.GanderSceneT.Introduction:
		if gander.velocity.x < 0.0:
			if gander.position.x <= 0.0:
				gander.velocity.x = 0.0
				gander.auto_control_action = "facing_front"
		

func _unhandled_input(event):
	if event.is_pressed() and event.is_action("Confirm"):
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
	var diff = gander.position - camera.position
	if diff.length() > 0.04:
		var move_vec = diff.normalized() * camera_move_speed * delta
		if diff.length() < move_vec.length():
			camera.position = gander.position
		else:
			camera.position += move_vec
	else:
		camera.position = gander.position
