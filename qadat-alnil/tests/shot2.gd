extends SceneTree
var game
var f := 0
var t0 := 0
func _initialize() -> void:
	t0 = Time.get_ticks_msec()
	var sc = load("res://scenes/main.tscn").instantiate()
	root.add_child(sc)
	game = sc
func _process(_d: float) -> bool:
	f += 1
	if f == 2:
		print("first frame ms: ", Time.get_ticks_msec() - t0)
	if f == 20:
		game.start_game(0)
	if f == 40:
		game.act("b:barracks")
	if f == 60:
		_save("/tmp/tut1.png")
		var hq = game._find_bld(0, "hq")
		game.placing = ""
		var b = game.mk_bld(0, "barracks", hq.p + Vector2(15, 2), true)
		game.mk_bld(0, "factory", hq.p + Vector2(2, -16), true)
		game.sel = [b]
		game.hud.refresh(true)
	if f == 90:
		_save("/tmp/tut2.png")
		for i in 6:
			game.mk_unit(0, ["tank","inf","rocket"][i%3], game._find_bld(0,"hq").p + Vector2(20 + i*3, -4))
		game.act("army")
		game._move_group(game.sel, game._find_bld(0,"hq").p + Vector2(30, -10))
	if f > 90 and f < 140:
		game._update(0.03)
	if f == 125:
		_save("/tmp/tut3.png")
		return true
	return false
func _save(p: String) -> void:
	root.get_texture().get_image().save_png(p)
