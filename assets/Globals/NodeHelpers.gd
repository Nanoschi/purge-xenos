extends Node
class_name NodeHelpers

static func find_parent_by_name(current : Node, target_name: String) -> Node:
	current = current.get_parent()
	while current:
		if current.name == target_name:
			return current
		current = current.get_parent()
	push_error("Node not found: %s" % target_name)
	return null
