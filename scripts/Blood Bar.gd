extends Control

var target_blood = 0.0;
var cur_blood = 0.0;
const MAX_BLOOD = 100.0;

var bar_velocity = 0.0;

const STIFFNESS = 0.4;
const DAMPING = 0.9;

@onready var bar = $"Blood Progress" as TextureProgressBar;

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if cur_blood != target_blood:
		adjust_bar(delta);
	pass

func add_blood(val):
	target_blood = clamp(target_blood + val, 0, MAX_BLOOD);

func adjust_bar(delta):
	if abs(cur_blood - target_blood) < 0.5 and abs(bar_velocity) < 0.2:
		bar.value = target_blood;
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
	
	bar.value = cur_blood;

