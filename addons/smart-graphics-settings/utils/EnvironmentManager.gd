extends Resource

var utils := preload("res://addons/smart-graphics-settings/utils/Utils.gd").new()
var environments: Array setget set_environments


func _init() -> void:
	var default_environment = utils.get_default_environment()
	if default_environment != null:
		# ensure default env is first in the environments list
		while default_environment in environments:
			environments.erase(default_environment)
		environments.push_front(default_environment)


func add_environment(env: Environment) -> void:
	if env in environments:
		printerr("ERROR: environment ", env, " is already in environments list: ", environments)
		print_stack()
		return
	environments.append(env)


func remove_environment(env: Environment) -> void:
	if env in environments:
		while env in environments:
			environments.erase(env)
		return
	printerr("ERROR: environment ", env, " was not found in environments list: ", environments)
	print_stack()


func set_environments(new_environments: Array) -> void:
	for env in new_environments:
		if env is Environment:
			continue
		printerr("ERROR: assigning non-Environment data to environments array")
		print_stack()
		return
	environments = new_environments
	print_debug(environments)
