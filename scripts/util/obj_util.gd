class_name ObjUtil

static func clone(src, dst, args, clone_args, pred = null):
	for a in args:
		dst[a] = src[a]
	for c in clone_args:
		dst[c] = src[c].clone()
	if pred:
		pred.call(src, dst)
	return dst
