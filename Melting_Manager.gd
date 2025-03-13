extends Node3D

# Arrays to hold data from the JSON and the MeshInstances we create.
var html_data: Array = []
var created_meshes: Array = []

# Paths to your resources. Adjust if needed.
var json_path = "res://resources/html.json"
var screenshot_path = "res://resources/screenshot.png"
var meltdown_shader_path = "res://meltdown_scripts/melt_shader.gdshader"

# Meltdown timing
var meltdown_duration = 5.0  # seconds to go from 0% to 100% melt
var meltdown_elapsed = 0.0
var meltdown_active = false

func _ready():
	# 1. Load the JSON data (image bounding boxes, etc.)
	load_html_data()
	
	# 2. Generate quads in 3D
	generate_3d_shapes()
	
	# 3. Start melting right away (optional; you could trigger this later)
	meltdown_active = true


func load_html_data():
	var file_path = "res://resources/html.json"
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Failed to open JSON file at path: %s" % file_path)
		return

	var raw_text = file.get_as_text()
	file.close()

	# Create a JSON parser
	var json_parser = JSON.new()

	# Parse the raw_text directly (no JSON.stringify)
	var parse_error = json_parser.parse(raw_text)
	if parse_error == OK:
		html_data = json_parser.data
		# Now html_data should be the array of objects from your file
		print(html_data)
	else:
		push_error("JSON parse error: %s" % json_parser.get_error_message())





func generate_3d_shapes() -> void:
	# Create a container node for organization
	var container = Node3D.new()
	container.name = "GeneratedShapes"
	add_child(container)

	# Load the meltdown shader resource
	var meltdown_shader_res = load(meltdown_shader_path)
	if meltdown_shader_res == null:
		push_error("Failed to load meltdown shader: %s" % meltdown_shader_path)
		return

	# Load the screenshot texture
	var screenshot_texture = load(screenshot_path)
	if screenshot_texture == null:
		push_error("Failed to load screenshot texture: %s" % screenshot_path)
		return

	# For each element in the JSON, create a quad
	for element in html_data:
		var x = element["x"]
		var y = element["y"]
		var w = element["width"]
		var h = element["height"]

		var shape_instance = create_quad(
			x, y, w, h,
			meltdown_shader_res,
			screenshot_texture
		)
		container.add_child(shape_instance)
		created_meshes.append(shape_instance)


func create_quad(
	x: float,
	y: float,
	w: float,
	h: float,
	meltdown_shader_res: Shader,
	screenshot_texture: Texture2D
) -> MeshInstance3D:
	# 1) Basic scaling from pixels to Godot 3D units
	var scale_factor = 0.01
	var pos_x = x * scale_factor
	var pos_y = y * scale_factor
	var size_w = w * scale_factor
	var size_h = h * scale_factor

	# 2) SurfaceTool to create a quad with UV(0..1, 0..1)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var v1 = Vector3(pos_x, pos_y, 0)
	var v2 = Vector3(pos_x + size_w, pos_y, 0)
	var v3 = Vector3(pos_x + size_w, pos_y + size_h, 0)
	var v4 = Vector3(pos_x, pos_y + size_h, 0)

	st.set_uv(Vector2(0, 0))
	st.add_vertex(v1)

	st.set_uv(Vector2(1, 0))
	st.add_vertex(v2)

	st.set_uv(Vector2(1, 1))
	st.add_vertex(v3)

	st.set_uv(Vector2(1, 1))
	st.add_vertex(v3)

	st.set_uv(Vector2(0, 1))
	st.add_vertex(v4)

	st.set_uv(Vector2(0, 0))
	st.add_vertex(v1)

	var array_mesh = ArrayMesh.new()
	st.commit(array_mesh)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = array_mesh

	# 3) Create a ShaderMaterial
	var mat = ShaderMaterial.new()
	mat.shader = meltdown_shader_res
	mat.set_shader_parameter("albedo_tex", screenshot_texture)

	# 4) The critical part: set uv1_offset/scale
	var screen_w = float(screenshot_texture.get_width())
	var screen_h = float(screenshot_texture.get_height())

	var offset_u = x / screen_w
	var offset_v = y / screen_h
	var scale_u  = w / screen_w
	var scale_v  = h / screen_h

	mat.set_shader_parameter("uv_offset", Vector2(offset_u, offset_v))
	mat.set_shader_parameter("uv_scale", Vector2(scale_u, scale_v))


	# 5) Apply material & position
	mesh_instance.set_surface_override_material(0, mat)

	# For a camera at (0,0,5) looking -Z, place the quad near (0,0,0)
	mesh_instance.transform.origin = Vector3(0, 0, 0)

	return mesh_instance



func _process(delta: float) -> void:
	# Check if the user just pressed the meltdown key
	if Input.is_action_just_pressed("start_meltdown"):
		meltdown_active = true
		meltdown_elapsed = 0.0  # Reset the timer if you want

	if meltdown_active:
		meltdown_elapsed += delta
		var factor = meltdown_elapsed / meltdown_duration
		if factor > 1.0:
			factor = 1.0
			meltdown_active = false  # optional: stop meltdown once fully melted

		# Update meltdown shader param on each quad
		for mesh in created_meshes:
			var mat = mesh.get_surface_override_material(0)
			if mat and mat is ShaderMaterial:
				mat.set_shader_parameter("melt_amount", factor)
