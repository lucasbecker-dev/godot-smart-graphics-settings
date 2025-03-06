@tool
@icon("res://addons/smart_graphics_settings/smart-graphics-settings-icon.svg")
class_name AdaptiveGraphicsUI
extends Control

## Path to the AdaptiveGraphics node
@export var adaptive_graphics_path: NodePath

## Reference to the AdaptiveGraphics node
var adaptive_graphics: AdaptiveGraphics

## UI Controls
@onready var target_fps_slider: HSlider = $VBoxContainer/TargetFPSSlider
@onready var enabled_checkbox: CheckBox = $VBoxContainer/EnabledCheckbox
@onready var allow_increase_checkbox: CheckBox = $VBoxContainer/AllowIncreaseCheckbox
@onready var threading_checkbox: CheckBox = $VBoxContainer/ThreadingCheckbox
@onready var preset_option: OptionButton = $VBoxContainer/PresetOption
@onready var fps_label: Label = $VBoxContainer/FPSLabel
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var renderer_label: Label = $VBoxContainer/RendererLabel

## Timer for updating FPS display
var update_timer: Timer

func _ready() -> void:
	adaptive_graphics = get_node(adaptive_graphics_path) as AdaptiveGraphics
	
	if not adaptive_graphics:
		push_error("AdaptiveGraphicsUI: Failed to find AdaptiveGraphics node at path: " + str(adaptive_graphics_path))
		return
	
	# Initialize UI with current values
	target_fps_slider.value = adaptive_graphics.target_fps
	enabled_checkbox.button_pressed = adaptive_graphics.enabled
	allow_increase_checkbox.button_pressed = adaptive_graphics.allow_quality_increase
	
	# Setup threading checkbox
	threading_checkbox.button_pressed = adaptive_graphics.use_threading
	threading_checkbox.disabled = not adaptive_graphics.threading_supported
	if not adaptive_graphics.threading_supported:
		threading_checkbox.tooltip_text = "Threading not supported on this platform"
	
	# Setup preset dropdown
	preset_option.clear()
	preset_option.add_item("Ultra Low", AdaptiveGraphics.QualityPreset.ULTRA_LOW)
	preset_option.add_item("Low", AdaptiveGraphics.QualityPreset.LOW)
	preset_option.add_item("Medium", AdaptiveGraphics.QualityPreset.MEDIUM)
	preset_option.add_item("High", AdaptiveGraphics.QualityPreset.HIGH)
	preset_option.add_item("Ultra", AdaptiveGraphics.QualityPreset.ULTRA)
	
	# Update UI for current renderer
	update_ui_for_current_renderer()
	
	# Connect signals
	target_fps_slider.value_changed.connect(_on_target_fps_changed)
	enabled_checkbox.toggled.connect(_on_enabled_toggled)
	allow_increase_checkbox.toggled.connect(_on_allow_increase_toggled)
	threading_checkbox.toggled.connect(_on_threading_toggled)
	preset_option.item_selected.connect(_on_preset_selected)
	
	# Setup update timer
	update_timer = Timer.new()
	update_timer.wait_time = 0.5 # Update twice per second
	update_timer.timeout.connect(_on_update_timer_timeout)
	add_child(update_timer)
	update_timer.start()

## Update UI elements based on the current renderer
func update_ui_for_current_renderer() -> void:
	if not adaptive_graphics or not adaptive_graphics.settings_manager:
		return
		
	var renderer_type: GraphicsSettingsManager.RendererType = adaptive_graphics.settings_manager.current_renderer
	var renderer_name: String = GraphicsSettingsManager.RendererType.keys()[renderer_type]
	
	# Add or update renderer label
	if not renderer_label:
		renderer_label = Label.new()
		renderer_label.name = "RendererLabel"
		$VBoxContainer.add_child(renderer_label)
		$VBoxContainer.move_child(renderer_label, 0) # Move to top
	
	renderer_label.text = "Current Renderer: " + renderer_name
	
	# Hide settings UI elements that don't apply to the current renderer
	# This assumes UI elements are named after the settings they control
	for setting_name in adaptive_graphics.settings_manager.available_settings.keys():
		var ui_element = find_node_by_name(setting_name + "Control")
		if ui_element:
			ui_element.visible = adaptive_graphics.settings_manager.is_setting_applicable(setting_name)

## Helper function to find a node by name
func find_node_by_name(node_name: String) -> Node:
	return find_child(node_name, true, false)

func _on_target_fps_changed(value: float) -> void:
	adaptive_graphics.target_fps = int(value)
	target_fps_slider.tooltip_text = "Target FPS: %d" % adaptive_graphics.target_fps

func _on_enabled_toggled(enabled: bool) -> void:
	adaptive_graphics.enabled = enabled

func _on_allow_increase_toggled(enabled: bool) -> void:
	adaptive_graphics.allow_quality_increase = enabled

func _on_threading_toggled(enabled: bool) -> void:
	adaptive_graphics.set_threading_enabled(enabled)

func _on_preset_selected(index: int) -> void:
	var preset: int = preset_option.get_item_id(index)
	adaptive_graphics.apply_preset(preset)

func _on_update_timer_timeout() -> void:
	# Update FPS display
	if adaptive_graphics.fps_monitor:
		var avg_fps: float = adaptive_graphics.fps_monitor.get_average_fps()
		fps_label.text = "Current FPS: %.1f" % avg_fps
		
		# Update status
		var status: String = "Status: "
		if not adaptive_graphics.enabled:
			status += "Disabled"
		elif adaptive_graphics.is_measuring:
			status += "Measuring..."
		elif adaptive_graphics.is_adjusting:
			status += "Adjusting..."
		else:
			if avg_fps < adaptive_graphics.target_fps - adaptive_graphics.fps_tolerance:
				status += "Performance below target"
			elif avg_fps > adaptive_graphics.target_fps + adaptive_graphics.fps_tolerance:
				status += "Performance above target"
			else:
				status += "Performance on target"
		
		status_label.text = status