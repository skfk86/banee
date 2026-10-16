extends SceneTree
## اختبار آلي: يشغّل مباراة بسرعة عالية ويتأكد من عدم وجود أخطاء.

var game
var frames := 0

func _initialize() -> void:
	var sc = load("res://scenes/main.tscn").instantiate()
	root.add_child(sc)
	game = sc

func _process(_d: float) -> bool:
	frames += 1
	if frames == 3:
		game.start_game(2)
		game.gold[0] = 9000
		var hq = game._find_bld(0, "hq")
		game.mk_bld(0, "barracks", hq.p + Vector2(14, 0), true)
		game.mk_bld(0, "factory", hq.p + Vector2(0, -16), true)
		for t in ["inf", "rocket", "tank", "art", "tank", "inf", "inf"]:
			game.mk_unit(0, t, hq.p + Vector2(20 + randf() * 6, -10 + randf() * 6))
		game.act("army")
		game.act("stop")
		game._on_tap(Vector2(640, 360))
		game.act("b:tower")
		game.act("cancel")
		game.sel = [game._find_bld(0, "factory")]
		game.act("u:tank")
		game.act("u:art")
		game.act("cq:1")
		game.sel = [hq]
		game.act("r:arm")
		game.act("desel")
		game.pw[0]["air"] = 0.0
		game.pw[0]["rein"] = 0.0
		game.act("p:rein")
		game.use_power(0, "air", Vector2(200, 40))
	if frames > 3 and frames < 1500:
		for i in 6:
			game._update(0.05)
		if frames % 200 == 0:
			var army = []
			for e in game.ents:
				if e.team == 0 and e.kind == "u" and e.type != "worker":
					army.append(e)
			game._move_group(army, Vector2(205, 35))
			for u in army:
				u.amove = true
			print("t=%d gold=%s ents=%d projs=%d wave=%d over=%s" % [game.t, game.gold, game.ents.size(), game.projs.size(), game.ai["wave"], game.over])
	if frames >= 1500 or game.over:
		print("END t=%d over=%s kills=%s" % [game.t, game.over, game.stats])
		return true
	return false
