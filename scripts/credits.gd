extends Control

signal menu_requested

@onready var return_button: Button = $Return

func _ready():
	# Conecta o sinal 'pressed' do botão à nossa função de retorno.
	return_button.pressed.connect(_on_return_button_pressed)

# Esta função é chamada quando o botão "Voltar" é pressionado.
func _on_return_button_pressed():
	print("Botão Voltar pressionado, emitindo sinal 'back_to_menu_requested'...")
	menu_requested.emit()
