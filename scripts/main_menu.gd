extends Control

# Sinal que será emitido para main quando o jogo deve começar
signal game_started
signal options_requested

# Nós que serão manipulados
@onready var button_container: VBoxContainer = $Button_Container
# @onready instancia_cutscene
# @onready animation_player_cutscene

func _ready():
	# Esconde o menu durante a animação de abertura
	#button_container.visible = false
	
	# Conecta o sinal de que a cutscene acabou
	# animation_player_cutscene.animation_finished.connect(_on_cutscene_finished)
	
	# Conecta os botões a suas respectivas funções
	$Button_Container/Start.pressed.connect(_on_start_button_pressed)
	$Button_Container/Options.pressed.connect(_on_options_button_pressed)
	$Button_Container/Quit.pressed.connect(_on_quit_button_pressed)
	
	# Inicia a cutscene
	# animation_player_cutscene.play("abertura")

func _on_start_button_pressed():
	# Emite o sinal para a main que o jogo deve começar
	game_started.emit()

func _on_options_button_pressed():
	# Emite o sinal para a main que as opções do menu foram solicitadas
	options_requested.emit()

func _on_quit_button_pressed():
	# Comando que fecha o jogo
	get_tree().quit()
