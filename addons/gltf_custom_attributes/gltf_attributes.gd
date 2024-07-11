@tool
extends EditorPlugin

var importer

func _enter_tree() -> void:
	importer = ExtrasImporter.new()
	GLTFDocument.register_gltf_document_extension(importer)

func _exit_tree() -> void:
	GLTFDocument.unregister_gltf_document_extension(importer)

class ExtrasImporter extends GLTFDocumentExtension:
	func _import_post(state: GLTFState, root: Node) -> Error:
		# Add metadata to ImporterMeshes
		var meshes_json: Array = state.json.get("meshes", [])
		var meshes: Array[GLTFMesh] = state.get_meshes()
		for mesh_i in range(meshes_json.size()):
			if not meshes_json[mesh_i].has("primitives"):
				continue
			var primitives = meshes_json[mesh_i].primitives
			for primitive_i in range(primitives.size()):
				if not primitives[primitive_i].has("attributes"):
					continue
				var attributes = primitives[primitive_i].attributes
				if not attributes.has("_DIE_FACE"):
					continue
				var accessor: GLTFAccessor = state.get_accessors()[attributes._DIE_FACE]
				var buffer_view: GLTFBufferView = state.get_buffer_views()[accessor.buffer_view]
				var buffer: PackedByteArray = state.get_buffers()[buffer_view.buffer]
				var face_values: PackedFloat32Array = []
				for die_face_i in accessor.count:
					var buffer_i = buffer_view.byte_offset + accessor.byte_offset + die_face_i * 4
					face_values.append(buffer.decode_float(buffer_i))
				var mesh: ImporterMesh = meshes[mesh_i].mesh
				mesh.set_meta("die_faces", face_values)

		# Add metadata to nodes
		var nodes_json: Array = state.json.get("nodes", [])
		for i in nodes_json.size():
			var node = state.get_scene_node(i)
			if !node:
				continue
			# Handle special case
			if node is ImporterMeshInstance3D and node.mesh and node.mesh.has_meta("die_faces"):
				# ImporterMeshInstance3D nodes will be converted later to either
				# MeshInstance3D or StaticBody3D and metadata will be lost
				# A sibling is created preserving the metadata. It can be later
				# merged back in using a EditorScenePostImport script
				var metadata_node = Node.new()

				# Meshes are also ImporterMeshes that will be later converted either
				# to ArrayMesh or some form of collision shape.
				# We'll save it as another metadata item. If the mesh is reused we'll
				# have duplicated info but at least it will always be accurate
				metadata_node.set_meta("die_faces", node.mesh.get_meta("die_faces"))

				# Well add it as sibling so metadata node always follows the actual metadata owner
				node.add_sibling(metadata_node)
				# Make sure owner is set otherwise it won't get serialized to disk
				metadata_node.owner = node.owner
				# Add a suffix to the generated name so it's easy to find
				metadata_node.name += "_meta"

		return OK
