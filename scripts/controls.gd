extends Control

signal menu_requested

@onready var return_button: Button = $Return

func _ready():
	return_button.pressed.connect(_on_return_button_pressed)

func _on_return_button_pressed():
	menu_requested.emit()
