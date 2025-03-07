@tool
@icon("res://addons/smart_graphics_settings/smart-graphics-settings-icon.svg")
class_name FPSMonitor
extends Node

## Stores the history of FPS values for analysis
var fps_history: Array[float] = []

## Running sum of FPS values for efficient average calculation
var running_sum: float = 0.0

## Number of frames to keep in history (about 1 second at 60fps)
var history_size: int = 60

## Threshold for determining if FPS is stable (variance must be below this)
var stable_threshold: float = 5.0

## Mutex for thread-safe access to FPS data
var fps_mutex: Mutex = Mutex.new()

## Hysteresis for stability detection to prevent rapid fluctuations
var stability_hysteresis: int = 5
var stability_counter: int = 0
var last_stability_state: bool = true # Default to stable

## Process function that collects FPS data each frame
func _process(_delta: float) -> void:
	# Skip processing in editor
	if Engine.is_editor_hint():
		return
		
	var current_fps: float = Engine.get_frames_per_second()
	
	fps_mutex.lock()
	# Update running sum and history
	running_sum += current_fps
	fps_history.append(current_fps)
	
	if fps_history.size() > history_size:
		running_sum -= fps_history.pop_front()
	fps_mutex.unlock()

## Calculate the average FPS from the history in a thread-safe way
func get_average_fps() -> float:
	fps_mutex.lock()
	var result: float = 0.0
	var size: int = fps_history.size()
	
	if size > 0:
		result = running_sum / size
	else:
		# Return current FPS if no history is available
		result = Engine.get_frames_per_second()
	
	fps_mutex.unlock()
	
	return result

## Get a thread-safe copy of the FPS history
func get_fps_history_copy() -> Array[float]:
	fps_mutex.lock()
	var copy: Array[float] = fps_history.duplicate()
	fps_mutex.unlock()
	return copy

## Determine if the FPS is stable (low variance) in a thread-safe way
## Uses hysteresis to prevent rapid fluctuations between stable and unstable states
func is_fps_stable() -> bool:
	fps_mutex.lock()
	var size: int = fps_history.size()
	
	# Need at least a few frames to make a determination
	if size < 10:
		fps_mutex.unlock()
		return true # Default to stable with insufficient data
		
	var avg: float = running_sum / size
	var variance: float = 0.0
	
	for fps in fps_history:
		variance += pow(fps - avg, 2)
	
	variance /= size
	
	# Calculate the coefficient of variation (CV) - a normalized measure of dispersion
	var cv: float = 0.0
	if avg > 0:
		cv = sqrt(variance) / avg
	
	fps_mutex.unlock()
	
	# Determine the raw stability state
	# More lenient threshold for stability
	var raw_stability: bool = variance < stable_threshold * 2 and cv < 0.15
	
	# Apply hysteresis to prevent rapid fluctuations
	if raw_stability != last_stability_state:
		stability_counter += 1
		if stability_counter >= stability_hysteresis:
			last_stability_state = raw_stability
			stability_counter = 0
	else:
		stability_counter = 0
	
	return last_stability_state

## Clear the FPS history in a thread-safe way
func clear_history() -> void:
	fps_mutex.lock()
	fps_history.clear()
	running_sum = 0.0
	stability_counter = 0
	last_stability_state = true # Default to stable when cleared
	fps_mutex.unlock()
