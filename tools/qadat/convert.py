# Blender: يحوّل أي مجسم إلى glb ويرسم صورة معاينة. الاستخدام: blender -b -P convert.py -- in out.glb out.png
import bpy, sys, math, os
a = sys.argv[sys.argv.index("--") + 1:]
src, glb, png = a
bpy.ops.wm.read_factory_settings(use_empty=True)
ext = os.path.splitext(src)[1].lower()
if ext == ".blend":
    bpy.ops.wm.open_mainfile(filepath=src)
    for o in list(bpy.data.objects):
        if o.type in ("CAMERA", "LIGHT"):
            bpy.data.objects.remove(o)
elif ext == ".fbx": bpy.ops.import_scene.fbx(filepath=src)
elif ext == ".obj": bpy.ops.wm.obj_import(filepath=src)
elif ext == ".dae": bpy.ops.wm.collada_import(filepath=src)
elif ext in (".glb", ".gltf"): bpy.ops.import_scene.gltf(filepath=src)
elif ext == ".3ds": bpy.ops.import_scene.max3ds(filepath=src)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
if not meshes: sys.exit(0)
tris = sum(len(o.data.polygons) for o in meshes)
bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", export_apply=True)
# معاينة
from mathutils import Vector
pts = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
ctr = (mn + mx) / 2; r = (mx - mn).length / 2 or 1
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); bpy.context.scene.collection.objects.link(cam)
cam.location = ctr + Vector((1.6, -1.6, 1.2)) * r * 1.6
d = ctr - cam.location; cam.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
bpy.context.scene.camera = cam
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN")); sun.rotation_euler = (0.8, 0.2, 0.6)
bpy.context.scene.collection.objects.link(sun)
sc = bpy.context.scene
if sc.world is None: sc.world = bpy.data.worlds.new("w")
sc.world.color = (0.55, 0.55, 0.6)
sc.render.engine = "CYCLES"; sc.cycles.samples = 12; sc.cycles.device = "CPU"
sc.render.resolution_x = 320; sc.render.resolution_y = 240
sc.render.filepath = png
bpy.ops.render.render(write_still=True)
open(glb + ".txt", "w").write("tris=%d size=%.2f,%.2f,%.2f\n" % (tris, *(mx - mn)))
