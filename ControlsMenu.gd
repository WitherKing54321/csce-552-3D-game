# res://UI/ControlsMenu.gd
extends Control

func _ready() -> void:
	# Make sure the node path matches your scene tree
	$ColorRect/VBoxContainer/BackButton.pressed.connect(_on_back_button_pressed)

func _on_back_button_pressed() -> void:
	# Go back to the main menu scene
	get_tree().change_scene_to_file("res://main_menu.tscn")
	# ^ change the path if your main menu scene is somewhere else
