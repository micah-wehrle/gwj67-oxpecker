extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready():
	visible = true;
	%"Screen Cover".visible = true;
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func hide_header():
	%"Blood Bar".visible = false;
	%"Riding Frame".visible = false;
	%"Game Over Text".visible = true;
