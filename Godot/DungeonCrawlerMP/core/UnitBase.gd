extends KinematicBody2D

const Speed = 3
const UnitNameLabel = "Name"

puppet var  m_puppet_pos
master var m_movement = Vector2(0,0)   setget setMovement
var m_rpcTargets = []                  # setRpcTargets
var m_unitOwner = 0


signal predelete()

func _init():
	Debug.updateVariable("Unit count", +1, true)


func _ready():
	m_puppet_pos = self.position


func set_position( pos ):
	.set_position( pos )
	m_puppet_pos = pos


func _physics_process(delta):
	if ( Network.isServer() ):
		if (m_movement != Vector2(0,0)):
			var previousPos = self.position
			move_and_collide( m_movement.normalized() * Speed )

			if self.position != previousPos:
				Network.RSETu(self, ["m_puppet_pos", self.position] )
	else:
		set_position(m_puppet_pos)


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		emit_signal( "predelete" )
		Debug.updateVariable("Unit count", -1, true)


master func setMovement( movement : Vector2 ):
	if get_tree() != null and get_tree().get_rpc_sender_id() in [0, m_unitOwner]:
		m_movement = movement


puppet func setNameLabel( newName ):
	get_node(UnitNameLabel).text = newName

	if is_inside_tree() and is_network_master():
		Network.RPC( self, ["setNameLabel", newName] )


func setRpcTargets( clientIds ):
	Network.setRpcTargets( self, clientIds )


func setUnitOwner( networkId : int ):
	m_unitOwner = networkId


func sendToClient(clientId):
	Network.RPCid( self, clientId, ["deserialize", serialize()] )


func serialize():
	var saveData = {
		posX = get_position().x,
		posY = get_position().y,
	}
	return saveData


puppet func deserialize(saveDict):
	set_position( Vector2(saveDict.posX, saveDict.posY) )
	m_puppet_pos = position

