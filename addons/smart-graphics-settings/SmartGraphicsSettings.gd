extends Node
class_name SmartGraphicsSettings, "res://addons/smart-graphics-settings/smart-graphics-settings-icon.svg"

export(int, 0, 500) var target_fps := 60 setget set_target_fps
# export(Environment) var environment = ProjectSettings.get_setting(
# 	"rendering/environment/default_environment"
# )
export(bool) var enabled := true setget set_enabled

enum State {
	ERROR,
	READY,
	ADJUSTING,
	CHECKING,
	STABLE,
}

enum ThreadMode {
	ERROR,  # disables _process
	SINGLE,  # run logic as coroutine
	THREADED,  # run logic in thread
}

onready var _settings := preload("res://addons/smart-graphics-settings/utils/SettingsMap.gd").new()
onready var _mutex := Mutex.new()
onready var _semaphore := Semaphore.new()
onready var _thread := Thread.new()
onready var _check_timer := Timer.new()
onready var state := _validate_export_vars()
onready var thread_mode: int = ThreadMode.ERROR

const _MIN_TARGET_FPS := 0
const _MAX_TARGET_FPS := 500


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


func _ready() -> void:
	if state == State.READY:
		enabled = true
		_thread.start(self, "_thread_execute")
	else:
		enabled = false
		printerr("SmartGraphicsSettings encountered an error and could not be initialized.")
		print_stack()
		return


func _process(delta: float) -> void:
	pass


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
		return State.ERROR
#	if not environment:
#		printerr("Invalid environment.\nenvironment: ", environment)
#		print_stack()
#		return State.ERROR
	return State.READY


func set_thread_mode(new_thread_mode: int = -1) -> void:
	if new_thread_mode in ThreadMode.values():
		if new_thread_mode == ThreadMode.THREADED:
			if OS.can_use_threads():
				thread_mode = new_thread_mode
			else:
				printerr(
					"SmartGraphicsSettings cannot run in multi-threaded mode on this OS: ",
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


func _check() -> int:
	# TODO: implement checking logic
	return State.ERROR


func _adjust() -> int:
	# TODO: implement adjusting logic
	return State.ERROR


func _stable() -> int:
	# TODO: implement stable fps logic
	return State.ERROR


func _coroutine_execute() -> void:
	# TODO: implement coroutine logic
	pass


func _thread_execute() -> void:
	# TODO: implement threaded logic
	pass


func _exit_tree() -> void:
	_semaphore.post()
	if _thread.is_alive():
		yield(_thread.wait_to_finish(), "completed")
	else:
		call_deferred(_thread.wait_to_finish())
	self.queue_free()
