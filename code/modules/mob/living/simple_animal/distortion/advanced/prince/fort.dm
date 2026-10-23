// The fort: square rings of root walls round the Prince, one at stage 0 and one at stage 1. Each ring has a gate
// in the middle of each side and on every door it crosses, and a watchtower just outside each gate, but only on spots
// the ring inside it can see. Walls stop everyone; gates let only his followers through. Ring 1 rises by itself; every
// ring after it is laid out as sites his harvesters build one by one. Hitting a wall or gate makes you a Foe. Past the
// rings he holds the streets with toll gates instead (see tolls.dm).

/// Adds rings until he has one more than his stage, up to max_rings. A jump of several stages plans them all now.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/BuildRings()
	var/wanted = min(max_rings, territory.stage + 1)
	while(length(rings) < wanted)
		rings += new /datum/prince_ring(src, length(rings) + 1)

/// A harvester's next job, in order: a fort site in the innermost ring that has any, then toll gate sites; a tap site; a tap with fewer
/// than drawers_per_tap drawing from it; then any tap. Within each, the one with the fewest harvesters on it, nearest
/// first. Anything nobody could reach lately is skipped.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/PickJobFor(mob/living/simple_animal/hostile/prince_follower/harvester/H)
	var/list/working = list()
	for(var/mob/living/simple_animal/hostile/prince_follower/harvester/other as anything in harvesters)
		if(other == H)
			continue
		if(other.building)
			working[other.building]++
		if(other.drawing)
			working[other.drawing]++
	var/list/tap_sites = list()
	var/list/taps = list()
	for(var/obj/machinery/vending/V as anything in held_machines)
		var/atom/A = held_machines[V]
		if(istype(A, /obj/structure/prince_site))
			tap_sites += A
		else if(istype(A, /obj/structure/prince_tap))
			taps += A
	// toll gates come after every ring, since they stand further out
	for(var/datum/prince_ring/R as anything in rings + tolls)
		var/list/sites = list()
		for(var/turf/T as anything in R.pieces)
			if(istype(R.pieces[T], /obj/structure/prince_site))
				sites += R.pieces[T]
		. = LeastWorked(H, sites, working)
		if(.)
			return
	. = LeastWorked(H, tap_sites, working)
	if(.)
		return
	. = LeastWorked(H, taps, working, drawers_per_tap)
	if(.)
		return
	return LeastWorked(H, taps, working)

/// Of candidates, the one with the fewest harvesters on it and then the nearest to H, skipping any that are
/// unreachable for now or already have cap harvesters. Null if none qualifies.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/LeastWorked(mob/living/H, list/candidates, list/working, cap)
	var/atom/best
	var/best_score
	for(var/atom/A as anything in candidates)
		if(PrinceUnreachable(A) || (cap && working[A] >= cap))
			continue
		var/score = working[A] * 1000 + get_dist(H, A)
		if(!best || score < best_score)
			best = A
			best_score = score
	return best

/// Whether a site or tap was found unreachable lately.
/proc/PrinceUnreachable(atom/A)
	if(istype(A, /obj/structure/prince_site))
		var/obj/structure/prince_site/S = A
		return S.unreachable_until > world.time
	if(istype(A, /obj/structure/prince_tap))
		var/obj/structure/prince_tap/tap = A
		return tap.unreachable_until > world.time
	return FALSE

// The rings. Each plans its turfs once, from what the ring inside it can see, then keeps something on every one: a
// piece, or a site for the harvesters to grow. Ring 1 starts as pieces, retried every retry_delay while someone
// stands in the way; later rings start as sites. A piece that breaks falls back to a site on the spot.

/datum/prince_ring
	var/mob/living/simple_animal/hostile/distortion/advanced/prince/prince
	/// 1 for the innermost.
	var/number
	/// What stands on each planned turf: "wall", "gate" or "tower".
	var/list/plan = list()
	/// The piece or site on each planned turf, and the turf of each.
	var/list/pieces = list()
	var/list/piece_turfs = list()
	/// For each gate on a side, the way out of the ring, and the tower beside it if it has one.
	var/list/gate_out = list()
	var/list/gate_tower = list()
	/// Planned turfs with nothing on them yet, and the time to try building there.
	var/list/regrow_at = list()
	var/retry_delay = 5 SECONDS

/datum/prince_ring/New(new_prince, new_number)
	prince = new_prince
	number = new_number
	Plan()
	for(var/turf/T as anything in plan)
		regrow_at[T] = 0
	Upkeep()

/datum/prince_ring/Destroy()
	for(var/atom/movable/piece as anything in piece_turfs)
		UnregisterSignal(piece, COMSIG_PARENT_QDELETING)
	pieces.Cut()
	piece_turfs.Cut()
	plan.Cut()
	gate_out.Cut()
	gate_tower.Cut()
	regrow_at.Cut()
	prince = null
	return ..()

/// Lays out a square at this ring's radius: walls on open turfs, gates by doors, alleys and side middles, towers by
/// gates. Blocked turfs and one-tile corridors running along the ring are left out (see Buildable()). Of the rest,
/// a stretch between two of those is built whole if any spot in it is seen, or can be walked to from inside the
/// ring, so neither a ring running into open ground nor an alley out of sight leaves a hole.
/datum/prince_ring/proc/Plan()
	var/turf/center = get_turf(prince)
	var/radius = prince.ring_first + (number - 1) * prince.ring_step
	var/list/eyes = Eyes()
	var/list/around = Perimeter(center, radius)
	var/list/corridors = list()
	for(var/turf/T as anything in around)
		if(AlongCorridor(T, center, radius))
			corridors[T] = TRUE
	var/list/reached = Reached(center, radius, corridors)
	var/count = length(around)
	// start just after a blocked spot, so no stretch is split across the end of the list
	var/start = 1
	for(var/i in 1 to count)
		if(!Buildable(around[i], corridors))
			start = i % count + 1
			break
	var/list/stretch = list()
	var/stretch_seen = FALSE
	for(var/n in 0 to count)
		var/turf/T = n < count ? around[(start + n - 1) % count + 1] : null
		if(n < count && Buildable(T, corridors))
			stretch += T
			if(!stretch_seen && (reached[T] || Seen(T, eyes)))
				stretch_seen = TRUE
			continue
		if(stretch_seen)
			// a stretch one tile long is an alley crossing the ring
			var/alley = length(stretch) == 1
			for(var/turf/S as anything in stretch)
				plan[S] = (alley || Doorstep(S, corridors, center, radius)) ? "gate" : "wall"
		stretch.Cut()
		stretch_seen = FALSE
	for(var/side in GLOB.cardinals)
		var/turf/G = SideGate(center, radius, side)
		if(G)
			plan[G] = "gate"
	for(var/turf/G as anything in plan.Copy())
		if(plan[G] != "gate")
			continue
		var/out = OutwardDir(center, G, radius)
		if(!out)
			continue
		gate_out[G] = out
		var/turf/T = TowerTurf(G, out, eyes)
		if(T)
			plan[T] = "tower"
			gate_tower[G] = T

/// The ring's turfs in order round the square, corners included: along the bottom, up the right side, back along
/// the top and down the left. Off the map is null, which counts as blocked.
/datum/prince_ring/proc/Perimeter(turf/center, radius)
	. = list()
	var/list/corners = list(list(-radius, -radius), list(radius, -radius), list(radius, radius), list(-radius, radius))
	for(var/c in 1 to 4)
		var/list/from = corners[c]
		var/list/to_corner = corners[c % 4 + 1]
		var/step_x = SIGN(to_corner[1] - from[1])
		var/step_y = SIGN(to_corner[2] - from[2])
		for(var/i in 0 to 2 * radius - 1)
			. += locate(center.x + from[1] + step_x * i, center.y + from[2] + step_y * i, center.z)

/// Every turf someone could walk to from his, without crossing the square at radius, plus the turfs of the square
/// itself they could step onto. Doors count as open, and so do his own walls and gates, which a hole may yet replace.
/// Corridors along the square are walked through, so the far mouth of one is reached. Cardinal steps are enough: a
/// diagonal one onto the square passes a turf of it or of the inside on the way.
/datum/prince_ring/proc/Reached(turf/center, radius, list/corridors)
	. = list()
	var/list/queue = list(center)
	.[center] = TRUE
	var/i = 1
	while(i <= length(queue))
		var/turf/from = queue[i++]
		for(var/step_dir in GLOB.cardinals)
			var/turf/T = get_step(from, step_dir)
			if(!T || .[T] || !PrinceWalkable(from, T))
				continue
			.[T] = TRUE
			// the square itself is reached but not walked past
			if(corridors[T] || max(abs(T.x - center.x), abs(T.y - center.y)) < radius)
				queue += T

/// A one-tile corridor running along the square at T: both turfs across the ring from it are blocked. Walling it
/// would fill the whole corridor, so it is left open and gated where it meets the rest of the ring. Never a corner.
/datum/prince_ring/proc/AlongCorridor(turf/T, turf/center, radius)
	if(!T || !PrinceWalkable(T, T))
		return FALSE
	var/dx = abs(T.x - center.x)
	var/dy = abs(T.y - center.y)
	if(dx == dy)
		return FALSE
	var/list/across = dy == radius ? list(NORTH, SOUTH) : list(EAST, WEST)
	for(var/across_dir in across)
		var/turf/side = get_step(T, across_dir)
		if(side && PrinceWalkable(T, side))
			return FALSE
	return TRUE

/// Whether a stretch spot should be a gate rather than a wall: it holds a door, stands in front of one, or is the
/// mouth of a corridor along the ring. A door on the ring itself only gates its own spot, not its neighbours.
/datum/prince_ring/proc/Doorstep(turf/T, list/corridors, turf/center, radius)
	if(HasDoor(T))
		return TRUE
	for(var/step_dir in GLOB.cardinals)
		var/turf/next = get_step(T, step_dir)
		if(!next)
			continue
		if(corridors[next])
			return TRUE
		if(max(abs(next.x - center.x), abs(next.y - center.y)) != radius && HasDoor(next))
			return TRUE
	return FALSE

/// Whether someone could step from one turf onto the next, with doors open and his own fort ignored. Water, chasms
/// and lava are not walked on.
/proc/PrinceWalkable(turf/from, turf/T)
	if(!PrinceGround(T))
		return FALSE
	var/out_dir = get_dir(from, T)
	for(var/obj/structure/window/W in from)
		if(!W.CanAStarPass(null, out_dir))
			return FALSE
	var/in_dir = turn(out_dir, 180)
	for(var/obj/O in T)
		if(!O.density || istype(O, /obj/machinery/door) || istype(O, /obj/structure/mineral_door) || istype(O, /obj/structure/prince_fort))
			continue
		if(!O.CanAStarPass(null, in_dir, null))
			return FALSE
	return TRUE

/// Where this ring is seen from: his own turf for ring 1, otherwise every planned turf of the ring before.
/// Plans, not pieces, so a ring can be planned while the one inside it is still unbuilt.
/datum/prince_ring/proc/Eyes()
	if(number == 1)
		return list(get_turf(prince))
	var/datum/prince_ring/inner = prince.rings[number - 1]
	return inner.plan

/// Whether any eye within reach has a clear line to T. Ring 1's only eye is him, so it has no reach limit.
/datum/prince_ring/proc/Seen(turf/T, list/eyes)
	for(var/turf/eye as anything in eyes)
		if(number > 1 && get_dist(eye, T) > prince.ring_step + 1)
			continue
		if(Sees(eye, T))
			return TRUE
	return FALSE

/// A clear line between two turfs, not counting either end. His own walls and gates never block it.
/datum/prince_ring/proc/Sees(turf/from, turf/dest)
	for(var/turf/L as anything in getline(from, dest))
		if(L == from || L == dest)
			continue
		if(L.opacity || isclosedturf(L))
			return FALSE
		for(var/atom/movable/AM as anything in L)
			if(AM.opacity && !istype(AM, /obj/structure/prince_fort))
				return FALSE
	return TRUE

/// Floor someone could stand on: not a wall, space, deep water, a chasm or lava.
/proc/PrinceGround(turf/T)
	return T && !T.density && !isclosedturf(T) && !isspaceturf(T) && !isgroundlessturf(T) && !ischasm(T) && !islava(T)

/datum/prince_ring/proc/Buildable(turf/T, list/corridors)
	if(!PrinceGround(T) || corridors[T])
		return FALSE
	for(var/obj/machinery/M in T)
		if(M.density && !istype(M, /obj/machinery/door))
			return FALSE
	return TRUE

/datum/prince_ring/proc/HasDoor(turf/T)
	return (locate(/obj/machinery/door) in T) || (locate(/obj/structure/mineral_door) in T)

/// The planned turf nearest the middle of one side, corners left out. Null if the side has no planned turf.
/datum/prince_ring/proc/SideGate(turf/center, radius, side)
	var/turf/middle = get_ranged_target_turf(center, side, radius)
	var/along = (side == NORTH || side == SOUTH) ? EAST : NORTH
	for(var/offset in 0 to radius - 1)
		for(var/sign in list(1, -1))
			var/turf/T = get_ranged_target_turf(middle, sign > 0 ? along : turn(along, 180), offset)
			if(plan[T])
				return T
			if(!offset)
				break

/// The way out of the ring at a gate. Null on a corner, which faces two ways.
/datum/prince_ring/proc/OutwardDir(turf/center, turf/G, radius)
	var/dx = G.x - center.x
	var/dy = G.y - center.y
	if(abs(dx) == radius && abs(dy) == radius)
		return null
	if(dy == radius)
		return NORTH
	if(dy == -radius)
		return SOUTH
	return dx == radius ? EAST : WEST

/// One step out from the gate and one to the side, so the way through stays clear. Either side will do.
/datum/prince_ring/proc/TowerTurf(turf/G, out, list/eyes)
	if(!out)
		return null
	var/turf/front = get_step(G, out)
	if(!front)
		return null
	for(var/side in list(turn(out, 90), turn(out, -90)))
		var/turf/T = get_step(front, side)
		if(TowerSpot(T) && Seen(T, eyes))
			return T
	return null

/datum/prince_ring/proc/TowerSpot(turf/T)
	if(!T || isclosedturf(T) || T.is_blocked_turf(TRUE) || plan[T])
		return FALSE
	for(var/datum/prince_ring/R as anything in prince.rings)
		if(R.plan[T])
			return FALSE
	return TRUE

/// Puts a piece, or for ring 2 and up a site, on every planned turf whose time has come. A finished piece waits
/// while someone stands on its turf; a site does not, since it is not solid.
/datum/prince_ring/proc/Upkeep()
	if(!prince || prince.torn_down)
		return
	for(var/turf/T as anything in regrow_at.Copy())
		if(regrow_at[T] > world.time)
			continue
		if(number == 1 && (locate(/mob/living) in T))
			regrow_at[T] = world.time + retry_delay
			continue
		regrow_at -= T
		if(number == 1)
			BuildPiece(T)
		else
			Track(T, new /obj/structure/prince_site(T, prince, src, plan[T]))

/// Builds the finished piece planned for T. It rises out of the ground, unless instant: a site the harvesters
/// finished turns into it on the spot.
/datum/prince_ring/proc/BuildPiece(turf/T, instant = FALSE)
	var/atom/movable/piece
	// a new solid piece changes the way round, so every flow map made before it is stale
	prince.fort_version++
	switch(plan[T])
		if("wall")
			piece = new /obj/structure/prince_fort/wall(T, prince, instant)
		if("gate")
			piece = new /obj/structure/prince_fort/gate(T, prince, instant)
		if("tower")
			piece = prince.SpawnFollower(/mob/living/simple_animal/hostile/prince_follower/tower, T, instant)
		if("toll")
			piece = new /obj/structure/prince_fort/gate/toll(T, prince, instant)
		if("nursery")
			piece = new /obj/structure/prince_nursery(T, prince, instant)
	Track(T, piece)

/datum/prince_ring/proc/Track(turf/T, atom/movable/piece)
	if(QDELETED(piece))
		return
	prince.Own(piece)
	pieces[T] = piece
	piece_turfs[piece] = T
	RegisterSignal(piece, COMSIG_PARENT_QDELETING, PROC_REF(OnPieceDeleted))

/// A site reached 100%. His followers on its turf are stepped off it; anyone else makes it wait, and it asks again on
/// its next tick.
/datum/prince_ring/proc/FinishSite(obj/structure/prince_site/S)
	var/turf/T = piece_turfs[S]
	if(!T)
		return FALSE
	for(var/mob/living/simple_animal/hostile/prince_follower/F in T)
		StepOff(F, T)
	if(locate(/mob/living) in T)
		return FALSE
	UnregisterSignal(S, COMSIG_PARENT_QDELETING)
	piece_turfs -= S
	pieces -= T
	qdel(S)
	BuildPiece(T, TRUE)
	return TRUE

/// Moves a follower off T onto any turf next to it that it could walk to.
/datum/prince_ring/proc/StepOff(mob/living/simple_animal/hostile/prince_follower/F, turf/T)
	for(var/step_dir in shuffle(GLOB.alldirs.Copy()))
		if(PrinceFlowStep(T, step_dir, F, F.access_card))
			F.forceMove(get_step(T, step_dir))
			return

/// A broken piece falls back to a site on its turf straight away, for the harvesters to grow again.
/datum/prince_ring/proc/OnPieceDeleted(datum/source)
	SIGNAL_HANDLER
	var/turf/T = piece_turfs[source]
	piece_turfs -= source
	pieces -= T
	if(T && prince && !prince.torn_down)
		Track(T, new /obj/structure/prince_site(T, prince, src, plan[T]))

// Sites. A half-grown piece that cannot be broken or blocked: anyone walks through it. Harvesters standing next to it
// grow it to 100% over build_time each, faster with more of them, and progress is kept when they leave.

/obj/structure/prince_site
	name = "half-grown roots"
	desc = "Bare roots stand up in the shape of something that is not finished yet."
	icon = 'ModularLobotomy/_Lobotomyicons/prince_structures.dmi'
	icon_state = "wall_build"
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE
	/// The distortion it belongs to. Null if an admin spawned it alone.
	var/mob/living/simple_animal/hostile/distortion/advanced/prince/prince
	var/datum/prince_ring/ring
	/// What it becomes: "wall", "gate", "tower", "toll" or "nursery".
	var/kind
	/// 0 to 100.
	var/progress = 0
	/// How long one harvester takes to grow it from 0 to 100.
	var/build_time = 10 SECONDS
	/// No harvester tries for it again before this, after one found no way to it.
	var/unreachable_until = 0
	/// The progress bar step shown, in fives, or -1 for none, so the overlay is only rebuilt when it changes.
	var/shown_progress = -1
	/// The bar sits this far above its turf: over the top of the sprite.
	var/bar_height = 32

/obj/structure/prince_site/Initialize(mapload, new_prince, new_ring, new_kind)
	. = ..()
	prince = new_prince
	ring = new_ring
	kind = new_kind || "wall"
	if(kind == "tower")
		icon = 'ModularLobotomy/_Lobotomyicons/prince_tower.dmi'
		bar_height = 64
	icon_state = "[kind]_build"
	update_icon()
	PrinceRise(src, bar_height)
	START_PROCESSING(SSobj, src)

/obj/structure/prince_site/Destroy()
	STOP_PROCESSING(SSobj, src)
	prince = null
	ring = null
	return ..()

/obj/structure/prince_site/examine(mob/user)
	. = ..()
	. += span_notice("It is [round(progress)]% grown.")

/// Harvesters within 1 tile that are working on it.
/obj/structure/prince_site/proc/Workers()
	. = 0
	for(var/mob/living/simple_animal/hostile/prince_follower/harvester/H in range(1, src))
		if(H.building == src && H.stat != DEAD)
			.++

/obj/structure/prince_site/process(delta_time)
	if(progress < 100)
		progress = min(100, progress + (100 / (build_time / 10)) * Workers() * delta_time)
	if(BarStep() != shown_progress)
		update_icon()
	if(progress >= 100)
		Complete()

/// Grown to 100%. A ring site asks its ring to finish it; the tap site in taps.dm goes its own way.
/obj/structure/prince_site/proc/Complete()
	ring?.FinishSite(src)

// Walls and gates. Both rise out of the ground over rise_time, block sight once risen, face the way their run
// goes, and take the doors and furniture under them into their roots, giving them back when they go.

/obj/structure/prince_fort
	name = "root palisade"
	desc = "Sharpened stakes of root, lashed together with thorned vine."
	icon = 'ModularLobotomy/_Lobotomyicons/prince_structures.dmi'
	icon_state = "wall"
	anchored = TRUE
	density = TRUE
	max_integrity = 500
	/// The distortion it belongs to. Null if an admin spawned it alone.
	var/mob/living/simple_animal/hostile/distortion/advanced/prince/prince
	/// His followers and their spit pass through it. Walls turn this off, so followers go round to a gate.
	var/followers_pass = FALSE
	/// The icon state once risen. The gate swaps it for its open states.
	var/base_state = "wall"
	var/rise_time = 2.5 SECONDS
	var/risen = FALSE
	var/list/swallowed = list()

/obj/structure/prince_fort/Initialize(mapload, new_prince, instant = FALSE)
	. = ..()
	prince = new_prince
	Swallow()
	UpdateRun()
	for(var/obj/structure/prince_fort/neighbour in orange(1, src))
		if(get_dir(src, neighbour) in GLOB.cardinals)
			neighbour.UpdateRun()
	if(instant)
		Rise()
		return
	icon_state = base_state
	PrinceRise(src, 32, rise_time)
	// a tick after the rise puts its icon back, so a corner picked up meanwhile is not undone
	addtimer(CALLBACK(src, PROC_REF(Rise)), rise_time + 1)

/obj/structure/prince_fort/Destroy()
	var/turf/T = get_turf(src)
	// the pieces beside it no longer join it once it is gone
	for(var/obj/structure/prince_fort/neighbour in orange(1, src))
		if(get_dir(src, neighbour) in GLOB.cardinals)
			addtimer(CALLBACK(neighbour, PROC_REF(UpdateRun)), 1)
	for(var/atom/movable/thing as anything in swallowed)
		if(!QDELETED(thing))
			thing.forceMove(T)
	swallowed.Cut()
	prince = null
	return ..()

/obj/structure/prince_fort/proc/Rise()
	if(risen)
		return
	risen = TRUE
	icon_state = base_state
	set_opacity(TRUE)

/// Doors and dense furniture on its turf go inside it.
/obj/structure/prince_fort/proc/Swallow()
	for(var/obj/O in get_turf(src))
		if(O == src || istype(O, /obj/structure/prince_fort))
			continue
		if(istype(O, /obj/machinery/door) || istype(O, /obj/structure/mineral_door) || (istype(O, /obj/structure) && O.density))
			O.forceMove(src)
			swallowed += O

/obj/structure/prince_fort/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(followers_pass && (istype(mover, /mob/living/simple_animal/hostile/prince_follower) || istype(mover, /obj/projectile/prince_spit)))
		return TRUE

/obj/structure/prince_fort/CanAStarPass(ID, dir, requester)
	if(followers_pass && istype(requester, /mob/living/simple_animal/hostile/prince_follower))
		return TRUE
	return ..()

/// Whether a run of wall carries on into T: a closed turf, or another wall or gate.
/obj/structure/prince_fort/proc/JoinsRun(turf/T)
	if(!T)
		return FALSE
	if(isclosedturf(T))
		return TRUE
	return !!(locate(/obj/structure/prince_fort) in T)

/// Faces EAST, the end-on sprite, when the run goes north-south: joined above or below and not to either side.
/obj/structure/prince_fort/proc/UpdateRun()
	var/turf/T = get_turf(src)
	var/north = JoinsRun(get_step(T, NORTH))
	var/south = JoinsRun(get_step(T, SOUTH))
	var/east = JoinsRun(get_step(T, EAST))
	var/west = JoinsRun(get_step(T, WEST))
	setDir((north || south) && !(east || west) ? EAST : SOUTH)
	UpdateCorner(north, south, east, west)

/// Walls use a corner sprite where the run turns. Gates never stand on a corner.
/obj/structure/prince_fort/proc/UpdateCorner(north, south, east, west)
	return

/// Joined on exactly one of north and south and one of east and west: wall_ne, wall_nw, wall_se or wall_sw.
/obj/structure/prince_fort/wall/UpdateCorner(north, south, east, west)
	base_state = initial(base_state)
	if(north != south && east != west)
		base_state = "wall_[north ? "n" : "s"][east ? "e" : "w"]"
	if(risen)
		icon_state = base_state

/obj/structure/prince_fort/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	Struck(user)

/obj/structure/prince_fort/bullet_act(obj/projectile/P)
	. = ..()
	Struck(P.firer)

/obj/structure/prince_fort/attack_animal(mob/living/simple_animal/M)
	. = ..()
	Struck(M)

/// Makes the attacker a Foe, which brings his waves and his towers down on them. Nothing is called out on the spot.
/obj/structure/prince_fort/proc/Struck(mob/living/by)
	if(!prince || !isliving(by) || istype(by, /mob/living/simple_animal/hostile/prince_follower))
		return
	prince.MakeFoe(by)

/obj/structure/prince_fort/wall

/obj/structure/prince_fort/gate
	name = "root gate"
	desc = "Two woven leaves of root between thick posts, clasped in gold."
	icon_state = "gate"
	max_integrity = 400
	followers_pass = TRUE
	base_state = "gate"
	/// How long it stays open after the last follower went through.
	var/gate_hold = 2 SECONDS
	var/close_timer
	/// RED damage the thorns deal to anyone else who bumps it.
	var/snap_damage = 5
	var/snap_cooldown = 1 SECONDS
	var/next_snap = 0

/obj/structure/prince_fort/gate/Destroy()
	if(close_timer)
		deltimer(close_timer)
	return ..()

/obj/structure/prince_fort/gate/examine(mob/user)
	. = ..()
	. += span_notice(PassNote())

/// Added to the message when the thorns snap at someone. The toll gate tells them what it wants.
/obj/structure/prince_fort/gate/proc/SnapHint()
	return ""

/// Who may go through, for examine.
/obj/structure/prince_fort/gate/proc/PassNote()
	return "Only his own may pass."

/// Whether AM may go through: his followers. The toll gate also lets through whoever paid.
/obj/structure/prince_fort/gate/proc/LetsThrough(atom/movable/AM)
	return istype(AM, /mob/living/simple_animal/hostile/prince_follower)

/// Anyone it lets through stepping in opens it, and it can be seen through while open.
/obj/structure/prince_fort/gate/Crossed(atom/movable/AM, oldloc)
	. = ..()
	if(risen && LetsThrough(AM))
		Open()

/// Opens, and shuts gate_hold after the last one it lets through has left.
/obj/structure/prince_fort/gate/proc/Open()
	if(icon_state != "[base_state]_open")
		flick("[base_state]_opening", src)
		icon_state = "[base_state]_open"
		set_opacity(FALSE)
	if(close_timer)
		deltimer(close_timer)
	close_timer = addtimer(CALLBACK(src, PROC_REF(Shut)), gate_hold, TIMER_STOPPABLE)

/obj/structure/prince_fort/gate/proc/Shut()
	close_timer = null
	for(var/atom/movable/AM in get_turf(src))
		if(AM != src && LetsThrough(AM))
			close_timer = addtimer(CALLBACK(src, PROC_REF(Shut)), gate_hold, TIMER_STOPPABLE)
			return
	flick("[base_state]_closing", src)
	icon_state = base_state
	set_opacity(TRUE)

/// Anyone else who walks into it gets the thorns.
/obj/structure/prince_fort/gate/Bumped(atom/movable/AM)
	. = ..()
	if(!risen || !isliving(AM) || LetsThrough(AM) || world.time < next_snap)
		return
	next_snap = world.time + snap_cooldown
	var/mob/living/L = AM
	flick("[base_state]_snap", src)
	playsound(src, 'sound/weapons/bladeslice.ogg', 30, TRUE)
	to_chat(L, span_warning("The thorns knot shut in your face.[SnapHint()]"))
	L.deal_damage(snap_damage, RED_DAMAGE, src)

// Watchtowers. A follower that never moves, just outside a gate, two tiles tall. It shoots whoever hit the fort lately,
// and every shot is aimed first: the eye goes red for aim_time, then it fires at where the target stood, so a step
// aside dodges it.

/mob/living/simple_animal/hostile/prince_follower/tower
	name = "watchtower"
	desc = "A hollow trunk with a woven nest on top. An eye on a green stalk turns to follow you."
	icon = 'ModularLobotomy/_Lobotomyicons/prince_tower.dmi'
	icon_state = "tower"
	icon_living = "tower"
	maxHealth = 800
	health = 800
	damage_coeff = list(RED_DAMAGE = 0.6, WHITE_DAMAGE = 1, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.2)
	density = TRUE
	move_resist = MOVE_FORCE_OVERPOWERING
	ranged = TRUE
	ranged_cooldown_time = 3 SECONDS
	projectiletype = /obj/projectile/prince_spit/tower
	projectilesound = 'sound/effects/splat.ogg'
	vision_range = 8
	aggro_vision_range = 8
	/// How long the eye is red before it fires.
	var/aim_time = 1 SECONDS
	var/rise_time = 2.5 SECONDS
	var/risen = FALSE

/mob/living/simple_animal/hostile/prince_follower/tower/Initialize(mapload, new_prince, instant = FALSE)
	. = ..()
	if(instant)
		Rise()
		return
	can_act = FALSE
	PrinceRise(src, 64, rise_time)
	addtimer(CALLBACK(src, PROC_REF(Rise)), rise_time)

/mob/living/simple_animal/hostile/prince_follower/tower/proc/Rise()
	if(risen)
		return
	risen = TRUE
	can_act = TRUE
	icon_state = icon_living

/mob/living/simple_animal/hostile/prince_follower/tower/Move(atom/newloc, direct, glide_size_override)
	return FALSE

/// Foes of the Prince it can see, and nobody else: once the mark is gone, so is the tower's interest.
/mob/living/simple_animal/hostile/prince_follower/tower/CanAttack(atom/the_target)
	if(!prince || !PrinceFoe(the_target, prince))
		return FALSE
	return ..()

/// Hitting a tower makes you a Foe, like hitting a wall or gate.
/mob/living/simple_animal/hostile/prince_follower/tower/PostDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	if(istype(source, /obj/projectile))
		var/obj/projectile/P = source
		source = P.firer
	prince?.MakeFoe(source)

/// Aims instead of firing: the shot leaves aim_time later, at the turf the target stood on.
/mob/living/simple_animal/hostile/prince_follower/tower/OpenFire(atom/A)
	if(stat == DEAD || !can_act || !A)
		return
	can_act = FALSE
	icon_state = "tower_aim"
	ranged_cooldown = world.time + aim_time + ranged_cooldown_time
	playsound(src, 'sound/weapons/batonextend.ogg', 30, TRUE)
	addtimer(CALLBACK(src, PROC_REF(Loose), get_turf(A)), aim_time)

/mob/living/simple_animal/hostile/prince_follower/tower/proc/Loose(turf/aimed)
	can_act = TRUE
	if(stat == DEAD)
		return
	icon_state = icon_living
	flick("tower_fire", src)
	Shoot(aimed)

/obj/projectile/prince_spit/tower
	name = "seed shot"
	damage = 35
	damage_type = RED_DAMAGE

/// Raises A out of the ground over time, shaking hard from side to side. Each step shows its sprite shifted down by
/// how far it still has to rise, with what falls below the tile cut away, so it climbs out with a hard edge at the
/// floor line and never fades in. height is the icon's height in pixels.
/proc/PrinceRise(atom/movable/A, height = 32, time = 2.5 SECONDS)
	var/steps = max(1, round(time))
	var/list/depths = list()
	var/list/shakes = list()
	for(var/i in 1 to steps)
		depths += i == steps ? 0 : clamp(round(height * (1 - i / steps)) + rand(-1, 1), 1, height)
		shakes += i == steps ? 0 : rand(-3, 3)
	var/icon/whole = A.icon
	var/whole_state = A.icon_state
	var/base_x = A.pixel_x
	// nothing shows until the first step
	PrinceRiseStep(A, whole, whole_state, height, base_x, FALSE)
	for(var/i in 1 to steps)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(PrinceRiseStep), A, whole, whole_state, depths[i], base_x + shakes[i], i == steps), i * time / steps)

/// One step of PrinceRise(): A shows its sprite depth pixels down, cut off at the floor, at pixel_x shake. The last
/// step puts its own icon back.
/proc/PrinceRiseStep(atom/movable/A, icon/whole, whole_state, depth, shake, last)
	if(QDELETED(A))
		return
	A.pixel_x = shake
	if(last)
		A.icon = whole
		A.icon_state = whole_state
		return
	// the facing it has now, since a wall turns to match neighbours that rise after it
	A.icon = PrinceRiseFrame(whole, whole_state, A.dir, depth)
	A.icon_state = "rise"

/// The sprite's first frame shifted down by depth, with the rows below the tile dropped, as the only state of a new
/// icon, named "rise". Cached, since every wall shares its frames.
/proc/PrinceRiseFrame(icon/whole, whole_state, sprite_dir, depth)
	var/static/list/frames = list()
	var/key = "[whole]|[whole_state]|[sprite_dir]|[depth]"
	var/icon/frame = frames[key]
	if(!frame)
		var/icon/cut = icon(whole, whole_state, sprite_dir, 1)
		cut.Shift(SOUTH, depth)
		frame = new
		frame.Insert(cut, "rise")
		frames[key] = frame
	return frame

/// The bar step to show: progress in fives, or -1 for no bar while nothing has been grown yet.
/obj/structure/prince_site/proc/BarStep()
	return progress > 0 ? round(progress, 5) : -1

/// The Prince's own progress bar over the site, seen by everyone, ghosts included: the stock bar recoloured, with thorns and leaves.
/obj/structure/prince_site/update_overlays()
	. = ..()
	shown_progress = BarStep()
	// no bar until someone has started on it
	if(shown_progress < 0)
		return
	var/mutable_appearance/bar = mutable_appearance('ModularLobotomy/_Lobotomyicons/prince_progress.dmi', "prince_bar_[shown_progress]", ABOVE_ALL_MOB_LAYER)
	bar.pixel_y = bar_height
	. += bar

/// Where a Tribute harvester stands at each of this ring's gates: one step out and one to the side, the side away
/// from the tower, so it never blocks the way through. A gate with no free spot there gets none.
/datum/prince_ring/proc/TributePosts()
	. = list()
	for(var/turf/G as anything in gate_out)
		var/out = gate_out[G]
		var/turf/front = get_step(G, out)
		if(!front)
			continue
		for(var/side in list(turn(out, 90), turn(out, -90)))
			var/turf/T = get_step(front, side)
			if(!T || T == gate_tower[G] || isclosedturf(T) || T.is_blocked_turf(TRUE) || plan[T])
				continue
			. += T
			break
