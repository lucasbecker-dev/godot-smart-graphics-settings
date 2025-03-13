# Smart Graphics Settings Demo (v0.1.1)

This demo scene showcases the functionality of the Smart Graphics Settings addon for Godot 4.4. It provides a practical example of how the adaptive graphics system works in a real-world scenario.

## Getting Started

1. Open the demo scene: `addons/smart_graphics_settings/demo/demo_scene.tscn`
2. Run the scene to see the adaptive graphics in action
3. Use the keyboard shortcuts to interact with the demo

## Demo Features

The demo includes:

- A 3D environment with dynamic lighting and shadows
- Stress testing capabilities to simulate different performance scenarios
- Real-time FPS display and performance metrics
- UI for adjusting and monitoring graphics settings

## Controls

| Key | Action |
|-----|--------|
| F7 | Toggle graphics settings UI |
| 1-5 | Apply quality presets (1=Low, 5=Ultra) |
| Space | Spawn stress test objects |
| Esc | Clear stress test objects |

## Stress Testing

The demo includes a stress test feature that allows you to spawn multiple 3D objects to test how the adaptive graphics system responds to changing performance conditions:

1. Press Space to spawn a batch of objects (default: 100 objects per batch)
2. Observe how the FPS drops and the adaptive graphics system automatically adjusts settings
3. Press Esc to clear all stress test objects

## Quality Presets

The demo includes 5 quality presets that you can apply using the number keys 1-5:

1. **Low**: Optimized for low-end hardware
2. **Medium**: Balanced performance and quality
3. **High**: Good visual quality with reasonable performance
4. **Ultra**: Maximum visual quality
5. **Custom**: User-defined settings

## Customizing the Demo

You can modify the demo scene to test different scenarios:

### Changing the Stress Test Parameters

Open `demo_scene.gd` and modify the following variables:

```gdscript
# Number of objects to spawn per batch
var spawn_count: int = 100

# Change this to adjust the types of meshes used in the stress test
func _ready() -> void:
    # Initialize mesh types
    mesh_types.append(BoxMesh.new())
    mesh_types.append(SphereMesh.new())
    mesh_types.append(TorusMesh.new())
    mesh_types.append(CylinderMesh.new())
```

### Testing Different Environments

The demo scene uses a standard 3D environment, but you can modify it to test specific rendering features:

1. Add more complex geometry to test geometry-heavy scenes
2. Add more lights to test lighting performance
3. Add reflective surfaces to test reflection performance
4. Add transparent materials to test transparency performance

## Performance Analysis

The demo includes real-time performance metrics that help you understand how the adaptive graphics system is working:

1. **FPS Counter**: Shows the current framerate
2. **Settings Display**: Shows which settings are currently active
3. **Adjustment Status**: Indicates when the system is measuring or adjusting settings

## Troubleshooting

If you encounter issues with the demo:

- Make sure the plugin is properly installed and enabled
- Check that the SmartGraphicsSettings singleton is available
- Verify that your Godot version is 4.4 or later
- Check the console for any error messages

## Next Steps

After exploring the demo, you can:

1. Integrate the Smart Graphics Settings into your own project
2. Customize the settings and presets to match your game's requirements
3. Extend the system with custom settings specific to your game

For more information, refer to the [main documentation](../README.md).
