extends Resource

var _states: Array : get = get_states
var _current_state: Resource : get = get_current_state, set = set_current_state
var _state_class := preload("res://addons/smart-graphics-settings/states/State.gd")

signal states_list_changed(states_list)
signal current_state_changed(current_state)


func _init(states: Array,current_state: Resource):
	set_states(states, current_state)


func process_execute() -> void:
	if _current_state_exists():
		_current_state.process_execute
	else:
		printerr(
			"ERROR: StateMachine ",
			self,
			" does not have a current state, and thus cannot execute process logic. Set one before use with set_current_state()."
		)
		print_stack()


func physics_process_execute() -> void:
	if _current_state_exists():
		_current_state.physics_process_execute
	else:
		printerr(
			"ERROR: StateMachine ",
			self,
			" does not have a current state, and thus cannot execute physics process logic. Set one before use with set_current_state()."
		)
		print_stack()


func set_states(states: Array, current_state: Resource) -> void:
	for state in _states:
		if state is _state_class:
			continue
		else:
			printerr("ERROR: Passed in state values must inherit from State")
			print_stack()
			return
	_states = states
	set_current_state(current_state)


func get_states() -> Array:
	return _states


func add_state(state: Resource, is_current_state: bool = false) -> void:
	if !(state is _state_class):
		printerr("ERROR: ", state, " is not a State.")
		print_stack()
		return
	if state in _states:
		printerr("ERROR: State ", state, " is already in StateMachine ", self)
		print_stack()
		return
	_states.push_back(state)
	if is_current_state:
		set_current_state(state)


func remove_state(state: Resource) -> void:
	if !(state is _state_class):
		printerr("ERROR: ", state, " is not a State.")
		print_stack()
		return
	if !(state in _states):
		printerr("ERROR: State ", state, " was not found in in StateMachine ", self)
		print_stack()
		return
	if state == _current_state:
		set_current_state(null)
		printerr(
			"ERROR: Removed state ",
			state,
			" from StateMachine ",
			self,
			", which was the StateMachine's current state."
		)
	while state in _states:
		_states.erase(state)


func set_current_state(state: Resource) -> void:
	if state == null:
		_current_state = null
		emit_signal("state_changed", null)
		return
	if !(state is _state_class):
		printerr("ERROR: ", state, " is not a State.")
		print_stack()
		return
	if !(state in _states):
		printerr("ERROR: State ", state, " was not found in in StateMachine ", self)
		print_stack()
		return
	_current_state = state
	emit_signal("state_changed", _current_state)


func get_current_state() -> Resource:
	return _current_state


func _current_state_exists() -> bool:
	return _current_state and _current_state in _states
