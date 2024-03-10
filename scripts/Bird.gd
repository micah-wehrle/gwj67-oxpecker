extends Node2D

@onready var grid = %Grid;

var flying = false;
var flying_dir = 0;
var target_pos;


const FLY_SPEED = 400.0;



func _ready():
	var start_pos = Vector2(0,3);
	global_position = grid.global_position + start_pos * (grid.tile_size + grid.tile_spacing);
	pass 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if !flying:
		if get_dir_input():
			begin_flight(get_dir_input());
		elif Input.is_action_just_pressed("Spacebar"):
			do_peck();
	else:
		# gross. Wondering if the direction should just be a vector
		position.x = move_toward(position.x, target_pos.x, FLY_SPEED * delta);
		position.y = move_toward(position.y, target_pos.y, FLY_SPEED * delta);
		
		if position.distance_to(target_pos) < 0.000001:
			position = target_pos;
			
			var beast = tile_on_beast();
			if beast:
				stop_flying();
				reparent(beast); # do we want to save the beast?
				
			elif tile_is_dangerous():
				# game over
				get_tree().paused = true;
			
			else: # keep flying!
				begin_flight(flying_dir);
	

func begin_flight(dir):
	reparent(grid);
	flying_dir = dir
	flying = true;
	var tile_space = (grid.tile_size + grid.tile_spacing);
	target_pos = position + get_dir_vector(flying_dir) * tile_space;

func stop_flying():
	flying = false;
	flying_dir = 0;

func get_dir_input():
	if Input.is_action_just_pressed("Up"):
		return 1;
	elif Input.is_action_just_pressed("Right"):
		return 2;
	elif Input.is_action_just_pressed("Down"):
		return 3;
	elif Input.is_action_just_pressed("Left"):
		return 4;
	
	return 0;

func get_dir_vector(dir):
	if dir == 1:
		return Vector2(0, -1);
	elif dir == 2:
		return Vector2(1, 0);
	elif dir == 3:
		return Vector2(0, 1);
	elif dir == 4:
		return Vector2(-1, 0);
	return Vector2();
	
func do_peck():
	pass;

func tile_on_beast():
	return grid.is_animal(global_position);
	pass;

func tile_is_dangerous():
	pass;
	
