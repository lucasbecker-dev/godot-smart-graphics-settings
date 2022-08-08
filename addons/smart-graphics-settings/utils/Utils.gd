extends Resource


func is_power_of_two(num: int) -> bool:
	if num > 0 and num & (num - 1) == 0:
		return true
	return false


func convert_to_docs_page(setting: String) -> String:
	return String(
		(
			"https://docs.godotengine.org/en/stable/classes/class_projectsettings.html?highlight=projectsettings#class-projectsettings-property-"
			+ setting.replace("/", "-")
		)
	)
