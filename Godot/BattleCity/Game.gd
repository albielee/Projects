extends Node

const MainMenuScn = "res://gui/MainMenu.tscn"
const PlayerAgentGd = preload("res://actors/PlayerAgent.gd")

#stages need to be located in
const StagesPath = "res://stages/"
# Stages need to start with string below and have number at the end
const StagePrefix = "Stage"
const StageExtension = ".tscn"

const GameOverScreenDelay = 2
const Resolution = Vector2(1024, 768)

var m_stages = []
var m_nextStage = 0
var m_delayedSceneSwitch

var m_playerData = {}


func _ready():
	OS.set_window_size(Resolution)
	set_process_input(true)
	m_stages = discoverStages()
	randomize()


func _input(event):
	if (event.is_action_pressed("ui_cancel")):
		if m_delayedSceneSwitch:
			m_delayedSceneSwitch.queue_free()

		SceneSwitcher.switchScene(MainMenuScn)


func discoverStages():
	var stages = []
	var stageNumber = 1
	while ( File.new().file_exists(StagesPath + StagePrefix + str(stageNumber) + StageExtension) ):
		stages.append( StagesPath + StagePrefix + str(stageNumber) + StageExtension )
		stageNumber += 1

	assert(stages.empty() == false)
	return stages


func startAGame(playerCount):
	for playerId in range(1, playerCount+1):
		var playerAgent = Node.new()
		playerAgent.set_script( PlayerAgentGd )
		playerAgent.setActions( PlayerAgentGd.PlayersActions[playerId - 1] )
		playerAgent.setPlayerId( playerId )
		m_playerData[playerId] = newPlayerData(playerAgent)

	m_nextStage = 0
	loadStage(2, m_playerData)


func onPlayersWon():
	m_delayedSceneSwitch = Timer.new()
	m_delayedSceneSwitch.set_wait_time(GameOverScreenDelay)
	m_delayedSceneSwitch.connect("timeout", m_delayedSceneSwitch, "queue_free")
	m_delayedSceneSwitch.connect("timeout", self, "stageComplete")
	self.add_child(m_delayedSceneSwitch)
	m_delayedSceneSwitch.start()


func onPlayersLost():
	m_delayedSceneSwitch = Timer.new()
	m_delayedSceneSwitch.set_wait_time(GameOverScreenDelay)
	m_delayedSceneSwitch.connect("timeout", m_delayedSceneSwitch, "queue_free")
	m_delayedSceneSwitch.connect("timeout", self, "gameOver")
	self.add_child(m_delayedSceneSwitch)
	m_delayedSceneSwitch.start()


func gameOver():
	m_delayedSceneSwitch = null
	SceneSwitcher.switchScene(MainMenuScn)


func stageComplete():
	m_delayedSceneSwitch = null
	m_nextStage += 1
	if m_nextStage < m_stages.size():
		loadStage(m_nextStage, m_playerData)
	else:
		gameOver()


func loadStage(stageNumber, playerData):
	SceneSwitcher.switchScene( m_stages[stageNumber], {playerData = playerData} )


func newPlayerData(agent = null, lives = 2, points = 0):
	return { agent = agent, lives = lives, points = points }


func awardPoints(playerId, points):
	assert(m_playerData.has(playerId))
	m_playerData[playerId].points += points
