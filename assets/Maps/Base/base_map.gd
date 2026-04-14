extends Node2D
class_name BaseMap

const CELL_DEBUG_LABEL_SCENE: PackedScene = preload("uid://s05eepwpbj7e")

@export var pathfind: Pathfind
@export var show_debug_cells: bool = false

@onready var map_floor: MapFloor = $Floor
@onready var map_walls: Node2D = $Walls
@onready var map_interior: Node2D = $Interior

func _ready():
	# sets the current map (self) at the cursor manager
	SignalBus.main_init_finished.connect(func():
		SignalBus.map_initialized.emit(self ))
	
	if show_debug_cells:
		Log.debug("Cell coordinates logging is on!")
		for x in map_floor.get_used_rect().size.x:
			for y in map_floor.get_used_rect().size.y:
				var cell_debug_label = CELL_DEBUG_LABEL_SCENE.instantiate() as CellDebugLabel
				cell_debug_label.current_cell = Vector2i(x, y)
				cell_debug_label.position = MapHelpers.cell_to_pixel(cell_debug_label.current_cell)
				self.add_child(cell_debug_label)
			
func is_tile_walk_selectable(pos: Vector2i) -> bool:
	return pathfind.astar_grid.region.has_point(pos) and not pathfind.astar_grid.is_point_solid(pos)

func set_point_solid(pos: Vector2i, solid: bool) -> void:
	pathfind.set_point_solid(pos, solid)

## Unblocks the from field temporarily if it is solid (e.g. occupied by a character)
func get_astar_path(from: Vector2i, to: Vector2i, partial_path: bool = false) -> Array[Vector2i]:
	var was_solid = pathfind.astar_grid.is_point_solid(from)
	if was_solid:
		set_point_solid(from, false)
	var path = pathfind.astar_grid.get_id_path(from, to, partial_path)
	if was_solid:
		set_point_solid(from, true)
	return path

## Returns the rect of the floor in pixel world coordinates.
func get_used_rect() -> Rect2:
	var used_rect: Rect2i = map_floor.get_used_rect()
	# Get the top-left position in world coordinates
	var world_position = map_floor.map_to_local(used_rect.position)
	# Get the size in world coordinates (pixels)
	var world_size = map_floor.map_to_local(used_rect.size)
	
	return Rect2(world_position, world_size)


# los = line of sight
func get_los_to_enemies(from: Vector2i, enemy_group_name: String, weapon_range: int = 0) -> Array:
	var result = []
	for child in self.get_children():
		var c = child as BaseCharacter
		if c == null:
			continue
		if c.get_groups().has(enemy_group_name):
			var los = get_line_of_sight(from, c.current_cell, true, true, weapon_range)
			if los.size() > 0:
				result.append(los)
	return result


func get_line_of_sight(from_cell: Vector2i,
	to_cell: Vector2i,
	ignore_solid_from: bool,
	ignore_solid_to: bool,
	weapon_range: int = 0) -> Array[Vector2]:
	if weapon_range > 0:
		var dist = maxi(abs(to_cell.x - from_cell.x), abs(to_cell.y - from_cell.y))
		if dist > weapon_range:
			return []
	
	# Compute the segment in world coordinates
	var segment_start = MapHelpers.cell_to_pixel(from_cell)
	var segment_end = MapHelpers.cell_to_pixel(to_cell)
	
	# Get cell size from MapHelpers
	var cell_size = MapHelpers.cell_size
	
	# Get the region of the astar grid
	var region = pathfind.astar_grid.region
	
	# Iterate over all cells in the grid region
	for x in range(region.position.x, region.position.x + region.size.x):
		for y in range(region.position.y, region.position.y + region.size.y):
			var cell = Vector2i(x, y)
			# Skip non-solid cells
			if not pathfind.astar_grid.is_point_solid(cell):
				continue
				
			# Skip from/to cells if ignoring them
			if (cell == from_cell and ignore_solid_from) or (cell == to_cell and ignore_solid_to):
				continue

			# Compute the tile rectangle in world coordinates
			var tile_center = MapHelpers.cell_to_pixel(cell)
			var tile_rect = Rect2(tile_center - Vector2(cell_size) / 2, Vector2(cell_size))
			
			# Test if the segment intersects the tile rectangle
			if segment_intersects_rect(segment_start, segment_end, tile_rect):
				# Line of sight is blocked
				return []
	
	# No intersections found, line of sight is clear
	return [segment_start, segment_end]

func segment_intersects_rect(from_point: Vector2, to_point: Vector2, rect: Rect2) -> bool:
	if rect.has_point(from_point) or rect.has_point(to_point):
		return true

	var a = rect.position
	var b = a + Vector2(rect.size.x, 0)
	var c = a + rect.size
	var d = a + Vector2(0, rect.size.y)

	if Geometry2D.segment_intersects_segment(from_point, to_point, a, b):
		return true
	if Geometry2D.segment_intersects_segment(from_point, to_point, b, c):
		return true
	if Geometry2D.segment_intersects_segment(from_point, to_point, c, d):
		return true
	if Geometry2D.segment_intersects_segment(from_point, to_point, d, a):
		return true

	return false
