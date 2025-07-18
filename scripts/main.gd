extends Node

# Pré-carregamento das cenas que a main irá gerenciar
@export var game_scene: PackedScene

# Referência a cena que está atualmente na tela
var current_scene: Node

func _ready():
	# Assim que o jogo aberto coloca a cena do jogo na tela
	change_scene(game_scene)

func change_scene(scene_to_load: PackedScene):
	# 1. LIMPEZA: Remove a cena atual da memória, se houver uma.
	if is_instance_valid(current_scene):
		current_scene.queue_free()
	# 2. CRIAÇÃO: Cria uma nova instância da cena que queremos carregar.
	var new_scene_instance = scene_to_load.instantiate()
	# 3. CONEXÃO: Conecta os sinais da nova cena às funções deste maestro.
	if new_scene_instance.has_signal("game_started"):
		new_scene_instance.game_started.connect(_on_game_started)

	# if new_scene_instance.has_signal("game_over"):
	#	 new_scene_instance.game_over.connect(_on_game_over)
	# 4. ADIÇÃO: Adiciona a nova cena como FILHA do nó Main.
	add_child(new_scene_instance)
	# 5. ATUALIZAÇÃO: Atualiza nossa variável de referência para a nova cena.
	current_scene = new_scene_instance

func _on_game_started():
	change_scene(game_scene)

# func _on_game_over():
#	 print("Sinal 'game_over' recebido! Voltando para o menu...")
#	 change_scene(menu_scene)
