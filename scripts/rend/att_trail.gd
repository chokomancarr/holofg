class_name AttTrail extends MeshInstance3D

const MAX_VI = 5

@export var generate = false
@onready var par = get_parent() as Skeleton3D

var chain : Array[BoneAttachment3D]

var vi = 0
var verts = PackedVector3Array()
var uvs = []
var indices = PackedInt32Array()

var arrays = []
var arr_mesh : ArrayMesh

func _ready():
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	arr_mesh = ArrayMesh.new()
	self.mesh = arr_mesh

func set_chain(arr):
	for c in chain:
		c.free()
	
	verts.clear()
	uvs = []
	indices.clear()
	vi = 0
	arr_mesh.clear_surfaces()
	
	chain.assign(arr.map(func (a):
		var ba = BoneAttachment3D.new()
		par.add_child(ba)
		ba.bone_name = a
		return ba
	))

func push_pose():
	var cn = chain.size()
	for j in range(cn):
		verts.push_back(chain[j].position)
	
	if vi < MAX_VI:
		for j in range(cn):
			uvs.push_back(Vector2(vi, j / (cn - 1.0)))
	
		if vi > 0:
			arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(uvs.map(func (u):
				return Vector2(1.0 - u.x / vi, 1.0 - u.y)
			))
			var _ii = [ -cn, -cn+1, 0, -cn+1, 1, 0 ]
			for j in range(cn - 1):
				var i0 = vi * cn + j
				for ii in _ii:
					indices.push_back(i0 + ii)
		vi += 1
	else:
		verts = verts.slice(cn)
		arrays[Mesh.ARRAY_VERTEX] = verts
	
	if vi > 1:
		arr_mesh.clear_surfaces()
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
func pop_pose():
	var cn = chain.size()
	verts = verts.slice(cn)
	arrays[Mesh.ARRAY_VERTEX] = verts

	uvs = uvs.slice(0, cn)

	arr_mesh.clear_surfaces()
	
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(uvs.map(func (u):
		return Vector2(1.0 - u.x / vi, 1.0 - u.y)
	))
	indices = indices.slice(0, -6 * (cn - 1))
	arrays[Mesh.ARRAY_INDEX] = indices
	
	vi -= 1
	
	if vi > 1:
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

var _did_freeze = false

func _physics_process(_dt):
	var f = GameMaster.game_state.state == GameState.MATCH_STATE.ATT_FREEZE
	var g = GameMaster.game_state.state == GameState.MATCH_STATE.GAME
	
	if g or (f and not _did_freeze):
		_did_freeze = f
		
		if not arrays.is_empty():
			if generate:
				push_pose()
			elif vi > 0:
				verts.clear()
				uvs = []
				indices.clear()
				vi = 0
				arr_mesh.clear_surfaces()
				
				#pop_pose()
