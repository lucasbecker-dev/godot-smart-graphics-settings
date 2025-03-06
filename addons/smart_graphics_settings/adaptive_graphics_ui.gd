@tool
@icon("res://addons/smart_graphics_settings/smart-graphics-settings-icon.svg")
class_name AdaptiveGraphicsUI
extends Control

## Path to the AdaptiveGraphics node
@export var adaptive_graphics_path: NodePath

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

func _ready() -> void:
	adaptive_graphics = get_node(adaptive_graphics_path) as AdaptiveGraphics
	
	if not adaptive_graphics:
		push_error("AdaptiveGraphicsUI: Failed to find AdaptiveGraphics node at path: " + str(adaptive_graphics_path))
		return
	
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
		threading_checkbox.tooltip_text = "Threading not supported on this platform"
	
	# Setup match refresh rate checkbox
	if match_refresh_rate_checkbox:
		match_refresh_rate_checkbox.button_pressed = adaptive_graphics.match_refresh_rate
		match_refresh_rate_checkbox.tooltip_text = "Set target FPS to match display refresh rate (%d Hz)" % int(adaptive_graphics.display_refresh_rate)
	
	# Setup VSync dropdown
	if vsync_option:
		# Select the current VSync mode
		adaptive_graphics.update_vsync_and_refresh_rate()
		vsync_option.select(adaptive_graphics.current_vsync_mode)
		
		# Update tooltip with current refresh rate
		vsync_option.tooltip_text = "Control vertical synchronization with the display (Refresh rate: %d Hz)" % int(adaptive_graphics.display_refresh_rate)
	
	# Setup preset dropdown
	preset_option.clear()
	preset_option.add_item("Ultra Low", AdaptiveGraphics.QualityPreset.ULTRA_LOW)
	preset_option.add_item("Low", AdaptiveGraphics.QualityPreset.LOW)
	preset_option.add_item("Medium", AdaptiveGraphics.QualityPreset.MEDIUM)
	preset_option.add_item("High", AdaptiveGraphics.QualityPreset.HIGH)
	preset_option.add_item("Ultra", AdaptiveGraphics.QualityPreset.ULTRA)
	
	# Set the current preset in the dropdown
	update_preset_dropdown()
	
	# Update UI for current renderer
	update_ui_for_current_renderer()
	
	# Connect signals
	target_fps_slider.value_changed.connect(_on_target_fps_slider_changed)
	target_fps_value.value_changed.connect(_on_target_fps_value_changed)
	target_fps_reset.pressed.connect(_on_target_fps_reset_pressed)
	enabled_checkbox.toggled.connect(_on_enabled_toggled)
	allow_increase_checkbox.toggled.connect(_on_allow_increase_toggled)
	threading_checkbox.toggled.connect(_on_threading_toggled)
	if match_refresh_rate_checkbox:
		match_refresh_rate_checkbox.toggled.connect(_on_match_refresh_rate_toggled)
	if vsync_option:
		vsync_option.item_selected.connect(_on_vsync_option_selected)
	preset_option.item_selected.connect(_on_preset_selected)
	
	# Setup update timer
	update_timer = Timer.new()
	update_timer.wait_time = 0.5 # Update twice per second
	update_timer.timeout.connect(_on_update_timer_timeout)
	add_child(update_timer)
	update_timer.start()
	
	# Connect to window resize signal
	get_tree().root.size_changed.connect(_on_window_resized)
	
	# Ensure panel fits contents
	call_deferred("ensure_panel_fits_contents")
	
	# Ensure popups are properly configured after a short delay
	call_deferred("setup_popups")

## Update UI elements based on the current renderer
func update_ui_for_current_renderer() -> void:
	if not adaptive_graphics or not adaptive_graphics.settings_manager:
		return
		
	var renderer_type: GraphicsSettingsManager.RendererType = adaptive_graphics.settings_manager.current_renderer
	var renderer_name: String = GraphicsSettingsManager.RendererType.keys()[renderer_type]
	
	# Update renderer label
	var label_changed: bool = false
	var new_text: String = "Current Renderer: " + renderer_name
	if renderer_label and renderer_label.text != new_text:
		renderer_label.text = new_text
		label_changed = true
	
	# Hide settings UI elements that don't apply to the current renderer
	# This assumes UI elements are named after the settings they control
	for setting_name in adaptive_graphics.settings_manager.available_settings.keys():
		var ui_element = find_node_by_name(setting_name + "Control")
		if ui_element:
			ui_element.visible = adaptive_graphics.settings_manager.is_setting_applicable(setting_name)
	
	# Ensure panel resizes if renderer label was changed
	if label_changed:
		call_deferred("ensure_panel_fits_contents")

## Helper function to find a node by name
func find_node_by_name(node_name: String) -> Node:
	return find_child(node_name, true, false)

## Update the preset dropdown to match the current settings
func update_preset_dropdown() -> void:
	if not adaptive_graphics or not adaptive_graphics.settings_manager:
		return
		
	var current_preset: int = determine_current_preset()
	
	# Find the index in the dropdown that corresponds to this preset
	for i in range(preset_option.item_count):
		if preset_option.get_item_id(i) == current_preset:
			preset_option.select(i)
			break

## Determine which preset most closely matches the current settings
func determine_current_preset() -> int:
	if not adaptive_graphics or not adaptive_graphics.settings_manager:
		return AdaptiveGraphics.QualityPreset.MEDIUM # Default to medium
		
	var settings_manager = adaptive_graphics.settings_manager
	var best_match_preset: int = AdaptiveGraphics.QualityPreset.MEDIUM
	var best_match_score: int = 0
	
	# Check each preset against current settings
	for preset_type in adaptive_graphics.presets.keys():
		var preset: Dictionary = adaptive_graphics.get_preset_for_current_renderer(preset_type)
		var match_score: int = 0
		var total_settings: int = 0
		
		# Count how many settings match this preset
		for setting_name in preset:
			if settings_manager.available_settings.has(setting_name) and settings_manager.is_setting_applicable(setting_name):
				total_settings += 1
				if settings_manager.available_settings[setting_name].current_index == preset[setting_name]:
					match_score += 1
		
		# Calculate match percentage
		var match_percentage: float = 0.0
		if total_settings > 0:
			match_percentage = float(match_score) / float(total_settings)
		
		# Update best match if this preset is better
		if match_score > best_match_score:
			best_match_score = match_score
			best_match_preset = preset_type
	
	return best_match_preset

func _on_target_fps_slider_changed(value: float) -> void:
	var fps_value: int = int(value)
	adaptive_graphics.target_fps = fps_value
	target_fps_value.value = fps_value
	target_fps_slider.tooltip_text = "Target FPS: %d" % fps_value

func _on_target_fps_value_changed(value: float) -> void:
	var fps_value: int = int(value)
	adaptive_graphics.target_fps = fps_value
	target_fps_slider.value = fps_value
	target_fps_slider.tooltip_text = "Target FPS: %d" % fps_value

func _on_target_fps_reset_pressed() -> void:
	target_fps_slider.value = default_target_fps
	target_fps_value.value = default_target_fps
	adaptive_graphics.target_fps = default_target_fps

func _on_enabled_toggled(enabled: bool) -> void:
	adaptive_graphics.enabled = enabled

func _on_allow_increase_toggled(enabled: bool) -> void:
	adaptive_graphics.allow_quality_increase = enabled

func _on_threading_toggled(enabled: bool) -> void:
	adaptive_graphics.set_threading_enabled(enabled)

func _on_match_refresh_rate_toggled(enabled: bool) -> void:
	adaptive_graphics.match_refresh_rate = enabled
	if enabled:
		adaptive_graphics.set_target_fps_to_refresh_rate()
		target_fps_slider.value = adaptive_graphics.target_fps
		target_fps_value.value = adaptive_graphics.target_fps

func _on_vsync_option_selected(index: int) -> void:
	adaptive_graphics.set_vsync_mode(index)
	
	# Update the status to reflect the new VSync mode
	var vsync_mode_names: Array[String] = ["Disabled", "Enabled", "Adaptive", "Mailbox"]
	print("VSync mode changed to: ", vsync_mode_names[index])

func _on_preset_selected(index: int) -> void:
	var preset: int = preset_option.get_item_id(index)
	adaptive_graphics.apply_preset(preset)

func _on_update_timer_timeout() -> void:
	# Update FPS display
	if adaptive_graphics.fps_monitor:
		var avg_fps: float = adaptive_graphics.fps_monitor.get_average_fps()
		fps_label.text = "Current FPS: %.1f" % avg_fps
		
		# Get the effective target FPS considering VSync limitations
		var max_fps = adaptive_graphics.get_effective_max_fps()
		var effective_target = adaptive_graphics.target_fps
		if max_fps > 0 and adaptive_graphics.target_fps > max_fps:
			effective_target = max_fps
		
		# Update status
		var status: String = "Status: "
		if not adaptive_graphics.enabled:
			status += "Disabled"
		elif adaptive_graphics.is_measuring:
			status += "Measuring FPS..."
		elif adaptive_graphics.is_adjusting:
			status += "Adjusting Graphics Settings..."
		else:
			if avg_fps < effective_target - adaptive_graphics.fps_tolerance:
				status += "Performance below target"
			elif avg_fps > effective_target + adaptive_graphics.fps_tolerance:
				status += "Performance above target"
			else:
				status += "Performance on target"
		
		# Add VSync info if it's limiting the target FPS
		if max_fps > 0 and adaptive_graphics.target_fps > max_fps:
			status += " (VSync limiting to %.1f FPS)" % max_fps
		
		# Add current VSync mode
		var vsync_mode_names: Array[String] = ["Disabled", "Enabled", "Adaptive", "Mailbox"]
		var current_mode: int = adaptive_graphics.current_vsync_mode
		if current_mode >= 0 and current_mode < vsync_mode_names.size():
			status += " | VSync: " + vsync_mode_names[current_mode]
		
		# Update status text
		if status_label.text != status:
			status_label.text = status
			# Ensure panel resizes if status text changes
			call_deferred("ensure_panel_fits_contents")
		
		# Update preset dropdown to match current settings
		# Only update occasionally to avoid constant changes
		if Engine.get_frames_drawn() % 30 == 0:
			update_preset_dropdown()

## Handle window resize to ensure popups stay within bounds
func _on_window_resized() -> void:
	# Update popup sizes
	if vsync_option:
		var popup: PopupMenu = vsync_option.get_popup()
		popup.size = Vector2i(vsync_option.size.x, 0)
		
		# Reset position to be recalculated by Godot
		# This is important to ensure the popup appears in the right place
		popup.position = Vector2i(0, 0)
	
	if preset_option:
		var preset_popup: PopupMenu = preset_option.get_popup()
		preset_popup.size = Vector2i(preset_option.size.x, 0)
		
		# Reset position to be recalculated by Godot
		# This is important to ensure the popup appears in the right place
		preset_popup.position = Vector2i(0, 0)
		
	# Ensure the panel container properly fits its contents
	$CenterContainer/PanelContainer.custom_minimum_size.x = 500
	$CenterContainer/PanelContainer.size.y = 0 # Reset height to allow proper resizing

## Ensure the panel properly fits its contents
func ensure_panel_fits_contents() -> void:
	# Wait one frame to ensure all UI elements have been properly sized
	await get_tree().process_frame
	
	# Reset the panel's height to allow it to resize based on content
	$CenterContainer/PanelContainer.size.y = 0
	
	# Ensure the panel has a minimum width
	$CenterContainer/PanelContainer.custom_minimum_size.x = 500

## Setup popups to ensure they're visible
func setup_popups() -> void:
	# Wait for UI to be fully initialized
	await get_tree().process_frame
	
	# Create a StyleBoxFlat for popups
	var popup_style = StyleBoxFlat.new()
	popup_style.content_margin_left = 8.0
	popup_style.content_margin_top = 4.0
	popup_style.content_margin_right = 8.0
	popup_style.content_margin_bottom = 4.0
	popup_style.bg_color = Color(0.2, 0.2, 0.2, 1.0)
	popup_style.corner_radius_top_left = 4
	popup_style.corner_radius_top_right = 4
	popup_style.corner_radius_bottom_right = 4
	popup_style.corner_radius_bottom_left = 4
	
	# Configure VSyncOption popup
	if vsync_option:
		var popup: PopupMenu = vsync_option.get_popup()
		
		# Set size constraints
		popup.max_size = Vector2i(400, 0)
		popup.size = Vector2i(vsync_option.size.x, 0)
		
		# Ensure text doesn't overflow
		popup.add_theme_constant_override("item_margin_left", 8)
		popup.add_theme_constant_override("item_margin_right", 8)
		
		# Ensure popup has proper styling
		popup.add_theme_stylebox_override("panel", popup_style)
		popup.add_theme_stylebox_override("hover", popup_style)
		
		# Make sure popup is not transparent
		popup.transparent_bg = false
		
		# Connect to the about_to_popup signal to ensure it's visible
		if not popup.about_to_popup.is_connected(_on_popup_about_to_show):
			popup.about_to_popup.connect(_on_popup_about_to_show.bind(popup))
	
	# Configure PresetOption popup
	if preset_option:
		var preset_popup: PopupMenu = preset_option.get_popup()
		
		# Set size constraints
		preset_popup.max_size = Vector2i(400, 0)
		preset_popup.size = Vector2i(preset_option.size.x, 0)
		
		# Ensure text doesn't overflow
		preset_popup.add_theme_constant_override("item_margin_left", 8)
		preset_popup.add_theme_constant_override("item_margin_right", 8)
		
		# Ensure popup has proper styling
		preset_popup.add_theme_stylebox_override("panel", popup_style)
		preset_popup.add_theme_stylebox_override("hover", popup_style)
		
		# Make sure popup is not transparent
		preset_popup.transparent_bg = false
		
		# Connect to the about_to_popup signal to ensure it's visible
		if not preset_popup.about_to_popup.is_connected(_on_popup_about_to_show):
			preset_popup.about_to_popup.connect(_on_popup_about_to_show.bind(preset_popup))
		
	# Ensure popups are properly positioned
	_on_window_resized()

## Handle popup about to show
func _on_popup_about_to_show(popup: PopupMenu) -> void:
	# Make sure popup is not transparent
	popup.transparent_bg = false
	
	# Reset position to be recalculated by Godot
	popup.position = Vector2i(0, 0)
	
	# Set size to match parent
	if popup == vsync_option.get_popup():
		popup.size = Vector2i(vsync_option.size.x, 0)
	elif popup == preset_option.get_popup():
		popup.size = Vector2i(preset_option.size.x, 0)
