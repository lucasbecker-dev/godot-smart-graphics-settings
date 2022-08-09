extends Resource

var _states: Array setget set_states, get_states
var _current_state: Resource setget set_current_state, get_current_state
var _state_class := preload("res://addons/smart-graphics-settings/states/State.gd")


func _init(states: Array) -> void:
	set_states(states)


func process_execute() -> void:
	_current_state.process_execute


func physics_process_execute() -> void:
	_current_state.physics_process_execute


func set_states(states: Array) -> void:
	for state in states:
		if state is _state_class:
			continue
		else:
			printerr("ERROR: Passed in state values must inherit from State")
			print_stack()
			return
	_states = states


func get_states() -> Array:
	return _states


func add_state(state: Resource) -> void:
	if !(state is _state_class):
		printerr("ERROR: ", state, " is not a State.")
		print_stack()
		return
	if state in _states:
		printerr("ERROR: State ", state, " is already in StateMachine ", self)
		print_stack()
		return


func remove_state(state: Resource) -> void:
	if !(state is _state_class):
		printerr("ERROR: ", state, " is not a State.")
		print_stack()
		return
	if !(state in _states):
		printerr("ERROR: State ", state, " was not found in in StateMachine ", self)
		print_stack()
		return


func set_current_state(state: Resource) -> void:
	if !(state is _state_class):
		printerr("ERROR: ", state, " is not a State.")
		print_stack()
		return
	if !(state in _states):
		printerr("ERROR: State ", state, " was not found in in StateMachine ", self)
		print_stack()
		return
	_current_state = state


func get_current_state() -> Resource:
	return _current_state
