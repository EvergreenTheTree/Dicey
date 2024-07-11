@tool
extends EditorScenePostImport

var verbose := true

func _post_import(scene: Node) -> Object:
	print("post_import")
	_merge_extras(scene)
	return scene

func _merge_extras(scene: Node) -> void:
	var verbose_output = []
	var nodes: Array[Node] = scene.find_children("*" + "_meta", "Node")
	verbose_output.append_array(["Metadata nodes:",  nodes])
	for node in nodes:
		var parent = node.get_parent()
		if !parent:
			verbose_output.append("Node %s has no parent" % node)
			continue
		var idx_original = node.get_index() - 1
		if idx_original < 0 or parent.get_child_count() <= idx_original:
			verbose_output.append("Original node index %s is out of bounds. Parent child count: %s" % [idx_original, parent.get_child_count()])
			continue
		var original = node.get_parent().get_child(idx_original)
		if original:
			verbose_output.append("Setting extras metadata for %s" % original)
			if node.has_meta("die_faces"):
				if original is MeshInstance3D and original.mesh:
					verbose_output.append("Setting extras metadata for mesh %s" % original.mesh)
					original.mesh.set_meta("die_faces", node.get_meta("die_faces"))
		else:
			verbose_output.append("Original node not found for %s" % node)
		node.queue_free()

	if verbose:
		for item in verbose_output:
			print(item)
