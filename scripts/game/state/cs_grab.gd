class_name CsGrab extends _CsAttBase

const _STATE_NAME = "grab"
var base_name : String

static func try_next(state : PlayerState, sliceback : int):
	return _check_inputs(state, sliceback, func (st, n):
		for nrm in st.names(true):
			var move = state._info.grabs.get(nrm)
			if move:
				var res = new()
				res.move = move
				res.base_name = nrm
				res.anim_name = move.name
				
				st.processed = true
				return res
	)

func check_next(state : PlayerState):
	var next = null
	if state_t == move.n_frames:
		return CsIdle.new()

func step(state : PlayerState):
	if state_t == 7:
		if not att_processed:
			move = move.whiff
			anim_name = move.name
	super.step(state)
	if att_processed:
		state.boxes = []
