extends Node
## محرك الصوت: مؤثرات مولّدة بالكود بطبقات متعددة (بدون ملفات خارجية وبدون حقوق)،
## موسيقى أصلية على مقام الحجاز (عود + دربكة + درون)، ورياح صحراوية محيطة.
## الحافلات: SFX (مع صدى خفيف) و Music، و Master عليه محدّد لمنع التشويه.
## أي صوت يمكن استبداله لاحقاً بملف res://sounds/<الاسم>.ogg وسيُحمّل تلقائياً.

const RATE := 22050

var streams := {}  # الاسم -> Array من AudioStreamWAV (نسخ متعددة للتنويع)
var players: Array = []
var last := {}
var muted := false
var music_vol := -13.0

var _music: AudioStreamPlayer
var _amb: AudioStreamPlayer
var _thread: Thread
var _music_want := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_setup_buses()
	_add("click", [_click()])
	_add("select", [_radio(0.16, 1250.0, 1600.0), _radio(0.16, 1100.0, 1450.0)])
	_add("ack", [_radio(0.2, 900.0, 1350.0), _radio(0.2, 1000.0, 760.0), _radio(0.18, 820.0, 1200.0)])
	_add("error", [_buzz()])
	_add("done", [_bells([293.7, 370.0, 440.0, 587.3], 0.11)])
	_add("ready", [_horn([440.0, 587.3], 0.16)])
	_add("bullet", [_gun(0), _gun(1), _gun(2)])
	_add("shell", [_cannon(0.7, 95.0), _cannon(0.75, 85.0)])
	_add("art", [_cannon(1.1, 60.0, true), _cannon(1.2, 52.0, true)])
	_add("boom", [_explosion(1.7, 0), _explosion(1.9, 1), _explosion(1.6, 2)])
	_add("rocket", [_rocket(0.75), _rocket(0.85)])
	_add("strike", [_jet(2.6)])
	_add("alert", [_siren(1.6)])
	_add("victory", [_horn([293.7, 370.0, 440.0, 587.3], 0.22, true)])
	_add("defeat", [_horn([293.7, 277.2, 233.1, 220.0], 0.3, true)])
	_load_overrides()
	for i in 14:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.volume_db = music_vol
	add_child(_music)
	_amb = AudioStreamPlayer.new()
	_amb.bus = "Music"
	_amb.volume_db = -20.0
	_amb.stream = _wind(8.0)
	add_child(_amb)
	# توليد الموسيقى في خيط منفصل حتى لا يتجمد الإقلاع
	_thread = Thread.new()
	_thread.start(_make_music)


func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()


func play(n: String, vol := 0.0, gap := 0.06) -> void:
	if muted or not streams.has(n):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(last.get(n, -10.0)) < gap:
		return
	last[n] = now
	var list: Array = streams[n]
	var s: AudioStream = list[_rng.randi() % list.size()]
	for p in players:
		if not p.playing:
			p.stream = s
			p.volume_db = vol
			p.pitch_scale = _rng.randf_range(0.94, 1.06)
			p.play()
			return


## تشغيل الموسيقى والرياح (on = true داخل القائمة واللعب)
func music(on: bool, battle := false) -> void:
	_music_want = on and not muted
	if _music_want:
		if _music.stream and not _music.playing:
			_music.play()
		if battle and not _amb.playing:
			_amb.play()
		elif not battle:
			_amb.stop()
		var tw := create_tween()
		tw.tween_property(_music, "volume_db", music_vol - (4.0 if battle else 0.0), 1.5)
	else:
		_music.stop()
		_amb.stop()


func set_muted(v: bool) -> void:
	muted = v
	AudioServer.set_bus_mute(0, v)


# ===================== الحافلات =====================

func _setup_buses() -> void:
	var lim := AudioEffectHardLimiter.new()
	lim.ceiling_db = -0.5
	AudioServer.add_bus_effect(0, lim)
	for bn in ["SFX", "Music"]:
		if AudioServer.get_bus_index(bn) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bn)
			AudioServer.set_bus_send(i, "Master")
	var sfx := AudioServer.get_bus_index("SFX")
	var rv := AudioEffectReverb.new()
	rv.room_size = 0.55
	rv.damping = 0.6
	rv.spread = 0.8
	rv.wet = 0.14
	rv.dry = 1.0
	rv.predelay_msec = 30.0
	AudioServer.add_bus_effect(sfx, rv)
	var cmp := AudioEffectCompressor.new()
	cmp.threshold = -14.0
	cmp.ratio = 3.0
	cmp.attack_us = 2000.0
	cmp.release_ms = 180.0
	AudioServer.add_bus_effect(sfx, cmp)


func _add(n: String, list: Array) -> void:
	streams[n] = list


func _load_overrides() -> void:
	for n in streams.keys():
		var path := "res://sounds/%s.ogg" % n
		if ResourceLoader.exists(path):
			streams[n] = [load(path)]


# ===================== أدوات DSP =====================

func _buf(dur: float) -> PackedFloat32Array:
	var s := PackedFloat32Array()
	s.resize(int(dur * RATE))
	return s


func _wav(s: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	# تطبيع خفيف إلى -1 dBFS
	var peak := 0.0001
	for v in s:
		peak = maxf(peak, absf(v))
	var g := 0.89 / peak if peak > 0.89 else 1.0
	var b := PackedByteArray()
	b.resize(s.size() * 2)
	for i in s.size():
		b.encode_s16(i * 2, int(clampf(s[i] * g, -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = b
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = s.size()
	return w


## تشبّع ناعم يعطي "دسامة" للأصوات القوية
func _sat(x: float, drive: float) -> float:
	return tanh(x * drive) / tanh(drive)


## صدى إجرائي قصير يُخبز داخل الصوت (خطوط تأخير متعددة)
func _bake_echo(s: PackedFloat32Array, taps: Array, fb: float) -> void:
	for t in taps:
		var d := int(float(t) * RATE)
		for i in range(d, s.size()):
			s[i] += s[i - d] * fb


func _fade_out(s: PackedFloat32Array, sec: float) -> void:
	var n := mini(int(sec * RATE), s.size())
	for i in n:
		s[s.size() - 1 - i] *= float(i) / n


# ===================== واجهة المستخدم =====================

func _click() -> PackedFloat32Array:
	var s := _buf(0.06)
	var lp := 0.0
	for i in s.size():
		var t := float(i) / RATE
		lp += (_rng.randf_range(-1, 1) - lp) * 0.5
		s[i] = (sin(TAU * 1850.0 * t) * 0.5 + sin(TAU * 3100.0 * t) * 0.2) * exp(-t * 90.0) + lp * 0.35 * exp(-t * 300.0)
	return _wav(s)


## صوت لاسلكي عسكري: نقرة + نغمتان مع ضجيج ناعم ومرشح نطاق
func _radio(dur: float, f1: float, f2: float) -> AudioStreamWAV:
	var s := _buf(dur)
	var ph := 0.0
	var lp := 0.0
	for i in s.size():
		var t := float(i) / RATE
		var k := t / dur
		var f := f1 if k < 0.45 else f2
		ph += TAU * f / RATE
		var tone := signf(sin(ph)) * 0.25 + sin(ph) * 0.5
		var nz := _rng.randf_range(-1, 1) * 0.18
		var x := tone * (0.6 if k > 0.12 else 0.0) + nz
		if k < 0.08:
			x = _rng.randf_range(-1, 1) * 0.8  # فتح القناة
		lp += (x - lp) * 0.35
		var env := minf(1.0, t * 300.0) * minf(1.0, (dur - t) * 60.0)
		s[i] = _sat(lp * env, 2.0) * 0.6
	return _wav(s)


func _buzz() -> AudioStreamWAV:
	var s := _buf(0.26)
	var ph := 0.0
	for i in s.size():
		var t := float(i) / RATE
		var f := 196.0 if t < 0.12 else 147.0
		ph += TAU * f / RATE
		var env := minf(1.0, t * 200.0) * (1.0 if fmod(t, 0.13) < 0.1 else 0.0) * exp(-t * 4.0)
		s[i] = _sat(sin(ph) + 0.5 * sin(ph * 3.0), 1.8) * env * 0.55
	return _wav(s)


## أجراس معدنية (جزئيات غير توافقية)
func _bells(fs: Array, step: float) -> AudioStreamWAV:
	var dur := step * fs.size() + 0.9
	var s := _buf(dur)
	var parts := [[1.0, 1.0, 3.0], [2.0, 0.5, 5.0], [2.76, 0.35, 7.0], [5.4, 0.18, 11.0]]
	for k in fs.size():
		var st := int(k * step * RATE)
		for i in range(st, s.size()):
			var t := float(i - st) / RATE
			var v := 0.0
			for p in parts:
				v += sin(TAU * fs[k] * p[0] * t) * p[1] * exp(-t * p[2])
			s[i] += v * minf(1.0, t * 800.0) * 0.28
	_bake_echo(s, [0.13], 0.25)
	return _wav(s)


## نفير نحاسي (مسنن مفلتر + اهتزاز)
func _horn(fs: Array, step: float, long := false) -> AudioStreamWAV:
	var hold := step * (2.5 if long else 1.2)
	var dur := step * (fs.size() - 1) + hold + 0.6
	var s := _buf(dur)
	for k in fs.size():
		var st := int(k * step * RATE)
		var ln := hold if k == fs.size() - 1 else step * 1.05
		var ph := 0.0
		var lp := 0.0
		var n := int((ln + 0.3) * RATE)
		for j in n:
			var i := st + j
			if i >= s.size():
				break
			var t := float(j) / RATE
			var vib := 1.0 + 0.006 * sin(TAU * 5.5 * t) * minf(1.0, t * 3.0)
			ph += fs[k] * vib / RATE
			var saw := 2.0 * (ph - floor(ph)) - 1.0
			var bright := 0.08 + 0.25 * minf(1.0, t * 12.0)
			lp += (saw - lp) * bright
			var env := minf(1.0, t * 25.0) * (1.0 if t < ln else exp(-(t - ln) * 14.0))
			s[i] += lp * env * 0.42
	_bake_echo(s, [0.17, 0.29], 0.22)
	return _wav(s)


# ===================== الأسلحة =====================

## طلقة رشاش: شرخ عالٍ + جسم ضجيج + دفعة منخفضة + ذيل قصير
func _gun(v: int) -> AudioStreamWAV:
	var s := _buf(0.32)
	var lp := 0.0
	var lp2 := 0.0
	var ph := 0.0
	var body := 140.0 + v * 25.0
	for i in s.size():
		var t := float(i) / RATE
		var w := _rng.randf_range(-1, 1)
		lp += (w - lp) * 0.45
		lp2 += (w - lp2) * 0.06
		ph += TAU * body * (1.0 - t * 1.5) / RATE
		var crack := w * exp(-t * 400.0) * 0.9
		var mid := lp * exp(-t * 55.0) * 0.8
		var thump := sin(ph) * exp(-t * 38.0) * 0.7
		var tail := lp2 * exp(-t * 9.0) * 0.5
		s[i] = _sat(crack + mid + thump + tail, 2.2)
	return _wav(s)


## مدفع دبابة / مدفعية: ضغط هائل + هبوط نغمي + هدير
func _cannon(dur: float, f: float, far := false) -> AudioStreamWAV:
	var s := _buf(dur)
	var lp := 0.0
	var lp2 := 0.0
	var ph := 0.0
	for i in s.size():
		var t := float(i) / RATE
		var w := _rng.randf_range(-1, 1)
		lp += (w - lp) * (0.12 if far else 0.3)
		lp2 += (w - lp2) * 0.025
		var fr := f * (1.0 + 2.5 * exp(-t * 18.0))
		ph += TAU * fr / RATE
		var blast := lp * exp(-t * (30.0 if far else 22.0)) * 1.2
		var sub := sin(ph) * exp(-t * 6.0) * 1.0
		var rumble := lp2 * exp(-t * 3.2 / dur) * 1.1
		var att := minf(1.0, t * (600.0 if far else 3000.0))
		s[i] = _sat((blast + sub + rumble) * att, 2.6)
	if far:
		_bake_echo(s, [0.21, 0.37], 0.3)
	_fade_out(s, 0.15)
	return _wav(s)


## انفجار كبير: باس عميق + ضوضاء بنية + طقطقة شظايا + صدى الأفق
func _explosion(dur: float, v: int) -> AudioStreamWAV:
	var s := _buf(dur)
	var brown := 0.0
	var lp := 0.0
	var ph := 0.0
	var crk := 0.0
	for i in s.size():
		var t := float(i) / RATE
		var w := _rng.randf_range(-1, 1)
		brown = clampf(brown + w * 0.08, -1.0, 1.0) * 0.995
		lp += (w - lp) * 0.18
		ph += TAU * (38.0 + 50.0 * exp(-t * 7.0) + v * 4.0) / RATE
		var sub := sin(ph) * exp(-t * 3.0) * 1.1
		var body := brown * exp(-t * 2.4 / dur * 2.0) * 1.6
		var hit := lp * exp(-t * 16.0) * 1.3
		if _rng.randf() < 0.004 * exp(-t * 2.0) and t > 0.05:
			crk = _rng.randf_range(0.4, 0.9)
		crk *= 0.93
		var crackle := crk * _rng.randf_range(-1, 1)
		var att := minf(1.0, t * 1500.0)
		s[i] = _sat((sub + body + hit + crackle * 0.6) * att, 3.0)
	_bake_echo(s, [0.33], 0.18)
	_fade_out(s, 0.3)
	return _wav(s)


## صاروخ: اشتعال + هسيس متحرك
func _rocket(dur: float) -> AudioStreamWAV:
	var s := _buf(dur)
	var lp := 0.0
	var bp := 0.0
	for i in s.size():
		var t := float(i) / RATE
		var k := t / dur
		var w := _rng.randf_range(-1, 1)
		var c := 0.08 + 0.35 * sin(PI * k)
		lp += (w - lp) * c
		bp += (lp - bp) * 0.5
		var ign := w * exp(-t * 70.0) * 0.9
		var env := minf(1.0, t * 40.0) * pow(1.0 - k, 1.3)
		s[i] = _sat((lp - bp * 0.5) * env * 2.2 + ign, 1.8)
	return _wav(s)


## ضربة جوية: طائرة نفاثة تعبر (دوبلر + هدير)
func _jet(dur: float) -> AudioStreamWAV:
	var s := _buf(dur)
	var lp := 0.0
	var lp2 := 0.0
	var ph := 0.0
	for i in s.size():
		var t := float(i) / RATE
		var k := t / dur
		var w := _rng.randf_range(-1, 1)
		var near := exp(-pow((k - 0.45) * 4.0, 2.0))
		lp += (w - lp) * (0.04 + 0.4 * near)
		lp2 += (w - lp2) * 0.02
		var dop := 1.0 + 0.35 * (0.45 - k)
		ph += TAU * 520.0 * dop / RATE
		var whine := sin(ph) * near * 0.18
		var env := minf(1.0, t * 3.0) * minf(1.0, (dur - t) * 2.0)
		s[i] = _sat((lp * 1.8 * (0.25 + near) + lp2 * 1.2 + whine) * env, 2.0)
	return _wav(s)


func _siren(dur: float) -> AudioStreamWAV:
	var s := _buf(dur)
	var ph := 0.0
	for i in s.size():
		var t := float(i) / RATE
		var f := 560.0 + 220.0 * (0.5 + 0.5 * sin(TAU * 1.25 * t - PI / 2.0))
		ph += TAU * f / RATE
		var env := minf(1.0, t * 20.0) * minf(1.0, (dur - t) * 6.0)
		s[i] = (sin(ph) * 0.7 + 0.25 * sin(ph * 2.0) + 0.1 * sin(ph * 3.0)) * env * 0.55
	_bake_echo(s, [0.24], 0.3)
	return _wav(s)


## رياح صحراوية قابلة للتكرار بلا فواصل
func _wind(dur: float) -> AudioStreamWAV:
	var s := _buf(dur)
	var lp := 0.0
	var lp2 := 0.0
	for i in s.size():
		var t := float(i) / RATE
		var w := _rng.randf_range(-1, 1)
		var gust := 0.55 + 0.3 * sin(TAU * t / dur) + 0.15 * sin(TAU * 3.0 * t / dur + 1.0)
		lp += (w - lp) * (0.02 + 0.03 * gust)
		lp2 += (lp - lp2) * 0.3
		s[i] = lp2 * gust * 4.0
	# دمج البداية بالنهاية لتكرار سلس
	var xf := int(0.5 * RATE)
	for i in xf:
		var a := float(i) / xf
		s[i] = s[i] * a + s[s.size() - xf + i] * (1.0 - a)
	s.resize(s.size() - xf)
	return _wav(s, true)


# ===================== الموسيقى (مقام الحجاز) =====================

func _make_music() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 7311
	var bpm := 92.0
	var beat := 60.0 / bpm
	var bars := 8
	var n := int(bars * 4 * beat * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	# مقام الحجاز على ري: D Eb F# G A Bb C D
	var D := 146.83
	var scale := [0, 1, 4, 5, 7, 8, 10, 12, 13, 16]
	var hz := func(deg: int) -> float: return D * pow(2.0, float(scale[deg]) / 12.0)
	# درون (ري + لا) متنفّس
	for i in n:
		var t := float(i) / RATE
		var sw := 0.5 + 0.5 * sin(TAU * t / (bars * 4 * beat) * 2.0)
		s[i] = (sin(TAU * D / 2.0 * t) * 0.16 + sin(TAU * D * 0.75 * t) * 0.07 + sin(TAU * D * t + sin(TAU * 0.3 * t)) * 0.05) * (0.6 + 0.4 * sw)
	# دربكة: دُم - تك - تك - دُم - تك (مقسوم)
	var pat := ["D", "", "T", "T", "D", "", "T", "k"]
	for bar in bars:
		for st in 8:
			var hit: String = pat[st]
			if hit == "":
				continue
			var at := int(((bar * 4) + st * 0.5) * beat * RATE)
			_drum(s, at, hit, r)
		if bar % 2 == 1:
			_drum(s, int(((bar * 4) + 3.75) * beat * RATE), "k", r)
	# لحن العود (Karplus-Strong) — جمل أصلية
	var mel := [
		[0, 1.0], [2, 0.5], [3, 0.5], [4, 1.0], [3, 0.5], [2, 0.5],
		[1, 1.0], [2, 1.0], [0, 2.0],
		[4, 0.5], [5, 0.5], [6, 1.0], [5, 0.5], [4, 0.5], [3, 1.0],
		[2, 0.5], [3, 0.5], [2, 0.5], [1, 0.5], [0, 2.0],
		[7, 1.0], [6, 0.5], [5, 0.5], [4, 1.0], [5, 0.5], [4, 0.5],
		[3, 1.0], [2, 0.5], [1, 0.5], [2, 2.0],
		[4, 0.5], [3, 0.5], [2, 0.5], [3, 0.5], [2, 0.5], [1, 0.5], [2, 0.5], [1, 0.5],
		[0, 3.0], [-1, 1.0]]
	var pos := 0.0
	for nt in mel:
		var deg: int = nt[0]
		if deg >= 0:
			var f: float = hz.call(deg)
			var at := int(pos * beat * RATE)
			_pluck(s, at, f, beat * float(nt[1]) + 0.6, 0.42, r)
			# ريشة مزدوجة (تريمولو) على النغمات الطويلة
			if float(nt[1]) >= 2.0:
				for q in range(1, int(nt[1] * 4.0)):
					_pluck(s, at + int(q * beat * 0.25 * RATE), f, 0.3, 0.12, r)
		pos += float(nt[1])
	# باص على الدُم
	for bar in bars:
		var root: float = D / 2.0 if bar % 4 != 2 else hz.call(3) / 2.0
		_pluck(s, int(bar * 4 * beat * RATE), root, beat * 2.0, 0.35, r)
		_pluck(s, int((bar * 4 + 2) * beat * RATE), root, beat * 2.0, 0.25, r)
	_bake_echo(s, [beat * 0.75], 0.18)
	# كي لا يحدث نقر عند التكرار
	var xf := int(0.03 * RATE)
	for i in xf:
		var a := float(i) / xf
		s[i] *= a
		s[n - 1 - i] *= a
	var w := _wav(s, true)
	call_deferred("_music_ready", w)


func _music_ready(w: AudioStreamWAV) -> void:
	var path := "res://sounds/music.ogg"
	if ResourceLoader.exists(path):
		var o: AudioStream = load(path)
		if o is AudioStreamOggVorbis:
			o.loop = true
		_music.stream = o
	else:
		_music.stream = w
	if _music_want:
		_music.play()


func _pluck(s: PackedFloat32Array, at: int, f: float, dur: float, vol: float, r: RandomNumberGenerator) -> void:
	var period := maxi(2, int(RATE / f))
	var buf := PackedFloat32Array()
	buf.resize(period)
	for i in period:
		buf[i] = r.randf_range(-1, 1)
	var n := int(dur * RATE)
	var idx := 0
	var prev := 0.0
	var body := 0.0
	for j in n:
		var i := at + j
		if i >= s.size():
			break
		var cur := buf[idx]
		var nxt := (cur + prev) * 0.5 * 0.996
		prev = cur
		buf[idx] = nxt
		idx = (idx + 1) % period
		body += (cur - body) * 0.45  # رنين الصندوق الخشبي
		var env := minf(1.0, float(j) / (RATE * 0.002)) * minf(1.0, (n - j) / (RATE * 0.05))
		s[i] += body * vol * env


func _drum(s: PackedFloat32Array, at: int, hit: String, r: RandomNumberGenerator) -> void:
	var dur := 0.45 if hit == "D" else 0.12
	var n := int(dur * RATE)
	var ph := 0.0
	var lp := 0.0
	for j in n:
		var i := at + j
		if i >= s.size():
			break
		var t := float(j) / RATE
		var v := 0.0
		if hit == "D":
			ph += TAU * (90.0 + 60.0 * exp(-t * 30.0)) / RATE
			v = sin(ph) * exp(-t * 9.0) * 0.75
		else:
			var w := r.randf_range(-1, 1)
			lp += (w - lp) * 0.6
			ph += TAU * 420.0 / RATE
			var amp := 0.38 if hit == "T" else 0.2
			v = (w - lp) * exp(-t * 60.0) * amp + sin(ph) * exp(-t * 80.0) * amp * 0.6
		s[i] += v
