extends Sprite2D

@onready var animation_player = $AnimationPlayer
@onready var blood_emitter = %"Blood Emitter"

func _process(delta):
	pass

func bleed():
	blood_emitter.spray();

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
