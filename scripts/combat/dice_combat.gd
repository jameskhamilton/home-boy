class_name DiceCombat
extends RefCounted
## The rules of a combat round, kept separate from the combat box's visuals.
## Both sides roll at once (King of Tokyo style):
## - damage to the enemy  = sloth ATTACK faces - enemy DEFEND faces (min 0)
## - damage to the sloth  = enemy ATTACK faces - sloth DEFEND faces (min 0), x multiplier
## - XP gained            = sloth XP (leaf) faces


## Roll every die in the set.
static func roll_all(dice: Array[DieDef], rng: RandomNumberGenerator) -> Array[DieDef.Face]:
	var faces: Array[DieDef.Face] = []
	for die in dice:
		faces.append(die.roll(rng))
	return faces


static func count(faces: Array[DieDef.Face], face: DieDef.Face) -> int:
	var n: int = 0
	for f in faces:
		if f == face:
			n += 1
	return n


## Work out one round. `enemy_multiplier` doubles snake damage on a sleeping sloth.
static func resolve(player_faces: Array[DieDef.Face], enemy_faces: Array[DieDef.Face],
		enemy_multiplier: int = 1) -> Dictionary:
	var to_enemy: int = maxi(0, count(player_faces, DieDef.Face.ATTACK) - count(enemy_faces, DieDef.Face.DEFEND))
	var to_player: int = maxi(0, count(enemy_faces, DieDef.Face.ATTACK) - count(player_faces, DieDef.Face.DEFEND))
	return {
		"to_enemy": to_enemy,
		"to_player": to_player * enemy_multiplier,
		"xp": count(player_faces, DieDef.Face.XP),
	}
