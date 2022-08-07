extends Resource

var utils := preload("res://addons/smart-graphics-settings/utils/Utils.gd").new()
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
		screen_width = _update_setting("display/window/size/width", width)
		_screen_resolution.width = screen_width


func set_screen_height(height: int) -> void:
	if height >= 0:
		screen_height = _update_setting("display/window/size/height", height)
		_screen_resolution.height = screen_height


func set_screen_resolution(width: int = -1, height: int = -1) -> void:
	if width != -1:
		set_screen_width(width)
	if height != -1:
		set_screen_height(height)


func get_screen_resolution() -> Dictionary:
	return _screen_resolution


func private_screen_res_setter(param) -> void:
	printerr(
		"Error: cannot assign directly to private field _screen_resolution. Use set_screen_resolution() instead."
	)
	print_stack()


func private_screen_res_getter() -> Dictionary:
	printerr(
		"Error: cannot assign directly to private field _screen_resolution. Use get_screen_resolution() instead."
	)
	print_stack()
	return {}


func set_anistropic_filter_level(level: int) -> void:
	if level <= 16 and utils.is_power_of_two(level):
		anistropic_filter_level = _update_setting(
			"rendering/quality/filters/anisotropic_filter_level", level
		)
		return
	printerr("Error: Anistropic filter level must be one of the following values: 2, 4, 8, 16")


func set_msaa(sample_count: int) -> void:
	msaa = _update_setting("rendering/quality/filters/msaa", sample_count)


func set_fxaa(enabled: bool) -> void:
	fxaa = _update_setting("rendering/quality/filters/use_fxaa", enabled)


func set_debanding(enabled: bool) -> void:
	debanding = _update_setting("rendering/quality/filters/use_debanding", enabled)


func set_directional_shadow_size(size: int) -> void:
	directional_shadow_size = _update_setting("rendering/quality/directional_shadow/size", size)


func set_directional_shadow_size_mobile(size: int) -> void:
	directional_shadow_size_mobile = _update_setting(
		"rendering/quality/directional_shadow/size.mobile", size
	)


func _update_setting(setting: String, new_value):
	if ProjectSettings.has_setting(setting):
		if typeof(new_value) is ProjectSettings.get_setting(setting):
			ProjectSettings.set_setting(setting, new_value)
			return ProjectSettings.get_setting(setting)
		printerr(
			"ERROR: Invalid type for this setting. Passed type: ",
			typeof(new_value),
			"Required type: ",
			typeof(ProjectSettings.get_setting(setting))
		)
		print_stack()
		return
	printerr("ERROR: Invalid setting string. Passed value: ", setting)
	print_stack()
