extends Node
class_name SmartGraphicsSettings, "res://addons/smart-graphics-settings/smart-graphics-settings-icon.svg"

export(int, 0, 500) var target_fps := 60 setget set_target_fps
# export(Environment) var environment = ProjectSettings.get_setting(
# 	"rendering/environment/default_environment"
# )
export(bool) var _enabled := true



enum State {
	ERROR,
	READY,
	ADJUSTING,
	CHECKING,
	STABLE,
}

enum ThreadMode {
	ERROR,
	SINGLE,
	THREADED,
}

onready var _mutex := Mutex.new()
onready var _semaphore := Semaphore.new()
onready var _thread := Thread.new()
onready var _check_timer := Timer.new()
onready var state := _validate_export_vars()
onready var thread_mode: int = ThreadMode.ERROR

const _MIN_TARGET_FPS := 0
const _MAX_TARGET_FPS := 1000


func enable() -> void:
	_enabled = true
	set_process(true)


func disable() -> void:
	_enabled = false
	set_process(false)

func is_enabled() -> bool:
	return _enabled

func set_target_fps(new_target_fps: int = 60) -> void:
	if new_target_fps < _MIN_TARGET_FPS or new_target_fps > _MAX_TARGET_FPS:
		printerr("New target FPS is out of range.",
		"\n_MIN_TARGET_FPS: ", _MIN_TARGET_FPS, 
		"\n_MAX_TARGET_FPS: ", _MAX_TARGET_FPS, 
		"\nnew_target_fps: ", new_target_fps)
		print_stack()
		return
	target_fps = new_target_fps

func _ready() -> void:
	if state == State.READY:
		enable()
	else:
		disable()
		printerr("SmartGraphicsSettings encountered an error and could not be initialized.")
		print_stack()
		return


func _process(delta: float) -> void:
	pass


func _validate_export_vars() -> int:
	if target_fps < _MIN_TARGET_FPS or target_fps > _MAX_TARGET_FPS:
		printerr("New target FPS is out of range.",
		"\n_MIN_TARGET_FPS: ", _MIN_TARGET_FPS, 
		"\n_MAX_TARGET_FPS: ", _MAX_TARGET_FPS, 
		"\ntarget_fps: ", target_fps)
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
				printerr("SmartGraphicsSettings cannot run in multi-threaded mode on this OS: ", 
				OS.get_name(), "\nDefaulting to single thread mode.")
				thread_mode = ThreadMode.SINGLE
		else:
			thread_mode = new_thread_mode
	elif OS.can_use_threads():
		thread_mode = ThreadMode.THREADED
	else:
		thread_mode = ThreadMode.SINGLE


func _check() -> int:
	return State.ERROR


func _adjust() -> int:
	return State.ERROR


func _stable() -> int:
	return State.ERROR


func _thread_execute() -> void:
	pass
