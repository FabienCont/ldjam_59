extends Node

const MUSIC_MENU   := "res://assets/music/untitled.wav"
const MUSIC_MENU1   := "res://assets/music/music2.wav"
const MUSIC_MENU2   := "res://assets/music/tambour2.wav"

const SFX_CROW   := "res://assets/music/crow.wav"
const SFX_CROW_1   := "res://assets/music/crow1.wav"

const SFX_WALK_2   := "res://assets/music/walk2.wav"
const SFX_WALK_1   := "res://assets/music/walk1.wav"
const SFX_WALK  := "res://assets/music/walk.wav"


const music1 =preload("res://assets/music/untitled.wav")
const music2 =preload("res://assets/music/music2.wav")
const music3 =preload("res://assets/music/tambour2.wav")
const music4 =preload("res://assets/music/crow.wav")
const music5 =preload("res://assets/music/crow1.wav")
const music6 =preload("res://assets/music/walk2.wav")
const music7 =preload("res://assets/music/walk1.wav")
const music8 =preload("res://assets/music/walk.wav")

var _music_player: AudioStreamPlayer
var _sfx_pool:     Array[AudioStreamPlayer] = []

func _ready() -> void:
	_ensure_buses()

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

	for i in 16:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)


# ─────────────────────── music ────────────────────────────────

func play_music(path: String, crossfade: float = 0.5) -> void:
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if crossfade > 0.0 and _music_player.playing:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, crossfade)
		await tween.finished
	_music_player.stream = stream
	_music_player.volume_db = 0.0
	_music_player.play()


func stop_music(fade: float = 0.5) -> void:
	if not _music_player.playing:
		return
	if fade > 0.0:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, fade)
		await tween.finished
	_music_player.stop()


# ─────────────────────── sfx ──────────────────────────────────

func play_sfx(path: String, pitch: float = 1.0) -> void:
	if not ResourceLoader.exists(path):
		printerr("play_sfx not ResourceLoader.exists(path)"+str(path))
		return
	var player := _get_free_sfx_player()
	if player == null:
		return
	player.stream     = load(path)
	player.pitch_scale = pitch
	player.play()


# ─────────────────────── helpers ──────────────────────────────

func _get_free_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_pool:
		if not p.playing:
			return p
	return null


func _ensure_buses() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")
