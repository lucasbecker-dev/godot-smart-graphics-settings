extends Node3D

## Available mesh types for stress testing
var mesh_types: Array[Mesh] = []

## Stress test objects container
@onready var stress_objects: Node3D = $StressObjects

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

func _input(event: InputEvent) -> void:
	# Handle quality preset hotkeys
	for i in range(1, 6):
		var action_name: String = "quality_preset_%d" % i
		if event.is_action_pressed(action_name):
			var preset: int = i - 1 # Convert to 0-based index
			SmartGraphicsSettings.apply_preset(preset)
			return
	
	# Handle stress test
	if event.is_action_pressed("stress_test"):
		spawn_stress_objects()

## Spawn a batch of objects to stress the renderer
func spawn_stress_objects() -> void:
	for i in range(20):
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
	
	print("Spawned 20 more objects. Total: ", stress_objects.get_child_count())
