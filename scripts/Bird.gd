extends Node2D

@onready var grid = %Grid;
@onready var blood_bar = %"Blood Bar";
@onready var blood_emitter = %"Blood Emitter" as CPUParticles2D;
@onready var bird_sprite = %"Bird Sprite" as Sprite2D;
@onready var riding_indicator = %"Riding Indicator" as Sprite2D;
@onready var wind_indicator = %"Wind Indicator" as Sprite2D;
@onready var sound_cloud = %"Sound Cloud";

var wind_texture = load("res://res/wind1.png");
var indicator_fade_rate = 15;

var can_move = true;

var flying = false;
var flying_dir = 0;
var target_pos;
var dead = false;
var flip_rate = 500.0;
var end_pos = null;
var cur_level = persist.current_level;

var current_animal;

const FLY_SPEED = 400.0;

func _ready():
	bird_sprite.scale = (Vector2(grid.tile_size, grid.tile_size) / Vector2(bird_sprite.texture.get_height(), bird_sprite.texture.get_height())) * 0.8;
	bird_sprite.sound_cloud = sound_cloud;
	grid.connect("animals_are_acting", _animal_acting_state_changed);
	grid.connect('ready', _get_ready);

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
	
	if dead:
		var deg = bird_sprite.rotation_degrees
		var progress = 1 - (deg / 180.0);
		bird_sprite.rotation_degrees = move_toward(deg, 180, delta * flip_rate);
		bird_sprite.position.y = -sin(PI * progress) * grid.tile_size * 0.5;
		
		if bird_sprite.rotation_degrees == 180:
			dead = false;
			grid.fade_out();
	
	if !can_move:    ####################################################
		return;
	
	if !flying:
		if get_dir_input():
			blood_bar.add_blood(-1);
			begin_flight(get_dir_input());
		elif Input.is_action_just_pressed("Spacebar"):
			if current_animal:
				do_peck();
	else:
		# gross. Wondering if the direction should just be a vector
		position.x = move_toward(position.x, target_pos.x, FLY_SPEED * delta);
		position.y = move_toward(position.y, target_pos.y, FLY_SPEED * delta);
		
		
		if position == target_pos:
			
			current_animal = tile_on_beast();
			if blood_bar.get_blood() == 0:
				game_over();
			elif tile_is_dangerous():
				game_over();
			elif current_animal:
				stop_flying();
				reparent(current_animal);
				current_animal.connect("changed_action_step", _riding_animal_began_action_step);
				update_riding_texture();
			else: # keep flying!
				begin_flight(flying_dir);
				
func _get_ready():
	if !grid.bird_start_pos:
		print("no bird pos");
		persist.current_level = 0;
		get_tree().reload_current_scene();
		return;
	global_position = grid.bird_start_pos;
	
	current_animal = tile_on_beast();
	update_riding_texture();
	grid.disconnect('ready', _get_ready);
	
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
	
	if current_animal:
		current_animal.disconnect("changed_action_step", _riding_animal_began_action_step);
		current_animal = null;
	update_riding_texture();
	
	if blood_bar.get_blood() == 0:
		target_pos = find_global_ending_pos() - grid.global_position;


func find_global_ending_pos():
	var check_pos = global_position;
	var start_pos = check_pos;
	var tile_space = (grid.tile_size + grid.tile_spacing);
	var fly_vec = get_dir_vector(flying_dir) * tile_space;
	var steps = 0;
	while steps <= 20:
		check_pos += fly_vec;
		if grid.is_pos_wall(check_pos, true) or grid.is_pos_dangerous(check_pos) or grid.is_pos_animal(check_pos):
			return start_pos + (check_pos - start_pos) / 2;
		
		steps += 1;
	
	return start_pos + fly_vec;

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
	if current_animal.type == "stump":
		sound_cloud.wood_hit();
	else:
		sound_cloud.play_peck();
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
	var danger_animal = grid.is_pos_dangerous(grid_pos)
	if danger_animal:
		danger_animal.do_final_attack();
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

func _animal_acting_state_changed(is_acting):
	if is_acting:
		can_move = false
	else:
		if tile_is_dangerous():
			game_over();
		else:
			can_move = true;

func _riding_animal_began_action_step():
	# just called to check for being in a dangrous square
	if tile_is_dangerous():
		game_over();
	
	var gpos = grid.calc_grid_pos(global_position);
	if gpos.x > grid.grid_width + 3:
		persist.current_level += 1;
		game_over();

func update_riding_texture():
	if current_animal:
		riding_indicator.texture = current_animal.get_texture();
		riding_indicator.scale = Vector2(grid.tile_size, grid.tile_size) / riding_indicator.texture.get_size();

func game_over():
	
	if cur_level == persist.current_level:
		sound_cloud.play_dead();
	
	sound_cloud.stop_flap();
	can_move = false;
	grid.stop_processes();
	bird_sprite.animation_player.stop();
	die();

func die():
	bird_sprite.frame = 7;
	dead = true;
