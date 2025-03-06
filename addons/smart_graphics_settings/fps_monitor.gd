@tool
@icon("res://addons/smart_graphics_settings/smart-graphics-settings-icon.svg")
class_name FPSMonitor
extends Node

## Stores the history of FPS values for analysis
var fps_history: Array[float] = []

## Number of frames to keep in history (about 1 second at 60fps)
var history_size: int = 60

## Threshold for determining if FPS is stable (variance must be below this)
var stable_threshold: float = 5.0

## Process function that collects FPS data each frame
func _process(_delta: float) -> void:
	# Skip processing in editor
	if Engine.is_editor_hint():
		return
		
	var current_fps: float = Engine.get_frames_per_second()
	fps_history.append(current_fps)
	
	if fps_history.size() > history_size:
		fps_history.pop_front()

## Calculate the average FPS from the history
func get_average_fps() -> float:
	if fps_history.size() == 0:
		return 0.0
	
	var sum: float = 0.0
	for fps in fps_history:
		sum += fps
	return sum / fps_history.size()

## Determine if the FPS is stable (low variance)
func is_fps_stable() -> bool:
	if fps_history.size() < history_size:
		return false
		
	var avg: float = get_average_fps()
	var variance: float = 0.0
	
	for fps in fps_history:
		variance += pow(fps - avg, 2)
	
	variance /= fps_history.size()
	return variance < stable_threshold