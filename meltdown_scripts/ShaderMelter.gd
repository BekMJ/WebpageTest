extends Node
class_name ShaderMelter

var meltdown_material: ShaderMaterial
var is_active: bool = false

func _ready():
	# So we can animate meltdown in _process(delta)
	set_process(true)

func start_melting(objects: Array[MeshInstance3D]):
	meltdown_material = ShaderMaterial.new()
	meltdown_material.shader = load("res://meltdown_scripts/melt_shader.gdshader")

	for obj in objects:
		obj.material_override = meltdown_material

	is_active = true

func stop_melting(objects: Array[MeshInstance3D]):
	for obj in objects:
		obj.material_override = null
	is_active = false

func _process(delta: float):
	if is_active and meltdown_material:
		var strength = abs(sin(Time.get_ticks_msec() / 500.0))
		meltdown_material.set_shader_parameter("melt_strength", strength)
