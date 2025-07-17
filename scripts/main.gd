extends Node

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	animation_player.play("abertura")
