class_name IN

class InputHistory:
	var history : Array[InputState]
	var dir_history : Array[InputState]

	func _init():
		history = [ InputState.new() ] as Array[InputState]
		dir_history = [ InputState.new() ] as Array[InputState]
	
	func push(v : InputState):
		if v.val == history[0].val:
			history[0].nf += 1
		else:
			history.push_front(v)
			if history.size() > 30:
				history.pop_back()
		
		var d = v.dir_flipped()
		if d == dir_history[0].val:
			dir_history[0].nf += 1
		else:
			dir_history.push_front(InputState.new(d))
			if dir_history.size() > 30:
				dir_history.pop_back()
	
	func clone():
		var res = new()
		res.history = history.slice(0, 100, 1, true) as Array[InputState]
		res.dir_history = dir_history.slice(0, 100, 1, true) as Array[int]
		return res

	func last_bts():
		return history[0].bts()
	func last_dir():
		return history[0].dir()

class InputState:
	var val : int = 5
	var nf : int = 1
	var processed : bool = false
	
	func _init(val = 5, nf = 1):
		self.val = val
		self.nf = nf
	
	func clone():
		var res = new()
		res.val = val
		res.nf = nf
		res.processed = processed
		return res
	
	#static func from_player(state: InputMan.ActionStatus):
		#var res = new()
		#res.val = 5 + state.axis_x() + 3 * state.axis_y()
		#
		#var i = 8
		#for nm in ["l", "m", "h", "s"]:
			#if state.get("button_" + nm) > 0:
				#res.val += 1 << i
				#res.bt_just = true
			#
			#i += 4
		#
		#return res
	
	func dir(): return val & 15
	func l(): return val & (1 << 8)
	func m(): return val & (1 << 12)
	func h(): return val & (1 << 16)
	func s(): return val & (1 << 20)
	func bt(e : BT): return val & e
	func bts(): return val & ((1 << 22) - 16)
	
	func dir_flipped():
		var res = dir()
		if (val & DIR_FLIP_BIT) == 0:
			return res
		var v = (res - 1) % 3
		if v == 0:
			res += 2
		elif v == 2:
			res -= 2
		return res
	
	func name(neutral):
		var res = ("2" if dir() < 4 else "5") if neutral else str(dir())
		if l(): res += "l"
		if m(): res += "m"
		if h(): res += "h"
		if s(): res += "s"
		
		return res
	
	func serialize() -> Dictionary:
		return {
			"v": val,
			"nf": nf
		}
	static func deserialize(d : Dictionary):
		var res = new()
		if d.has("v"):
			res.val = d.v
			res.nf = d.nf
		return res

const JUST_PRESSED = 1

enum BT {
	l = 1 << 8,
	m = 1 << 12,
	h = 1 << 16,
	s = 1 << 20,
}

const DIR_ANY_2 = 12
const DIR_ANY_4 = 14
const DIR_ANY_6 = 16
const DIR_ANY_8 = 18
const DIR_OPT_BIT = 1024
const DIR_FLIP_BIT = 1 << 25

const _DIR_ALLOWED = {
	12: [1,2,3],
	14: [1,4,7],
	16: [3,6,9],
	18: [7,8,9]
}

class InputCommand:
	var command : Array[int]
	var command_str : String
	var bt : BT
	
	var t_dir2bt = 20 #max frames between direction input and button
	#var t_dir2dir = 6 #max frames between directions
	var t_dirs = 20 #max frames for all directions
	
	func _check_one(cmd, dir):
		if cmd < 10:
			return dir == cmd
		else:
			return _DIR_ALLOWED[cmd].has(dir)

	func check(history: Array[IN.InputState], current_bt : int, current_str : String = ""):
		if current_bt != bt: return false
		var ff = 0
		var ci = 0
		var cn = command.size()
		if cn == 0:
			return command_str == current_str
		var cmd = command[0]
		var is_opt = false
		for h in history:
			var dir = h.dir()
			if ff == 0 and dir == 5:
				if h.nf > t_dir2bt:
					break
				else:
					ff += h.nf
					if ff > t_dirs:
						break
					continue
			
			if not _check_one(cmd, dir):
				var ok2 = false
				while is_opt:
					ci += 1
					cmd = command[ci]
					is_opt = cmd > 1000
					cmd &= ~1024
					if _check_one(cmd, dir):
						ok2 = true
						break
				if not ok2:
					break
			
			ci += 1
			if ci == cn:
				return true
			else:
				cmd = command[ci]
				is_opt = cmd > 1000
				cmd &= ~1024
			
			ff += h.nf
			if ff > t_dirs:
				break
		return false

	static func from_string(s : String):
		s = s.rsplit(".")[-1]
		
		var res = new()
		
		var i = 0
		for c : int in s.to_ascii_buffer():
			if c > 60:
				break
			i += 1
		
		var cmd = s.substr(0, i)
		var bt = s.substr(i)
		
		match cmd:
			"236":
				res.command = [
					6, 3, 2
				] as Array[int]
			"214":
				res.command = [
					4, 1, 2
				] as Array[int]
			"623":
				res.command = [
					DIR_ANY_6, DIR_ANY_2, 2 | DIR_OPT_BIT, 5 | DIR_OPT_BIT, DIR_ANY_6
				] as Array[int]
			"63214":
				res.command = [
					4, 1 | DIR_OPT_BIT, 2, 3 | DIR_OPT_BIT, 6
				] as Array[int]
			"66":
				res.command = [
					6, 5, 6
				] as Array[int]
			"44":
				res.command = [
					4, 5, 4
				] as Array[int]
			_:
				res.command_str = s
		
		for c in bt:
			res.bt += BT.get(c)
		
		return res