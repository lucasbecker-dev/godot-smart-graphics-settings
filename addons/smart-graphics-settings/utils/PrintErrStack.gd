extends RefCounted


func _init(error_string: String):
	PrintErrStack(error_string)


static func PrintErrStack(error_string: String) -> void:
	printerr(error_string)
	print_stack()
