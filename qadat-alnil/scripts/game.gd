extends Node3D
## المحاكاة الرئيسية: العالم، الكاميرا، اللمس، الاقتصاد، القتال، والذكاء الاصطناعي.

signal game_over(won: bool) ## اربط هنا إعلان AdMob البيني

const M := 240.0
const PL := 0
const EN := 1
const CAP := 80
const PITCH := 0.95
const TEAM_COLORS := [Color(0.16, 0.6, 0.34), Color(0.76, 0.2, 0.15)]

var ents: Array = []
var mines: Array = []
var projs: Array = []
var strikes: Array = []
var gold := [500, 500]
var up: Array = []
var pw: Array = []
var diff := 1
var D: Dictionary = {}
var t := 0.0
var speed := 1
var paused := false
var over := false
var running := false
var sel: Array = []
var placing := ""
var power := ""
var ghost: MeshInstance3D
var ai: Dictionary = {}
var stats := {"kills": 0, "lost": 0}

var world: Node3D
var ent_root: Node3D
var fx_root: Node3D
var cam: Camera3D
var cam_target := Vector3(120, 0, 120)
var cam_dist := 120.0
var cam_yaw := 0.0
var shake := 0.0
var hud: Hud
var ui_t := 0.0

var touches := {}
var ignored := {}
var drag_moved := false
var drag_start := Vector2.ZERO
var pinch_d := 0.0
var last_tap_id := -1
var last_tap_ms := 0
var last_pointer := Vector2(-1, -1)
var tut := -1
var tut_t := 0.0
var tut_unit = null
var arrow: Node3D


func _ready() -> void:
	randomize()
	_build_env()
	world = Node3D.new()
	add_child(world)
	_build_terrain()
	cam = Camera3D.new()
	cam.fov = 40.0
	cam.near = 0.5
	cam.far = 900.0
	add_child(cam)
	cam.current = true
	hud = Hud.new()
	hud.game = self
	add_child(hud)
	_new_world(1)
	running = false
	cam_target = Vector3(120, 0, 130)
	cam_dist = 130.0
	_update_cam()
	hud.show_menu()
	Sfx.music(true)


# ===================== العالم =====================

func _build_env() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.22, 0.42, 0.72)
	sm.sky_horizon_color = Color(0.95, 0.8, 0.6)
	sm.sky_curve = 0.12
	sm.ground_horizon_color = Color(0.9, 0.76, 0.56)
	sm.ground_bottom_color = Color(0.42, 0.33, 0.22)
	sm.sun_angle_max = 30.0
	sm.sun_curve = 0.08
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.75
	env.ambient_light_sky_contribution = 0.85
	# تدرج لوني سينمائي + توهج للانفجارات والأضواء (مدعوم في gl_compatibility)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_strength = 0.9
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.12
	env.fog_enabled = true
	env.fog_light_color = Color(0.9, 0.78, 0.62)
	env.fog_sun_scatter = 0.25
	env.fog_density = 0.0018
	env.fog_aerial_perspective = 0.3
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -40, 0)
	sun.light_energy = 1.55
	sun.light_color = Color(1.0, 0.91, 0.76)
	sun.shadow_enabled = true
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.2
	sun.shadow_blur = 1.5
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 110.0
	add_child(sun)
	# ضوء سماوي خافت من الجهة المقابلة لتنعيم الظلال
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, 140, 0)
	fill.light_energy = 0.28
	fill.light_color = Color(0.6, 0.72, 1.0)
	fill.shadow_enabled = false
	add_child(fill)


func _build_terrain() -> void:
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(M + 400, M + 400)
	pm.add_uv2 = true
	ground.mesh = pm
	ground.position = Vector3(M / 2, 0, M / 2)
	var mat := StandardMaterial3D.new()
	var nt := NoiseTexture2D.new()
	nt.width = 256
	nt.height = 256
	nt.seamless = true
	var n := FastNoiseLite.new()
	n.frequency = 0.02
	n.fractal_octaves = 3
	nt.noise = n
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 0.7, 1.0])
	g.colors = PackedColorArray([Color(0.5, 0.38, 0.23), Color(0.66, 0.52, 0.33), Color(0.74, 0.6, 0.4), Color(0.8, 0.68, 0.48)])
	nt.color_ramp = g
	mat.albedo_texture = nt
	mat.roughness = 0.97
	mat.uv1_scale = Vector3(4, 4, 1)
	# خريطة تضاريس (نتوءات الرمل) وطبقة تفاصيل دقيقة تُظهر حبيبات الرمل عن قرب
	var nn := FastNoiseLite.new()
	nn.frequency = 0.06
	nn.fractal_octaves = 4
	var nmap := NoiseTexture2D.new()
	nmap.width = 256
	nmap.height = 256
	nmap.seamless = true
	nmap.as_normal_map = true
	nmap.bump_strength = 6.0
	nmap.noise = nn
	mat.normal_enabled = true
	mat.normal_texture = nmap
	mat.normal_scale = 0.8
	var dn := FastNoiseLite.new()
	dn.frequency = 0.25
	dn.noise_type = FastNoiseLite.TYPE_CELLULAR
	var dtex := NoiseTexture2D.new()
	dtex.width = 128
	dtex.height = 128
	dtex.seamless = true
	dtex.noise = dn
	dtex.color_ramp = Fx._ramp([Color(0.55, 0.45, 0.32), Color(0.85, 0.74, 0.55), Color(1.0, 0.93, 0.78)], [0.0, 0.6, 1.0])
	mat.detail_enabled = true
	mat.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	mat.detail_albedo = dtex
	mat.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
	mat.uv2_scale = Vector3(60, 60, 1)
	ground.material_override = mat
	world.add_child(ground)
	# حواف الخريطة: تلال منخفضة
	var hill := Models.mat(Color(0.6, 0.47, 0.3), 1.0)
	for i in 28:
		var side := i % 4
		var k := randf()
		var pos := Vector3.ZERO
		match side:
			0: pos = Vector3(k * M, 0, -8)
			1: pos = Vector3(k * M, 0, M + 8)
			2: pos = Vector3(-8, 0, k * M)
			3: pos = Vector3(M + 8, 0, k * M)
		var s := randf_range(8, 16)
		Models.sph(world, 1.0, pos, hill, Vector3(s, s * 0.35, s), 10)
	# صخور ونباتات
	var rock := Models.mat(Color(0.5, 0.46, 0.4), 0.95)
	var rock2 := Models.mat(Color(0.42, 0.38, 0.33), 0.95)
	var bush := Models.mat(Color(0.36, 0.42, 0.2), 0.9)
	var palm_t := Models.mat(Color(0.42, 0.32, 0.2), 0.9)
	var palm_l := Models.mat(Color(0.25, 0.45, 0.18), 0.85)
	for i in 90:
		var p := Vector3(randf() * M, 0, randf() * M)
		if Vector2(p.x, p.z).distance_to(Vector2(30, 210)) < 30 or Vector2(p.x, p.z).distance_to(Vector2(210, 30)) < 30:
			continue
		var r := randf()
		if r < 0.5:
			var s := randf_range(0.4, 1.6)
			var mi := Models.sph(world, 1.0, p, rock if randf() < 0.5 else rock2, Vector3(s * 1.4, s * 0.7, s), 6)
			mi.rotation.y = randf() * TAU
		elif r < 0.85:
			var s2 := randf_range(0.4, 0.9)
			for j in 3:
				Models.sph(world, 1.0, p + Vector3(randf_range(-0.6, 0.6), s2 * 0.5, randf_range(-0.6, 0.6)), bush, Vector3.ONE * s2, 6)
		else:
			var trunk := Models.cyl(world, 0.22, 6.0, p + Vector3(0, 3, 0), palm_t, Vector3(randf_range(-8, 8), 0, randf_range(-8, 8)), 0.15, 8)
			for j in 6:
				var a := j / 6.0 * TAU
				var leaf := Models.box(world, Vector3(2.6, 0.06, 0.5), p + Vector3(cos(a) * 1.1, 6.0, sin(a) * 1.1), palm_l)
				leaf.rotation = Vector3(0, -a, -0.45)
			trunk.rotation_degrees.y = randf() * 360


func _new_world(d: int) -> void:
	if ent_root:
		ent_root.queue_free()
	if fx_root:
		fx_root.queue_free()
	if ghost:
		ghost.queue_free()
		ghost = null
	ents = []
	mines = []
	projs = []
	strikes = []
	sel = []
	placing = ""
	power = ""
	diff = d
	D = Data.DIFF[d]
	t = 0.0
	speed = 1
	over = false
	paused = false
	gold = [500, 500]
	up = [{"arm": 0, "wep": 0, "har": 0}, {"arm": 0, "wep": 0, "har": 0}]
	pw = [{"air": 60.0, "rein": 45.0}, {"air": 90.0, "rein": 120.0}]
	ai = {"t": 2.0, "timer": D["first"], "wave_size": D["wave"], "wave": 0}
	stats = {"kills": 0, "lost": 0}
	ent_root = Node3D.new()
	world.add_child(ent_root)
	fx_root = Node3D.new()
	world.add_child(fx_root)
	var mp := [[52, 216, 1500], [30, 187, 1500], [50, 196, 1500], [30, 120, 2500], [120, 210, 2500], [120, 120, 3500], [90, 150, 3000]]
	for a in mp:
		_mk_mine(Vector2(a[0], a[1]), a[2])
		if not (a[0] == 120 and a[1] == 120):
			_mk_mine(Vector2(M - a[0], M - a[1]), a[2])
	var bases := [Vector2(30, 210), Vector2(M - 30, M - 210)]
	for tm in 2:
		var b: Vector2 = bases[tm]
		mk_bld(tm, "hq", b, true)
		for i in 3:
			var off := Vector2(8, -8) if tm == PL else Vector2(-8, 8)
			mk_unit(tm, "worker", b + off + Vector2(i * 2.4, 0))


func start_game(d: int) -> void:
	_new_world(d)
	running = true
	cam_yaw = 0.0
	cam_target = Vector3(42, 0, 214)
	cam_dist = 62.0
	hud.on_game_start()
	Sfx.music(true, true)
	tut = 0
	tut_t = 0.0
	ai["timer"] += 90.0


func quit_to_menu() -> void:
	skip_tutorial()
	_new_world(1)
	running = false
	cam_target = Vector3(120, 0, 130)
	cam_dist = 130.0
	hud.show_menu()
	Sfx.music(true)


func _mk_mine(p: Vector2, amt: int) -> void:
	var dct := Models.mine(ent_root, p)
	dct["p"] = p
	dct["amt"] = amt
	dct["max"] = amt
	dct["r"] = 2.2
	mines.append(dct)


func mk_unit(tm: int, type: String, p: Vector2) -> Entity:
	var s: Dictionary = Data.UT[type]
	var e := Entity.new()
	e.kind = "u"
	e.team = tm
	e.type = type
	e.p = p
	e.hp = s["hp"]
	e.mhp = s["hp"]
	e.r = s["size"]
	e.ang = PI * 0.75 if tm == EN else -PI * 0.25
	e.tang = e.ang
	e.scan = randf() * 0.3
	if type == "worker":
		e.st = "harvest"
	ent_root.add_child(e)
	Models.build_unit(e, TEAM_COLORS[tm])
	ents.append(e)
	_sync(e, 0.0)
	return e


func mk_bld(tm: int, type: String, p: Vector2, built: bool) -> Entity:
	var s: Dictionary = Data.BT[type]
	var e := Entity.new()
	e.kind = "b"
	e.team = tm
	e.type = type
	e.p = p
	e.mhp = s["hp"]
	e.hp = s["hp"] if built else s["hp"] * 0.1
	e.r = s["size"]
	e.prog = 1.0 if built else 0.0
	e.announced = built
	e.tang = -PI / 2
	ent_root.add_child(e)
	Models.build_bld(e, TEAM_COLORS[tm])
	if tm == EN:
		e.body.rotation.y = PI
	ents.append(e)
	_sync(e, 0.0)
	return e


# ===================== أدوات =====================

func alive(e) -> bool:
	return e != null and is_instance_valid(e) and not e.dead


func _turn(a: float, b: float, m: float) -> float:
	return a + clampf(angle_difference(a, b), -m, m)


func has_built(tm: int, type: String) -> bool:
	for e in ents:
		if e.team == tm and e.kind == "b" and e.type == type and e.prog >= 1.0 and not e.dead:
			return true
	return false


func req_ok(tm: int, type: String) -> bool:
	var s: Dictionary = Data.BT[type]
	return not s.has("req") or has_built(tm, s["req"])


func unit_count(tm: int) -> int:
	var n := 0
	for e in ents:
		if e.team == tm and e.kind == "u":
			n += 1
	return n


func _find_bld(tm: int, type: String):
	for e in ents:
		if e.team == tm and e.kind == "b" and e.type == type and not e.dead:
			return e
	return null


func _item_time(it: String) -> float:
	return Data.RS[it.substr(2)]["time"] if it.begins_with("r:") else Data.UT[it]["time"]


func _item_cost(it: String) -> int:
	return Data.RS[it.substr(2)]["cost"] if it.begins_with("r:") else Data.UT[it]["cost"]


func _dmg_of(e) -> float:
	var s: Dictionary = Data.UT[e.type] if e.kind == "u" else Data.BT[e.type]
	var d: float = s["dmg"] * (1.0 + 0.2 * up[e.team]["wep"])
	if e.vet > 0:
		d *= 1.0 + 0.2 * e.vet
	return d


func _nearest_enemy(e, rng_: float):
	var best = null
	var bd := 1e9
	for o in ents:
		if o.team == e.team or o.dead or o.drop > 0.0:
			continue
		var d: float = e.p.distance_to(o.p) - o.r
		if d > rng_:
			continue
		var sc: float = d + (8.0 if o.kind == "b" else 0.0) + (3.0 if o.type == "worker" else 0.0)
		if sc < bd:
			bd = sc
			best = o
	return best


func _nearest_drop(e):
	var best = null
	var bd := 1e9
	for o in ents:
		if o.team == e.team and o.kind == "b" and (o.type == "hq" or o.type == "depot") and o.prog >= 1.0 and not o.dead:
			var d: float = e.p.distance_to(o.p)
			if d < bd:
				bd = d
				best = o
	return best


func _nearest_mine(e):
	var best = null
	var bd := 1e9
	for m in mines:
		if m["amt"] <= 0:
			continue
		var d: float = e.p.distance_to(m["p"])
		if d < bd:
			bd = d
			best = m
	return best


func _pick_mine(p: Vector2):
	for m in mines:
		if m["amt"] > 0 and p.distance_to(m["p"]) < m["r"] + 2.5:
			return m
	return null


# ===================== الحلقة =====================

func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	if running and not paused and not over:
		for i in speed:
			_update(dt)
	elif not running:
		cam_yaw += dt * 0.05
	_visuals(dt)
	shake = maxf(0.0, shake - delta * 2.5)
	_update_cam()
	ui_t -= delta
	if ui_t <= 0.0:
		ui_t = 0.25
		hud.refresh()
		_tutorial()
	if arrow and arrow.visible:
		arrow.position.y = 9.0 + sin(Time.get_ticks_msec() / 160.0) * 0.8
		arrow.rotation.y += delta * 2.0
	hud.minimap.queue_redraw()


func _update(dt: float) -> void:
	t += dt
	for p in pw:
		p["air"] = maxf(0.0, p["air"] - dt)
		p["rein"] = maxf(0.0, p["rein"] - dt)
	_ai(dt)
	for e in ents:
		if e.dead:
			continue
		if e.kind == "u":
			_upd_unit(e, dt)
		else:
			_upd_bld(e, dt)
	_upd_proj(dt)
	_upd_strikes(dt)
	_separate()
	_cleanup()
	_check_end()


func _cleanup() -> void:
	var keep := []
	for e in ents:
		if e.dead:
			e.queue_free()
		else:
			keep.append(e)
	if keep.size() != ents.size():
		ents = keep
		var ns := []
		for x in sel:
			if is_instance_valid(x) and not x.dead:
				ns.append(x)
		sel = ns
		hud.refresh(true)


# ===================== الوحدات =====================

func _move_toward(e, tp: Vector2, dt: float) -> void:
	var s: Dictionary = Data.UT[e.type]
	var dv: Vector2 = tp - e.p
	var d := dv.length()
	if d < 0.05:
		return
	var dir := dv / d
	for b in ents:
		if b.kind != "b" or b.dead:
			continue
		var o: Vector2 = e.p - b.p
		var od := maxf(o.length(), 0.01)
		var rr: float = b.r * 1.2 + e.r + 2.8
		if od < rr and dir.dot(-o / od) > 0.0 and tp.distance_to(b.p) > b.r * 1.2:
			var tn := Vector2(-o.y, o.x) / od
			if tn.dot(dir) < 0.0:
				tn = -tn
			var w := 1.6 * (1.0 - od / rr)
			dir += tn * w + o / od * w * 0.4
	dir = dir.normalized()
	e.ang = _turn(e.ang, dir.angle(), dt * 7.0)
	var step := minf(s["spd"] * dt * (1.0 + 0.08 * e.vet), d)
	e.p += dir * step
	e.walk += step


func _upd_unit(e, dt: float) -> void:
	var s: Dictionary = Data.UT[e.type]
	if e.cd > 0.0:
		e.cd -= dt
	if e.hit > 0.0:
		e.hit -= dt
	if e.rec > 0.0:
		e.rec = maxf(0.0, e.rec - dt * 4.0)
	if e.drop > 0.0:
		e.drop = maxf(0.0, e.drop - dt * 6.0)
		return
	if e.vet > 0 and e.hp < e.mhp:
		e.hp = minf(e.mhp, e.hp + dt * 2.0 * e.vet)
	if e.tgt != null and not alive(e.tgt):
		e.tgt = null
		e.forced = false
	if e.type == "worker":
		_worker(e, dt)
		return
	var turret_t: bool = e.type == "tank" or e.type == "art"
	if e.tgt == null and (e.mv == null or e.amove):
		e.scan -= dt
		if e.scan <= 0.0:
			e.scan = 0.3 + randf() * 0.2
			e.tgt = _nearest_enemy(e, maxf(s["sight"], s["range"]))
	if e.tgt != null:
		var tg = e.tgt
		var d: float = e.p.distance_to(tg.p) - tg.r
		var a: float = (tg.p - e.p).angle()
		if not e.forced and d > s["sight"] * 1.4:
			e.tgt = null
			return
		if d > s["range"]:
			_move_toward(e, tg.p, dt)
			if turret_t:
				e.tang = _turn(e.tang, a, dt * 4.0)
			return
		if s.has("minR") and d < s["minR"]:
			_move_toward(e, e.p - (tg.p - e.p), dt)
			return
		var aim := 0.0
		if turret_t:
			e.tang = _turn(e.tang, a, dt * 4.0)
			aim = angle_difference(e.tang, a)
		else:
			e.ang = _turn(e.ang, a, dt * 8.0)
			aim = angle_difference(e.ang, a)
		if e.cd <= 0.0 and absf(aim) < 0.25:
			_fire(e, tg)
			e.cd = s["rof"] * randf_range(0.9, 1.1)
		return
	if turret_t:
		e.tang = _turn(e.tang, e.ang, dt * 3.0)
	if e.mv != null:
		var d2: float = e.p.distance_to(e.mv)
		if d2 < e.r + 0.6:
			e.mv = null
			e.amove = false
			return
		if d2 < 5.0:
			e.stuck += dt
			if e.stuck > 1.4:
				e.mv = null
				e.amove = false
				e.stuck = 0.0
				return
		_move_toward(e, e.mv, dt)


func _worker(e, dt: float) -> void:
	if e.mv != null:
		var d: float = e.p.distance_to(e.mv)
		if d < e.r + 0.6:
			e.mv = null
		else:
			if d < 5.0:
				e.stuck += dt
				if e.stuck > 1.4:
					e.mv = null
					e.stuck = 0.0
			if e.mv != null:
				_move_toward(e, e.mv, dt)
		return
	if e.st != "harvest":
		return
	if e.carry > 0 and (e.carry >= 10 or e.mine == null or e.mine["amt"] <= 0):
		var dep = _nearest_drop(e)
		if dep == null:
			return
		if e.p.distance_to(dep.p) < dep.r * 1.2 + e.r + 1.2:
			var mult: float = D["inc"] if e.team == EN else 1.0
			gold[e.team] += int(round(e.carry * mult))
			e.carry = 0
		else:
			_move_toward(e, dep.p, dt)
		return
	if e.mine == null or e.mine["amt"] <= 0:
		e.mine = _nearest_mine(e)
	var m = e.mine
	if m == null:
		return
	if e.p.distance_to(m["p"]) < m["r"] + e.r + 1.4:
		e.mt += dt * (1.0 + 0.4 * up[e.team]["har"])
		if e.mt >= 2.0:
			e.mt = 0.0
			var g: int = mini(10, m["amt"])
			m["amt"] -= g
			e.carry = g
	else:
		_move_toward(e, m["p"], dt)


# ===================== المباني =====================

func _upd_bld(b, dt: float) -> void:
	var s: Dictionary = Data.BT[b.type]
	if b.hit > 0.0:
		b.hit -= dt
	if b.prog < 1.0:
		var m: float = D["bmul"] if b.team == EN else 1.0
		b.prog = minf(1.0, b.prog + dt / s["time"] * m)
		b.hp = minf(b.mhp, b.hp + b.mhp * 0.9 * dt / s["time"] * m)
		if b.prog >= 1.0 and not b.announced:
			b.announced = true
			if b.team == PL:
				hud.toast("اكتمل بناء " + s["n"])
				Sfx.play("done")
		return
	if b.type == "tower":
		if b.cd > 0.0:
			b.cd -= dt
		if b.tgt != null and (not alive(b.tgt) or b.p.distance_to(b.tgt.p) - b.tgt.r > s["range"]):
			b.tgt = null
		if b.tgt == null:
			b.tgt = _nearest_enemy(b, s["range"])
		if b.tgt != null:
			var a: float = (b.tgt.p - b.p).angle()
			b.tang = _turn(b.tang, a, dt * 4.0)
			if b.cd <= 0.0 and absf(angle_difference(b.tang, a)) < 0.2:
				_fire(b, b.tgt)
				b.cd = s["rof"]
		return
	if b.q.is_empty():
		return
	var it: String = b.q[0]
	b.pt += dt
	if b.pt < _item_time(it):
		return
	if it.begins_with("r:"):
		var k := it.substr(2)
		up[b.team][k] = 1
		b.q.pop_front()
		b.pt = 0.0
		if b.team == PL:
			hud.toast("اكتمل تطوير " + Data.RS[k]["n"])
			Sfx.play("done")
		return
	if unit_count(b.team) >= CAP:
		b.pt = _item_time(it)
		return
	b.q.pop_front()
	b.pt = 0.0
	var tp: Vector2 = b.rally if b.rally != null else Vector2(M / 2, M / 2)
	var a2: float = (tp - b.p).angle()
	var u := mk_unit(b.team, it, b.p + Vector2.from_angle(a2) * (b.r * 1.2 + 1.6))
	u.ang = a2
	u.tang = a2
	if b.team == PL:
		Sfx.play("ready", -4.0)
	if b.rally != null:
		if it == "worker":
			var mn = _pick_mine(b.rally)
			if mn != null:
				u.mine = mn
			else:
				u.mv = b.rally
				u.st = "idle"
		else:
			u.mv = b.rally + Vector2(randf_range(-2, 2), randf_range(-2, 2))
			u.amove = true
	elif it != "worker":
		u.mv = u.p + Vector2.from_angle(a2) * 5.0


func can_place(tm: int, type: String, x: float, y: float) -> bool:
	var r: float = Data.BT[type]["size"]
	if x < r + 3 or y < r + 3 or x > M - r - 3 or y > M - r - 3:
		return false
	var near := false
	var p := Vector2(x, y)
	for e in ents:
		var d: float = e.p.distance_to(p)
		if e.kind == "b":
			if d < e.r * 1.2 + r * 1.2 + 1.0:
				return false
			if e.team == tm and d < e.r + r + 28.0:
				near = true
		elif e.team != tm and d < r * 1.2 + e.r:
			return false
	for m in mines:
		if p.distance_to(m["p"]) < m["r"] + r + 2.4:
			return false
	return near


func _find_spot(tm: int, type: String):
	var own := []
	for e in ents:
		if e.team == tm and e.kind == "b":
			own.append(e)
	if own.is_empty():
		return null
	var enemy_hq = _find_bld(1 - tm, "hq")
	for i in 80:
		var b = own[randi() % own.size()]
		var a := randf() * TAU
		if type == "tower" and enemy_hq != null:
			a = (enemy_hq.p - b.p).angle() + randf_range(-1.0, 1.0)
		var d: float = b.r * 1.2 + Data.BT[type]["size"] * 1.2 + 2.0 + randf() * 13.0
		var p: Vector2 = b.p + Vector2.from_angle(a) * d
		if can_place(tm, type, p.x, p.y):
			return p
	return null


# ===================== القتال =====================

func _muzzle_h(e) -> float:
	match e.type:
		"tank":
			return 1.45
		"art":
			return 2.0
		"tower":
			return 4.1
		_:
			return 1.4


func _fire(e, tg) -> void:
	var s: Dictionary = Data.UT[e.type] if e.kind == "u" else Data.BT[e.type]
	var dt: String = s["dtype"]
	var a: float = (tg.p - e.p).angle()
	var off: float = e.r + (2.8 if e.type == "art" else 1.0)
	var start: Vector2 = e.p + Vector2.from_angle(a) * off
	var tp: Vector2 = tg.p
	if dt == "art":
		tp += Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5))
	var sp: float = {"bullet": 90.0, "rocket": 40.0, "shell": 62.0, "art": 32.0}[dt]
	var h := _muzzle_h(e)
	var node := Fx.projectile(fx_root, dt)
	node.position = Vector3(start.x, h, start.y)
	projs.append({"p": start, "h": h, "t": tg, "tp": tp, "sp": sp, "dt": dt, "dmg": _dmg_of(e), "src": e, "team": e.team, "splash": s.get("splash", 0.0), "node": node, "d0": maxf(0.5, start.distance_to(tp)), "dead": false})
	Fx.muzzle(fx_root, Vector3(start.x, h, start.y), dt)
	if cam.is_position_in_frustum(Vector3(start.x, h, start.y)):
		Sfx.play(dt, -9.0 if dt == "bullet" else -4.0, 0.07)
	if e.kind == "u":
		e.rec = 1.0


func _upd_proj(dt: float) -> void:
	var keep := []
	for pr in projs:
		var tp: Vector2 = pr["tp"]
		if pr["dt"] != "art" and alive(pr["t"]):
			tp = pr["t"].p
			pr["tp"] = tp
		var dv: Vector2 = tp - pr["p"]
		var d := dv.length()
		var st: float = pr["sp"] * dt
		if d <= st:
			pr["dead"] = true
			_impact(pr, tp)
			pr["node"].queue_free()
			continue
		pr["p"] += dv / d * st
		var k := clampf(1.0 - (d - st) / pr["d0"], 0.0, 1.0)
		var y: float
		if pr["dt"] == "art":
			y = lerpf(pr["h"], 0.5, k) + sin(k * PI) * pr["d0"] * 0.3
		else:
			y = lerpf(pr["h"], 1.0, k)
		var node: Node3D = pr["node"]
		node.position = Vector3(pr["p"].x, y, pr["p"].y)
		node.rotation.y = -dv.angle()
		keep.append(pr)
	projs = keep


func _impact(pr: Dictionary, tp: Vector2) -> void:
	if pr["splash"] > 0.0:
		for e in ents:
			if e.team == pr["team"] or e.dead:
				continue
			var d: float = e.p.distance_to(tp) - e.r
			if d < pr["splash"]:
				_hurt(e, pr["dmg"] * (1.0 - 0.5 * maxf(0.0, d) / pr["splash"]), pr["dt"], pr["src"], pr["team"])
		_boom(tp, 1.2)
	else:
		if alive(pr["t"]):
			_hurt(pr["t"], pr["dmg"], pr["dt"], pr["src"], pr["team"])
		Fx.spark(fx_root, Vector3(tp.x, 1.0, tp.y), pr["dt"])


func _hurt(tg, amt: float, dtype: String, src, team: int) -> void:
	if not alive(tg) or tg.team == team:
		return
	var cls: String = "bld" if tg.kind == "b" else Data.UT[tg.type]["armor"]
	var a: float = amt * Data.MULT[dtype][cls]
	if tg.kind == "u" and up[tg.team]["arm"] == 1:
		a *= 0.78
	tg.hp -= a
	tg.hit = 0.15
	if tg.kind == "u" and tg.type != "worker" and alive(src) and tg.tgt == null and tg.mv == null:
		tg.tgt = src
	if tg.hp <= 0.0:
		_kill(tg, src)


func _kill(tg, src) -> void:
	tg.dead = true
	var s := 3.0 if tg.kind == "b" else (2.0 if tg.r > 1.2 else 1.0)
	_boom(tg.p, s)
	if alive(src) and src.kind == "u":
		src.kills += 1
		var v := 2 if src.kills >= 8 else (1 if src.kills >= 3 else 0)
		if v > src.vet:
			src.vet = v
			src.hp = src.mhp
			Models.set_vet(src, v)
			if src.team == PL:
				hud.toast("ترقية " + Data.UT[src.type]["n"] + " إلى الرتبة " + str(v))
	if tg.team == EN:
		stats["kills"] += 1
	elif tg.kind == "u":
		stats["lost"] += 1
	if tg.team == PL and tg.kind == "b":
		hud.toast("فقدنا " + Data.BT[tg.type]["n"])


func _boom(p: Vector2, s: float) -> void:
	if not is_instance_valid(fx_root):
		return
	Fx.explosion(fx_root, Vector3(p.x, 0.8, p.y), s)
	if cam.is_position_in_frustum(Vector3(p.x, 0.8, p.y)):
		Sfx.play("boom", -3.0, 0.1)
		shake = minf(1.2, shake + 0.35 * s)
	Fx.scorch(fx_root, Vector3(p.x, 0.0, p.y), s)


# ===================== القدرات =====================

func use_power(tm: int, k: String, p := Vector2.ZERO) -> void:
	if k == "air":
		pw[tm]["air"] = Data.AIR_CD
		var dir := Vector2(1, -0.6).normalized() if tm == PL else Vector2(-1, 0.6).normalized()
		strikes.append({"p": p, "t": 2.2, "team": tm, "jet": Models.jet(fx_root, TEAM_COLORS[tm]), "marker": Models.strike_marker(fx_root, p), "done": false, "dir": dir})
		hud.toast("الطائرات في الطريق" if tm == PL else "تحذير: غارة جوية معادية!")
		Sfx.play("strike" if tm == PL else "alert")
	elif k == "rein":
		var hq = _find_bld(tm, "hq")
		if hq == null:
			return
		pw[tm]["rein"] = Data.REIN_CD
		var types := ["inf", "inf", "inf", "rocket"]
		for i in types.size():
			var a := i * 1.6 + (PI if tm == EN else 0.0)
			var u := mk_unit(tm, types[i], hq.p + Vector2.from_angle(a) * 9.0)
			u.drop = 14.0
			Models.add_chute(u)
		if tm == PL:
			hud.toast("وصل الإنزال المظلي")


func _upd_strikes(dt: float) -> void:
	for s in strikes:
		s["t"] -= dt
		if s["t"] <= 0.0 and not s["done"]:
			s["done"] = true
			for i in 7:
				var bp: Vector2 = s["p"] + Vector2(randf_range(-9, 9), randf_range(-9, 9))
				var cb := func():
					if running:
						_boom(bp, 1.6)
				get_tree().create_timer(i * 0.07).timeout.connect(cb)
			for e in ents:
				if e.team == s["team"] or e.dead:
					continue
				var d: float = e.p.distance_to(s["p"]) - e.r
				if d < 13.0:
					_hurt(e, 230.0 * (1.0 - 0.5 * maxf(0.0, d) / 13.0), "strike", null, s["team"])
	var keep := []
	for s in strikes:
		if s["t"] < -1.6:
			s["jet"].queue_free()
			s["marker"].queue_free()
		else:
			keep.append(s)
	strikes = keep


# ===================== الذكاء الاصطناعي =====================

func _ai(dt: float) -> void:
	ai["timer"] -= dt
	ai["t"] -= dt
	if ai["t"] > 0.0:
		return
	ai["t"] = 1.0
	var blds := []
	var army := []
	var workers := 0
	for e in ents:
		if e.team != EN:
			continue
		if e.kind == "b":
			blds.append(e)
		elif e.type == "worker":
			workers += 1
		else:
			army.append(e)
	if blds.is_empty():
		return
	var hq = _find_bld(EN, "hq")
	var cnt := {}
	for b in blds:
		cnt[b.type] = cnt.get(b.type, 0) + 1
	if hq != null and hq.prog >= 1.0 and hq.q.size() < 2 and gold[EN] >= 50:
		var queued: int = hq.q.count("worker")
		if workers + queued < 6 + cnt.get("depot", 0) * 2:
			hq.q.append("worker")
			gold[EN] -= 50
	var need := {}
	var pending := ""
	var building := false
	for b in blds:
		if b.prog < 1.0:
			building = true
	for ty in Data.AI_ORDER:
		need[ty] = need.get(ty, 0) + 1
		if cnt.get(ty, 0) < need[ty]:
			pending = ty
			if not building and gold[EN] >= Data.BT[ty]["cost"] and req_ok(EN, ty):
				var sp = _find_spot(EN, ty)
				if sp != null:
					gold[EN] -= Data.BT[ty]["cost"]
					mk_bld(EN, ty, sp, false)
					pending = ""
			break
	if D["res"] and hq != null and hq.prog >= 1.0 and has_built(EN, "factory") and hq.q.is_empty() and gold[EN] > 600:
		for k in ["wep", "arm", "har"]:
			if up[EN][k] == 0:
				hq.q.append("r:" + k)
				gold[EN] -= Data.RS[k]["cost"]
				break
	var reserve: float = Data.BT[pending]["cost"] * 0.5 if pending != "" else 0.0
	var pl_armor := 0
	for e in ents:
		if e.team == PL and (e.type == "tank" or e.type == "art"):
			pl_armor += 1
	for b in blds:
		if b.prog < 1.0 or b.q.size() >= 2:
			continue
		var ty2 := ""
		if b.type == "barracks":
			ty2 = "rocket" if randf() < (0.6 if pl_armor > 3 else 0.3) else "inf"
		elif b.type == "factory":
			ty2 = "tank" if randf() < 0.65 else "art"
		if ty2 != "" and gold[EN] >= Data.UT[ty2]["cost"] + reserve:
			b.q.append(ty2)
			gold[EN] -= Data.UT[ty2]["cost"]
	var threat = null
	for e in ents:
		if e.team == PL and e.kind == "u":
			for b in blds:
				if b.p.distance_to(e.p) < 42.0:
					threat = e
					break
		if threat != null:
			break
	if threat != null:
		for u in army:
			if u.tgt == null and not u.attacking and u.p.distance_to(threat.p) < 90.0:
				u.mv = threat.p
				u.amove = true
	var pl_b := []
	for e in ents:
		if e.team == PL and e.kind == "b":
			pl_b.append(e)
	if army.size() >= ai["wave_size"] or (ai["timer"] <= 0.0 and army.size() >= 4):
		if not pl_b.is_empty():
			ai["wave"] += 1
			ai["wave_size"] += 2
			ai["timer"] = D["int"]
			var c := Vector2.ZERO
			for u in army:
				c += u.p
			c /= army.size()
			var tg = _closest(pl_b, c)
			for u in army:
				u.mv = tg.p + Vector2(randf_range(-6, 6), randf_range(-6, 6))
				u.amove = true
				u.attacking = true
			hud.toast("العدو يشن هجوماً! (الموجة %d)" % ai["wave"])
			Sfx.play("alert")
	for u in army:
		if u.attacking and u.tgt == null and u.mv == null and not pl_b.is_empty():
			u.mv = _closest(pl_b, u.p).p
			u.amove = true
	if D["air"] and pw[EN]["air"] <= 0.0 and has_built(EN, "factory"):
		var pu := []
		for e in ents:
			if e.team == PL and e.kind == "u" and e.type != "worker":
				pu.append(e)
		for u in pu:
			var n := 0
			for o in pu:
				if o.p.distance_to(u.p) < 13.0:
					n += 1
			if n >= 4:
				use_power(EN, "air", u.p)
				break
		if pw[EN]["air"] <= 0.0 and randf() < 0.05 and not pl_b.is_empty():
			use_power(EN, "air", pl_b[randi() % pl_b.size()].p)
	if diff == 2 and pw[EN]["rein"] <= 0.0 and has_built(EN, "barracks"):
		use_power(EN, "rein")


func _closest(arr: Array, p: Vector2):
	var best = arr[0]
	var bd := 1e9
	for e in arr:
		var d: float = e.p.distance_to(p)
		if d < bd:
			bd = d
			best = e
	return best


# ===================== الفيزياء البسيطة =====================

func _separate() -> void:
	var us := []
	for e in ents:
		if e.kind == "u" and not e.dead and e.drop <= 0.0:
			us.append(e)
	var n := us.size()
	for i in n:
		var a = us[i]
		for j in range(i + 1, n):
			var b = us[j]
			var dx: float = b.p.x - a.p.x
			var dy: float = b.p.y - a.p.y
			var m: float = a.r + b.r
			if dx > m or dx < -m or dy > m or dy < -m:
				continue
			var d := maxf(sqrt(dx * dx + dy * dy), 0.01)
			if d < m:
				var push := (m - d) * 0.5
				var nv := Vector2(dx / d, dy / d) * push
				a.p -= nv
				b.p += nv
	for b in ents:
		if b.kind != "b":
			continue
		var rr: float = b.r * 1.2
		for u in us:
			var o: Vector2 = u.p - b.p
			var m2: float = rr + u.r
			if absf(o.x) > m2 or absf(o.y) > m2:
				continue
			var d2 := maxf(o.length(), 0.01)
			if d2 < m2:
				u.p = b.p + o / d2 * m2
	for u in us:
		u.p = Vector2(clampf(u.p.x, 1, M - 1), clampf(u.p.y, 1, M - 1))


func _check_end() -> void:
	if over:
		return
	var pb := false
	var eb := false
	for e in ents:
		if e.kind == "b":
			if e.team == PL:
				pb = true
			else:
				eb = true
	if pb and eb:
		return
	over = true
	var won := not eb
	Sfx.play("victory" if won else "defeat", 0.0, 0.0)
	Sfx.music(false)
	var cb := func():
		hud.show_end(won)
		game_over.emit(won)
	get_tree().create_timer(1.6).timeout.connect(cb)


# ===================== العرض =====================

func _sync(e, dt: float) -> void:
	e.position = Vector3(e.p.x, e.drop, e.p.y)
	var selected := sel.has(e)
	if e.kind == "u":
		e.body.rotation.y = -e.ang
		if e.turret:
			e.turret.rotation.y = -(e.tang - e.ang)
		if e.barrel:
			e.barrel.position.x = e.barrel_x0 - e.rec * 0.4
		if e.cargo:
			e.cargo.visible = e.carry > 0
		if not e.legs.is_empty():
			var sw := sin(e.walk * 2.2) * 0.45
			e.legs[0].rotation.z = sw
			e.legs[1].rotation.z = -sw
		if e.chute and e.drop <= 0.0:
			e.chute.queue_free()
			e.chute = null
	else:
		e.body.scale.y = 0.08 + 0.92 * minf(e.prog, 1.0)
		if e.turret and e.type == "tower":
			e.turret.rotation.y = -e.tang - e.body.rotation.y
		if e.spin:
			e.spin.rotation.y += dt * 1.3
		if e.smoke:
			e.smoke.emitting = e.prog >= 1.0 and not e.q.is_empty()
		if e.dmg_fx == null and e.prog >= 1.0 and e.hp < e.mhp * 0.5:
			e.dmg_fx = Fx.damage_fire(e, e.h)
		elif e.dmg_fx != null and e.hp >= e.mhp * 0.5:
			e.dmg_fx.queue_free()
			e.dmg_fx = null
	e.ring.visible = selected
	var show_bar: bool = selected or e.hp < e.mhp
	e.hpbar.visible = show_bar
	if show_bar:
		Models.set_bar(e, e.hp / e.mhp)
		e.hpbar.position.y = e.h * (e.body.scale.y if e.kind == "b" else 1.0) + 0.9


func _visuals(dt: float) -> void:
	for e in ents:
		_sync(e, dt)
	for m in mines:
		m["beam"].rotation.z = sin(t * 2.2 + m["p"].x) * 0.32 if m["amt"] > 0 else 0.0
	for s in strikes:
		var k: float = s["t"]
		var jp: Vector2 = s["p"] - s["dir"] * (k * 32.0)
		s["jet"].position = Vector3(jp.x, 16.0, jp.y)
		s["jet"].rotation.y = -s["dir"].angle()
		var pulse := 1.0 + sin(t * 10.0) * 0.04
		s["marker"].scale = Vector3(pulse, 1, pulse)
		s["marker"].visible = k > 0.0
	_update_ghost()


func _update_ghost() -> void:
	if placing == "":
		if ghost:
			ghost.visible = false
		return
	if ghost == null:
		ghost = MeshInstance3D.new()
		ghost.mesh = BoxMesh.new()
		ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(ghost)
	var r: float = Data.BT[placing]["size"]
	(ghost.mesh as BoxMesh).size = Vector3(r * 2, 0.6, r * 2)
	var sp := last_pointer
	if sp.x < 0:
		sp = get_viewport().get_visible_rect().size * 0.5
	var g := ground_at(sp)
	ghost.position = Vector3(g.x, 0.3, g.z)
	var ok := can_place(PL, placing, g.x, g.z)
	ghost.material_override = Models.unshaded(Color(0.3, 1, 0.4, 0.4) if ok else Color(1, 0.25, 0.2, 0.4))
	ghost.visible = true


# ===================== الكاميرا واللمس =====================

func _update_cam() -> void:
	var off := Vector3(0, sin(PITCH), cos(PITCH)) * cam_dist
	off = off.rotated(Vector3.UP, cam_yaw)
	cam.position = cam_target + off
	cam.look_at(cam_target, Vector3.UP)
	if shake > 0.01:
		cam.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * shake


func _clamp_cam() -> void:
	cam_target.x = clampf(cam_target.x, 0, M)
	cam_target.z = clampf(cam_target.z, 10, M + 10)
	cam_dist = clampf(cam_dist, 28.0, 120.0)


func ground_at(sp: Vector2) -> Vector3:
	var o := cam.project_ray_origin(sp)
	var d := cam.project_ray_normal(sp)
	if absf(d.y) < 0.0001:
		return cam_target
	var k := -o.y / d.y
	if k < 0.0:
		return cam_target
	return o + d * k


func _pinch_dist() -> float:
	var v := touches.values()
	if v.size() < 2:
		return 0.0
	return (v[0] as Vector2).distance_to(v[1])


func _unhandled_input(ev: InputEvent) -> void:
	if not running or over or paused:
		return
	if ev is InputEventScreenTouch:
		if ev.pressed:
			if hud.is_over_ui(ev.position):
				ignored[ev.index] = true
				return
			touches[ev.index] = ev.position
			last_pointer = ev.position
			if touches.size() == 1:
				drag_moved = false
				drag_start = ev.position
			else:
				drag_moved = true
				pinch_d = _pinch_dist()
		else:
			if ignored.has(ev.index):
				ignored.erase(ev.index)
				return
			touches.erase(ev.index)
			if touches.is_empty() and not drag_moved:
				_on_tap(ev.position)
			pinch_d = _pinch_dist()
	elif ev is InputEventScreenDrag:
		if ignored.has(ev.index):
			return
		var prev: Vector2 = touches.get(ev.index, ev.position)
		touches[ev.index] = ev.position
		last_pointer = ev.position
		if touches.size() >= 2:
			var nd := _pinch_dist()
			if pinch_d > 0.0 and nd > 0.0:
				cam_dist *= pinch_d / nd
			pinch_d = nd
		else:
			if ev.position.distance_to(drag_start) > 14.0:
				drag_moved = true
			if drag_moved:
				var a := ground_at(prev)
				var b := ground_at(ev.position)
				cam_target += a - b
		_clamp_cam()
	elif ev is InputEventMouseButton and ev.pressed:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam_dist *= 0.9
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam_dist *= 1.1
		_clamp_cam()
	elif ev is InputEventMouseMotion:
		last_pointer = ev.position


func _pick(w: Vector2):
	var best = null
	var bd := 1e9
	var tol := cam_dist * 0.025
	for e in ents:
		if e.dead or e.drop > 0.0:
			continue
		var d: float = e.p.distance_to(w)
		var rr: float = e.r + tol if e.kind == "u" else e.r * 1.2
		if d < rr and d < bd:
			bd = d
			best = e
	return best


func _on_tap(sp: Vector2) -> void:
	var g := ground_at(sp)
	var w := Vector2(g.x, g.z)
	if placing != "":
		var ty := placing
		if not can_place(PL, ty, w.x, w.y):
			hud.toast("مكان غير صالح، ابنِ قرب قاعدتك")
			Sfx.play("error")
			return
		if gold[PL] < Data.BT[ty]["cost"]:
			hud.toast("النفط غير كافٍ")
			placing = ""
			hud.refresh(true)
			return
		gold[PL] -= Data.BT[ty]["cost"]
		mk_bld(PL, ty, w, false)
		Sfx.play("ack")
		placing = ""
		hud.refresh(true)
		return
	if power != "":
		use_power(PL, power, w)
		power = ""
		hud.refresh(true)
		return
	var hit = _pick(w)
	var su := []
	for x in sel:
		if x.kind == "u":
			su.append(x)
	if hit != null and hit.team == PL:
		if hit.kind == "u":
			var now := Time.get_ticks_msec()
			if last_tap_id == hit.get_instance_id() and now - last_tap_ms < 380:
				sel = []
				for e in ents:
					if e.team == PL and e.kind == "u" and e.type == hit.type and cam.is_position_in_frustum(e.position):
						sel.append(e)
			else:
				sel = [hit]
			last_tap_id = hit.get_instance_id()
			last_tap_ms = now
		else:
			sel = [hit]
		Sfx.play("select")
		hud.refresh(true)
		return
	if hit != null and hit.team == EN and not su.is_empty():
		for u in su:
			if u.type != "worker":
				u.tgt = hit
				u.forced = true
				u.mv = null
		Fx.ring_marker(fx_root, Vector3(hit.p.x, 0, hit.p.y), Color(1, 0.3, 0.2, 0.95))
		Sfx.play("ack")
		return
	var mn = _pick_mine(w)
	if mn != null:
		var any := false
		for u in su:
			if u.type == "worker":
				u.st = "harvest"
				u.mine = mn
				u.mv = null
				any = true
		if any:
			Fx.ring_marker(fx_root, Vector3(w.x, 0, w.y), Color(1, 0.85, 0.3, 0.95))
			Sfx.play("ack")
			return
	if not su.is_empty():
		_move_group(su, w)
		return
	if sel.size() == 1 and sel[0].kind == "b" and sel[0].type != "tower" and sel[0].prog >= 1.0:
		sel[0].rally = w
		hud.toast("تم تحديد نقطة التجمع")
		return
	if not sel.is_empty():
		sel = []
		hud.refresh(true)


func _move_group(us: Array, w: Vector2) -> void:
	var n := us.size()
	var cols := ceili(sqrt(n))
	var rows := ceili(float(n) / cols)
	var spc := 3.2
	for i in n:
		var u = us[i]
		var cx := i % cols
		var cy := i / cols
		u.mv = Vector2(clampf(w.x + (cx - (cols - 1) * 0.5) * spc, 2, M - 2), clampf(w.y + (cy - (rows - 1) * 0.5) * spc, 2, M - 2))
		u.tgt = null
		u.forced = false
		u.amove = false
		u.stuck = 0.0
		if u.type == "worker":
			u.st = "idle"
	Fx.ring_marker(fx_root, Vector3(w.x, 0, w.y), Color(0.4, 1, 0.5, 0.95))
	Sfx.play("ack")


# ===================== أوامر الواجهة =====================

func act(a: String) -> void:
	if not running or over:
		return
	Sfx.play("click", -4.0, 0.0)
	var g: int = gold[PL]
	if a.begins_with("b:"):
		var ty := a.substr(2)
		if not req_ok(PL, ty):
			hud.toast("يتطلب " + Data.BT[Data.BT[ty]["req"]]["n"])
		elif g < Data.BT[ty]["cost"]:
			hud.toast("النفط غير كافٍ")
		else:
			placing = ty
			sel = []
			hud.toast("اضغط على الأرض قرب قاعدتك")
	elif a.begins_with("u:"):
		var ty2 := a.substr(2)
		if sel.size() == 1 and sel[0].q.size() < 5:
			if g >= Data.UT[ty2]["cost"]:
				gold[PL] -= Data.UT[ty2]["cost"]
				sel[0].q.append(ty2)
			else:
				hud.toast("النفط غير كافٍ")
	elif a.begins_with("r:"):
		var k := a.substr(2)
		if sel.size() == 1 and up[PL][k] == 0 and not sel[0].q.has(a) and g >= Data.RS[k]["cost"]:
			gold[PL] -= Data.RS[k]["cost"]
			sel[0].q.append(a)
	elif a.begins_with("cq:"):
		var i := int(a.substr(3))
		if sel.size() == 1 and i < sel[0].q.size():
			gold[PL] += _item_cost(sel[0].q[i])
			sel[0].q.remove_at(i)
			if i == 0:
				sel[0].pt = 0.0
	elif a == "p:air":
		if not has_built(PL, "factory"):
			hud.toast("يتطلب المصنع")
		elif pw[PL]["air"] > 0.0:
			hud.toast("الغارة غير جاهزة بعد")
		else:
			power = "air"
			sel = []
			hud.toast("اختر هدف الغارة")
	elif a == "p:rein":
		if not has_built(PL, "barracks"):
			hud.toast("يتطلب الثكنة")
		elif pw[PL]["rein"] > 0.0:
			hud.toast("الإنزال غير جاهز بعد")
		else:
			use_power(PL, "rein")
	elif a == "cancel":
		placing = ""
		power = ""
	elif a == "desel":
		sel = []
	elif a == "stop":
		for u in sel:
			u.mv = null
			u.tgt = null
			u.forced = false
			u.amove = false
	elif a == "army":
		sel = []
		for e in ents:
			if e.team == PL and e.kind == "u" and e.type != "worker":
				sel.append(e)
		if sel.is_empty():
			hud.toast("لا توجد قوات بعد")
	elif a == "home":
		var hq = _find_bld(PL, "hq")
		if hq != null:
			cam_target = Vector3(hq.p.x, 0, hq.p.y - 6)
	hud.refresh(true)


func _sp(a: String, txt: String, ic: String, dis: bool) -> Dictionary:
	return {"a": a, "t": txt, "ic": ic, "dis": dis}


func panel_specs() -> Array:
	var r := []
	var g: int = gold[PL]
	if placing != "" or power != "":
		r.append(_sp("cancel", "إلغاء", "", false))
		return r
	if sel.size() == 1 and sel[0].kind == "b":
		var b = sel[0]
		if b.prog >= 1.0:
			for k in Data.UT:
				if Data.UT[k]["from"] == b.type:
					r.append(_sp("u:" + k, "%s\n%d" % [Data.UT[k]["n"], Data.UT[k]["cost"]], "u:" + k, g < Data.UT[k]["cost"] or b.q.size() >= 5))
			if b.type == "hq":
				for k in Data.RS:
					var done: bool = up[PL][k] == 1
					var inq: bool = b.q.has("r:" + k)
					r.append(_sp("r:" + k, "%s\n%s" % [Data.RS[k]["n"], "مكتمل" if done else str(Data.RS[k]["cost"])], "r:" + k, done or inq or g < Data.RS[k]["cost"]))
			for i in b.q.size():
				var it: String = b.q[i]
				r.append(_sp("cq:%d" % i, "إلغاء", it if it.begins_with("r:") else "u:" + it, false))
		r.append(_sp("desel", "رجوع", "", false))
		return r
	r.append(_sp("army", "كل\nالجيش", "", false))
	if not sel.is_empty():
		r.append(_sp("stop", "توقف", "", false))
		r.append(_sp("desel", "إلغاء\nالتحديد", "", false))
	else:
		for k in Data.BUILD_MENU:
			var ok := req_ok(PL, k)
			r.append(_sp("b:" + k, "%s\n%s" % [Data.BT[k]["n"], str(Data.BT[k]["cost"]) if ok else "مقفل"], "b:" + k, not ok or g < Data.BT[k]["cost"]))
	var air_cd: float = pw[PL]["air"]
	var rein_cd: float = pw[PL]["rein"]
	r.append(_sp("p:air", "غارة جوية\n%s" % ("%d ث" % ceili(air_cd) if air_cd > 0.0 else "جاهزة"), "x:jet", air_cd > 0.0 or not has_built(PL, "factory")))
	r.append(_sp("p:rein", "إنزال\n%s" % ("%d ث" % ceili(rein_cd) if rein_cd > 0.0 else "جاهز"), "x:chute", rein_cd > 0.0 or not has_built(PL, "barracks")))
	r.append(_sp("home", "القاعدة", "", false))
	return r


func info_text() -> String:
	if placing != "":
		return "اضغط على الأرض لبناء " + Data.BT[placing]["n"] + " قرب قاعدتك"
	if power != "":
		return "اضغط على هدف الغارة الجوية"
	if sel.size() == 1 and sel[0].kind == "b":
		var b = sel[0]
		var s: Dictionary = Data.BT[b.type]
		var txt := "%s   الصحة %d/%d" % [s["n"], ceili(b.hp), int(b.mhp)]
		if b.prog < 1.0:
			txt += "   قيد البناء %d%%" % int(b.prog * 100)
		elif not b.q.is_empty():
			var it: String = b.q[0]
			var nm: String = Data.RS[it.substr(2)]["n"] if it.begins_with("r:") else Data.UT[it]["n"]
			txt += "   ينتج: %s %d%%   في الطابور %d" % [nm, int(minf(1.0, b.pt / _item_time(it)) * 100), b.q.size()]
		elif b.type == "tower":
			txt += "   يهاجم تلقائياً"
		else:
			txt += "   اضغط على الأرض لتحديد نقطة التجمع"
		return txt
	if not sel.is_empty():
		var cnt := {}
		for u in sel:
			cnt[u.type] = cnt.get(u.type, 0) + 1
		var parts := []
		for k in cnt:
			parts.append("%s ×%d" % [Data.UT[k]["n"], cnt[k]])
		return "  ".join(parts) + "   اضغط على الأرض للتحرك أو على العدو للهجوم"
	return "اختر مبنى للبناء أو اضغط على وحداتك لتحديدها"


# ===================== المرحلة التعليمية =====================

func skip_tutorial() -> void:
	tut = -1
	hud.set_tutorial("", "")
	_point(null)


func _point(p) -> void:
	if arrow == null:
		arrow = Node3D.new()
		world.add_child(arrow)
		var m := Models.unshaded(Color(1, 0.82, 0.2))
		Models.cyl(arrow, 1.1, 2.2, Vector3(0, -1.1, 0), m, Vector3(180, 0, 0), 0.0, 4)
		Models.box(arrow, Vector3(0.7, 2.0, 0.7), Vector3(0, 1.0, 0), m)
	if p == null:
		arrow.visible = false
		return
	arrow.visible = true
	arrow.position.x = p.x
	arrow.position.z = p.y


func _tutorial() -> void:
	if tut < 0 or not running or over:
		return
	var hq = _find_bld(PL, "hq")
	var br = _find_bld(PL, "barracks")
	var txt := ""
	var hl := ""
	var pt = null
	match tut:
		0:
			txt = "١) اضغط زر «الثكنة» تحت عشان تبني ثكنة لتدريب الجنود"
			hl = "b:barracks"
			if placing == "barracks" or br != null:
				tut = 1
		1:
			txt = "٢) اضغط على الأرض الفاضية جنب القيادة (المكان الأخضر)"
			if hq != null:
				pt = hq.p + Vector2(15, 2)
			if br != null:
				tut = 2
			elif placing == "":
				tut = 0
		2:
			txt = "٣) الثكنة قيد البناء… شاحنات النفط بتجمع لك المال تلقائياً"
			if br != null:
				pt = br.p
				if br.prog >= 1.0:
					tut = 3
		3:
			txt = "٤) اضغط على الثكنة عشان تختارها"
			if br != null:
				pt = br.p
				if sel.has(br):
					tut = 4
		4:
			txt = "٥) اضغط زر «جندي» عشان تدرّب جندي"
			hl = "u:inf"
			if br != null and (br.q.has("inf") or _first_unit("inf") != null):
				tut = 5
			elif br != null and not sel.has(br):
				tut = 3
		5:
			txt = "٦) الجندي قيد التدريب…"
			var u0 = _first_unit("inf")
			if u0 != null:
				tut_unit = u0
				tut = 6
		6:
			txt = "٧) اضغط على الجندي عشان تختاره"
			if not alive(tut_unit):
				tut_unit = _first_unit("inf")
			if tut_unit != null:
				pt = tut_unit.p
				if sel.has(tut_unit):
					tut = 7
		7:
			txt = "٨) اضغط على أي مكان في الأرض عشان يتحرك هناك"
			if alive(tut_unit) and tut_unit.mv != null:
				tut = 8
				tut_t = 0.0
			elif not alive(tut_unit) or not sel.has(tut_unit):
				tut = 6
		8:
			txt = "ممتاز! درّب جيشك، ابنِ المصنع للدبابات، ودمّر قاعدة العدو الحمراء"
			var ehq = _find_bld(EN, "hq")
			if ehq != null:
				pt = ehq.p
			tut_t += 0.25
			if tut_t > 9.0:
				skip_tutorial()
				return
	hud.set_tutorial(txt, hl)
	_point(pt)


func _first_unit(type: String):
	for e in ents:
		if e.team == PL and e.kind == "u" and e.type == type:
			return e
	return null


func toggle_speed() -> void:
	speed = 2 if speed == 1 else 1


func set_paused(v: bool) -> void:
	if not running or over:
		return
	paused = v
	if v:
		hud.show_pause()
	else:
		hud.hide_pause()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if running and not over:
			set_paused(true)
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if running and not over:
			if placing != "" or power != "" or not sel.is_empty():
				act("cancel")
				act("desel")
			else:
				set_paused(not paused)
