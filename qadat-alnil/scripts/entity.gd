class_name Entity
extends Node3D
## كائن موحد للوحدات ("u") والمباني ("b").

var kind := "u"
var team := 0
var type := ""
var p := Vector2.ZERO
var hp := 1.0
var mhp := 1.0
var r := 1.0
var h := 2.0
var dead := false

# الوحدات
var ang := 0.0
var tang := 0.0
var cd := 0.0
var tgt = null
var mv = null
var amove := false
var forced := false
var attacking := false
var carry := 0
var mine = null
var st := "idle"
var kills := 0
var vet := 0
var mt := 0.0
var scan := 0.0
var stuck := 0.0
var hit := 0.0
var rec := 0.0
var walk := 0.0
var drop := 0.0

# المباني
var prog := 1.0
var q: Array = []
var pt := 0.0
var rally = null
var announced := false

# مراجع المجسم
var body: Node3D
var turret: Node3D
var barrel: Node3D
var barrel_x0 := 0.0
var cargo: Node3D
var chute: Node3D
var spin: Node3D
var smoke: CPUParticles3D
var dmg_fx: Node3D
var legs: Array = []
var ring: MeshInstance3D
var hpbar: Node3D
var hp_fg: MeshInstance3D
var hp_w := 2.0
var vet_node: Node3D
