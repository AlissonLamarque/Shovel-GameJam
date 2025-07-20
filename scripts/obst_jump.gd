extends Area2D

@export var velocidade = 150.0

func _ready():
	$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)
	
func _process(delta):
	position.x -= velocidade * delta
	
func _on_screen_exited():
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	print("Colisão detectada com: ", body.name)
