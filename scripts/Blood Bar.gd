extends Control

var target_blood = 0.0;
var cur_blood = 0.0;
const MAX_BLOOD = 10.0;

var bar_velocity = 0.0;

var blood_adjustment_mult = 10.0;

const STIFFNESS = 0.4;
const DAMPING = 0.9;

var setup_blood_on_ready = false;

@onready var bar = $"Blood Frame/TextureProgressBar" as TextureProgressBar;

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if cur_blood != target_blood:
		adjust_bar(delta);
	pass


func add_blood(val):
	target_blood = clamp(target_blood + val, 0, MAX_BLOOD);

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

