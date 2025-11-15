@tool
extends EditorScript

const TORCH_SCENE := preload("res://torch.tscn")  # <--- change to your path

func _run() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		push_error("Open the scene you want to modify (complete_build.tscn) and run again.")
		return

	var count := 0
	_add_torches_recursive(root, root, count)
	print("Added %d torches." % count)


func _add_torches_recursive(node: Node, scene_root: Node, count: int) -> void:
	for child in node.get_children():
		# Match your Empty nodes however you want
		if child is Node3D and child.name.begins_with("Empty"):
			var inst := TORCH_SCENE.instantiate()
			child.add_child(inst)

			# THIS is the important part: make it part of the saved scene
			inst.owner = scene_root   # or: inst.owner = child.owner

			count += 1

		# Recurse into children in case Empties are nested
		_add_torches_recursive(child, scene_root, count)
