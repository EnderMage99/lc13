// The ground an advanced distortion has claimed. One per distortion, made from its spawn turf.
// It fills outward by walking distance, bounded only by walls, and treats doors as a cost rather than a wall,
// so areas are never consulted: on the city map one area type is reused for several detached buildings.
/datum/distortion_territory
	/// The distortion this belongs to.
	var/mob/living/simple_animal/hostile/distortion/advanced/owner
	/// Where it started. Claim order counts outward from here.
	var/turf/origin
	/// Claimed turfs in claim order, which is walking-cost order from the origin. Value is that cost.
	var/list/claimed = list()
	/// The stage each turf was claimed at, for the debug colours.
	var/list/claim_stage = list()
	/// The largest walking cost claimed so far; the territory's reach.
	var/reach = 0
	/// Open turfs next to claimed ones, not yet claimed. Value is the walking cost from the origin.
	var/list/frontier = list()
	/// Most turfs it may hold.
	var/cap = 2000
	/// Current stage, derived from size by StageFor(). Read, never set.
	var/stage = 0
	/// Claimed sizes at which the next stage begins. Stage 4 is the cap.
	var/list/stage_thresholds = list(100, 400, 1000)
	/// What a door tile costs in budget. Doors are where growth tends to pause, so rooms arrive as stages.
	var/door_cost = 6
	var/claims_water = FALSE
	var/claims_space = FALSE
	/// Typecache of area types it may claim. Null means anywhere.
	var/list/area_typecache
	/// Set by the owner to hold growth without stopping the loop.
	var/paused = FALSE
	/// Turfs per tick divided by the square root of the size, when the owner sets one. Null keeps the 15% rule.
	var/growth_rate
	/// Timer id for the growth loop, so Revert() can stop it.
	var/growth_timer
	/// Base interval between transient oddities. Divided by (stage + 1).
	var/oddity_interval = 20 SECONDS
	/// A transient oddity only plays if a player is within this many turfs.
	var/oddity_player_range = 7
	var/oddity_timer
	/// Coloured overlays on claimed turfs, one icon state per stage. Testing only.
	var/debug = FALSE
	var/list/debug_states = list("green", "yellow", "purple", "blue", "space_near")
	var/list/debug_overlays = list()

/datum/distortion_territory/New(mob/living/simple_animal/hostile/distortion/advanced/new_owner, turf/new_origin)
	owner = new_owner
	origin = new_origin
	cap = owner.territory_cap
	if(length(owner.territory_stages))
		stage_thresholds = owner.territory_stages.Copy()
	growth_rate = owner.territory_growth_rate
	if(length(owner.territory_areas))
		area_typecache = typecacheof(owner.territory_areas)
	frontier[origin] = 0

/datum/distortion_territory/Destroy()
	Revert()
	owner = null
	origin = null
	return ..()

/// Claims up to amount of budget from the frontier, cheapest turf first.
/// A plain turf costs 1 and a door tile costs door_cost. Stops early at the cap or when nothing is reachable.
/datum/distortion_territory/proc/Claim(amount)
	while(amount > 0 && claimed.len < cap && frontier.len)
		var/turf/T = CheapestFrontierTurf()
		var/distance = frontier[T]
		frontier -= T
		if(T in claimed)
			continue
		amount -= TurfCost(T)
		ClaimTurf(T, distance)
	UpdateStage()

/datum/distortion_territory/proc/CheapestFrontierTurf()
	var/turf/best
	var/best_cost = INFINITY
	for(var/turf/T in frontier)
		if(frontier[T] < best_cost)
			best = T
			best_cost = frontier[T]
	return best

/datum/distortion_territory/proc/TurfCost(turf/T)
	if(locate(/obj/machinery/door) in T)
		return door_cost
	if(locate(/obj/structure/mineral_door) in T)
		return door_cost
	return 1

/// Takes T and offers its neighbours to the frontier at distance plus their own cost.
/datum/distortion_territory/proc/ClaimTurf(turf/T, distance = 0)
	claimed[T] = distance
	claim_stage[T] = stage
	reach = max(reach, distance)
	for(var/dir in GLOB.cardinals)
		var/turf/next = get_step(T, dir)
		if(!next || (next in claimed) || !Eligible(next))
			continue
		var/next_cost = distance + TurfCost(next)
		if(isnull(frontier[next]) || frontier[next] > next_cost)
			frontier[next] = next_cost
	if(debug)
		ShowTurf(T)
	owner.OnTurfClaimed(T)

/// Whether a turf may ever be claimed. Only walls stop it: structures, doors and furniture never do,
/// since the territory is not walking, it is seeping. Water and space only if the subtype says so.
/datum/distortion_territory/proc/Eligible(turf/T)
	if(T.z != origin.z || isclosedturf(T))
		return FALSE
	if(!claims_water && istype(T, /turf/open/water))
		return FALSE
	if(!claims_space && isspaceturf(T))
		return FALSE
	if(area_typecache)
		var/area/A = get_area(T)
		if(!area_typecache[A.type])
			return FALSE
	return TRUE

/datum/distortion_territory/proc/StartGrowing(interval)
	if(growth_timer)
		deltimer(growth_timer)
	growth_timer = addtimer(CALLBACK(src, PROC_REF(Grow)), interval, TIMER_STOPPABLE | TIMER_LOOP)
	ScheduleOddity()

/datum/distortion_territory/proc/Grow()
	if(!owner || owner.stat == DEAD || paused)
		return
	Claim(GrowthAmount())
	owner.OnTerritoryGrown()

/// Budget per growth tick. By default 15% of the current size with a floor of 10, slow at first and fast once
/// large. With growth_rate set it is growth_rate / sqrt(size) instead: a burst at the start that keeps slowing.
/// From 25 turfs the cap is reached in about 1.5 * (cap ** 1.5 - 125) / growth_rate ticks.
/datum/distortion_territory/proc/GrowthAmount()
	if(growth_rate)
		return max(5, round(growth_rate / sqrt(max(1, claimed.len))))
	return max(10, round(claimed.len * 0.15))

/datum/distortion_territory/proc/StageFor(size)
	var/result = 0
	for(var/threshold in stage_thresholds)
		if(size >= threshold)
			result++
	if(size >= cap)
		result++
	return result

/datum/distortion_territory/proc/UpdateStage()
	var/new_stage = StageFor(claimed.len)
	if(new_stage == stage)
		return
	var/old_stage = stage
	stage = new_stage
	if(debug)
		message_admins("[owner] territory: stage [old_stage] -> [new_stage] at [claimed.len] turfs.")
	owner.OnStageChange(old_stage, new_stage)
	owner.UpdateCenter(new_stage)

/datum/distortion_territory/proc/Contains(turf/T)
	return (T in claimed)

/datum/distortion_territory/proc/Size()
	return claimed.len

/datum/distortion_territory/proc/Center()
	return origin

/// A random claimed turf, or the owner's turf if nothing is claimed.
/datum/distortion_territory/proc/RandomTurf()
	if(!claimed.len)
		return get_turf(owner)
	return pick(claimed)

/// A random claimed turf within range of T, falling back to any claimed turf.
/datum/distortion_territory/proc/RandomTurfNear(turf/T, range)
	var/list/near = list()
	for(var/turf/candidate in RANGE_TURFS(range, T))
		if(candidate in claimed)
			near += candidate
	if(near.len)
		return pick(near)
	return RandomTurf()

/// The n claimed turfs nearest the origin by walking cost: the first n claimed, since claiming is cheapest-first.
/datum/distortion_territory/proc/CenterTurfs(n)
	return claimed.Copy(1, min(n, claimed.len) + 1)

/// The n claimed turfs nearest the origin by plain steps, a door costing the same as a floor, so the room next
/// door comes before the far end of the street. Breadth-first over claimed turfs only, so it never crosses a wall.
/datum/distortion_territory/proc/NearestTurfs(n)
	var/list/result = list(origin)
	var/list/seen = list()
	seen[origin] = TRUE
	var/i = 1
	while(i <= result.len && result.len < n)
		var/turf/T = result[i++]
		for(var/dir in GLOB.cardinals)
			var/turf/next = get_step(T, dir)
			if(!next || seen[next] || !(next in claimed))
				continue
			seen[next] = TRUE
			result += next
			if(result.len >= n)
				break
	return result

/// Walking cost from the origin to a claimed turf, or null if it is not claimed.
/datum/distortion_territory/proc/Cost(turf/T)
	return claimed[T]

/// Every claimed turf whose walking cost is at most max_cost, in claim order.
/datum/distortion_territory/proc/TurfsWithin(max_cost)
	var/list/result = list()
	for(var/turf/T in claimed)
		if(claimed[T] > max_cost)
			break
		result += T
	return result

/// Stops growth and takes back every change. Safe to call more than once.
/datum/distortion_territory/proc/Revert()
	if(growth_timer)
		deltimer(growth_timer)
		growth_timer = null
	if(oddity_timer)
		deltimer(oddity_timer)
		oddity_timer = null
	HideAll()
	claimed.Cut()
	claim_stage.Cut()
	frontier.Cut()
	reach = 0

/datum/distortion_territory/proc/Debug(on)
	debug = on
	if(!on)
		HideAll()
		return
	for(var/turf/T in claimed)
		ShowTurf(T)

/datum/distortion_territory/proc/ShowTurf(turf/T)
	if(debug_overlays[T])
		return
	var/state = debug_states[min(claim_stage[T] + 1, debug_states.len)]
	var/mutable_appearance/MA = mutable_appearance('icons/turf/areas.dmi', state, ABOVE_OBJ_LAYER)
	MA.alpha = 110
	T.add_overlay(MA)
	debug_overlays[T] = MA

/datum/distortion_territory/proc/HideAll()
	for(var/turf/T in debug_overlays)
		T.cut_overlay(debug_overlays[T])
	debug_overlays.Cut()

// Oddities. Every so often one of the owner's oddities plays on a random claimed turf that has a player near it.

/datum/distortion_territory/proc/ScheduleOddity()
	if(oddity_timer)
		deltimer(oddity_timer)
	oddity_timer = addtimer(CALLBACK(src, PROC_REF(TickOddity)), oddity_interval / (stage + 1), TIMER_STOPPABLE)

/datum/distortion_territory/proc/TickOddity()
	oddity_timer = null
	if(!owner || owner.stat == DEAD)
		return
	ScheduleOddity()
	if(!claimed.len || !length(owner.oddities))
		return
	for(var/i in 1 to 5)
		var/turf/T = pick(claimed)
		if(!PlayerNear(T))
			continue
		var/path = pick(owner.oddities)
		new path(T, owner)
		return

/datum/distortion_territory/proc/PlayerNear(turf/T)
	for(var/mob/M as anything in GLOB.player_list)
		if(M.z == T.z && get_dist(M, T) <= oddity_player_range)
			return TRUE
	return FALSE
