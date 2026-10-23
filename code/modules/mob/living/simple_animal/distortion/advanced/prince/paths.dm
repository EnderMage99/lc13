// Trails: a root path from the Prince to each machine he holds, so it is clear where the stolen stock goes. A faint
// thread while the tap is growing, a trodden trail with a pad at each end once it stands. Routes go through his gates,
// never his walls, and are planned again when new walls go up. Tiles join like cables: each knows which neighbours it
// links to, and its icon state names them. They are only a picture; nothing moves faster on them.

/obj/effect/prince_path
	name = "thread of root"
	desc = "A faint thread of root across the ground, marking where a trail is meant to go."
	icon = 'ModularLobotomy/_Lobotomyicons/prince_paths.dmi'
	icon_state = "plan-none"
	anchored = TRUE
	layer = ABOVE_OPEN_TURF_LAYER
	// a picture on the floor; clicks go to whatever is under it
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	/// The cardinals it links to, as a bitflag, the way cables keep theirs.
	var/linked_dirs = 0
	/// A trodden trail rather than a thread.
	var/laid = FALSE
	/// An end of a route, drawn as a wider pad once laid.
	var/node = FALSE

/obj/effect/prince_path/proc/Set(new_dirs, new_laid, new_node)
	if(new_dirs == linked_dirs && new_laid == laid && new_node == node)
		return
	linked_dirs = new_dirs
	laid = new_laid
	node = new_node
	name = laid ? "trodden trail" : initial(name)
	desc = laid ? "Trodden earth with a sheen of green goop and roots along its edges." : initial(desc)
	update_icon()

/// "plan-" while a thread, "node-" at a laid end, then the linked cardinals joined by "-", or "none".
/obj/effect/prince_path/update_icon_state()
	var/list/linked = list()
	for(var/dir in GLOB.cardinals)
		if(linked_dirs & dir)
			linked += "[dir]"
	var/joined = length(linked) ? linked.Join("-") : "none"
	if(!laid)
		icon_state = "plan-[joined]"
	else if(node)
		icon_state = "node-[joined]"
	else
		icon_state = joined
	return ..()

/mob/living/simple_animal/hostile/distortion/advanced/prince
	/// Each held machine's route from him, as a list of turfs.
	var/list/routes = list()
	/// Each toll gate's route from him to its nursery, the same way.
	var/list/toll_routes = list()
	/// Every trail tile, by turf.
	var/list/path_tiles = list()
	/// Most turfs a route search looks at before giving up.
	var/route_search_max = 4000
	/// Routes are planned again after the fort changes, but no more often than this.
	var/route_replan_interval = 30 SECONDS
	var/next_route_replan = 0
	var/routes_version = 0

/// Plans the route to V's site or tap and redraws the trails. It searches, so it runs off the caller.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/PlanRoute(obj/machinery/vending/V)
	set waitfor = FALSE
	var/list/route = RouteTo(get_turf(V))
	if(QDELETED(src) || torn_down)
		return
	if(route && held_machines[V])
		routes[V] = route
	else
		routes -= V
	DrawPaths()

/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/DropRoute(obj/machinery/vending/V)
	if(!routes[V])
		return
	routes -= V
	DrawPaths()

/// Plans every route again once the fort has changed since they were planned.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/ReplanRoutes()
	if(routes_version == fort_version || world.time < next_route_replan)
		return
	routes_version = fort_version
	next_route_replan = world.time + route_replan_interval
	for(var/obj/machinery/vending/V as anything in routes)
		PlanRoute(V)
	for(var/datum/prince_ring/toll/R as anything in tolls)
		PlanTollRoute(R)

/// Plans the route to R's nursery, built or not, and redraws the trails. It searches, so it runs off the caller.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/PlanTollRoute(datum/prince_ring/toll/R)
	set waitfor = FALSE
	var/list/route = RouteTo(R.nest)
	if(QDELETED(src) || torn_down)
		return
	if(route && R.prince)
		toll_routes[R] = route
	else
		toll_routes -= R
	DrawPaths()

/// The shortest walk in cardinal steps from him to goal, over ground his followers can walk: through his gates, round
/// his walls. The goal itself may be solid, like a vending machine, and so may start, if given in place of his turf.
/// Null if there is none within route_search_max.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/RouteTo(turf/goal, turf/start)
	start = start || get_turf(src)
	if(!start || !goal)
		return null
	var/mob/living/simple_animal/hostile/prince_follower/requester = length(harvesters) ? harvesters[1] : null
	var/obj/item/card/id/card = requester?.access_card
	var/list/came_from = list()
	came_from[start] = start
	var/list/queue = list(start)
	var/i = 1
	while(i <= length(queue) && length(queue) < route_search_max)
		var/turf/T = queue[i]
		i++
		if(T == goal)
			var/list/route = list(goal)
			while(route[1] != start)
				route.Insert(1, came_from[route[1]])
			return route
		for(var/dir in GLOB.cardinals)
			var/turf/next = get_step(T, dir)
			if(!next || came_from[next])
				continue
			if(next != goal && !PrinceFlowStep(T, dir, requester, card))
				continue
			came_from[next] = T
			queue += next
		if(!(i % 300))
			CHECK_TICK
	return null

/// Rebuilds the trail tiles from the routes: links from every route through a tile, laid where any of them leads to a
/// finished tap or nursery, a pad at every route's ends. Tiles no route uses any more are removed.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/DrawPaths()
	var/list/links = list()
	var/list/laid_at = list()
	var/list/nodes = list()
	// each route, and whether its end stands finished
	var/list/all_routes = list()
	var/list/all_laid = list()
	for(var/obj/machinery/vending/V as anything in routes)
		all_routes += list(routes[V])
		all_laid += istype(held_machines[V], /obj/structure/prince_tap)
	for(var/datum/prince_ring/toll/R as anything in toll_routes)
		all_routes += list(toll_routes[R])
		all_laid += istype(R.pieces[R.nest], /obj/structure/prince_nursery)
	for(var/r in 1 to length(all_routes))
		var/list/route = all_routes[r]
		var/laid = all_laid[r]
		var/count = length(route)
		for(var/i in 1 to count)
			var/turf/T = route[i]
			links[T] |= 0
			if(i > 1)
				links[T] |= get_dir(T, route[i - 1])
			if(i < count)
				links[T] |= get_dir(T, route[i + 1])
			if(laid)
				laid_at[T] = TRUE
			if(i == 1 || i == count)
				nodes[T] = TRUE
	for(var/turf/T as anything in path_tiles)
		if(!(T in links))
			qdel(path_tiles[T])
			path_tiles -= T
	for(var/turf/T as anything in links)
		var/obj/effect/prince_path/P = path_tiles[T]
		if(QDELETED(P))
			P = new(T)
			Own(P)
			path_tiles[T] = P
		P.Set(links[T], !!laid_at[T], !!nodes[T])
