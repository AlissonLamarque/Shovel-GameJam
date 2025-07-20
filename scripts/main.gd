extends Node

# Pré-carregamento das cenas que a main irá gerenciar
@export var game_scene: PackedScene
@export var menu_scene: PackedScene
@export var game_over_scene: PackedScene

# Referência a cena que está atualmente na tela
var current_scene: Node

func _ready():
	# Assim que o jogo aberto coloca a cena do menu principal na tela
	change_scene(menu_scene)

func change_scene(scene_to_load: PackedScene):
	# 1. LIMPEZA: Remove a cena atual da memória, se houver uma.
	if is_instance_valid(current_scene):
		current_scene.queue_free()
	# 2. CRIAÇÃO: Cria uma nova instância da cena que queremos carregar.
	var new_scene_instance = scene_to_load.instantiate()
	# 3. CONEXÃO: Conecta os sinais da nova cena às funções deste maestro.
	if new_scene_instance.has_signal("game_started"):
		new_scene_instance.game_started.connect(_on_game_started)
	
	# Conecta o sinal do Player (que está dentro da cena do jogo)
	if scene_to_load == game_scene:
		# Tentamos encontrar o nó do Player dentro da cena do jogo.
		var player_node = new_scene_instance.get_node_or_null("Player") 
		if player_node and player_node.has_signal("game_over"):
			# Conectamos o sinal 'game_over' do player à nossa função _on_game_over.
			player_node.game_over.connect(_on_game_over)
	
	if new_scene_instance is GameOverScreen:
		# E conectamos os sinais na INSTÂNCIA, não na cena pré-carregada.
		new_scene_instance.restart_requested.connect(_on_restart_requested)
		new_scene_instance.main_menu_requested.connect(_on_main_menu_requested)

	# 4. ADIÇÃO: Adiciona a nova cena como FILHA do nó Main.
	add_child(new_scene_instance)
	# 5. ATUALIZAÇÃO: Atualiza nossa variável de referência para a nova cena.
	current_scene = new_scene_instance

func _on_game_started():
	change_scene(game_scene)

func _on_game_over():
	print("Sinal gameover recebido")
	change_scene(game_over_scene)

func _on_restart_requested():
	print("Sinal 'retry_requested' recebido! Reiniciando o jogo...")
	change_scene(game_scene)

func _on_main_menu_requested():
	print("Sinal 'main_menu_requested' recebido! Voltando ao menu...")
	change_scene(menu_scene)
