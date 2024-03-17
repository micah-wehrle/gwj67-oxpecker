extends ColorRect

@onready var bird_sprite = %"Bird Sprite"
@onready var move_nodes = %"Move Nodes"

#Scene tiems to manipulate:
@onready var description = %Description
@onready var description_2 = %Description2
@onready var description_3 = %Description3
@onready var drinks = %Drinks
@onready var their = %Their
@onready var red_overlay = %"Red Overlay"
@onready var blood = %Blood
@onready var scientific_name = %"Scientific Name"

@onready var sound_cloud = $"Sound Cloud"

const FADE_IN_RATE = 1;
const FLY_RATE = 620;
const HOP_X_RATE = 1000;
const HOP_Y_SIZE = 40;
const RED_FADE = 1.2;
const RED_OVERLAY_A = 0.7;

const DRINKS_THEIR_DELAY = 500;

var true_pos;
var advance_phase;
@export var phase = "fade in";
var last_peck = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	bird_sprite.sound_cloud = sound_cloud;
	modulate = Color.BLACK;
	
	if !persist.show_blood:
		drinks.text = "GIVES";
		their.text = "THEM";
		blood.text = "LOVE <3";
		
	drinks.self_modulate = persist.blood_color;
	their.self_modulate = persist.blood_color;
	blood.self_modulate = persist.blood_color;
	description_3.self_modulate = persist.blood_color
	
	red_overlay.color = persist.blood_color;
	red_overlay.color.a = 0;
		
		
		
	
	description.modulate.a = 0;
	description_2.modulate.a = 0;
	drinks.modulate.a = 0;
	their.modulate.a = 0;
	blood.modulate.a = 0;
	
	return;
	# TEST SECTION
	modulate = Color.WHITE;
	bird_sprite.global_position = pos(2);
	phase = "hop1";
	true_pos = pos(2);
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if phase == "fade in":
		modulate.r += FADE_IN_RATE * delta;
		modulate.g += FADE_IN_RATE * delta;
		modulate.b += FADE_IN_RATE * delta;
		
		if modulate.r >= 1:
			phase = "wait after fade in";
			advance_phase = Time.get_ticks_msec() + 500;
	elif phase == "wait after fade in":
		if wait_then("fly in"):
			bird_sprite.animate("flying");
		
	elif phase == "fly in":
		bird_sprite.global_position = bird_sprite.global_position.move_toward(pos(2), FLY_RATE * delta);
		
		true_pos = bird_sprite.global_position;
		description.modulate.a = progress(1,2)*1.5;
		
		if bird_sprite.global_position == pos(2):
			phase = "wait1";
			advance_phase = Time.get_ticks_msec() + 2000;
			bird_sprite.animate("resting");
			description.modulate.a = 1;
		
	elif phase == "wait1":
		wait_then("hop1");
		
	elif phase == "hop1":
		if hop(3, delta):
			phase = "wait2";
			advance_phase = Time.get_ticks_msec() + 200;
			description_2.modulate.a = 1;
			
	elif phase == "wait2":
		wait_then("hop2");
		
	elif phase == "hop2":
		if hop(4, delta):
			phase = "wait3";
			advance_phase = Time.get_ticks_msec() + 3000;
	elif phase == "wait3":
		wait_then("peck");
	elif phase == "peck":
		bird_sprite.animate("peck");
		sound_cloud.play_boom();
		description.modulate.a = 0;
		description_2.modulate.a = 0;
		description_3.visible = true;
		scientific_name.modulate.a = 0;
		drinks.modulate.a = 1;
		phase = "red shift 1"
		red_overlay.color.a = RED_OVERLAY_A;
	elif phase == "red shift 1":
		red_overlay.color.a -= RED_FADE * delta;
		if red_overlay.color.a <= 0:
			phase = "wait4"
			advance_phase = Time.get_ticks_msec() + DRINKS_THEIR_DELAY;
		
	elif phase == "wait4":
		if wait_then("red shift 2"):
			sound_cloud.play_boom();
			bird_sprite.animate("peck");
			their.modulate.a = 1;
			red_overlay.color.a = RED_OVERLAY_A;
	elif phase == "red shift 2":
		red_overlay.color.a -= RED_FADE * delta;
		if red_overlay.color.a <= 0:
			phase = "wait5"
			advance_phase = Time.get_ticks_msec() + DRINKS_THEIR_DELAY;
	elif phase == "wait5":
		if wait_then("peck2"):
			sound_cloud.play_boom();
			bird_sprite.animate("peck");
			(bird_sprite.animation_player as AnimationPlayer).connect("animation_finished", _anim_fin);
	elif phase == "peck2":
		if last_peck:
			phase = "blood wash"
			blood.modulate.a = 1;
			red_overlay.color.a = 1;
			
			drinks.z_index = 15;
			their.z_index = 15;
			blood.z_index = 15;
			bird_sprite.z_index = 15;
	elif phase == "blood wash":
		red_overlay.color.r -= RED_FADE * delta;
		red_overlay.color.g -= RED_FADE * delta;
		red_overlay.color.b -= RED_FADE * delta;
		if red_overlay.color.r <= 0:
			phase = "wait6";
			advance_phase = Time.get_ticks_msec() + 3000; # start blood fade out
	elif phase == "wait6":
		wait_then("blood fade");
	elif phase == "blood fade":
		blood.modulate.a -= RED_FADE * delta;
		drinks.modulate.a = blood.modulate.a;
		their.modulate.a = blood.modulate.a;
		bird_sprite.modulate.a = blood.modulate.a;
		if blood.modulate.a <= 0:
			phase = "wait7";
			advance_phase = Time.get_ticks_msec() + 1500; # jump to game
	elif phase == "wait7":
		if wait_then("end"):
			get_tree().change_scene_to_file("res://scenes/world.tscn");
			pass;
	elif phase == "":
		pass;
	elif phase == "":
		pass;
	elif phase == "":
		pass;
	elif phase == "":
		pass;
	
	pass

func pos(num):
	for child in move_nodes.get_children():
		if child.name == str(num):
			return child.global_position;

func progress(p1, p2):
	return 1.0 - true_pos.distance_to(pos(p2)) / pos(p1).distance_to(pos(p2));

func hop(target, delta):
	true_pos = true_pos.move_toward(pos(target), HOP_X_RATE * delta);
	bird_sprite.global_position = true_pos + Vector2(0, -sin(progress(target-1, target) * PI) * HOP_Y_SIZE);
	
	if true_pos == pos(target):
		bird_sprite.global_position = pos(target);
		return true;
	return false;

func wait_then(next):
	if Time.get_ticks_msec() >= advance_phase:
		phase = next;
		return true;
	return false;

func _anim_fin(anim_name):
	last_peck = true;
