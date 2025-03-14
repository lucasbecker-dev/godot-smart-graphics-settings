<p align="center">
    <img src="addons/smart_graphics_settings/images/logo.svg" alt="Smart Graphics Settings" style="width: 100%"/>
</p>

# Smart Graphics Settings for Godot 4.4

A powerful adaptive graphics settings system for Godot 4.4 that automatically adjusts visual quality based on performance to maintain a smooth framerate.

## Features

- **Adaptive Quality**: Automatically adjusts graphics settings to maintain target FPS
- **Comprehensive Settings Management**: Controls render scale, anti-aliasing, shadows, reflections, and more
- **User-friendly UI**: Built-in settings panel for players to customize their experience
- **Performance Monitoring**: Real-time FPS tracking and performance analysis
- **Platform-specific Optimizations**: Detects and applies optimal settings for different devices
- **Fully Customizable**: Extensive configuration options for developers

## Installation

1. Download or clone this repository
2. Copy the `addons/smart_graphics_settings` folder into your Godot project's `addons` directory
3. Enable the plugin in Project Settings → Plugins

## Quick Start

1. Add the SmartGraphicsSettings node to your main scene or use the autoload singleton
2. Configure your desired target FPS and adjustment settings
3. Run your game - graphics will automatically adjust to maintain performance

```gdscript
# Access the SmartGraphicsSettings singleton directly
# No need for get_node() as it's registered as an autoload

# Enable or disable adaptive graphics
SmartGraphicsSettings.adaptive_graphics.enabled = true

# Set target FPS
SmartGraphicsSettings.adaptive_graphics.target_fps = 60

# Show the settings UI
SmartGraphicsSettings.toggle_ui()
```

## Demo

A demo scene is included to showcase the functionality. Open `addons/smart_graphics_settings/demo/demo_scene.tscn` to try it out.

## Documentation

For detailed documentation on all features and configuration options, see the [README](addons/smart_graphics_settings/README.md) in the addon directory.

## License

This project is licensed under the MIT License - see the [LICENSE](addons/smart_graphics_settings/LICENSE) file for details.

## Credits

Created by Lucas Becker. Open to community-submitted issues and pull requests.

## Support

If you find this plugin useful, please consider:

- Starring the repository on GitHub
- Contributing to the project
- Reporting any issues you encounter
