class_name Models
extends RefCounted
## بناء المجسمات ثلاثية الأبعاد من أشكال أساسية مع خامات PBR.

static var _mats := {}
static var _meshes := {}

const C_TRACK := Color(0.11, 0.11, 0.11)
const C_METAL := Color(0.17, 0.17, 0.18)
const C_CONC := Color(0.66, 0.62, 0.55)
const C_WALL := Color(0.55, 0.52, 0.47)
const C_DARK := Color(0.2, 0.18, 0.16)
const C_SAND := Color(0.76, 0.66, 0.47)
const C_GLASS := Color(0.22, 0.42, 0.55)
const C_LIGHT := Color(1.0, 0.85, 0.55)
const C_SKIN := Color(0.62, 0.43, 0.3)


static func mat(c: Color, rough := 0.75, metal := 0.0, emis := 0.0) -> StandardMaterial3D:
	var k := "%s|%.2f|%.2f|%.2f" % [c.to_html(), rough, metal, emis]
	if _mats.has(k):
		return _mats[k]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if emis > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emis
	_mats[k] = m
	return m


## تمويه صحراوي ببقع متداخلة مبني على لون الفريق (إسقاط ثلاثي لا يحتاج UV)
static func camo(tc: Color, rough := 0.6) -> StandardMaterial3D:
	var k := "camo|%s" % tc.to_html()
	if _mats.has(k):
		return _mats[k]
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	g.offsets = PackedFloat32Array([0.0, 0.38, 0.55, 0.72])
	g.colors = PackedColorArray([tc.darkened(0.12), tc, tc.lerp(C_SAND, 0.35), tc.darkened(0.45)])
	var m := _tex_mat(g, 0.035, 0.45)
	m.roughness = rough
	m.metallic = 0.25
	m.metallic_specular = 0.6
	_mats[k] = m
	return m


## خامة متسخة للخرسانة والجدران (بقع وتآكل)
static func grime(c: Color, rough := 0.92) -> StandardMaterial3D:
	var k := "grime|%s" % c.to_html()
	if _mats.has(k):
		return _mats[k]
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 0.8, 1.0])
	g.colors = PackedColorArray([c.darkened(0.3), c.darkened(0.08), c, c.lightened(0.08)])
	var m := _tex_mat(g, 0.06, 0.25)
	m.roughness = rough
	_mats[k] = m
	return m


static func _tex_mat(g: Gradient, freq: float, scl: float) -> StandardMaterial3D:
	var n := FastNoiseLite.new()
	n.frequency = freq
	n.fractal_octaves = 3
	var t := NoiseTexture2D.new()
	t.width = 128
	t.height = 128
	t.seamless = true
	t.noise = n
	t.color_ramp = g
	var m := StandardMaterial3D.new()
	m.albedo_texture = t
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE * scl
	return m


static func unshaded(c: Color, prio := 0, billboard := false, depth := true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if billboard:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.no_depth_test = not depth
	m.render_priority = prio
	return m


static func _mi(parent: Node3D, mesh: Mesh, pos: Vector3, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi


static func box(parent: Node3D, size: Vector3, pos: Vector3, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var k := "b%s" % size
	if not _meshes.has(k):
		var bm := BoxMesh.new()
		bm.size = size
		_meshes[k] = bm
	return _mi(parent, _meshes[k], pos, m, rot)


static func cyl(parent: Node3D, rad: float, height: float, pos: Vector3, m: Material, rot := Vector3.ZERO, top := -1.0, segs := 16) -> MeshInstance3D:
	var tr := rad if top < 0.0 else top
	var k := "c%.3f|%.3f|%.3f|%d" % [rad, height, tr, segs]
	if not _meshes.has(k):
		var cm := CylinderMesh.new()
		cm.bottom_radius = rad
		cm.top_radius = tr
		cm.height = height
		cm.radial_segments = segs
		cm.rings = 1
		_meshes[k] = cm
	return _mi(parent, _meshes[k], pos, m, rot)


static func sph(parent: Node3D, rad: float, pos: Vector3, m: Material, scl := Vector3.ONE, segs := 14) -> MeshInstance3D:
	var k := "s%.3f|%d" % [rad, segs]
	if not _meshes.has(k):
		var sm := SphereMesh.new()
		sm.radius = rad
		sm.height = rad * 2.0
		sm.radial_segments = segs
		sm.rings = maxi(4, segs / 2)
		_meshes[k] = sm
	var mi := _mi(parent, _meshes[k], pos, m)
	mi.scale = scl
	return mi


static func prism(parent: Node3D, size: Vector3, pos: Vector3, m: Material, rot := Vector3.ZERO, ltr := 0.5) -> MeshInstance3D:
	var k := "p%s|%.2f" % [size, ltr]
	if not _meshes.has(k):
		var pm := PrismMesh.new()
		pm.size = size
		pm.left_to_right = ltr
		_meshes[k] = pm
	return _mi(parent, _meshes[k], pos, m, rot)


static func capsule(parent: Node3D, rad: float, height: float, pos: Vector3, m: Material) -> MeshInstance3D:
	var k := "k%.3f|%.3f" % [rad, height]
	if not _meshes.has(k):
		var cm := CapsuleMesh.new()
		cm.radius = rad
		cm.height = height
		cm.radial_segments = 12
		cm.rings = 4
		_meshes[k] = cm
	return _mi(parent, _meshes[k], pos, m)


# ===================== الوحدات =====================

static func build_unit(e: Entity, tc: Color) -> void:
	var body := Node3D.new()
	e.add_child(body)
	e.body = body
	var veh: bool = e.type in ["tank", "art", "worker"]
	var mt := camo(tc) if veh else mat(tc, 0.55, 0.2)
	var md := mat(tc.darkened(0.4), 0.6, 0.2)
	var metal := mat(C_METAL, 0.45, 0.6)
	var black := mat(Color(0.06, 0.06, 0.06), 0.85)
	match e.type:
		"tank":
			_tracks(body, 3.6, 0.95, 5)
			box(body, Vector3(3.1, 0.55, 1.65), Vector3(-0.15, 0.88, 0), mt)
			box(body, Vector3(0.75, 0.42, 1.65), Vector3(1.6, 0.8, 0), mt, Vector3(0, 0, -30))
			box(body, Vector3(0.95, 0.1, 1.25), Vector3(-1.15, 1.2, 0), mat(Color(0.1, 0.1, 0.1), 0.9))
			box(body, Vector3(0.12, 0.18, 0.3), Vector3(1.85, 0.95, 0.55), mat(C_LIGHT, 0.3, 0.0, 1.5))
			box(body, Vector3(0.12, 0.18, 0.3), Vector3(1.85, 0.95, -0.55), mat(C_LIGHT, 0.3, 0.0, 1.5))
			var tur := Node3D.new()
			tur.position = Vector3(0.05, 1.16, 0)
			body.add_child(tur)
			e.turret = tur
			box(tur, Vector3(1.6, 0.52, 1.25), Vector3(-0.15, 0.26, 0), mt)
			box(tur, Vector3(0.55, 0.42, 1.05), Vector3(0.78, 0.22, 0), mt, Vector3(0, 0, -22))
			box(tur, Vector3(0.5, 0.35, 1.3), Vector3(-1.0, 0.25, 0), md)
			cyl(tur, 0.3, 0.14, Vector3(-0.45, 0.58, 0.28), md)
			cyl(tur, 0.02, 1.5, Vector3(-0.85, 1.25, -0.45), mat(Color(0.05, 0.05, 0.05)))
			var bar := Node3D.new()
			bar.position = Vector3(0.95, 0.3, 0)
			tur.add_child(bar)
			e.barrel = bar
			e.barrel_x0 = 0.95
			cyl(bar, 0.09, 2.0, Vector3(1.0, 0, 0), metal, Vector3(0, 0, 90))
			cyl(bar, 0.15, 0.32, Vector3(1.95, 0, 0), metal, Vector3(0, 0, 90))
			cyl(bar, 0.12, 0.35, Vector3(0.9, 0, 0), md, Vector3(0, 0, 90))  # مبخّر الدخان
			# تنانير جانبية فوق الجنازير
			for zs in [-1.0, 1.0]:
				box(body, Vector3(3.3, 0.42, 0.06), Vector3(0.05, 0.62, 1.27 * zs), mt)
				for i in 4:
					box(body, Vector3(0.05, 0.36, 0.07), Vector3(-1.2 + i * 0.85, 0.62, 1.29 * zs), md)
			# دروع تفاعلية أمام البرج
			for i in 3:
				for zs in [-1.0, 1.0]:
					box(tur, Vector3(0.28, 0.2, 0.3), Vector3(0.62, 0.42, (0.2 + i * 0.12) * zs), md, Vector3(0, 0, -22))
			# قاذفات الدخان والرشاش وصندوق التخزين الخلفي
			for zs in [-1.0, 1.0]:
				for i in 3:
					cyl(tur, 0.05, 0.22, Vector3(0.35, 0.58, (0.48 + i * 0.07) * zs), black, Vector3(0, 0, -60))
			box(tur, Vector3(0.45, 0.32, 1.4), Vector3(-1.35, 0.3, 0), mat(Color(0.32, 0.3, 0.2), 0.9))
			cyl(tur, 0.03, 0.75, Vector3(-0.1, 0.78, 0.28), black, Vector3(0, 0, 90))
			box(tur, Vector3(0.18, 0.14, 0.1), Vector3(-0.4, 0.74, 0.28), black)
			# شبكة العادم الخلفية
			for i in 4:
				box(body, Vector3(0.05, 0.06, 1.2), Vector3(-1.72, 0.85 + i * 0.09, 0), black)
			e.h = 2.1
		"art":
			_tracks(body, 3.8, 0.9, 5)
			box(body, Vector3(3.6, 0.5, 1.55), Vector3(0, 0.84, 0), mt)
			box(body, Vector3(1.0, 0.7, 1.4), Vector3(1.25, 1.35, 0), md)
			box(body, Vector3(0.08, 0.35, 1.0), Vector3(1.76, 1.45, 0), mat(C_GLASS, 0.1, 0.5))
			var tur := Node3D.new()
			tur.position = Vector3(-0.7, 1.1, 0)
			body.add_child(tur)
			e.turret = tur
			box(tur, Vector3(1.9, 0.85, 1.5), Vector3(0, 0.42, 0), mt)
			box(tur, Vector3(0.4, 0.5, 1.6), Vector3(-1.0, 0.4, 0), md)
			var bar := Node3D.new()
			bar.position = Vector3(0.9, 0.55, 0)
			bar.rotation_degrees = Vector3(0, 0, 14)
			tur.add_child(bar)
			e.barrel = bar
			e.barrel_x0 = 0.9
			cyl(bar, 0.13, 3.2, Vector3(1.6, 0, 0), metal, Vector3(0, 0, 90))
			cyl(bar, 0.2, 0.4, Vector3(3.2, 0, 0), metal, Vector3(0, 0, 90))
			cyl(bar, 0.22, 0.9, Vector3(0.3, 0, 0), md, Vector3(0, 0, 90))
			cyl(bar, 0.17, 0.5, Vector3(2.3, 0, 0), md, Vector3(0, 0, 90))
			# مساند خلفية وصناديق ذخيرة
			for zs in [-1.0, 1.0]:
				box(body, Vector3(0.9, 0.08, 0.25), Vector3(-2.15, 0.45, 0.6 * zs), metal, Vector3(0, 0, 35))
			var ammo := mat(Color(0.33, 0.36, 0.22), 0.85)
			box(body, Vector3(0.7, 0.35, 0.5), Vector3(1.25, 1.08, 0.95), ammo)
			box(body, Vector3(0.7, 0.35, 0.5), Vector3(1.25, 1.08, -0.95), ammo)
			box(tur, Vector3(0.35, 0.3, 0.35), Vector3(0.4, 1.0, 0.45), md)
			cyl(tur, 0.02, 1.2, Vector3(-0.8, 1.4, -0.6), black)
			e.h = 2.4
		"worker":
			var hub := mat(Color(0.6, 0.6, 0.58), 0.4, 0.7)
			for wp in [Vector3(-1.0, 0.34, -0.72), Vector3(-0.2, 0.34, -0.72), Vector3(1.0, 0.34, -0.72), Vector3(-1.0, 0.34, 0.72), Vector3(-0.2, 0.34, 0.72), Vector3(1.0, 0.34, 0.72)]:
				cyl(body, 0.34, 0.28, wp, black, Vector3(90, 0, 0))
				cyl(body, 0.16, 0.3, wp, hub, Vector3(90, 0, 0), -1.0, 8)
			box(body, Vector3(3.0, 0.28, 1.25), Vector3(0, 0.6, 0), mat(C_METAL, 0.7, 0.3))
			box(body, Vector3(0.95, 1.05, 1.35), Vector3(1.0, 1.25, 0), mat(Color(0.9, 0.88, 0.82), 0.45))
			box(body, Vector3(0.06, 0.5, 1.15), Vector3(1.49, 1.42, 0), mat(C_GLASS, 0.08, 0.6))
			box(body, Vector3(0.6, 0.06, 1.37), Vector3(1.0, 1.79, 0), mt)
			box(body, Vector3(0.08, 0.14, 0.28), Vector3(1.49, 0.85, 0.48), mat(C_LIGHT, 0.3, 0.0, 1.5))
			box(body, Vector3(0.08, 0.14, 0.28), Vector3(1.49, 0.85, -0.48), mat(C_LIGHT, 0.3, 0.0, 1.5))
			box(body, Vector3(1.95, 0.12, 1.35), Vector3(-0.5, 0.8, 0), mt)
			box(body, Vector3(1.95, 0.5, 0.08), Vector3(-0.5, 1.1, 0.64), mt)
			box(body, Vector3(1.95, 0.5, 0.08), Vector3(-0.5, 1.1, -0.64), mt)
			box(body, Vector3(0.08, 0.5, 1.35), Vector3(-1.45, 1.1, 0), mt)
			var cg := Node3D.new()
			body.add_child(cg)
			e.cargo = cg
			cyl(cg, 0.48, 1.6, Vector3(-0.5, 1.35, 0), mat(Color(0.05, 0.05, 0.05), 0.2, 0.7), Vector3(0, 0, 90))
			box(cg, Vector3(1.5, 0.06, 0.12), Vector3(-0.5, 1.84, 0), mat(Color(0.85, 0.65, 0.2), 0.4, 0.5))
			# عادم عمودي ومنارة تحذير برتقالية وصدّام أمامي
			cyl(body, 0.06, 1.1, Vector3(0.45, 1.6, 0.6), metal)
			cyl(body, 0.1, 0.12, Vector3(1.0, 1.88, 0), mat(Color(1.0, 0.5, 0.1), 0.3, 0.0, 2.5))
			box(body, Vector3(0.12, 0.2, 1.4), Vector3(1.55, 0.55, 0), metal)
			for zs in [-1.0, 1.0]:
				box(body, Vector3(0.1, 0.14, 0.06), Vector3(1.3, 1.45, 0.72 * zs), black)
			e.h = 2.0
		"inf", "rocket":
			var legm := mat(tc.darkened(0.55), 0.85)
			var l1 := box(body, Vector3(0.18, 0.62, 0.17), Vector3(0, 0.31, -0.13), legm)
			var l2 := box(body, Vector3(0.18, 0.62, 0.17), Vector3(0, 0.31, 0.13), legm)
			e.legs = [l1, l2]
			capsule(body, 0.25, 0.85, Vector3(0, 0.98, 0), mt)
			box(body, Vector3(0.24, 0.48, 0.42), Vector3(-0.27, 1.02, 0), mat(Color(0.3, 0.27, 0.2), 0.9))
			box(body, Vector3(0.5, 0.13, 0.13), Vector3(0.22, 1.08, 0.24), mt)
			box(body, Vector3(0.5, 0.13, 0.13), Vector3(0.22, 1.08, -0.22), mt)
			sph(body, 0.16, Vector3(0.03, 1.5, 0), mat(C_SKIN, 0.8))
			sph(body, 0.21, Vector3(0, 1.58, 0), md, Vector3(1, 0.62, 1))
			# سترة واقية وحزام ونظارة
			box(body, Vector3(0.36, 0.42, 0.46), Vector3(0.05, 1.05, 0), md)
			box(body, Vector3(0.38, 0.08, 0.5), Vector3(0.05, 0.78, 0), mat(Color(0.25, 0.2, 0.12), 0.9))
			box(body, Vector3(0.06, 0.06, 0.24), Vector3(0.17, 1.52, 0), black)
			if e.type == "rocket":
				cyl(body, 0.11, 1.3, Vector3(0.05, 1.42, 0.25), mat(Color(0.38, 0.4, 0.28), 0.8), Vector3(0, 0, 90))
				cyl(body, 0.11, 0.3, Vector3(0.85, 1.42, 0.25), mat(Color(0.85, 0.4, 0.12), 0.6), Vector3(0, 0, -90), 0.0)
			else:
				box(body, Vector3(0.85, 0.07, 0.07), Vector3(0.45, 1.06, 0.02), mat(Color(0.06, 0.06, 0.06), 0.5, 0.4))
				box(body, Vector3(0.12, 0.18, 0.06), Vector3(0.3, 0.97, 0.02), mat(Color(0.06, 0.06, 0.06), 0.5, 0.4))
			body.scale = Vector3.ONE * 1.3
			e.h = 2.3
	overlays(e)


static func black_mat() -> StandardMaterial3D:
	return mat(Color(0.06, 0.06, 0.06), 0.85)


static func _tracks(body: Node3D, length: float, z: float, wheels: int) -> void:
	var tm := mat(C_TRACK, 0.95)
	var wm := mat(Color(0.25, 0.25, 0.24), 0.6, 0.4)
	for s in [-1.0, 1.0]:
		box(body, Vector3(length, 0.62, 0.6), Vector3(0, 0.33, z * s), tm)
		for i in wheels:
			var x := -length * 0.38 + i * (length * 0.76 / float(wheels - 1))
			cyl(body, 0.24, 0.64, Vector3(x, 0.3, z * s), wm, Vector3(90, 0, 0), -1.0, 12)
		box(body, Vector3(length - 0.2, 0.08, 0.7), Vector3(0, 0.67, z * s), mat(C_METAL, 0.7, 0.3))


# ===================== المباني =====================

static func build_bld(e: Entity, tc: Color) -> void:
	var b := Node3D.new()
	e.add_child(b)
	e.body = b
	var mt := mat(tc, 0.6, 0.15)
	var md := mat(tc.darkened(0.35), 0.65, 0.15)
	var conc := grime(C_CONC)
	var wall := grime(C_WALL, 0.9)
	var crate := mat(Color(0.45, 0.33, 0.18), 0.9)
	var unit_box := mat(Color(0.78, 0.78, 0.75), 0.6, 0.3)
	var sand := mat(C_SAND, 0.95)
	var dark := mat(C_DARK, 0.9)
	var glow := mat(C_LIGHT, 0.4, 0.0, 1.2)
	var metal := mat(Color(0.55, 0.57, 0.6), 0.35, 0.7)
	match e.type:
		"hq":
			box(b, Vector3(10.2, 0.3, 10.2), Vector3(0, 0.15, 0), mat(Color(0.5, 0.47, 0.42), 0.95))
			box(b, Vector3(8.2, 3.3, 8.2), Vector3(0, 1.95, 0), conc)
			box(b, Vector3(8.35, 0.45, 8.35), Vector3(0, 3.4, 0), mt)
			for i in 5:
				var x := -3.2 + i * 1.6
				box(b, Vector3(0.8, 0.5, 0.06), Vector3(x, 2.3, 4.12), glow)
				box(b, Vector3(0.06, 0.5, 0.8), Vector3(4.12, 2.3, x), glow)
			box(b, Vector3(1.8, 1.9, 0.1), Vector3(0, 1.25, 4.13), dark)
			box(b, Vector3(3.8, 2.4, 3.8), Vector3(-1.2, 4.8, -1.2), wall)
			box(b, Vector3(3.86, 0.55, 3.86), Vector3(-1.2, 5.25, -1.2), mat(C_GLASS, 0.1, 0.6))
			box(b, Vector3(4.1, 0.3, 4.1), Vector3(-1.2, 6.15, -1.2), mt)
			cyl(b, 1.5, 0.06, Vector3(2.0, 3.66, 2.0), mat(Color(0.25, 0.25, 0.25), 0.9))
			var wh := unshaded(Color(0.95, 0.95, 0.9))
			box(b, Vector3(0.18, 0.02, 1.4), Vector3(1.55, 3.7, 2.0), wh)
			box(b, Vector3(0.18, 0.02, 1.4), Vector3(2.45, 3.7, 2.0), wh)
			box(b, Vector3(0.9, 0.02, 0.18), Vector3(2.0, 3.7, 2.0), wh)
			var dish := Node3D.new()
			dish.position = Vector3(-1.2, 6.3, -1.2)
			b.add_child(dish)
			e.spin = dish
			cyl(dish, 0.08, 1.4, Vector3(0, 0.7, 0), metal)
			cyl(dish, 0.15, 0.35, Vector3(0.25, 1.5, 0), mat(Color(0.9, 0.9, 0.88), 0.4, 0.3), Vector3(0, 0, -60), 1.05)
			cyl(b, 0.06, 3.4, Vector3(-3.6, 5.2, 3.6), metal)
			box(b, Vector3(1.4, 0.85, 0.05), Vector3(-2.85, 6.4, 3.6), mt)
			# مكيفات وألواح شمسية ودرابزين على السطح
			for i in 3:
				box(b, Vector3(0.9, 0.55, 0.7), Vector3(2.6, 3.9, -3.0 + i * 1.1), unit_box)
				cyl(b, 0.25, 0.04, Vector3(2.6, 4.19, -3.0 + i * 1.1), black_mat())
			var solar := mat(Color(0.08, 0.12, 0.25), 0.15, 0.6)
			for i in 2:
				box(b, Vector3(1.6, 0.06, 1.0), Vector3(1.5, 3.85, -0.6 + i * 1.2), solar, Vector3(0, 0, 18))
			for x in [-4.0, 4.0]:
				box(b, Vector3(0.08, 0.35, 8.2), Vector3(x, 3.85, 0), metal)
				box(b, Vector3(8.2, 0.35, 0.08), Vector3(0, 3.85, x), metal)
			# أكياس رمل عند المدخل
			for i in 6:
				box(b, Vector3(0.7, 0.32, 0.4), Vector3(-2.2 + i * 0.88, 0.46, 4.9), sand)
			e.h = 6.8
		"barracks":
			box(b, Vector3(7.2, 0.25, 5.6), Vector3(0, 0.12, 0), mat(Color(0.5, 0.47, 0.42), 0.95))
			box(b, Vector3(6.4, 1.9, 4.6), Vector3(0, 1.2, 0), mat(Color(0.56, 0.5, 0.39), 0.9))
			prism(b, Vector3(5.1, 1.5, 6.7), Vector3(0, 2.9, 0), mt, Vector3(0, 90, 0))
			box(b, Vector3(1.3, 1.5, 0.1), Vector3(0, 0.95, 2.33), dark)
			for x in [-2.4, -1.4, 1.4, 2.4]:
				box(b, Vector3(0.55, 0.45, 0.06), Vector3(x, 1.4, 2.33), glow)
			for i in 8:
				box(b, Vector3(0.7, 0.32, 0.4), Vector3(-3.1 + i * 0.88, 0.16, 3.3), sand)
				if i < 7:
					box(b, Vector3(0.7, 0.32, 0.4), Vector3(-2.66 + i * 0.88, 0.48, 3.3), sand)
			cyl(b, 0.05, 3.0, Vector3(3.3, 1.5, 2.6), metal)
			box(b, Vector3(1.0, 0.6, 0.04), Vector3(2.8, 2.7, 2.6), mt)
			# خزان ماء وصناديق إمداد
			for lx in [-2.6, -2.0]:
				cyl(b, 0.06, 2.4, Vector3(lx, 1.2, -2.0), metal)
			cyl(b, 0.6, 0.9, Vector3(-2.3, 2.8, -2.0), mat(Color(0.25, 0.4, 0.6), 0.5, 0.3), Vector3.ZERO, -1.0, 12)
			box(b, Vector3(0.8, 0.6, 0.8), Vector3(3.3, 0.55, -1.5), crate)
			box(b, Vector3(0.6, 0.5, 0.6), Vector3(3.3, 1.1, -1.5), crate, Vector3(0, 25, 0))
			e.h = 3.8
		"factory":
			box(b, Vector3(9.2, 0.3, 8.6), Vector3(0, 0.15, 0), mat(Color(0.48, 0.46, 0.42), 0.95))
			box(b, Vector3(8.2, 3.5, 7.2), Vector3(0, 2.0, 0), mat(Color(0.45, 0.44, 0.42), 0.8, 0.25))
			var roof := mat(Color(0.58, 0.61, 0.64), 0.45, 0.5)
			for i in 3:
				prism(b, Vector3(2.7, 1.4, 7.3), Vector3(-2.73 + i * 2.73, 4.45, 0), roof, Vector3.ZERO, 0.0)
				box(b, Vector3(0.06, 1.1, 7.0), Vector3(-4.0 + i * 2.73, 4.35, 0), mat(C_GLASS, 0.1, 0.5, 0.3))
			box(b, Vector3(8.3, 0.4, 7.3), Vector3(0, 3.6, 0), mt)
			box(b, Vector3(3.4, 2.5, 0.1), Vector3(-0.8, 1.55, 3.62), dark)
			for i in 9:
				box(b, Vector3(0.38, 0.22, 0.12), Vector3(-2.4 + i * 0.4, 2.95, 3.64), mat(Color(0.95, 0.75, 0.1) if i % 2 == 0 else Color(0.08, 0.08, 0.08), 0.6))
			box(b, Vector3(1.0, 0.5, 0.06), Vector3(2.6, 2.2, 3.63), glow)
			cyl(b, 0.5, 5.0, Vector3(3.0, 4.6, -2.6), metal)
			cyl(b, 0.42, 4.0, Vector3(1.8, 4.1, -2.6), metal)
			# أنابيب ومراوح تهوية وصناديق شحن
			box(b, Vector3(0.2, 0.2, 5.5), Vector3(-4.2, 2.6, -0.5), metal)
			box(b, Vector3(0.2, 2.4, 0.2), Vector3(-4.2, 1.4, 2.2), metal)
			for i in 3:
				cyl(b, 0.4, 0.35, Vector3(-2.73 + i * 2.73, 5.3, -2.5), unit_box, Vector3.ZERO, -1.0, 10)
			for i in 3:
				box(b, Vector3(1.0, 0.9, 1.0), Vector3(3.6, 0.75 + (0.9 if i == 2 else 0.0), 4.2 - (i % 2) * 1.1), crate)
			var sm := Fx.chimney_smoke(b, Vector3(3.0, 7.2, -2.6))
			e.smoke = sm
			e.h = 7.2
		"depot":
			box(b, Vector3(5.6, 0.45, 5.6), Vector3(0, 0.22, 0), conc)
			var steel := mat(Color(0.78, 0.8, 0.82), 0.3, 0.65)
			for x in [-1.25, 1.25]:
				cyl(b, 1.1, 2.6, Vector3(x, 1.75, 0), steel, Vector3.ZERO, -1.0, 20)
				sph(b, 1.1, Vector3(x, 3.05, 0), steel, Vector3(1, 0.35, 1), 20)
				cyl(b, 1.13, 0.35, Vector3(x, 2.2, 0), mt, Vector3.ZERO, -1.0, 20)
			box(b, Vector3(2.6, 0.18, 0.18), Vector3(0, 1.0, 1.0), mat(Color(0.3, 0.3, 0.3), 0.5, 0.6))
			box(b, Vector3(0.6, 0.6, 0.6), Vector3(2.4, 0.75, 2.4), mat(Color(0.75, 0.55, 0.15), 0.6))
			# سلّم وممر علوي وأنبوب تفريغ
			for x in [-1.25, 1.25]:
				box(b, Vector3(0.05, 2.6, 0.05), Vector3(x + 0.2, 1.75, 1.15), metal)
				box(b, Vector3(0.05, 2.6, 0.05), Vector3(x - 0.2, 1.75, 1.15), metal)
				for i in 6:
					box(b, Vector3(0.4, 0.04, 0.04), Vector3(x, 0.7 + i * 0.42, 1.15), metal)
			box(b, Vector3(1.5, 0.08, 0.6), Vector3(0, 3.0, 0), metal)
			cyl(b, 0.14, 2.4, Vector3(0, 0.6, -1.6), mat(Color(0.3, 0.3, 0.3), 0.5, 0.6), Vector3(0, 0, 90))
			e.h = 3.6
		"tower":
			cyl(b, 1.9, 3.0, Vector3(0, 1.5, 0), mat(Color(0.55, 0.52, 0.47), 0.95), Vector3.ZERO, 1.55, 10)
			cyl(b, 1.85, 0.3, Vector3(0, 3.15, 0), conc, Vector3.ZERO, -1.0, 10)
			for i in 10:
				var a := i / 10.0 * TAU
				box(b, Vector3(0.7, 0.32, 0.4), Vector3(cos(a) * 1.55, 3.45, sin(a) * 1.55), sand, Vector3(0, -rad_to_deg(a) + 90, 0))
			var tur := Node3D.new()
			tur.position = Vector3(0, 3.6, 0)
			b.add_child(tur)
			e.turret = tur
			box(tur, Vector3(1.5, 0.75, 1.3), Vector3(0, 0.38, 0), mt)
			box(tur, Vector3(0.5, 0.55, 1.1), Vector3(0.85, 0.35, 0), mt, Vector3(0, 0, -25))
			for z in [-0.25, 0.25]:
				cyl(tur, 0.08, 2.0, Vector3(1.6, 0.45, z), mat(C_METAL, 0.45, 0.6), Vector3(0, 0, 90))
			# رادار صغير وهوائي وضوء تحذير
			cyl(tur, 0.03, 1.0, Vector3(-0.5, 1.2, 0.45), metal)
			box(tur, Vector3(0.1, 0.35, 0.7), Vector3(-0.4, 0.95, -0.2), md)
			box(tur, Vector3(0.12, 0.12, 0.12), Vector3(-0.5, 1.75, 0.45), mat(Color(1, 0.2, 0.1), 0.3, 0.0, 3.0))
			for i in 4:
				box(b, Vector3(0.06, 2.6, 0.12), Vector3(cos(i * PI / 2.0) * 1.72, 1.5, sin(i * PI / 2.0) * 1.72), dark, Vector3(0, -i * 90, 0))
			e.h = 4.8
	overlays(e)


# ===================== عناصر مساعدة =====================

static func overlays(e: Entity) -> void:
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	var rr := e.r * (1.25 if e.kind == "b" else 1.2)
	tm.inner_radius = rr
	tm.outer_radius = rr + (0.3 if e.kind == "b" else 0.18)
	tm.rings = 48
	tm.ring_segments = 4
	ring.mesh = tm
	ring.material_override = unshaded(Color(0.45, 1.0, 0.5, 0.9))
	ring.position.y = 0.12
	ring.scale.y = 0.15
	ring.visible = false
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	e.add_child(ring)
	e.ring = ring
	var hb := Node3D.new()
	hb.position.y = e.h + 0.9
	e.add_child(hb)
	e.hpbar = hb
	var w := maxf(e.r * 1.9, 1.8)
	e.hp_w = w
	var bg := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(w + 0.14, 0.34)
	bg.mesh = q
	bg.material_override = unshaded(Color(0, 0, 0, 0.75), 1, true, false)
	bg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hb.add_child(bg)
	var fg := MeshInstance3D.new()
	var q2 := QuadMesh.new()
	q2.size = Vector2(w, 0.2)
	fg.mesh = q2
	fg.material_override = unshaded(Color(0.3, 1, 0.4), 2, true, false)
	fg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hb.add_child(fg)
	e.hp_fg = fg
	hb.visible = false


static func set_bar(e: Entity, k: float) -> void:
	k = clampf(k, 0.0, 1.0)
	var q: QuadMesh = e.hp_fg.mesh
	q.size = Vector2(maxf(0.01, e.hp_w * k), 0.2)
	q.center_offset = Vector3(-(e.hp_w - e.hp_w * k) * 0.5, 0, 0)
	var c := Color(0.3, 1, 0.4) if k > 0.6 else (Color(1, 0.82, 0.25) if k > 0.3 else Color(1, 0.3, 0.22))
	(e.hp_fg.material_override as StandardMaterial3D).albedo_color = c


static func set_vet(e: Entity, v: int) -> void:
	if e.vet_node:
		e.vet_node.queue_free()
	var n := Node3D.new()
	n.position.y = e.h + 1.45
	e.add_child(n)
	e.vet_node = n
	var gm := unshaded(Color(1, 0.84, 0.3), 3, true, false)
	for i in v:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.38, 0.38)
		q.center_offset = Vector3((i - (v - 1) * 0.5) * 0.5, 0, 0)
		mi.mesh = q
		mi.material_override = gm
		mi.rotation_degrees.z = 45
		n.add_child(mi)


static func add_chute(e: Entity) -> void:
	var c := Node3D.new()
	c.position.y = 3.6
	e.add_child(c)
	e.chute = c
	var cm := mat(Color(0.92, 0.92, 0.88), 0.9)
	var cm2 := mat(Color(0.3, 0.5, 0.3), 0.9)
	sph(c, 1.6, Vector3.ZERO, cm, Vector3(1, 0.55, 1), 12)
	sph(c, 1.62, Vector3(0, -0.02, 0), cm2, Vector3(0.5, 0.56, 0.5), 12)
	for a in [0.0, PI * 0.5, PI, PI * 1.5]:
		var l := cyl(c, 0.015, 2.4, Vector3(cos(a) * 0.8, -1.2, sin(a) * 0.8), mat(Color(0.2, 0.2, 0.2)))
		l.rotation = Vector3(sin(a) * 0.35, 0, -cos(a) * 0.35)


static func mine(parent: Node3D, p: Vector2) -> Dictionary:
	var n := Node3D.new()
	n.position = Vector3(p.x, 0, p.y)
	parent.add_child(n)
	var oil := mat(Color(0.12, 0.09, 0.06), 0.15, 0.2)
	cyl(n, 2.5, 0.03, Vector3(0, 0.02, 0), oil, Vector3.ZERO, -1.0, 24)
	box(n, Vector3(4.0, 0.35, 1.8), Vector3(0, 0.18, 0), mat(C_CONC, 0.95))
	var steel := mat(Color(0.3, 0.3, 0.32), 0.5, 0.6)
	box(n, Vector3(0.18, 2.6, 0.18), Vector3(0, 1.5, 0.5), steel, Vector3(18, 0, 0))
	box(n, Vector3(0.18, 2.6, 0.18), Vector3(0, 1.5, -0.5), steel, Vector3(-18, 0, 0))
	var beam := Node3D.new()
	beam.position = Vector3(0, 2.75, 0)
	n.add_child(beam)
	var ochre := mat(Color(0.8, 0.55, 0.15), 0.55, 0.3)
	box(beam, Vector3(3.6, 0.28, 0.24), Vector3(0.2, 0, 0), ochre)
	box(beam, Vector3(0.45, 1.0, 0.36), Vector3(2.0, -0.35, 0), ochre)
	box(beam, Vector3(0.6, 0.6, 0.5), Vector3(-1.5, -0.2, 0), mat(Color(0.2, 0.2, 0.2), 0.7, 0.4))
	box(n, Vector3(0.6, 0.5, 0.5), Vector3(-1.5, 0.6, 0), mat(Color(0.25, 0.25, 0.25), 0.7, 0.4))
	cyl(n, 0.08, 1.6, Vector3(2.2, 0.9, 0), steel)
	return {"node": n, "beam": beam}


static func jet(parent: Node3D, tc: Color) -> Node3D:
	var j := Node3D.new()
	parent.add_child(j)
	var grey := mat(Color(0.5, 0.53, 0.56), 0.4, 0.5)
	cyl(j, 0.42, 6.0, Vector3.ZERO, grey, Vector3(0, 0, 90), 0.25)
	cyl(j, 0.25, 1.4, Vector3(3.7, 0, 0), grey, Vector3(0, 0, -90), 0.0)
	prism(j, Vector3(3.2, 0.12, 7.0), Vector3(-0.3, 0, 0), grey, Vector3(0, 0, 0), 0.0)
	prism(j, Vector3(1.4, 0.1, 2.8), Vector3(-2.7, 0, 0), grey, Vector3(0, 0, 0), 0.0)
	box(j, Vector3(1.2, 1.2, 0.08), Vector3(-2.7, 0.6, 0), mat(tc, 0.5, 0.3), Vector3(0, 0, -25))
	sph(j, 0.35, Vector3(1.8, 0.3, 0), mat(C_GLASS, 0.05, 0.7), Vector3(2.2, 0.8, 1))
	cyl(j, 0.3, 0.3, Vector3(-3.1, 0, 0), mat(Color(1, 0.55, 0.15), 0.3, 0.0, 3.0), Vector3(0, 0, 90))
	return j


static func strike_marker(parent: Node3D, p: Vector2) -> Node3D:
	var n := Node3D.new()
	n.position = Vector3(p.x, 0.15, p.y)
	parent.add_child(n)
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 12.6
	tm.outer_radius = 13.0
	tm.rings = 64
	tm.ring_segments = 4
	mi.mesh = tm
	mi.scale.y = 0.1
	mi.material_override = unshaded(Color(1, 0.25, 0.15, 0.85))
	n.add_child(mi)
	var dot := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 12.6
	dm.bottom_radius = 12.6
	dm.height = 0.02
	dot.mesh = dm
	dot.material_override = unshaded(Color(1, 0.2, 0.1, 0.12))
	n.add_child(dot)
	return n


## مجسم لأيقونات الواجهة، يرجع (نصف القطر، الارتفاع)
static func icon_model(key: String, holder: Node3D) -> Vector2:
	var parts := key.split(":")
	var kind := parts[0]
	var t := parts[1]
	var tc := Color(0.18, 0.62, 0.36)
	if kind == "u" or kind == "b":
		var e := Entity.new()
		e.kind = kind
		e.type = t
		e.r = Data.UT[t]["size"] if kind == "u" else Data.BT[t]["size"]
		holder.add_child(e)
		if kind == "u":
			build_unit(e, tc)
		else:
			build_bld(e, tc)
			if e.smoke:
				e.smoke.emitting = false
		e.ring.visible = false
		e.hpbar.visible = false
		e.body.rotation.y = deg_to_rad(-25)
		return Vector2(e.r * (1.5 if kind == "u" else 1.25), e.h)
	match t:
		"jet":
			var j := jet(holder, tc)
			j.rotation_degrees = Vector3(0, -35, 0)
			return Vector2(4.0, 1.0)
		"chute":
			var e2 := Entity.new()
			e2.type = "inf"
			e2.r = 0.8
			holder.add_child(e2)
			build_unit(e2, tc)
			e2.ring.visible = false
			e2.hpbar.visible = false
			add_chute(e2)
			e2.chute.position.y = 4.2
			return Vector2(2.0, 5.0)
		"arm":
			var steel := mat(Color(0.45, 0.6, 0.78), 0.3, 0.7)
			cyl(holder, 1.2, 0.3, Vector3(0, 1.3, 0), steel, Vector3(90, 0, 0), -1.0, 6)
			cyl(holder, 0.6, 0.35, Vector3(0, 1.3, 0.05), mat(Color(0.9, 0.75, 0.3), 0.35, 0.7), Vector3(90, 0, 0), -1.0, 6)
			return Vector2(1.4, 2.6)
		"wep":
			var brass := mat(Color(0.85, 0.65, 0.25), 0.3, 0.8)
			for x in [-0.6, 0.0, 0.6]:
				cyl(holder, 0.25, 1.6, Vector3(x, 0.8, 0), brass)
				cyl(holder, 0.25, 0.6, Vector3(x, 1.9, 0), mat(Color(0.45, 0.45, 0.45), 0.4, 0.7), Vector3.ZERO, 0.02)
			return Vector2(1.2, 2.2)
		"har":
			mine(holder, Vector2.ZERO)
			return Vector2(2.6, 3.0)
	return Vector2(1, 1)
