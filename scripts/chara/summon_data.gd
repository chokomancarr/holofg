class_name SD

static var _singleton : SD

static func _get_singleton():
	if not _singleton:
		_singleton = new()
	return _singleton

var _list : Dictionary

static func create(sig : String) -> _SmBase:
	return _get_singleton()._list[sig].call()

static func reg(s, cls):
	_get_singleton()._list[s] = cls