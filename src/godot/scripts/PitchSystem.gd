extends Node3D

func _ready() -> void:
	# Build SubViewport that renders the 2D pitch line markings once
	var vp := SubViewport.new()
	vp.name = "PitchViewport"
	vp.size = Vector2i(2048, 1024)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)

	vp.add_child(load("res://scripts/ProceduralPitch.gd").new())

	# Build ShaderMaterial that combines tiled grass + line viewport texture
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/pitch.gdshader")
	mat.set_shader_parameter("grass_texture",
		load("res://assets/textures/pitch/seamlessgrass08.png"))
	mat.set_shader_parameter("lines_texture", vp.get_texture())

	# Apply to pitch mesh (material_override overrides surface materials)
	var pitch_mesh: MeshInstance3D = get_node_or_null("../Pitch/MeshInstance3D")
	if pitch_mesh:
		pitch_mesh.material_override = mat
