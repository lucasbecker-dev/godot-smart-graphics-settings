extends Node

export(int, 0, 500) var target_fps := 60
export(Environment) var environment = ProjectSettings.get(
	"rendering/environment/default_environment"
)

enum {
	ERROR = -1,
	READY = 0,
	ADJUSTING = 1,
	CHECKING = 2,
	STABLE = 3,
}

enum thread_mode {
	NOT_THREADED,
	THREADED,
}

onready var _mut := Mutex.new()
onready var _sem := Semaphore.new()
onready var _thread := Thread.new()
onready var _check_timer := Timer.new()
onready var _state := ERROR

const _MIN_TARGET_FPS := 0
const _MAX_TARGET_FPS := 1000


func _ready() -> void:
	_state = _validate_export_vars()
	print_debug("target_fps: ", target_fps, "\nenvironment: ", environment)  # TODO: remove this debug print


func _process(delta: float) -> void:
	pass


func _validate_export_vars() -> int:
	if target_fps < _MIN_TARGET_FPS or target_fps > _MAX_TARGET_FPS:
		printerr("Target FPS is out of range.\ntarget_fps: ", target_fps)
		print_stack()
		return ERROR
	if not environment:
		printerr("Invalid environment.\nenvironment: ", environment)
		print_stack()
		return ERROR
	return READY


func _check() -> int:
	return ERROR


func _adjust() -> int:
	return ERROR


func _stable() -> int:
	return ERROR


func _thread_execute() -> void:
	pass
