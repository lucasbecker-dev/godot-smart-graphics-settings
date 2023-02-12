#TODO: Benchmark graphics settings and evaluate impact checked fidelity to generate weights
#TODO: Design algorithm for determining which settings to adjust and when
#TODO: Determine if tweaking Environment settings in addition to ProjectSettings is worthwhile
#TODO: Implement coroutine version of logic
#TODO: Implement threaded version of logic
#TODO: Determine options to expose to user
#TODO: Document and comment code adequately

class_name SmartGraphicsSettings, "./smart-graphics-settings-icon.svg"
extends Node

enum PluginState {
	READY,
	CHECKING,
	ADJUSTING,
	STABLE,
	ERROR,
}

enum ThreadMode {
	SINGLE,  # run logic as coroutine
	THREADED,  # run logic in thread
	ERROR,  # disables _process
}

const _MIN_TARGET_FPS := 0
const _MAX_TARGET_FPS := 500

@export var target_fps: int = 60 setget set_target_fps # (int, 0, 500)
@export var environments: Array # (Array, Environment)
@export var enabled: bool := true : set = set_enabled

@onready var _settings := preload("./utils/SettingsMap.gd").new()
@onready var _environments := preload("./utils/EnvironmentManager.gd").new()
@onready var _mutex := Mutex.new()
@onready var _semaphore := Semaphore.new()
@onready var _thread := Thread.new()
@onready var _check_timer := Timer.new()
@onready var _addon_state_machine
@onready var addon_state := _validate_export_vars()
@onready var thread_mode: int = ThreadMode.ERROR


func _ready() -> void:
	_settings.set_screen_height(420)
	if addon_state == PluginState.READY:
		enabled = true
		_thread.start(Callable(self,"_thread_execute"))
	else:
		enabled = false
		printerr("SmartGraphicsSettings encountered an error and could not be initialized.")
		print_stack()
		return


func _process(delta: float) -> void:
	pass


func _exit_tree() -> void:
	_semaphore.post()
	if _thread.is_alive():
		await _thread.wait_to_finish().completed
	else:
		_thread.wait_to_finish()
	self.queue_free()


func set_enabled(val: bool) -> void:
	if val == true:
		enabled = true
		set_process(true)
	else:
		enabled = false
		set_process(false)


func is_enabled() -> bool:
	return enabled


func set_target_fps(new_target_fps: int = 60) -> void:
	if new_target_fps < _MIN_TARGET_FPS or new_target_fps > _MAX_TARGET_FPS:
		printerr(
			"New target FPS is out of range.",
			"\n_MIN_TARGET_FPS: ",
			_MIN_TARGET_FPS,
			"\n_MAX_TARGET_FPS: ",
			_MAX_TARGET_FPS,
			"\nnew_target_fps: ",
			new_target_fps
		)
		print_stack()
		return
	Engine.target_fps = new_target_fps
	target_fps = Engine.target_fps


func set_thread_mode(new_thread_mode: int = ThreadMode.ERROR) -> void:
	if new_thread_mode in ThreadMode.values():
		if new_thread_mode == ThreadMode.THREADED:
			if OS.can_use_threads():
				thread_mode = new_thread_mode
			else:
				printerr(
					"SmartGraphicsSettings cannot run in multi-threaded mode checked this OS: ",
					OS.get_name(),
					"\nDefaulting to single thread mode."
				)
				thread_mode = ThreadMode.SINGLE
		else:
			thread_mode = new_thread_mode
	elif OS.can_use_threads():
		thread_mode = ThreadMode.THREADED
	else:
		thread_mode = ThreadMode.SINGLE


func _validate_export_vars() -> int:
	if target_fps < _MIN_TARGET_FPS or target_fps > _MAX_TARGET_FPS:
		printerr(
			"New target FPS is out of range.",
			"\n_MIN_TARGET_FPS: ",
			_MIN_TARGET_FPS,
			"\n_MAX_TARGET_FPS: ",
			_MAX_TARGET_FPS,
			"\ntarget_fps: ",
			target_fps
		)
		print_stack()
		return PluginState.ERROR
	return PluginState.READY


func _check() -> int:
	# TODO: implement checking logic
	return PluginState.ERROR


func _adjust() -> int:
	# TODO: implement adjusting logic
	return PluginState.ERROR


func _stable() -> int:
	# TODO: implement stable fps logic
	return PluginState.ERROR


func _coroutine_execute() -> void:
	# TODO: implement coroutine logic
	pass


func _thread_execute() -> void:
	# TODO: implement threaded logic
	pass
