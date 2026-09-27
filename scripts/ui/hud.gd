class_name Hud
extends CanvasLayer
## On-screen info: HP bar, XP, status line, message log, seed and the game-over banner.
## Holds no game rules; Main feeds it.

const MAX_MESSAGES: int = 6
const HP_BAR_WIDTH: float = 60.0
const HP_OK: Color = Color("#7fb24a")  # G
const HP_LOW: Color = Color("#b13e53") # r

var _messages: Array[String] = []

@onready var _hp_fill: ColorRect = $HpBar/Fill
@onready var _hp_label: Label = $HpLabel
@onready var _xp_label: Label = $XpLabel
@onready var _depth_label: Label = $DepthLabel
@onready var _carry_label: Label = $CarryLabel
@onready var _status_label: Label = $StatusLabel
@onready var _seed_label: Label = $SeedLabel
@onready var _log: RichTextLabel = $MessageLog
@onready var _game_over: Label = $GameOver


func set_hp(hp: int, max_hp: int) -> void:
	var ratio: float = float(hp) / float(max_hp) if max_hp > 0 else 0.0
	_hp_fill.size.x = HP_BAR_WIDTH * ratio
	_hp_fill.color = HP_LOW if ratio <= 0.3 else HP_OK
	_hp_label.text = "HP %d/%d" % [hp, max_hp]


## XP carried on this trip (lost if you die) and XP safely banked at home.
func set_xp(carried: int, banked: int) -> void:
	_xp_label.text = "XP %d   (home %d)" % [carried, banked]


func set_depth(depth: int) -> void:
	_depth_label.text = "Depth %d" % depth


## Furniture being carried home (empty = nothing).
func set_carrying(names: String) -> void:
	_carry_label.text = "Carrying: " + names if names != "" else ""


func set_status(text: String) -> void:
	_status_label.text = text


func set_seed(seed_value: int) -> void:
	_seed_label.text = "Seed %d" % seed_value


## Add a coloured line to the bottom of the log (oldest lines scroll off).
func add_message(text: String, colour: Color) -> void:
	_messages.append("[color=#%s]%s[/color]" % [colour.to_html(false), text])
	while _messages.size() > MAX_MESSAGES:
		_messages.pop_front()
	_log.text = "\n".join(_messages)


func clear_messages() -> void:
	_messages.clear()
	_log.text = ""


func show_game_over(shown: bool, text: String = "") -> void:
	_game_over.visible = shown
	if text != "":
		_game_over.text = text
