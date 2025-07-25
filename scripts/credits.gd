extends Control

signal menu_requested

@onready var return_button: Button = $Return

func _ready():
	# Conecta o sinal 'pressed' do botão à nossa função de retorno.
	return_button.pressed.connect(_on_return_button_pressed)

# Esta função é chamada quando o botão "Voltar" é pressionado.
func _on_return_button_pressed():
	menu_requested.emit()
