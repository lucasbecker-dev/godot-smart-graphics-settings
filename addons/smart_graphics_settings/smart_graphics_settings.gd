@tool
@icon("res://addons/smart_graphics_settings/smart-graphics-settings-icon.svg")
extends Node

## The main AdaptiveGraphics controller
var adaptive_graphics: AdaptiveGraphics

## Whether the UI is currently visible
var ui_visible: bool = false

## The UI instance
var ui_instance: AdaptiveGraphicsUI

## UI scene resource
var ui_scene: PackedScene = preload("res://addons/smart_graphics_settings/adaptive_graphics_ui.tscn")

func _ready() -> void:
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
		add_child(adaptive_graphics)
		
		# Wait for the settings manager to be initialized
		await get_tree().process_frame
		
		# Log the detected renderer
		if adaptive_graphics.settings_manager:
			var renderer_type: GraphicsSettingsManager.RendererType = adaptive_graphics.settings_manager.current_renderer
			var renderer_name: String = GraphicsSettingsManager.RendererType.keys()[renderer_type]
			print("Smart Graphics Settings: Detected renderer - ", renderer_name)
	else:
		push_error("AdaptiveGraphics class not found. Make sure the addon is properly installed.")

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
		ui_instance = ui_scene.instantiate() as AdaptiveGraphicsUI
		ui_instance.adaptive_graphics_path = adaptive_graphics.get_path()
		get_tree().root.add_child(ui_instance)
	
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
