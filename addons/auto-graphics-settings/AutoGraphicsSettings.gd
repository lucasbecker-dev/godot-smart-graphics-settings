extends Node

export(int, 500) var target_fps := 60
export(Environment) var environment = ProjectSettings.get("rendering/environment/default_environment")

onready var _mutex := Mutex.new()
onready var _thread := Thread.new()

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	print_debug("target_fps: ", target_fps, "\nenvironment: ", environment)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
