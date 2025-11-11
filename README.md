<p align="center">
    <img src="addons/smart_graphics_settings/images/logo.svg" alt="Smart Graphics Settings" style="width: 100%"/>
</p>

# Smart Graphics Settings for Godot 4.5.1

A powerful adaptive graphics settings system for Godot 4.5.1 that automatically adjusts visual quality based on performance to maintain a smooth framerate.

## Release Version

This is the release branch of Smart Graphics Settings, containing only the addon files needed for use in your Godot projects. The current version is **0.1.1**.

## Installation

### Option 1: Godot Asset Library (Recommended)

1. Open your Godot project
2. Go to the AssetLib tab in the Godot editor
3. Search for "Smart Graphics Settings"
4. Download and install directly in the editor

### Option 2: Manual Installation

1. Download or clone this repository
2. Copy the `addons/smart_graphics_settings` folder into your Godot project's `addons` directory
3. Enable the plugin in Project Settings → Plugins

## Quick Start

1. Add the SmartGraphicsSettings node to your main scene or use the autoload singleton
2. Configure your desired target FPS and adjustment settings
3. Run your game - graphics will automatically adjust to maintain performance

## Access the SmartGraphicsSettings singleton directly

### Enable or disable adaptive graphics
SmartGraphicsSettings.set_enabled(true)

### Set target FPS
SmartGraphicsSettings.set_target_fps(60)

### Show the settings UI
SmartGraphicsSettings.toggle_ui()

## Important Note on Initialization

When accessing `SmartGraphicsSettings` properties like `adaptive_graphics` or calling functions like `set_target_fps` immediately in your script's `_ready()` function, you might encounter issues because the addon performs some initialization steps deferred (after `_ready()` has finished).

To ensure the system is fully initialized before you interact with it at startup, connect to the `SmartGraphicsSettings.initialized` signal:

```gdscript
func _ready():
	if SmartGraphicsSettings.get_adaptive_graphics(): # Check if already initialized
		_on_graphics_ready()
	else:
		SmartGraphicsSettings.initialized.connect(_on_graphics_ready)

func _on_graphics_ready():
	# Now it's safe to access SmartGraphicsSettings functions and properties
	print("Smart Graphics Settings Ready!")
	SmartGraphicsSettings.set_target_fps(90)
```

See the [technical documentation](addons/smart_graphics_settings/README.md#handling-initialization-timing) for more details.

## Public API Reference

The `SmartGraphicsSettings` autoload singleton provides the following methods and signals:

### Methods

| Method | Description |
| --- | --- |
| `toggle_ui()` | Toggles the visibility of the settings UI. |
| `show_ui()` | Shows the settings UI. |
| `hide_ui()` | Hides the settings UI. |
| `apply_preset(preset: AdaptiveGraphics.QualityPreset)` | Applies a quality preset (e.g., `ULTRA_LOW`, `LOW`, `MEDIUM`, `HIGH`, `ULTRA`). |
| `set_enabled(enabled: bool)` | Enables or disables the adaptive graphics system. |
| `set_target_fps(fps: int)` | Sets the target FPS for the adaptive system to maintain. |
| `get_average_fps() -> float` | Returns the current average FPS. |
| `is_fps_stable() -> bool` | Returns `true` if the FPS is currently stable. |
| `set_match_refresh_rate(enabled: bool)` | Sets whether the target FPS should automatically match the display's refresh rate. |
| `set_target_fps_to_refresh_rate()` | Immediately sets the target FPS to match the display's refresh rate. |
| `get_display_refresh_rate() -> float` | Returns the display's refresh rate in Hz. |
| `set_vsync_mode(mode: int)` | Sets the VSync mode (see `DisplayServer` VSync constants). |
| `get_vsync_mode() -> int` | Returns the current VSync mode. |
| `get_status_info() -> Dictionary` | Returns a dictionary with detailed information about the current state of the system. |
| `get_adaptive_graphics() -> AdaptiveGraphics` | Returns the underlying `AdaptiveGraphics` node. |

### Signals

| Signal | Description |
| --- | --- |
| `initialized` | Emitted when the `AdaptiveGraphics` node has been fully initialized and it's safe to interact with the system. |

## Demo

A demo scene is included to showcase the functionality. Open `addons/smart_graphics_settings/demo/demo_scene.tscn` to try it out.

## Documentation

For detailed documentation on all features and configuration options, see the [README](addons/smart_graphics_settings/README.md) in the addon directory.

## Demo

A demo scene is included to showcase the functionality. Open `addons/smart_graphics_settings/demo/demo_scene.tscn` to try it out. For more information about the demo, see the [Demo README](addons/smart_graphics_settings/demo/README.md).

## License

This project is licensed under the MIT License - see the [LICENSE](addons/smart_graphics_settings/LICENSE) file for details.

## Credits

Created by Lucas Becker. Open to community-submitted issues and pull requests.

## Support

If you find this plugin useful, please consider:

- Starring the repository on GitHub
- Contributing to the project
- Reporting any issues you encounter

## Contact

Created by [Lucas Becker](https://github.com/lucasbecker-dev)
