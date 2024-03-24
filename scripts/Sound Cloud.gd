extends Node2D

@onready var music = $Music as AudioStreamPlayer2D;
@onready var peck = $Peck as AudioStreamPlayer2D;
@onready var thud = $Thud
@onready var grass = $Grass
@onready var lion = $Lion
@onready var flap = $Flap
@onready var flap_timer = $"Flap/Flap Timer"
@onready var dead = $Dead
@onready var boom = $Boom



var flapping = false;

var disable_grass = false;


#@onready var grass_sound = load("res://sounds/396016__morganpurkis__rustling-grass-4.wav");

func _ready():
	if !persist.show_blood:
		var kiss_sound = load("res://sounds/kiss.wav");
		peck.stream = kiss_sound;
		peck.volume_db = 9.8;
	
	flap_timer.connect("timeout", _flap_loop);

func _restart_music():
	music.stop();
	music.play();
	
func start_music():
	#music.play(persist.last_song_time);
	music.connect("finished", _restart_music);

func store_music():
	persist.last_song_time = music.get_playback_position();

func play_peck():
	peck.stop();
	peck.play();

func wood_hit():
	thud.stop();
	thud.play();
	
func play_grass():
	if disable_grass:
		return;
	grass.stop();
	grass.pitch_scale = randf_range(0.87, 1.13);
	grass.play();

func play_lion():
	lion.stop();
	lion.play(0.4);

func play_flap():
	
	if flapping:
		return;
	flap_timer.start();
	flapping = true;
	flap.play(0.2);

func _flap_loop():
	flap.stop();
	flap.play(0.2);
	
func stop_flap():
	flapping = false;
	flap.stop();
	flap_timer.stop();

func play_dead():
	dead.stop();
	dead.play();
	
func play_boom():
	boom.stop();
	boom.play();
