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

@export_group("Posicionamento na Tela")
# VALOR ALTERADO: O deslocamento na velocidade zero agora é 0 (posição inicial).
@export var slow_speed_x_offset: float = 0.0 
# VALOR ALTERADO: Define o quão para a DIREITA o personagem vai em velocidade máxima.
@export var fast_speed_x_offset: float = 50.0
# Fator de suavização para o movimento de posição.
@export var position_lerp_factor: float = 0.05

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
var _initial_x_position: float # LÓGICA ALTERADA

# --- Referências de Nós ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


var _is_jumping = false


func _ready() -> void:
	# LÓGICA ALTERADA: Armazena a posição inicial do personagem no mundo do jogo.
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
		if is_equal_approx(_current_speed, 0.0):
			_is_sliding = false
	else:
		_time_since_last_input += delta
		if _time_since_last_input > input_timeout:
			_current_speed = max(0, _current_speed - constant_deceleration * delta)

	# 3. ATUALIZAR POSIÇÃO HORIZONTAL SUAVEMENTE
	_update_horizontal_position()

	# 4. ATUALIZAR ANIMAÇÕES
	_update_animation()

	# 5. MOVER O PERSONAGEM
	# move_and_slide() ainda é necessário para a gravidade e colisões verticais.
	move_and_slide()


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
		_is_jumping = true
	
	if event.is_action_released("jump") and velocity.y < 0:
		velocity.y *= jump_release_multiplier
		
	# --- LÓGICA DO DESLIZE ---
	if event.is_action_pressed("slide") and is_on_floor() and _current_speed > 0:
		_is_sliding = true
	
	if event.is_action_released("slide"):
		_is_sliding = false


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
	# LÓGICA ALTERADA: Mapeia a velocidade para um deslocamento relativo à posição inicial do personagem.
	var target_x = remap(_current_speed, 0, max_speed, _initial_x_position + slow_speed_x_offset, _initial_x_position + fast_speed_x_offset)
	
	# Interpola suavemente a posição atual do personagem para a posição alvo.
	global_position.x = lerp(global_position.x, target_x, position_lerp_factor)


func _update_animation() -> void:
	if _is_sliding:
		animated_sprite.play("slide")
		return

	if is_on_floor():
		if _current_speed >= 400:
			animated_sprite.play("run_fast")
		elif _current_speed >= 200:
			animated_sprite.play("run")
		elif _current_speed > 10.0:
			animated_sprite.play("walk")
		else:
			animated_sprite.play("idle")
	else:
		if _is_jumping:
			_is_jumping = false
			animated_sprite.play("jump")
