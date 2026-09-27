extends Node
## Autoload "GameState": everything that lasts between trips underground
## (banked XP, upgrades bought, furniture at home) plus the current trip
## (depth, carried XP and furniture, HP). Resets when the game closes until Save/Load (M10).

## Emitted whenever anything here changes (HUDs listen).
signal changed

const BASE_MAX_HP: int = 10
const BASE_SIGHT: int = 8
const BASE_REROLLS: int = 1
const BASE_DICE: int = 2
const BASE_CAMO_TURNS: int = 3
const BASE_FRUIT_HEAL: int = 3
const HP_PER_TOUGH_HIDE: int = 2
const SHOP_OFFERS: int = 3
## Faces of the starting sloth die, before upgrades.
const BASE_FACES: Array[DieDef.Face] = [
	DieDef.Face.DEFEND, DieDef.Face.DEFEND, DieDef.Face.DEFEND,
	DieDef.Face.ATTACK, DieDef.Face.ATTACK, DieDef.Face.XP,
]

# --- Lasting progress ---
var banked_xp: int = 0
var upgrade_counts: Dictionary[StringName, int] = {}
var furniture_home: Array[StringName] = []

# --- Current trip ---
var trip_active: bool = false
var depth: int = 1
var carried_xp: int = 0
var carried_furniture: Array[FurnitureDef] = []
var trip_hp: int = BASE_MAX_HP
## Extra dice for the next fight only (lucky pebbles).
var lucky_dice: int = 0

## What happened on the last trip, shown when you get home.
var last_trip_summary: String = ""
## Current computer offers (and which are sold).
var shop_offers: Array[UpgradeDef] = []
var shop_sold: Array[bool] = []

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	roll_shop()


# --- Derived stats (base + upgrades + furniture) ---

func upgrade_count(id: StringName) -> int:
	return upgrade_counts.get(id, 0)


func furniture_bonus(bonus: FurnitureDef.Bonus) -> int:
	var total: int = 0
	for f in Catalog.FURNITURE:
		if f.bonus == bonus and furniture_home.has(f.id):
			total += f.amount
	return total


func max_hp() -> int:
	return BASE_MAX_HP + HP_PER_TOUGH_HIDE * upgrade_count(&"tough_hide") \
		+ furniture_bonus(FurnitureDef.Bonus.MAX_HP)


func rerolls_per_round() -> int:
	return BASE_REROLLS + upgrade_count(&"extra_reroll")


func sight_radius() -> int:
	return BASE_SIGHT + furniture_bonus(FurnitureDef.Bonus.SIGHT)


func turns_to_camouflage() -> int:
	return maxi(1, BASE_CAMO_TURNS - furniture_bonus(FurnitureDef.Bonus.CAMO_SPEED))


## HP restored by a healing fruit (the hammock adds more).
func fruit_heal() -> int:
	return BASE_FRUIT_HEAL + furniture_bonus(FurnitureDef.Bonus.FRUIT_HEAL)


func fight_xp_bonus() -> int:
	return furniture_bonus(FurnitureDef.Bonus.FIGHT_XP)


## The sloth's dice with every upgrade applied.
func player_dice() -> Array[DieDef]:
	var faces: Array[DieDef.Face] = BASE_FACES.duplicate()
	var to_claw: int = upgrade_count(&"sharper_claws")
	var to_leaf: int = upgrade_count(&"green_thumb")
	for i in faces.size():
		if faces[i] != DieDef.Face.DEFEND:
			continue
		if to_claw > 0:
			faces[i] = DieDef.Face.ATTACK
			to_claw -= 1
		elif to_leaf > 0:
			faces[i] = DieDef.Face.XP
			to_leaf -= 1
	var die := DieDef.new()
	die.display_name = "Sloth die"
	die.faces = faces
	die.skin_row = 0
	var dice: Array[DieDef] = []
	for i in BASE_DICE + upgrade_count(&"extra_die"):
		dice.append(die)
	return dice


# --- Trips ---

func start_trip() -> void:
	trip_active = true
	depth = 1
	carried_xp = 0
	carried_furniture.clear()
	lucky_dice = 0
	trip_hp = max_hp()
	changed.emit()


func descend() -> void:
	depth += 1
	changed.emit()


func add_xp(amount: int) -> void:
	carried_xp += amount
	changed.emit()


func carry(furniture: FurnitureDef) -> void:
	carried_furniture.append(furniture)
	changed.emit()


## Climbed home: bank everything carried.
func finish_trip_home() -> void:
	banked_xp += carried_xp
	var names: Array[String] = []
	for f in carried_furniture:
		if not furniture_home.has(f.id):
			furniture_home.append(f.id)
			names.append(f.display_name)
	last_trip_summary = "Home safe from depth %d! Banked %d XP." % [depth, carried_xp]
	if not names.is_empty():
		last_trip_summary += "  New: " + ", ".join(names) + "."
	_end_trip()


## Died underground: lose what was carried.
func lose_trip() -> void:
	var lost: Array[String] = []
	if carried_xp > 0:
		lost.append("%d XP" % carried_xp)
	for f in carried_furniture:
		lost.append(f.display_name)
	last_trip_summary = "The macaw carried you home from depth %d." % depth
	if not lost.is_empty():
		last_trip_summary += "  Lost: " + ", ".join(lost) + "."
	_end_trip()


func _end_trip() -> void:
	trip_active = false
	carried_xp = 0
	carried_furniture.clear()
	roll_shop()
	changed.emit()


## A piece of furniture for this depth that you don't own or carry yet, or null.
func pick_furniture_for_depth(p_rng: RandomNumberGenerator) -> FurnitureDef:
	var options: Array[FurnitureDef] = []
	for f in Catalog.FURNITURE:
		if f.min_depth <= depth and not furniture_home.has(f.id) and not carried_furniture.has(f):
			options.append(f)
	if options.is_empty():
		return null
	return options[p_rng.randi_range(0, options.size() - 1)]


# --- Computer shop ---

func upgrade_cost(u: UpgradeDef) -> int:
	return u.base_cost + u.cost_step * upgrade_count(u.id)


func can_offer(u: UpgradeDef) -> bool:
	if upgrade_count(u.id) >= u.max_count:
		return false
	# Face changes need a shell face left to change (each die has 3).
	if u.kind == UpgradeDef.Kind.SHELL_TO_CLAW or u.kind == UpgradeDef.Kind.SHELL_TO_LEAF:
		return upgrade_count(&"sharper_claws") + upgrade_count(&"green_thumb") < 3
	return true


## Pick 3 random upgrades for the computer (done each time you get home).
func roll_shop() -> void:
	var pool: Array[UpgradeDef] = []
	for u in Catalog.UPGRADES:
		if can_offer(u):
			pool.append(u)
	shop_offers.clear()
	shop_sold.clear()
	while not pool.is_empty() and shop_offers.size() < SHOP_OFFERS:
		shop_offers.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
		shop_sold.append(false)


## Buy offer `index` with banked XP. Returns the upgrade bought, or null.
func buy(index: int) -> UpgradeDef:
	if index < 0 or index >= shop_offers.size() or shop_sold[index]:
		return null
	var u: UpgradeDef = shop_offers[index]
	var cost: int = upgrade_cost(u)
	if banked_xp < cost or not can_offer(u):
		return null
	banked_xp -= cost
	upgrade_counts[u.id] = upgrade_count(u.id) + 1
	shop_sold[index] = true
	changed.emit()
	return u
