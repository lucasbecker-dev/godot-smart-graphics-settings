extends "../State.gd"

var _sgs := load("../../SmartGraphicsSettings.gd")
var _current_fps := Performance.get_monitor(Performance.TIME_FPS)
var _addon_target_fps: int = _sgs.target_fps
var _engine_target_fps: int = Engine.target_fps


func process_execute() -> void:
	print_debug(_current_fps)
