extends Node
## كل أرقام التوازن في مكان واحد. المسافات بالمتر والسرعات بالمتر/ثانية.

const UT := {
	"worker": {"n": "عامل", "hp": 70.0, "spd": 7.2, "cost": 50, "time": 5.0, "size": 0.9, "from": "hq", "sight": 20.0, "range": 0.0, "armor": "inf"},
	"inf": {"n": "جندي", "hp": 100.0, "spd": 6.2, "range": 12.0, "dmg": 10.0, "rof": 0.8, "dtype": "bullet", "cost": 80, "time": 5.0, "size": 0.8, "from": "barracks", "sight": 24.0, "armor": "inf"},
	"rocket": {"n": "صاروخي", "hp": 85.0, "spd": 5.5, "range": 16.0, "dmg": 30.0, "rof": 2.0, "dtype": "rocket", "cost": 130, "time": 6.0, "size": 0.8, "from": "barracks", "sight": 25.0, "armor": "inf"},
	"tank": {"n": "دبابة", "hp": 380.0, "spd": 7.8, "range": 15.0, "dmg": 32.0, "rof": 1.5, "dtype": "shell", "cost": 260, "time": 9.0, "size": 1.7, "from": "factory", "sight": 25.0, "armor": "armor"},
	"art": {"n": "مدفعية", "hp": 170.0, "spd": 4.5, "range": 31.0, "minR": 9.0, "dmg": 55.0, "rof": 3.6, "dtype": "art", "splash": 4.5, "cost": 320, "time": 11.0, "size": 1.6, "from": "factory", "sight": 32.0, "armor": "armor"},
}

const BT := {
	"hq": {"n": "القيادة", "hp": 2200.0, "size": 4.8, "cost": 0, "time": 1.0, "sight": 32.0, "h": 6.6},
	"barracks": {"n": "الثكنة", "hp": 850.0, "size": 3.4, "cost": 200, "time": 12.0, "sight": 24.0, "req": "hq", "h": 3.6},
	"depot": {"n": "المستودع", "hp": 550.0, "size": 2.6, "cost": 150, "time": 9.0, "sight": 22.0, "req": "hq", "h": 3.4},
	"factory": {"n": "المصنع", "hp": 1200.0, "size": 4.2, "cost": 400, "time": 16.0, "sight": 24.0, "req": "barracks", "h": 6.0},
	"tower": {"n": "برج دفاع", "hp": 700.0, "size": 2.0, "cost": 250, "time": 10.0, "sight": 28.0, "req": "barracks", "range": 23.0, "dmg": 24.0, "rof": 1.1, "dtype": "shell", "h": 4.6},
}

const BUILD_MENU := ["barracks", "depot", "factory", "tower"]

const RS := {
	"arm": {"n": "دروع معززة", "cost": 450, "time": 30.0},
	"wep": {"n": "ذخيرة متطورة", "cost": 450, "time": 30.0},
	"har": {"n": "حفر سريع", "cost": 300, "time": 20.0},
}

const MULT := {
	"bullet": {"inf": 1.0, "armor": 0.25, "bld": 0.25},
	"rocket": {"inf": 0.45, "armor": 1.5, "bld": 0.8},
	"shell": {"inf": 0.75, "armor": 1.0, "bld": 1.0},
	"art": {"inf": 1.0, "armor": 0.7, "bld": 1.6},
	"strike": {"inf": 1.0, "armor": 1.0, "bld": 1.0},
}

const DIFF := [
	{"name": "سهل", "inc": 0.75, "wave": 5, "int": 150.0, "first": 260.0, "air": false, "res": false, "bmul": 0.8},
	{"name": "متوسط", "inc": 1.0, "wave": 7, "int": 120.0, "first": 210.0, "air": true, "res": false, "bmul": 1.0},
	{"name": "صعب", "inc": 1.35, "wave": 8, "int": 100.0, "first": 170.0, "air": true, "res": true, "bmul": 1.3},
]

const AI_ORDER := ["barracks", "depot", "tower", "factory", "barracks", "tower", "factory", "depot", "tower", "tower"]

const AIR_CD := 90.0
const REIN_CD := 120.0
