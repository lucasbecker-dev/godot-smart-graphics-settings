# Smart Graphics Settings for Godot 4.4

<p align="center">
    <img src="addons/smart_graphics_settings/images/logo.svg" alt="Smart Graphics Settings" />
</p>

A powerful adaptive graphics settings system for Godot 4.4 that automatically adjusts visual quality based on performance to maintain a smooth framerate.

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

## Features

- **Adaptive Quality**: Automatically adjusts graphics settings to maintain target FPS
- **Comprehensive Settings Management**: Controls render scale, anti-aliasing, shadows, reflections, and more
- **User-friendly UI**: Built-in settings panel for players to customize their experience
- **Performance Monitoring**: Real-time FPS tracking and performance analysis
- **Platform-specific Optimizations**: Detects and applies optimal settings for different devices
- **Fully Customizable**: Extensive configuration options for developers

## Documentation

For detailed documentation on all features and configuration options, see the [README](addons/smart_graphics_settings/README.md) in the addon directory.

## Demo

A demo scene is included to showcase the functionality. Open `addons/smart_graphics_settings/demo/demo_scene.tscn` to try it out. For more information about the demo, see the [Demo README](addons/smart_graphics_settings/demo/README.md).

## License

This project is licensed under the MIT License - see the [LICENSE](addons/smart_graphics_settings/LICENSE) file for details.

## Contributing

Contributions are welcome! If you'd like to help improve Smart Graphics Settings:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Support

If you find this plugin useful, please consider:

- Starring the repository on GitHub
- Contributing to the project
- Reporting any issues you encounter

## Contact

Created by [Lucas Becker](https://github.com/lucasbecker-dev)
