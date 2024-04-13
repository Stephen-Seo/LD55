extends Node2D

@onready var main_label = $Camera2D/MainLabel
@onready var lower_label = $Camera2D/LowerLabel

@onready var fire_diamond = $FireDiamond
@onready var water_diamond = $WaterDiamond
@onready var wind_diamond = $WindDiamond
@onready var earth_diamond = $EarthDiamond

@onready var audio_stream_player = $AudioStreamPlayer

const start_text = "You seek the elementals?\nProve your worth!\nShow the elements your mastery over summoning, and they are yours!"

const diamond_angle_rate = 1.2
const diamond_dist_rate = 50.0
const diamond_start_dist = 800.0
const diamond_min_dist = 150.0

enum StateT {Start, Start_TextRendered, Start_Stopping, MainMenu}

static var state_dict = {}

var tween_volume

var diamonds_gone = false

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
		audio_stream_player.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	state_dict["timer"] += delta
	match state_dict["state"]:
		StateT.Start:
			if state_dict["timer"] > 0.15:
				main_label.text += start_text[state_dict["text_idx"]]
				state_dict["text_idx"] += 1
				state_dict["timer"] = 0.0
				if state_dict["text_idx"] >= start_text.length():
					state_dict["state"] = StateT.Start_TextRendered
					state_dict["text_idx"] = 0
			update_start_diamonds(delta)
		StateT.Start_TextRendered:
			update_start_diamonds(delta)
			lower_label.text = "(Press \"Confirm\" to continue! Z, Enter, Space, or A on gamepad.)"
		StateT.Start_Stopping:
			update_stop_diamonds(delta)
		StateT.MainMenu:
			update_stop_diamonds(delta)
		_:
			pass
			
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
				tween_volume.tween_property(audio_stream_player, "volume_db", -80.0, 4.0)
				tween_volume.tween_callback(start_volume_tween_callback)
				main_label.text = ""
				lower_label.text = ""
			_:
				pass

func start_volume_tween_callback():
	audio_stream_player.stop()
	state_dict["state"] = StateT.MainMenu
	
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
	
	if state_dict["start_diamonds"]["angle"] > PI * 2.0:
		state_dict["start_diamonds"]["angle"] -= PI * 2.0
	
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
	
	if state_dict["start_diamonds"]["angle"] > PI * 2.0:
		state_dict["start_diamonds"]["angle"] -= PI * 2.0
	
	diamond_position_update()
