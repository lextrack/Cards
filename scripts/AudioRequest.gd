class_name AudioRequest
extends RefCounted

enum Priority {
	LOW = 0,
	NORMAL = 1,
	HIGH = 2,
	CRITICAL = 3
}

enum AudioCategory {
	SFX,
	MUSIC,
	UI,
	VOICE,
	AMBIENT
}

var pitch: float = 1.0
var volume_offset: float = 0.0
var delay: float = 0.0
var priority: Priority = Priority.NORMAL
var category: AudioCategory = AudioCategory.SFX

var fade_in_duration: float = 0.0
var fade_out_duration: float = 0.0
var loop_count: int = 1 
var duck_other_audio: bool = false
var duck_amount: float = -10.0

var on_started: Callable
var on_finished: Callable
var on_failed: Callable

var request_id: String = ""
var timestamp: int = 0
var user_data: Dictionary = {}

func _init():
	timestamp = Time.get_ticks_msec()
	request_id = _generate_id()

func _generate_id() -> String:
	return "audio_" + str(timestamp) + "_" + str(randi() % 1000)

static func create_simple(p: float = 1.0, vol: float = 0.0) -> AudioRequest:
	var request = AudioRequest.new()
	request.pitch = p
	request.volume_offset = vol
	return request

static func create_with_delay(d: float, p: float = 1.0, vol: float = 0.0) -> AudioRequest:
	var request = create_simple(p, vol)
	request.delay = d
	return request

static func create_damage_sound(damage: int) -> AudioRequest:
	var request = AudioRequest.new()
	request.pitch = 1.0 + (damage * 0.05)
	request.pitch = clamp(request.pitch, 0.5, 2.0)
	request.volume_offset = min(damage * 0.5, 6.0)
	request.priority = Priority.HIGH
	return request

static func create_attack_sound(damage: int) -> AudioRequest:
	var request = AudioRequest.new()
	request.pitch = 1.0 + (damage * 0.05)
	request.pitch = clamp(request.pitch, 0.5, 2.0)
	request.priority = Priority.NORMAL
	return request

static func create_ui_sound() -> AudioRequest:
	var request = AudioRequest.new()
	request.category = AudioCategory.UI
	request.priority = Priority.NORMAL
	return request

static func create_critical_sound() -> AudioRequest:
	var request = AudioRequest.new()
	request.priority = Priority.CRITICAL
	request.duck_other_audio = true
	return request

static func create_music_request() -> AudioRequest:
	var request = AudioRequest.new()
	request.category = AudioCategory.MUSIC
	request.priority = Priority.LOW
	request.loop_count = -1
	return request

static func create_layered_sound(vol_offset: float = -3.0) -> AudioRequest:
	var request = AudioRequest.new()
	request.volume_offset = vol_offset
	request.priority = Priority.NORMAL
	return request

func with_pitch(p: float) -> AudioRequest:
	pitch = p
	return self

func with_volume(vol: float) -> AudioRequest:
	volume_offset = vol
	return self

func with_delay(d: float) -> AudioRequest:
	delay = d
	return self

func with_priority(p: Priority) -> AudioRequest:
	priority = p
	return self

func with_category(cat: AudioCategory) -> AudioRequest:
	category = cat
	return self

func with_fade_in(duration: float) -> AudioRequest:
	fade_in_duration = duration
	return self

func with_fade_out(duration: float) -> AudioRequest:
	fade_out_duration = duration
	return self

func with_loop(count: int = -1) -> AudioRequest:
	loop_count = count
	return self

func with_ducking(amount: float = -10.0) -> AudioRequest:
	duck_other_audio = true
	duck_amount = amount
	return self

func with_callback_started(callback: Callable) -> AudioRequest:
	on_started = callback
	return self

func with_callback_finished(callback: Callable) -> AudioRequest:
	on_finished = callback
	return self

func with_callback_failed(callback: Callable) -> AudioRequest:
	on_failed = callback
	return self

func with_user_data(data: Dictionary) -> AudioRequest:
	user_data = data
	return self

func is_music() -> bool:
	return category == AudioCategory.MUSIC

func should_loop() -> bool:
	return loop_count != 1

func is_infinite_loop() -> bool:
	return loop_count == -1

func has_effects() -> bool:
	return fade_in_duration > 0.0 or fade_out_duration > 0.0 or duck_other_audio

func get_priority_value() -> int:
	return int(priority)

func _to_string() -> String:
	return "AudioRequest[%s] pitch:%.2f vol:%.1f delay:%.1f priority:%s" % [
		request_id, pitch, volume_offset, delay, Priority.keys()[priority]
	]
