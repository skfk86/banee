extends SceneTree
## يلتقط صوراً للعبة للمراجعة.
var game
var f := 0
func _initialize() -> void:
	var sc = load("res://scenes/main.tscn").instantiate()
	root.add_child(sc)
	game = sc
func _process(_d: float) -> bool:
	f += 1
	if f == 30:
		_save("/tmp/shot_menu.png")
		game.start_game(1)
		game.gold[0] = 3000
		var hq = game._find_bld(0, "hq")
		game.mk_bld(0, "barracks", hq.p + Vector2(15, 2), true)
		game.mk_bld(0, "factory", hq.p + Vector2(2, -16), true)
		game.mk_bld(0, "tower", hq.p + Vector2(16, -14), true)
		game.mk_bld(0, "depot", hq.p + Vector2(-12, -14), false).prog = 0.6
		for t in ["inf", "rocket", "tank", "art", "tank", "inf", "inf", "rocket"]:
			game.mk_unit(0, t, hq.p + Vector2(22 + randf() * 10, -6 + randf() * 8))
		for t in ["tank", "inf", "inf"]:
			game.mk_unit(1, t, hq.p + Vector2(42, -8 + randf() * 4))
		game.act("army")
		game.cam_target = Vector3(hq.p.x + 14, 0, hq.p.y - 6)
		game.cam_dist = 58
	if f > 30 and f < 200:
		game._update(0.03)
	if f == 200:
		_save("/tmp/shot_game.png")
		game.sel = [game._find_bld(0, "factory")]
		game.hud.refresh(true)
	if f == 215:
		_save("/tmp/shot_factory.png")
		return true
	return false
func _save(p: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png(p)
	print("saved ", p)
