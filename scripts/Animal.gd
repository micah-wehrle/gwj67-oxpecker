extends Node2D

# To be passed by init or calculated later
var animal_id;
var type;
var sprite_target_size;
var tile_spacing;
var facing_dir;
var grid;
var blood_total;
var blood_per_peck;

var action_queue = [];
var reacting_to_event = false;
var fulfilling_single_action = false;
var current_reaction;
var reaction_start_time;

var true_arrow_pos;
var arrow_time = 0;

var true_danger_scale;

var targ_move_pos;
var start_move_pos;
var true_move_pos;
const MOVE_SPEED = 500;
var targ_scale;

var targ_dir = null;
const ROT_SPEED = 500;

signal reaction_state_changed;

@onready var body_sprite = $"Sprites/Body Sprite" as Sprite2D;
@onready var dir_arrow = $"Sprites/Dir Arrow" as Node2D;
@onready var arrow_sprite = $"Sprites/Dir Arrow/Dir Arrow Sprite" as Sprite2D;
@onready var danger_sprite = $"Sprites/Dir Arrow/Danger Space Sprite" as Sprite2D;

var dangerous = true;
var can_move = true;
var peckable = true;

func init(animal_id, type, sprite_target_size, tile_spacing, pos, facing_dir, the_grid):
	self.animal_id = animal_id;
	self.type = type;
	self.sprite_target_size = sprite_target_size;
	self.tile_spacing = tile_spacing;
	self.facing_dir = facing_dir;
	self.grid = the_grid;
	
	arrow_sprite.position.x = sprite_target_size * 0.5;
	true_arrow_pos = arrow_sprite.position;
	
	position = pos;
	
	var target_size_vec = Vector2(sprite_target_size, sprite_target_size);
	
	blood_total = 20;
	blood_per_peck = 5;
	
	var tex;
	var sprite_scale_mult = 1;
	match(type):
		"cow":
			tex = "res://res/cow1.png"; # should pre-load for reuse?
			sprite_scale_mult = 0.85;
		"deer":
			tex = "res://res/deer.png";
		"stump":
			tex = "res://res/stump1.png";
			dangerous = false;
			can_move = false;
			peckable = false;
			sprite_scale_mult = 0.65;
	
	var texture = load(tex) as CompressedTexture2D;
	
	body_sprite.texture = texture;
	body_sprite.scale = target_size_vec / texture.get_size() * sprite_scale_mult;
	body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST;
	
	arrow_sprite.scale = target_size_vec / arrow_sprite.texture.get_size() * Vector2(1, 0.7);
	danger_sprite.scale = target_size_vec / danger_sprite.texture.get_size();
	true_danger_scale = danger_sprite.scale;
	
	# Do this before rotating the arrow as it is a child of the arrow
	danger_sprite.position.x = sprite_target_size + tile_spacing;
	
	arrow_sprite.visible = can_move;
	danger_sprite.visible = dangerous;
	
	rotate_arrow_to_dir();
	pass;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if true_arrow_pos:
		arrow_time += delta * 5;
		arrow_sprite.position.x = true_arrow_pos.x + sin(arrow_time) * sprite_target_size * 0.05;
	
	# Check if we are supposed to be reacting to a peck
	if reacting_to_event:
		
		# If we're supposed to be reacting, but haven't started yet:
		if !fulfilling_single_action:
			
			# If we still have actions in the queue
			if action_queue.size() != 0:
				current_reaction = action_queue.pop_front();
				reaction_start_time = Time.get_ticks_msec();
				fulfilling_single_action = true;
			else:
				change_reaction_state(false);
		
		# Otherwise, do the current reaction:
		else: 
			if current_reaction["action"] == "move":
				
				if !targ_move_pos:
					targ_move_pos = position;
					start_move_pos = position;
					true_move_pos = position;
					var temp_global = global_position;
					if facing_dir == 1 or facing_dir == 3:
						var offset = (facing_dir-2) * (sprite_target_size + tile_spacing);
						targ_move_pos.y += offset;
						temp_global.y += offset;
					elif facing_dir == 2 or facing_dir == 4:
						var offset = (facing_dir-3) * (sprite_target_size + tile_spacing);
						targ_move_pos.x -= offset;
						temp_global.x -= offset;
					
					if grid.is_animal(temp_global):
						
						# TODO add run into effect!
						targ_move_pos = null;
						action_queue = [];
						fulfilling_single_action = false;
				
				if fulfilling_single_action:
					true_move_pos = true_move_pos.move_toward(targ_move_pos, MOVE_SPEED * delta);
					var temp_scale = sin(PI * (true_move_pos.distance_to(targ_move_pos) / start_move_pos.distance_to(targ_move_pos)))
					scale = Vector2(1 + temp_scale * 0.15, 1 + temp_scale * 0.15);
					position = true_move_pos + Vector2(0,-temp_scale*sprite_target_size*0.2);
					if true_move_pos == targ_move_pos:
						position = true_move_pos;
						targ_move_pos = null;
						fulfilling_single_action = false; 
			
			elif current_reaction["action"] == "turn":
				
				if targ_dir == null:
					#targ_dir = (facing_dir + 7 + current_reaction["value"]) % 4 + 1;
					targ_dir = (facing_dir + current_reaction["value"] - 2) * 90;
					if dir_arrow.rotation_degrees == 270 and targ_dir == 0:
						targ_dir = 360;
					
					if targ_dir == 270 and dir_arrow.rotation_degrees == 0:
						targ_dir = -90;
					
					if targ_dir == -180 and dir_arrow.rotation_degrees == 270:
						targ_dir = 180;
						
					#print(facing_dir);
					#print(dir_arrow.rotation_degrees);
					#print(targ_dir);
					#print('--');
					
				dir_arrow.rotation_degrees = move_toward(dir_arrow.rotation_degrees, targ_dir, ROT_SPEED * delta);
				
				if dir_arrow.rotation_degrees == targ_dir:
					if targ_dir == 360:
						dir_arrow.rotation_degrees = 0;
					if targ_dir == -90:
						dir_arrow.rotation_degrees = 270
					
					facing_dir = (facing_dir + 7 + current_reaction["value"]) % 4 + 1;
					targ_dir = null;
					fulfilling_single_action = false;
			
			# instead of wait, do we want this to be like "shutter"? I'm imagining this is a short pause between the peck and the first reaction
			elif current_reaction["action"] == "wait":
				if Time.get_ticks_msec() - reaction_start_time >= current_reaction["value"]:
					fulfilling_single_action = false;
				
			pass;
		pass;
	
	# not reacting to peck:
	else:
		
		if true_danger_scale:
			var just_sin = sin(arrow_time*0.841563);
			var wave = 1.5 + just_sin * 0.075;
			danger_sprite.scale = true_danger_scale * Vector2(wave, wave);
			danger_sprite.self_modulate.a = 0.4 + 0.2 * just_sin;
	
func rotate_arrow_to_dir():
	dir_arrow.rotation_degrees = -180 + 90 * facing_dir;

func peck():
	
	# Make the animal pause before the first reaction
	action_queue.push_back({
		"action": "wait",
		"value": 250 #ms
	})
	
	match(type):
		"cow":
			move(1);
		"deer":
			move(2);
			turn(-1);
		"lion":
			special("roar");
	
	change_reaction_state(true);
	danger_sprite.self_modulate.a = 0;

func independant_react(queue_entry:Array):
	for action in queue_entry:
		action_queue.push_back(action);
	
	change_reaction_state(true);
	danger_sprite.self_modulate.a = 0;

func move(amt):
	for i in amt:
		action_queue.push_back({
			"action": "move",
			"value": 1
		});

func turn(amt):
	if amt == -2:
		amt = 2;
	if amt == -3:
		amt = -1;
	
	action_queue.push_back({
		"action": "turn",
		"value": amt
	});

func special(spec):
	action_queue.push_back({
		"action": "special",
		"value": spec
	});

func change_reaction_state(state):
	reacting_to_event = state;
	reaction_state_changed.emit(animal_id, state);

func get_blood():
	var new_blood = max(blood_total - blood_per_peck, 0);
	var output = blood_total - new_blood;
	blood_total = new_blood;
	return output;
