extends Area2D

func _ready():
	$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)

func _on_screen_exited():
	queue_free()

func speed_relative_to_player(velocidade_do_player: float, delta: float):
	position.x -= velocidade_do_player * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("COLISÃO! O obstáculo atingiu o jogador.")
		
		# Agora você decide o que fazer. Aqui estão algumas opções:

		# Opção A: Chamar uma função no script do player para ele "morrer".
		# (Para isso, você precisaria criar uma função 'die()' no seu player.gd)
		# if body.has_method("die"):
		#	 body.die()
		
		# Opção B: A mais simples para um "Game Over" - recarregar a cena do jogo.
		get_tree().reload_current_scene()
		
		# Opcional: O obstáculo se destrói ao colidir para não atingir de novo.
		# queue_free()
