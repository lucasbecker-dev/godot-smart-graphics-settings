extends Node
class_name SmartGraphicsSettings, "res://addons/smart-graphics-settings/GodotSmartGraphicsSettings.svg"

export(int, 0, 500) var target_fps := 60
export(Environment) var environment: Environment = ProjectSettings.get(
	"rendering/environment/default_environment"
)

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
onready var thread_mode := _get_thread_mode()

const _MIN_TARGET_FPS := 0
const _MAX_TARGET_FPS := 1000


func _ready() -> void:
	set_process(false)
	if state == State.READY:
		set_process(true)
	else:
		printerr("SmartGraphicsSettings encountered an error and could not be initialized.")
		print_stack()
	print_debug("target_fps: ", target_fps, "\nenvironment: ", environment)  # TODO: remove this debug print


func _process(delta: float) -> void:
	pass


func _validate_export_vars() -> int:
	if target_fps < _MIN_TARGET_FPS or target_fps > _MAX_TARGET_FPS:
		printerr("Target FPS is out of range.\ntarget_fps: ", target_fps)
		print_stack()
		return State.ERROR
	if not environment:
		printerr("Invalid environment.\nenvironment: ", environment)
		print_stack()
		return State.ERROR
	return State.READY


func _get_thread_mode(new_thread_mode: int = -1) -> int:
	if new_thread_mode != -1:
		thread_mode = new_thread_mode
		return thread_mode
	elif OS.can_use_threads():
		return ThreadMode.THREADED
	return ThreadMode.SINGLE


func _check() -> int:
	return State.ERROR


func _adjust() -> int:
	return State.ERROR


func _stable() -> int:
	return State.ERROR


func _thread_execute() -> void:
	pass
