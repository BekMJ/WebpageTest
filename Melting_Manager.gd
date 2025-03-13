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
		var html_data = json_parser.data
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
	# Scale factor to convert pixel coords to Godot 3D units
	var scale_factor = 0.01
	var pos_x = x * scale_factor
	var pos_y = y * scale_factor
	var size_w = w * scale_factor
	var size_h = h * scale_factor

	# Use SurfaceTool to build a flat rectangle
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Four corners in 3D space
	var v1 = Vector3(pos_x, pos_y, 0)
	var v2 = Vector3(pos_x + size_w, pos_y, 0)
	var v3 = Vector3(pos_x + size_w, pos_y + size_h, 0)
	var v4 = Vector3(pos_x, pos_y + size_h, 0)

	# Assign UVs for a simple 0..1 mapping
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

	# Rotate so the quad faces up if camera is above (looking down -Z)
	mesh_instance.transform.origin = Vector3(0, 0, -5)


	# Create a ShaderMaterial for meltdown
	var mat = ShaderMaterial.new()
	mat.shader = meltdown_shader_res
	mat.set_shader_param("albedo_tex", screenshot_texture)

	# Assign the material to the mesh
	mesh_instance.set_surface_override_material(0, mat)

	return mesh_instance


func _process(delta: float) -> void:
	# If meltdown is active, animate "melt_amount" from 0 to 1
	if meltdown_active:
		meltdown_elapsed += delta
		var meltdown_factor = meltdown_elapsed / meltdown_duration

		if meltdown_factor >= 1.0:
			meltdown_factor = 1.0
			meltdown_active = false  # optional: stop updating once fully melted

		# Update the shader param on each quad
		for shape in created_meshes:
			var mat = shape.get_surface_override_material(0)
			if mat and mat is ShaderMaterial:
				mat.set_shader_param("melt_amount", meltdown_factor)
