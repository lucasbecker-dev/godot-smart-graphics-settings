# Smart Graphics Settings for Godot 3

When enabled, this addon will dynamically adjust the user's graphics settings until a stable target FPS is reached. It will adjust a few quality settings up or down, wait until the FPS stabilizes, and then check to see if the new FPS matches the target value.

## Installation

After cloning this repo into your base project folder, simply add the new SmartGraphicsSettings node somewhere in your scene tree or add it as an autoload singleton.

## Options

On selecting the SmartGraphicsSettings Node in the editor, you'll see a few options appear in the inspector.

### Target FPS

This is the FPS value the addon will attempt to target.

### Environment

This is the Environment or WorldEnvironment which contains the graphics settings to adjust. It gets the default environment from your project settings automatically, but you can change it to an other Environment/WorldEnvironment, if needed.
