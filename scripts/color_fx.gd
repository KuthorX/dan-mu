extends RefCounted

static func alpha(color: Color, value: float) -> Color:
	var result: Color = color
	result.a = value
	return result
