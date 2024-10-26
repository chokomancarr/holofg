import bpy

def export_root_pos(f0, f1, zx = False, zy = False):
    res = []
    bn = bpy.context.active_pose_bone
    lsx = 0
    lsy = 0
    for i in range(f0, f1 + 1):
        bpy.context.scene.frame_set(i)
        sx = round(bn.head.x * 500)
        sy = round(bn.head.z * 500)
        res.append('[{},{}]'.format(sx - lsx, sy - lsy))
        lsx = sx
        lsy = sy
    
    if not zx:
        lsx = 0
    if not zy:
        lsy = 0
    
    res.append('[{},{}]'.format(-lsx, -lsy))
    
    print(', '.join(res))


export_root_pos(0, 49, False, True)