extends RefCounted
class_name OBB

var _center: Vector3 = Vector3.ZERO
var _half_extents: Vector3 = Vector3.ZERO
var _basis: Basis = Basis()
var _cached_bounds := {}
var _cached_basis_x_inv := Vector3.ZERO
var _cached_basis_y_inv := Vector3.ZERO
var _cached_basis_z_inv := Vector3.ZERO

func _init(aabb: AABB, object: Node3D):
	compute(aabb, object)

func get_transformed_point(point: Vector3) -> Vector3:
	# Transform point to local space
	var local_point = point - _center
	# Apply inverse transformation
	return _basis.inverse() * local_point

func compute(aabb: AABB, object: Node3D):
	var center = object.global_position
	var half_extents = aabb.size / 2
	var p_basis = object.global_transform.basis
	_center = center
	_half_extents = half_extents
	_basis = p_basis

func get_rotated_bounds(expanded_distance: float) -> Dictionary:
	var cache_key := "%s_%s_%s_%s" % [_center, _basis, _half_extents, expanded_distance]
	if _cached_bounds.has(cache_key):
		return _cached_bounds[cache_key]

	var expanded_half_extents := _half_extents + Vector3.ONE * expanded_distance
	var basis_x := _basis.x * expanded_half_extents.x
	var basis_y := _basis.y * expanded_half_extents.y
	var basis_z := _basis.z * expanded_half_extents.z

	var min_bound := _center
	var max_bound := _center

	for i in 8:
		var point := _center
		point += basis_x if (i & 1) else -basis_x
		point += basis_y if (i & 2) else -basis_y
		point += basis_z if (i & 4) else -basis_z
		min_bound = min_bound.min(point)
		max_bound = max_bound.max(point)

	var result := {"min": min_bound, "max": max_bound}
	_cached_bounds[cache_key] = result
	return result

func _update_cached_inverse_basis() -> void:
	_cached_basis_x_inv = _basis.x / _half_extents.x
	_cached_basis_y_inv = _basis.y / _half_extents.y
	_cached_basis_z_inv = _basis.z / _half_extents.z

func get_obb_distance(point: Vector3) -> float:
	var local_point := point - _center
	var projected := Vector3(
		local_point.dot(_cached_basis_x_inv),
		local_point.dot(_cached_basis_y_inv),
		local_point.dot(_cached_basis_z_inv)
	)

	var distance := Vector3(
		maxf(absf(projected.x) - 1.0, 0.0),
		maxf(absf(projected.y) - 1.0, 0.0),
		maxf(absf(projected.z) - 1.0, 0.0)
	)

	return distance.length()