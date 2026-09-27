class_name Catalog
extends RefCounted
## Every upgrade, furniture piece and floor item in the game. Add new .tres files here.
## (Explicit preloads work in exported builds, unlike scanning folders.)

const UPGRADES: Array[UpgradeDef] = [
	preload("res://data/upgrades/extra_reroll.tres"),
	preload("res://data/upgrades/extra_die.tres"),
	preload("res://data/upgrades/sharper_claws.tres"),
	preload("res://data/upgrades/green_thumb.tres"),
	preload("res://data/upgrades/tough_hide.tres"),
]

const FURNITURE: Array[FurnitureDef] = [
	preload("res://data/furniture/hammock.tres"),
	preload("res://data/furniture/lamp.tres"),
	preload("res://data/furniture/rug.tres"),
	preload("res://data/furniture/bookshelf.tres"),
	preload("res://data/furniture/armchair.tres"),
]

const ITEMS: Array[ItemDef] = [
	preload("res://data/items/fruit.tres"),
	preload("res://data/items/pebble.tres"),
	preload("res://data/items/moss.tres"),
]
