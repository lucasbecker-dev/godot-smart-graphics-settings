extends Resource

var utils := preload("res://addons/smart-graphics-settings/utils/Utils.gd").new()
var screen_width: int = ProjectSettings.get_setting("display/window/size/width") setget set_screen_width
var screen_height: int = ProjectSettings.get_setting("display/window/size/height") setget set_screen_height
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
var cubemap_size: int = ProjectSettings.get_setting("rendering/quality/shadow_atlas/cubemap_size") setget set_cubemap_size
var shadow_filter_mode: int = ProjectSettings.get_setting("rendering/quality/shadows/filter_mode") setget set_shadow_filter_mode
var shadow_filter_mode_mobile: int = ProjectSettings.get_setting(
	"rendering/quality/shadows/filter_mode.mobile"
) setget set_shadow_filter_mode_mobile
var texture_array_reflections: bool = ProjectSettings.get_setting(
	"rendering/quality/reflections/texture_array_reflections"
) setget set_texture_array_reflections
var texture_array_reflections_mobile: bool = ProjectSettings.get_setting(
	"rendering/quality/reflections/texture_array_reflections.mobile"
) setget set_texture_array_reflections_mobile
var high_quality_ggx: bool = ProjectSettings.get_setting(
	"rendering/quality/reflections/high_quality_ggx"
) setget set_high_quality_ggx
var high_quality_ggx_mobile: bool = ProjectSettings.get_setting(
	"rendering/quality/reflections/high_quality_ggx.mobile"
) setget set_high_quality_ggx_mobile
var atlas_size: int = ProjectSettings.get_setting("rendering/quality/reflections/atlas_size") setget set_atlas_size
var atlas_subdiv: int = ProjectSettings.get_setting("rendering/quality/reflections/atlas_subdiv") setget set_atlas_subdiv
var force_vertex_shading: bool = ProjectSettings.get_setting(
	"rendering/quality/shading/force_vertex_shading"
) setget set_force_vertex_shading
var force_vertex_shading_mobile: bool = ProjectSettings.get_setting(
	"rendering/quality/shading/force_vertex_shading.mobile"
) setget set_force_vertex_shading_mobile
var force_lambert_over_burley: bool = ProjectSettings.get_setting(
	"rendering/quality/shading/force_lambert_over_burley"
) setget set_force_lambert_over_burley
var force_lambert_over_burley_mobile: bool = ProjectSettings.get_setting(
	"rendering/quality/shading/force_lambert_over_burley.mobile"
) setget set_force_lambert_over_burley_mobile
var force_blinn_over_ggx: bool = ProjectSettings.get_setting(
	"rendering/quality/shading/force_blinn_over_ggx"
) setget set_force_blinn_over_ggx
var force_blinn_over_ggx_mobile: bool = ProjectSettings.get_setting(
	"rendering/quality/shading/force_blinn_over_ggx.mobile"
) setget set_force_blinn_over_ggx_mobile
var subsurface_scattering_quality: int = ProjectSettings.get_setting(
	"rendering/quality/subsurface_scattering/quality"
) setget set_subsurface_scattering_quality
var subsurface_scattering_scale: int = ProjectSettings.get_setting(
	"rendering/quality/subsurface_scattering/scale"
) setget set_subsurface_scattering_scale
var subsurface_scattering_follow_surface: bool = ProjectSettings.get_setting(
	"rendering/quality/subsurface_scattering/follow_surface"
) setget set_subsurface_scattering_follow_surface
var subsurface_scattering_weight_samples: bool = ProjectSettings.get_setting(
	"rendering/quality/subsurface_scattering/weight_samples"
) setget set_subsurface_scattering_weight_samples
var voxel_cone_tracing_high_quality: bool = ProjectSettings.get_setting(
	"rendering/quality/voxel_cone_tracing/high_quality"
) setget set_voxel_cone_tracing_high_quality
var use_physical_light_attenuation: bool = ProjectSettings.get_setting(
	"rendering/quality/shading/use_physical_light_attenuation"
) setget set_use_physical_light_attenuation
var _screen_resolution := {"width": screen_width, "height": screen_height} setget _private_screen_res_setter, _private_screen_res_getter


func set_screen_width(width: int) -> void:
	if width >= 0:
		screen_width = _update_setting("display/window/size/width", width)
		_screen_resolution.width = screen_width


func set_screen_height(height: int) -> void:
	if height >= 0:
		screen_height = _update_setting("display/window/size/height", height)
		_screen_resolution.height = screen_height


func set_screen_resolution(width: int = -1, height: int = -1) -> void:
	if width > -1:
		set_screen_width(width)
	if height > -1:
		set_screen_height(height)


func get_screen_resolution() -> Dictionary:
	return _screen_resolution


func set_anistropic_filter_level(level: int) -> void:
	if level <= 16 and utils.is_power_of_two(level):
		anistropic_filter_level = _update_setting(
			"rendering/quality/filters/anisotropic_filter_level", level
		)
		return
	printerr("ERROR: Anistropic filter level must be one of the following values: 2, 4, 8, 16")


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


func set_cubemap_size(size: int) -> void:
	cubemap_size = _update_setting("rendering/quality/shadow_atlas/cubemap_size", size)


func set_shadow_filter_mode(setting: int) -> void:
	shadow_filter_mode = _update_setting("rendering/quality/shadows/filter_mode", setting)


func set_shadow_filter_mode_mobile(setting: int) -> void:
	shadow_filter_mode_mobile = _update_setting(
		"rendering/quality/shadows/filter_mode.mobile", setting
	)


func set_texture_array_reflections(enabled: bool) -> void:
	texture_array_reflections = _update_setting(
		"rendering/quality/reflections/texture_array_reflections", enabled
	)


func set_texture_array_reflections_mobile(enabled: bool) -> void:
	texture_array_reflections_mobile = _update_setting(
		"rendering/quality/reflections/texture_array_reflections.mobile", enabled
	)


func set_high_quality_ggx(enabled: bool) -> void:
	high_quality_ggx = _update_setting("rendering/quality/reflections/high_quality_ggx", enabled)


func set_high_quality_ggx_mobile(enabled: bool) -> void:
	high_quality_ggx_mobile = _update_setting(
		"rendering/quality/reflections/high_quality_ggx.mobile", enabled
	)


func set_atlas_size(size: int) -> void:
	atlas_size = _update_setting("rendering/quality/reflections/atlas_size", size)


func set_atlas_subdiv(num: int) -> void:
	atlas_subdiv = _update_setting("rendering/quality/reflections/atlas_subdiv", num)


func set_force_vertex_shading(enabled: bool) -> void:
	force_vertex_shading = _update_setting(
		"rendering/quality/shading/force_vertex_shading", enabled
	)


func set_force_vertex_shading_mobile(enabled: bool) -> void:
	force_vertex_shading_mobile = _update_setting(
		"rendering/quality/shading/force_vertex_shading.mobile", enabled
	)


func set_force_lambert_over_burley(enabled: bool) -> void:
	force_lambert_over_burley = _update_setting(
		"rendering/quality/shading/force_lambert_over_burley", enabled
	)


func set_force_lambert_over_burley_mobile(enabled: bool) -> void:
	force_lambert_over_burley_mobile = _update_setting(
		"rendering/quality/shading/force_lambert_over_burley.mobile", enabled
	)


func set_force_blinn_over_ggx(enabled: bool) -> void:
	force_blinn_over_ggx = _update_setting(
		"rendering/quality/shading/force_blinn_over_ggx", enabled
	)


func set_force_blinn_over_ggx_mobile(enabled: bool) -> void:
	force_blinn_over_ggx_mobile = _update_setting(
		"rendering/quality/shading/force_blinn_over_ggx.mobile", enabled
	)


func set_use_physical_light_attenuation(enabled: bool) -> void:
	use_physical_light_attenuation = _update_setting(
		"rendering/quality/shading/use_physical_light_attenuation", enabled
	)


func set_subsurface_scattering_quality(setting: int) -> void:
	subsurface_scattering_quality = _update_setting(
		"rendering/quality/subsurface_scattering/quality", setting
	)


func set_subsurface_scattering_scale(scale: int) -> void:
	subsurface_scattering_scale = _update_setting(
		"rendering/quality/subsurface_scattering/scale", scale
	)


func set_subsurface_scattering_follow_surface(enabled: bool) -> void:
	subsurface_scattering_follow_surface = _update_setting(
		"rendering/quality/subsurface_scattering/follow_surface", enabled
	)


func set_subsurface_scattering_weight_samples(enabled: bool) -> void:
	subsurface_scattering_weight_samples = _update_setting(
		"rendering/quality/subsurface_scattering/weight_samples", enabled
	)


func set_voxel_cone_tracing_high_quality(enabled: bool) -> void:
	voxel_cone_tracing_high_quality = _update_setting(
		"rendering/quality/voxel_cone_tracing/high_quality", enabled
	)


func _private_screen_res_setter(param) -> void:
	printerr(
		"ERROR: cannot assign directly to private field _screen_resolution. Use set_screen_resolution() instead."
	)
	print_stack()


func _private_screen_res_getter() -> Dictionary:
	printerr(
		"ERROR: cannot assign directly to private field _screen_resolution. Use get_screen_resolution() instead."
	)
	print_stack()
	return {}


func _update_setting(setting: String, new_value):
	if ProjectSettings.has_setting(setting):
		if typeof(new_value) == typeof(ProjectSettings.get_setting(setting)):
			ProjectSettings.set_setting(setting, new_value)
			if ProjectSettings.get_setting(setting) == new_value:
				return ProjectSettings.get_setting(setting)
			printerr(
				'Invalid value for "', setting, '" - Please refer to the docs for possible values.'
			)
			print_stack()
			return
		printerr(
			'ERROR: Invalid type for "',
			setting,
			'" - Passed type: ',
			typeof(new_value),
			"Required type: ",
			typeof(ProjectSettings.get_setting(setting))
		)
		print_stack()
		return
	printerr("ERROR: Invalid setting string. Passed value: ", setting)
	print_stack()
