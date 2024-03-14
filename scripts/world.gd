extends Node2D

@onready var screen_cover = %"Screen Cover"

var cover_val = 100;
var move_rate = 12;
var do_fade_out = false;

func _process(delta):
	if screen_cover.value > 0:
		cover_val -= delta * move_rate;
		move_rate *= 1.04;
		screen_cover.value = cover_val;
	
	if do_fade_out:
		cover_val += delta * move_rate;
		move_rate *= 1.04;
		screen_cover.value = cover_val;
		
		if cover_val >= 100:
			get_tree().change_scene_to_file("res://scenes/world.tscn");

func fade_out():
	do_fade_out = true;
	move_rate = 12;
	cover_val = 0;
