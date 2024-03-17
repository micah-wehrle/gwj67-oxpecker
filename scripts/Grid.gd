extends Node2D

var grid_width = 14;
var grid_height = 6;
var exit_height = 2;

var tile_size = 100.0;
var tile_spacing = 0.0;

var chance_for_special_grass_tile = 0.2;

var do_checkerboard = true;

@onready var grass_texture = load("res://res/grass1.png");
@onready var fancy_grass_texture = load("res://res/random_plants2.png");
@onready var bush_sheet = load("res://res/bushes1.png");

@onready var grid_parent = %"Grid Parent";
@onready var animals_parent = %"Animals Parent";
@onready var extra_sprite_parent = %"Extra Sprite Parent"
@onready var camera = %Camera2D
@onready var bird = $Bird
@onready var blood_bar = %"Blood Bar"

@onready var animal_scene = preload("res://scenes/animal.tscn");

signal animals_are_acting;
var acting_animal_list:Array[bool] = [];
var animal_id_counter = 0;
var are_any_animals_acting = false;

var bird_start_pos;
var blood_start = 10;



func _ready():
	
	# animals first to adjust exit height?
	make_animals();
	make_grid();
	

func _process(delta):
	pass

func make_grass():
	var tile = Sprite2D.new();
	
	tile.texture = grass_texture;
	tile.hframes = 2;
	tile.vframes = 2;
	tile.frame = randi_range(0, 3);
	tile.rotation_degrees = randi_range(0,3) * 90;
	tile.flip_h = randf() < 0.5;
	tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST;
	var canvas_size = tile.texture.get_size().x / 2;
	var tile_scale = tile_size / canvas_size;
	tile.scale = Vector2(tile_scale, tile_scale);
	tile.z_index = 0;
	
	if randf() <= chance_for_special_grass_tile:
		var tile2 = Sprite2D.new();
		tile.add_child(tile2);
		tile2.texture = fancy_grass_texture;
		tile2.hframes = 2;
		tile2.vframes = 2;
		tile2.frame = randi_range(0, 2); #exclude mud idk don't like it
		tile2.rotation_degrees = -tile.rotation_degrees;
		tile2.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST;
		#tile2.scale = Vector2(tile_scale, tile_scale);
		tile2.z_index = 1;
	return tile;

func make_grid():
	delete_grid();
	
	var cushion_outside_level = 8;
	
	for i in grid_height + cushion_outside_level:
		for j in grid_width + cushion_outside_level:
			var y = i - cushion_outside_level/2;
			var x = j - cushion_outside_level/2;
			
			var tile = make_grass();
			add_child(tile);
			if (x + (y % 2)) % 2 == 0:
				tile.self_modulate = Color(0.84, 1, 0.84);
			
			#tile.self_modulate *= Color(0.95, 0.95, 0.95, 1);
			
			tile.position = Vector2((tile_size + tile_spacing) * x, (tile_size + tile_spacing) * y);
			
			if tile.get_children().size() > 0:
				for xtra in extra_sprite_parent.get_children():
					if xtra.global_position.distance_to(tile.global_position) < tile_size:
						tile.get_child(0).queue_free();
						break;
	
	for i in grid_height + 2:
		for j in grid_width + 2:
			
			var y = i - 1;
			var x = j - 1;
			
			var x_extreme = x == -1 or x == grid_width;
			var y_extreme = y == -1 or y == grid_height;
			
			if (x_extreme or y_extreme) and !(x == grid_width and y == exit_height):
				var sprite = Sprite2D.new();
				sprite.texture = bush_sheet;
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST;
				add_child(sprite);
				sprite.z_index = 2;
				
				sprite.vframes = 3;
				sprite.hframes = 3;
				
				if x_extreme and y_extreme: 
					sprite.frame = 0;
					
					if y == grid_height:
						if x == -1:
							sprite.rotation_degrees = -90;
						else:
							sprite.rotation_degrees = 180;
					elif x == grid_width:
						sprite.rotation_degrees = 90;
					
					
				elif x == grid_width and y >= exit_height -1 and y <= exit_height + 1:
					sprite.frame = 3;
					if y == exit_height + 1:
						sprite.rotation_degrees = 180;
				else:
					sprite.frame = randi_range(1,2) if randf() < 0.5 else randi_range(4, 5);
					
					if x_extreme:
						sprite.rotation_degrees = (randi_range(0,1) - 0.5) * 180;
					else:
						sprite.rotation_degrees = randi_range(0,1) * 180;
					sprite.flip_h = randf() < 0.5;
					
				sprite.scale = Vector2(tile_size, tile_size) / Vector2(16, 16);
				
				sprite.position = Vector2((tile_size + tile_spacing) * x, (tile_size + tile_spacing) * y);
			

func delete_grid():
	for node in grid_parent.get_children():
		grid_parent.remove_child(node);
		node.queue_free();

func make_animal(type, pos, dir):
	
	var animal = animal_scene.instantiate();
	
	animals_parent.add_child(animal);
	animal.grid = self;
	animal.camera = camera;
	animal.init(animal_id_counter, type, tile_size, tile_spacing, pos * (tile_size + tile_spacing), dir, self);
	acting_animal_list.push_back(false);
	animal_id_counter += 1;
	
	animal.connect("reaction_state_changed", _animal_acting_state_changed);

func is_pos_animal(pos):
	for animal in animals_parent.get_children():
		if pos.distance_to(animal.global_position) < tile_size/2:
			return animal;
	return null;

func is_pos_wall(pos, ignore_exit_height = false):
	var gpos = calc_grid_pos(pos);
	if ignore_exit_height:
		if gpos.x < 0 or gpos.y < 0 or gpos.x >= grid_width or gpos.y >= grid_height:
			return true;
	else:
		if gpos.x < 0 or gpos.y < 0 or (gpos.x >= grid_width and gpos.y != exit_height) or gpos.y >= grid_height:
			return true;
	return false;

func is_pos_dangerous(pos):
	for animal in animals_parent.get_children():
		if animal.dangerous and pos == animal.get_attack_grid_pos():
			return animal;
	return null;

func calc_grid_pos(pos):
	return round( (pos - global_position) / (tile_size + tile_spacing) );

func found_acting_animals():
	for animal in acting_animal_list:
		if animal:
			return true;
	return false;

func give_queue_to_all_animals(action_queue, giver):
	for animal in animals_parent.get_children():
		if animal == giver:
			continue;
		if action_queue:
			animal.independant_react(action_queue);
		else:
			animal.build_own_queue();
			animal.change_reaction_state(true);

func _animal_acting_state_changed(acting_id, is_acting):
	acting_animal_list[acting_id] = is_acting;
	
	var any_acting_animals = found_acting_animals();
	
	if any_acting_animals != are_any_animals_acting:
		are_any_animals_acting = any_acting_animals;
		animals_are_acting.emit(are_any_animals_acting);

func add_sprite(name, pos, rot = 0):
	var sprite = Sprite2D.new();
	extra_sprite_parent.add_child(sprite);
	if name.substr(0, 5) == "arrow":
		sprite.texture = load("res://res/tut_stuff1.png");
		sprite.hframes = 3;
		sprite.vframes = 3;
		sprite.scale = Vector2(tile_size, tile_size) / Vector2(16, 16);
		
		sprite.frame = int(name.substr(5, 1)) - 1;
		
		sprite.self_modulate = Color(0, 0, 0, 0.3);
	#match name:
	
	sprite.z_index = 4;
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST;
	sprite.position = pos * (tile_size + tile_spacing);
	sprite.rotation_degrees = rot;
	pass;

func stop_processes():
	for animal in animals_parent.get_children():
		animal.stop_everything();
	
func fade_out():
	$"..".fade_out();

func setup_end_screen():
	for animal in animals_parent.get_children():
		animal.arrow_sprite.visible = false;
		animal.danger_sprite.visible = false;
		animal.independant_react([
			{
				"action": "hop",
				"loop": true,
				"delay": true,
			}
		], true);
		
	bird.can_move = false;
	
	%CanvasLayer.hide_header();
	
	await get_tree().create_timer(2.0).timeout;
	
	%"Left Confetti".emitting = true;
	%"Right Confetti".emitting = true;

func bird_start(x, y, make_stump = true):
	if make_stump:
		make_animal("stump", Vector2(x, y), 1);
	bird_start_pos = global_position + Vector2(x, y) * (tile_size + tile_spacing);

func setup_blood():
	blood_bar.init_bar(blood_start * 1.0);

func make_animals():
	
	match persist.current_level:
		0:
			bird_start(1, 3);
			blood_start = 7+1; # 5 steps 0 pecks
			# short arrow
			#add_sprite("arrow1", Vector2(3, 3));
			#add_sprite("arrow2", Vector2(4, 3));
			#add_sprite("arrow3", Vector2(5, 3));
			
			# long arrow
			add_sprite("arrow1", Vector2(2, 3));
			add_sprite("arrow2", Vector2(3, 3));
			add_sprite("arrow2", Vector2(4, 3));
			add_sprite("arrow2", Vector2(5, 3));
			add_sprite("arrow3", Vector2(6, 3));
			
			# wasd
			add_sprite("arrow4", Vector2(4, 1));
			add_sprite("arrow5", Vector2(3, 2));
			add_sprite("arrow6", Vector2(4, 2));
			add_sprite("arrow7", Vector2(5, 2));
			
			# up arrow
			#add_sprite("arrow1", Vector2(7, 2), -90);
			#add_sprite("arrow3", Vector2(7, 1), -90);
			
			make_animal("stump", Vector2(7, 3), 1);
			make_animal("stump", Vector2(7, 0), 1);
			make_animal("stump", Vector2(10, 0), 1);
			make_animal("stump", Vector2(10, 2), 1);
			
			add_sprite("arrow1", Vector2(13, 2));
			add_sprite("arrow2", Vector2(14, 2));
			add_sprite("arrow3", Vector2(15, 2));
			
		1:
			bird_start(3, 2);
			blood_start = 8+1; # 6 steps, 0 pecks
			
			make_animal("cow", Vector2(6, 1), 3);
			make_animal("stump", Vector2(3, 4), 1);
			
			# shorter level
			#make_animal("stump", Vector2(9, 4), 1);
			#make_animal("stump", Vector2(9, 2), 1);
			
			# longer level
			make_animal("stump", Vector2(8, 4), 1);
			make_animal("stump", Vector2(8, 0), 1);
			make_animal("stump", Vector2(11, 0), 1);
			make_animal("stump", Vector2(11, 2), 1);
		
		2:
			exit_height = 3;
			blood_start = 3+1; # 4 steps, 4 pecks
			
			bird_start(2, 1);
			
			make_animal("stump", Vector2(2, 3), 1);
			make_animal("cow", Vector2(4, 1), 3);
			add_sprite("arrow8", Vector2(5, 1));
			add_sprite("arrow9", Vector2(6, 1));
			make_animal("cow", Vector2(9, 3), 4);
			make_animal("stump", Vector2(11, 3), 1);
			make_animal("stump", Vector2(11, 5), 1);
		
		3:
			exit_height = 3;
			blood_start = 3+1; # mostly pecking
			
			bird_start(2,2);
			
			make_animal("cow", Vector2(2, 4), 2);
			make_animal("cow", Vector2(4, 2), 1);
			make_animal("cow", Vector2(7, 0), 3);
			make_animal("cow", Vector2(9, 4), 1);
			
		"4 too hard":
			bird_start(1,5);
			
			make_animal("rhino", Vector2(1, 2), 2);
			make_animal("cow", Vector2(6, 2), 2);
			make_animal("cow", Vector2(12, 2), 4);
			make_animal("stump", Vector2(6, 5), 1);
			make_animal("stump", Vector2(2, 4), 1);
			make_animal("rhino", Vector2(2, 1), 1);
			make_animal("stump", Vector2(2, 0), 1);
			make_animal("stump", Vector2(9, 1), 1);
			
			
			"""make_animal("rhino", Vector2(1, 2), 2);
			make_animal("cow", Vector2(6, 2), 2);
			make_animal("cow", Vector2(12, 2), 4);
			make_animal("stump", Vector2(6, 5), 1);
			make_animal("stump", Vector2(2, 4), 1);
			make_animal("rhino", Vector2(2, 1), 2);
			make_animal("stump", Vector2(2, 0), 1);
			make_animal("stump", Vector2(9, 0), 1);
			make_animal("stump", Vector2(13, 0), 1);
			make_animal("stump", Vector2(8, 3), 1);"""
			
		4:
			exit_height = 3;
			blood_start = 8; #just trust me, we wrote it out bro
			
			# maybe shift everything 3 tiles to the right
			bird_start(2,5);
			
			make_animal("rhino", Vector2(2, 3), 2);
			make_animal("cow", Vector2(13, 3), 4);
			make_animal("cow", Vector2(6, 1), 3);
			
			make_animal("stump", Vector2(6, 0), 1);
			make_animal("stump", Vector2(0, 0), 1);
			make_animal("stump", Vector2(0, 3), 1);
			make_animal("stump", Vector2(3, 1), 1);
			
		5:
			exit_height = 3;
			blood_start = 3;
			
			bird_start(9,4);
			
			make_animal("lion", Vector2(3,4), 3);
			#make_animal("stump", Vector2(4,4), 3);
			
			make_animal("cow", Vector2(6,1), 2);
			
			make_animal("stump", Vector2(9,2), 1);
			
			make_animal("stump", Vector2(11,3), 1);
			
			make_animal("rhino", Vector2(9,5), 4);
			
			#make_animal("cow", Vector2(1, 0), 1);
			#make_animal("cow", Vector2(0, 1), 4);
			
		6:
			exit_height = 1;
			blood_start = 5;
			
			bird_start(1,5);
			
			make_animal("cow", Vector2(1,2), 2);
			make_animal("cow", Vector2(4, 1), 4);
			make_animal("cow", Vector2(11, 2), 1);
			
			make_animal("stump", Vector2(10, 5), 1);
			make_animal("stump", Vector2(0, 4), 1);
			
			make_animal("rhino", Vector2(4, 5), 1);
		
		7:
			blood_start = 4;
			exit_height = 3;
			bird_start(2,4);
			
			make_animal("turtle", Vector2(2,1), 2);
			
			make_animal("lion", Vector2(12,3), 3);
			
			make_animal("rhino", Vector2(3, 5), 2);
			make_animal("stump", Vector2(2, 5), 1);
			
			make_animal("rhino", Vector2(13, 4), 1);
			
			make_animal("cow", Vector2(11, 0), 4);
			
			make_animal("cow", Vector2(0,2), 2);
			
			#for i in 7:
			#	make_animal("cow", Vector2(i + 4, 1 + i%2*4), 3 - i%2*2);
		
		8:
			blood_start = 5;
			exit_height = 3;
			
			bird_start(0,1);
			
			make_animal("deer", Vector2(4,2), 2);
			make_animal("deer", Vector2(9,1), 3);
			make_animal("deer", Vector2(6,0), 4);
			make_animal("stump", Vector2(7,0), 1);
			#make_animal("stump", Vector2(9,0), 1);
			
			make_animal("cow", Vector2(13,0), 4);
			
			make_animal("deer", Vector2(1,4), 1);
			make_animal("stump", Vector2(2,3), 1);
			
			make_animal("lion", Vector2(1,0), 2);
			
			
			#make_animal("deer", Vector2(9,5), 1);
			
			make_animal("cow", Vector2(12, 0), 3);
			
			make_animal("cow", Vector2(11, 3), 4);
			make_animal("stump", Vector2(10, 3), 1);
			make_animal("cow", Vector2(11, 5), 4);
			make_animal("stump", Vector2(10, 5), 1);
			
			
		9:
			bird_start(0,0);
			blood_start = 4;
			
			var rng = RandomNumberGenerator.new();
			rng.seed = 123;
			
			for y in grid_height:
				for x in grid_width:
					if (x + (y % 2)) % 2 == 1:
						var dir = rng.randi_range(1,4);
						if x == 13:
							if y == 2:
								dir = 1;
							elif y == 4:
								dir = 3;
						make_animal("cow", Vector2(x, y), dir);
		10:
			
			bird_start(2,3);
			blood_start = 5;
			
			exit_height = 3
			
			make_animal("lion", Vector2(6, 3), 2);
			
			make_animal("stump", Vector2(6, 1), 1);
			
			make_animal("gorilla", Vector2(9, 1), 4);
			
			make_animal("deer", Vector2(10, 1), 2);
			
		11:
			
			bird_start(9,0);
			blood_start = 4;
			
			make_animal("stump", Vector2(7,2), 1);
			make_animal("stump", Vector2(10,2), 1);

			make_animal("gorilla", Vector2(7,5), 1);
			
			make_animal("rhino", Vector2(3, 4), 1);
			
			make_animal("stump", Vector2(2,5), 1);
			make_animal("stump", Vector2(3,1), 1);
			
			make_animal("lion", Vector2(1, 0), 3);
			
			
		12:
			
			
			
			
			
			
		_: # default - game end!
			exit_height = 100
			bird_start(1000,1000, false);
			make_animal("bird", Vector2(6,2), 1);
			
			make_animal("gorilla", Vector2(3,1), 2);
			make_animal("rhino", Vector2(1,2), 2);
			make_animal("stump", Vector2(8,1), 1);
			make_animal("cow", Vector2(4,3), 3);
			make_animal("turtle", Vector2(12,3), 3);
			make_animal("lion", Vector2(7,4), 3);
			make_animal("deer", Vector2(10,2), 3);
			
			setup_end_screen();



	#make_animal("cow", Vector2(2, 3), 1);
	#make_animal("deer", Vector2(6, 1), 3);
	
	
	
			#make_animal("stump", Vector2(6,3), 1);
			#make_animal("stump", Vector2(6,0), 1);
			#make_animal("stump", Vector2(4,0), 1);
			#make_animal("stump", Vector2(4,4), 1);
			#make_animal("stump", Vector2(11,4), 1);
			#make_animal("stump", Vector2(11,2), 1);
			
			#make_animal("gorilla", Vector2(0,2), 2);
			#make_animal("rhino", Vector2(0,2), 2);
			#make_animal("stump", Vector2(2,2), 1);
			#make_animal("cow", Vector2(4,2), 3);
			#make_animal("cow", Vector2(4,1), 3);
			#make_animal("turtle", Vector2(1,3), 3);
			#make_animal("lion", Vector2(1,3), 3);
			
			#make_animal("deer", Vector2(10,2), 3);
	
	setup_blood();
