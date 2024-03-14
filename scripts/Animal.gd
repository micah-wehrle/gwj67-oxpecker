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
var pushable = true;
var peckable = true;
var can_step = true;
var bully = false;
var strongman = false;
var destory_on_muscle = false;
var slow_af = false;

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
	var sprite_scale_mult = 0.85;
	match(type):
		"cow":
			tex = "res://res/cow1.png"; # should pre-load for reuse?
		"deer":
			tex = "res://res/deer1.png";
		"stump":
			tex = "res://res/stump1.png";
			dangerous = false;
			can_step = false;
			pushable = false;
			peckable = false;
			destory_on_muscle = true;
			sprite_scale_mult = 0.65;
		"rhino":
			tex = "res://res/rhino.png";
			pushable = false;
			bully = true;
		"gorilla":
			tex = "res://res/gorilla1.png";
			pushable = false;
			bully = true;
			strongman = true;
		"lion":
			tex = "res://res/lion.png";
			pushable = false;
			can_step = false;
		"turtle":
			tex = "res://res/turtle1.png";
			slow_af = true;
		
	
	var texture = load(tex) as CompressedTexture2D;
	
	body_sprite.texture = texture;
	body_sprite.scale = target_size_vec / texture.get_size() * sprite_scale_mult;
	body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST;
	body_sprite.flip_h = randf() < 0.5;
	
	arrow_sprite.scale = target_size_vec / arrow_sprite.texture.get_size() * Vector2(1, 0.7);
	danger_sprite.scale = target_size_vec / danger_sprite.texture.get_size();
	true_danger_scale = danger_sprite.scale;
	
	# Do this before rotating the arrow as it is a child of the arrow
	danger_sprite.position.x = sprite_target_size + tile_spacing;
	
	arrow_sprite.visible = can_step;
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
			if current_reaction["action"] == "move" or current_reaction["action"] == "bump" or current_reaction["action"] == "charge" or current_reaction["action"] == "muscle":
				
				if !targ_move_pos:
					targ_move_pos = position;
					start_move_pos = position;
					true_move_pos = position;
					var temp_global = global_position;
					
					var facing_to_use = facing_dir if current_reaction["value"] == -1 else current_reaction["value"];
					
					if facing_to_use == 1 or facing_to_use == 3:
						var offset = (facing_to_use-2) * (sprite_target_size + tile_spacing);
						targ_move_pos.y += offset;
						temp_global.y += offset;
					elif facing_to_use == 2 or facing_to_use == 4:
						var offset = (facing_to_use-3) * (sprite_target_size + tile_spacing);
						targ_move_pos.x -= offset;
						temp_global.x -= offset;
						
					var hit_animal = grid.is_pos_animal(temp_global)
					var hit_wall = grid.is_pos_wall(temp_global)
					
					if hit_animal or hit_wall:
						
						# TODO add run into effect!
						#targ_move_pos = null;
						if current_reaction["action"] == "move":
							action_queue = [{
								"action": "bump",
								"value": 2
							}];
						elif current_reaction["action"] == "charge":
							if hit_animal and hit_animal.pushable and bully:
								action_queue.push_front({
									"action": "bump",
									"value": 2,
									"bullied animal": hit_animal
								})
							else:
								action_queue.push_front({
									"action": "bump",
									"value": 2,
								})
						elif current_reaction["action"] == "muscle":
							if hit_animal:
								if hit_animal.pushable and bully:
									action_queue.push_front({
										"action": "bump",
										"value": 2,
										"bullied animal": hit_animal
									})
								elif !hit_animal.pushable and strongman and hit_animal.destory_on_muscle:
									action_queue.push_front({ # make this an overwrite?
										"action": "bump",
										"value": 2,
										"bullied animal": hit_animal,
										"destory animal": true
									})
							else:
								action_queue.push_front({
									"action": "bump",
									"value": 2,
								})
						fulfilling_single_action = false;
				
				if fulfilling_single_action:
					var slow_offset = 1 if !("slow" in current_reaction) else 0.01;
					true_move_pos = true_move_pos.move_toward(targ_move_pos, MOVE_SPEED * delta * slow_offset);
					var hop_progress = (true_move_pos.distance_to(targ_move_pos) / start_move_pos.distance_to(targ_move_pos));
					var temp_scale = sin(PI * hop_progress)
					scale = Vector2(1 + temp_scale * 0.15 * slow_offset, 1 + temp_scale * 0.15 * slow_offset);
					
					if current_reaction["action"] == "move":
						position = true_move_pos + Vector2(0,-temp_scale*sprite_target_size*0.2 * slow_offset);
					else:
						if hop_progress <= 0.5 and current_reaction["value"] == 2:
							if bully and "bullied animal" in current_reaction:
								if "destory animal" in current_reaction:
									current_reaction["bullied animal"].queue_free();
								else:
									current_reaction["bullied animal"].independant_react([{
										"action": "move",
										"value": facing_dir
									}]);
							current_reaction["value"] = 3;
							var temp = targ_move_pos;
							targ_move_pos = start_move_pos;
							start_move_pos = temp;
							
						position = true_move_pos + Vector2(0,-temp_scale*sprite_target_size*0.2);
						
					if true_move_pos == targ_move_pos:
						position = true_move_pos;
						
						if current_reaction["action"] == "charge":
							action_queue.push_front(current_reaction);
								
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
			
			elif current_reaction["action"] == "roar":
				grid.give_queue_to_all_animals(null, self);
				fulfilling_single_action = false;
				pass;
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
	
	if !peckable:
		return;
	
	# Make the animal pause before the first reaction
	action_queue.push_back({
		"action": "wait",
		"value": 250 #ms
	})
	
	build_own_queue();
	
	change_reaction_state(true);

func build_own_queue():
	match(type):
		"cow":
			move(1);
		"deer":
			move(2);
			turn(-1);
		"lion":
			special("roar");
		"rhino":
			special("charge");
			turn(1);
		"gorilla":
			special("muscle");
		"turtle":
			action_queue.push_back({
				"action": "move",
				"value": -1,
				"slow": true
			});
			

func independant_react(queue_entry:Array):
	for action in queue_entry:
		action_queue.push_back(action);
	
	change_reaction_state(true);

func move(amt):
	for i in amt:
		action_queue.push_back({
			"action": "move",
			"value": -1
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
		"action": spec,
		"value": -1
	});

func change_reaction_state(state):
	reacting_to_event = state;
	reaction_state_changed.emit(animal_id, state);
	danger_sprite.self_modulate.a = 0;

func get_blood():
	if !peckable: 
		return 0;
	
	var new_blood = max(blood_total - blood_per_peck, 0);
	var output = blood_total - new_blood;
	blood_total = new_blood;
	return output;

func get_texture():
	return body_sprite.texture;

func get_attack_grid_pos():
	var output_pos = global_position;
	if facing_dir == 1 or facing_dir == 3:
		var offset = (facing_dir-2) * (sprite_target_size + tile_spacing);
		output_pos.y += offset;
	elif facing_dir == 2 or facing_dir == 4:
		var offset = (facing_dir-3) * (sprite_target_size + tile_spacing);
		output_pos.x -= offset;
	
	return grid.calc_grid_pos(output_pos);
