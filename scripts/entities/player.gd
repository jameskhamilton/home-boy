class_name Player
extends Actor
## The sloth. Turns input into Actions for the TurnManager, and tracks stillness:
## waiting `turns_to_camouflage` turns in a row makes the sloth camouflaged.

## Emitted after each turn with the current stillness state (for the HUD).
signal stillness_changed(still_turns: int, camouflaged: bool)

## Waits in a row needed to become camouflaged.
@export_range(1, 10) var turns_to_camouflage: int = 3

const CAMO_TINT: Color = Color(0.55, 0.85, 0.5, 0.75)

## Consecutive turns spent waiting.
var still_turns: int = 0

@onready var _camera: Camera2D = $Camera2D
@onready var _input: DirectionInput = $DirectionInput
@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	super()
	_input.step_requested.connect(_on_step_requested)
	_input.wait_requested.connect(_on_wait_requested)


## True once the sloth has been still long enough to blend in.
func is_camouflaged() -> bool:
	return still_turns >= turns_to_camouflage


## Called by TurnManager after the player's action has been performed.
func after_action(action: Action) -> void:
	if action is WaitAction:
		still_turns += 1
	else:
		still_turns = 0
	_sprite.modulate = CAMO_TINT if is_camouflaged() else Color.WHITE
	stillness_changed.emit(still_turns, is_camouflaged())


## Reset stillness (e.g. on a new floor).
func reset_stillness() -> void:
	still_turns = 0
	_sprite.modulate = Color.WHITE
	stillness_changed.emit(0, false)


## Stop the camera scrolling past the map's edges (size in pixels).
func set_camera_limits(map_size_px: Vector2i) -> void:
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = map_size_px.x
	_camera.limit_bottom = map_size_px.y


## A step from input. If a diagonal is blocked, slide along the wall by taking
## whichever single direction is open (if exactly one is).
func _on_step_requested(dir: Vector2i) -> void:
	var chosen: Vector2i = _resolve_step(dir)
	if chosen != Vector2i.ZERO:
		_submit(MoveAction.new(self, chosen))


func _on_wait_requested() -> void:
	_submit(WaitAction.new(self))


func _resolve_step(dir: Vector2i) -> Vector2i:
	if can_step(dir):
		return dir
	if dir.x == 0 or dir.y == 0:
		return Vector2i.ZERO
	var horizontal := Vector2i(dir.x, 0)
	var vertical := Vector2i(0, dir.y)
	var can_h: bool = can_step(horizontal)
	var can_v: bool = can_step(vertical)
	if can_h and not can_v:
		return horizontal
	if can_v and not can_h:
		return vertical
	return Vector2i.ZERO


func _submit(action: Action) -> void:
	if world != null:
		world.play_turn(action)
	else:
		action.perform()
