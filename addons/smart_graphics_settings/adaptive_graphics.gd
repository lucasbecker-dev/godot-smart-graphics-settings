@tool
@icon("res://addons/smart_graphics_settings/smart-graphics-settings-icon.svg")
class_name AdaptiveGraphics
extends Node

## Signal emitted when graphics settings are changed
signal changed_settings

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

## Whether to automatically set target FPS to match display refresh rate
@export var match_refresh_rate: bool = false

## Internal state
var fps_monitor: FPSMonitor
var settings_manager: GraphicsSettingsManager
var cooldown_timer: float = 0.0
var measurement_timer: float = 0.0
var is_measuring: bool = false
var is_adjusting: bool = false
var settings_changed: bool = false
var threading_supported: bool = false
var current_vsync_mode: int = -1
var display_refresh_rate: float = 60.0
var _current_action: String = "Idle" # Internal current action storage

## Threading components
var adjustment_thread: Thread
var adjustment_mutex: Mutex
var thread_exit: bool = false
var pending_adjustments: Array[Dictionary] = []
var adjustment_timer: Timer

## Platform information for debugging
var platform_info: Dictionary = {}

## Presets for quick configuration
enum QualityPreset {
	ULTRA_LOW,
	LOW,
	MEDIUM,
	HIGH,
	ULTRA
}

## Preset configurations
var presets: Dictionary[int, Dictionary] = {
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
	# Initialize current action
	current_action = "Initializing"
	
	# Gather platform information for better debugging
	platform_info = {
		"os_name": OS.get_name(),
		"model_name": OS.get_model_name(),
		"processor_name": OS.get_processor_name(),
		"processor_count": OS.get_processor_count()
	}
	
	# Check if threading is supported on this platform using multiple methods
	var has_threads_feature: bool = OS.has_feature("threads")
	var has_multiple_processors: bool = OS.get_processor_count() > 1
	var is_web_platform: bool = OS.has_feature("web")
	
	# Determine threading support based on platform and features
	threading_supported = has_threads_feature and not is_web_platform
	
	# Additional platform-specific checks
	if OS.get_name() == "Web":
		threading_supported = false
		print_debug("Smart Graphics Settings: Threading disabled on Web platform")
	elif OS.get_name() == "Android" or OS.get_name() == "iOS":
		# Mobile platforms may have threading limitations
		threading_supported = has_threads_feature and has_multiple_processors
		print_debug("Smart Graphics Settings: Mobile platform detected, threading support: ", threading_supported)
		
		# Apply mobile-specific optimizations
		fps_tolerance = 8 # Allow more variation on mobile
		adjustment_cooldown = 5.0 # Less frequent adjustments to save battery
		measurement_period = 3.0 # Longer measurement period for more stable readings
	elif OS.get_name() == "Windows" or OS.get_name() == "macOS" or OS.get_name() == "Linux":
		# Desktop platforms can use more precise settings
		fps_tolerance = 3
		adjustment_cooldown = 2.0
		measurement_period = 1.5
	
	# Default to threaded mode if supported
	use_threading = threading_supported
	
	# Log threading support status
	print_debug("Smart Graphics Settings: Threading support detected: ", threading_supported)
	if threading_supported:
		print_debug("Smart Graphics Settings: Using ", OS.get_processor_count(), " processors")
	else:
		print_debug("Smart Graphics Settings: Threading disabled, using single-threaded mode")
	
	# Set current action to idle after initialization
	current_action = "Idle"

func _ready() -> void:
	if not Engine.is_editor_hint():
		current_action = "Setting Up"
		
		# Initialize FPS monitor
		fps_monitor = FPSMonitor.new()
		add_child(fps_monitor)
		
		# Setup threading if supported
		if threading_supported and use_threading:
			setup_threading()
		
		# Get the current VSync mode and display refresh rate
		update_vsync_and_refresh_rate()
		
		# If match_refresh_rate is enabled, set target FPS to match display refresh rate
		if match_refresh_rate:
			target_fps = int(display_refresh_rate)
			if target_fps <= 0: # Fallback if we couldn't get the refresh rate
				target_fps = 60
		
		settings_manager = GraphicsSettingsManager.new()
		add_child(settings_manager)
		
		# Try to load saved settings
		settings_manager.load_graphics_settings()
		
		# Create timer for staggered setting application
		adjustment_timer = Timer.new()
		adjustment_timer.one_shot = true
		adjustment_timer.timeout.connect(_on_adjustment_timer_timeout)
		add_child(adjustment_timer)
		
		current_action = "Ready"
		
		# Set to Idle after a short delay to allow UI to update
		await get_tree().create_timer(0.5).timeout
		current_action = "Idle"

func _exit_tree() -> void:
	# Clean up threading resources
	if threading_supported and use_threading and adjustment_thread != null and adjustment_thread.is_started():
		thread_exit = true
		adjustment_thread.wait_to_finish()

func setup_threading() -> void:
	# Create mutex for thread synchronization
	adjustment_mutex = Mutex.new()
	
	# Create timer for delayed setting changes
	adjustment_timer = Timer.new()
	adjustment_timer.wait_time = setting_change_delay
	adjustment_timer.one_shot = true
	adjustment_timer.timeout.connect(_on_adjustment_timer_timeout)
	add_child(adjustment_timer)
	
	# Start adjustment thread
	thread_exit = false
	adjustment_thread = Thread.new()
	var thread_start_error = adjustment_thread.start(thread_function)
	
	if thread_start_error != OK:
		push_error("Smart Graphics Settings: Failed to start adjustment thread. Error code: ", thread_start_error)
		threading_supported = false
		use_threading = false
		print_debug("Smart Graphics Settings: Falling back to single-threaded mode")
	else:
		print_debug("Smart Graphics Settings: Adjustment thread started successfully")

func _thread_evaluate_performance() -> void:
	# Get a thread-safe copy of FPS data
	var avg_fps: float = fps_monitor.get_average_fps()
	var is_stable: bool = fps_monitor.is_fps_stable()
	
	# Reset measuring flag with proper locking
	adjustment_mutex.lock()
	is_measuring = false
	var current_target_fps: int = target_fps
	var current_fps_tolerance: int = fps_tolerance
	var current_allow_increase: bool = allow_quality_increase
	adjustment_mutex.unlock()
	
	# Get the effective maximum FPS based on VSync settings
	var max_fps: float = get_effective_max_fps()
	var effective_target: int = current_target_fps
	
	# If VSync is limiting our FPS and our target is higher, adjust the target
	if max_fps > 0 and current_target_fps > max_fps:
		effective_target = int(max_fps)
	
	# Only adjust if FPS is stable (to avoid reacting to temporary spikes)
	if is_stable:
		if avg_fps < effective_target - current_fps_tolerance:
			queue_quality_decrease()
			
			adjustment_mutex.lock()
			cooldown_timer = adjustment_cooldown
			adjustment_mutex.unlock()
			
			call_deferred("set_settings_changed", true)
		elif current_allow_increase and avg_fps > effective_target + current_fps_tolerance * 2:
			queue_quality_increase()
			
			adjustment_mutex.lock()
			cooldown_timer = adjustment_cooldown * 2 # Longer cooldown for increases
			adjustment_mutex.unlock()
			
			call_deferred("set_settings_changed", true)
	else:
		# If FPS is not stable, just reset the measuring state
		adjustment_mutex.lock()
		is_adjusting = false
		adjustment_mutex.unlock()

## Helper function to safely set settings_changed from thread
func set_settings_changed(value: bool) -> void:
	adjustment_mutex.lock()
	settings_changed = value
	adjustment_mutex.unlock()
	
	if value:
		settings_manager.save_graphics_settings()

func _process(delta: float) -> void:
	# Skip processing in editor
	if Engine.is_editor_hint() or not enabled:
		return
	
	# Update timers with proper locking
	adjustment_mutex.lock()
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	var current_cooldown: float = cooldown_timer
	var current_is_measuring: bool = is_measuring
	var current_is_adjusting: bool = is_adjusting
	var current_use_threading: bool = use_threading
	var current_threading_supported: bool = threading_supported
	adjustment_mutex.unlock()
	
	if not current_use_threading or not current_threading_supported:
		# Synchronous mode
		if current_is_measuring:
			adjustment_mutex.lock()
			measurement_timer -= delta
			var current_measurement_timer: float = measurement_timer
			adjustment_mutex.unlock()
			
			if current_measurement_timer <= 0:
				adjustment_mutex.lock()
				is_measuring = false
				adjustment_mutex.unlock()
				evaluate_performance()
		elif current_cooldown <= 0 and not current_is_adjusting:
			# Start a new measurement period
			start_measurement()
	else:
		# Threaded mode - just start measurement when ready
		if current_cooldown <= 0 and not current_is_measuring and not current_is_adjusting:
			# Check if there are pending adjustments
			adjustment_mutex.lock()
			var has_pending: bool = not pending_adjustments.is_empty()
			adjustment_mutex.unlock()
			
			if not has_pending:
				start_measurement()

func start_measurement() -> void:
	fps_monitor.clear_history()
	
	adjustment_mutex.lock()
	measurement_timer = measurement_period
	is_measuring = true
	current_action = "Measuring Performance..."
	adjustment_mutex.unlock()

func evaluate_performance() -> void:
	current_action = "Analyzing Performance..."
	
	var avg_fps: float = fps_monitor.get_average_fps()
	var is_stable: bool = fps_monitor.is_fps_stable()
	
	# Get the effective maximum FPS based on VSync settings
	var max_fps = get_effective_max_fps()
	var effective_target = target_fps
	
	# If VSync is limiting our FPS and our target is higher, adjust the target
	if max_fps > 0 and target_fps > max_fps:
		effective_target = max_fps
	
	# Only adjust if FPS is stable (to avoid reacting to temporary spikes)
	if is_stable:
		if avg_fps < effective_target - fps_tolerance:
			decrease_quality()
			cooldown_timer = adjustment_cooldown
			settings_changed = true
		elif allow_quality_increase and avg_fps > effective_target + fps_tolerance * 2:
			increase_quality()
			cooldown_timer = adjustment_cooldown * 2 # Longer cooldown for increases
			settings_changed = true
	
	# Save settings if they've changed
	if settings_changed:
		settings_manager.save_graphics_settings()
		settings_changed = false
	
	current_action = "Performance Analysis Complete"
	await get_tree().create_timer(1.0).timeout
	current_action = "Monitoring Performance"

func decrease_quality() -> void:
	is_adjusting = true
	current_action = "Optimizing Performance..."
	
	# Try to decrease quality of settings in priority order
	for setting_name in settings_manager.get_settings_by_priority():
		if settings_manager.decrease_setting_quality(setting_name):
			print("Decreased quality of ", setting_name, " to maintain target FPS")
			current_action = "Decreased " + setting_name + " Quality"
			is_adjusting = false
			return
	
	is_adjusting = false
	current_action = "Monitoring Performance"

func increase_quality() -> void:
	is_adjusting = true
	current_action = "Improving Visual Quality..."
	
	# Try to increase quality of settings in reverse priority order
	var settings: Array[String] = settings_manager.get_settings_by_priority()
	settings.reverse()
	
	for setting_name in settings:
		if settings_manager.increase_setting_quality(setting_name):
			print("Increased quality of ", setting_name, " as performance allows")
			current_action = "Increased " + setting_name + " Quality"
			is_adjusting = false
			return
	
	is_adjusting = false
	current_action = "Monitoring Performance"

## Queue a quality decrease for threaded processing
func queue_quality_decrease() -> void:
	adjustment_mutex.lock()
	is_adjusting = true
	current_action = "Preparing Performance Optimization..."
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
	current_action = "Monitoring Performance"
	adjustment_mutex.unlock()

## Queue a quality increase for threaded processing
func queue_quality_increase() -> void:
	adjustment_mutex.lock()
	is_adjusting = true
	current_action = "Preparing Quality Improvement..."
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
	current_action = "Monitoring Performance"
	adjustment_mutex.unlock()

## Process the next adjustment in the queue
func process_next_adjustment() -> void:
	adjustment_mutex.lock()
	var has_adjustments: bool = not pending_adjustments.is_empty()
	var adjustment: Dictionary = {}
	
	if has_adjustments:
		adjustment = pending_adjustments[0]
		pending_adjustments.remove_at(0)
	
	adjustment_mutex.unlock()
	
	if has_adjustments:
		var setting_name: String = adjustment.setting_name
		var new_index: int = adjustment.index
		var is_decrease: bool = adjustment.is_decrease
		
		# Update current action
		adjustment_mutex.lock()
		if is_decrease:
			current_action = "Decreasing " + setting_name + " Quality..."
		else:
			current_action = "Increasing " + setting_name + " Quality..."
		adjustment_mutex.unlock()
		
		# Apply the setting change
		settings_manager.available_settings[setting_name].current_index = new_index
		settings_manager.apply_setting(setting_name)
		
		# Emit the changed_settings signal
		emit_signal("changed_settings")
		
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
			current_action = "Monitoring Performance"
			cooldown_timer = adjustment_cooldown
			adjustment_mutex.unlock()

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
		current_action = "Applying " + QualityPreset.keys()[preset] + " Quality Preset..."
		adjustment_mutex.unlock()
	else:
		is_adjusting = true
		current_action = "Applying " + QualityPreset.keys()[preset] + " Quality Preset..."
	
	# Apply all preset settings
	for setting_name in preset_settings:
		if settings_manager.available_settings.has(setting_name) and settings_manager.is_setting_applicable(setting_name):
			settings_manager.available_settings[setting_name].current_index = preset_settings[setting_name]
			settings_manager.apply_setting(setting_name)
	
	settings_changed = true
	settings_manager.save_graphics_settings()
	
	# Emit the changed_settings signal
	emit_signal("changed_settings")
	
	# Reset state
	if use_threading and threading_supported:
		adjustment_mutex.lock()
		is_adjusting = false
		current_action = "Applied " + QualityPreset.keys()[preset] + " Quality Preset"
		adjustment_mutex.unlock()
	else:
		is_adjusting = false
		current_action = "Applied " + QualityPreset.keys()[preset] + " Quality Preset"
	
	# Show the completion message briefly before returning to monitoring
	await get_tree().create_timer(1.0).timeout
	current_action = "Monitoring Performance"
	
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
		push_warning("Smart Graphics Settings: Threading is not supported on this platform")
		return
	
	use_threading = enabled
	
	# If enabling threading and it's supported, set up the thread
	if use_threading and threading_supported:
		if adjustment_thread == null or not adjustment_thread.is_started():
			setup_threading()
	# If disabling threading, clean up the thread
	elif adjustment_thread != null and adjustment_thread.is_started():
		cleanup_threading()

## Updates the current VSync mode and display refresh rate
func update_vsync_and_refresh_rate() -> void:
	current_vsync_mode = DisplayServer.window_get_vsync_mode()
	display_refresh_rate = DisplayServer.screen_get_refresh_rate()
	if display_refresh_rate <= 0: # Fallback if we couldn't get the refresh rate
		display_refresh_rate = 60.0

## Get the effective maximum FPS based on VSync settings
func get_effective_max_fps() -> float:
	update_vsync_and_refresh_rate()
	
	# If VSync is enabled or adaptive, the max FPS is limited by the refresh rate
	if current_vsync_mode == DisplayServer.VSYNC_ENABLED:
		return display_refresh_rate
	elif current_vsync_mode == DisplayServer.VSYNC_ADAPTIVE:
		# For adaptive VSync, we can go below the refresh rate but not above
		return display_refresh_rate
	
	# For disabled VSync or mailbox, there's no upper limit
	return 0.0 # 0 means no limit

## Set the target FPS to match the display refresh rate
func set_target_fps_to_refresh_rate() -> void:
	update_vsync_and_refresh_rate()
	target_fps = int(display_refresh_rate)
	if target_fps <= 0: # Fallback if we couldn't get the refresh rate
		target_fps = 60

## Set the VSync mode
func set_vsync_mode(mode: int) -> void:
	DisplayServer.window_set_vsync_mode(mode)
	update_vsync_and_refresh_rate()
	
	# If match_refresh_rate is enabled, update the target FPS
	if match_refresh_rate:
		set_target_fps_to_refresh_rate()

## Get detailed threading support information
func get_threading_support_info() -> Dictionary:
	return {
		"threading_supported": threading_supported,
		"use_threading": use_threading,
		"platform": OS.get_name(),
		"processor_count": OS.get_processor_count(),
		"has_threads_feature": OS.has_feature("threads"),
		"is_web_platform": OS.has_feature("web"),
		"thread_active": adjustment_thread != null and adjustment_thread.is_started() if threading_supported else false
	}

## Thread function for performance evaluation
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
			_thread_evaluate_performance()

## Clean up threading resources
func cleanup_threading() -> void:
	if adjustment_thread != null and adjustment_thread.is_started():
		# Signal thread to exit
		thread_exit = true
		# Wait for thread to finish
		adjustment_thread.wait_to_finish()
		adjustment_thread = null
	
	# Clean up mutex
	adjustment_mutex = null
	
	# Remove timer if it exists
	if adjustment_timer != null and adjustment_timer.is_inside_tree():
		adjustment_timer.queue_free()
		adjustment_timer = null
	
	print_debug("Smart Graphics Settings: Threading resources cleaned up")

## Get the current action in a thread-safe way
func get_current_action() -> String:
	if use_threading and threading_supported and adjustment_mutex != null:
		adjustment_mutex.lock()
		var action = _current_action
		adjustment_mutex.unlock()
		return action
	return _current_action

## Set the current action in a thread-safe way
func set_current_action(action: String) -> void:
	if use_threading and threading_supported and adjustment_mutex != null:
		adjustment_mutex.lock()
		_current_action = action
		adjustment_mutex.unlock()
	else:
		_current_action = action

## Current action property
var current_action: String:
	get:
		return get_current_action()
	set(value):
		set_current_action(value)
