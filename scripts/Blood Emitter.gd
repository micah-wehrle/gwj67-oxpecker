extends CPUParticles2D

func _ready():
	self_modulate = persist.blood_color;

func spray():
	restart();
	emitting = true;
