extends Node2D

# To be passed by init or calculated later
var type;
var sprite_target_size;
var tile_spacing;
var facing_dir;
var blood_total;
var blood_per_peck;

var action_queue = [];
var reacting_to_peck = false;
var fulfilling_single_action = false;
var current_reaction;
var reaction_start_time;

signal end_reaction_signal();

@onready var body_sprite = $"Sprites/Body Sprite" as Sprite2D;
@onready var dir_arrow = $"Sprites/Dir Arrow" as Node2D;
@onready var arrow_sprite = $"Sprites/Dir Arrow/Dir Arrow Sprite" as Sprite2D;
@onready var danger_sprite = $"Sprites/Dir Arrow/Danger Space Sprite" as Sprite2D;

func init(type, sprite_target_size, tile_spacing, pos, facing_dir):
	self.type = type;
	self.sprite_target_size = sprite_target_size;
	self.tile_spacing = tile_spacing;
	self.facing_dir = facing_dir;
	
	position = pos;
	
	var target_size_vec = Vector2(sprite_target_size, sprite_target_size);
	
	blood_total = 20;
	blood_per_peck = 5;
	
	var tex;
	match(type):
		"cow":
			tex = "res://res/cow.png"; # should pre-load for reuse?
		"deer":
			tex = "res://res/deer.png";
	
	var texture = load(tex) as CompressedTexture2D;
	
	body_sprite.texture = texture;
	
	body_sprite.scale = target_size_vec / texture.get_size();
	arrow_sprite.scale = target_size_vec / arrow_sprite.texture.get_size() * Vector2(1, 0.7);
	danger_sprite.scale = target_size_vec / danger_sprite.texture.get_size();
	
	# Do this before rotating the arrow as it is a child of the arrow
	danger_sprite.position.x = sprite_target_size + tile_spacing;
	
	rotate_arrow_to_dir();
	pass;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# Check if we are supposed to be reacting to a peck
	if reacting_to_peck:
		
		# If we're supposed to be reacting, but haven't started yet:
		if !fulfilling_single_action:
			
			# If we still have actions in the queue
			if action_queue.size() != 0:
				current_reaction = action_queue.pop_front();
				reaction_start_time = Time.get_ticks_msec();
				fulfilling_single_action = true;
			else:
				end_reaction();
		
		# Otherwise, do the current reaction:
		else: 
			if current_reaction["action"] == "move":
				
				if facing_dir == 1 or facing_dir == 3:
					position.y += (facing_dir-2) * (sprite_target_size + tile_spacing);
				elif facing_dir == 2 or facing_dir == 4:
					position.x -= (facing_dir-3) * (sprite_target_size + tile_spacing);
				
				fulfilling_single_action = false; # TODO make longer
			
			elif current_reaction["action"] == "turn":
				facing_dir = (facing_dir + 7 + current_reaction["value"]) % 4 + 1;
				rotate_arrow_to_dir();
				fulfilling_single_action = false; # TODO make longer
			
			# instead of wait, do we want this to be like "shutter"? I'm imagining this is a short pause between the peck and the first reaction
			elif current_reaction["action"] == "wait":
				if Time.get_ticks_msec() - reaction_start_time >= current_reaction["value"]:
					fulfilling_single_action = false;
				
			pass;
		pass;
	pass
	
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
			turn(1);
		"lion":
			special("roar");
	
	reacting_to_peck = true;

func move(amt):
	for i in amt:
		action_queue.push_back({
			"action": "move",
			"value": 1
		});

func turn(amt):
	action_queue.push_back({
		"action": "turn",
		"value": amt
	});

func special(spec):
	action_queue.push_back({
		"action": "special",
		"value": spec
	});

func end_reaction():
	reacting_to_peck = false;
	end_reaction_signal.emit(); # Tell bird it can move again

func get_blood():
	var new_blood = max(blood_total - blood_per_peck, 0);
	var output = blood_total - new_blood;
	blood_total = new_blood;
	return output;
