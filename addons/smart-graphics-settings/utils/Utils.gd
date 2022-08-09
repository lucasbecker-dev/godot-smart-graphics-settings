extends Resource


func is_power_of_two(num: int) -> bool:
	if num > 0 and num & (num - 1) == 0:
		return true
	return false


func convert_setting_to_docs_webpage(setting: String) -> String:
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
