@tool
@icon("res://addons/smart_graphics_settings/smart-graphics-settings-icon.svg")
class_name AdaptiveGraphicsUI
extends Control

## Path to the AdaptiveGraphics node
@export var adaptive_graphics_path: NodePath = NodePath("")

## Reference to the AdaptiveGraphics node
var adaptive_graphics: AdaptiveGraphics

## UI Controls
@onready var target_fps_slider: HSlider = $CenterContainer/PanelContainer/MarginContainer/VBoxContent/TargetFPSContainer/TargetFPSSlider
@onready var target_fps_value: SpinBox = $CenterContainer/PanelContainer/MarginContainer/VBoxContent/TargetFPSContainer/TargetFPSValue
@onready var target_fps_reset: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContent/TargetFPSContainer/ResetButton
@onready var enabled_checkbox: CheckBox = $CenterContainer/PanelContainer/MarginContainer/VBoxContent/EnabledCheckbox
@onready var allow_increase_checkbox: CheckBox = $CenterContainer/PanelContainer/MarginContainer/VBoxContent/AllowIncreaseCheckbox
@onready var threading_checkbox: CheckBox = $CenterContainer/PanelContainer/MarginContainer/VBoxContent/ThreadingCheckbox
@onready var match_refresh_rate_checkbox: CheckBox = $CenterContainer/PanelContainer/MarginContainer/VBoxContent/MatchRefreshRateCheckbox
@onready var vsync_option: OptionButton = $CenterContainer/PanelContainer/MarginContainer/VBoxContent/VSyncOption
@onready var preset_option: OptionButton = $CenterContainer/PanelContainer/MarginContainer/VBoxContent/PresetOption
@onready var fps_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContent/FPSLabel
@onready var status_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContent/StatusLabel
@onready var renderer_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContent/RendererLabel

## Default target FPS value
var default_target_fps: int = 60

## Timer for updating FPS display
var update_timer: Timer

## Current quality preset (for UI feedback)
var current_preset: String = "Custom"

## Current settings state (for detecting changes)
var current_settings: Dictionary = {}

func _ready() -> void:
	# If adaptive_graphics is already set directly, use it
	if adaptive_graphics:
		# Already set directly, no need to look up
		pass
	# Otherwise, try to get the AdaptiveGraphics node from the path
	elif not adaptive_graphics_path.is_empty():
		adaptive_graphics = get_node_or_null(adaptive_graphics_path)
	
	# If we couldn't get it from the path, try to find it through the singleton
	if not adaptive_graphics and has_node("/root/SmartGraphicsSettings"):
		var smart_settings = get_node("/root/SmartGraphicsSettings")
		if smart_settings and smart_settings.has_method("get_adaptive_graphics"):
			adaptive_graphics = smart_settings.get_adaptive_graphics()
	
	if not adaptive_graphics:
		push_error("AdaptiveGraphicsUI: Failed to find AdaptiveGraphics node at path: " + str(adaptive_graphics_path))
		return
	
	# Connect to the settings_changed signal
	if not adaptive_graphics.changed_settings.is_connected(_on_changed_settings):
		adaptive_graphics.changed_settings.connect(_on_changed_settings)
	
	# Store default target FPS
	default_target_fps = adaptive_graphics.target_fps
	
	# Initialize UI with current values
	target_fps_slider.value = adaptive_graphics.target_fps
	target_fps_value.value = adaptive_graphics.target_fps
	enabled_checkbox.button_pressed = adaptive_graphics.enabled
	allow_increase_checkbox.button_pressed = adaptive_graphics.allow_quality_increase
	
	# Setup threading checkbox
	threading_checkbox.button_pressed = adaptive_graphics.use_threading
	threading_checkbox.disabled = not adaptive_graphics.threading_supported
	if not adaptive_graphics.threading_supported:
		var platform_name: String = OS.get_name()
		threading_checkbox.tooltip_text = "Threading not supported on this platform (%s)" % platform_name
		
		# Add a small warning icon next to the checkbox if threading is not supported
		var warning_icon = TextureRect.new()
		warning_icon.texture = get_theme_icon("NodeWarning", "EditorIcons")
		warning_icon.tooltip_text = "Threading is not available on %s or has been disabled due to platform limitations. The extension will use single-threaded mode instead." % platform_name
		warning_icon.custom_minimum_size = Vector2(16, 16)
		warning_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Add the warning icon as a sibling to the checkbox
		var parent = threading_checkbox.get_parent()
		parent.add_child(warning_icon)
		parent.move_child(warning_icon, threading_checkbox.get_index() + 1)
	else:
		# Add processor count information to the tooltip
		var processor_count = OS.get_processor_count()
		threading_checkbox.tooltip_text = "Enable multi-threaded processing (%d processors available)" % processor_count
	
	# Setup match refresh rate checkbox
	if match_refresh_rate_checkbox:
		match_refresh_rate_checkbox.button_pressed = adaptive_graphics.match_refresh_rate
		match_refresh_rate_checkbox.tooltip_text = "Set target FPS to match display refresh rate (%d Hz)" % int(adaptive_graphics.display_refresh_rate)
	
	# Apply simple theme to dropdowns for Godot 4.4
	_apply_simple_dropdown_theme()
	
	# Setup VSync dropdown - Simple approach for Godot 4.4
	if vsync_option:
		# Clear existing items
		vsync_option.clear()
		
		# Add VSync options
		vsync_option.add_item("Disabled", 0)
		vsync_option.add_item("Enabled", 1)
		vsync_option.add_item("Adaptive", 2)
		vsync_option.add_item("Mailbox", 3)
		
		# Select the current VSync mode
		adaptive_graphics.update_vsync_and_refresh_rate()
		vsync_option.select(adaptive_graphics.current_vsync_mode)
		
		# Update tooltip with current refresh rate
		vsync_option.tooltip_text = "Control vertical synchronization with the display (Refresh rate: %d Hz)" % int(adaptive_graphics.display_refresh_rate)
	
	# Setup preset dropdown - Simple approach for Godot 4.4
	preset_option.clear()
	preset_option.add_item("Ultra Low", AdaptiveGraphics.QualityPreset.ULTRA_LOW)
	preset_option.add_item("Low", AdaptiveGraphics.QualityPreset.LOW)
	preset_option.add_item("Medium", AdaptiveGraphics.QualityPreset.MEDIUM)
	preset_option.add_item("High", AdaptiveGraphics.QualityPreset.HIGH)
	preset_option.add_item("Ultra", AdaptiveGraphics.QualityPreset.ULTRA)
	preset_option.add_item("Custom", -1)
	
	# Store current settings for change detection
	_store_current_settings()
	
	# Detect and select the current preset
	current_preset = _detect_preset_from_settings()
	
	# Select the appropriate preset in the dropdown
	if current_preset == "Custom":
		# Select the "Custom" option (last item)
		preset_option.select(preset_option.item_count - 1)
	else:
		# Find the preset by name and select it
		var preset_index: int = AdaptiveGraphics.QualityPreset.get(current_preset, -1)
		if preset_index >= 0:
			for i in range(preset_option.item_count):
				if preset_option.get_item_id(i) == preset_index:
					preset_option.select(i)
					break
	
	# Create timer for updating UI
	update_timer = Timer.new()
	update_timer.wait_time = 0.5
	update_timer.timeout.connect(_on_update_timer_timeout)
	update_timer.autostart = true
	add_child(update_timer)
	
	# Update UI immediately
	_update_ui()

func _store_current_settings() -> void:
	if not adaptive_graphics or not adaptive_graphics.settings_manager:
		return
		
	current_settings.clear()
	
	for setting_name in adaptive_graphics.settings_manager.available_settings:
		if adaptive_graphics.settings_manager.is_setting_applicable(setting_name):
			var setting = adaptive_graphics.settings_manager.available_settings[setting_name]
			current_settings[setting_name] = setting.current_index

func _detect_preset_from_settings() -> String:
	if not adaptive_graphics:
		return "Custom"
		
	# Check if current settings match any preset
	for preset_name in AdaptiveGraphics.QualityPreset.keys():
		var preset_index = AdaptiveGraphics.QualityPreset[preset_name]
		if _settings_match_preset(preset_index):
			return preset_name
			
	return "Custom"

func _settings_match_preset(preset_index: int) -> bool:
	if not adaptive_graphics or not adaptive_graphics.settings_manager:
		return false
		
	if not adaptive_graphics.presets.has(preset_index):
		return false
		
	var preset_settings = adaptive_graphics.get_preset_for_current_renderer(preset_index)
	
	for setting_name in preset_settings:
		if not adaptive_graphics.settings_manager.available_settings.has(setting_name):
			continue
			
		if not adaptive_graphics.settings_manager.is_setting_applicable(setting_name):
			continue
			
		var current_index = adaptive_graphics.settings_manager.available_settings[setting_name].current_index
		if current_index != preset_settings[setting_name]:
			return false
			
	return true

func _apply_simple_dropdown_theme() -> void:
	# Simple theme adjustments for Godot 4.4
	if vsync_option:
		vsync_option.custom_minimum_size.y = 30
	
	if preset_option:
		preset_option.custom_minimum_size.y = 30

func _on_update_timer_timeout() -> void:
	_update_ui()

func _update_ui() -> void:
	if not adaptive_graphics:
		return
	
	# Update FPS display
	if fps_label:
		# Make sure the FPS monitor exists
		if adaptive_graphics.fps_monitor:
			var avg_fps: float = adaptive_graphics.fps_monitor.get_average_fps()
			var is_stable: bool = adaptive_graphics.fps_monitor.is_fps_stable()
			var stability_text: String = "stable" if is_stable else "unstable"
			
			# Ensure we're not showing 0 FPS
			if avg_fps < 0.1:
				avg_fps = Engine.get_frames_per_second()
			
			fps_label.text = "FPS: %.1f (%s)" % [avg_fps, stability_text]
			
			# Color code based on performance
			var target_fps: int = adaptive_graphics.target_fps
			var tolerance: int = adaptive_graphics.fps_tolerance
			
			if avg_fps >= target_fps - tolerance:
				fps_label.modulate = Color(0.2, 1.0, 0.2) # Green for good performance
			elif avg_fps >= target_fps - tolerance * 2:
				fps_label.modulate = Color(1.0, 1.0, 0.2) # Yellow for borderline performance
			else:
				fps_label.modulate = Color(1.0, 0.2, 0.2) # Red for poor performance
		else:
			# Fallback if FPS monitor doesn't exist
			var current_fps: float = Engine.get_frames_per_second()
			fps_label.text = "FPS: %.1f (unknown)" % current_fps
			fps_label.modulate = Color(1.0, 1.0, 1.0) # White for unknown status
	
	# Update status display
	if status_label:
		# Get the current action directly from adaptive_graphics
		var current_action: String = adaptive_graphics.current_action
		
		# Get other status information
		var renderer_type: GraphicsSettingsManager.RendererType = adaptive_graphics.settings_manager.current_renderer
		var renderer_name: String = GraphicsSettingsManager.RendererType.keys()[renderer_type]
		
		var vsync_mode: int = adaptive_graphics.current_vsync_mode
		var vsync_modes: Array[String] = ["Disabled", "Enabled", "Adaptive", "Mailbox"]
		
		var threading_info: Dictionary = adaptive_graphics.get_threading_support_info()
		var threading_active: bool = threading_info.thread_active
		
		# Build the status text
		var status_text: String = "Status: %s\n" % current_action
		status_text += "Threading: %s" % ("Active" if threading_active else "Inactive")
		
		status_label.text = status_text
	
	# Update renderer display
	if renderer_label and adaptive_graphics.settings_manager:
		var renderer_type = adaptive_graphics.settings_manager.current_renderer
		var renderer_name = GraphicsSettingsManager.RendererType.keys()[renderer_type]
		renderer_label.text = "Renderer: " + renderer_name
		
		# Add FSR info if available
		if adaptive_graphics.settings_manager.fsr_available:
			renderer_label.text += " (FSR supported)"
	
	# Check if settings have changed and update the preset dropdown
	if _have_settings_changed():
		# Store the new settings
		_store_current_settings()
		
		# Detect which preset matches the current settings
		var detected_preset: String = _detect_preset_from_settings()
		
		# Update the preset dropdown
		if detected_preset != current_preset:
			current_preset = detected_preset
			
			# Find and select the matching preset in the dropdown
			if detected_preset == "Custom":
				# Select the "Custom" option (last item)
				preset_option.select(preset_option.item_count - 1)
			else:
				# Find the preset by name and select it
				var preset_index: int = AdaptiveGraphics.QualityPreset.get(detected_preset, -1)
				if preset_index >= 0:
					for i in range(preset_option.item_count):
						if preset_option.get_item_id(i) == preset_index:
							preset_option.select(i)
							break

func _have_settings_changed() -> bool:
	if not adaptive_graphics or not adaptive_graphics.settings_manager:
		return false
		
	for setting_name in adaptive_graphics.settings_manager.available_settings:
		if adaptive_graphics.settings_manager.is_setting_applicable(setting_name):
			var setting = adaptive_graphics.settings_manager.available_settings[setting_name]
			
			if not current_settings.has(setting_name) or current_settings[setting_name] != setting.current_index:
				return true
				
	return false

func _on_target_fps_slider_value_changed(value: float) -> void:
	if adaptive_graphics:
		adaptive_graphics.target_fps = int(value)
		target_fps_value.value = value

func _on_target_fps_value_changed(value: float) -> void:
	if adaptive_graphics:
		adaptive_graphics.target_fps = int(value)
		target_fps_slider.value = value

func _on_reset_button_pressed() -> void:
	if adaptive_graphics:
		adaptive_graphics.target_fps = default_target_fps
		target_fps_slider.value = default_target_fps
		target_fps_value.value = default_target_fps

func _on_enabled_checkbox_toggled(button_pressed: bool) -> void:
	if adaptive_graphics:
		adaptive_graphics.enabled = button_pressed

func _on_allow_increase_checkbox_toggled(button_pressed: bool) -> void:
	if adaptive_graphics:
		adaptive_graphics.allow_quality_increase = button_pressed

func _on_threading_checkbox_toggled(button_pressed: bool) -> void:
	if adaptive_graphics:
		adaptive_graphics.set_threading_enabled(button_pressed)

func _on_match_refresh_rate_checkbox_toggled(button_pressed: bool) -> void:
	if adaptive_graphics:
		adaptive_graphics.match_refresh_rate = button_pressed
		if button_pressed:
			adaptive_graphics.set_target_fps_to_refresh_rate()
			target_fps_slider.value = adaptive_graphics.target_fps
			target_fps_value.value = adaptive_graphics.target_fps

func _on_vsync_option_item_selected(index: int) -> void:
	if adaptive_graphics:
		adaptive_graphics.set_vsync_mode(index)

func _on_preset_option_item_selected(index: int) -> void:
	var preset_id = preset_option.get_item_id(index)
	
	if preset_id >= 0 and adaptive_graphics:
		adaptive_graphics.apply_preset(preset_id)
		current_preset = AdaptiveGraphics.QualityPreset.keys()[preset_id]
		_store_current_settings()
	
	# Update UI immediately
	_update_ui()

func _on_changed_settings() -> void:
	# Update the UI when settings are changed from any source
	_update_ui()
