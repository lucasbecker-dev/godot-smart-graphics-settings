@tool
@icon("res://addons/smart_graphics_settings/smart-graphics-settings-icon.svg")
class_name AdaptiveGraphics
extends Node

## Target FPS to maintain
@export var target_fps: int = 60

## Allow FPS to be within this range of target
@export var fps_tolerance: int = 5

## Seconds between adjustments
@export var adjustment_cooldown: float = 3.0

## Seconds to measure FPS before adjusting
@export var measurement_period: float = 2.0

## Whether adaptive graphics is enabled
@export var enabled: bool = true

## Whether to increase quality when FPS is high
@export var allow_quality_increase: bool = false

## Whether to use threading for adjustments
@export var use_threading: bool = true

## Seconds between applying each setting change
@export var setting_change_delay: float = 0.5

## Internal state
var fps_monitor: FPSMonitor
var settings_manager: GraphicsSettingsManager
var cooldown_timer: float = 0.0
var measurement_timer: float = 0.0
var is_measuring: bool = false
var is_adjusting: bool = false
var settings_changed: bool = false
var threading_supported: bool = false

## Threading components
var adjustment_thread: Thread
var adjustment_mutex: Mutex
var thread_exit: bool = false
var pending_adjustments: Array = []
var adjustment_timer: Timer

## Presets for quick configuration
enum QualityPreset {
	ULTRA_LOW,
	LOW,
	MEDIUM,
	HIGH,
	ULTRA
}

## Preset configurations
var presets: Dictionary = {
	QualityPreset.ULTRA_LOW: {
		"render_scale": 0, # 0.5
		"msaa": 0, # Disabled
		"shadow_quality": 0, # Disabled
		"shadow_size": 0, # 1024
		"fxaa": 0, # Disabled
		"ssao": 0, # Disabled
		"ssr": 0, # Disabled
		"sdfgi": 0, # Disabled
		"glow": 0, # Disabled
		"volumetric_fog": 0, # Disabled
		"dof": 0, # Disabled
		"motion_blur": 0 # Disabled
	},
	QualityPreset.LOW: {
		"render_scale": 1, # 0.6
		"msaa": 0, # Disabled
		"shadow_quality": 1, # Low
		"shadow_size": 0, # 1024
		"fxaa": 1, # Enabled
		"ssao": 0, # Disabled
		"ssr": 0, # Disabled
		"sdfgi": 0, # Disabled
		"glow": 1, # Enabled
		"volumetric_fog": 0, # Disabled
		"dof": 0, # Disabled
		"motion_blur": 0 # Disabled
	},
	QualityPreset.MEDIUM: {
		"render_scale": 3, # 0.8
		"msaa": 1, # 2X
		"shadow_quality": 2, # Medium
		"shadow_size": 1, # 2048
		"fxaa": 1, # Enabled
		"ssao": 1, # Enabled
		"ssao_quality": 1, # Low
		"ssr": 0, # Disabled
		"sdfgi": 0, # Disabled
		"glow": 1, # Enabled
		"volumetric_fog": 0, # Disabled
		"dof": 1, # Enabled
		"motion_blur": 0 # Disabled
	},
	QualityPreset.HIGH: {
		"render_scale": 4, # 0.9
		"msaa": 2, # 4X
		"shadow_quality": 3, # High
		"shadow_size": 2, # 4096
		"fxaa": 1, # Enabled
		"ssao": 1, # Enabled
		"ssao_quality": 2, # Medium
		"ssr": 1, # Enabled
		"ssr_max_steps": 2, # 32
		"sdfgi": 1, # Enabled
		"glow": 1, # Enabled
		"volumetric_fog": 1, # Enabled
		"volumetric_fog_density": 2, # 0.03
		"dof": 1, # Enabled
		"motion_blur": 1 # Enabled
	},
	QualityPreset.ULTRA: {
		"render_scale": 5, # 1.0
		"msaa": 3, # 8X
		"shadow_quality": 4, # Ultra
		"shadow_size": 3, # 8192
		"fxaa": 1, # Enabled
		"ssao": 1, # Enabled
		"ssao_quality": 3, # High
		"ssr": 1, # Enabled
		"ssr_max_steps": 3, # 64
		"sdfgi": 1, # Enabled
		"glow": 1, # Enabled
		"volumetric_fog": 1, # Enabled
		"volumetric_fog_density": 3, # 0.05
		"dof": 1, # Enabled
		"motion_blur": 1 # Enabled
	}
}

func _init() -> void:
	# Check if threading is supported on this platform
	threading_supported = OS.has_feature("threads")
	
	# Default to threaded mode if supported
	use_threading = threading_supported

func _ready() -> void:
	fps_monitor = FPSMonitor.new()
	settings_manager = GraphicsSettingsManager.new()
	
	add_child(fps_monitor)
	add_child(settings_manager)
	
	# Create timer for staggered setting application
	adjustment_timer = Timer.new()
	adjustment_timer.one_shot = true
	adjustment_timer.timeout.connect(_on_adjustment_timer_timeout)
	add_child(adjustment_timer)
	
	# Try to load saved settings
	settings_manager.load_graphics_settings()
	
	# Setup threading if supported and enabled
	if threading_supported and use_threading:
		setup_threading()

func _exit_tree() -> void:
	# Clean up threading resources
	if threading_supported and use_threading and adjustment_thread != null:
		thread_exit = true
		adjustment_thread.wait_to_finish()

func setup_threading() -> void:
	adjustment_mutex = Mutex.new()
	adjustment_thread = Thread.new()
	thread_exit = false
	
	# In Godot 4.4, Thread.start requires a Callable
	var err = adjustment_thread.start(Callable(self, "thread_function"))
	
	if err != OK:
		print("Failed to start adjustment thread: ", err)
		use_threading = false

func thread_function() -> void:
	while not thread_exit:
		# Sleep to avoid busy waiting
		OS.delay_msec(100)
		
		# Check if we need to analyze performance
		var should_analyze: bool = false
		
		adjustment_mutex.lock()
		should_analyze = is_measuring and fps_monitor.fps_history.size() >= fps_monitor.history_size
		adjustment_mutex.unlock()
		
		if should_analyze:
			var avg_fps: float = fps_monitor.get_average_fps()
			var is_stable: bool = fps_monitor.is_fps_stable()
			
			adjustment_mutex.lock()
			is_measuring = false
			adjustment_mutex.unlock()
			
			# Only adjust if FPS is stable (to avoid reacting to temporary spikes)
			if is_stable:
				if avg_fps < target_fps - fps_tolerance:
					queue_quality_decrease()
					call_deferred("set_settings_changed", true)
				elif allow_quality_increase and avg_fps > target_fps + fps_tolerance * 2:
					queue_quality_increase()
					call_deferred("set_settings_changed", true)

## Helper function to safely set settings_changed from thread
func set_settings_changed(value: bool) -> void:
	settings_changed = value
	if value:
		settings_manager.save_graphics_settings()

func _process(delta: float) -> void:
	if not enabled:
		return
	
	# Update timers
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	if not use_threading or not threading_supported:
		# Synchronous mode
		if is_measuring:
			measurement_timer -= delta
			if measurement_timer <= 0:
				is_measuring = false
				evaluate_performance()
		elif cooldown_timer <= 0 and not is_adjusting:
			# Start a new measurement period
			start_measurement()
	else:
		# Threaded mode - just start measurement when ready
		if cooldown_timer <= 0 and not is_measuring and not is_adjusting:
			# Check if there are pending adjustments
			adjustment_mutex.lock()
			var has_pending = not pending_adjustments.is_empty()
			adjustment_mutex.unlock()
			
			if not has_pending:
				start_measurement()

func start_measurement() -> void:
	fps_monitor.fps_history.clear()
	measurement_timer = measurement_period
	is_measuring = true

func evaluate_performance() -> void:
	var avg_fps: float = fps_monitor.get_average_fps()
	var is_stable: bool = fps_monitor.is_fps_stable()
	
	# Only adjust if FPS is stable (to avoid reacting to temporary spikes)
	if is_stable:
		if avg_fps < target_fps - fps_tolerance:
			decrease_quality()
			cooldown_timer = adjustment_cooldown
			settings_changed = true
		elif allow_quality_increase and avg_fps > target_fps + fps_tolerance * 2:
			increase_quality()
			cooldown_timer = adjustment_cooldown * 2 # Longer cooldown for increases
			settings_changed = true
	
	# Save settings if they've changed
	if settings_changed:
		settings_manager.save_graphics_settings()
		settings_changed = false

func decrease_quality() -> void:
	is_adjusting = true
	
	# Try to decrease quality of settings in priority order
	for setting_name in settings_manager.get_settings_by_priority():
		if settings_manager.decrease_setting_quality(setting_name):
			print("Decreased quality of ", setting_name, " to maintain target FPS")
			is_adjusting = false
			return
	
	is_adjusting = false

func increase_quality() -> void:
	is_adjusting = true
	
	# Try to increase quality of settings in reverse priority order
	var settings: Array[String] = settings_manager.get_settings_by_priority()
	settings.reverse()
	
	for setting_name in settings:
		if settings_manager.increase_setting_quality(setting_name):
			print("Increased quality of ", setting_name, " as performance allows")
			is_adjusting = false
			return
	
	is_adjusting = false

## Queue a quality decrease for threaded processing
func queue_quality_decrease() -> void:
	adjustment_mutex.lock()
	is_adjusting = true
	adjustment_mutex.unlock()
	
	# Try to decrease quality of settings in priority order
	for setting_name in settings_manager.get_settings_by_priority():
		var setting: GraphicsSettingsManager.Setting = settings_manager.available_settings[setting_name]
		if setting.current_index > 0:
			var new_index: int = setting.current_index - 1
			
			adjustment_mutex.lock()
			pending_adjustments.append({
				"setting_name": setting_name,
				"index": new_index,
				"is_decrease": true
			})
			adjustment_mutex.unlock()
			
			# Start processing the queue if not already processing
			call_deferred("process_next_adjustment")
			
			print("Queued decrease of quality for ", setting_name)
			return
	
	adjustment_mutex.lock()
	is_adjusting = false
	adjustment_mutex.unlock()

## Queue a quality increase for threaded processing
func queue_quality_increase() -> void:
	adjustment_mutex.lock()
	is_adjusting = true
	adjustment_mutex.unlock()
	
	# Try to increase quality of settings in reverse priority order
	var settings: Array[String] = settings_manager.get_settings_by_priority()
	settings.reverse()
	
	for setting_name in settings:
		var setting: GraphicsSettingsManager.Setting = settings_manager.available_settings[setting_name]
		if setting.current_index < setting.values.size() - 1:
			var new_index: int = setting.current_index + 1
			
			adjustment_mutex.lock()
			pending_adjustments.append({
				"setting_name": setting_name,
				"index": new_index,
				"is_decrease": false
			})
			adjustment_mutex.unlock()
			
			# Start processing the queue if not already processing
			call_deferred("process_next_adjustment")
			
			print("Queued increase of quality for ", setting_name)
			return
	
	adjustment_mutex.lock()
	is_adjusting = false
	adjustment_mutex.unlock()

## Process the next adjustment in the queue
func process_next_adjustment() -> void:
	adjustment_mutex.lock()
	var has_adjustments: bool = not pending_adjustments.is_empty()
	adjustment_mutex.unlock()
	
	if has_adjustments:
		adjustment_mutex.lock()
		var adjustment: Dictionary = pending_adjustments[0]
		pending_adjustments.remove_at(0)
		adjustment_mutex.unlock()
		
		var setting_name: String = adjustment.setting_name
		var new_index: int = adjustment.index
		var is_decrease: bool = adjustment.is_decrease
		
		# Apply the setting change
		settings_manager.available_settings[setting_name].current_index = new_index
		settings_manager.apply_setting(setting_name)
		
		if is_decrease:
			print("Decreased quality of ", setting_name, " to maintain target FPS")
		else:
			print("Increased quality of ", setting_name, " as performance allows")
		
		# Schedule the next adjustment after a delay
		adjustment_mutex.lock()
		var has_more: bool = not pending_adjustments.is_empty()
		adjustment_mutex.unlock()
		
		if has_more:
			adjustment_timer.start(setting_change_delay)
		else:
			# No more adjustments, reset state and start cooldown
			adjustment_mutex.lock()
			is_adjusting = false
			adjustment_mutex.unlock()
			
			cooldown_timer = adjustment_cooldown

## Timer callback for staggered setting application
func _on_adjustment_timer_timeout() -> void:
	process_next_adjustment()

## Apply a quality preset
func apply_preset(preset: QualityPreset) -> void:
	if not presets.has(preset):
		return
	
	var preset_settings: Dictionary = get_preset_for_current_renderer(preset)
	
	# Stop any ongoing adjustments
	if use_threading and threading_supported:
		adjustment_mutex.lock()
		pending_adjustments.clear()
		is_adjusting = true
		adjustment_mutex.unlock()
	else:
		is_adjusting = true
	
	# Apply all preset settings
	for setting_name in preset_settings:
		if settings_manager.available_settings.has(setting_name) and settings_manager.is_setting_applicable(setting_name):
			settings_manager.available_settings[setting_name].current_index = preset_settings[setting_name]
			settings_manager.apply_setting(setting_name)
	
	settings_changed = true
	settings_manager.save_graphics_settings()
	
	# Reset state
	if use_threading and threading_supported:
		adjustment_mutex.lock()
		is_adjusting = false
		adjustment_mutex.unlock()
	else:
		is_adjusting = false
	
	cooldown_timer = adjustment_cooldown
	print("Applied preset: ", QualityPreset.keys()[preset])

## Get a preset adjusted for the current renderer
func get_preset_for_current_renderer(preset_type: QualityPreset) -> Dictionary:
	var base_preset: Dictionary = presets[preset_type].duplicate()
	var renderer_type: GraphicsSettingsManager.RendererType = settings_manager.current_renderer
	
	# Filter out settings that don't apply to the current renderer
	var filtered_preset: Dictionary = {}
	for setting_name in base_preset:
		if settings_manager.is_setting_applicable(setting_name):
			filtered_preset[setting_name] = base_preset[setting_name]
	
	return filtered_preset

## Toggle threading mode
func set_threading_enabled(enabled: bool) -> void:
	if enabled == use_threading:
		return
	
	if enabled and not threading_supported:
		print("Threading not supported on this platform")
		return
	
	# Clean up existing thread if disabling
	if not enabled and adjustment_thread != null:
		thread_exit = true
		adjustment_thread.wait_to_finish()
		adjustment_thread = null
		adjustment_mutex = null
	
	# Start new thread if enabling
	if enabled and adjustment_thread == null:
		setup_threading()
	
	use_threading = enabled