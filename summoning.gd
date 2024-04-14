extends Node2D

enum Direction {
	LEFT,
	RIGHT,
	UP,
	DOWN,
}

@onready var ar_one = $SummonArrow
@onready var ar_two = $SummonArrow2
@onready var ar_three = $SummonArrow3
@onready var ar_four = $SummonArrow4
@onready var ar_five = $SummonArrow5
@onready var ar_six = $SummonArrow6
@onready var ar_seven = $SummonArrow7
@onready var ar_eight = $SummonArrow8

@onready var timer_box = $TimerBox
const TIMER_BOX_WIDTH = 380.0

var summon_arrows_arr = []

var arrow_directions = []

const MAX_ERRORS = 3
const MAX_SUCCESS = 8
var error_count = 0
var success_count = 0

const TIMER_AMOUNT = 5.0
var timer = 0.0

func int_to_dir(i):
	match i:
		0:
			return Direction.LEFT
		1:
			return Direction.RIGHT
		2:
			return Direction.UP
		3:
			return Direction.DOWN
		_:
			return Direction.DOWN

func dir_to_angle(d: Direction):
	match d:
		Direction.LEFT:
			return 0.0
		Direction.RIGHT:
			return PI
		Direction.UP:
			return PI / 2.0
		Direction.DOWN:
			return PI * 3.0 / 2.0

func _ready():
	summon_arrows_arr.append(ar_one)
	summon_arrows_arr.append(ar_two)
	summon_arrows_arr.append(ar_three)
	summon_arrows_arr.append(ar_four)
	summon_arrows_arr.append(ar_five)
	summon_arrows_arr.append(ar_six)
	summon_arrows_arr.append(ar_seven)
	summon_arrows_arr.append(ar_eight)
	var rng = RandomNumberGenerator.new()
	for i in range(8):
		arrow_directions.append(int_to_dir(rng.randi_range(0, 3)))
		summon_arrows_arr[i].rotation = dir_to_angle(arrow_directions[i])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	timer += delta
	if timer >= TIMER_AMOUNT:
		timer = 0.0
		if success_count < MAX_SUCCESS and error_count < MAX_ERRORS:
			on_summon_error()
	if success_count < MAX_SUCCESS and error_count < MAX_ERRORS:
		var interp_amount = (TIMER_AMOUNT - timer) / TIMER_AMOUNT
		timer_box.scale.x = interp_amount * TIMER_BOX_WIDTH
		timer_box.self_modulate = Color((1.0 - interp_amount), interp_amount, 0.0)

func _unhandled_input(event):
	if error_count >= MAX_ERRORS or success_count >= MAX_SUCCESS:
		return
	if event.is_pressed():
		if event.is_action("Left"):
			if arrow_directions[success_count] == Direction.LEFT:
				on_summon_success(success_count)
			else:
				on_summon_error()
		elif event.is_action("Right"):
			if arrow_directions[success_count] == Direction.RIGHT:
				on_summon_success(success_count)
			else:
				on_summon_error()
		elif event.is_action("Up"):
			if arrow_directions[success_count] == Direction.UP:
				on_summon_success(success_count)
			else:
				on_summon_error()
		elif event.is_action("Down"):
			if arrow_directions[success_count] == Direction.DOWN:
				on_summon_success(success_count)
			else:
				on_summon_error()
				
func on_summon_success(idx):
	summon_arrows_arr[idx].self_modulate = Color(0.0, 1.0, 0.0)
	success_count += 1

func on_summon_error():
	timer = 0.0
	success_count = 0
	error_count += 1
	if error_count >= MAX_ERRORS:
		for i in range(8):
			summon_arrows_arr[i].self_modulate = Color(1.0, 0.0, 0.0)
	else:
		for i in range(8):
			summon_arrows_arr[i].self_modulate = Color(1.0, 1.0, 1.0)
