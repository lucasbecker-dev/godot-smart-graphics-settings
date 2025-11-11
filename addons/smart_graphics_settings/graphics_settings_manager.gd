@tool
@icon("res://addons/smart_graphics_settings/images/smart-graphics-settings-icon.svg")
class_name GraphicsSettingsManager
extends Node

## Enum for setting priority (determines adjustment order)
enum SettingPriority {
	RENDER_SCALE = 0, # Minimal visual impact, adjust first
	ANTI_ALIASING = 10, # Low visual impact
	POST_PROCESSING = 20, # Medium visual impact
	SHADOWS = 30, # Medium-high visual impact
	REFLECTIONS = 40, # High visual impact
	GLOBAL_ILLUMINATION = 50 # Major visual impact, adjust last
}

## Enum for setting type (determines how the setting is applied)
enum SettingType {
	VIEWPORT,
	ENVIRONMENT,
	CAMERA,
	RENDER_SCALE
}

## Enum for renderer type
enum RendererType {
	FORWARD_PLUS,
	MOBILE,
	COMPATIBILITY,
	CUSTOM
}

## Current renderer being used
var current_renderer: RendererType = RendererType.FORWARD_PLUS

## Define setting structure with strong typing
class Setting:
	var values: Array[Variant]
	var current_index: int
	var priority: SettingPriority
	var type: SettingType
	
	func _init(p_values: Array[Variant], p_current_index: int, p_priority: SettingPriority, p_type: SettingType) -> void:
		values = p_values
		current_index = p_current_index
		priority = p_priority
		type = p_type

## Dictionary of available settings
var available_settings: Dictionary[String, Setting] = {}
var _cached_priority_list: Array[String] = []
var _priority_list_dirty: bool = true

## References to nodes
var viewport: Viewport
var environment: Environment
var camera: Camera3D
var original_window_size: Vector2i

## Platform information
var platform_info: Dictionary = {}

## Whether FSR is available on this platform
var fsr_available: bool = false

func _init() -> void:
	# Gather platform information
	platform_info = {
		"os_name": OS.get_name(),
		"model_name": OS.get_model_name(),
		"processor_name": OS.get_processor_name(),
		"processor_count": OS.get_processor_count(),
		"renderer": RenderingServer.get_rendering_device().get_device_name() if RenderingServer.get_rendering_device() else "Unknown"
	}
	
	# Check if FSR is available
	fsr_available = OS.has_feature("fsr")
	
	# Initialize common settings with strong typing and more granular priorities
	available_settings = {
		# Render Scale (highest performance impact, lowest visual degradation)
		"render_scale": Setting.new(
			[0.5, 0.6, 0.7, 0.8, 0.9, 1.0],
			5, # Start with highest quality
			SettingPriority.RENDER_SCALE,
			SettingType.RENDER_SCALE
		),
		
		# Common Viewport Settings for all renderers
		"msaa": Setting.new(
			[Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X, Viewport.MSAA_8X],
			3,
			SettingPriority.ANTI_ALIASING,
			SettingType.VIEWPORT
		),
		"shadow_quality": Setting.new(
			[
				Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_DISABLED,
				Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_1,
				Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_4,
				Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_16,
				Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_64
			],
			4,
			SettingPriority.SHADOWS,
			SettingType.VIEWPORT
		),
		"shadow_size": Setting.new(
			[1024, 2048, 4096, 8192],
			2,
			SettingPriority.SHADOWS,
			SettingType.VIEWPORT
		),
		"fxaa": Setting.new(
			[Viewport.SCREEN_SPACE_AA_DISABLED, Viewport.SCREEN_SPACE_AA_FXAA],
			1,
			SettingPriority.ANTI_ALIASING,
			SettingType.VIEWPORT
		),
		
		# Camera Settings (common to all renderers)
		"dof": Setting.new(
			[false, true],
			1,
			SettingPriority.POST_PROCESSING,
			SettingType.CAMERA
		)
		# Removed motion_blur as it's not supported in Godot 4.4
	}
	
	# Renderer-specific settings will be initialized in _ready()

func _ready() -> void:
	# Skip initialization in editor
	if Engine.is_editor_hint():
		return
		
	# Get viewport with error handling
	viewport = get_viewport()
	if not viewport:
		push_error("Smart Graphics Settings: Failed to get viewport")
		return
		
	original_window_size = DisplayServer.window_get_size()
	
	# Detect current renderer
	detect_renderer()
	
	# Initialize renderer-specific settings
	initialize_renderer_specific_settings()
	
	# Find WorldEnvironment and Camera3D in the scene
	var world_env: WorldEnvironment = find_world_environment()
	if world_env:
		environment = world_env.environment
	else:
		# Try to get environment from the viewport's world
		if viewport and viewport.get_world_3d() and viewport.get_world_3d().environment:
			environment = viewport.get_world_3d().environment
		else:
			push_warning("Smart Graphics Settings: No WorldEnvironment found. Environment settings will not be applied.")
	
	camera = find_main_camera()
	if not camera:
		push_warning("Smart Graphics Settings: No Camera3D found. Camera settings will not be applied.")

## Detect which renderer is currently being used
func detect_renderer() -> void:
	var rendering_method: String = ProjectSettings.get_setting("rendering/renderer/rendering_method", "forward_plus")
	
	# Check for custom rendering pipelines
	if ProjectSettings.has_setting("rendering/custom_pipeline/enabled") and ProjectSettings.get_setting("rendering/custom_pipeline/enabled", false):
		print("Smart Graphics Settings: Detected custom rendering pipeline")
		current_renderer = RendererType.CUSTOM
		return
	
	match rendering_method:
		"forward_plus":
			current_renderer = RendererType.FORWARD_PLUS
		"mobile":
			current_renderer = RendererType.MOBILE
		"gl_compatibility":
			current_renderer = RendererType.COMPATIBILITY
		_:
			# Default to Forward+ if unknown
			current_renderer = RendererType.FORWARD_PLUS
			push_warning("Smart Graphics Settings: Unknown rendering method: %s. Defaulting to Forward+." % rendering_method)
			
	print("Smart Graphics Settings: Detected renderer: ", RendererType.keys()[current_renderer])

## Initialize settings specific to the detected renderer
func initialize_renderer_specific_settings() -> void:
	_priority_list_dirty = true
	match current_renderer:
		RendererType.FORWARD_PLUS:
			# Forward+ specific settings
			available_settings["ssao"] = Setting.new(
				[false, true],
				1,
				SettingPriority.POST_PROCESSING,
				SettingType.VIEWPORT
			)
			available_settings["ssao_quality"] = Setting.new(
				[0, 1, 2, 3, 4], # Very Low, Low, Medium, High, Ultra
				3,
				SettingPriority.POST_PROCESSING,
				SettingType.VIEWPORT
			)
			available_settings["ssr"] = Setting.new(
				[false, true],
				1,
				SettingPriority.REFLECTIONS,
				SettingType.VIEWPORT
			)
			available_settings["ssr_max_steps"] = Setting.new(
				[8, 16, 32, 64],
				3,
				SettingPriority.REFLECTIONS,
				SettingType.VIEWPORT
			)
			available_settings["sdfgi"] = Setting.new(
				[false, true],
				1,
				SettingPriority.GLOBAL_ILLUMINATION,
				SettingType.VIEWPORT
			)
			available_settings["glow"] = Setting.new(
				[false, true],
				1,
				SettingPriority.POST_PROCESSING,
				SettingType.VIEWPORT
			)
			
			# Environment Settings (Forward+ specific)
			available_settings["volumetric_fog"] = Setting.new(
				[false, true],
				1,
				SettingPriority.POST_PROCESSING,
				SettingType.ENVIRONMENT
			)
			available_settings["volumetric_fog_density"] = Setting.new(
				[0.01, 0.02, 0.03, 0.05],
				3,
				SettingPriority.POST_PROCESSING,
				SettingType.ENVIRONMENT
			)
			
		RendererType.MOBILE:
			# Mobile-specific settings
			# Mobile has more limited features
			available_settings["glow"] = Setting.new(
				[false, true],
				1,
				SettingPriority.POST_PROCESSING,
				SettingType.VIEWPORT
			)
			
			# Mobile-specific optimizations
			# Adjust render scale values for mobile
			if available_settings.has("render_scale"):
				available_settings["render_scale"] = Setting.new(
					[0.5, 0.6, 0.7, 0.75, 0.8, 1.0], # More aggressive scaling options
					4, # Default to 0.8 on mobile
					SettingPriority.RENDER_SCALE,
					SettingType.RENDER_SCALE
				)
			
		RendererType.COMPATIBILITY:
			# Compatibility-specific settings
			available_settings["glow"] = Setting.new(
				[false, true],
				1,
				SettingPriority.POST_PROCESSING,
				SettingType.VIEWPORT
			)
			# Some limited SSAO might be available in compatibility mode
			available_settings["ssao"] = Setting.new(
				[false, true],
				1,
				SettingPriority.POST_PROCESSING,
				SettingType.VIEWPORT
			)
			
		RendererType.CUSTOM:
			# For custom renderers, we'll keep only the most basic settings
			# and let the user extend as needed
			push_warning("Smart Graphics Settings: Custom rendering pipeline detected. Only basic settings will be available.")

## Find the WorldEnvironment node in the scene
func find_world_environment() -> WorldEnvironment:
	var root: Node = get_tree().root
	if not root:
		push_error("Smart Graphics Settings: Unable to access scene tree root")
		return null
		
	var world_env: WorldEnvironment = find_node_of_type(root, "WorldEnvironment") as WorldEnvironment
	
	# If not found directly, try to get it from the current scene
	if not world_env and get_tree().current_scene:
		world_env = find_node_of_type(get_tree().current_scene, "WorldEnvironment") as WorldEnvironment
	
	if not world_env:
		push_warning("Smart Graphics Settings: No WorldEnvironment node found in the scene")
	
	return world_env

## Find the main Camera3D in the scene
func find_main_camera() -> Camera3D:
	var root: Node = get_tree().root
	if not root:
		push_error("Smart Graphics Settings: Unable to access scene tree root")
		return null
		
	var camera: Camera3D = find_node_of_type(root, "Camera3D") as Camera3D
	
	# If not found directly, try to get it from the current scene
	if not camera and get_tree().current_scene:
		camera = find_node_of_type(get_tree().current_scene, "Camera3D") as Camera3D
		
	# If still not found, try to get the current camera
	if not camera and get_viewport() and get_viewport().get_camera_3d():
		camera = get_viewport().get_camera_3d()
	
	return camera

## Helper function to find a node of a specific type
func find_node_of_type(node: Node, type_name: String) -> Node:
	if not node:
		return null
		
	if node.get_class() == type_name:
		return node
	
	for child in node.get_children():
		var found: Node = find_node_of_type(child, type_name)
		if found:
			return found
	
	return null

## Check if a setting is applicable to the current renderer
func is_setting_applicable(setting_name: String) -> bool:
	if not available_settings.has(setting_name):
		return false
		
	# Define which settings apply to which renderers
	match current_renderer:
		RendererType.FORWARD_PLUS:
			return true # All settings apply to Forward+
			
		RendererType.MOBILE:
			# Return false for Forward+ specific settings
			if setting_name in ["sdfgi", "ssr", "ssr_max_steps", "volumetric_fog",
								"volumetric_fog_density", "ssao", "ssao_quality"]:
				return false
			return true
			
		RendererType.COMPATIBILITY:
			# Similar to Mobile but might have different constraints
			if setting_name in ["sdfgi", "ssr", "ssr_max_steps", "volumetric_fog",
								"volumetric_fog_density"]:
				return false
			return true
			
		RendererType.CUSTOM:
			# For custom renderers, only allow basic settings
			if setting_name in ["render_scale", "msaa", "shadow_quality", "shadow_size", "fxaa"]:
				return true
			return false
	
	return false

## Order settings by priority for adjustment
func get_settings_by_priority() -> Array[String]:
	if not _priority_list_dirty:
		return _cached_priority_list

	var settings_by_priority: Dictionary = {}
	
	# Initialize dictionary with all priority levels
	for priority in range(SettingPriority.RENDER_SCALE, SettingPriority.GLOBAL_ILLUMINATION + 10, 10):
		settings_by_priority[priority] = []
	
	# Only include settings applicable to the current renderer
	for setting_name in available_settings:
		if is_setting_applicable(setting_name):
			var priority: SettingPriority = available_settings[setting_name].priority
			if not settings_by_priority.has(priority):
				settings_by_priority[priority] = []
			settings_by_priority[priority].append(setting_name)
	
	var result: Array[String] = []
	
	# Sort by priority
	var priorities: Array = settings_by_priority.keys()
	priorities.sort()
	
	for priority in priorities:
		result.append_array(settings_by_priority[priority])
	
	_cached_priority_list = result
	_priority_list_dirty = false
	return result

## Decrease quality of a specific setting
func decrease_setting_quality(setting_name: String) -> bool:
	if not available_settings.has(setting_name):
		push_warning("Smart Graphics Settings: Attempted to decrease non-existent setting: %s" % setting_name)
		return false
		
	if not is_setting_applicable(setting_name):
		push_warning("Smart Graphics Settings: Setting %s is not applicable to the current renderer" % setting_name)
		return false
		
	var setting: Setting = available_settings[setting_name]
	if setting.current_index > 0:
		setting.current_index -= 1
		apply_setting(setting_name)
		return true
	return false

## Increase quality of a specific setting
func increase_setting_quality(setting_name: String) -> bool:
	if not available_settings.has(setting_name):
		push_warning("Smart Graphics Settings: Attempted to increase non-existent setting: %s" % setting_name)
		return false
		
	if not is_setting_applicable(setting_name):
		push_warning("Smart Graphics Settings: Setting %s is not applicable to the current renderer" % setting_name)
		return false
		
	var setting: Setting = available_settings[setting_name]
	if setting.current_index < setting.values.size() - 1:
		setting.current_index += 1
		apply_setting(setting_name)
		return true
	return false

func register_setting(setting_name: String, values: Array[Variant], 
	  current_index: int, priority: SettingPriority, 
	  type: SettingType) -> void:
	available_settings[setting_name] = Setting.new(values, current_index, priority, type)
	_priority_list_dirty = true

## Apply the current setting value to the game
func apply_setting(setting_name: String) -> void:
	# Check if this setting exists
	if not available_settings.has(setting_name):
		push_warning("Smart Graphics Settings: Attempted to apply non-existent setting: %s" % setting_name)
		return
		
	# Check if this setting is applicable to the current renderer
	if not is_setting_applicable(setting_name):
		push_warning("Smart Graphics Settings: Setting %s is not applicable to the current renderer: %s" % [setting_name, RendererType.keys()[current_renderer]])
		return
		
	var setting: Setting = available_settings[setting_name]
	var value = setting.values[setting.current_index]
	
	# Apply the setting based on the setting type and name
	match setting.type:
		SettingType.VIEWPORT:
			if not viewport:
				push_warning("Smart Graphics Settings: Cannot apply viewport setting %s - no viewport found" % setting_name)
				return
				
			match setting_name:
				"msaa":
					# In Godot 4.4, we need to use different approaches for Window vs Viewport
					if viewport is Window:
						# For the main viewport (Window), we need to use the viewport's own methods
						var vp: Viewport = get_viewport()
						if vp:
							vp.msaa_3d = value
					else:
						viewport.msaa = value
				"shadow_quality":
					if viewport is Window:
						# For the main viewport (Window)
						var vp: Viewport = get_viewport()
						if vp:
							# Get the viewport RID
							var viewport_rid: RID = vp.get_viewport_rid()
							# Set the shadow atlas quadrant subdivision
							RenderingServer.viewport_set_positional_shadow_atlas_quadrant_subdivision(viewport_rid, 0, value)
					else:
						viewport.shadow_atlas_quad_0 = value
				"shadow_size":
					if viewport is Window:
						# For the main viewport (Window)
						var vp: Viewport = get_viewport()
						if vp:
							# Get the viewport RID
							var viewport_rid: RID = vp.get_viewport_rid()
							RenderingServer.viewport_set_positional_shadow_atlas_size(viewport_rid, value)
					else:
						viewport.shadow_atlas_size = value
				"fxaa":
					if viewport is Window:
						# For the main viewport (Window)
						var vp: Viewport = get_viewport()
						if vp:
							vp.screen_space_aa = value
					else:
						viewport.screen_space_aa = value
				"ssao":
					if viewport is Window:
						# For the main viewport (Window)
						if get_viewport() and get_viewport().get_world_3d() and get_viewport().get_world_3d().environment:
							get_viewport().get_world_3d().environment.ssao_enabled = value
					else:
						viewport.ssao_enabled = value
				"ssao_quality":
					# In Godot 4.4, SSAO quality is controlled via ProjectSettings
					ProjectSettings.set_setting("rendering/environment/ssao/quality", value)
				"ssr":
					if viewport is Window:
						# For the main viewport (Window)
						if get_viewport() and get_viewport().get_world_3d() and get_viewport().get_world_3d().environment:
							get_viewport().get_world_3d().environment.ssr_enabled = value
					else:
						viewport.ssr_enabled = value
				"ssr_max_steps":
					if viewport is Window:
						# For the main viewport (Window)
						if get_viewport() and get_viewport().get_world_3d() and get_viewport().get_world_3d().environment:
							get_viewport().get_world_3d().environment.ssr_max_steps = value
					else:
						viewport.ssr_max_steps = value
				"sdfgi":
					if viewport is Window:
						# For the main viewport (Window)
						if get_viewport() and get_viewport().get_world_3d() and get_viewport().get_world_3d().environment:
							get_viewport().get_world_3d().environment.sdfgi_enabled = value
					else:
						viewport.sdfgi_enabled = value
				"glow":
					if viewport is Window:
						# For the main viewport (Window)
						if get_viewport() and get_viewport().get_world_3d() and get_viewport().get_world_3d().environment:
							get_viewport().get_world_3d().environment.glow_enabled = value
					else:
						viewport.glow_enabled = value
		
		SettingType.ENVIRONMENT:
			if not environment:
				# Try to get the environment from the world if not directly set
				if viewport and viewport.get_world_3d() and viewport.get_world_3d().environment:
					environment = viewport.get_world_3d().environment
				else:
					push_warning("Smart Graphics Settings: Cannot apply environment setting %s - no environment found" % setting_name)
					return
				
			match setting_name:
				"volumetric_fog":
					environment.volumetric_fog_enabled = value
				"volumetric_fog_density":
					environment.volumetric_fog_density = value
		
		SettingType.CAMERA:
			if not camera:
				push_warning("Smart Graphics Settings: Cannot apply camera setting %s - no camera found" % setting_name)
				return
				
			match setting_name:
				"dof":
					if camera.attributes:
						camera.attributes.dof_blur_far_enabled = value
					else:
						push_warning("Smart Graphics Settings: Camera has no attributes resource assigned. Cannot set DOF settings.")
		
		SettingType.RENDER_SCALE:
			if setting_name == "render_scale":
				var scale_factor: float = value
				
				if viewport is Window:
					# For the main viewport (Window)
					var vp: Viewport = get_viewport()
					if not vp:
						push_warning("Smart Graphics Settings: Cannot apply render scale - no viewport found")
						return
					
					# Set the scaling mode
					if scale_factor < 1.0:
						if fsr_available:
							vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
						else:
							vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
						vp.scaling_3d_scale = scale_factor
					else:
						vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
						vp.scaling_3d_scale = 1.0
				else:
					# For other viewports
					viewport.size = Vector2i(original_window_size.x * scale_factor, original_window_size.y * scale_factor)
					if scale_factor < 1.0:
						if fsr_available:
							viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
						else:
							viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
						viewport.scaling_3d_scale = scale_factor
					else:
						viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
						viewport.scaling_3d_scale = 1.0
	
	print("Smart Graphics Settings: Applied setting: ", setting_name, " = ", value)

## Save current graphics settings to user://graphics_settings.cfg
func save_graphics_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	
	# Save renderer type
	config.set_value("system", "renderer", current_renderer)
	
	# Save platform info for debugging
	config.set_value("system", "platform", OS.get_name())
	
	for setting_name in available_settings:
		var setting: Setting = available_settings[setting_name]
		config.set_value("graphics", setting_name, setting.current_index)
	
	var err: Error = config.save("user://graphics_settings.cfg")
	if err != OK:
		push_error("Smart Graphics Settings: Error saving graphics settings: %s" % error_string(err))

## Load graphics settings from user://graphics_settings.cfg
func load_graphics_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load("user://graphics_settings.cfg")
	
	if err != OK:
		push_warning("Smart Graphics Settings: No saved settings found or error loading settings: %s" % error_string(err))
		return
	
	# Check if settings were saved with a different renderer
	if config.has_section_key("system", "renderer"):
		var saved_renderer: int = config.get_value("system", "renderer")
		if saved_renderer != current_renderer:
			push_warning("Smart Graphics Settings: Saved settings were for a different renderer. Some settings may not apply.")
	
	for setting_name in available_settings:
		if config.has_section_key("graphics", setting_name):
			var index: int = config.get_value("graphics", setting_name)
			
			# Validate index is within bounds
			if index >= 0 and index < available_settings[setting_name].values.size():
				available_settings[setting_name].current_index = index
				
				# Only apply if the setting is applicable to the current renderer
				if is_setting_applicable(setting_name):
					apply_setting(setting_name)
			else:
				push_warning("Smart Graphics Settings: Invalid index %d for setting %s" % [index, setting_name])
