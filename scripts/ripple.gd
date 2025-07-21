# RippleInstance.gd
# Script para a cena de uma única ondulação.

extends GPUParticles2D

# Esta variável receberá a velocidade do jogador.
var player_speed: float = 0.0

# Você pode ajustar este valor para mudar o quão rápido a ondulação se move para trás.
# 1.0 = mesma velocidade do cenário (se houvesse um).
var scroll_multiplier: float = 1

func _ready():
	# Inicia a emissão assim que a cena é criada.
	emitting = true
	# Cria um timer que espera a duração das partículas e depois libera a cena da memória.
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float):
	# Move a ondulação para a esquerda (para trás) com base na velocidade
	# que o jogador tinha quando a ondulação foi criada.
	global_position.x -= player_speed * scroll_multiplier * delta / 5
