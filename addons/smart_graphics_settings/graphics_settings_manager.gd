@tool
@icon("res://addons/smart_graphics_settings/smart-graphics-settings-icon.svg")
class_name GraphicsSettingsManager
extends Node

## Enum for setting priority (determines adjustment order)
enum SettingPriority {
	LOWEST, # Minimal visual impact, adjust first
	LOW,
	MEDIUM,
	HIGH,
	HIGHEST # Major visual impact, adjust last
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
	COMPATIBILITY
}

## Current renderer being used
var current_renderer: RendererType = RendererType.FORWARD_PLUS

## Define setting structure with strong typing
class Setting:
	var values: Array
	var current_index: int
	var priority: SettingPriority
	var type: SettingType
	
	func _init(p_values: Array, p_current_index: int, p_priority: SettingPriority, p_type: SettingType) -> void:
		values = p_values
		current_index = p_current_index
		priority = p_priority
		type = p_type

## Dictionary of available settings
var available_settings: Dictionary = {}

## References to nodes
var viewport: Viewport
var environment: Environment
var camera: Camera3D
var original_window_size: Vector2i

func _init() -> void:
	# Initialize common settings with strong typing
	available_settings = {
		# Render Scale (highest performance impact, lowest visual degradation)
		"render_scale": Setting.new(
			[0.5, 0.6, 0.7, 0.8, 0.9, 1.0],
			5, # Start with highest quality
			SettingPriority.LOWEST,
			SettingType.RENDER_SCALE
		),
		
		# Common Viewport Settings for all renderers
		"msaa": Setting.new(
			[Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X, Viewport.MSAA_8X],
			3,
			SettingPriority.LOW,
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
			SettingPriority.MEDIUM,
			SettingType.VIEWPORT
		),
		"shadow_size": Setting.new(
			[1024, 2048, 4096, 8192],
			2,
			SettingPriority.MEDIUM,
			SettingType.VIEWPORT
		),
		"fxaa": Setting.new(
			[Viewport.SCREEN_SPACE_AA_DISABLED, Viewport.SCREEN_SPACE_AA_FXAA],
			1,
			SettingPriority.LOW,
			SettingType.VIEWPORT
		),
		
		# Camera Settings (common to all renderers)
		"dof": Setting.new(
			[false, true],
			1,
			SettingPriority.LOW,
			SettingType.CAMERA
		),
		"motion_blur": Setting.new(
			[false, true],
			1,
			SettingPriority.LOW,
			SettingType.CAMERA
		)
	}
	
	# Renderer-specific settings will be initialized in _ready()

func _ready() -> void:
	viewport = get_viewport()
	original_window_size = DisplayServer.window_get_size()
	
	# Detect current renderer
	detect_renderer()
	
	# Initialize renderer-specific settings
	initialize_renderer_specific_settings()
	
	# Find WorldEnvironment and Camera3D in the scene
	var world_env: WorldEnvironment = find_world_environment()
	if world_env:
		environment = world_env.environment
	
	camera = find_main_camera()

## Detect which renderer is currently being used
func detect_renderer() -> void:
	var rendering_method: String = ProjectSettings.get_setting("rendering/renderer/rendering_method")
	
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
			
	print("Detected renderer: ", RendererType.keys()[current_renderer])

## Initialize settings specific to the detected renderer
func initialize_renderer_specific_settings() -> void:
	match current_renderer:
		RendererType.FORWARD_PLUS:
			# Forward+ specific settings
			available_settings["ssao"] = Setting.new(
				[false, true],
				1,
				SettingPriority.MEDIUM,
				SettingType.VIEWPORT
			)
			available_settings["ssao_quality"] = Setting.new(
				[
					Viewport.SSAO_QUALITY_VERY_LOW,
					Viewport.SSAO_QUALITY_LOW,
					Viewport.SSAO_QUALITY_MEDIUM,
					Viewport.SSAO_QUALITY_HIGH,
					Viewport.SSAO_QUALITY_ULTRA
				],
				3,
				SettingPriority.MEDIUM,
				SettingType.VIEWPORT
			)
			available_settings["ssr"] = Setting.new(
				[false, true],
				1,
				SettingPriority.HIGH,
				SettingType.VIEWPORT
			)
			available_settings["ssr_max_steps"] = Setting.new(
				[8, 16, 32, 64],
				3,
				SettingPriority.HIGH,
				SettingType.VIEWPORT
			)
			available_settings["sdfgi"] = Setting.new(
				[false, true],
				1,
				SettingPriority.HIGHEST,
				SettingType.VIEWPORT
			)
			available_settings["glow"] = Setting.new(
				[false, true],
				1,
				SettingPriority.LOW,
				SettingType.VIEWPORT
			)
			
			# Environment Settings (Forward+ specific)
			available_settings["volumetric_fog"] = Setting.new(
				[false, true],
				1,
				SettingPriority.HIGH,
				SettingType.ENVIRONMENT
			)
			available_settings["volumetric_fog_density"] = Setting.new(
				[0.01, 0.02, 0.03, 0.05],
				3,
				SettingPriority.HIGH,
				SettingType.ENVIRONMENT
			)
			
		RendererType.MOBILE:
			# Mobile-specific settings
			# Mobile has more limited features
			available_settings["glow"] = Setting.new(
				[false, true],
				1,
				SettingPriority.LOW,
				SettingType.VIEWPORT
			)
			# Mobile-specific optimizations could be added here
			
		RendererType.COMPATIBILITY:
			# Compatibility-specific settings
			available_settings["glow"] = Setting.new(
				[false, true],
				1,
				SettingPriority.LOW,
				SettingType.VIEWPORT
			)
			# Some limited SSAO might be available in compatibility mode
			available_settings["ssao"] = Setting.new(
				[false, true],
				1,
				SettingPriority.MEDIUM,
				SettingType.VIEWPORT
			)
			# Compatibility-specific optimizations could be added here

## Find the WorldEnvironment node in the scene
func find_world_environment() -> WorldEnvironment:
	var root: Node = get_tree().root
	return find_node_of_type(root, "WorldEnvironment") as WorldEnvironment

## Find the main Camera3D in the scene
func find_main_camera() -> Camera3D:
	var root: Node = get_tree().root
	return find_node_of_type(root, "Camera3D") as Camera3D

## Helper function to find a node of a specific type
func find_node_of_type(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name:
		return node
	
	for child in node.get_children():
		var found: Node = find_node_of_type(child, type_name)
		if found:
			return found
	
	return null

## Check if a setting is applicable to the current renderer
func is_setting_applicable(setting_name: String) -> bool:
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
	
	return false

## Order settings by priority for adjustment
func get_settings_by_priority() -> Array[String]:
	var settings_by_priority: Dictionary = {
		SettingPriority.LOWEST: [],
		SettingPriority.LOW: [],
		SettingPriority.MEDIUM: [],
		SettingPriority.HIGH: [],
		SettingPriority.HIGHEST: []
	}
	
	# Only include settings applicable to the current renderer
	for setting_name in available_settings:
		if is_setting_applicable(setting_name):
			var priority: SettingPriority = available_settings[setting_name].priority
			settings_by_priority[priority].append(setting_name)
	
	var result: Array[String] = []
	for priority in range(SettingPriority.LOWEST, SettingPriority.HIGHEST + 1):
		result.append_array(settings_by_priority[priority])
	
	return result

## Decrease quality of a specific setting
func decrease_setting_quality(setting_name: String) -> bool:
	var setting: Setting = available_settings[setting_name]
	if setting.current_index > 0:
		setting.current_index -= 1
		apply_setting(setting_name)
		return true
	return false

## Increase quality of a specific setting
func increase_setting_quality(setting_name: String) -> bool:
	var setting: Setting = available_settings[setting_name]
	if setting.current_index < setting.values.size() - 1:
		setting.current_index += 1
		apply_setting(setting_name)
		return true
	return false

## Apply the current setting value to the game
func apply_setting(setting_name: String) -> void:
	# Check if this setting exists
	if not available_settings.has(setting_name):
		return
		
	# Check if this setting is applicable to the current renderer
	if not is_setting_applicable(setting_name):
		print("Setting ", setting_name, " is not applicable to the current renderer: ", RendererType.keys()[current_renderer])
		return
		
	var setting: Setting = available_settings[setting_name]
	var value = setting.values[setting.current_index]
	
	# Apply the setting based on the setting type and name
	match setting.type:
		SettingType.VIEWPORT:
			if not viewport:
				return
				
			match setting_name:
				"msaa":
					viewport.msaa = value
				"shadow_quality":
					viewport.shadow_atlas_quad_0 = value
				"shadow_size":
					viewport.shadow_atlas_size = value
				"fxaa":
					viewport.screen_space_aa = value
				"ssao":
					viewport.ssao_enabled = value
				"ssao_quality":
					viewport.ssao_quality = value
				"ssr":
					viewport.ssr_enabled = value
				"ssr_max_steps":
					viewport.ssr_max_steps = value
				"sdfgi":
					viewport.sdfgi_enabled = value
				"glow":
					viewport.glow_enabled = value
		
		SettingType.ENVIRONMENT:
			if not environment:
				return
				
			match setting_name:
				"volumetric_fog":
					environment.volumetric_fog_enabled = value
				"volumetric_fog_density":
					environment.volumetric_fog_density = value
		
		SettingType.CAMERA:
			if not camera:
				return
				
			match setting_name:
				"dof":
					camera.dof_blur_far_enabled = value
				"motion_blur":
					camera.motion_blur_enabled = value
		
		SettingType.RENDER_SCALE:
			if setting_name == "render_scale":
				var scale_factor: float = value
				viewport.size = Vector2i(original_window_size.x * scale_factor, original_window_size.y * scale_factor)
				if scale_factor < 1.0:
					viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
					viewport.scaling_3d_scale = scale_factor
				else:
					viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
					viewport.scaling_3d_scale = 1.0
	
	print("Applied setting: ", setting_name, " = ", value)

## Save current graphics settings to user://graphics_settings.cfg
func save_graphics_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	
	for setting_name in available_settings:
		var setting: Setting = available_settings[setting_name]
		config.set_value("graphics", setting_name, setting.current_index)
	
	var err: Error = config.save("user://graphics_settings.cfg")
	if err != OK:
		print("Error saving graphics settings: ", err)

## Load graphics settings from user://graphics_settings.cfg
func load_graphics_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load("user://graphics_settings.cfg")
	
	if err != OK:
		return
	
	for setting_name in available_settings:
		if config.has_section_key("graphics", setting_name):
			var index: int = config.get_value("graphics", setting_name)
			available_settings[setting_name].current_index = index
			apply_setting(setting_name)