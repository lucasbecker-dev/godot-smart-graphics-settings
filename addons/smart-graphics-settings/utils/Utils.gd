extends Resource


static func is_power_of_two(num: int) -> bool:
	if num > 0 and num & (num - 1) == 0:
		return true
	return false
