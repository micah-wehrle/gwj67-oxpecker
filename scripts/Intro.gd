extends ColorRect

@onready var bird_sprite = %"Bird Sprite"
@onready var move_nodes = %"Move Nodes"

#Scene tiems to manipulate:
@onready var description = %Description
@onready var description_2 = %Description2
@onready var drinks = %Drinks
@onready var their = %Their
@onready var red_overlay = %"Red Overlay"

const FADE_IN_RATE = 1;
const FLY_RATE = 600;
const HOP_X_RATE = 1000;
const HOP_Y_SIZE = 40;

var true_pos;
var advance_phase;
@export var phase = "fade in";

# Called when the node enters the scene tree for the first time.
func _ready():
	modulate = Color.BLACK;
	
	description.modulate.a = 0;
	description_2.modulate.a = 0;
	drinks.modulate.a = 0;
	their.modulate.a = 0;
	
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
		description.modulate.a = progress(1,2);
		
		if bird_sprite.global_position == pos(2):
			phase = "wait1";
			advance_phase = Time.get_ticks_msec() + 1000;
			bird_sprite.animate("resting");
			description.modulate.a = 1;
		
	elif phase == "wait1":
		wait_then("hop1");
		
	elif phase == "hop1":
		if hop(3, delta):
			phase = "wait2";
			advance_phase = Time.get_ticks_msec() + 200;
			
	elif phase == "wait2":
		wait_then("hop2");
		
	elif phase == "hop2":
		if hop(4, delta):
			phase = "wait3";
			advance_phase = Time.get_ticks_msec() + 1000;
		
	elif phase == "wait3":
		wait_then("peck");
	elif phase == "peck":
		bird_sprite.animate("peck");
		phase = "end";
		pass;
	elif phase == "":
		pass;
	elif phase == "":
		pass;
	elif phase == "":
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
