@tool
extends EditorPlugin

func _enter_tree() -> void:
	# Register the addon
	add_autoload_singleton("SmartGraphicsSettings", "res://addons/smart_graphics_settings/smart_graphics_settings.gd")
	
	# Register custom types with the icon
	var icon_path: String = "res://addons/smart_graphics_settings/images/smart-graphics-settings-icon.svg"
	var icon: Texture2D
	
	if ResourceLoader.exists(icon_path):
		icon = load(icon_path)
	else:
		push_warning("Smart Graphics Settings: Icon not found at %s" % icon_path)
	
	# Register custom classes with the icon
	var adaptive_graphics_script: String = "res://addons/smart_graphics_settings/adaptive_graphics.gd"
	var fps_monitor_script: String = "res://addons/smart_graphics_settings/fps_monitor.gd"
	var graphics_settings_manager_script: String = "res://addons/smart_graphics_settings/graphics_settings_manager.gd"
	var adaptive_graphics_ui_script: String = "res://addons/smart_graphics_settings/adaptive_graphics_ui.gd"
	
	if ResourceLoader.exists(adaptive_graphics_script):
		add_custom_type("AdaptiveGraphics", "Node", load(adaptive_graphics_script), icon)
	else:
		push_error("Smart Graphics Settings: AdaptiveGraphics script not found at %s" % adaptive_graphics_script)
	
	if ResourceLoader.exists(fps_monitor_script):
		add_custom_type("FPSMonitor", "Node", load(fps_monitor_script), icon)
	else:
		push_error("Smart Graphics Settings: FPSMonitor script not found at %s" % fps_monitor_script)
	
	if ResourceLoader.exists(graphics_settings_manager_script):
		add_custom_type("GraphicsSettingsManager", "Node", load(graphics_settings_manager_script), icon)
	else:
		push_error("Smart Graphics Settings: GraphicsSettingsManager script not found at %s" % graphics_settings_manager_script)
	
	if ResourceLoader.exists(adaptive_graphics_ui_script):
		add_custom_type("AdaptiveGraphicsUI", "Control", load(adaptive_graphics_ui_script), icon)
	else:
		push_error("Smart Graphics Settings: AdaptiveGraphicsUI script not found at %s" % adaptive_graphics_ui_script)
	
	print("Smart Graphics Settings: Plugin initialized successfully")

func _exit_tree() -> void:
	# Clean up when the plugin is disabled
	remove_autoload_singleton("SmartGraphicsSettings")
	
	# Remove custom types
	remove_custom_type("AdaptiveGraphics")
	remove_custom_type("FPSMonitor")
	remove_custom_type("GraphicsSettingsManager")
	remove_custom_type("AdaptiveGraphicsUI")
	
	print("Smart Graphics Settings: Plugin cleaned up successfully")