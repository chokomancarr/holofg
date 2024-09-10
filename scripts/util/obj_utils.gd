class_name ObjUtil

static func clone(obj : Object, res : Object):
	for param in obj.get_property_list().slice(3):
		res.set(param.name, obj.get(param.name))
	return res

static func fill(obj : Object, params : Array):
	var i = 0
	var props = obj.get_property_list().slice(3)
	for p in params:
		if p:
			obj.set(props[i].name, p)
		i += 1
	return obj
