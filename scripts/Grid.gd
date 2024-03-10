extends Node2D

var grid_width = 13;
var grid_height = 6;

var tile_size = 100.0;
var tile_spacing = 10.0;

var canvas_size = 474.0;

var do_checkerboard = true;

@onready var grass_texture = load("res://res/grass.png");

@onready var grid_parent = Node2D.new();
@onready var animals_parent = Node2D.new();


func _ready():
	add_child(grid_parent);
	add_child(animals_parent);
	
	make_grid();
	
	make_animal("cow", Vector2(2, 3), 3);

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
	var animal = Sprite2D.new();
	animals_parent.add_child(animal);
	
	match(type):
		"cow":
			animal.texture = load("res://res/cow.png"); # should pre-load for reuse
	
	var tile_scale = tile_size / canvas_size;
	animal.scale = Vector2(tile_scale, tile_scale);
	
	animal.position = pos * (tile_size + tile_spacing);
	animal.rotation_degrees = -180 + dir * 90;
	

func is_animal(pos):
	for animal in animals_parent.get_children():
		if pos.distance_to(animal.global_position) < 1:
			return animal;
	return null;
