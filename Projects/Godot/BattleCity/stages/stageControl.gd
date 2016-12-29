extends Node2D

const TILESET_PATH = "res://assets/BattleCityTiles.tscn"
const BRICKS_GROUP = "Bricks"

var cellIdMap = {}


func _enter_tree():
	prepareStage()


func _ready():
	set_process( true )
	set_process_input( true )
	var groundTiles = get_node("Ground")
	var ids = groundTiles.get_tileset().get_tiles_ids()
	var bar = groundTiles.get_used_cells()
	prepareSpawns()


func _process(delta):
	pass
	
func processBulletCollision( bullet, collidingBody ):
	var collidingObject = collidingBody.get_parent()
	
	if collidingObject.is_in_group(BRICKS_GROUP):
		collidingObject.queue_free()
	
	
func assignCellIds():
	var tileNames = [ "Water", "Trees", "Ice", "Grey", 
		"WallSteel", "WallSteel2", "WallSteel4", "WallSteel6", "WallSteel8",
		"WallBrick", "WallBrick2", "WallBrick4", "WallBrick6", "WallBrick8"
		]
	var tileset = get_node("Ground").get_tileset()
	
	for name in tileNames:
		#assert( tileset.find_tile_by_name(name) != -1 )
		cellIdMap[name] = tileset.find_tile_by_name(name)
		
	
func prepareStage():
	assignCellIds()
	var tilesScene = load(TILESET_PATH)
	var groundTilemap = get_node("Ground")
	
	if ( tilesScene != null and groundTilemap != null):
		replaceBrickWallTilesWithNodes(groundTilemap, tilesScene)
		replaceWaterTilesWithNodes(groundTilemap, tilesScene)
		
	assignActors()
	
	
func replaceBrickWallTilesWithNodes(groundTilemap, packedTilesScene):
	var tilesTree = packedTilesScene.instance()
	var wallBrickSmallPrototype = tilesTree.get_node("WallBrickSmall")
	assert( wallBrickSmallPrototype )
	wallBrickSmallPrototype.add_to_group(BRICKS_GROUP)
	var wallBrickPositions = []
	
	for cell in groundTilemap.get_used_cells():
		if ( groundTilemap.get_cellv(cell) == cellIdMap["WallBrick"] ):
			groundTilemap.set_cellv(cell, -1)
			var cellCoords = groundTilemap.map_to_world( cell )
			wallBrickPositions.append( Vector2(cellCoords.x + 4, cellCoords.y + 4) )
			wallBrickPositions.append( Vector2(cellCoords.x + 4 + 8, cellCoords.y + 4) )
			wallBrickPositions.append( Vector2(cellCoords.x + 4, cellCoords.y + 4 + 8) )
			wallBrickPositions.append( Vector2(cellCoords.x + 4 + 8, cellCoords.y + 4 + 8) )
		elif ( groundTilemap.get_cellv(cell) == cellIdMap["WallBrick6"] ):
			groundTilemap.set_cellv(cell, -1)
			var cellCoords = groundTilemap.map_to_world( cell )
			wallBrickPositions.append( Vector2(cellCoords.x + 4 + 8, cellCoords.y + 4) )
			wallBrickPositions.append( Vector2(cellCoords.x + 4 + 8, cellCoords.y + 4 + 8) )
	
	for position in wallBrickPositions:
		var wallBrickSmall = wallBrickSmallPrototype.duplicate()
		assert( wallBrickSmall.get_name() == "WallBrickSmall" )
		assert( wallBrickSmall.is_in_group(BRICKS_GROUP) )
		self.add_child( wallBrickSmall )
		wallBrickSmall.set_pos( position )
	
	
func replaceWaterTilesWithNodes(groundTilemap, packedTilesScene):
	var tilesTree = packedTilesScene.instance()
	var waterPrototype = tilesTree.get_node("Water")
	assert( waterPrototype )
	
	var waterPositions = []
	for cell in groundTilemap.get_used_cells():
		if ( groundTilemap.get_cellv(cell) == cellIdMap["Water"] ):
			groundTilemap.set_cellv(cell, -1)
			var cellCoords = groundTilemap.map_to_world( cell )
			waterPositions.append( Vector2(cellCoords.x + 8, cellCoords.y + 8) )
	
	for position in waterPositions:
		var water = waterPrototype.duplicate()
		assert( water.get_name() == "Water" )
		self.add_child( water )
		water.set_pos( position )
	
	
func assignActors():
	var agentPrototype = Node.new()
	agentPrototype.set_script( preload("res://units/PlayerAgent.gd") )
	agentPrototype.set_name("Agent")
	
	var player1Tank = get_node( "TankPlayer1" )
	if ( player1Tank != null ):
		var agentNode = agentPrototype.duplicate()
		agentNode.setActions( ["player1_move_up","player1_move_down",
			"player1_move_left", "player1_move_right", "player1_shoot"] )
		agentNode.assignToTank( player1Tank )
		player1Tank.add_to_group( player1Tank.PLAYERS_GROUP )
	
	var player2Tank = get_node( "TankPlayer2" )
	if ( player2Tank != null ):
		var agentNode = agentPrototype.duplicate()
		agentNode.setActions( ["player2_move_up","player2_move_down",
			"player2_move_left", "player2_move_right", "player2_shoot"] )
		agentNode.assignToTank( player2Tank )
		player1Tank.add_to_group( player2Tank.PLAYERS_GROUP )
	
	
var spawnTimesAndPositions = [ [1,4], [2,2], [3,3], [4,1] ]

func prepareSpawns():
	var spawnTimers = []
	for timeAndPosition in spawnTimesAndPositions:
		var enemySpawnTimer = Timer.new()
		enemySpawnTimer.set_wait_time( timeAndPosition[0] )
		enemySpawnTimer.set_one_shot(true)
		var conn = enemySpawnTimer.connect( "timeout", self, "spawnEnemyAtPosition", [timeAndPosition[1]] )
		spawnTimers.append( enemySpawnTimer )
	
	for spawnTimer in spawnTimers:
		self.add_child( spawnTimer )
		spawnTimer.start()
	
	
func spawnEnemyAtPosition(position):
	var enemySpawn = get_node("EnemySpawn" + str(position))
	
	if ( enemySpawn == null ):
		return
		
	var enemyTank = self.get_node("TankEnemyPrototype").duplicate()
	enemyTank.set_pos( enemySpawn.get_pos() )
	self.add_child(enemyTank)
	
	
	
	