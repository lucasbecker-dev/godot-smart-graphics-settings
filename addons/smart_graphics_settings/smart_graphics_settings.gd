@tool
@icon("res://addons/smart_graphics_settings/images/smart-graphics-settings-icon.svg")
extends Node

## Signal emitted when the AdaptiveGraphics node has been initialized.
## Connect to this signal to safely access adaptive_graphics after startup.
signal initialized

## The main AdaptiveGraphics controller
var adaptive_graphics: AdaptiveGraphics

## Whether the UI is currently visible
var ui_visible: bool = false

## The UI instance
var ui_instance: AdaptiveGraphicsUI

## UI scene resource
var ui_scene: PackedScene = preload("res://addons/smart_graphics_settings/adaptive_graphics_ui.tscn")

## Platform information for optimizations
var platform_info: Dictionary = {}

func _ready() -> void:
	# Gather platform information
	platform_info = {
		"os_name": OS.get_name(),
		"model_name": OS.get_model_name(),
		"processor_name": OS.get_processor_name(),
		"processor_count": OS.get_processor_count()
	}
	
	# Only initialize adaptive graphics when running the game, not in the editor
	if not Engine.is_editor_hint():
		# Create the adaptive graphics controller using a deferred call
		# This ensures classes are registered before we try to use them
		call_deferred("_initialize_adaptive_graphics")
		
		# Register input action for toggling UI
		if not InputMap.has_action("toggle_graphics_settings"):
			InputMap.add_action("toggle_graphics_settings")
			var event: InputEventKey = InputEventKey.new()
			event.keycode = KEY_F7
			InputMap.action_add_event("toggle_graphics_settings", event)

func _initialize_adaptive_graphics() -> void:
	# Try to create the adaptive graphics controller
	if ClassDB.class_exists("AdaptiveGraphics") or Engine.has_singleton("AdaptiveGraphics") or ResourceLoader.exists("res://addons/smart_graphics_settings/adaptive_graphics.gd"):
		adaptive_graphics = AdaptiveGraphics.new()
		
		# Check if creation was successful before proceeding
		if adaptive_graphics:
			add_child(adaptive_graphics)
			# Emit the signal AFTER initialization is complete
			initialized.emit()
			
			# Wait for the settings manager to be initialized
			await get_tree().process_frame
			
			# Log the detected renderer
			if adaptive_graphics.settings_manager:
				var renderer_type: GraphicsSettingsManager.RendererType = adaptive_graphics.settings_manager.current_renderer
				var renderer_name: String = GraphicsSettingsManager.RendererType.keys()[renderer_type]
				print("Smart Graphics Settings: Detected renderer - ", renderer_name)
		else:
			push_error("Smart Graphics Settings: Failed to instantiate AdaptiveGraphics.")
	else:
		push_error("Smart Graphics Settings: AdaptiveGraphics class not found. Make sure the addon is properly installed.")

func _input(event: InputEvent) -> void:
	# Only process input when running the game, not in the editor
	if Engine.is_editor_hint():
		return
		
	# Only check for the action if it exists
	if InputMap.has_action("toggle_graphics_settings") and event.is_action_pressed("toggle_graphics_settings"):
		toggle_ui()

## Toggle the graphics settings UI
func toggle_ui() -> void:
	if ui_visible:
		hide_ui()
	else:
		show_ui()

## Show the graphics settings UI
func show_ui() -> void:
	if ui_instance:
		ui_instance.show()
	else:
		if not ui_scene:
			push_error("Smart Graphics Settings: UI scene not found")
			return
			
		ui_instance = ui_scene.instantiate() as AdaptiveGraphicsUI
		if not ui_instance:
			push_error("Smart Graphics Settings: Failed to instantiate UI")
			return
			
		if not adaptive_graphics:
			push_error("Smart Graphics Settings: AdaptiveGraphics not initialized")
			return
		
		var root: Viewport = get_tree().root
		if not root:
			push_error("Smart Graphics Settings: Failed to get scene root")
			return
			
		root.add_child(ui_instance)
	
	ui_visible = true

## Hide the graphics settings UI
func hide_ui() -> void:
	if ui_instance:
		ui_instance.hide()
	
	ui_visible = false

## Apply a quality preset
func apply_preset(preset: AdaptiveGraphics.QualityPreset) -> void:
	if adaptive_graphics:
		adaptive_graphics.apply_preset(preset)

## Enable or disable adaptive graphics
func set_enabled(enabled: bool) -> void:
	if adaptive_graphics:
		adaptive_graphics.enabled = enabled

## Set the target FPS
func set_target_fps(fps: int) -> void:
	if adaptive_graphics:
		adaptive_graphics.target_fps = fps

## Get the current average FPS
func get_average_fps() -> float:
	if adaptive_graphics and adaptive_graphics.fps_monitor:
		return adaptive_graphics.fps_monitor.get_average_fps()
	return 0.0

## Check if FPS is stable
func is_fps_stable() -> bool:
	if adaptive_graphics and adaptive_graphics.fps_monitor:
		return adaptive_graphics.fps_monitor.is_fps_stable()
	return false

## Set whether to match the target FPS to the display refresh rate
func set_match_refresh_rate(enabled: bool) -> void:
	if adaptive_graphics:
		adaptive_graphics.match_refresh_rate = enabled
		if enabled:
			adaptive_graphics.set_target_fps_to_refresh_rate()

## Set the target FPS to match the display refresh rate
func set_target_fps_to_refresh_rate() -> void:
	if adaptive_graphics:
		adaptive_graphics.set_target_fps_to_refresh_rate()

## Get the display refresh rate
func get_display_refresh_rate() -> float:
	if adaptive_graphics:
		adaptive_graphics.update_vsync_and_refresh_rate()
		return adaptive_graphics.display_refresh_rate
	return 60.0

## Set the VSync mode
func set_vsync_mode(mode: int) -> void:
	if adaptive_graphics:
		adaptive_graphics.set_vsync_mode(mode)

## Get the current VSync mode
func get_vsync_mode() -> int:
	if adaptive_graphics:
		adaptive_graphics.update_vsync_and_refresh_rate()
		return adaptive_graphics.current_vsync_mode
	return DisplayServer.VSYNC_ENABLED # Default fallback

## Get detailed information about the current state
func get_status_info() -> Dictionary:
	var info: Dictionary = {
		"enabled": false,
		"target_fps": 60,
		"current_fps": 0.0,
		"fps_stable": false,
		"vsync_mode": DisplayServer.VSYNC_ENABLED,
		"refresh_rate": 60.0,
		"renderer": "Unknown",
		"current_action": "Not initialized",
		"threading": false,
		"platform": platform_info
	}
	
	if adaptive_graphics:
		info.enabled = adaptive_graphics.enabled
		info.target_fps = adaptive_graphics.target_fps
		info.current_fps = get_average_fps()
		info.fps_stable = is_fps_stable()
		info.vsync_mode = get_vsync_mode()
		info.refresh_rate = get_display_refresh_rate()
		info.current_action = adaptive_graphics.current_action
		info.threading = adaptive_graphics.use_threading
		
		if adaptive_graphics.settings_manager:
			var renderer_type: GraphicsSettingsManager.RendererType = adaptive_graphics.settings_manager.current_renderer
			info.renderer = GraphicsSettingsManager.RendererType.keys()[renderer_type]
	
	return info

## Get the adaptive graphics controller
func get_adaptive_graphics() -> AdaptiveGraphics:
	return adaptive_graphics
