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
@export var slide_ripple_interval: float = 0.05

# --- Configurações da Trilha Sonora ---
@export_group("Configurações da Trilha Sonora")
@export var soundtrack_players: Array[AudioStreamPlayer]
@export var walk_loop_threshold: int = 3 # Repetições para adicionar camada ao andar
@export var run_loop_threshold: int = 1   # Repetições para adicionar camada ao correr
@export var music_fade_duration: float = 2.0 # Duração do fade in/out da música

# --- Variáveis de Física ---
@export_group("Física, Pulo e Deslize")
@export var gravity_scale: float = 1.0
@export var jump_velocity: float = -400.0
@export var jump_release_multiplier: float = 0.5
@export var slide_deceleration: float = 250.0 # Desaceleração rápida enquanto desliza.
@export_flags_2d_physics var slide_collision_layer: int

var control_enabled = true
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- Variáveis de Estado Interno ---
var _current_speed: float = 0.0
var _last_press_time: int = 0
var _last_key_direction: int = 0
var _time_since_last_input: float = 0.0
var _is_sliding: bool = false
var _initial_x_position: float
var _original_collision_layer: int

# --- Variáveis de estado da música ---
enum SpeedTier { STOPPED, WALKING, RUNNING }
var _current_speed_tier: SpeedTier = SpeedTier.STOPPED
var _loop_counters: Array[int] = []
var _active_music_layers: int = 0
var _soundtrack_timers: Array[Timer] = []

# --- Referências de Nós ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var step_timer: Timer = $StepTimer
@onready var slide_ripple_timer: Timer = $SlideRippleTimer
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var sound_timer: Timer = $SoundTimer

var rng = RandomNumberGenerator.new()
signal game_over

func _ready() -> void:
	# Armazena a posição inicial do personagem no mundo do jogo.
	_initial_x_position = global_position.x
	# Armazena a camada de colisão original do corpo.
	_original_collision_layer = self.collision_layer
	
	# Prepara o sistema de música com Timers em vez de sinais 'finished'.
	_loop_counters.resize(soundtrack_players.size())
	_loop_counters.fill(0)
	for i in soundtrack_players.size():
		var player = soundtrack_players[i]
		if player.stream:
			var timer = Timer.new()
			timer.name = "SoundtrackTimer_" + str(i)
			timer.wait_time = player.stream.get_length()
			timer.one_shot = false # O timer irá repetir
			timer.timeout.connect(_on_soundtrack_loop_finished.bind(i))
			_soundtrack_timers.append(timer)
			add_child(timer)
		else:
			push_warning("Soundtrack player at index %d has no audio stream." % i)


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
			slide_ripple_timer.stop() # Para o rastro se a velocidade zerar.
			self.collision_layer = _original_collision_layer # Reativa a colisão
	else:
		_time_since_last_input += delta
		if _time_since_last_input > input_timeout:
			_current_speed = max(0, _current_speed - constant_deceleration * delta)

	# 3. ATUALIZAR POSIÇÃO HORIZONTAL SUAVEMENTE
	_update_horizontal_position()
	
	# Atualiza a lógica da música a cada quadro
	_update_music_system()

	# 4. ATUALIZAR ANIMAÇÕES
	_update_animation()

	# Armazena o estado do chão ANTES de mover.
	var was_on_floor = is_on_floor()

	# 5. MOVER O PERSONAGEM
	move_and_slide()

	# 6. LÓGICA DE ATERRISSAGEM
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
		_spawn_ripple()
	
	if event.is_action_released("jump") and velocity.y < 0:
		velocity.y *= jump_release_multiplier
		
	# --- LÓGICA DO DESLIZE ---
	if event.is_action_pressed("slide") and is_on_floor() and _current_speed > 0:
		_is_sliding = true
		self.collision_layer = slide_collision_layer # Altera a camada de colisão
		slide_ripple_timer.wait_time = slide_ripple_interval
		slide_ripple_timer.start()
		_spawn_ripple() # Cria a primeira ondulação do deslize imediatamente.
	
	if event.is_action_released("slide"):
		if _is_sliding: # Só executa se estava realmente deslizando
			_is_sliding = false
			self.collision_layer = _original_collision_layer # Restaura a camada de colisão
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
			if _current_speed >= 400:
				animated_sprite.play("run_fast")
			elif _current_speed >= 200:
				animated_sprite.play("run")
			else:
				animated_sprite.play("walk")
			
			var animation_speed = remap(_current_speed, initial_speed, max_speed, min_animation_speed, max_animation_speed)
			animated_sprite.speed_scale = clamp(animation_speed, min_animation_speed, max_animation_speed)

			if step_timer.is_stopped():
				_spawn_ripple()
				
				var step_duration = 0.4 / animated_sprite.speed_scale
				step_timer.wait_time = clamp(step_duration, 0.1, 0.8)
				step_timer.start()
			
			# LÓGICA RESTAURADA: Som dos passos
			if sound_timer.is_stopped():
				audio_stream_player_2d.pitch_scale = rng.randf_range(0.9, 1.1)
				audio_stream_player_2d.play()
				
				var step_duration = 0.4 / animated_sprite.speed_scale
				sound_timer.wait_time = clamp(step_duration, 0.1, 0.8)
				sound_timer.start()
		else:
			animated_sprite.play("idle")
			animated_sprite.speed_scale = 1.0
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

# --- Funções do Sistema de Música ---

func _update_music_system():
	var new_speed_tier = _get_current_speed_tier()
	
	if new_speed_tier == _current_speed_tier:
		return

	match new_speed_tier:
		SpeedTier.STOPPED:
			for i in range(1, soundtrack_players.size()):
				_fade_out(soundtrack_players[i])
			_active_music_layers = 1
		
		SpeedTier.WALKING:
			if _current_speed_tier == SpeedTier.STOPPED:
				_fade_in(soundtrack_players[0])
				_active_music_layers = 1
			else: # Veio de RUNNING
				for i in range(2, soundtrack_players.size()):
					_fade_out(soundtrack_players[i])
				_active_music_layers = 2
		
		SpeedTier.RUNNING:
			if not soundtrack_players[0].playing:
				_fade_in(soundtrack_players[0])
				_active_music_layers = 1

	_current_speed_tier = new_speed_tier
	_loop_counters.fill(0)

func _get_current_speed_tier() -> SpeedTier:
	if _current_speed >= 200:
		return SpeedTier.RUNNING
	elif _current_speed > 10.0:
		return SpeedTier.WALKING
	else:
		return SpeedTier.STOPPED

# LÓGICA ALTERADA: Esta função agora é chamada pelo timeout do Timer.
func _on_soundtrack_loop_finished(layer_index: int):
	if layer_index >= _active_music_layers:
		return

	_loop_counters[layer_index] += 1
	
	var threshold = run_loop_threshold if _current_speed_tier == SpeedTier.RUNNING else walk_loop_threshold
	
	if _loop_counters[layer_index] >= threshold:
		var next_layer_index = layer_index + 1
		if next_layer_index < soundtrack_players.size():
			if not soundtrack_players[next_layer_index].playing:
				_fade_in(soundtrack_players[next_layer_index])
				_active_music_layers = next_layer_index + 1
				_loop_counters[layer_index] = 0

func _fade_in(player: AudioStreamPlayer):
	var index = soundtrack_players.find(player)
	if index == -1: return

	if player.playing and player.volume_db > -1.0:
		return
	
	var tween = create_tween().set_parallel(false)
	player.volume_db = -80.0
	player.play()
	_soundtrack_timers[index].start() # LÓGICA ALTERADA
	tween.tween_property(player, "volume_db", 0.0, music_fade_duration)

func _fade_out(player: AudioStreamPlayer):
	var index = soundtrack_players.find(player)
	if index == -1: return

	if not player.playing:
		return

	_soundtrack_timers[index].stop() # LÓGICA ALTERADA
	var tween = create_tween().set_parallel(false)
	tween.tween_property(player, "volume_db", -80.0, music_fade_duration)
	await tween.finished
	if player:
		player.stop()

# --- Funções de Efeitos Visuais ---

func _spawn_ripple():
	if ripple_scene:
		var ripple = ripple_scene.instantiate()
		get_parent().add_child(ripple)
		
		var ripple_position = global_position
		
		var x_offset = remap(_current_speed, 0, max_speed, 0.0, 15.0)
		ripple_position.x += x_offset
			
		ripple.global_position = ripple_position
		ripple.player_speed = _current_speed

func _on_step_timer_timeout():
	_spawn_ripple()

func _on_slide_ripple_timer_timeout():
	_spawn_ripple()

func die():
	control_enabled = false
	game_over.emit()
	velocity = Vector2.ZERO
