extends Control

@onready var warning_group = %"Warning Group";
@onready var text_1 = %"Text 1";
@onready var text_2 = %"Text 2";
@onready var buttons = %Buttons;

var waits = [1000, 250, 1000, 1000];
@onready var texts = [warning_group, text_1, text_2, buttons];

const FADE_RATE = 1;

var waiting = true;
var target_time;

var fade_out = false;

var fade_out_a = 1.0;


# Called when the node enters the scene tree for the first time.
func _ready():
	for text in texts:
		(text as Control).modulate.a = 0;
	next_wait();

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if fade_out:
		
		fade_out_a -= FADE_RATE * delta * 1.5;
		modulate.a = fade_out_a;
		
		if fade_out_a <= -1:
			get_tree().change_scene_to_file("res://scenes/intro.tscn");
		
		
		
		return;
		
	if Input.is_action_just_pressed("Click") and target_time < INF:
		while texts.size() > 0:
			texts.pop_front().modulate.a = 1.0;
		target_time = INF;
		waiting = true;
	
	if waiting:
		
		if Time.get_ticks_msec() >= target_time:
			waiting = false;
	else:
		if (texts[0] as Control).modulate.a < 1:
			texts[0].modulate.a += FADE_RATE * delta;
		else:
			texts.pop_front();
			if texts.size() != 0:
				next_wait();
			else:
				waiting = true;
				target_time = INF;
			
	pass


func next_wait():
	target_time = Time.get_ticks_msec() + waits.pop_front();
	waiting = true;

func _blood_mode():
	if target_time < INF:
		return;
	persist.show_blood = true;
	next_scene();

func _bloodless_mode():
	if target_time < INF:
		return;
	persist.show_blood = false;
	next_scene();

func next_scene():
	fade_out = true;
