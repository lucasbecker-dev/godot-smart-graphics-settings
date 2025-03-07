# Smart Graphics Settings for Godot 4.4

A powerful adaptive graphics settings system that automatically adjusts visual quality to maintain target performance in Godot 4.4 games and applications.

![Smart Graphics Settings](addons/smart_graphics_settings/smart-graphics-settings-icon.svg)

## Features

- **Automatic Performance Optimization**: Dynamically adjusts graphics settings to maintain your target FPS
- **Threaded Performance Analysis**: Uses a separate thread for performance monitoring to minimize gameplay impact
- **Cross-Platform Support**: Intelligently detects threading support with automatic fallback mechanisms
- **Quality Presets**: Includes Ultra Low, Low, Medium, High, and Ultra presets for quick configuration
- **Complete Settings UI**: Ready-to-use settings panel with performance monitoring
- **Prioritized Adjustments**: Intelligently adjusts settings with minimal visual impact first
- **Persistent Settings**: Automatically saves and loads user preferences
- **VSync Management**: Automatically detects and manages VSync modes
- **Refresh Rate Detection**: Can automatically match target FPS to display refresh rate
- **Multi-Renderer Support**: Works with all Godot 4.4 renderers (Forward+, Mobile, and Compatibility)

## Installation

1. Copy the `addons/smart_graphics_settings` folder into your project's `addons` directory
2. Enable the plugin in Project Settings → Plugins
3. The `SmartGraphicsSettings` singleton will be automatically added to your project

## Quick Start

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

# Match target FPS to display refresh rate
settings.set_match_refresh_rate(true)
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
- Set target FPS or match to display refresh rate
- Configure VSync settings
- Enable/disable adaptive graphics
- Allow quality increases when performance is good
- Enable/disable threading
- Select quality presets
- Adjust individual graphics settings

## Threading Support

The extension includes robust threading support:

- Automatically detects platform capabilities for threading
- Provides detailed feedback in the UI about threading status
- Falls back gracefully to single-threaded mode when needed
- Includes comprehensive documentation in `THREADING_SUPPORT.md`

## Demo Scene

The extension includes a demo scene that showcases the adaptive graphics system. To run it:

1. Open the project in the demo directory in Godot 4.4
2. Open the `addons/smart_graphics_settings/demo/demo_scene.tscn` scene
3. Run the scene
4. Press F7 to toggle the settings UI
5. Press Space to spawn objects and stress the renderer
6. Press 1-5 to quickly switch between quality presets

## Requirements

- Godot 4.4 or higher
- Works with all rendering methods: Forward+, Mobile, and Compatibility

## License

This extension is released under the MIT License. See the LICENSE file for details.

## Documentation

For detailed usage instructions, see the `README.md` file in the addon directory.

## Support

For issues, feature requests, or questions, please open an issue on the GitHub repository.
