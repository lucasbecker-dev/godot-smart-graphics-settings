extends Resource

var screen_width: int = ProjectSettings.get_setting("display/window/size/width") setget set_screen_width
var screen_height: int = ProjectSettings.get_setting("display/window/size/height") setget set_screen_height
var _screen_resolution := {"width": screen_width, "height": screen_height} setget private_screen_res_setter, private_screen_res_getter
var sharpen_intensity: float = ProjectSettings.get_setting(
	"rendering/quality/filters/sharpen_intensity"
)
var anistropic_filter_level: int = ProjectSettings.get_setting(
	"rendering/quality/filters/anisotropic_filter_level"
) setget set_anistropic_filter_level
var use_nearest_mipmap_filter: bool = ProjectSettings.get_setting(
	"rendering/quality/filters/use_nearest_mipmap_filter"
)
var msaa: int = ProjectSettings.get_setting("rendering/quality/filters/msaa") setget set_msaa
var fxaa: bool = ProjectSettings.get_setting("rendering/quality/filters/use_fxaa") setget set_fxaa
var debanding: bool = ProjectSettings.get_setting("rendering/quality/filters/use_debanding") setget set_debanding
var directional_shadow_size: int = ProjectSettings.get_setting(
	"rendering/quality/directional_shadow/size"
) setget set_directional_shadow_size
var directional_shadow_size_mobile: int = ProjectSettings.get_setting(
	"rendering/quality/directional_shadow/size.mobile"
) setget set_directional_shadow_size_mobile


func set_screen_width(width: int) -> void:
	if width >= 0:
		ProjectSettings.set_setting("display/window/size/width", width)
		screen_width = ProjectSettings.get_setting("display/window/size/width")
		_screen_resolution.width = screen_width


func set_screen_height(height: int) -> void:
	if height >= 0:
		ProjectSettings.set_setting("display/window/size/height", height)
		screen_height = ProjectSettings.get_setting("display/window/size/height")
		_screen_resolution.height = screen_height


func set_screen_resolution(width: int, height: int) -> void:
	set_screen_width(width)
	set_screen_height(height)


func get_screen_resolution() -> Dictionary:
	return _screen_resolution


func private_screen_res_setter(param) -> void:
	printerr(
		"Error: cannot assign directly to private field _screen_resolution. Use set_screen_resolution() instead."
	)


func private_screen_res_getter() -> Dictionary:
	printerr(
		"Error: cannot assign directly to private field _screen_resolution. Use set_screen_resolution() instead."
	)
	return {}


func set_anistropic_filter_level(level: int) -> void:
	if level <= 16 and _is_power_of_two(level):
		ProjectSettings.set_setting("rendering/quality/filters/anisotropic_filter_level", level)
		anistropic_filter_level = ProjectSettings.get_setting(
			"rendering/quality/filters/anisotropic_filter_level"
		)
		return
	printerr("Error: Anistropic filter level must be one of the following values: 2, 4, 8, 16")


func set_msaa(sample_count: int) -> void:
	ProjectSettings.set_setting("rendering/quality/filters/msaa", sample_count)
	msaa = ProjectSettings.get_setting("rendering/quality/filters/msaa")


func set_fxaa(enabled: bool) -> void:
	ProjectSettings.set_setting("rendering/quality/filters/use_fxaa", enabled)
	fxaa = ProjectSettings.get_setting("rendering/quality/filters/use_fxaa")


func set_debanding(enabled: bool) -> void:
	ProjectSettings.set_setting("rendering/quality/filters/use_debanding", enabled)
	debanding = ProjectSettings.get_setting("rendering/quality/filters/use_debanding")


func set_directional_shadow_size(size: int) -> void:
	ProjectSettings.set_setting("rendering/quality/directional_shadow/size", size)
	directional_shadow_size = ProjectSettings.get_setting(
		"rendering/quality/directional_shadow/size"
	)


func set_directional_shadow_size_mobile(size: int) -> void:
	ProjectSettings.set_setting("rendering/quality/directional_shadow/size.mobile", size)
	directional_shadow_size = ProjectSettings.get_setting(
		"rendering/quality/directional_shadow/size.mobile"
	)


func _update_setting(setting: String, new_value) -> void:
	if ProjectSettings.has_setting(setting):
		if typeof(new_value) is ProjectSettings.get_setting(setting):
			ProjectSettings.set_setting(setting, new_value)
			return
		printerr(
			"ERROR: Invalid type for this setting. Passed type: ",
			typeof(new_value),
			"Required type: ",
			typeof(ProjectSettings.get_setting(setting))
		)
		print_stack()
	printerr("ERROR: Invalid setting string. Passed value: ", setting)
	print_stack()


func _is_power_of_two(num: int) -> bool:
	if num > 0 and num & (num - 1) == 0:
		return true
	return false
