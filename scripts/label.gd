# scrolling_label.gd
extends Label

# Vamos exportar uma variável para "conectar" o player a este script no editor.
@export var player: CharacterBody2D

# Você pode ajustar esta variável no Inspetor para fazer o texto
# se mover mais rápido ou mais lento que o jogador.
@export var scroll_speed_multiplier: float = 1.0

# Armazena a largura da tela para saber quando resetar a posição.
var screen_width: float

func _ready():
	# Pegamos o tamanho da tela uma vez no início.
	screen_width = get_viewport_rect().size.x

func _process(delta: float):
	# Verificação de segurança: não faz nada se o player não estiver conectado.
	if not is_instance_valid(player):
		return
	
	# 1. Pega a velocidade atual do player diretamente da variável dele.
	var player_speed = player._current_speed
	
	# 2. Move a posição X do Label para a esquerda.
	position.x -= player_speed * scroll_speed_multiplier * delta
	
	# 3. Lógica para o texto "dar a volta" (loop infinito).
	# Se a posição direita do texto saiu completamente pela esquerda da tela...
	if global_position.x < -size.x:
		# ...reposicionamos ele de volta no lado direito da tela.
		position.x = screen_width
