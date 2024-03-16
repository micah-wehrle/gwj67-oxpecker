extends Camera2D

@onready var default_pos = offset;
@onready var default_rot = rotation_degrees;
@onready var default_zoom = zoom;

var pos_offset = 5;
var rot_offset = 2;
var zoom_offset = 0.01;

var shake = false;


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if shake:
		offset = default_pos + Vector2(randf_range(-pos_offset, pos_offset), randf_range(-pos_offset, pos_offset));
		rotation_degrees = default_rot + randf_range(-rot_offset, rot_offset);
		zoom = default_zoom +  Vector2(1,1) * randf_range(-zoom_offset, zoom_offset);

func do_shake(shake):
	self.shake = shake;
	
	if !shake:
		offset = default_pos;
		rotation_degrees = default_rot;
		zoom = default_zoom;
