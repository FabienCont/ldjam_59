# PolygonBuilder.gd
# Traces the outline of opaque pixels in an Image and returns a list of
# PackedVector2Array polygons, with each point centred in the tile coordinate
# system (origin = tile centre).
#
# Algorithm: for every solid pixel we emit only the edges that border a
# transparent (or out-of-bounds) pixel.  Those directed edge segments are then
# stitched into closed polygons and collinear vertices are removed.

extends RefCounted

# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

## Returns Array of PackedVector2Array, one per distinct polygon.
## alpha_threshold: pixels with alpha >= this value are considered solid.
func build_from_image(image: Image, alpha_threshold: float = 0.4) -> Array:
	# get_pixel() requires an uncompressed format – convert to RGBA8 in place.
	# The caller always passes a cropped copy so this is safe.
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)

	var w: int = image.get_width()
	var h: int = image.get_height()

	# 1. Build a flat solid-pixel mask (1 = solid, 0 = transparent).
	#    get_data() returns raw bytes – for FORMAT_RGBA8 alpha is byte index i*4+3.
	#    This is orders of magnitude faster than calling get_pixel() per pixel.
	var alpha_byte: int = int(alpha_threshold * 255.0)
	var raw: PackedByteArray = image.get_data()
	var solid := PackedByteArray()
	solid.resize(w * h)
	for i in w * h:
		solid[i] = 1 if raw[i * 4 + 3] >= alpha_byte else 0

	# 2. Collect boundary edges directed so that solid is always on the left.
	#    Each edge is a PackedVector2Array([start, end]).
	var edges: Array[PackedVector2Array] = []

	for y in h:
		for x in w:
			if solid[y * w + x] == 0:
				continue
			var top_empty:    bool = y == 0     or solid[(y - 1) * w + x] == 0
			var bottom_empty: bool = y == h - 1 or solid[(y + 1) * w + x] == 0
			var left_empty:   bool = x == 0     or solid[y * w + (x - 1)] == 0
			var right_empty:  bool = x == w - 1 or solid[y * w + (x + 1)] == 0

			# Each pixel occupies the square (x,y) → (x+1, y+1)
			if top_empty:
				edges.append(PackedVector2Array([Vector2(x, y),         Vector2(x + 1, y)]))
			if right_empty:
				edges.append(PackedVector2Array([Vector2(x + 1, y),     Vector2(x + 1, y + 1)]))
			if bottom_empty:
				edges.append(PackedVector2Array([Vector2(x + 1, y + 1), Vector2(x, y + 1)]))
			if left_empty:
				edges.append(PackedVector2Array([Vector2(x, y + 1),     Vector2(x, y)]))

	# 3. Stitch edges into closed polygons
	var raw_polygons: Array[PackedVector2Array] = _stitch(edges)

	# 4. Simplify (remove collinear vertices) and centre on tile origin
	var half := Vector2(w * 0.5, h * 0.5)
	var result: Array = []
	for poly in raw_polygons:
		var simplified: PackedVector2Array = _simplify(poly)
		var centred := PackedVector2Array()
		centred.resize(simplified.size())
		for i in simplified.size():
			centred[i] = simplified[i] - half
		if centred.size() >= 3:
			result.append(centred)

	return result

# ---------------------------------------------------------------------------
# Edge stitching
# ---------------------------------------------------------------------------

func _stitch(edges: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	# Map from a start-point to the list of edge indices beginning there.
	# Dictionary key is Vector2 (hashable in Godot 4).
	var start_map: Dictionary = {}
	for i in edges.size():
		var key: Vector2 = edges[i][0]
		if not start_map.has(key):
			start_map[key] = []
		(start_map[key] as Array).append(i)

	# Flag array: 0 = unused, 1 = used
	var used := PackedByteArray()
	used.resize(edges.size())  # zero-initialised by Godot

	var polygons: Array[PackedVector2Array] = []

	for i in edges.size():
		if used[i] != 0:
			continue
		var poly := PackedVector2Array()
		var idx: int = i
		while used[idx] == 0:
			used[idx] = 1
			poly.append(edges[idx][0])
			var next_pt: Vector2 = edges[idx][1]
			var found: int = -1
			if start_map.has(next_pt):
				for j in (start_map[next_pt] as Array):
					if used[j] == 0:
						found = j
						break
			if found == -1:
				# Only append next_pt if this is a genuinely open chain.
				# For a properly closed loop next_pt == poly[0] – do NOT add it,
				# as the duplicate causes _simplify to drop the real corner vertex.
				if not poly.is_empty() and next_pt != poly[0]:
					poly.append(next_pt)
				break
			idx = found
		if poly.size() >= 3:
			polygons.append(poly)

	return polygons

# ---------------------------------------------------------------------------
# Collinear vertex removal
# ---------------------------------------------------------------------------

func _simplify(poly: PackedVector2Array) -> PackedVector2Array:
	if poly.size() < 3:
		return poly
	var result := PackedVector2Array()
	var n: int = poly.size()
	for i in n:
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % n]
		var c: Vector2 = poly[(i + 2) % n]
		# 2-D cross product; zero means b is collinear with a–c
		var cross: float = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x)
		if absf(cross) > 0.0001:
			result.append(b)
	# Guard against over-simplification
	if result.size() < 3:
		return poly
	return result

