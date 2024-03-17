extends Control

var target_blood = 0.0;
var cur_blood = 0.0;
const MAX_BLOOD = 10.0;

var bar_velocity = 0.0;

var blood_adjustment_mult = 10.0;

const STIFFNESS = 0.4;
const DAMPING = 0.9;

var setup_blood_on_ready = false;

var shake_length = 100; #ms
var stop_shaking_time;
var base_pos;
var shake_size = 3;

signal blood_changed;

@onready var bar = $"Blood Frame/TextureProgressBar" as TextureProgressBar;
@onready var background_panel = %"Blood Background Panel"
@onready var blood_frame = %"Blood Frame"

@onready var bar_emitter = %"Bar Emitter"

var bar_size;


func init_bar(cur_blood):
	self.cur_blood = cur_blood;
	target_blood = cur_blood;
	if !bar:
		setup_blood_on_ready = true;
	else:
		bar.value = target_blood * blood_adjustment_mult;

func _ready():
	if setup_blood_on_ready:
		bar.value = target_blood * blood_adjustment_mult;
	
	base_pos = blood_frame.position;
	
	bar.self_modulate = Color.RED if persist.show_blood else Color.HOT_PINK;
	
	bar_size = bar.scale.x * bar.texture_progress.get_size().x;

var flash_time = 0;
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if cur_blood != target_blood:
		adjust_bar(delta);
	
	if target_blood <= 2:
		flash_time += 7*delta;
		background_panel.self_modulate = Color(0,0.5,0.5,0) * sin(flash_time) + Color(1.0,0.5,0.5, 1.0);
	
	if stop_shaking_time:
		if Time.get_ticks_msec() <= stop_shaking_time:
			blood_frame.position = base_pos + Vector2(randf_range(-shake_size, shake_size), randf_range(-shake_size, shake_size));
		else:
			stop_shaking_time = null;
			blood_frame.position = base_pos;
		


func add_blood(val):
	if target_blood == 2 and val > 0:
		background_panel.self_modulate = Color.WHITE;
	target_blood = clamp(target_blood + val, 0, MAX_BLOOD);
	
	blood_changed.emit(target_blood);
	
	stop_shaking_time = Time.get_ticks_msec() + shake_length;
	
	set_emitter_pos();
	bar_emitter.spray();

func get_blood():
	return target_blood;

func adjust_bar(delta):
	if abs(cur_blood - target_blood) < 0.5 and abs(bar_velocity) < 0.2:
		bar.value = target_blood * blood_adjustment_mult;
		cur_blood = target_blood;
		bar_velocity = 0;
		return;
	
	# I found this online
	var dist = target_blood - cur_blood;
	var spring_force = dist * STIFFNESS;
	var damping_force = -bar_velocity * DAMPING;
	var force = spring_force + damping_force;
	bar_velocity += force * delta;
	cur_blood += bar_velocity;
	
	bar.value = cur_blood * blood_adjustment_mult;

func set_emitter_pos():
	bar_emitter.global_position.x = bar.global_position.x + bar_size * (target_blood / MAX_BLOOD);
