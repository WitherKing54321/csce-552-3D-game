@tool
extends EditorScript

const TORCH_SCENE := preload("res://Objects/torch.tscn")           # your torch scene
const FLASH_PANE_SCENE := preload("res://Objects/flash_pane.tscn") # your flash pane scene

func _run() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		push_error("Open the scene you want to modify (e.g. complete_build.tscn) and run again.")
		return

	var counts := {
		"torches": 0,
		"windows": 0,
	}

	_add_children_recursive(root, root, counts)

	print("Added %d torches and %d window flash panes."
		% [counts["torches"], counts["windows"]])


func _add_children_recursive(node: Node, scene_root: Node, counts: Dictionary) -> void:
	for child in node.get_children():
		if child is Node3D:
			var name := str(child.name)
			var lower_name := name.to_lower()

			# Only operate on "empties" (any node whose name contains "empty")
			if lower_name.contains("empty"):
				# If the empty name also has "window" anywhere -> flash pane
				if lower_name.contains("window"):
					if FLASH_PANE_SCENE:
						var flash_inst := FLASH_PANE_SCENE.instantiate()
						child.add_child(flash_inst)
						flash_inst.owner = scene_root
						flash_inst.transform = Transform3D.IDENTITY
						counts["windows"] += 1
				# Otherwise -> torch
				else:
					if TORCH_SCENE:
						var torch_inst := TORCH_SCENE.instantiate()
						child.add_child(torch_inst)
						torch_inst.owner = scene_root
						counts["torches"] += 1

		# Recurse
		_add_children_recursive(child, scene_root, counts)
