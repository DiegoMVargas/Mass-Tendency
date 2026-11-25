extends Control

# Conecte os sinais dos botões ou use o _ready para puxá-los por código:
@onready var btn_fase_1: Button = $VBoxContainer/BtnFase1
@onready var btn_fase_2: Button = $VBoxContainer/BtnFase2

func _ready() -> void:
	# Garante que o mouse fique visível no menu
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Conecta os cliques dos botões às funções de mudança de fase
	btn_fase_1.pressed.connect(_on_fase_1_pressed)
	btn_fase_2.pressed.connect(_on_fase_2_pressed)

func _on_fase_1_pressed() -> void:
	# Altere o caminho para onde salvou a cena da Fase 1
	get_tree().change_scene_to_file("res://scenes/fase1.tscn")

func _on_fase_2_pressed() -> void:
	# Altere o caminho para onde salvou a cena da Fase 2
	get_tree().change_scene_to_file("res://scenes/fase2.tscn")
