class_name Die extends RigidBody3D

static var dice_meshes_scene = preload("res://models/dice.tscn")
var display_mesh: Mesh
var collision_mesh: Mesh
var display_mesh_instance: MeshInstance3D
var highlight_material: ShaderMaterial
var face_normals: Dictionary

signal right_click(die: Die)
signal result(die: Die, result: int)

@export var type: Constants.DieType = Constants.DieType.D6
var resulted: bool = false
var highlighted: bool = false:
	set(value):
		highlighted = value
		if value:
			display_mesh_instance.get_active_material(0).next_pass = highlight_material
		else:
			display_mesh_instance.get_active_material(0).next_pass = null
	get:
		return highlighted

var audio_players: Array[AudioStreamPlayer]

static var wood_dice_hit_sample = preload("res://sounds/wood_dice_hit.ogg")
static var plastic_dice_hit_sample = preload("res://sounds/plastic_dice_hit.ogg")
static var outline_shader = preload("res://shaders/outline.gdshader")

static var samples: Dictionary = {
	"Wood": wood_dice_hit_sample,
	"Plastic": plastic_dice_hit_sample
}

const type_to_mesh_str: Dictionary = {
	Constants.DieType.D4: "d4_alt_fixed",
	Constants.DieType.D6: "d6",
	Constants.DieType.D8: "d8",
	Constants.DieType.D10: "d10",
	Constants.DieType.PERCENTILE: "d00",
	Constants.DieType.D12: "d12",
	Constants.DieType.D20: "d20"
}

func _init():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

# Called when the node enters the scene tree for the first time.
func _ready():
	var dice_meshes = dice_meshes_scene.instantiate()
	display_mesh = dice_meshes.get_node(type_to_mesh_str[type]).mesh
	collision_mesh = dice_meshes.get_node(type_to_mesh_str[type] + "_unbaked").mesh
	var surface: Array = collision_mesh.surface_get_arrays(0)
	var die_faces: PackedFloat32Array = collision_mesh.get_meta("die_faces", [])
	var normals = surface[Mesh.ARRAY_NORMAL]
	var index = surface[Mesh.ARRAY_INDEX]
	for i in range(0, index.size(), 3):
		face_normals[int(die_faces[index[i]])] = normals[index[i]]

	# Create mesh
	display_mesh_instance = MeshInstance3D.new()
	display_mesh_instance.set_mesh(display_mesh.duplicate())
	display_mesh_instance.set_position(Vector3(0, 0, 0))
	display_mesh_instance.material_override = display_mesh_instance.get_active_material(0).duplicate()

	# Set up highlighting shader
	highlight_material = ShaderMaterial.new()
	highlight_material.shader = outline_shader
	highlight_material.set_shader_parameter("border_width", 0.1)

	# Create collision shape
	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	collision_shape.set_shape(collision_mesh.create_convex_shape(false, false))
	collision_shape.add_child(display_mesh_instance)
	collision_shape.set_scale(Vector3(0.1, 0.1, 0.1))
	if type == Constants.DieType.D4:
		collision_shape.set_scale(Vector3(.5, .5, .5))

	contact_monitor = true
	max_contacts_reported = 4
	$AudioStreamPlayer.max_polyphony = 2
	add_child(collision_shape)

func _on_mouse_entered():
	print("hovered")
	highlighted = true

func _on_mouse_exited():
	print("unhovered")
	highlighted = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		print("right click")
		if highlighted:
			print("right click on highlighted object")
			right_click.emit(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

var last_linear_velocity: Vector3
var last_angular_velocity: Vector3
func _physics_process(delta: float) -> void:
	var colliding_bodies = get_colliding_bodies()
	var linear_jolt = last_linear_velocity.distance_to(linear_velocity)
	var angular_jolt = last_angular_velocity.distance_to(angular_velocity)

	for body in colliding_bodies:
		if "physics_material_override" in body and body.physics_material_override != null:
			var physics_material_name = body.physics_material_override.resource_name
			if samples.has(physics_material_name):
				$AudioStreamPlayer.stream = samples[physics_material_name]

			if linear_jolt > 1:
				$AudioStreamPlayer.volume_db = -45 + min(linear_jolt * 5, 40)
				$AudioStreamPlayer.play()
			if angular_jolt > 1:
				$AudioStreamPlayer.volume_db = -45 + min(angular_jolt * 5, 40)
				$AudioStreamPlayer.play()

	last_linear_velocity = linear_velocity
	last_angular_velocity = angular_velocity


func _on_sleeping_state_changed() -> void:
	if sleeping and not resulted:
		for face_value in face_normals:
			var face_transform: Vector3 = transform.basis * face_normals[face_value]
			if face_transform.distance_to(Vector3.UP) < 0.1:
				resulted = true
				result.emit(self, face_value)

	if sleeping and not resulted:
		print("ambiguous result")
		result.emit(self, -1)
