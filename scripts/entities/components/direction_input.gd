class_name DirectionInput
extends Node
## Turns the move keys into grid steps (including diagonals) and the wait key into waits.
## - Pressing two keys together (within `chord_window`) gives a diagonal step.
## - Holding keys repeats steps at a steady pace (we don't rely on OS key-repeat).
## Emits `step_requested`; the owner decides whether the step is legal.

## Emitted when the player wants to step one tile in `dir` (each axis -1, 0 or 1).
signal step_requested(dir: Vector2i)
## Emitted when the player wants to wait a turn (repeats while the key is held).
signal wait_requested

## Seconds to wait after a key press for a second key, so two keys = one diagonal step.
@export_range(0.0, 0.2) var chord_window: float = 0.06
## Seconds a key must be held before steps start repeating.
@export_range(0.05, 1.0) var repeat_delay: float = 0.125
## Seconds between repeated steps while held.
@export_range(0.03, 0.5) var repeat_interval: float = 0.11

const _ACTIONS: Dictionary[StringName, Vector2i] = {
	&"move_up": Vector2i.UP,
	&"move_down": Vector2i.DOWN,
	&"move_left": Vector2i.LEFT,
	&"move_right": Vector2i.RIGHT,
}

var _pending: bool = false       # a press is waiting out the chord window
var _pending_dir: Vector2i = Vector2i.ZERO
var _pending_time: float = 0.0
var _repeat_time: float = 0.0    # countdown to the next held-key step
var _wait_repeat_time: float = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"wait", false):
		_wait_repeat_time = repeat_delay
		wait_requested.emit()
		get_viewport().set_input_as_handled()
		return
	for action: StringName in _ACTIONS:
		# false = ignore OS key-repeat; holding is handled in _process.
		if event.is_action_pressed(action, false):
			if not _pending:
				_pending = true
				_pending_time = chord_window
				_pending_dir = Vector2i.ZERO
			_pending_dir += _ACTIONS[action]
			get_viewport().set_input_as_handled()
			return


func _process(delta: float) -> void:
	if _pending:
		_pending_time -= delta
		if _pending_time > 0.0:
			return
		_pending = false
		# Keys pressed in the window, plus any key already being held (e.g. hold Up, tap Right).
		var held: Vector2i = held_direction()
		var dir: Vector2i = _pending_dir.clampi(-1, 1)
		if dir.x == 0:
			dir.x = held.x
		if dir.y == 0:
			dir.y = held.y
		_repeat_time = repeat_delay
		if dir != Vector2i.ZERO:
			step_requested.emit(dir)
		return

	var held_dir: Vector2i = held_direction()
	if held_dir == Vector2i.ZERO:
		# Holding wait (with no direction) repeats waits at the walking pace.
		if Input.is_action_pressed(&"wait"):
			_wait_repeat_time -= delta
			if _wait_repeat_time <= 0.0:
				_wait_repeat_time = repeat_interval
				wait_requested.emit()
		return
	_repeat_time -= delta
	if _repeat_time <= 0.0:
		_repeat_time = repeat_interval
		step_requested.emit(held_dir)


## Direction from the move keys currently held down (opposite keys cancel out).
func held_direction() -> Vector2i:
	var dir: Vector2i = Vector2i.ZERO
	for action: StringName in _ACTIONS:
		if Input.is_action_pressed(action):
			dir += _ACTIONS[action]
	return dir.clampi(-1, 1)
