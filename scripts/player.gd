# player_controller.gd
# Script para um CharacterBody2D com corrida, pulo de altura variável e deslize.

extends CharacterBody2D

# --- Variáveis de Movimento (Ajuste no Inspetor) ---
@export_group("Parâmetros de Corrida")
@export var max_speed: float = 450.0
@export var speed_boost_factor: float = 35000.0
@export var constant_deceleration: float = 100.0
@export var input_timeout: float = 0.4
@export var initial_speed: float = 60.0
@export var same_key_penalty: float = 0.25
@export var speed_lerp_factor: float = 0.2 
# Controle da velocidade da animação
@export var min_animation_speed: float = 0.8 # Velocidade da animação quando o personagem está lento
@export var max_animation_speed: float = 1.5 # Velocidade da animação quando o personagem está rápido

@export_group("Posicionamento na Tela")
@export var slow_speed_x_offset: float = 0.0 
@export var fast_speed_x_offset: float = 50.0
@export var position_lerp_factor: float = 0.05

# Referência para a cena da ondulação e seu controle
@export_group("Efeitos Visuais")
@export var ripple_scene: PackedScene
@export var idle_ripple_interval: float = 2.5 # Intervalo da ondulação quando parado
# NOVO: Intervalo para o rastro de ondulações durante o deslize.
@export var slide_ripple_interval: float = 0.05

# --- Variáveis de Física ---
@export_group("Física, Pulo e Deslize")
@export var gravity_scale: float = 1.0
@export var jump_velocity: float = -400.0
@export var jump_release_multiplier: float = 0.5
@export var slide_deceleration: float = 250.0 # Desaceleração rápida enquanto desliza.

var control_enabled = true
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- Variáveis de Estado Interno ---
var _current_speed: float = 0.0
var _last_press_time: int = 0
var _last_key_direction: int = 0
var _time_since_last_input: float = 0.0
var _is_sliding: bool = false
var _initial_x_position: float

# --- Referências de Nós ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var step_timer: Timer = $StepTimer
# NOVO: Timer para o rastro de ondulações do deslize.
@onready var slide_ripple_timer: Timer = $SlideRippleTimer



func _ready() -> void:
	# Armazena a posição inicial do personagem no mundo do jogo.
	_initial_x_position = global_position.x


func _physics_process(delta: float) -> void:
	if !control_enabled:
		return
		
	# 1. APLICAR GRAVIDADE
	if not is_on_floor():
		velocity.y += gravity * gravity_scale * delta

	# 2. GERENCIAR DESACELERAÇÃO
	if _is_sliding:
		_current_speed = max(0, _current_speed - slide_deceleration * delta)
		# Para de deslizar se a velocidade zerar.
		if is_equal_approx(_current_speed, 0.0):
			_is_sliding = false
			slide_ripple_timer.stop() # Para o rastro se a velocidade zerar.
	else:
		# Desaceleração normal da corrida.
		_time_since_last_input += delta
		if _time_since_last_input > input_timeout:
			_current_speed = max(0, _current_speed - constant_deceleration * delta)

	# 3. ATUALIZAR POSIÇÃO HORIZONTAL SUAVEMENTE
	_update_horizontal_position()

	# 4. ATUALIZAR ANIMAÇÕES
	_update_animation()

	# Armazena o estado do chão ANTES de mover.
	var was_on_floor = is_on_floor()

	# 5. MOVER O PERSONAGEM
	move_and_slide()

	# 6. LÓGICA DE ATERRISSAGEM (NOVO)
	# Se não estava no chão antes, mas está agora, significa que acabou de aterrissar.
	if not was_on_floor and is_on_floor():
		_spawn_ripple()


func _input(event: InputEvent) -> void:
	if !control_enabled:
		return

	# --- LÓGICA DA CORRIDA ---
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		if not _is_sliding:
			var current_direction: int = 0
			if event.is_action_pressed("ui_left"):
				current_direction = -1
			elif event.is_action_pressed("ui_right"):
				current_direction = 1
			
			if current_direction != 0:
				_process_running_input(current_direction)
	
	# --- LÓGICA DO PULO ---
	if event.is_action_pressed("jump") and is_on_floor() and not _is_sliding:
		velocity.y = jump_velocity

		# LÓGICA ALTERADA: Cria uma ondulação no momento do pulo.
		_spawn_ripple()

	
	if event.is_action_released("jump") and velocity.y < 0:
		velocity.y *= jump_release_multiplier
		
	# --- LÓGICA DO DESLIZE ---
	if event.is_action("slide") and is_on_floor() and _current_speed > 0:
		_is_sliding = true
		# NOVO: Inicia o timer para o rastro de ondulações do deslize.
		slide_ripple_timer.wait_time = slide_ripple_interval
		slide_ripple_timer.start()
		_spawn_ripple() # Cria a primeira ondulação do deslize imediatamente.
	
	if event.is_action_released("slide"):
		_is_sliding = false
		# NOVO: Para o rastro de ondulações ao soltar o botão.
		slide_ripple_timer.stop()


func _process_running_input(current_direction: int) -> void:
	_time_since_last_input = 0.0
	# animated_sprite.flip_h = (current_direction == -1)

	if _last_key_direction == 0:
		_current_speed = initial_speed
	elif current_direction != _last_key_direction:
		var time_now: int = Time.get_ticks_msec()
		var time_diff: int = time_now - _last_press_time
		if time_diff > 0:
			var speed_from_timing = speed_boost_factor / float(time_diff)
			var target_speed = clamp(speed_from_timing, 0, max_speed)
			_current_speed = lerp(_current_speed, target_speed, speed_lerp_factor)
	elif current_direction == _last_key_direction:
		_current_speed *= (1.0 - same_key_penalty)
	
	_last_press_time = Time.get_ticks_msec()
	_last_key_direction = current_direction


func _update_horizontal_position() -> void:
	# Mapeia a velocidade para um deslocamento relativo à posição inicial do personagem.
	var target_x = remap(_current_speed, 0, max_speed, _initial_x_position + slow_speed_x_offset, _initial_x_position + fast_speed_x_offset)
	
	# Interpola suavemente a posição atual do personagem para a posição alvo.
	global_position.x = lerp(global_position.x, target_x, position_lerp_factor)


func _update_animation() -> void:
	if _is_sliding:
		animated_sprite.play("slide")
		animated_sprite.speed_scale = 1.0
		step_timer.stop() # Garante que não haja ripples de passos ao deslizar
		return

	if is_on_floor():
		if _current_speed > 10.0:
			# Escolhe a animação correta baseada na velocidade
			if _current_speed >= 400:
				animated_sprite.play("run_fast")
			elif _current_speed >= 200:
				animated_sprite.play("run")
			else:
				animated_sprite.play("walk")
			
			# Mapeia a velocidade do personagem para a velocidade da animação
			var animation_speed = remap(_current_speed, initial_speed, max_speed, min_animation_speed, max_animation_speed)
			animated_sprite.speed_scale = clamp(animation_speed, min_animation_speed, max_animation_speed)

			# Controla o timer dos passos para o efeito de ondulação
			if step_timer.is_stopped():
				# Dispara a primeira ondulação imediatamente ao começar a andar.
				_spawn_ripple()
				
				var step_duration = 0.4 / animated_sprite.speed_scale
				step_timer.wait_time = clamp(step_duration, 0.1, 0.8)
				step_timer.start()
		else:
			# Animação de parado com velocidade normal
			animated_sprite.play("idle")
			animated_sprite.speed_scale = 1.0
			# Timer continua rodando lentamente quando parado.
			if step_timer.is_stopped():
				step_timer.wait_time = idle_ripple_interval
				step_timer.start()
	else:
  
		if velocity.y < 0:
			animated_sprite.play("jumping")
		else:
			animated_sprite.play("falling")

		animated_sprite.speed_scale = 1.0
		step_timer.stop()

# Função para criar a ondulação foi separada para ser reutilizada.
func _spawn_ripple():
	if ripple_scene:
		var ripple = ripple_scene.instantiate()
		get_parent().add_child(ripple)
		
		var ripple_position = global_position
		
		# Interpola o deslocamento da ondulação com base na velocidade.
		var x_offset = remap(_current_speed, 0, max_speed, 0.0, 15.0)
		ripple_position.x += x_offset
			
		ripple.global_position = ripple_position
		ripple.player_speed = _current_speed

func _on_step_timer_timeout():
	# O timer agora chama a mesma função de criação de ondulação.
	_spawn_ripple()

# NOVO: Função chamada pelo novo Timer para o rastro do deslize.
func _on_slide_ripple_timer_timeout():
	_spawn_ripple()
