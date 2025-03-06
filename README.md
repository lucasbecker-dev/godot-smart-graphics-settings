# Smart Graphics Settings for Godot 4.4

A powerful adaptive graphics settings system that automatically adjusts visual quality to maintain target performance in Godot 4.4 games. It also provides a set of customizable graphics profiles.

![Smart Graphics Settings](https://via.placeholder.com/800x400?text=Smart+Graphics+Settings)

## Features

- **Automatic Performance Optimization**: Dynamically adjusts graphics settings to maintain target FPS
- **Threaded Performance Analysis**: Uses a separate thread for performance monitoring to minimize impact on gameplay
- **Customizable Quality Presets**: Includes Ultra Low, Low, Medium, High, and Ultra presets
- **In-Game Settings UI**: Provides a ready-to-use settings panel for players
- **Prioritized Adjustments**: Intelligently adjusts settings with minimal visual impact first
- **Persistent Settings**: Automatically saves and loads user preferences
- **Easy Integration**: Simple to add to any Godot 4.4 project
- **Multi-Renderer Support**: Works with all Godot 4.4 renderers (Forward+, Mobile, and Compatibility)

## Installation

1. Copy the `addons/smart_graphics_settings` folder into your project's `addons` directory
2. Enable the plugin in Project Settings → Plugins
3. The `SmartGraphicsSettings` singleton will be automatically added to your project

## Quick Start

The extension works out of the box with minimal setup:

```gdscript
# Access the Smart Graphics Settings singleton
var settings = SmartGraphicsSettings

# Show the settings UI
settings.show_ui()

# Apply a quality preset
settings.apply_preset(AdaptiveGraphics.QualityPreset.HIGH)

# Enable/disable adaptive graphics
settings.set_enabled(true)

# Set target FPS
settings.set_target_fps(60)
```

## How It Works

Smart Graphics Settings continuously monitors your game's performance and makes intelligent adjustments to maintain your target framerate:

1. **Monitoring**: Tracks FPS over time to detect performance issues
2. **Analysis**: Determines if performance is stable and below target
3. **Adjustment**: Automatically adjusts graphics settings in order of priority
4. **Persistence**: Saves settings for future sessions

The system prioritizes adjustments that have the least visual impact but highest performance gain, such as render scale, before moving on to more visually significant settings.

## Renderer Support

The extension automatically detects which renderer your project is using and adjusts available settings accordingly:

### Forward+ Renderer

- Full support for all graphics settings including advanced features like SDFGI, SSR, and volumetric fog

### Mobile Renderer

- Support for core settings like render scale, MSAA, shadows, and glow
- Advanced features not available in Mobile renderer are automatically disabled

### Compatibility Renderer

- Support for core settings plus some additional features like SSAO
- Advanced features not available in Compatibility renderer are automatically disabled

## Configurable Settings

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

## User Interface

The extension includes a complete settings UI that can be toggled with the F7 key (customizable). The UI allows players to:

- View current FPS and performance status
- See which renderer is currently being used
- Set target FPS
- Enable/disable adaptive graphics
- Allow quality increases when performance is good
- Enable/disable threading
- Select quality presets

## Advanced Usage

### Custom Integration

You can create your own UI or integrate with your existing settings menu:

```gdscript
# Get the adaptive graphics controller
var adaptive = SmartGraphicsSettings.adaptive_graphics

# Customize settings
adaptive.target_fps = 60
adaptive.fps_tolerance = 5
adaptive.adjustment_cooldown = 3.0
adaptive.measurement_period = 2.0
adaptive.enabled = true
adaptive.allow_quality_increase = true
adaptive.use_threading = true
```

### Custom Quality Presets

You can define your own quality presets:

```gdscript
var adaptive = SmartGraphicsSettings.adaptive_graphics

# Define a custom preset
var custom_preset = {
    "render_scale": 3,  # 0.8
    "msaa": 1,          # 2X
    "shadow_quality": 2,
    # ... other settings
}

# Apply custom settings
for setting_name in custom_preset:
    if adaptive.settings_manager.available_settings.has(setting_name) and 
       adaptive.settings_manager.is_setting_applicable(setting_name):
        adaptive.settings_manager.available_settings[setting_name].current_index = custom_preset[setting_name]
        adaptive.settings_manager.apply_setting(setting_name)
```

## Demo Scene

The extension includes a demo scene that showcases the adaptive graphics system. To run it:

1. Open the project in Godot 4.4
2. Open the `demo/demo_scene.tscn` scene
3. Run the scene
4. Press F7 to toggle the settings UI
5. Press Space to spawn objects and stress the renderer
6. Press 1-5 to quickly switch between quality presets

## Requirements

- Godot 4.4 or higher
- Works with all rendering methods: Forward+, Mobile, and Compatibility

## License

This extension is released under the MIT License. See the LICENSE file for details.

## Credits

Developed by Smart Graphics Team

## Support

For issues, feature requests, or questions, please open an issue on the GitHub repository.
