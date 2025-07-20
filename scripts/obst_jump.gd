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
	
		if body.has_method("die"):
			body.die()
		
		queue_free()
