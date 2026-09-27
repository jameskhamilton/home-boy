extends Node2D
## The sloth's tree house. Walk with left/right. E at the computer opens the shop
## (a macaw delivers what you order); E at the ladder climbs down underground.
## Furniture you've brought home appears in the room.

const DUNGEON_SCENE: String = "res://scenes/main.tscn"
const ACTORS: Texture2D = preload("res://art/actors.png")
const WALK_SPEED: float = 70.0
const FLOOR_Y: float = 194.0
const MIN_X: float = 204.0
const MAX_X: float = 404.0
const COMPUTER_REACH_X: float = 222.0 # stand left of this to use the computer
const LADDER_REACH_X: float = 390.0   # stand right of this to use the ladder
const DROP_POINT: Vector2 = Vector2(376, 184) # where packages land on the porch

var _busy: bool = false
var _walk_anim: float = 0.0

@onready var _sloth: Sprite2D = $Sloth
@onready var _furniture_root: Node2D = $Furniture
@onready var _macaw: Sprite2D = $Macaw
@onready var _package: Sprite2D = $Package
@onready var _info: Label = $UI/Info
@onready var _message: Label = $UI/Message
@onready var _prompt: Label = $UI/Prompt
@onready var _shop: ShopPanel = $UI/Shop


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#1b1420"))
	_sloth.texture = ACTORS
	_sloth.region_enabled = true
	_sloth.region_rect = Rect2(0, 0, 16, 16)
	_sloth.position = Vector2(300, FLOOR_Y - 16)
	_macaw.visible = false
	_package.visible = false
	_build_furniture()
	_shop.bought.connect(_on_bought)
	GameState.changed.connect(_refresh_info)
	_message.text = GameState.last_trip_summary if GameState.last_trip_summary != "" \
		else "Home sweet (empty) home. Fetch furniture from underground to make it cosy."
	_refresh_info()


func _process(delta: float) -> void:
	if _busy or _shop.visible:
		_prompt.text = "" if _busy else "1-3: order    E: close"
		return
	var dir: float = Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		_sloth.position.x = clampf(_sloth.position.x + dir * WALK_SPEED * delta, MIN_X, MAX_X)
		_sloth.flip_h = dir < 0.0
		_walk_anim += delta
		_sloth.region_rect.position.x = 16.0 if int(_walk_anim / 0.2) % 2 == 1 else 0.0
		_sloth.position.y = FLOOR_Y - 16 - (1.0 if int(_walk_anim / 0.2) % 2 == 1 else 0.0)
	else:
		_sloth.region_rect.position.x = 0.0
		_sloth.position.y = FLOOR_Y - 16
	if _near_computer():
		_prompt.text = "E: use the computer"
	elif _near_ladder():
		_prompt.text = "E: climb down the ladder"
	else:
		_prompt.text = "Left/Right: walk"


func _unhandled_input(event: InputEvent) -> void:
	if _busy or _shop.visible:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if _near_computer():
			_shop.open()
		elif _near_ladder():
			GameState.start_trip()
			get_tree().change_scene_to_file(DUNGEON_SCENE)


func _near_computer() -> bool:
	return _sloth.position.x <= COMPUTER_REACH_X


func _near_ladder() -> bool:
	return _sloth.position.x >= LADDER_REACH_X


## Show every furniture piece already brought home.
func _build_furniture() -> void:
	for child in _furniture_root.get_children():
		child.queue_free()
	for f in Catalog.FURNITURE:
		if GameState.furniture_home.has(f.id):
			var s := Sprite2D.new()
			s.texture = f.texture
			s.centered = false
			s.position = f.home_position
			_furniture_root.add_child(s)


func _refresh_info() -> void:
	var dice: Array[DieDef] = GameState.player_dice()
	_info.text = "Banked XP %d    HP %d    Dice %d    Rerolls %d    Furniture %d/%d" % [
		GameState.banked_xp, GameState.max_hp(), dice.size(), GameState.rerolls_per_round(),
		GameState.furniture_home.size(), Catalog.FURNITURE.size()]


## A macaw flies in from the right, drops the package on the porch, and flies off.
func _on_bought(u: UpgradeDef) -> void:
	_busy = true
	_message.text = "Order placed: %s. Here comes the delivery macaw..." % u.display_name
	_macaw.position = Vector2(500, 110)
	_macaw.visible = true
	_package.position = _macaw.position + Vector2(10, 20)
	_package.modulate = Color.WHITE
	_package.visible = true
	var flap: Timer = Timer.new()
	flap.wait_time = 0.12
	flap.timeout.connect(func() -> void: _macaw.frame = 1 - _macaw.frame)
	add_child(flap)
	flap.start()
	var hover: Vector2 = DROP_POINT + Vector2(-6, -44)
	var t1: Tween = create_tween().set_parallel(true)
	t1.tween_property(_macaw, "position", hover, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t1.tween_property(_package, "position", hover + Vector2(10, 20), 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await t1.finished
	var t2: Tween = create_tween()
	t2.tween_property(_package, "position", DROP_POINT, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await t2.finished
	var t3: Tween = create_tween()
	t3.tween_property(_macaw, "position", Vector2(-50, 30), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_message.text = "Delivered: %s!  %s" % [u.display_name, u.description]
	await t3.finished
	flap.queue_free()
	_macaw.visible = false
	var t4: Tween = create_tween()
	t4.tween_interval(0.8)
	t4.tween_property(_package, "modulate:a", 0.0, 0.4)
	await t4.finished
	_package.visible = false
	_busy = false
	_refresh_info()
