class_name ShopPanel
extends NinePatchRect
## The computer's online shop: 3 random upgrades with XP prices (from GameState).
## 1-3 orders one (if you can afford it), E closes. Ordering emits `bought`.

signal bought(upgrade: UpgradeDef)
signal closed

const AFFORD: Color = Color("#d9c49c")
const TOO_DEAR: Color = Color("#7e7892")
const SOLD: Color = Color("#5a5468")

@onready var _cards: Array[Label] = [$Card1, $Card2, $Card3]
@onready var _xp: Label = $Xp
@onready var _note: Label = $Note


func _ready() -> void:
	visible = false


func open() -> void:
	visible = true
	_note.text = ""
	refresh()


func close() -> void:
	visible = false
	closed.emit()


func refresh() -> void:
	_xp.text = "Banked XP: %d" % GameState.banked_xp
	for i in _cards.size():
		var card: Label = _cards[i]
		if i >= GameState.shop_offers.size():
			card.text = "%d.  (nothing else in stock)" % (i + 1)
			card.add_theme_color_override("font_color", SOLD)
			continue
		var u: UpgradeDef = GameState.shop_offers[i]
		if GameState.shop_sold[i]:
			card.text = "%d.  %s  -  SOLD" % [i + 1, u.display_name]
			card.add_theme_color_override("font_color", SOLD)
			continue
		var cost: int = GameState.upgrade_cost(u)
		var owned: int = GameState.upgrade_count(u.id)
		card.text = "%d.  %s  -  %d XP   (owned %d/%d)\n     %s" % [i + 1, u.display_name, cost, owned, u.max_count, u.description]
		card.add_theme_color_override("font_color", AFFORD if GameState.banked_xp >= cost else TOO_DEAR)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	# The number keys reuse the combat reroll actions (keys 1-3).
	for i in 3:
		if event.is_action_pressed("reroll_%d" % (i + 1)):
			get_viewport().set_input_as_handled()
			_try_buy(i)
			return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _try_buy(index: int) -> void:
	if index >= GameState.shop_offers.size() or GameState.shop_sold[index]:
		return
	var u: UpgradeDef = GameState.buy(index)
	if u == null:
		_note.text = "Not enough XP. Bring more home from underground!"
		return
	visible = false
	bought.emit(u)
