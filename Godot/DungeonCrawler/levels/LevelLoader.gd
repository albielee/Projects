extends Node

const DwarfScn = preload("res://units/Dwarf.tscn")
const PlayerAgentGd = preload("res://actors/PlayerAgent.gd")
const UnitGd = preload("res://units/unit.gd")

const PlayerSpawnsGroup = "PlayerSpawns"

var m_loadedLevel  setget deleted


func deleted():
	assert(false)


slave func loadLevel(levelFilename):
	unloadLevel()
	var level = load(levelFilename).instance()
	get_tree().get_root().add_child(level)
	m_loadedLevel = level
	
	
func unloadLevel():
	if (m_loadedLevel != null):
		m_loadedLevel.queue_free()
		m_loadedLevel = null
	
	
sync func insertPlayers(players):
	assert(m_loadedLevel != null)
	var spawns = m_loadedLevel.get_tree().get_nodes_in_group(PlayerSpawnsGroup)
	
	var spawnIdx = 0
	for pid in players:
		if m_loadedLevel.get_node("Units").has_node( str(pid) ):
			continue
		
		if (not pid in gamestate.m_players):
			continue
		
		if spawnIdx >= spawns.size():
			break

		var dwarf = DwarfScn.instance()
		dwarf.set_position( spawns[spawnIdx].get_position() )
		dwarf.set_name(str(pid))
		dwarf.get_node(UnitGd.UnitNameLabel).text = players[pid]
		m_loadedLevel.get_node("Units").add_child(dwarf)

		if(pid == m_loadedLevel.get_tree().get_network_unique_id()):
			var playerAgent = Node.new()
			playerAgent.set_network_master(pid)
			playerAgent.set_script(PlayerAgentGd)
			playerAgent.setActions(PlayerAgentGd.PlayersActions[0])
			playerAgent.assignToUnit(dwarf)
		
		spawnIdx += 1
	
	
func sendToClient(clientId):
	assert(get_tree().is_network_server())
	assert(m_loadedLevel != null)
	var levelFilename = m_loadedLevel.get_filename()
	rpc_id(clientId, "loadLevel", levelFilename)
	m_loadedLevel.sendToClient(clientId)
	rpc_id(clientId, "levelLoadingComplete")
	
	
func saveGame(filePath):
	var saveDict = {}
	saveDict[m_loadedLevel.get_name()] = m_loadedLevel.save()

	var saveFile = File.new()
	saveFile.open(filePath, File.WRITE)

	saveFile.store_line(to_json(saveDict))
	saveFile.close()


func loadGame(saveFilePath):
	var saveFile = File.new()
	if not saveFile.file_exists(saveFilePath):
		return
		
	saveFile.open(saveFilePath, File.READ)
	var gameStateDict = parse_json(saveFile.get_as_text())

	var levelDict = gameStateDict.values()[0]
	loadLevel( levelDict.scene )
	m_loadedLevel.set_name( levelDict.keys()[0] )
	m_loadedLevel.load(levelDict)
	
	
func createChildFromPath(childNodePath, childScenePath, parent):
	var nodePath = NodePath(childNodePath)
	var node = load( childScenePath ).instance()
	var get_name_count = nodePath.get_name_count()
	var get_subname_count  = nodePath.get_subname_count()
	var get_name  = nodePath.get_name(nodePath.get_name_count()-1)
	pass
	
	
slave func levelLoadingComplete():
	gamestate.rpc("registerPlayer", get_tree().get_network_unique_id(), \
		gamestate.m_playerName)
	gamestate.rpc_id(gamestate.SERVER_ID, "addRegisteredPlayerToGame", \
		get_tree().get_network_unique_id() )
	
	