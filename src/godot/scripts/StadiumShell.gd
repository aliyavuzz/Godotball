extends Node3D

# Stadium shell: tribünler, kale ağları, reklam panoları, scoreboard, projektör kuleleri, gece gökyüzü
# Tüm geometri runtime'da üretilir — sahne dosyasında sadece tek bir node girişi yeterli.

const PITCH_W := 105.0
const PITCH_H := 68.0

func _ready() -> void:
	_build_stands()
	_build_goal_nets()
	_build_ad_boards()
	_build_scoreboard()
	_build_floodlights()
	_setup_night_sky()
	_disable_sun()

# ── helpers ──────────────────────────────────────────────────────────────────

func _mat(color: Color, roughness: float = 0.9, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

func _mi(mesh: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	return mi

# ── tribünler ─────────────────────────────────────────────────────────────────

func _build_stands() -> void:
	var concrete := _mat(Color(0.22, 0.22, 0.25))
	var seats    := _mat(Color(0.10, 0.32, 0.72))  # koyu mavi koltuklar

	# ── Uzun kenar tribünleri (Kuzey +Z, Güney -Z) ──────────────────────────
	var sw := PITCH_W + 22.0   # 127 m genişlik
	var sd := 24.0             # derinlik
	var sh := 18.0             # yükseklik
	var stilt := deg_to_rad(32.0)

	for sz in [-1, 1]:
		var z0 := sz * (PITCH_H * 0.5 + 6.0)

		# Beton temel
		var base := BoxMesh.new(); base.size = Vector3(sw, 2.0, sd)
		add_child(_mi(base, concrete, Vector3(0, 0.0, z0 + sz * sd * 0.5)))

		# Eğimli koltuk yüzeyi (3 sıralı temsili basamak)
		for row in range(3):
			var t := float(row) / 2.0
			var row_z := z0 + sz * (3.0 + t * (sd - 6.0))
			var row_y := 1.5 + t * sh
			var row_mesh := BoxMesh.new()
			row_mesh.size = Vector3(sw - 0.5, 0.5, 7.0)
			add_child(_mi(row_mesh, seats, Vector3(0, row_y, row_z)))

		# Arka duvar
		var wall := BoxMesh.new(); wall.size = Vector3(sw, sh + 2.0, 2.0)
		add_child(_mi(wall, concrete, Vector3(0, sh * 0.5, z0 + sz * (sd + 1.0))))

		# Yan pilonlar (her 20 m'de bir)
		for px in [-2, -1, 0, 1, 2]:
			var pylon := BoxMesh.new(); pylon.size = Vector3(1.5, sh + 2.0, sd + 2.0)
			add_child(_mi(pylon, concrete,
				Vector3(px * (sw / 5.0), sh * 0.5, z0 + sz * (sd * 0.5 + 1.0))))

	# ── Kısa kenar tribünleri (Doğu +X, Batı -X) ──────────────────────────
	var ew := PITCH_H + 18.0  # 86 m genişlik
	var ed := 20.0
	var eh := 16.0

	for sx in [-1, 1]:
		var x0 := sx * (PITCH_W * 0.5 + 6.0)

		var base := BoxMesh.new(); base.size = Vector3(ed, 2.0, ew)
		add_child(_mi(base, concrete, Vector3(x0 + sx * ed * 0.5, 0.0, 0)))

		for row in range(3):
			var t := float(row) / 2.0
			var row_x := x0 + sx * (3.0 + t * (ed - 6.0))
			var row_y := 1.5 + t * eh
			var row_mesh := BoxMesh.new()
			row_mesh.size = Vector3(7.0, 0.5, ew - 0.5)
			add_child(_mi(row_mesh, seats, Vector3(row_x, row_y, 0)))

		var wall := BoxMesh.new(); wall.size = Vector3(2.0, eh + 2.0, ew)
		add_child(_mi(wall, concrete, Vector3(x0 + sx * (ed + 1.0), eh * 0.5, 0)))

# ── kale ağları ──────────────────────────────────────────────────────────────

func _build_goal_nets() -> void:
	var net_mat := StandardMaterial3D.new()
	net_mat.albedo_color = Color(1, 1, 1, 0.65)
	net_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	net_mat.cull_mode   = BaseMaterial3D.CULL_DISABLED

	const GW := 7.32   # kale genişliği
	const GH := 2.44   # kale yüksekliği
	const GD := 2.2    # ağ derinliği

	for sx in [-1, 1]:
		var gx := sx * PITCH_W * 0.5

		# Arka ağ
		var back := BoxMesh.new(); back.size = Vector3(0.06, GH, GW)
		add_child(_mi(back, net_mat, Vector3(gx + sx * GD, GH * 0.5, 0)))

		# Üst ağ
		var top := BoxMesh.new(); top.size = Vector3(GD, 0.06, GW)
		add_child(_mi(top, net_mat, Vector3(gx + sx * GD * 0.5, GH, 0)))

		# Yan ağlar
		var side := BoxMesh.new(); side.size = Vector3(GD, GH, 0.06)
		for sz in [-1, 1]:
			add_child(_mi(side, net_mat,
				Vector3(gx + sx * GD * 0.5, GH * 0.5, sz * GW * 0.5)))

# ── reklam panoları ──────────────────────────────────────────────────────────

func _build_ad_boards() -> void:
	var colors := [
		Color(0.85, 0.08, 0.08),  # kırmızı
		Color(0.08, 0.08, 0.85),  # mavi
		Color(0.85, 0.65, 0.00),  # sarı
		Color(0.08, 0.55, 0.10),  # yeşil
		Color(0.85, 0.40, 0.00),  # turuncu
	]

	const BH   := 1.0   # pano yüksekliği
	const BSPC := 8.0   # panel aralığı
	const BDEP := 0.18  # kalınlık

	var n := int(PITCH_W / BSPC)
	for i in range(n):
		var bx := -PITCH_W * 0.5 + (i + 0.5) * BSPC
		var c  := colors[i % colors.size()]
		var m  := _mat(c)

		var mesh := BoxMesh.new()
		mesh.size = Vector3(BSPC - 0.3, BH, BDEP)

		# Kuzey ve Güney uzun kenarlar
		for sz in [-1, 1]:
			add_child(_mi(mesh, m,
				Vector3(bx, BH * 0.5, sz * (PITCH_H * 0.5 + 0.5))))

	# Kale çizgisi arkası panoları (doğu-batı)
	var m2 := int(PITCH_H / BSPC)
	for i in range(m2):
		var bz  := -PITCH_H * 0.5 + (i + 0.5) * BSPC
		var c   := colors[i % colors.size()]
		var m   := _mat(c)
		var mesh := BoxMesh.new()
		mesh.size = Vector3(BDEP, BH, BSPC - 0.3)
		for sx in [-1, 1]:
			add_child(_mi(mesh, m,
				Vector3(sx * (PITCH_W * 0.5 + 0.5), BH * 0.5, bz)))

# ── skor tabelası ─────────────────────────────────────────────────────────────

func _build_scoreboard() -> void:
	var frame_mat  := _mat(Color(0.08, 0.08, 0.08))
	var screen_mat := _mat(Color(0.03, 0.03, 0.03), 0.05)

	const SBW := 22.0  # tabela genişliği
	const SBH := 9.0   # tabela yüksekliği

	# Kuzey tribünü üstünde (+Z tarafı, uzun kenar üstü)
	var sb_pos := Vector3(0, SBH * 0.5 + 20.0, PITCH_H * 0.5 + 34.0)

	var frame := BoxMesh.new(); frame.size = Vector3(SBW + 2.0, SBH + 2.0, 1.0)
	add_child(_mi(frame, frame_mat, sb_pos))

	var screen := BoxMesh.new(); screen.size = Vector3(SBW, SBH, 0.3)
	add_child(_mi(screen, screen_mat, sb_pos + Vector3(0, 0, -0.5)))

	var label := Label3D.new()
	label.text = "HOME  0 - 0  AWAY"
	label.font_size = 80
	label.modulate = Color(1.0, 1.0, 0.2)
	label.position = sb_pos + Vector3(0, 0.5, -0.7)
	label.rotation = Vector3(0, PI, 0)  # yüzü sahaya dönük
	add_child(label)

# ── projektör kuleleri ────────────────────────────────────────────────────────

func _build_floodlights() -> void:
	var pole_mat := _mat(Color(0.65, 0.65, 0.65), 0.3, 0.7)

	const POLE_H := 36.0

	var tower_pos := [
		Vector3(-62.0, 0.0, -40.0),
		Vector3( 62.0, 0.0, -40.0),
		Vector3( 62.0, 0.0,  40.0),
		Vector3(-62.0, 0.0,  40.0),
	]

	# Işıkların hedef noktaları (saha dörtte birleri)
	var aim_quads := [
		Vector3(-26.0, 1.0, -17.0),
		Vector3( 26.0, 1.0, -17.0),
		Vector3( 26.0, 1.0,  17.0),
		Vector3(-26.0, 1.0,  17.0),
	]

	for tp in tower_pos:
		# Direk
		var pole := CylinderMesh.new()
		pole.top_radius    = 0.35
		pole.bottom_radius = 0.75
		pole.height        = POLE_H
		add_child(_mi(pole, pole_mat, tp + Vector3(0, POLE_H * 0.5, 0)))

		# Platform
		var plat := BoxMesh.new(); plat.size = Vector3(3.0, 0.6, 3.0)
		add_child(_mi(plat, pole_mat, tp + Vector3(0, POLE_H, 0)))

		# Her kule köşeden 4 farklı saha bölgesini aydınlatır
		var light_origin := tp + Vector3(0, POLE_H, 0)
		for aim in aim_quads:
			var spot := SpotLight3D.new()
			spot.light_color   = Color(1.0, 0.96, 0.90)  # gün ışığı beyazı
			spot.light_energy  = 1.6
			spot.spot_angle    = 38.0
			spot.spot_range    = 130.0
			spot.shadow_enabled = false  # 16 spot gölgesi pahalı
			spot.position      = light_origin
			spot.look_at_from_position(light_origin, aim, Vector3.UP)
			add_child(spot)

# ── gece gökyüzü + ortam ─────────────────────────────────────────────────────

func _setup_night_sky() -> void:
	var env_node := get_node_or_null("../WorldEnvironment") as WorldEnvironment
	if not env_node or not env_node.environment:
		return
	var env := env_node.environment

	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color      = Color(0.03, 0.03, 0.10)
	sky_mat.sky_horizon_color  = Color(0.07, 0.09, 0.16)
	sky_mat.ground_bottom_color   = Color(0.01, 0.01, 0.02)
	sky_mat.ground_horizon_color  = Color(0.04, 0.05, 0.08)
	sky_mat.sun_angle_max      = 4.0

	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky                   = sky
	env.background_mode       = Environment.BG_SKY
	env.ambient_light_source  = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy  = 0.12   # karanlık gece atmosferi

func _disable_sun() -> void:
	# Güneş ışığı gece maçıyla çelişiyor — kapat
	var sun := get_node_or_null("../DirectionalLight3D") as DirectionalLight3D
	if sun:
		sun.light_energy = 0.0
