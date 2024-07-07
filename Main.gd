extends Node3D

const Die = preload("res://Die.tscn")
const ControlsUI = preload("res://ControlsUI.tscn")
const RightClickMenu = preload("res://RightClickMenu.tscn")
var dice: Array[Die] = []

func bipolar_randf() -> float:
	return (randf() * 2) - 1

func _init() -> void:
	print("running")

# Called when the node enters the scene tree for the first time.
func _ready():
	var ui = ControlsUI.instantiate()
	ui.title = "Controls"
	ui.close_requested.connect(func(): get_tree().quit())
	ui.find_child("d4_button").pressed.connect(func(): spawn_die(Constants.DieType.D4))
	ui.find_child("d6_button").pressed.connect(func(): spawn_die(Constants.DieType.D6))
	ui.find_child("d8_button").pressed.connect(func(): spawn_die(Constants.DieType.D8))
	ui.find_child("d10_button").pressed.connect(func(): spawn_die(Constants.DieType.D10))
	ui.find_child("d100_button").pressed.connect(func():
		spawn_die(Constants.DieType.D10)
		spawn_die(Constants.DieType.PERCENTILE)
	)
	ui.find_child("d12_button").pressed.connect(func(): spawn_die(Constants.DieType.D12))
	ui.find_child("d20_button").pressed.connect(func(): spawn_die(Constants.DieType.D20))
	ui.find_child("clear_button").pressed.connect(func():
		while dice.size() > 0:
			var die: Die = dice.pop_back()
			die.queue_free()
	)
	add_child(ui)

func spawn_die(type: Constants.DieType) -> void:
	var instance: Die = Die.instantiate()
	instance.type = type
	instance.rotate_x(bipolar_randf() * 2 * PI)
	instance.rotate_y(bipolar_randf() * 2 * PI)
	instance.rotate_z(bipolar_randf() * 2 * PI)
	instance.set_position(Vector3(bipolar_randf() * 8, (randf() + 1) * 5, bipolar_randf() * 8))
	instance.apply_impulse(Vector3(
		bipolar_randf() * 10,
		bipolar_randf() * 10,
		bipolar_randf() * 10
	))
	instance.apply_torque(Vector3(
		bipolar_randf() * 10,
		bipolar_randf() * 10,
		bipolar_randf() * 10
	))
	dice.append(instance)
	add_child(instance)
	instance.right_click.connect(_on_right_click)

func _on_right_click(die: Die):
	var right_click_menu = RightClickMenu.instantiate()
	$Camera3D.add_child(right_click_menu)
	right_click_menu.show()
	print((right_click_menu.get_child(0) as PanelContainer).get_global_rect())
	print(get_viewport().get_visible_rect())
	right_click_menu.set_global_position(get_viewport().get_mouse_position())
	right_click_menu.find_child("reroll_button").pressed.connect(func ():
		spawn_die(die.type)
		var i = dice.find(die)
		if i != -1:
			dice.remove_at(i)
		die.queue_free()
		right_click_menu.queue_free()
	)
	right_click_menu.find_child("delete_button").pressed.connect(func ():
		var i = dice.find(die)
		if i != -1:
			dice.remove_at(i)
		die.queue_free()
		right_click_menu.queue_free()
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
