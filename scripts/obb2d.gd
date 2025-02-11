class_name OBB2D

enum Axis {X, Y, Z}

static func compute_obb(node: Node3D, axis: OBB2D.Axis) -> Dictionary:
	var projected_points = _get_projected_points(node, axis)
	if projected_points.is_empty():
		return {}

	var convex_hull = Geometry2D.convex_hull(projected_points)
	if convex_hull.is_empty():
		return {}

	var min_area = INF
	var best_rect = {}

	for i in convex_hull.size():
		var j = (i + 1) % convex_hull.size()
		var edge = convex_hull[j] - convex_hull[i]
		if edge.length_squared() < 0.0001:
			continue

		var direction = edge.normalized()
		var perp = Vector2(-direction.y, direction.x)

		var data = _get_projection_extremes(convex_hull, direction, perp)
		var min_dir = data[0]
		var max_dir = data[1]
		var min_perp = data[2]
		var max_perp = data[3]
		var width = max_dir - min_dir
		var height = max_perp - min_perp
		var area = width * height

		if area < min_area:
			min_area = area
			best_rect = _create_obb_dict(direction, perp, min_dir, max_dir, min_perp, max_perp)

	return best_rect

static func _get_projected_points(node: Node3D, axis: OBB2D.Axis) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var mesh_instances = _find_mesh_instances(node)

	for mesh_instance in mesh_instances:
		var mesh: Mesh = mesh_instance.mesh
		if not mesh:
			continue

		var transform = mesh_instance.transform
		for surface_idx in mesh.get_surface_count():
			var vertices = mesh.surface_get_arrays(surface_idx)[Mesh.ARRAY_VERTEX]
			if vertices.is_empty():
				continue

			for vertex in vertices:
				var global_vertex = transform * vertex
				points.append(_project_vertex(global_vertex, axis))

	return points

static func _find_mesh_instances(node: Node3D) -> Array[Node3D]:
	var mesh_instances: Array[Node3D] = []
	if node is MeshInstance3D:
		mesh_instances.append(node)
	mesh_instances.append_array(node.find_children("*", "MeshInstance3D", true, false))
	return mesh_instances

static func _project_vertex(vertex: Vector3, axis: OBB2D.Axis) -> Vector2:
	match axis:
		Vector3.AXIS_X: return Vector2(vertex.y, vertex.z) # YZ plane
		Vector3.AXIS_Z: return Vector2(vertex.x, vertex.y) # XY plane
		_: return Vector2(vertex.x, vertex.z) # XZ plane (default)

static func _get_projection_extremes(points: Array[Vector2], dir: Vector2, perp: Vector2) -> Array:
	var min_dir = INF
	var max_dir = -INF
	var min_perp = INF
	var max_perp = -INF

	for p in points:
		var proj_dir = p.dot(dir)
		var proj_perp = p.dot(perp)
		min_dir = minf(min_dir, proj_dir)
		max_dir = maxf(max_dir, proj_dir)
		min_perp = minf(min_perp, proj_perp)
		max_perp = maxf(max_perp, proj_perp)

	return [min_dir, max_dir, min_perp, max_perp]

static func _create_obb_dict(dir: Vector2, perp: Vector2, min_d: float, max_d: float, min_p: float, max_p: float) -> Dictionary:
	var width = max_d - min_d
	var height = max_p - min_p
	var center = dir * (min_d + max_d) / 2 + perp * (min_p + max_p) / 2

	return {
		center = center,
		size = Vector2(width, height),
		rotation = dir.angle(),
		direction_axis = dir,
		perpendicular_axis = perp,
		min_projection_dir = min_d,
		max_projection_dir = max_d,
		min_projection_perp = min_p,
		max_projection_perp = max_p
	}
