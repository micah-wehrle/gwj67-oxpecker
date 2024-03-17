extends CPUParticles2D

var emission_started = false;

func _ready():
	emitting = true;
	emission_started = true;

func _process(delta):
	if emission_started and emitting == false:
		queue_free();
