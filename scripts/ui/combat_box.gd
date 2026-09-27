class_name CombatBox
extends CanvasLayer
## The combat "cut scene": dims the map, opens a bordered 8-bit box with both fighters,
## their HP and dice, and animates rolls. Visuals and input only; rules live in DiceCombat.

## Emitted when the player presses Space/Enter while the box waits.
signal accepted
## Emitted when the player picks a die to reroll (0-based), or -1 to keep.
signal die_chosen(index: int)

const DICE_TEXTURE: Texture2D = preload("res://art/dice.png")
const ACTORS_TEXTURE: Texture2D = preload("res://art/actors.png")
const TILE: int = 16       # actors.png cells
const DICE_TILE: int = 32  # dice.png cells (from James's dice art)
const HP_BAR_WIDTH: float = 72.0
const FACE_COLUMN: Dictionary[int, int] = {
	DieDef.Face.ATTACK: 0, DieDef.Face.DEFEND: 1, DieDef.Face.XP: 2, DieDef.Face.BLANK: 3,
}
const HURT_FLASH: Color = Color("#b13e53")

@export var roll_time: float = 0.6
@export var tumble_frame_time: float = 0.06

var _player_dice: Array[DieDef] = []
var _enemy_dice: Array[DieDef] = []
var _player_rects: Array[TextureRect] = []
var _enemy_rects: Array[TextureRect] = []
var _choosing: bool = false
var _choice_count: int = 0
var _waiting_accept: bool = false
var _player_max: int = 1
var _enemy_max: int = 1

@onready var _dim: ColorRect = $Dim
@onready var _frame: NinePatchRect = $Frame
@onready var _title: Label = $Frame/Title
@onready var _player_portrait: TextureRect = $Frame/PlayerPortrait
@onready var _enemy_portrait: TextureRect = $Frame/EnemyPortrait
@onready var _player_name: Label = $Frame/PlayerName
@onready var _enemy_name: Label = $Frame/EnemyName
@onready var _player_hp_fill: ColorRect = $Frame/PlayerHp/Fill
@onready var _enemy_hp_fill: ColorRect = $Frame/EnemyHp/Fill
@onready var _player_hp_label: Label = $Frame/PlayerHpLabel
@onready var _enemy_hp_label: Label = $Frame/EnemyHpLabel
@onready var _player_dice_row: HBoxContainer = $Frame/PlayerDice
@onready var _enemy_dice_row: HBoxContainer = $Frame/EnemyDice
@onready var _fight_xp: Label = $Frame/FightXp
@onready var _result: Label = $Frame/Result
@onready var _prompt: Label = $Frame/Prompt


func _ready() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _choosing:
		for i in _choice_count:
			if event.is_action_pressed("reroll_%d" % (i + 1)):
				_finish_choice(i)
				get_viewport().set_input_as_handled()
				return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _choosing:
			_finish_choice(-1)
		elif _waiting_accept:
			_waiting_accept = false
			accepted.emit()


## Show the box for a new fight. Awaitable (plays the opening animation).
func open(player: Player, enemy: Enemy, player_dice: Array[DieDef], enemy_dice: Array[DieDef], title: String) -> void:
	_player_dice = player_dice
	_enemy_dice = enemy_dice
	_title.text = title
	_fight_xp.text = "XP +0"
	_result.text = ""
	_prompt.text = ""
	_player_name.text = "Sloth"
	_enemy_name.text = MeleeAction._cap(enemy.def.display_name)
	_player_portrait.texture = _atlas(ACTORS_TEXTURE, Vector2i(0, 0))
	_enemy_portrait.texture = _atlas(ACTORS_TEXTURE, enemy.def.atlas_coords)
	_player_max = player.fighter.max_hp
	_enemy_max = enemy.fighter.max_hp
	_set_hp(player.fighter.hp, enemy.fighter.hp)
	_player_rects = _build_dice(_player_dice_row, _player_dice)
	_enemy_rects = _build_dice(_enemy_dice_row, _enemy_dice)
	visible = true
	_dim.modulate.a = 0.0
	_frame.pivot_offset = _frame.size / 2.0
	_frame.scale = Vector2(0.1, 0.1)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_dim, "modulate:a", 1.0, 0.18)
	tween.tween_property(_frame, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished


## Close the box. Awaitable.
func close() -> void:
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_dim, "modulate:a", 0.0, 0.15)
	tween.tween_property(_frame, "scale", Vector2(0.1, 0.1), 0.15)
	await tween.finished
	visible = false


func set_prompt(text: String) -> void:
	_prompt.text = text


## Replace the result line with a big message (end of fight).
func set_banner(text: String) -> void:
	_result.text = text


## Wait for Space/Enter.
func wait_accept() -> void:
	_waiting_accept = true
	await accepted


## Wait for the player to pick a die (0-based) to reroll, or -1 to keep. Awaitable.
func choose_die(count: int) -> int:
	_choosing = true
	_choice_count = count
	var index: int = await die_chosen
	return index


## Tumble every die, then land on the given faces. An empty `player_faces`
## means the sloth isn't rolling: its dice stay blank. Awaitable.
func roll_dice(player_faces: Array[DieDef.Face], enemy_faces: Array[DieDef.Face]) -> void:
	_result.text = ""
	var rolling: Array[TextureRect] = _enemy_rects.duplicate()
	if not player_faces.is_empty():
		rolling.append_array(_player_rects)
	else:
		for i in _player_rects.size():
			_show_face(_player_rects[i], _player_dice[i], DieDef.Face.BLANK)
	await _tumble(rolling)
	for i in enemy_faces.size():
		_land(_enemy_rects[i], _enemy_dice[i], enemy_faces[i])
	for i in player_faces.size():
		_land(_player_rects[i], _player_dice[i], player_faces[i])
	await get_tree().create_timer(0.15).timeout


## Re-roll one of the sloth's dice. Awaitable.
func reroll_die(index: int, face: DieDef.Face) -> void:
	await _tumble([_player_rects[index]], roll_time * 0.6)
	_land(_player_rects[index], _player_dice[index], face)
	await get_tree().create_timer(0.12).timeout


## Show a round's outcome: flash whoever was hurt and update both HP bars.
func show_result(text: String, to_enemy: int, to_player: int, enemy_hp: int, player_hp: int) -> void:
	_result.text = text
	_set_hp(player_hp, enemy_hp)
	if to_enemy > 0:
		_flash(_enemy_portrait)
	if to_player > 0:
		_flash(_player_portrait)


## Show the XP earned so far in this fight, with a little pop when it goes up.
func set_fight_xp(total: int, gained: bool) -> void:
	_fight_xp.text = "XP +%d" % total
	if gained:
		_fight_xp.pivot_offset = _fight_xp.size / 2.0
		_fight_xp.scale = Vector2(1.5, 1.5)
		create_tween().tween_property(_fight_xp, "scale", Vector2.ONE, 0.2)


func _finish_choice(index: int) -> void:
	_choosing = false
	die_chosen.emit(index)


func _set_hp(player_hp: int, enemy_hp: int) -> void:
	_player_hp_fill.size.x = HP_BAR_WIDTH * float(player_hp) / float(_player_max)
	_enemy_hp_fill.size.x = HP_BAR_WIDTH * float(enemy_hp) / float(_enemy_max)
	_player_hp_label.text = "HP %d/%d" % [player_hp, _player_max]
	_enemy_hp_label.text = "HP %d/%d" % [enemy_hp, _enemy_max]


func _build_dice(row: HBoxContainer, dice: Array[DieDef]) -> Array[TextureRect]:
	for child in row.get_children():
		child.queue_free()
	var rects: Array[TextureRect] = []
	# Shrink the dice a little when there are lots of them (upgrades + ambush + pebbles).
	var size: float = 32.0 if dice.size() <= 4 else 22.0
	row.add_theme_constant_override("separation", 6 if dice.size() <= 4 else 3)
	for i in dice.size():
		var rect := TextureRect.new()
		rect.custom_minimum_size = Vector2(size, size)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		rect.pivot_offset = Vector2(size, size) / 2.0
		rect.mouse_filter = Control.MOUSE_FILTER_STOP
		_show_face(rect, dice[i], DieDef.Face.BLANK)
		if row == _player_dice_row:
			# Key hint under each of the sloth's dice ("1", "2", ...).
			var hint := Label.new()
			hint.text = str(i + 1)
			hint.position = Vector2(0, size)
			hint.size = Vector2(size, 10)
			hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hint.add_theme_font_size_override("font_size", 8)
			hint.add_theme_color_override("font_color", Color("#7e7892"))
			rect.add_child(hint)
			var index: int = i
			rect.gui_input.connect(func(event: InputEvent) -> void:
				if _choosing and event is InputEventMouseButton and event.pressed \
						and event.button_index == MOUSE_BUTTON_LEFT:
					_finish_choice(index))
		row.add_child(rect)
		rects.append(rect)
	return rects


func _tumble(rects: Array[TextureRect], duration: float = -1.0) -> void:
	var total: float = roll_time if duration < 0.0 else duration
	var elapsed: float = 0.0
	var frame: int = 0
	while elapsed < total:
		for rect in rects:
			# Flicker through random faces while tumbling (cosmetic only - the real roll is already decided).
			var skin: int = int(rect.get_meta("skin", 0))
			rect.texture = _atlas(DICE_TEXTURE, Vector2i(randi_range(0, 3), skin), DICE_TILE)
			rect.rotation = 0.25 if frame % 2 == 0 else -0.25
			rect.position.y = -3.0 if frame % 2 == 0 else 0.0
		frame += 1
		await get_tree().create_timer(tumble_frame_time).timeout
		elapsed += tumble_frame_time


func _land(rect: TextureRect, die: DieDef, face: DieDef.Face) -> void:
	rect.rotation = 0.0
	rect.position.y = 0.0
	_show_face(rect, die, face)
	rect.scale = Vector2(1.25, 1.25)
	create_tween().tween_property(rect, "scale", Vector2.ONE, 0.12)


func _show_face(rect: TextureRect, die: DieDef, face: DieDef.Face) -> void:
	rect.set_meta("skin", die.skin_row)
	rect.texture = _atlas(DICE_TEXTURE, Vector2i(FACE_COLUMN[face], die.skin_row), DICE_TILE)


func _flash(target: CanvasItem) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(target, "modulate", HURT_FLASH, 0.06)
	tween.tween_property(target, "modulate", Color.WHITE, 0.06)
	tween.tween_property(target, "modulate", HURT_FLASH, 0.06)
	tween.tween_property(target, "modulate", Color.WHITE, 0.1)


static func _atlas(texture: Texture2D, cell: Vector2i, tile: int = TILE) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(cell * tile, Vector2(tile, tile))
	return atlas
