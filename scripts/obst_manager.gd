extends Node2D

@export var cenas_obstaculos: Array[PackedScene]
@export var player: CharacterBody2D
@onready var spawn_timer: Timer = $Spawn_Timer
@onready var spawn_position: Marker2D = $Spawn_Position

func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func _physics_process(delta: float):
	if not is_instance_valid(player):
		return

	# Pega a velocidade atual do player diretamente da sua variável.
	var velocidade_atual_player = player._current_speed
	
	# Se o jogador está se movendo e o timer está parado, o timer é iniciado
	if velocidade_atual_player > 5.0 and spawn_timer.is_stopped():
		spawn_timer.start()
	# Se o jogador parou e o timer está rodando, o timer é parado
	elif velocidade_atual_player <= 5.0 and not spawn_timer.is_stopped():
		spawn_timer.stop()

	# Passa por todos os filhos deste nó (que serão os obstáculos).
	for obstaculo in get_children():
		if obstaculo is Area2D:
			# Chama a função de movimento do obstáculo, passando a velocidade do player.
			obstaculo.speed_relative_to_player(velocidade_atual_player, delta)


func _on_spawn_timer_timeout():
	if cenas_obstaculos.is_empty():
		return
		
	var obstaculo_escolhido = cenas_obstaculos.pick_random()
	var novo_obstaculo = obstaculo_escolhido.instantiate()
	 
	novo_obstaculo.global_position = Vector2(spawn_position.global_position.x, 200)

	add_child(novo_obstaculo)
