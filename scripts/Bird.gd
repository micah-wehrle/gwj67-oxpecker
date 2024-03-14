extends Node2D

@onready var grid = %Grid;
@onready var blood_bar = %"Blood Bar";
@onready var blood_emitter = %"Blood Emitter" as CPUParticles2D;
@onready var bird_sprite = %"Bird Sprite" as Sprite2D;
@onready var riding_indicator = %"Riding Indicator" as Sprite2D;
@onready var wind_indicator = %"Wind Indicator" as Sprite2D;

var wind_texture = load("res://res/wind1.png");
var indicator_fade_rate = 15;

var can_move = true;

var flying = false;
var flying_dir = 0;
var target_pos;

var current_animal;

const FLY_SPEED = 400.0;

func _ready():
	var start_pos = Vector2(0,3);
	global_position = grid.global_position + start_pos * (grid.tile_size + grid.tile_spacing);
	bird_sprite.scale = (Vector2(grid.tile_size, grid.tile_size) / Vector2(bird_sprite.texture.get_height(), bird_sprite.texture.get_height())) * 0.8;
	grid.connect("animals_are_acting", _animal_acting_state_changed);
	grid.connect('ready', get_ready);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if flying:
		if riding_indicator.self_modulate.a > 0:
			riding_indicator.self_modulate.a -= delta * indicator_fade_rate;
		if wind_indicator.self_modulate.a < 1:
			wind_indicator.self_modulate.a += delta * indicator_fade_rate;
		pass;
	else:
		if riding_indicator.self_modulate.a < 1:
			riding_indicator.self_modulate.a += delta * indicator_fade_rate;
		if wind_indicator.self_modulate.a > 0:
			wind_indicator.self_modulate.a -= delta * indicator_fade_rate;
	
	
	if !can_move:    ####################################################
		return;
	
	if !flying:
		if get_dir_input():
			begin_flight(get_dir_input());
		elif Input.is_action_just_pressed("Spacebar"):
			if current_animal:
				do_peck();
	else:
		# gross. Wondering if the direction should just be a vector
		position.x = move_toward(position.x, target_pos.x, FLY_SPEED * delta);
		position.y = move_toward(position.y, target_pos.y, FLY_SPEED * delta);
		
		if position.distance_to(target_pos) < 0.000001:
			position = target_pos;
			
			current_animal = tile_on_beast();
			if tile_is_dangerous():
				game_over();
			elif current_animal:
				stop_flying();
				reparent(current_animal);
				update_riding_texture();
			else: # keep flying!
				begin_flight(flying_dir);
				
func get_ready():
	current_animal = tile_on_beast();
	update_riding_texture();
	grid.disconnect('ready', get_ready);
	
	wind_indicator.scale = Vector2(grid.tile_size, grid.tile_size) / wind_indicator.texture.get_size();

func begin_flight(dir):
	reparent(grid);
	flying_dir = dir
	flying = true;
	bird_sprite.animate("flying");
	
	if dir == 2:
		bird_sprite.flip_h = false;
	elif dir == 4:
		bird_sprite.flip_h = true;
	
	var tile_space = (grid.tile_size + grid.tile_spacing);
	target_pos = position + get_dir_vector(flying_dir) * tile_space;
	
	current_animal = null;
	update_riding_texture();

func stop_flying():
	bird_sprite.animate("resting");
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
	try_to_bleed();
	bird_sprite.animate("peck");
	current_animal.peck()
	pass;

func tile_on_beast():
	return grid.is_pos_animal(global_position);

func tile_is_dangerous():
	var grid_pos = grid.calc_grid_pos(global_position);
	
	if grid_pos.x < 0 or grid_pos.y < 0 or (grid_pos.x >= grid.grid_width and grid_pos.y != grid.exit_height) or grid_pos.y >= grid.grid_height:
		return true;
	elif grid.is_pos_dangerous(grid_pos):
		return true;
	elif grid_pos.x >= grid.grid_width + 2 and grid_pos.y == grid.exit_height:
		persist.current_level += 1;
		return true;
	return false;
	pass;

func try_to_bleed():
	var blood_drained = current_animal.get_blood();
	if blood_drained:
		bird_sprite.bleed();
		blood_bar.add_blood(blood_drained);
	else:
		pass; #handle no blood left?

func _animal_acting_state_changed(state):
	
	if state:
		can_move = false
	else:
		can_move = true;

func update_riding_texture():
	if current_animal:
		riding_indicator.texture = current_animal.get_texture();
		riding_indicator.scale = Vector2(grid.tile_size, grid.tile_size) / riding_indicator.texture.get_size();

func game_over():
	can_move = false;
	$"../..".fade_out();
	pass;
