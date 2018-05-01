extends Reference

const GameSceneGd = preload("res://game/GameScene.gd")

const PlayerSpawnsGroup = "PlayerSpawns"


func loadLevel(levelFilename, parentNode):
	assert(parentNode != null)
	var level = load(levelFilename).instance()
	parentNode.add_child(level)
	return level


func unloadLevel(level):
	assert( level )
	level.queue_free()


func insertPlayerUnits(playerUnits, level):
	var spawns = level.get_tree().get_nodes_in_group(PlayerSpawnsGroup)

	var spawnIdx = 0
	for unit in playerUnits:
		assert( unit[GameSceneGd.OWNER] in Network.m_players )

		var freeSpawn = findFreePlayerSpawn( spawns )
		if freeSpawn == null:
			continue

		spawns.erase(freeSpawn)
		var unitNode = unit[GameSceneGd.NODE]
		level.get_node("Units").add_child( unitNode, true )
		unitNode.set_position( freeSpawn.get_position() )
		spawnIdx += 1


func findFreePlayerSpawn( spawns ):
	for spawn in spawns:
		if spawn.spawnAllowed():
			return spawn

	return null
