extends Resource


static func is_power_of_two(num: int) -> bool:
	return num > 2 and num & (num - 1) == 0


static func get_default_environment() -> Object:
	var default_environment_path: String = ProjectSettings.get_setting(
		"rendering/environment/default_environment"
	)
	if !default_environment_path.empty():
		var default_environment: Environment = load(default_environment_path)
		return default_environment
	return null


static func convert_setting_to_docs_webpage(setting: String) -> String:
	if ProjectSettings.has_setting(setting):
		# TODO: support multiple languages if this ends up being useful
		return String(
			(
				"https://docs.godotengine.org/en/stable/classes/class_projectsettings.html?highlight=projectsettings#class-projectsettings-property-"
				+ setting.replace("/", "-")
			)
		)
	printerr(
		"ERROR: Invalid setting string passed to convert_setting_to_docs_webpage\n",
		"Passed string: ",
		setting
	)
	print_stack()
	return ""
