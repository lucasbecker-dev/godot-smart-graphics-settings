# Smart Graphics Settings Demo

This demo showcases the Smart Graphics Settings extension for Godot 4.4. It provides a simple 3D scene with various objects and a stress test feature to demonstrate how the adaptive graphics system automatically adjusts visual quality to maintain performance.

## Features

- **Basic 3D Scene**: Simple scene with various 3D primitives
- **Stress Test**: Press Space to spawn 100 additional objects to test performance adaptation
- **Quality Presets**: Press 1-5 to quickly switch between quality presets
- **Real-time Monitoring**: Displays current FPS, stability, and system status
- **Settings UI**: Press F7 to toggle the built-in settings panel

## How to Use

1. Open the demo scene in Godot 4.4
2. Run the scene
3. Press F7 to open the settings UI
4. Try different quality presets using the 1-5 keys
5. Press Space to add 100 more objects and stress the renderer
6. Watch how the system automatically adjusts settings to maintain performance

## Implementation Details

The demo scene demonstrates how to:

1. **Initialize the Smart Graphics Settings system**:

   ```gdscript
   # Get the SmartGraphicsSettings singleton
   settings = get_node("/root/SmartGraphicsSettings")
   ```

2. **Apply quality presets**:

   ```gdscript
   # Apply a quality preset (0=ULTRA_LOW, 4=ULTRA)
   settings.apply_preset(preset_index)
   ```

3. **Monitor performance**:

   ```gdscript
   # Get current performance metrics
   var avg_fps: float = settings.get_average_fps()
   var is_stable: bool = settings.is_fps_stable()
   ```

4. **Get detailed status information**:

   ```gdscript
   # Get comprehensive status information
   var info: Dictionary = settings.get_status_info()
   ```

5. **Show the settings UI**:

   ```gdscript
   # Show the built-in settings UI
   settings.show_ui()
   ```

## FPS Stability Indicator

The demo includes an improved FPS stability indicator that shows whether your frame rate is stable or unstable:

- **Stable**: Indicates that the FPS has low variance and is consistent
- **Unstable**: Indicates that the FPS is fluctuating significantly

The stability is determined using both variance and coefficient of variation (CV) calculations, which provide a more accurate representation of FPS stability across different frame rate ranges.

## Customizing the Demo

You can modify this demo to test different scenarios:

- Change the `spawn_count` variable to adjust how many objects are spawned at once
- Add more complex 3D models to increase rendering load
- Adjust the stress test to spawn different types of objects
- Modify the camera movement to test different viewing angles
- Add post-processing effects to test their performance impact

## Troubleshooting

If you encounter issues with the demo:

1. Make sure the Smart Graphics Settings plugin is enabled in Project Settings → Plugins
2. Check the console for any error messages
3. Verify that the SmartGraphicsSettings singleton is properly registered
4. Ensure your Godot version is 4.4 or higher
