extends Node2D

@onready var screen_cover = %"Screen Cover"

var cover_val = 100;
var start_rate = 5;
var accel = 1.09;
var move_rate = start_rate;
var fade_in = true;
var do_fade_out = false;

func _process(delta):
	if fade_in:
		if screen_cover.value > 0:
			cover_val -= delta * move_rate;
			move_rate *= accel;
			screen_cover.value = cover_val;
		else:
			fade_in = false;
			screen_cover.fill_mode = ProgressBar.FILL_TOP_TO_BOTTOM;
	
	if do_fade_out:
		cover_val += delta * move_rate;
		move_rate *= accel;
		screen_cover.value = cover_val;
		
		if cover_val >= 100:
			get_tree().reload_current_scene();

func fade_out():
	do_fade_out = true;
	move_rate = start_rate;
	cover_val = 0;
