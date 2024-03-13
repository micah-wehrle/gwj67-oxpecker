extends Node2D

var grid_width = 13;
var grid_height = 6;

var tile_size = 100.0;
var tile_spacing = 0.0;

var chance_for_special_grass_tile = 0.2;

var do_checkerboard = true;

@onready var grass_texture = load("res://res/grass1.png");
@onready var fancy_grass_texture = load("res://res/random_plants2.png");

@onready var grid_parent = %"Grid Parent";
@onready var animals_parent = %"Animals Parent";

@onready var animal_scene = preload("res://scenes/animal.tscn");

signal animals_are_acting;
var acting_animal_list:Array[bool] = [];
var animal_id_counter = 0;
var are_any_animals_acting = false;


func _ready():
	make_grid();
	
	make_animal("stump", Vector2(0,3), 1);
	make_animal("cow", Vector2(2, 3), 1);
	make_animal("deer", Vector2(6, 1), 3);

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
	
	for y in grid_height:
		for x in grid_width:
			var tile = make_grass();
			add_child(tile);
			if (x + (y % 2)) % 2 == 0:
				tile.self_modulate = Color(0.84, 1, 0.84);
			
			tile.position = Vector2((tile_size + tile_spacing) * x, (tile_size + tile_spacing) * y);

func delete_grid():
	for node in grid_parent.get_children():
		grid_parent.remove_child(node);
		node.queue_free();

func make_animal(type, pos, dir):
	
	var animal = animal_scene.instantiate();
	
	animals_parent.add_child(animal);
	animal.grid = self;
	animal.init(animal_id_counter, type, tile_size, tile_spacing, pos * (tile_size + tile_spacing), dir, self);
	acting_animal_list.push_back(false);
	animal_id_counter += 1;
	
	animal.connect("reaction_state_changed", _animal_acting_state_changed);

func is_animal(pos):
	for animal in animals_parent.get_children():
		if pos.distance_to(animal.global_position) < tile_size:
			return animal;
	return null;

func is_pos_dangerous(pos):
	pass;

func calc_grid_pos(pos):
	return round( (pos - global_position) / (tile_size + tile_spacing) );

func found_acting_animals():
	for animal in acting_animal_list:
		if animal:
			return true;
	return false;

func _animal_acting_state_changed(acting_id, is_acting):
	acting_animal_list[acting_id] = is_acting;
	
	var any_acting_animals = found_acting_animals();
	
	if any_acting_animals != are_any_animals_acting:
		are_any_animals_acting = any_acting_animals;
		animals_are_acting.emit(are_any_animals_acting);
