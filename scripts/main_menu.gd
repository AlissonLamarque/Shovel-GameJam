extends Control

# Sinal que será emitido para main quando o jogo deve começar
signal game_started
signal options_requested

# Nós que serão manipulados
@onready var button_container: VBoxContainer = $Button_Container
@onready var cutscene_opening: Node2D = $Cutscene_Opening
@onready var animation_player: AnimationPlayer = $Cutscene_Opening/AnimationPlayer


func _ready():
	# Estabelece uma função para quando terminar a cutscene
	animation_player.animation_finished.connect(_on_animation_finished)
	
	# Conecta os botões a suas respectivas funções
	$Button_Container/Start.pressed.connect(_on_start_button_pressed)
	$Button_Container/Options.pressed.connect(_on_options_button_pressed)
	$Button_Container/Quit.pressed.connect(_on_quit_button_pressed)
	
	# Inicia a cutscene
	animation_player.play("opening")

func _on_start_button_pressed():
	# Emite o sinal para a main que o jogo deve começar
	game_started.emit()

func _on_options_button_pressed():
	# Emite o sinal para a main que as opções do menu foram solicitadas
	options_requested.emit()

func _on_quit_button_pressed():
	# Comando que fecha o jogo
	get_tree().quit()

func _on_animation_finished(anim_name: String):
	# Verificação se a animação que terminou é a de abertura
	if anim_name == "opening":
		# Habilita todos os botões para que se tornem clicáveis.
		for button in button_container.get_children():
			if button is Button:
				button.disabled = false
