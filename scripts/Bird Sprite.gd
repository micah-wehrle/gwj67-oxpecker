extends Sprite2D

@onready var animation_player = $AnimationPlayer
@onready var blood_emitter = %"Blood Emitter"

# Called when the node enters the scene tree for the first time.
func _ready():
	blood_emitter.self_modulate = Color.PINK if !persist.show_blood else Color.RED;
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func bleed():
	blood_emitter.restart();
	blood_emitter.emitting = true;

func animate(anim_name):
	if anim_name == "resting":
		animation_player.stop();
		frame = 0;
	else:
		animation_player.play(anim_name);

func _animation_finished(anim_name):
	if anim_name == "peck":
		frame = 0;
	pass;
