extends Node3D

## Available mesh types for stress testing
var mesh_types: Array[Mesh] = []

## Stress test objects container
@onready var stress_objects: Node3D = $StressObjects

## FPS display
@onready var fps_label: Label = $FPSLabel

## Status display
@onready var status_label: Label = $StatusLabel

## Reference to the SmartGraphicsSettings singleton
var settings: Node

## Number of objects to spawn per batch
var spawn_count: int = 100

func _ready() -> void:
	# Initialize mesh types
	mesh_types.append(BoxMesh.new())
	mesh_types.append(SphereMesh.new())
	mesh_types.append(TorusMesh.new())
	mesh_types.append(CylinderMesh.new())
	
	# Set up input actions for quality presets
	if not InputMap.has_action("quality_preset_1"):
		for i in range(1, 6):
			var action_name: String = "quality_preset_%d" % i
			InputMap.add_action(action_name)
			var event: InputEventKey = InputEventKey.new()
			event.keycode = KEY_1 + i - 1 # KEY_1, KEY_2, etc.
			InputMap.action_add_event(action_name, event)
	
	# Set up stress test input
	if not InputMap.has_action("stress_test"):
		InputMap.add_action("stress_test")
		var event: InputEventKey = InputEventKey.new()
		event.keycode = KEY_SPACE
		InputMap.action_add_event("stress_test", event)
	
	# Get the SmartGraphicsSettings singleton
	settings = get_node("/root/SmartGraphicsSettings")
	if not settings:
		push_error("Demo: Failed to find SmartGraphicsSettings singleton")
		return
	
	# Create a timer to update the UI
	var timer: Timer = Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(_update_ui)
	timer.autostart = true
	add_child(timer)
	
	# Update UI immediately
	_update_ui()

func _input(event: InputEvent) -> void:
	# Handle quality preset hotkeys
	for i in range(1, 6):
		var action_name: String = "quality_preset_%d" % i
		if event.is_action_pressed(action_name):
			var preset: int = i - 1 # Convert to 0-based index
			if settings:
				settings.apply_preset(preset)
				print("Applied quality preset: ", i)
			return
	
	# Handle stress test
	if event.is_action_pressed("stress_test"):
		spawn_stress_objects()

## Spawn a batch of objects to stress the renderer
func spawn_stress_objects() -> void:
	for i in range(spawn_count):
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		var mesh_type: Mesh = mesh_types[randi() % mesh_types.size()]
		mesh_instance.mesh = mesh_type
		
		# Random position
		var x: float = randf_range(-10, 10)
		var z: float = randf_range(-10, 10)
		mesh_instance.position = Vector3(x, 1.0, z)
		
		# Random rotation
		mesh_instance.rotation = Vector3(
			randf_range(0, TAU),
			randf_range(0, TAU),
			randf_range(0, TAU)
		)
		
		# Random scale
		var scale: float = randf_range(0.5, 1.5)
		mesh_instance.scale = Vector3(scale, scale, scale)
		
		stress_objects.add_child(mesh_instance)
	
	print("Spawned %d more objects. Total: %d" % [spawn_count, stress_objects.get_child_count()])

## Update the UI with current status information
func _update_ui() -> void:
	if not settings:
		return
	
	# Update FPS display
	if fps_label:
		var avg_fps: float = settings.get_average_fps()
		var is_stable: bool = settings.is_fps_stable()
		var stability_text: String = "stable" if is_stable else "unstable"
		fps_label.text = "FPS: %.1f (%s)" % [avg_fps, stability_text]
		
		# Color code based on performance
		var adaptive_graphics = settings.get_adaptive_graphics()
		if adaptive_graphics:
			var target_fps: int = adaptive_graphics.target_fps
			var tolerance: int = adaptive_graphics.fps_tolerance
			
			if avg_fps >= target_fps - tolerance:
				fps_label.modulate = Color(0.2, 1.0, 0.2) # Green for good performance
			elif avg_fps >= target_fps - tolerance * 2:
				fps_label.modulate = Color(1.0, 1.0, 0.2) # Yellow for borderline performance
			else:
				fps_label.modulate = Color(1.0, 0.2, 0.2) # Red for poor performance
	
	# Update status display
	if status_label:
		var info: Dictionary = settings.get_status_info()
		
		# Get the current action directly
		var current_action: String = info.current_action
		
		# Build the status text
		var status_text: String = "Status: %s\n" % current_action
		status_text += "Renderer: %s\n" % info.renderer
		status_text += "VSync: %s\n" % _get_vsync_name(info.vsync_mode)
		status_text += "Threading: %s" % ("Active" if info.threading else "Inactive")
		
		status_label.text = status_text

## Helper function to get the name of a VSync mode
func _get_vsync_name(mode: int) -> String:
	var vsync_modes: Array[String] = ["Disabled", "Enabled", "Adaptive", "Mailbox"]
	if mode >= 0 and mode < vsync_modes.size():
		return vsync_modes[mode]
	return "Unknown"