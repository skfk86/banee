class_name Fx
extends RefCounted
## المؤثرات: انفجارات، دخان، مقذوفات، آثار حريق.

static var _scorch_tex: Texture2D
static var _puff: SphereMesh


static func _puff_mesh() -> SphereMesh:
	if _puff == null:
		_puff = SphereMesh.new()
		_puff.radius = 0.5
		_puff.height = 1.0
		_puff.radial_segments = 8
		_puff.rings = 4
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.vertex_color_use_as_albedo = true
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_puff.material = m
	return _puff


static func _ramp(cols: Array, offs: Array) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offs)
	g.colors = PackedColorArray(cols)
	return g


static func _shrink() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0, 0.4))
	c.add_point(Vector2(0.25, 1.0))
	c.add_point(Vector2(1, 0.7))
	return c


static func _particles(parent: Node3D, pos: Vector3, amount: int, life: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.mesh = _puff_mesh()
	p.amount = maxi(1, amount)
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 0.95
	p.local_coords = false
	p.position = pos
	parent.add_child(p)
	return p


static func _auto_free(n: Node, sec: float) -> void:
	var tw := n.create_tween()
	tw.tween_interval(sec)
	tw.tween_callback(n.queue_free)


static func explosion(parent: Node3D, pos: Vector3, s := 1.0) -> void:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = pos
	var fire := _particles(root, Vector3.ZERO, int(12 * s), 0.55)
	fire.direction = Vector3.UP
	fire.spread = 180.0
	fire.initial_velocity_min = 2.0 * s
	fire.initial_velocity_max = 6.0 * s
	fire.gravity = Vector3(0, 3, 0)
	fire.damping_min = 4.0
	fire.damping_max = 6.0
	fire.scale_amount_min = 0.9 * s
	fire.scale_amount_max = 2.0 * s
	fire.scale_amount_curve = _shrink()
	fire.color_ramp = _ramp([Color(1, 0.97, 0.75, 1), Color(1, 0.55, 0.12, 0.95), Color(0.35, 0.12, 0.05, 0.0)], [0.0, 0.3, 1.0])
	fire.emitting = true
	var smoke := _particles(root, Vector3(0, 0.3, 0), int(6 * s), 1.8)
	smoke.direction = Vector3.UP
	smoke.spread = 60.0
	smoke.initial_velocity_min = 1.0
	smoke.initial_velocity_max = 3.0 * s
	smoke.gravity = Vector3(0.6, 1.2, 0)
	smoke.damping_min = 1.0
	smoke.damping_max = 2.0
	smoke.scale_amount_min = 1.2 * s
	smoke.scale_amount_max = 2.6 * s
	smoke.scale_amount_curve = _shrink()
	smoke.color_ramp = _ramp([Color(0.25, 0.23, 0.2, 0.0), Color(0.22, 0.2, 0.18, 0.75), Color(0.45, 0.42, 0.38, 0.0)], [0.0, 0.15, 1.0])
	smoke.emitting = true
	var deb := CPUParticles3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.18, 0.18, 0.18)
	bm.material = Models.mat(Color(0.15, 0.13, 0.11), 0.9)
	deb.mesh = bm
	deb.amount = int(5 * s)
	deb.lifetime = 1.2
	deb.one_shot = true
	deb.explosiveness = 1.0
	deb.local_coords = false
	deb.direction = Vector3.UP
	deb.spread = 70.0
	deb.initial_velocity_min = 5.0 * s
	deb.initial_velocity_max = 11.0 * s
	deb.gravity = Vector3(0, -22, 0)
	deb.angular_velocity_min = -400
	deb.angular_velocity_max = 400
	deb.scale_amount_min = 0.5
	deb.scale_amount_max = 1.5 * s
	root.add_child(deb)
	deb.emitting = true
	var fl := MeshInstance3D.new()
	fl.mesh = _puff_mesh()
	fl.material_override = _flash_mat()
	fl.scale = Vector3.ONE * 1.5 * s
	fl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(fl)
	var tw := fl.create_tween()
	tw.tween_property(fl, "scale", Vector3.ONE * 4.0 * s, 0.18)
	tw.tween_callback(fl.hide)
	_auto_free(root, 2.5)


static func spark(parent: Node3D, pos: Vector3, dtype: String) -> void:
	var s := 0.35 if dtype == "bullet" else 0.7
	var p := _particles(parent, pos, 6 if dtype == "bullet" else 12, 0.25)
	p.spread = 180.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 5.0
	p.gravity = Vector3.ZERO
	p.scale_amount_min = 0.4 * s
	p.scale_amount_max = 1.0 * s
	p.color_ramp = _ramp([Color(1, 0.95, 0.6, 1), Color(1, 0.45, 0.1, 0)], [0.0, 1.0])
	p.emitting = true
	_auto_free(p, 0.6)


static func muzzle(parent: Node3D, pos: Vector3, dtype: String) -> void:
	var big := dtype != "bullet"
	var p := _particles(parent, pos, 5 if big else 2, 0.12)
	p.spread = 25.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.0
	p.gravity = Vector3.ZERO
	p.scale_amount_min = 0.5 if big else 0.25
	p.scale_amount_max = 1.0 if big else 0.4
	p.color_ramp = _ramp([Color(1, 0.95, 0.7, 1), Color(1, 0.6, 0.2, 0)], [0.0, 1.0])
	p.emitting = true
	_auto_free(p, 0.4)
	if big:
		var sm := _particles(parent, pos, 6, 1.0)
		sm.spread = 40.0
		sm.initial_velocity_min = 0.5
		sm.initial_velocity_max = 1.5
		sm.gravity = Vector3(0, 1, 0)
		sm.scale_amount_min = 0.6
		sm.scale_amount_max = 1.2
		sm.color_ramp = _ramp([Color(0.6, 0.58, 0.55, 0.6), Color(0.6, 0.58, 0.55, 0)], [0.0, 1.0])
		sm.emitting = true
		_auto_free(sm, 1.4)


static func projectile(parent: Node3D, dtype: String) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	match dtype:
		"bullet":
			Models.box(n, Vector3(0.9, 0.06, 0.06), Vector3.ZERO, Models.unshaded(Color(2.4, 2.0, 1.0)))
		"shell":
			Models.sph(n, 0.16, Vector3.ZERO, Models.unshaded(Color(2.6, 1.7, 0.7)), Vector3(2.2, 1, 1), 8)
		"rocket":
			Models.cyl(n, 0.08, 0.7, Vector3.ZERO, Models.mat(Color(0.4, 0.42, 0.3), 0.6), Vector3(0, 0, 90))
			Models.sph(n, 0.16, Vector3(-0.45, 0, 0), Models.unshaded(Color(3.0, 1.6, 0.5)), Vector3.ONE, 8)
			var tr := CPUParticles3D.new()
			tr.mesh = _puff_mesh()
			tr.amount = 10
			tr.lifetime = 0.7
			tr.local_coords = false
			tr.direction = Vector3.UP
			tr.spread = 30.0
			tr.initial_velocity_min = 0.2
			tr.initial_velocity_max = 0.6
			tr.gravity = Vector3.ZERO
			tr.scale_amount_min = 0.3
			tr.scale_amount_max = 0.6
			tr.scale_amount_curve = _shrink()
			tr.color_ramp = _ramp([Color(0.85, 0.82, 0.78, 0.7), Color(0.6, 0.58, 0.55, 0)], [0.0, 1.0])
			tr.position = Vector3(-0.5, 0, 0)
			n.add_child(tr)
		"art":
			Models.sph(n, 0.24, Vector3.ZERO, Models.mat(Color(0.15, 0.15, 0.15), 0.5, 0.5))
			Models.sph(n, 0.14, Vector3(-0.25, 0, 0), Models.unshaded(Color(2.8, 1.5, 0.6)), Vector3.ONE, 8)
	return n


static var _scorch_mat: StandardMaterial3D
static var _scorches: Array = []
static var _flash: StandardMaterial3D


static func _flash_mat() -> StandardMaterial3D:
	if _flash == null:
		_flash = StandardMaterial3D.new()
		_flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_flash.albedo_color = Color(2.6, 2.0, 1.1, 0.6)  # قيم HDR لتفعيل التوهج
		_flash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return _flash


static func scorch(parent: Node3D, pos: Vector3, s := 1.0) -> void:
	if _scorch_mat == null:
		var gt := GradientTexture2D.new()
		gt.width = 64
		gt.height = 64
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.gradient = _ramp([Color(0.08, 0.06, 0.04, 0.8), Color(0.1, 0.08, 0.05, 0.45), Color(0.1, 0.08, 0.05, 0.0)], [0.0, 0.45, 1.0])
		_scorch_mat = StandardMaterial3D.new()
		_scorch_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_scorch_mat.albedo_texture = gt
		_scorch_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_scorches = _scorches.filter(func(x): return is_instance_valid(x))
	if _scorches.size() > 30:
		_scorches.pop_front().queue_free()
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(3.2 * s, 3.2 * s)
	mi.mesh = pm
	mi.material_override = _scorch_mat
	mi.position = pos + Vector3(0, 0.03 + randf() * 0.02, 0)
	mi.rotation.y = randf() * TAU
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	_scorches.append(mi)
	_auto_free(mi, 25.0)


## حلقة تظهر وتختفي مكان الأمر (تحرك أو هجوم)
static func ring_marker(parent: Node3D, pos: Vector3, c: Color) -> void:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.2
	tm.outer_radius = 1.6
	tm.rings = 24
	tm.ring_segments = 4
	mi.mesh = tm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	mi.position = pos + Vector3(0, 0.15, 0)
	mi.scale = Vector3(1.6, 0.1, 1.6)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	var tw := mi.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3(0.4, 0.1, 0.4), 0.5)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.5)
	tw.chain().tween_callback(mi.queue_free)


static func chimney_smoke(parent: Node3D, pos: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.mesh = _puff_mesh()
	p.amount = 8
	p.lifetime = 2.5
	p.local_coords = false
	p.direction = Vector3.UP
	p.spread = 12.0
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 2.5
	p.gravity = Vector3(0.8, 0.3, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	p.scale_amount_curve = _shrink()
	p.color_ramp = _ramp([Color(0.45, 0.43, 0.4, 0.0), Color(0.42, 0.4, 0.38, 0.6), Color(0.6, 0.58, 0.55, 0.0)], [0.0, 0.15, 1.0])
	p.position = pos
	p.emitting = false
	parent.add_child(p)
	return p


static func damage_fire(e: Node3D, h: float) -> Node3D:
	var root := Node3D.new()
	root.position.y = h * 0.9
	e.add_child(root)
	var f := CPUParticles3D.new()
	f.mesh = _puff_mesh()
	f.amount = 8
	f.lifetime = 0.7
	f.local_coords = false
	f.direction = Vector3.UP
	f.spread = 15.0
	f.initial_velocity_min = 1.5
	f.initial_velocity_max = 3.0
	f.gravity = Vector3.ZERO
	f.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	f.emission_sphere_radius = 0.8
	f.scale_amount_min = 0.5
	f.scale_amount_max = 1.0
	f.scale_amount_curve = _shrink()
	f.color_ramp = _ramp([Color(1, 0.85, 0.4, 0.9), Color(1, 0.4, 0.1, 0.7), Color(0.2, 0.1, 0.05, 0)], [0.0, 0.4, 1.0])
	root.add_child(f)
	var s := CPUParticles3D.new()
	s.mesh = _puff_mesh()
	s.amount = 8
	s.lifetime = 2.5
	s.local_coords = false
	s.direction = Vector3.UP
	s.spread = 10.0
	s.initial_velocity_min = 2.0
	s.initial_velocity_max = 3.0
	s.gravity = Vector3(1.0, 0.2, 0)
	s.scale_amount_min = 1.0
	s.scale_amount_max = 2.2
	s.scale_amount_curve = _shrink()
	s.color_ramp = _ramp([Color(0.1, 0.09, 0.08, 0.0), Color(0.12, 0.11, 0.1, 0.75), Color(0.3, 0.28, 0.26, 0)], [0.0, 0.1, 1.0])
	root.add_child(s)
	return root
