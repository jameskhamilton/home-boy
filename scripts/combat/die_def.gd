class_name DieDef
extends Resource
## One kind of combat die: its six faces and how it looks.
## New dice (e.g. from items) = new .tres files in data/dice/, not new code.

## What a face does when it lands.
enum Face {
	ATTACK, ## Deals 1 damage (claw for the sloth, fangs for snakes).
	DEFEND, ## Blocks 1 damage (shell / scales).
	XP,     ## +1 XP (leaf).
	BLANK,  ## Nothing.
}

@export var display_name: String = "Die"
## The faces, one per side. Usually 6, but any number works.
@export var faces: Array[Face] = [Face.ATTACK, Face.ATTACK, Face.DEFEND, Face.DEFEND, Face.XP, Face.BLANK]
## Row in art/dice.png for this die's look (0 = sloth, 1 = snake).
@export var skin_row: int = 0


## Roll this die once.
func roll(rng: RandomNumberGenerator) -> Face:
	return faces[rng.randi_range(0, faces.size() - 1)]
