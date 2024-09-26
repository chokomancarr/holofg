extends RefCounted

static func is_type(obj: Object):
	return obj.has_method("serialize") \
		and obj.has_method("unserialize")

#func serialize(v : Dictionary):
#	if v.has("gs"):
#		assert(v.gs is GameState, "unexpected non-GameState in gs for hash.serialize!")
#		return (v.gs as GameState).dict4hash()
#	else:
#		return serialize_dictionary(v)

func unserialize(v : Dictionary):
	#only used for input state
	return v

func serialize(value):
	if value is GameState:
		return value.dict4hash()
	elif value is Dictionary:
		return serialize(value)
		#return serialize_dictionary(value)
	elif value is Array:
		return serialize_array(value)
	elif value is Resource:
		return serialize_resource(value)
	elif value is Object:
		return serialize_object(value)

	return serialize_other(value)

func serialize_dictionary(value: Dictionary) -> Dictionary:
	var serialized := {}
	for key in value:
		serialized[key] = serialize2(value[key])
	return serialized

func serialize_array(value: Array):
	var serialized := []
	for item in value:
		serialized.append(serialize2(item))
	return serialized

func serialize_resource(value: Resource):
	return {
		'_' = 'resource',
		path = value.resource_path,
	}

func serialize_object(value: Object):
	return {
		'_' = 'object',
		string = value.to_string(),
	}

func serialize_other(value):
	if value is Vector2:
		return {
			'_' = 'Vector2',
			x = value.x,
			y = value.y,
		}
	elif value is Vector3:
		return {
			'_' = 'Vector3',
			x = value.x,
			y = value.y,
			z = value.z,
		}
	elif value is Transform2D:
		return {
			'_' = 'Transform2D',
			x = {x = value.x.x, y = value.x.y},
			y = {x = value.y.x, y = value.y.y},
			origin = {x = value.origin.x, y = value.origin.y},
		}
	elif value is Transform3D:
		return {
			'_' = 'Transform3D',
			x = {x = value.basis.x.x, y = value.basis.x.y, z = value.basis.x.z},
			y = {x = value.basis.y.x, y = value.basis.y.y, z = value.basis.y.z},
			z = {x = value.basis.z.x, y = value.basis.z.y, z = value.basis.z.z},
			origin = {x = value.origin.x, y = value.origin.y, z = value.origin.z},
		}

	return value