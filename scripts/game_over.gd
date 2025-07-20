class_name GameOverScreen
extends Control

signal restart_requested
signal main_menu_requested

@onready var game_over_label: Label = $VBoxContainer/Game_Over_Label
@onready var restart_button: Button = $VBoxContainer/Restart
@onready var main_menu_button: Button = $VBoxContainer/Main_Menu

func _ready():
	restart_button.pressed.connect(_on_restart_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)

func _on_restart_button_pressed():
	restart_requested.emit()

func _on_main_menu_button_pressed():
	main_menu_requested.emit()
