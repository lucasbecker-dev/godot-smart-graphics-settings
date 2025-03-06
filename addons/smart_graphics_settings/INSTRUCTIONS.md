# Smart Graphics Settings for Godot 4.4

A powerful adaptive graphics settings system that automatically adjusts visual quality to maintain target performance in Godot 4.4 games.

## Features

- **Automatic Performance Optimization**: Dynamically adjusts graphics settings to maintain target FPS
- **Threaded Performance Analysis**: Uses a separate thread for performance monitoring to minimize impact on gameplay
- **Customizable Quality Presets**: Includes Ultra Low, Low, Medium, High, and Ultra presets
- **In-Game Settings UI**: Provides a ready-to-use settings panel for players
- **Prioritized Adjustments**: Intelligently adjusts settings with minimal visual impact first
- **Persistent Settings**: Automatically saves and loads user preferences
- **Multi-Renderer Support**: Works with all Godot 4.4 renderers (Forward+, Mobile, and Compatibility)

## Installation

1. Copy the `smart_graphics_settings` folder into your project's `addons` directory
2. Enable the plugin in Project Settings → Plugins
3. The `SmartGraphicsSettings` singleton will be automatically added to your project

## Usage Instructions

### Basic Usage

The extension works out of the box with minimal setup:

```gdscript
# Access the Smart Graphics Settings singleton
var settings: SmartGraphicsSettings = SmartGraphicsSettings

# Show the settings UI (can be toggled with F7 by default)
settings.show_ui()

# Apply a quality preset
settings.apply_preset(AdaptiveGraphics.QualityPreset.HIGH)

# Enable/disable adaptive graphics
settings.set_enabled(true)

# Set target FPS
settings.set_target_fps(60)
```

### Accessing Components

You can access the individual components for more advanced control:

```gdscript
# Get the adaptive graphics controller
var adaptive: AdaptiveGraphics = SmartGraphicsSettings.adaptive_graphics

# Get the FPS monitor
var fps_monitor: FPSMonitor = adaptive.fps_monitor

# Get the settings manager
var settings_manager: GraphicsSettingsManager = adaptive.settings_manager

# Check which renderer is being used
var renderer_type: GraphicsSettingsManager.RendererType = settings_manager.current_renderer
var renderer_name: String = GraphicsSettingsManager.RendererType.keys()[renderer_type]
print("Current renderer: ", renderer_name)
```

### Customizing Settings

You can customize the adaptive graphics behavior:

```gdscript
var adaptive: AdaptiveGraphics = SmartGraphicsSettings.adaptive_graphics

# Set target FPS and tolerance
adaptive.target_fps = 60
adaptive.fps_tolerance = 5  # Allow FPS to be within 5 frames of target

# Set adjustment timing
adaptive.adjustment_cooldown = 3.0  # Seconds between adjustments
adaptive.measurement_period = 2.0   # Seconds to measure FPS before adjusting
adaptive.setting_change_delay = 0.5  # Seconds between applying each setting change

# Enable/disable features
adaptive.enabled = true
adaptive.allow_quality_increase = true  # Allow increasing quality when FPS is high
adaptive.use_threading = true           # Use threading for performance analysis
```

### Creating Custom Quality Presets

You can define your own quality presets:

```gdscript
var adaptive: AdaptiveGraphics = SmartGraphicsSettings.adaptive_graphics
var settings_manager: GraphicsSettingsManager = adaptive.settings_manager

# Define a custom preset
var custom_preset: Dictionary = {
    "render_scale": 3,  # 0.8
    "msaa": 1,          # 2X
    "shadow_quality": 2, # Medium
    "shadow_size": 1,    # 2048
    "fxaa": 1,           # Enabled
    # ... other settings
}

# Apply custom settings
for setting_name in custom_preset:
    if settings_manager.available_settings.has(setting_name) and settings_manager.is_setting_applicable(setting_name):
        settings_manager.available_settings[setting_name].current_index = custom_preset[setting_name]
        settings_manager.apply_setting(setting_name)
```

### Manually Adjusting Individual Settings

You can manually adjust individual graphics settings:

```gdscript
var settings_manager: GraphicsSettingsManager = SmartGraphicsSettings.adaptive_graphics.settings_manager

# Check if a setting is applicable to the current renderer
if settings_manager.is_setting_applicable("render_scale"):
    # Decrease quality of a specific setting
    settings_manager.decrease_setting_quality("render_scale")

# Increase quality of a specific setting
if settings_manager.is_setting_applicable("msaa"):
    settings_manager.increase_setting_quality("msaa")

# Set a specific quality level
if settings_manager.is_setting_applicable("shadow_quality"):
    settings_manager.available_settings["shadow_quality"].current_index = 3  # High
    settings_manager.apply_setting("shadow_quality")
```

### Saving and Loading Settings

Settings are automatically saved, but you can manually trigger saving:

```gdscript
var settings_manager: GraphicsSettingsManager = SmartGraphicsSettings.adaptive_graphics.settings_manager

# Save current settings
settings_manager.save_graphics_settings()

# Load saved settings
settings_manager.load_graphics_settings()
```

### Monitoring Performance

You can monitor performance metrics:

```gdscript
var fps_monitor: FPSMonitor = SmartGraphicsSettings.adaptive_graphics.fps_monitor

# Get current average FPS
var avg_fps: float = fps_monitor.get_average_fps()

# Check if FPS is stable
var is_stable: bool = fps_monitor.is_fps_stable()

# Access FPS history
var history: Array[float] = fps_monitor.fps_history
```

### Customizing the UI

You can customize the built-in UI or create your own:

```gdscript
# Show the default UI
SmartGraphicsSettings.show_ui()

# Hide the UI
SmartGraphicsSettings.hide_ui()

# Toggle the UI
SmartGraphicsSettings.toggle_ui()

# Change the toggle key (default is F7)
if InputMap.has_action("toggle_graphics_settings"):
    InputMap.action_erase_events("toggle_graphics_settings")
    
var event: InputEventKey = InputEventKey.new()
event.keycode = KEY_F8  # Change to F8
InputMap.action_add_event("toggle_graphics_settings", event)
```

## Available Settings

The following graphics settings are automatically managed (availability depends on the renderer):

| Setting | Description | Priority | Forward+ | Mobile | Compatibility |
|---------|-------------|----------|----------|--------|---------------|
| Render Scale | Renders at lower resolution and upscales | Lowest | ✓ | ✓ | ✓ |
| MSAA | Multi-sample anti-aliasing | Low | ✓ | ✓ | ✓ |
| FXAA | Fast approximate anti-aliasing | Low | ✓ | ✓ | ✓ |
| Shadow Quality | Shadow map detail level | Medium | ✓ | ✓ | ✓ |
| Shadow Size | Shadow map resolution | Medium | ✓ | ✓ | ✓ |
| SSAO | Screen space ambient occlusion | Medium | ✓ | ✗ | ✓ |
| SSR | Screen space reflections | High | ✓ | ✗ | ✗ |
| SDFGI | Signed distance field global illumination | Highest | ✓ | ✗ | ✗ |
| Volumetric Fog | 3D volumetric fog effects | High | ✓ | ✗ | ✗ |
| Glow | Screen glow effects | Low | ✓ | ✓ | ✓ |
| Depth of Field | Camera depth of field blur | Low | ✓ | ✓ | ✓ |
| Motion Blur | Camera motion blur | Low | ✓ | ✓ | ✓ |

## Troubleshooting

### Performance Issues

If the adaptive graphics system isn't maintaining your target FPS:

1. Check if the `enabled` property is set to `true`
2. Try lowering the `target_fps` value
3. Increase the `fps_tolerance` to allow more variation
4. Check if your game has other performance bottlenecks (like physics or scripts)

### UI Not Appearing

If the settings UI doesn't appear when pressing F7:

1. Check if the input action is registered correctly
2. Make sure the UI scene is properly loaded
3. Try manually calling `SmartGraphicsSettings.show_ui()`

### Settings Not Applying

If graphics settings aren't being applied correctly:

1. Make sure the plugin is enabled in Project Settings
2. Check if the `SmartGraphicsSettings` singleton is properly registered
3. Verify that the required nodes (Viewport, WorldEnvironment, Camera3D) are found
4. Check if the setting is applicable to your current renderer using `is_setting_applicable()`

## Requirements

- Godot 4.4 or higher
- Works with all rendering methods: Forward+, Mobile, and Compatibility
