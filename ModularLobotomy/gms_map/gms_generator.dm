// Builds a floor of the Grand Magasin each round: plans rooms around the base, loads them, then cuts the doors.
// The step by step is in workspace/docs/lc13/grand_magasin_sisyphe/MAP_GENERATION.md.
GLOBAL_DATUM(gms_generator, /obj/effect/landmark/gms_generator)
GLOBAL_LIST_EMPTY(gms_exits)

// Cells each room shape covers, counted from its bottom left cell.
GLOBAL_LIST_INIT(gms_room_shapes, list(
	"1x1" = list(list(0, 0)),
	"2x1" = list(list(0, 0), list(1, 0)),
	"1x2" = list(list(0, 0), list(0, 1)),
	"2x2" = list(list(0, 0), list(1, 0), list(0, 1), list(1, 1)),
	"l_missing_top_left" = list(list(0, 0), list(1, 0), list(1, 1)),
	"l_missing_top_right" = list(list(0, 0), list(1, 0), list(0, 1)),
	"l_missing_bottom_left" = list(list(1, 0), list(0, 1), list(1, 1)),
	"l_missing_bottom_right" = list(list(0, 0), list(0, 1), list(1, 1)),
	))

/// One planned room: the cells it covers, how far it is from the base, and the template loaded into it.
/datum/gms_room
	var/shape
	/// Bottom left cell of the shape.
	var/cell_x
	var/cell_y
	/// Cells it covers, as list(x, y) pairs.
	var/list/cells = list()
	/// Rooms between this one and the base, counting itself.
	var/distance = 1
	/// Rooms that grew out of this one. A room with none is a dead end.
	var/children = 0
	var/datum/map_template/random_room/gms/template

/// A door slot on the edge of the base that rooms may attach to. Its dir points out of the base.
/obj/effect/landmark/gms_exit
	name = "floor exit"

/obj/effect/landmark/gms_exit/Initialize()
	. = ..()
	GLOB.gms_exits += src

/obj/effect/landmark/gms_exit/Destroy()
	GLOB.gms_exits -= src
	return ..()

/// Sits on the bottom left turf of the cell grid and builds the floor once the map has loaded.
/obj/effect/landmark/gms_generator
	name = "floor generator"
	icon_state = "x"
	/// Tiles per side of a cell. Room templates are whole cells.
	var/cell_size = 7
	/// Size of the grid in cells, counted from this landmark.
	var/grid_width = 36
	var/grid_height = 36
	/// Percent of the free cells the rooms try to cover.
	var/fill_percent = 60
	/// A plan covering less than this percent of the free cells is thrown away and planned again.
	var/fill_min_percent = 50
	var/plan_attempts = 20
	/// Percent chance a room grows into a free cell beside it on each pass.
	var/grow_chance = 50
	/// Most claimed neighbours a cell may have and still be grown into. Passes start at 1 and loosen up to this.
	var/max_claimed_neighbours = 2
	/// Percent chance to try the bigger shapes before a 1x1.
	var/big_room_chance = 40
	/// Percent chance each exit after the first gets a room.
	var/exit_chance = 40
	/// Longest corridor cut from a base exit to the base floor.
	var/max_corridor_length = 8
	/// Doorways are this many tiles wide, centred on the door slot.
	var/doorway_width = 3
	var/floor_type = /turf/open/indestructible/gms
	var/wall_type = /turf/closed/indestructible/reinforced/gms
	var/void_type = /turf/closed/indestructible/gms_void
	/// Placed in the middle of each doorway if set.
	var/door_type
	/// Cells the current plan's rooms cover, and how many it should cover.
	var/room_cell_count = 0
	var/fill_target = 0

	var/turf/origin
	/// Keys of the cells the base takes up.
	var/list/base_cells = list()
	/// Cell key -> TRUE for the base, or the /datum/gms_room there.
	var/list/cells = list()
	var/list/rooms = list()
	/// Doors as list(cell_x, cell_y, dir): the slot on that cell's edge facing dir, and the slot across from it.
	var/list/doors = list()
	/// Shape -> the GMS room templates of that shape.
	var/list/templates_by_shape = list()
	/// Base turfs changed for corridors -> their type before, so a rebuild can put them back.
	var/list/base_changes = list()
	var/generating = FALSE

/obj/effect/landmark/gms_generator/Initialize()
	. = ..()
	GLOB.gms_generator = src
	origin = get_turf(src)
	return INITIALIZE_HINT_LATELOAD

// Rooms loaded while atoms are still initializing would not initialize, so build once the timer runs.
/obj/effect/landmark/gms_generator/LateInitialize()
	addtimer(CALLBACK(src, PROC_REF(Generate)), 1 SECONDS)

/obj/effect/landmark/gms_generator/Destroy()
	if(GLOB.gms_generator == src)
		GLOB.gms_generator = null
	return ..()

/// Tears down the last floor and builds a new one. Returns FALSE if it could not build.
/obj/effect/landmark/gms_generator/proc/Generate()
	if(generating)
		return FALSE
	generating = TRUE
	Clear()
	SortTemplates()
	ClaimBaseCells()
	var/list/exits = ValidExits()
	if(!length(exits) || !length(templates_by_shape["1x1"]))
		message_admins("GMS floor generator: no usable exits or no 1x1 room templates, nothing built.")
		log_world("GMS floor generator: no usable exits or no 1x1 room templates, nothing built.")
		generating = FALSE
		return FALSE
	var/free_cells = grid_width * grid_height - length(base_cells)
	fill_target = round(free_cells * fill_percent / 100)
	var/fill_minimum = round(free_cells * fill_min_percent / 100)
	var/list/best_rooms
	var/list/best_doors
	var/best_count = -1
	var/plans_made = 0
	for(var/attempt in 1 to plan_attempts)
		plans_made = attempt
		Plan(exits)
		if(room_cell_count > best_count)
			best_rooms = rooms
			best_doors = doors
			best_count = room_cell_count
		if(room_cell_count >= fill_minimum)
			break
	rooms = best_rooms
	doors = best_doors
	room_cell_count = best_count
	cells = base_cells.Copy()
	for(var/datum/gms_room/room as anything in rooms)
		for(var/list/cell as anything in room.cells)
			cells[CellKey(cell)] = room
	LoadRooms()
	CutDoors()
	var/joined = ConnectStrays()
	Report(plans_made, joined)
	generating = FALSE
	return TRUE

/obj/effect/landmark/gms_generator/proc/SortTemplates()
	templates_by_shape = list()
	for(var/id in SSmapping.random_room_templates)
		var/datum/map_template/random_room/gms/template = SSmapping.random_room_templates[id]
		if(!istype(template))
			continue
		if(!templates_by_shape[template.shape])
			templates_by_shape[template.shape] = list()
		templates_by_shape[template.shape] += template

/// Step 2: any cell holding a turf outside the unbuilt area belongs to the base.
/obj/effect/landmark/gms_generator/proc/ClaimBaseCells()
	base_cells = list()
	for(var/cell_x in 0 to grid_width - 1)
		for(var/cell_y in 0 to grid_height - 1)
			for(var/turf/T as anything in CellTurfs(cell_x, cell_y))
				if(!istype(T.loc, /area/gms/unbuilt))
					base_cells[CellKey(list(cell_x, cell_y))] = TRUE
					break

/// Exits that sit on a base door slot, face a free cell, and have base floor within reach.
/obj/effect/landmark/gms_generator/proc/ValidExits()
	. = list()
	for(var/obj/effect/landmark/gms_exit/exit as anything in GLOB.gms_exits)
		var/turf/slot = get_turf(exit)
		if(slot.z != origin.z)
			continue
		var/turf/outside = get_step(slot, exit.dir)
		var/list/room_cell = CellOf(outside)
		if(base_cells[CellKey(CellOf(slot))] && InGrid(room_cell) && !base_cells[CellKey(room_cell)] \
			&& SlotTurf(room_cell[1], room_cell[2], turn(exit.dir, 180)) == outside && CorridorPath(slot, turn(exit.dir, 180)))
			. += exit
		else
			log_world("GMS exit at [AREACOORD(slot)] is not on a usable door slot, skipped.")

/// Steps 3 and 4: seed rooms at the exits, then keep growing rooms out of rooms until the floor is full enough.
/// Each pass gives every room a chance to grow; once nothing can grow, the neighbour rule loosens by one.
/obj/effect/landmark/gms_generator/proc/Plan(list/exits)
	cells = base_cells.Copy()
	rooms = list()
	doors = list()
	room_cell_count = 0
	for(var/obj/effect/landmark/gms_exit/exit as anything in shuffle(exits))
		if(length(rooms) && !prob(exit_chance))
			continue
		var/list/room_cell = CellOf(get_step(get_turf(exit), exit.dir))
		PlaceRoom(room_cell, turn(exit.dir, 180), null)
	for(var/neighbour_limit in 1 to max_claimed_neighbours)
		var/could_grow = TRUE
		while(could_grow && room_cell_count < fill_target)
			could_grow = FALSE
			for(var/datum/gms_room/room as anything in shuffle(rooms))
				for(var/list/cell as anything in shuffle(room.cells))
					for(var/dir in shuffle(GLOB.cardinals))
						var/list/next = StepCell(cell, dir)
						if(room_cell_count >= fill_target || !CanGrowInto(next, neighbour_limit))
							continue
						could_grow = TRUE
						if(!prob(grow_chance))
							continue
						if(PlaceRoom(next, turn(dir, 180), room))
							room.children++

/// The Isaac rules: a free cell in the grid, with no more than the allowed number of claimed neighbours.
/obj/effect/landmark/gms_generator/proc/CanGrowInto(list/cell, neighbour_limit)
	if(!InGrid(cell) || cells[CellKey(cell)])
		return FALSE
	var/claimed_neighbours = 0
	for(var/dir in GLOB.cardinals)
		if(cells[CellKey(StepCell(cell, dir))])
			claimed_neighbours++
	return claimed_neighbours <= neighbour_limit

/// Fits a shape over the cell, big shapes first if the roll allows, claims its cells and records the door back.
/obj/effect/landmark/gms_generator/proc/PlaceRoom(list/cell, door_dir, datum/gms_room/parent)
	var/list/shapes = list()
	if(prob(big_room_chance))
		shapes += shuffle(templates_by_shape - "1x1")
	shapes += "1x1"
	for(var/shape in shapes)
		var/list/offsets = GLOB.gms_room_shapes[shape]
		for(var/list/anchor as anything in shuffle(offsets))
			var/base_x = cell[1] - anchor[1]
			var/base_y = cell[2] - anchor[2]
			if(!ShapeFits(offsets, base_x, base_y))
				continue
			var/datum/gms_room/room = new
			room.shape = shape
			room.cell_x = base_x
			room.cell_y = base_y
			room.distance = parent ? parent.distance + 1 : 1
			for(var/list/offset as anything in offsets)
				var/list/room_cell = list(base_x + offset[1], base_y + offset[2])
				room.cells += list(room_cell)
				cells[CellKey(room_cell)] = room
			rooms += room
			room_cell_count += length(offsets)
			doors += list(list(cell[1], cell[2], door_dir))
			return room
	return null

/obj/effect/landmark/gms_generator/proc/ShapeFits(list/offsets, base_x, base_y)
	for(var/list/offset as anything in offsets)
		var/list/cell = list(base_x + offset[1], base_y + offset[2])
		if(!InGrid(cell) || cells[CellKey(cell)])
			return FALSE
	return TRUE

/// Steps 7 and 8: pick a template for every planned room and load it, after checking its cells are still empty.
/obj/effect/landmark/gms_generator/proc/LoadRooms()
	var/list/used = list()
	for(var/datum/gms_room/room as anything in rooms)
		var/list/options = list()
		for(var/datum/map_template/random_room/gms/template as anything in templates_by_shape[room.shape])
			if(used[template] < template.stock)
				options[template] = template.weight
		if(!length(options))
			log_world("GMS floor generator: no [room.shape] template left, room skipped.")
			continue
		if(!CellsUnbuilt(room))
			log_world("GMS floor generator: cells of a [room.shape] room at [room.cell_x],[room.cell_y] are not empty, room skipped.")
			continue
		room.template = pickweight(options)
		used[room.template]++
		room.template.load(CellCorner(room.cell_x, room.cell_y))
		CHECK_TICK

/obj/effect/landmark/gms_generator/proc/CellsUnbuilt(datum/gms_room/room)
	for(var/list/cell as anything in room.cells)
		for(var/turf/T as anything in CellTurfs(cell[1], cell[2]))
			if(!istype(T.loc, /area/gms/unbuilt))
				return FALSE
	return TRUE

/// Step 9: open a doorway doorway_width tiles wide through both walls of every planned door.
/// Into another room it is a plain gap; into the base it runs on as a corridor to the base floor.
/obj/effect/landmark/gms_generator/proc/CutDoors()
	for(var/list/door as anything in doors)
		var/list/cell = list(door[1], door[2])
		var/datum/gms_room/room = cells[CellKey(cell)]
		var/other = cells[CellKey(StepCell(cell, door[3]))]
		if(!room.template)
			continue
		if(other != TRUE)
			var/datum/gms_room/other_room = other
			if(!other_room.template)
				continue
		OpenDoorway(cell, door[3], other == TRUE)

/// Cuts one doorway out of a room cell's edge. into_base runs it on as a corridor to the base floor.
/obj/effect/landmark/gms_generator/proc/OpenDoorway(list/cell, dir, into_base)
	var/half_width = round(doorway_width / 2)
	var/turf/slot = SlotTurf(cell[1], cell[2], dir)
	var/along_x = (dir == NORTH || dir == SOUTH)
	for(var/offset in -half_width to half_width)
		var/turf/lane = locate(slot.x + (along_x ? offset : 0), slot.y + (along_x ? 0 : offset), slot.z)
		var/turf/across = get_step(lane, dir)
		if(into_base)
			CarveCorridor(across, dir)
		else
			across.ChangeTurf(FloorBeside(across, dir))
		lane.ChangeTurf(FloorBeside(lane, turn(dir, 180)))
	if(door_type)
		new door_type(slot)

/// The floor one step into the room from a wall tile, so a doorway matches the room it opens into.
/obj/effect/landmark/gms_generator/proc/FloorBeside(turf/wall, inward_dir)
	var/turf/inside = get_step(wall, inward_dir)
	return isopenturf(inside) ? inside.type : floor_type

/// Step 9b: the base can have parts cut off from the spawn, and so can the rooms planned out of them.
/// Floods from a spawn and joins one cut off room to a reachable neighbour at a time, until nothing more can be joined.
/obj/effect/landmark/gms_generator/proc/ConnectStrays()
	if(!length(SSjob.latejoin_trackers))
		return 0
	var/turf/start = SSjob.latejoin_trackers[1]
	var/joined = 0
	for(var/attempt in 1 to length(rooms))
		var/list/reached = FloodFloor(start)
		var/found = FALSE
		for(var/datum/gms_room/room as anything in shuffle(rooms))
			if(!room.template || reached[RoomFloor(room)])
				continue
			for(var/list/cell as anything in shuffle(room.cells))
				for(var/dir in shuffle(GLOB.cardinals))
					var/datum/gms_room/other = cells[CellKey(StepCell(cell, dir))]
					if(!istype(other) || other == room || !other.template || !reached[RoomFloor(other)])
						continue
					OpenDoorway(cell, dir, FALSE)
					found = TRUE
					break
				if(found)
					break
			if(found)
				break
		if(!found)
			break
		joined++
		CHECK_TICK
	return joined

/// Every open turf walkable from the start, as turf -> TRUE.
/obj/effect/landmark/gms_generator/proc/FloodFloor(turf/start)
	var/list/reached = list()
	reached[start] = TRUE
	var/list/queue = list(start)
	var/index = 1
	while(index <= length(queue))
		var/turf/T = queue[index++]
		for(var/dir in GLOB.cardinals)
			var/turf/next = get_step(T, dir)
			if(next && !reached[next] && isopenturf(next))
				reached[next] = TRUE
				queue += next
	return reached

/// Any floor turf of the room, to test whether it can be reached. Layouts may put a pillar in the middle.
/obj/effect/landmark/gms_generator/proc/RoomFloor(datum/gms_room/room)
	var/list/cell = room.cells[1]
	for(var/turf/T as anything in CellTurfs(cell[1], cell[2]))
		if(isopenturf(T))
			return T

/// The turfs from a base door slot inward up to the first base floor, or null if there is none in reach inside the base.
/obj/effect/landmark/gms_generator/proc/CorridorPath(turf/start, inward_dir)
	. = list(start)
	var/turf/T = start
	for(var/i in 1 to max_corridor_length)
		T = get_step(T, inward_dir)
		if(!T || !base_cells[CellKey(CellOf(T))])
			return null
		if(isopenturf(T))
			return .
		. += T
	return null

/// Opens one lane of a corridor from a base door slot to the base floor it leads to, walling off the darkness around it.
/obj/effect/landmark/gms_generator/proc/CarveCorridor(turf/start, inward_dir)
	var/list/path = CorridorPath(start, inward_dir)
	if(!path)
		return
	var/turf/reached = get_step(path[length(path)], inward_dir)
	var/corridor_floor = istype(reached, /turf/open/indestructible/gms) ? reached.type : floor_type
	for(var/turf/T as anything in path)
		ChangeBaseTurf(T, corridor_floor)
	for(var/turf/T as anything in path)
		for(var/dir in GLOB.alldirs)
			var/turf/beside = get_step(T, dir)
			if(istype(beside, void_type) && base_cells[CellKey(CellOf(beside))])
				ChangeBaseTurf(beside, wall_type)

/obj/effect/landmark/gms_generator/proc/ChangeBaseTurf(turf/T, path)
	if(!(T in base_changes))
		base_changes[T] = T.type
	T.ChangeTurf(path)

/// Tears down the last floor: empties and voids every room cell, and puts the base's corridor turfs back.
/obj/effect/landmark/gms_generator/proc/Clear()
	var/area/unbuilt = GLOB.areas_by_type[/area/gms/unbuilt]
	var/turf/safe_spot = length(SSjob.latejoin_trackers) ? pick(SSjob.latejoin_trackers) : null
	for(var/datum/gms_room/room as anything in rooms)
		if(!room.template)
			continue
		for(var/list/cell as anything in room.cells)
			for(var/turf/T as anything in CellTurfs(cell[1], cell[2]))
				EmptyTurf(T, safe_spot)
				var/turf/voided = T.ChangeTurf(void_type)
				var/area/old_area = voided.loc
				if(unbuilt && old_area != unbuilt)
					unbuilt.contents += voided
					voided.change_area(old_area, unbuilt)
		CHECK_TICK
	for(var/turf/T as anything in base_changes)
		EmptyTurf(T, safe_spot)
		T.ChangeTurf(base_changes[T])
	base_changes = list()
	rooms = list()
	doors = list()

// Landmarks are kept, since the generator itself may stand in a cell that gets cleared.
/obj/effect/landmark/gms_generator/proc/EmptyTurf(turf/T, turf/safe_spot)
	for(var/mob/living/L in T)
		if(safe_spot)
			L.forceMove(safe_spot)
	for(var/obj/O in T)
		if(!istype(O, /obj/effect/landmark))
			qdel(O)

/obj/effect/landmark/gms_generator/proc/Report(plans_made, joined)
	var/dead_ends = 0
	var/farthest = 0
	var/loaded = 0
	for(var/datum/gms_room/room as anything in rooms)
		if(!room.template)
			continue
		loaded++
		farthest = max(farthest, room.distance)
		if(!room.children)
			dead_ends++
	var/message = "GMS floor built: [loaded] rooms covering [room_cell_count] cells (target [fill_target]), [dead_ends] dead ends, farthest [farthest] rooms out, [joined] extra doorways to reach cut off rooms, plan [plans_made] of [plan_attempts]."
	message_admins(message)
	log_world(message)

/obj/effect/landmark/gms_generator/proc/CellKey(list/cell)
	return "[cell[1]],[cell[2]]"

/obj/effect/landmark/gms_generator/proc/InGrid(list/cell)
	return cell[1] >= 0 && cell[2] >= 0 && cell[1] < grid_width && cell[2] < grid_height

/obj/effect/landmark/gms_generator/proc/StepCell(list/cell, dir)
	switch(dir)
		if(NORTH)
			return list(cell[1], cell[2] + 1)
		if(SOUTH)
			return list(cell[1], cell[2] - 1)
		if(EAST)
			return list(cell[1] + 1, cell[2])
		if(WEST)
			return list(cell[1] - 1, cell[2])

/obj/effect/landmark/gms_generator/proc/CellOf(turf/T)
	return list(round((T.x - origin.x) / cell_size), round((T.y - origin.y) / cell_size))

/obj/effect/landmark/gms_generator/proc/CellCorner(cell_x, cell_y)
	return locate(origin.x + cell_x * cell_size, origin.y + cell_y * cell_size, origin.z)

/obj/effect/landmark/gms_generator/proc/CellTurfs(cell_x, cell_y)
	var/turf/corner = CellCorner(cell_x, cell_y)
	return block(corner, locate(corner.x + cell_size - 1, corner.y + cell_size - 1, corner.z))

/// The door slot in the middle of a cell edge.
/obj/effect/landmark/gms_generator/proc/SlotTurf(cell_x, cell_y, dir)
	var/turf/corner = CellCorner(cell_x, cell_y)
	var/middle = round(cell_size / 2)
	var/far_edge = cell_size - 1
	switch(dir)
		if(NORTH)
			return locate(corner.x + middle, corner.y + far_edge, corner.z)
		if(SOUTH)
			return locate(corner.x + middle, corner.y, corner.z)
		if(EAST)
			return locate(corner.x + far_edge, corner.y + middle, corner.z)
		if(WEST)
			return locate(corner.x, corner.y + middle, corner.z)

/// Testing tool: tears the floor down and builds a new one.
/obj/structure/gms_floor_lever
	name = "floor plan lever"
	desc = "Pulling it tears down every room past the base and builds a new floor. Admins only."
	icon = 'icons/obj/recycling.dmi'
	icon_state = "switch-off"
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE

/obj/structure/gms_floor_lever/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	if(!check_rights_for(user.client, R_DEBUG))
		to_chat(user, span_warning("The lever will not budge."))
		return
	if(!GLOB.gms_generator)
		to_chat(user, span_warning("There is no floor generator on this map."))
		return
	if(GLOB.gms_generator.generating)
		to_chat(user, span_warning("The floor is still being built."))
		return
	to_chat(user, span_notice("You pull the lever. The floor tears down and builds itself again."))
	INVOKE_ASYNC(GLOB.gms_generator, TYPE_PROC_REF(/obj/effect/landmark/gms_generator, Generate))

