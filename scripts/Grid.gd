extends Node2D

var grid_width = 13;
var grid_height = 6;

var tile_size = 100.0;
var tile_spacing = 10.0;

var canvas_size = 474.0;

var do_checkerboard = true;

@onready var grass_texture = load("res://res/grass.png");

@onready var grid_parent = %"Grid Parent";
@onready var animals_parent = %"Animals Parent";

@onready var animal_scene = preload("res://scenes/animal.tscn");


func _ready():
	make_grid();
	
	make_animal("cow", Vector2(2, 3), 1);
	make_animal("deer", Vector2(6, 1), 3);

func _process(delta):
	pass

func make_tile():
	var tile = Sprite2D.new();
	
	tile.texture = grass_texture;
	
	var tile_scale = tile_size / canvas_size;
	tile.scale = Vector2(tile_scale, tile_scale);
	
	tile.z_index = -10;
	
	return tile;

func make_grid():
	delete_grid();
	
	for y in grid_height:
		for x in grid_width:
			var tile = make_tile();
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
	
	animal.init(type, tile_size, tile_spacing, pos * (tile_size + tile_spacing), dir);
	

func is_animal(pos):
	for animal in animals_parent.get_children():
		if pos.distance_to(animal.global_position) < 1:
			return animal;
	return null;

func is_pos_dangerous(pos):
	pass;

func calc_grid_pos(pos):
	return round( (pos - global_position) / (tile_size + tile_spacing) );
