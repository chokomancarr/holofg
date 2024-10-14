class_name CsCutscene extends _CsBase

const _STATE_NAME = "cutscene"

func clone():
	return ObjUtil.clone(self, _clone(new()),
		[ ],
		[]
	)

func _init(p : PlayerState = null, nm  = ""):
	if p:
		anim_name = nm

func step(state : PlayerState):
	_step()

func dict4hash():
	return [ _STATE_NAME,
		
	]
