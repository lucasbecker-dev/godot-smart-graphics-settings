extends Resource

var screen_width: int = ProjectSettings.get_setting("display/window/size/width") setget set_screen_width
var screen_height: int = ProjectSettings.get_setting("display/window/size/height") setget set_screen_height
var screen_resolution := {
	"width": screen_width,
	"height": screen_height
} setget set_screen_resolution
var sharpen_intensity: float = ProjectSettings.get_setting("rendering/quality/filters/sharpen_intensity")
var anistropic_filter_level: int = ProjectSettings.get_setting("rendering/quality/filters/anisotropic_filter_level") setget set_anistropic_filter_level
var use_nearest_mipmap_filter: bool = ProjectSettings.get_setting("rendering/quality/filters/use_nearest_mipmap_filter")

func set_screen_width(width: int) -> void:
	screen_width = width
	screen_resolution.width = width

func set_screen_height(height: int) -> void:
	screen_height = height
	screen_resolution.height = height

func set_screen_resolution(width_and_height: Dictionary) -> void:
	set_screen_width(width_and_height.width)
	set_screen_height(width_and_height.height)

func set_anistropic_filter_level(level: int) -> bool:
	if is_power_of_two(level):
		ProjectSettings.set_setting("rendering/quality/filters/anisotropic_filter_level", level)
		return true
	return false

func is_power_of_two(num: int) -> bool:
	if num > 0 and num & (num - 1) == 0:
		return true
	return false
