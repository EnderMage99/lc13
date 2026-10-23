// The Prince's followers: the crew's kids, grown into twigs. They move on flow maps (see below), open doors by
// bumping them, pass through each other and through his gates, but not his walls.
/mob/living/simple_animal/hostile/prince_follower
	name = "twiglet"
	desc = "A child-sized tangle of twigs under an acorn cap."
	icon = 'ModularLobotomy/_Lobotomyicons/prince_household.dmi'
	icon_state = "twiglet"
	icon_living = "twiglet"
	faction = list("prince")
	maxHealth = 40
	health = 40
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 1, PALE_DAMAGE = 1.5)
	melee_damage_lower = 0
	melee_damage_upper = 0
	vision_range = 7
	aggro_vision_range = 9
	del_on_death = TRUE
	robust_searching = TRUE
	// flow maps move it; stray random steps would only fight them
	wander = FALSE
	// twig-limbed things scramble over tables and counters
	pass_flags = PASSTABLE
	stat_attack = HARD_CRIT
	/// The distortion this follower belongs to. Null if an admin spawned it alone.
	var/mob/living/simple_animal/hostile/distortion/advanced/prince/prince
	/// The flow map it is following, and the timer that steps it along.
	var/datum/prince_flow/flow
	var/step_timer
	/// Set when the map it asked for does not reach where it stands: the goal cannot be reached from here.
	var/flow_failed = FALSE

/mob/living/simple_animal/hostile/prince_follower/Initialize(mapload, new_prince)
	. = ..()
	prince = new_prince
	access_card = new(src)
	access_card.access = get_all_accesses()

/mob/living/simple_animal/hostile/prince_follower/Destroy()
	StopFlow()
	flow = null
	prince = null
	QDEL_NULL(access_card)
	return ..()

/// Steps towards goal along a shared flow map. TRUE once it has arrived: on the goal or next to it.
/// Call it again every tick while it is going there; it keeps the map fresh and the steps going.
/mob/living/simple_animal/hostile/prince_follower/proc/FlowTo(turf/goal)
	flow_failed = FALSE
	if(!goal || !isturf(loc))
		return FALSE
	if(!flow || flow.goal != goal || !flow.Covers(src, prince))
		StopFlow()
		flow = prince ? prince.GetFlow(goal, src) : PrinceNewFlow(goal, src, 0)
	if(!flow.ready)
		return FALSE
	var/step_dir = flow.dirs[loc]
	if(step_dir == "dest")
		StopFlow()
		return TRUE
	if(!step_dir)
		StopFlow()
		// the way round may run outside a small map; only the widest one failing means there is none
		if(flow.range < flow.wide_range)
			flow = prince ? prince.GetFlow(goal, src, TRUE) : PrinceNewFlow(goal, src, 0, TRUE)
			return FALSE
		flow_failed = TRUE
		return FALSE
	if(!step_timer)
		FlowStep()
	return FALSE

/// One step along the map, then again move_to_delay later until it arrives. Stops while it is fighting.
/mob/living/simple_animal/hostile/prince_follower/proc/FlowStep()
	step_timer = null
	if(stat == DEAD || client || target || !flow?.ready || !isturf(loc))
		return
	var/step_dir = flow.dirs[loc]
	if(!step_dir || step_dir == "dest")
		return
	step(src, step_dir)
	step_timer = addtimer(CALLBACK(src, PROC_REF(FlowStep)), move_to_delay, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/prince_follower/proc/StopFlow()
	if(step_timer)
		deltimer(step_timer)
		step_timer = null

/// Followers pass through one another, so one standing in a gate never blocks the others.
/mob/living/simple_animal/hostile/prince_follower/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(istype(mover, /mob/living/simple_animal/hostile/prince_follower))
		return TRUE

/// Opens the doors its map runs through.
/mob/living/simple_animal/hostile/prince_follower/Bump(atom/A)
	if(istype(A, /obj/machinery/door))
		var/obj/machinery/door/D = A
		if(!D.operating && D.density && D.open())
			return
	if(istype(A, /obj/structure/mineral_door))
		var/obj/structure/mineral_door/M = A
		if(!M.door_opened && !M.isSwitchingStates)
			M.Open()
			return
	return ..()

/// Vanishes in a puff of green mist and steps out of another beside T.
/mob/living/simple_animal/hostile/prince_follower/proc/MistTo(turf/T)
	var/turf/landing = T
	for(var/turf/side in shuffle(orange(1, T)))
		if(!side.density && !side.is_blocked_turf(TRUE))
			landing = side
			break
	if(!landing)
		return
	StopFlow()
	new /obj/effect/temp_visual/small_smoke/halfsecond/green(get_turf(src))
	forceMove(landing)
	new /obj/effect/temp_visual/small_smoke/halfsecond/green(landing)

// Flow maps, after the Baromez's in branch12/he/baroputian.dm. Rather than a path per follower, one map per goal
// turf gives every turf around it the step that leads there, so followers heading for the same place share it. It
// is mapped outward from the goal: the goal and the turfs one step from it are "dest", where a follower has arrived.
// The goal itself may be solid; the turfs beside it only need to be walkable.
// Diagonal steps never cut a corner. His gates are open to followers; his walls, and anything solid, are not.

/datum/prince_flow
	var/turf/goal
	/// Turf to the direction a follower on it steps, or "dest" on and next to the goal.
	var/list/dirs = list()
	/// How far from the goal it was mapped, and his fort_version when it was. A new solid piece makes it stale.
	var/range = 0
	/// The widest a map is made, when a smaller one found no way.
	var/wide_range = 60
	var/version = 0
	var/ready = FALSE
	var/last_used = 0

/// Whether this map still serves F standing where it is: the fort has not changed and it reaches that far.
/datum/prince_flow/proc/Covers(mob/living/simple_animal/hostile/prince_follower/F, mob/living/simple_animal/hostile/distortion/advanced/prince/P)
	if(P && version != P.fort_version)
		return FALSE
	if(ready && !dirs[get_turf(F)] && get_dist(F, goal) > range)
		return FALSE
	last_used = world.time
	return TRUE

/// Maps outward from the goal, breadth first, a few hundred turfs per tick.
/datum/prince_flow/proc/Build(mob/living/simple_animal/hostile/prince_follower/requester)
	set waitfor = FALSE
	var/obj/item/card/id/card = requester.access_card
	var/list/queue = list(goal)
	dirs[goal] = "dest"
	var/i = 1
	while(i <= length(queue))
		var/turf/T = queue[i]
		i++
		for(var/d in GLOB.alldirs)
			var/turf/N = get_step(T, d)
			if(!N || dirs[N] || get_dist(N, goal) > range)
				continue
			var/back = turn(d, 180)
			// next to the goal is arrived without stepping onto it, which may be solid, like a vending machine
			if(T == goal ? isclosedturf(N) : !PrinceFlowStep(N, back, requester, card))
				continue
			dirs[N] = T == goal ? "dest" : back
			queue += N
		if(!(i % 300))
			CHECK_TICK
	ready = TRUE

/// A new map to goal, wide enough to reach the requester with room to spare, or as wide as a map goes if wide.
/proc/PrinceNewFlow(turf/goal, mob/living/simple_animal/hostile/prince_follower/requester, version, wide = FALSE)
	var/datum/prince_flow/F = new
	F.goal = goal
	F.range = wide ? F.wide_range : clamp(get_dist(requester, goal) + 6, 10, F.wide_range)
	F.version = version
	F.last_used = world.time
	F.Build(requester)
	return F

/// Whether a follower can step from one turf in a direction. A diagonal also needs both of its sides open.
/proc/PrinceFlowStep(turf/from, step_dir, requester, card)
	var/turf/dest = get_step(from, step_dir)
	if(!dest)
		return FALSE
	if(step_dir in GLOB.cardinals)
		return from.PrinceFollowerReachable(requester, dest, card, TRUE)
	var/vertical = step_dir & (NORTH|SOUTH)
	var/horizontal = step_dir & (EAST|WEST)
	if(!PrinceFlowStep(from, vertical, requester, card) || !PrinceFlowStep(from, horizontal, requester, card))
		return FALSE
	var/turf/side = get_step(from, vertical)
	return side.PrinceFollowerReachable(requester, dest, card, TRUE)

/// The step test for followers: the stock test with the doors they open by bumping let through, and his gates
/// open to them through their own CanAStarPass().
/turf/proc/PrinceFollowerReachable(requester, turf/T, ID, simulated_only)
	if(!T || T.density || (simulated_only && SSpathfinder.space_type_cache[T.type]))
		return FALSE
	var/adir = get_dir(src, T)
	var/rdir = turn(adir, 180)
	for(var/obj/structure/window/W in src)
		if(!W.CanAStarPass(ID, adir))
			return FALSE
	for(var/obj/structure/railing/R in src)
		if(!R.CanAStarPass(ID, adir, requester))
			return FALSE
	for(var/obj/machinery/door/window/W in src)
		if(!W.CanAStarPass(ID, adir))
			return FALSE
	for(var/obj/O in T)
		if(O.CanAStarPass(ID, rdir, requester))
			continue
		if(istype(O, /obj/structure/mineral_door))
			continue
		if(istype(O, /obj/machinery/door) && !istype(O, /obj/machinery/door/airlock) && !istype(O, /obj/machinery/door/window))
			var/obj/machinery/door/D = O
			if(D.check_access(ID))
				continue
		return FALSE
	return TRUE

// Worker harvesters. They never fight. Each asks him for a job (see PickJobFor()): grow a site, standing next to it,
// or draw from a tap, carrying the load back to him to eat. With no job they go back to him. A harvester killed while
// carrying drops its load where it falls.

/mob/living/simple_animal/hostile/prince_follower/harvester
	// they slip past people instead of getting stuck behind them on the way to work
	pass_flags = PASSTABLE | PASSMOB
	/// The site it is growing.
	var/obj/structure/prince_site/building
	/// The tap it is drawing from, and when the draw it has started is done.
	var/obj/structure/prince_tap/drawing
	var/draw_done_at = 0
	var/draw_time = 3 SECONDS
	/// What it is carrying to him.
	var/list/load = list()

/mob/living/simple_animal/hostile/prince_follower/harvester/Destroy()
	prince?.HarvesterLost(src)
	building = null
	drawing = null
	var/turf/T = get_turf(src)
	for(var/obj/item/I as anything in load)
		if(T)
			I.forceMove(T)
		else
			qdel(I)
	load.Cut()
	return ..()

/mob/living/simple_animal/hostile/prince_follower/harvester/CanAttack(atom/the_target)
	return FALSE

/mob/living/simple_animal/hostile/prince_follower/harvester/Life()
	. = ..()
	if(!. || client || !prince)
		return
	if(length(load))
		if(GoHome())
			prince.Eat(load)
			update_icon()
		return
	// a job someone else found unreachable is kept: Build() and Draw() give it up if this one cannot get there either
	if(QDELETED(building))
		building = null
	if(QDELETED(drawing))
		drawing = null
		draw_done_at = 0
	if(!building && !drawing)
		var/atom/job = prince.PickJobFor(src)
		if(istype(job, /obj/structure/prince_site))
			building = job
		else if(istype(job, /obj/structure/prince_tap))
			drawing = job
	if(building)
		Build()
		return
	if(drawing)
		Draw()
		return
	GoHome()

/// Walks back to him. Shut in where no way leads to him, it goes back in green mist instead. TRUE once beside him.
/mob/living/simple_animal/hostile/prince_follower/harvester/proc/GoHome()
	if(FlowTo(get_turf(prince)))
		return TRUE
	if(!flow_failed)
		return FALSE
	MistTo(get_turf(prince))
	return get_dist(src, prince) <= 1

/// Its job cannot be reached from here. Away from him it may be shut in, so it mists home and tries again from
/// there; only from beside him does that mean nobody can reach the job for now. TRUE when the job is to be dropped.
/mob/living/simple_animal/hostile/prince_follower/harvester/proc/GiveUp()
	if(get_dist(src, prince) > 1)
		MistTo(get_turf(prince))
		return FALSE
	return TRUE

/// Goes to its site and stands next to it; the site counts it as working while it does.
/mob/living/simple_animal/hostile/prince_follower/harvester/proc/Build()
	if(FlowTo(get_turf(building)))
		face_atom(building)
	else if(flow_failed && GiveUp())
		// nobody can reach it from him for now; the fort may open up
		building.unreachable_until = world.time + 30 SECONDS
		building = null

/// Goes to its tap, works it for draw_time, then takes what comes out and is done with that tap.
/mob/living/simple_animal/hostile/prince_follower/harvester/proc/Draw()
	if(!FlowTo(get_turf(drawing)))
		if(flow_failed && GiveUp())
			drawing.unreachable_until = world.time + 30 SECONDS
			drawing = null
		draw_done_at = 0
		return
	face_atom(drawing)
	if(!draw_done_at)
		draw_done_at = world.time + draw_time
		return
	if(world.time < draw_done_at)
		return
	draw_done_at = 0
	for(var/obj/item/I as anything in drawing.Draw(rand(1, 3)))
		I.forceMove(src)
		load += I
	drawing = null
	update_icon()

/// Shows the first thing it carries on its head.
/mob/living/simple_animal/hostile/prince_follower/harvester/update_overlays()
	. = ..()
	if(!length(load))
		return
	var/obj/item/I = load[1]
	var/mutable_appearance/carried = mutable_appearance(I.icon, I.icon_state)
	carried.transform = matrix() * 0.6
	carried.pixel_y = 10
	. += carried

/mob/living/simple_animal/hostile/prince_follower/harvester/examine(mob/user)
	. = ..()
	if(!isobserver(user))
		return
	if(building)
		var/turf/T = get_turf(building)
		. += span_notice("Building: [building.kind] at ([T.x], [T.y]), [round(building.progress)]% grown.")
	else if(drawing)
		var/turf/T = get_turf(drawing)
		. += span_notice("Drawing from: [drawing] at ([T.x], [T.y]).")
	if(length(load))
		. += span_notice("Carrying [length(load)] item\s to him.")

// Summons, sent out in his Foe waves (see foes.dm). Each starts after one Foe, but every tick it looks around:
// - a Foe of the Prince it can see, on his ground or off it, is chased and fought;
// - with none in sight, it follows a flow map to a living Foe on his ground, its own one if still there, else the
//   nearest other;
// - with no living Foe left on his ground, it walks home to him and is gone.
// It also fights back at anyone who hurts it.

/mob/living/simple_animal/hostile/prince_follower/summon
	name = "grown twiglet"
	desc = "Too tall for a child, with an arm bent into a hook."
	icon_state = "twiglet_large_a"
	icon_living = "twiglet_large_a"
	maxHealth = 150
	health = 150
	melee_damage_lower = 8
	melee_damage_upper = 12
	melee_damage_type = RED_DAMAGE
	attack_verb_continuous = "hooks"
	attack_verb_simple = "hook"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	/// The Foe on his ground it is making for while none is in sight.
	var/mob/living/quarry
	/// Anyone who has hurt it. It fights them too.
	var/list/grudges = list()

/mob/living/simple_animal/hostile/prince_follower/summon/Destroy()
	prince?.foe_summons -= src
	SetQuarry(null)
	for(var/mob/living/L as anything in grudges)
		UnregisterSignal(L, COMSIG_PARENT_QDELETING)
	grudges.Cut()
	return ..()

/mob/living/simple_animal/hostile/prince_follower/summon/proc/SetQuarry(mob/living/new_quarry)
	if(new_quarry == quarry)
		return
	if(quarry && !(quarry in grudges))
		UnregisterSignal(quarry, COMSIG_PARENT_QDELETING)
	quarry = new_quarry
	if(quarry)
		RegisterSignal(quarry, COMSIG_PARENT_QDELETING, PROC_REF(OnMarkDeleted), override = TRUE)

/mob/living/simple_animal/hostile/prince_follower/summon/proc/OnMarkDeleted(datum/source)
	SIGNAL_HANDLER
	grudges -= source
	if(source == quarry)
		quarry = null
	if(source == target)
		LoseTarget()

/// Foes of the Prince, wherever they stand, and whoever hurt it.
/mob/living/simple_animal/hostile/prince_follower/summon/CanAttack(atom/the_target)
	if(!(the_target in grudges) && !PrinceFoe(the_target, prince))
		return FALSE
	return ..()

/// Hurting one of his guards makes you a Foe, and it holds a grudge.
/mob/living/simple_animal/hostile/prince_follower/summon/PostDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	if(istype(source, /obj/projectile))
		var/obj/projectile/P = source
		source = P.firer
	if(!isliving(source) || istype(source, /mob/living/simple_animal/hostile/prince_follower))
		return
	prince?.MakeFoe(source)
	if(source in grudges)
		return
	grudges += source
	RegisterSignal(source, COMSIG_PARENT_QDELETING, PROC_REF(OnMarkDeleted), override = TRUE)

/mob/living/simple_animal/hostile/prince_follower/summon/Life()
	. = ..()
	// riding a light between nurseries
	if(!. || client || !isturf(loc))
		return
	if(target)
		StopFlow()
		return
	if(!prince)
		qdel(src)
		return
	if(FightInSight())
		return
	if(!ValidQuarry(quarry))
		SetQuarry(NearestFoeInside())
	if(quarry)
		Hunt()
		return
	GoHome()

/// Takes on any Foe of the Prince, or anyone it holds a grudge against, that it can see. TRUE if it found one.
/mob/living/simple_animal/hostile/prince_follower/summon/proc/FightInSight()
	var/list/seen = list()
	for(var/mob/living/L in view(vision_range, src))
		if(L.stat != DEAD && ((L in grudges) || PrinceFoe(L, prince)))
			seen += L
	return length(seen) && FindTarget(seen, TRUE)

/// A Foe worth walking to: alive, still his Foe, and on his ground.
/mob/living/simple_animal/hostile/prince_follower/summon/proc/ValidQuarry(mob/living/L)
	return L && L.stat != DEAD && PrinceFoe(L, prince) && prince.territory.Contains(get_turf(L))

/mob/living/simple_animal/hostile/prince_follower/summon/proc/NearestFoeInside()
	var/mob/living/best
	for(var/mob/living/L as anything in prince.FoesInside())
		if(!best || get_dist(src, L) < get_dist(src, best))
			best = L
	return best

/// Follows a map to its quarry. The map's goal only moves once they are more than 2 tiles from it, so a quarry on the
/// move does not remap it every tick. Unreachable, it tries another Foe next tick. Rides when that is shorter.
/mob/living/simple_animal/hostile/prince_follower/summon/proc/Hunt()
	if(RideToward(quarry))
		return
	var/turf/goal = flow?.goal
	if(!goal || get_dist(goal, quarry) > 2)
		goal = get_turf(quarry)
	if(FlowTo(goal))
		// there, and still no sight of them: map to where they stand now
		flow = null
	else if(flow_failed)
		SetQuarry(null)

/// Walks back to him or the nearest of his nurseries, and is gone once it gets there, or straight away if there is no
/// way back.
/mob/living/simple_animal/hostile/prince_follower/summon/proc/GoHome()
	if(FlowTo(get_turf(prince.NodeNear(src))) || flow_failed)
		qdel(src)

/// Heads for the node nearest it when riding from there to the node nearest A saves ride_margin tiles of walking,
/// and boards once beside it. FALSE if walking is as good.
/mob/living/simple_animal/hostile/prince_follower/summon/proc/RideToward(atom/A)
	var/atom/board = prince.NodeNear(src)
	var/obj/structure/prince_nursery/alight = prince.NodeNear(A)
	if(board == alight || !istype(alight))
		return FALSE
	if(get_dist(src, board) + get_dist(alight, A) + prince.ride_margin > get_dist(src, A))
		return FALSE
	if(get_dist(src, board) <= 1)
		StopFlow()
		prince.Ride(list(src), board, alight)
		return TRUE
	if(!FlowTo(get_turf(board)) && flow_failed)
		return FALSE
	return TRUE

/mob/living/simple_animal/hostile/prince_follower/summon/ranged
	name = "gilded twiglet"
	desc = "A gold skull sits on its shoulders, and its mouth never closes."
	icon_state = "twiglet_large_b"
	icon_living = "twiglet_large_b"
	maxHealth = 100
	health = 100
	melee_damage_lower = 4
	melee_damage_upper = 6
	ranged = TRUE
	ranged_cooldown_time = 3 SECONDS
	retreat_distance = 3
	minimum_distance = 3
	projectiletype = /obj/projectile/prince_spit
	projectilesound = 'sound/effects/splat.ogg'

/obj/projectile/prince_spit
	name = "green spit"
	icon_state = "neurotoxin"
	damage = 8
	damage_type = BLACK_DAMAGE

/// His spit, tower shots included, never hits him or his own: it flies through them, so the front line is safe.
/obj/projectile/prince_spit/can_hit_target(atom/target, direct_target = FALSE, ignore_loc = FALSE, cross_failed = FALSE)
	if(PrinceHousehold(target))
		return FALSE
	return ..()

/obj/projectile/prince_spit/prehit_pierce(atom/A)
	if(PrinceHousehold(A))
		return PROJECTILE_PIERCE_PHASE
	return ..()

/// The Prince or one of his followers.
/proc/PrinceHousehold(atom/A)
	return istype(A, /mob/living/simple_animal/hostile/prince_follower) || istype(A, /mob/living/simple_animal/hostile/distortion/advanced/prince)
