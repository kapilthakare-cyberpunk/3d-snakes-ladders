class_name AudioManager
extends Node

## AudioManager — centralized SFX / BGM / volume control
## Place audio files in res://assets/audio/ and update the paths below.

signal bgm_changed(is_playing: bool)
signal sfx_volume_changed(value: float)
signal bgm_volume_changed(value: float)

enum SFX {
	DICE_ROLL,
	HOP,
	LADDER_WHOOSH,
	SNAKE_SLIDE,
	WIN_FANFARE,
	BUTTON_CLICK,
	LANDING_BURST
}

const SFX_PATHS: Dictionary = {
	SFX.DICE_ROLL: "res://assets/audio/sfx/dice_roll.ogg",
	SFX.HOP: "res://assets/audio/sfx/hop.ogg",
	SFX.LADDER_WHOOSH: "res://assets/audio/sfx/ladder_whoosh.ogg",
	SFX.SNAKE_SLIDE: "res://assets/audio/sfx/snake_slide.ogg",
	SFX.WIN_FANFARE: "res://assets/audio/sfx/win_fanfare.ogg",
	SFX.BUTTON_CLICK: "res://assets/audio/sfx/button_click.ogg",
	SFX.LANDING_BURST: "res://assets/audio/sfx/landing_burst.ogg",
}

const BGM_PATHS: Dictionary = {
	"menu": "res://assets/audio/bgm/menu_theme.ogg",
	"gameplay": "res://assets/audio/bgm/gameplay_theme.ogg",
}

var sfx_bus: AudioBusLayout
var bgm_bus: AudioBusLayout
var sfx_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer
var sfx_volume: float = 0.8:
	set(v):
		sfx_volume = clampi(v, 0.0, 1.0)
		if sfx_player:
			sfx_player.volume_db = linear_to_db(sfx_volume)
		sfx_volume_changed.emit(sfx_volume)
var bgm_volume: float = 0.6:
	set(v):
		bgm_volume = clampi(v, 0.0, 1.0)
		if bgm_player:
			bgm_player.volume_db = linear_to_db(bgm_volume)
		bgm_volume_changed.emit(bgm_volume)

var current_bgm_key: String = ""
var is_muted: bool = false:
	set(v):
		is_muted = v
		if sfx_player:
			sfx_player.volume_db = linear_to_db(sfx_volume) if not is_muted else -80.0
		if bgm_player:
			bgm_player.volume_db = linear_to_db(bgm_volume) if not is_muted else -80.0

func _ready() -> void:
	_setup_audio_buses()
	_create_players()
	_connect_signals()

func _setup_audio_buses() -> void:
	var idx_sfx := AudioServer.bus_count
	AudioServer.add_bus(idx_sfx)
	AudioServer.set_bus_name(idx_sfx, "SFX")
	sfx_bus = AudioServer.get_bus_layout(idx_sfx)

	var idx_bgm := AudioServer.bus_count
	AudioServer.add_bus(idx_bgm)
	AudioServer.set_bus_name(idx_bgm, "BGM")
	bgm_bus = AudioServer.get_bus_layout(idx_bgm)

	AudioServer.set_bus_volume_db(idx_sfx, linear_to_db(sfx_volume))
	AudioServer.set_bus_volume_db(idx_bgm, linear_to_db(bgm_volume))

func _create_players() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	sfx_player.volume_db = linear_to_db(sfx_volume)
	add_child(sfx_player)

	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "BGM"
	bgm_player.volume_db = linear_to_db(bgm_volume)
	bgm_player.autoplay = false
	bgm_player.finished.connect(_on_bgm_finished)
	add_child(bgm_player)

func _connect_signals() -> void:
	pass

func play_sfx(id: SFX, pitch_variation: float = 0.0) -> void:
	if not sfx_player or is_muted:
		return
	var path: String = SFX_PATHS.get(id, "")
	if path.is_empty():
		return
	var stream := load(path)
	if not stream:
		return
	sfx_player.stream = stream
	sfx_player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	sfx_player.play()

func play_bgm(key: String, fade_duration: float = 1.2) -> void:
	if not bgm_player:
		return
	var path: String = BGM_PATHS.get(key, "")
	if path.is_empty():
		return
	var stream := load(path)
	if not stream:
		return
	if current_bgm_key == key and bgm_player.playing:
		return
	current_bgm_key = key
	_fade_bgm(stream, fade_duration)

func stop_bgm(fade_duration: float = 0.8) -> void:
	if not bgm_player or not bgm_player.playing:
		return
	_fade_out(fade_duration)

func _fade_bgm(new_stream: AudioStream, duration: float) -> void:
	if bgm_player.playing:
		_fade_out(duration * 0.5)
		await get_tree().create_timer(duration * 0.5).timeout
	bgm_player.stream = new_stream
	bgm_player.volume_db = linear_to_db(bgm_volume)
	bgm_player.play()
	_fade_in(duration * 0.5)

func _fade_out(duration: float) -> void:
	if not bgm_player:
		return
	var tween := create_tween()
	tween.tween_property(self, "_bgm_volume_target", -80.0, duration)
	await tween.finished
	if bgm_player:
		bgm_player.stop()

func _fade_in(duration: float) -> void:
	if not bgm_player:
		return
	bgm_player.volume_db = -80.0
	var tween := create_tween()
	tween.tween_property(self, "_bgm_volume_target", linear_to_db(bgm_volume), duration)

var _bgm_volume_target: float = 0.0:
	set(v):
		if bgm_player:
			bgm_player.volume_db = v

func _on_bgm_finished() -> void:
	if bgm_player and bgm_player.playing:
		bgm_player.play()
	bgm_changed.emit(false)

func set_sfx_volume_linear(value: float) -> void:
	sfx_volume = value

func set_bgm_volume_linear(value: float) -> void:
	bgm_volume = value

func toggle_mute() -> void:
	is_muted = not is_muted
