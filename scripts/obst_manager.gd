extends Node2D

@export var cenas_obstaculos: Array[PackedScene]
@onready var spawn_timer: Timer = $Spawn_Timer
@onready var spawn_position: Marker2D = $Spawn_Position

func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
func _on_spawn_timer_timeout():
	if cenas_obstaculos.is_empty():
		return
		
	var obstaculo_escolhido = cenas_obstaculos.pick_random()
	var novo_obstaculo = obstaculo_escolhido.instantiate()
	 
	novo_obstaculo.global_position = Vector2(spawn_position.global_position.x, 200)

	add_child(novo_obstaculo)
