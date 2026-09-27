class_name CombatManager
extends Node
## Plays out a dice fight between the sloth and one enemy inside the combat box.
## Each round: both sides roll, the sloth may reroll one die, then DiceCombat resolves it.
## The fight lasts until one side is out of HP (no fleeing).

## Set by Main.
var world: TurnManager
var box: CombatBox


## Play a whole fight. Awaitable.
func fight(request: CombatRequest) -> void:
	var player: Player = world.player
	var enemy: Enemy = request.enemy
	var rng: RandomNumberGenerator = world.rng
	var enemy_name: String = enemy.display_name()

	var player_dice: Array[DieDef] = player.dice.duplicate()
	if request.ambush and player.ambush_die != null:
		player_dice.append(player.ambush_die)
	var enemy_dice: Array[DieDef] = enemy.def.dice

	var title: String
	if request.caught_napping:
		title = "%s finds you napping!" % MeleeAction._cap(enemy_name)
	elif request.ambush:
		title = "Ambush! You spring at %s. (+1 die)" % enemy_name
	else:
		title = "You fight %s!" % enemy_name
	world.post_message(title, MessageColours.INFO)

	await box.open(player, enemy, player_dice, enemy_dice, title)
	var free_bite: bool = request.caught_napping
	var fight_xp: int = 0

	while not player.fighter.is_dead() and not enemy.fighter.is_dead():
		box.set_prompt("Space: roll")
		await box.wait_accept()
		var enemy_faces: Array[DieDef.Face] = DiceCombat.roll_all(enemy_dice, rng)
		var player_faces: Array[DieDef.Face] = []
		if free_bite:
			await box.roll_dice(player_faces, enemy_faces) # asleep: the sloth doesn't roll
		else:
			player_faces = DiceCombat.roll_all(player_dice, rng)
			await box.roll_dice(player_faces, enemy_faces)
			var rerolls: int = player.rerolls_per_round
			while rerolls > 0:
				box.set_prompt("1-%d: reroll a die   Space: keep" % player_dice.size())
				var index: int = await box.choose_die(player_dice.size())
				if index < 0:
					break
				player_faces[index] = player_dice[index].roll(rng)
				await box.reroll_die(index, player_faces[index])
				rerolls -= 1

		var result: Dictionary = DiceCombat.resolve(player_faces, enemy_faces, 2 if free_bite else 1)
		if free_bite:
			player.wake("You wake with a start!")
			free_bite = false
		enemy.fighter.take_damage(result.to_enemy)
		player.fighter.take_damage(result.to_player)
		if result.xp > 0:
			player.gain_xp(result.xp)
			fight_xp += result.xp
		box.set_fight_xp(fight_xp, result.xp > 0)
		var line: String = "You deal %d.  %s deals %d." % [result.to_enemy, MeleeAction._cap(enemy_name), result.to_player]
		if result.xp > 0:
			line += "  +%d XP" % result.xp
		world.post_message(line, MessageColours.HURT if result.to_player > result.to_enemy else MessageColours.HIT)
		box.show_result(line, result.to_enemy, result.to_player, enemy.fighter.hp, player.fighter.hp)

	var won: bool = enemy.fighter.is_dead()
	if won and GameState.fight_xp_bonus() > 0:
		player.gain_xp(GameState.fight_xp_bonus()) # bookshelf at home
		fight_xp += GameState.fight_xp_bonus()
		box.set_fight_xp(fight_xp, true)
	box.set_prompt("Space: continue")
	var xp_note: String = "  +%d XP" % fight_xp if fight_xp > 0 else ""
	box.set_banner(("%s is defeated!" % MeleeAction._cap(enemy_name) if won else "You collapse...") + xp_note)
	if fight_xp > 0:
		world.post_message("Fight over: +%d XP in total." % fight_xp, MessageColours.GOOD)
	await box.wait_accept()
	await box.close()
	if won:
		world.enemy_died(enemy)
