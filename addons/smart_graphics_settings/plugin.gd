@tool
extends EditorPlugin

func _enter_tree() -> void:
	# Register the addon
	add_autoload_singleton("SmartGraphicsSettings", "res://addons/smart_graphics_settings/smart_graphics_settings.gd")
	
	# Register custom types with the icon
	var icon: Texture2D = preload("res://addons/smart_graphics_settings/smart-graphics-settings-icon.svg")
	
	# Register custom classes with the icon
	add_custom_type("AdaptiveGraphics", "Node", preload("res://addons/smart_graphics_settings/adaptive_graphics.gd"), icon)
	add_custom_type("FPSMonitor", "Node", preload("res://addons/smart_graphics_settings/fps_monitor.gd"), icon)
	add_custom_type("GraphicsSettingsManager", "Node", preload("res://addons/smart_graphics_settings/graphics_settings_manager.gd"), icon)
	add_custom_type("AdaptiveGraphicsUI", "Control", preload("res://addons/smart_graphics_settings/adaptive_graphics_ui.gd"), icon)

func _exit_tree() -> void:
	# Clean up when the plugin is disabled
	remove_autoload_singleton("SmartGraphicsSettings")
	
	# Remove custom types
	remove_custom_type("AdaptiveGraphics")
	remove_custom_type("FPSMonitor")
	remove_custom_type("GraphicsSettingsManager")
	remove_custom_type("AdaptiveGraphicsUI")