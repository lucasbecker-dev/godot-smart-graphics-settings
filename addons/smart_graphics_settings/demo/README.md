# Smart Graphics Settings Demo

This demo showcases the Smart Graphics Settings extension for Godot 4.4.

## Running the Demo

1. Open the project in Godot 4.4
2. Open the `demo_scene.tscn` scene
3. Run the scene

## Controls

- Press **F7** to toggle the settings UI
- Press **1-5** to quickly switch between quality presets (1=Ultra Low, 5=Ultra)
- Press **Space** to spawn objects and stress the renderer

## What to Observe

- Watch how the FPS changes as you add more objects with Space
- Notice how the system automatically adjusts graphics settings to maintain performance
- Try different quality presets to see their impact on visual quality and performance

## Integration Example

This demo shows how to integrate Smart Graphics Settings into your own projects. The key components are:

1. Adding the autoload singleton in your project settings
2. Using the SmartGraphicsSettings API to control quality settings
3. Providing UI controls for players to customize their experience
