class_name IN

const V = "v"
const NF = "nf"
const NP = "np"

class InputHistory:
	var his : Array[InputState]
	var dirs : Array
	
	func clone():
		var res = new()
		res.his.assign(his.duplicate().map(func (st): return st.clone()))
		res.dirs = dirs.duplicate(true)
		return res
	
	func _init():
		his.push_front(InputState.new())
		dirs.push_front({ V: 5, NF: 1 })
	
	func push(v : InputState):
		#sx = v.name(false)
		#s5 = v.name(true)
		var b = v.bts()
		var d = v.dir_flipped()
		
		if v.val == his[0].val:
			his[0].nf += 1
		else:
			var st = v.clone()
			st.processed = false
			st.val_new = (b & (~his[0].bts())) + d
			st.new_bt = st.val_new > 0
			his.push_front(st)
			#bts.push_front({ V: b, NF: 1, "used": false, NP: (b & (~bts[0].v)) > 0, "_id": _id })
			if his.size() > 30:
				his.pop_back()
		
		if d == dirs[0].v:
			dirs[0].nf += 1
		else:
			dirs.push_front({ V: d, NF: 1 })
			if dirs.size() > 30:
				dirs.pop_back()
	
	func last_bts():
		return his[0].bts()
	func last_dir():
		return dirs[0].v
	
	func dict4hash():
		return {
			"hs": his.map(func (h : InputState): return h.hashed()),
			"dr": dirs.map(func (h): return [ h.v, h.nf ].hash())
		}

class InputState:
	var val : int = 5
	var val_new : int = 0
	var nf : int = 1
	var new_bt : bool = false
	var processed : bool = false
	
	func _init(val = 5, nf = 1):
		self.val = val
		self.nf = nf
	
	func clone():
		var res = new()
		res.val = val
		res.val_new = val_new
		res.nf = nf
		res.new_bt = new_bt
		res.processed = processed
		return res
	
	func _v(n): return val_new if n else val
	
	func dir(): return val & 15
	func l(n = false): return _v(n) & (1 << 8)
	func m(n = false): return _v(n) & (1 << 12)
	func h(n = false): return _v(n) & (1 << 16)
	func s(n = false): return _v(n) & (1 << 20)
	func g(n = false): return _v(n) & (1 << 24)
	func p(n = false): return _v(n) & (1 << 28)
	func bt(e : BT, n = false): return _v(n) & e
	func bts(n = false): return _v(n) & ((1 << 30) - 16)
	
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
	
	func name(neutral, n = false):
		var res = ("2" if dir() < 4 else "5") if neutral else str(dir_flipped())
		if l(n): res += "l"
		if m(n): res += "m"
		if h(n): res += "h"
		if s(n): res += "s"
		
		return res
	
	func names(n = false):
		var btt = []
		if p(n): btt.push_back("p")
		if g(n): btt.push_back("g")
		if s(n): btt.push_back("s")
		if h(n): btt.push_back("h")
		if m(n): btt.push_back("m")
		if l(n): btt.push_back("l")
		
		var d = dir_flipped()
		
		var res = []
		for bt in btt:
			if d != 5:
				if [ 1, 3, 7, 9 ].has(d):
					res.push_back(str(d) + bt)
					d = d + 1 if (d == 1 or d == 7) else d - 1
				res.push_back(str(d) + bt)
			res.push_back("5" + bt)
		
		return res
	
	func serialize4input() -> Dictionary:
		return { "v" : val }
	static func deserialize4input(d : Dictionary):
		if d.is_empty():
			return new()
		else:
			return new(d["v"])
	
	func hashed():
		return [
			val, val_new, nf, new_bt, processed
		].hash()

const JUST_PRESSED = 1

enum BT {
	l = 1 << 8,
	m = 1 << 12,
	h = 1 << 16,
	s = 1 << 20,
	g = 1 << 24,
	p = 1 << 28,
	ANY = 1
}

const DIR_ANY_2 = 12
const DIR_ANY_4 = 14
const DIR_ANY_6 = 16
const DIR_ANY_8 = 18
const DIR_OPT_BIT = 1024
const DIR_FLIP_BIT = 1 << 31

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

	func check(history : InputHistory):
		if bt != BT.ANY and history.his[0].bts() != bt: return false
		var ff = 0
		var ci = 0
		var cn = command.size()
		if cn == 0:
			return command_str == history.his[0].name(false) or command_str == history.his[0].name(true)
		var cmd = command[0]
		var is_opt = false
		for h in history.dirs:
			var dir = h.v
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
			var b = BT.get(c)
			if not b:
				return null
			res.bt += b
		
		return res
