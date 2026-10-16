class_name Minimap
extends Control
## الخريطة المصغرة: اضغط أو اسحب عليها لتحريك الكاميرا.

var game


func _draw() -> void:
	if game == null:
		return
	var s := size
	var k: float = s.x / game.M
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.55, 0.45, 0.3))
	draw_rect(Rect2(Vector2(s.x * 0.45, 0), Vector2(s.x * 0.1, s.y)), Color(0.5, 0.41, 0.27))
	for m in game.mines:
		if m["amt"] > 0:
			draw_circle(m["p"] * k, 2.5, Color(1, 0.8, 0.25))
	for e in game.ents:
		var c: Color = game.TEAM_COLORS[e.team].lightened(0.25)
		var z := 7.0 if e.kind == "b" else 3.0
		draw_rect(Rect2(e.p * k - Vector2(z, z) * 0.5, Vector2(z, z)), c)
	for st in game.strikes:
		if st["t"] > 0.0:
			draw_arc(st["p"] * k, 13.0 * k, 0, TAU, 24, Color(1, 0.3, 0.2), 2.0)
	var vs: Vector2 = get_viewport().get_visible_rect().size
	var pts := PackedVector2Array()
	for c2 in [Vector2(0, 0), Vector2(vs.x, 0), vs, Vector2(0, vs.y)]:
		var g: Vector3 = game.ground_at(c2)
		pts.append(Vector2(clampf(g.x, 0, game.M), clampf(g.z, 0, game.M)) * k)
	pts.append(pts[0])
	draw_polyline(pts, Color(1, 1, 1, 0.9), 1.5)
	draw_rect(Rect2(Vector2.ZERO, s), Color(1, 1, 1, 0.25), false, 2.0)


func _gui_input(ev: InputEvent) -> void:
	var pos := Vector2(-1, -1)
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		pos = ev.position
	elif ev is InputEventMouseMotion and (ev.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		pos = ev.position
	if pos.x >= 0.0 and game != null and game.running:
		var w: Vector2 = pos / size.x * game.M
		game.cam_target = Vector3(clampf(w.x, 0, game.M), 0, clampf(w.y + 8.0, 0, game.M + 10))
		accept_event()
