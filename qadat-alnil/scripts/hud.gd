class_name Hud
extends CanvasLayer
## الواجهة العربية: الشريط العلوي، لوحة الأوامر، القوائم، والأيقونات المصوّرة من المجسمات.

const ACCENT := Color(0.9, 0.7, 0.3)

var game
var root: Control
var top_panel: PanelContainer
var bottom_panel: PanelContainer
var lbl_gold: Label
var lbl_pop: Label
var lbl_time: Label
var btn_speed: Button
var info: Label
var row: HBoxContainer
var minimap: Minimap
var toast_lbl: Label
var toast_tw: Tween
var menu: Control
var pause_ov: Control
var end_ov: Control
var end_title: Label
var end_stats: Label
var help_lbl: Label
var icons := {}
var btns := {}
var row_sig := ""
var tut_panel: PanelContainer
var tut_lbl: Label
var hl_action := ""


func _ready() -> void:
	layer = 10
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Noto Sans Arabic UI", "Noto Sans Arabic", "Noto Kufi Arabic", "Noto Naskh Arabic", "DejaVu Sans", "sans-serif"])
	font.font_weight = 600
	var th := Theme.new()
	th.default_font = font
	th.default_font_size = 18
	th.set_stylebox("normal", "Button", _sb(Color(0.12, 0.13, 0.14, 0.94), Color(1, 1, 1, 0.12)))
	th.set_stylebox("hover", "Button", _sb(Color(0.18, 0.19, 0.2, 0.96), Color(1, 1, 1, 0.28)))
	th.set_stylebox("pressed", "Button", _sb(Color(0.32, 0.25, 0.1, 0.98), ACCENT))
	th.set_stylebox("disabled", "Button", _sb(Color(0.09, 0.09, 0.1, 0.75), Color(1, 1, 1, 0.05)))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_color("font_color", "Button", Color(0.96, 0.94, 0.88))
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_pressed_color", "Button", Color.WHITE)
	th.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.35))
	th.set_constant("icon_max_width", "Button", 62)
	th.set_constant("h_separation", "Button", 2)
	th.set_stylebox("panel", "PanelContainer", _sb(Color(0.05, 0.055, 0.06, 0.84), Color(1, 1, 1, 0.08), 14))
	th.set_color("font_color", "Label", Color(0.96, 0.94, 0.88))
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = th
	root.layout_direction = Control.LAYOUT_DIRECTION_RTL
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_top()
	_build_bottom()
	_build_toast()
	_build_tutorial()
	_build_menu()
	_build_pause()
	_build_end()
	_build_splash()


func _sb(bg: Color, border: Color, rad := 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(rad)
	s.set_content_margin_all(8)
	s.anti_aliasing = true
	return s


func _lbl(parent: Control, txt: String, sz := 18, col := Color(0.96, 0.94, 0.88)) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l


func _btn(parent: Control, txt: String, cb: Callable, minsz := Vector2(0, 0), fs := 18) -> Button:
	var b := Button.new()
	b.pressed.connect(func(): Sfx.play("click", -4.0, 0.0))
	b.text = txt
	b.custom_minimum_size = minsz
	b.add_theme_font_size_override("font_size", fs)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


# ===================== البناء =====================

func _build_top() -> void:
	top_panel = PanelContainer.new()
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 10
	top_panel.offset_right = -10
	top_panel.offset_top = 8
	root.add_child(top_panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 22)
	top_panel.add_child(h)
	lbl_gold = _lbl(h, "", 21, ACCENT)
	lbl_pop = _lbl(h, "", 18)
	lbl_time = _lbl(h, "", 18, Color(0.8, 0.85, 0.9))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(sp)
	btn_speed = _btn(h, "السرعة ×1", func(): game.toggle_speed(), Vector2(110, 40), 16)
	_btn(h, "إيقاف مؤقت", func(): game.set_paused(true), Vector2(110, 40), 16)


func _build_bottom() -> void:
	bottom_panel = PanelContainer.new()
	bottom_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_panel.offset_left = 10
	bottom_panel.offset_right = -10
	bottom_panel.offset_bottom = -8
	bottom_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	root.add_child(bottom_panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	bottom_panel.add_child(h)
	minimap = Minimap.new()
	minimap.game = game
	minimap.custom_minimum_size = Vector2(150, 150)
	minimap.layout_direction = Control.LAYOUT_DIRECTION_LTR
	h.add_child(minimap)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	h.add_child(v)
	info = _lbl(v, "", 16, Color(1, 0.88, 0.62))
	info.clip_text = true
	info.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var sc := ScrollContainer.new()
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	sc.custom_minimum_size = Vector2(0, 118)
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	sc.add_child(row)


func _build_toast() -> void:
	toast_lbl = Label.new()
	toast_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	toast_lbl.offset_top = 78
	toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_lbl.add_theme_font_size_override("font_size", 24)
	toast_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	toast_lbl.add_theme_constant_override("outline_size", 8)
	toast_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_lbl.modulate.a = 0.0
	root.add_child(toast_lbl)


func _build_tutorial() -> void:
	tut_panel = PanelContainer.new()
	tut_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	tut_panel.offset_top = 70
	tut_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tut_panel.add_theme_stylebox_override("panel", _sb(Color(0.2, 0.14, 0.04, 0.92), ACCENT, 14))
	root.add_child(tut_panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	tut_panel.add_child(h)
	tut_lbl = _lbl(h, "", 21, Color(1, 0.95, 0.8))
	_btn(h, "تخطي الشرح", func(): game.skip_tutorial(), Vector2(0, 40), 15)
	tut_panel.visible = false


func set_tutorial(txt: String, hl: String) -> void:
	tut_panel.visible = txt != "" and game.running
	tut_lbl.text = txt
	hl_action = hl
	if txt != "":
		toast_lbl.offset_top = 140
	else:
		toast_lbl.offset_top = 78


func _process(_d: float) -> void:
	var k := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 140.0)
	for a in btns:
		var b: Button = btns[a]
		if not is_instance_valid(b):
			continue
		if a == hl_action:
			b.modulate = Color(1, 1, 1).lerp(Color(1.6, 1.3, 0.4), k)
		else:
			b.modulate = Color.WHITE


func _overlay(alpha: float) -> Control:
	var ov := ColorRect.new()
	ov.color = Color(0.03, 0.035, 0.03, alpha)
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(ov)
	return ov


func _center_box(ov: Control) -> VBoxContainer:
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.add_child(cc)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	cc.add_child(v)
	return v


func _build_menu() -> void:
	menu = _overlay(0.35)
	var v := _center_box(menu)
	var lg := TextureRect.new()
	lg.texture = load("res://art/logo.png")
	lg.custom_minimum_size = Vector2(150, 150)
	lg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(lg)
	var t := _lbl(v, "قادة النيل", 88, ACCENT)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.0, 0.9))
	t.add_theme_constant_override("outline_size", 14)
	var s := _lbl(v, "ابنِ قاعدتك، استخرج النفط، وقُد جيشك للنصر", 22)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	s.add_theme_constant_override("outline_size", 6)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	v.add_child(gap)
	for i in 3:
		var d: int = i
		var b := _btn(v, "ابدأ: " + Data.DIFF[i]["name"], func(): game.start_game(d), Vector2(340, 62), 26)
		b.add_theme_stylebox_override("normal", _sb([Color(0.16, 0.42, 0.22, 0.95), Color(0.5, 0.36, 0.1, 0.95), Color(0.5, 0.15, 0.1, 0.95)][i], Color(1, 1, 1, 0.25), 16))
	_btn(v, "طريقة اللعب", func(): help_lbl.visible = not help_lbl.visible, Vector2(340, 52), 20)
	help_lbl = _lbl(v, "", 17)
	help_lbl.text = "• اسحب بإصبع لتحريك الخريطة، وقرّب أو بعّد بإصبعين\n• اضغط على وحدة لتحديدها، وضغطتين لتحديد كل وحداتك من نفس النوع\n• اضغط على الأرض للتحرك، وعلى العدو للهجوم\n• العمال يجمعون النفط تلقائياً\n• اضغط على مبنى لإنتاج الوحدات، ثم على الأرض لنقطة التجمع\n• الصاروخي ضد الدبابات، والجندي ضد المشاة، والمدفعية ضد المباني\n• دمّر كل مباني العدو لتفوز"
	help_lbl.custom_minimum_size = Vector2(560, 0)
	help_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_lbl.visible = false
	var cr := _lbl(v, "", 15, Color(0.85, 0.82, 0.75))
	cr.text = "المجسمات: Kenney (CC0)، و 32kda و rgsdev و Sketlux و pixelmannen و JamesWhite من OpenGameArt (CC0)\nالأصوات: Kenney (CC0)، KuraiWolf (CC-BY 4.0)، NenadSimic (CC0)\nالموسيقى: Dizzy Crow — Desert Calmness and Fighting (CC0)"
	cr.custom_minimum_size = Vector2(560, 0)
	cr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cr.visible = false
	_btn(v, "الحقوق والمصادر", func(): cr.visible = not cr.visible, Vector2(340, 46), 18)


func _build_pause() -> void:
	pause_ov = _overlay(0.6)
	var v := _center_box(pause_ov)
	var t := _lbl(v, "متوقفة مؤقتاً", 54, ACCENT)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_btn(v, "متابعة", func(): game.set_paused(false), Vector2(320, 60), 24)
	_btn(v, "القائمة الرئيسية", func(): game.quit_to_menu(), Vector2(320, 56), 22)
	pause_ov.visible = false


func _build_end() -> void:
	end_ov = _overlay(0.65)
	var v := _center_box(end_ov)
	end_title = _lbl(v, "", 64)
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_stats = _lbl(v, "", 22)
	end_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_btn(v, "العب مرة أخرى", func(): game.start_game(game.diff), Vector2(320, 60), 24)
	_btn(v, "القائمة الرئيسية", func(): game.quit_to_menu(), Vector2(320, 56), 22)
	end_ov.visible = false


## شاشة البداية: الشعار يكبر ويتوهج ثم يظهر الاسم، وتختفي بعد ثوانٍ أو باللمس
func _build_splash() -> void:
	var sp := ColorRect.new()
	sp.color = Color(0.05, 0.04, 0.03)
	sp.set_anchors_preset(Control.PRESET_FULL_RECT)
	sp.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(sp)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	sp.add_child(v)
	var lg := TextureRect.new()
	lg.texture = load("res://art/logo.png")
	lg.custom_minimum_size = Vector2(300, 300)
	lg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lg.pivot_offset = Vector2(150, 150)
	v.add_child(lg)
	var t := _lbl(v, "قادة النيل", 76, ACCENT)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.0))
	t.add_theme_constant_override("outline_size", 12)
	var s := _lbl(v, "حرب الصحراء الاستراتيجية", 22, Color(0.85, 0.8, 0.7))
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lg.modulate.a = 0.0
	lg.scale = Vector2(0.6, 0.6)
	t.modulate.a = 0.0
	s.modulate.a = 0.0
	var tw := sp.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lg, "modulate:a", 1.0, 0.8)
	tw.tween_property(lg, "scale", Vector2.ONE, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(t, "modulate:a", 1.0, 0.6)
	tw.chain().tween_property(s, "modulate:a", 1.0, 0.5)
	tw.chain().tween_interval(1.4)
	tw.chain().tween_property(sp, "modulate:a", 0.0, 0.6)
	tw.chain().tween_callback(sp.queue_free)
	sp.gui_input.connect(func(e: InputEvent):
		if e is InputEventScreenTouch or e is InputEventMouseButton:
			if is_instance_valid(sp) and sp.modulate.a > 0.99:
				tw.kill()
				sp.queue_free())
	Sfx.play("ready", -2.0, 0.0)


# ===================== الحالات =====================

func show_menu() -> void:
	menu.visible = true
	pause_ov.visible = false
	end_ov.visible = false
	top_panel.visible = false
	bottom_panel.visible = false
	tut_panel.visible = false


func on_game_start() -> void:
	menu.visible = false
	pause_ov.visible = false
	end_ov.visible = false
	top_panel.visible = true
	bottom_panel.visible = true
	row_sig = ""
	refresh(true)


func show_pause() -> void:
	pause_ov.visible = true


func hide_pause() -> void:
	pause_ov.visible = false


func show_end(won: bool) -> void:
	end_title.text = "النصر!" if won else "الهزيمة"
	end_title.add_theme_color_override("font_color", Color(0.5, 1, 0.6) if won else Color(1, 0.42, 0.35))
	var m := int(game.t) / 60
	var s := int(game.t) % 60
	end_stats.text = "المدة %02d:%02d\nوحدات العدو المدمرة: %d\nخسائرنا: %d" % [m, s, game.stats["kills"], game.stats["lost"]]
	end_ov.visible = true


func is_over_ui(pos: Vector2) -> bool:
	for c in [top_panel, bottom_panel, menu, pause_ov, end_ov, tut_panel]:
		if c.visible and c.get_global_rect().has_point(pos):
			return true
	return false


func toast(msg: String) -> void:
	toast_lbl.text = msg
	if toast_tw:
		toast_tw.kill()
	toast_lbl.modulate.a = 1.0
	toast_tw = create_tween()
	toast_tw.tween_interval(2.0)
	toast_tw.tween_property(toast_lbl, "modulate:a", 0.0, 0.5)


func refresh(force := false) -> void:
	if game == null or not game.running:
		return
	lbl_gold.text = "النفط  %d" % game.gold[0]
	lbl_pop.text = "الوحدات  %d/%d" % [game.unit_count(0), game.CAP]
	lbl_time.text = "%02d:%02d" % [int(game.t) / 60, int(game.t) % 60]
	btn_speed.text = "السرعة ×%d" % game.speed
	info.text = game.info_text()
	var specs: Array = game.panel_specs()
	var sig := ""
	for s in specs:
		sig += s["a"] + "|" + s["ic"] + ";"
	if sig != row_sig:
		row_sig = sig
		for c in row.get_children():
			c.queue_free()
		btns.clear()
		for s in specs:
			var b := _mk_btn(s)
			row.add_child(b)
			btns[s["a"]] = b
	for s in specs:
		var b: Button = btns.get(s["a"])
		if b:
			b.text = s["t"]
			b.disabled = s["dis"]


func _mk_btn(s: Dictionary) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(98, 112) if s["ic"] != "" else Vector2(84, 112)
	b.add_theme_font_size_override("font_size", 14)
	b.text = s["t"]
	b.disabled = s["dis"]
	if s["ic"] != "":
		b.icon = icon(s["ic"])
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	var a: String = s["a"]
	b.pressed.connect(func(): game.act(a))
	return b


## يصوّر المجسم ثلاثي الأبعاد مرة واحدة ويستخدمه كأيقونة
func icon(key: String) -> Texture2D:
	if icons.has(key):
		return icons[key]
	var vp := SubViewport.new()
	vp.size = Vector2i(112, 112)
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.8, 0.85)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	vp.add_child(we)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -35, 0)
	light.light_energy = 1.4
	vp.add_child(light)
	var holder := Node3D.new()
	vp.add_child(holder)
	var dims: Vector2 = Models.icon_model(key, holder)
	var cam3 := Camera3D.new()
	cam3.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam3.size = maxf(dims.x * 2.4, dims.y * 1.5)
	vp.add_child(cam3)
	var center := Vector3(0, dims.y * 0.45, 0)
	cam3.position = center + Vector3(dims.x * 2.0, dims.x * 1.6 + dims.y * 0.5, dims.x * 2.4)
	cam3.look_at(center, Vector3.UP)
	cam3.current = true
	var tex := vp.get_texture()
	icons[key] = tex
	return tex
