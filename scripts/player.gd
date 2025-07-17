# player_controller.gd
# Script para um CharacterBody2D controlado por cliques alternados de setas.
# A velocidade do personagem é baseada na rapidez com que o jogador alterna
# entre as teclas esquerda e direita.

extends CharacterBody2D

# --- Variáveis de Movimento (Ajuste no Inspetor) ---
@export_group("Parâmetros de Corrida")
@export var max_speed: float = 450.0 # A velocidade máxima que o personagem pode atingir.
@export var speed_boost_factor: float = 35000.0 # Fator principal para calcular o impulso. Ajuste para sentir a velocidade ideal.
@export var deceleration: float = 15.0 # Quão rápido o personagem para quando os cliques cessam. Um valor maior significa uma parada mais abrupta.
@export var input_timeout: float = 0.4 # Tempo em segundos para considerar que o jogador parou de clicar e começar a desacelerar.
@export var initial_speed: float = 60.0 # Uma pequena velocidade inicial para o personagem sair do lugar.
@export var same_key_penalty: float = 0.25 # Penalidade ao clicar na mesma tecla (ex: 0.25 = perde 25% da velocidade atual).

# --- Variáveis de Física ---
@export_group("Física")
@export var gravity_scale: float = 1.0 # Multiplicador para a gravidade padrão do projeto.

# Variável para armazenar a gravidade do projeto.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- Variáveis de Controle Interno (Não mexer) ---
var _current_speed: float = 0.0
var _last_press_time: int = 0 # Usaremos milissegundos (ticks) para mais precisão.
var _last_key_direction: int = 0 # -1 para esquerda, 1 para direita, 0 para nenhum.
var _time_since_last_input: float = 0.0

# --- Referências de Nós ---
# Garanta que seu personagem tenha um nó AnimatedSprite2D para o visual.
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	# 1. APLICAR GRAVIDADE
	if not is_on_floor():
		velocity.y += gravity * gravity_scale * delta

	# 2. GERENCIAR DESACELERAÇÃO
	_time_since_last_input += delta
	if _time_since_last_input > input_timeout:
		_current_speed = lerp(_current_speed, 0.0, deceleration * delta)

	# 3. APLICAR MOVIMENTO HORIZONTAL (DESATIVADO)
	# A linha abaixo foi comentada para impedir que o personagem se mova.
	# velocity.x = _current_speed * _last_key_direction

	# 4. ATUALIZAR ANIMAÇÕES
	_update_animation()

	# 5. MOVER O PERSONAGEM
	# move_and_slide() ainda é chamado para aplicar a gravidade e manter a física do chão.
	move_and_slide()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed():
		return

	var current_direction: int = 0
	if event.is_action_pressed("ui_left"):
		current_direction = -1
	elif event.is_action_pressed("ui_right"):
		current_direction = 1

	if current_direction == 0:
		return

	# --- LÓGICA DE VELOCIDADE (CORRIGIDA E SIMPLIFICADA) ---

	# Reinicia o contador de timeout.
	_time_since_last_input = 0.0
	
	# A linha abaixo foi comentada para impedir que o sprite vire.
	# animated_sprite.flip_h = (current_direction == -1)

	# CASO 1: É o primeiro clique da corrida.
	if _last_key_direction == 0:
		_current_speed = initial_speed
	
	# CASO 2: O jogador alternou a direção (o que queremos!).
	elif current_direction != _last_key_direction:
		var time_now: int = Time.get_ticks_msec()
		var time_diff: int = time_now - _last_press_time
		if time_diff > 0:
			var speed_from_timing = speed_boost_factor / float(time_diff)
			# Aumenta a velocidade, mas sem deixar que ela caia abaixo da atual.
			_current_speed = clamp(speed_from_timing, _current_speed, max_speed)
	
	# CASO 3: O jogador pressionou a mesma tecla (NOVA LÓGICA).
	elif current_direction == _last_key_direction:
		# Penaliza a velocidade, reduzindo-a pelo fator de penalidade.
		_current_speed *= (1.0 - same_key_penalty)
	
	# Em todos os casos de clique válido, atualizamos o tempo e a direção.
	_last_press_time = Time.get_ticks_msec()
	_last_key_direction = current_direction


func _update_animation() -> void:
	# Lógica de animação revisada para ser mais clara.
	if is_on_floor():
		# Usamos uma cadeia if/elif para garantir que apenas uma animação toque por vez.
		# Verificamos da mais rápida para a mais lenta.
		if _current_speed >= 400:
			animated_sprite.play("run_fast")
		elif _current_speed >= 200:
			animated_sprite.play("run")
		elif _current_speed > 10.0: # Um pequeno limiar para evitar "walk" quando quase parado.
			animated_sprite.play("walk")
		else:
			animated_sprite.play("idle")
	else:
		animated_sprite.play("jump")
