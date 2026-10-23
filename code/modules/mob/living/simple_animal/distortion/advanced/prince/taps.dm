// Taps. He holds a few vending machines near his fort, 2 and 2 more per stage, the nearest by walking first. Harvesters grow a
// tap site over each; the finished tap seals the machine, and harvesters draw its stock out a few items at a time
// and carry it to him to eat. Hitting a tap or a tap site makes you a Foe of the Prince.

/mob/living/simple_animal/hostile/distortion/advanced/prince
	/// Each machine he holds, with the tap site or tap on it.
	var/list/held_machines = list()
	/// Machines he will not take before the time given: broken free (for reclaim_delay) or emptied (never again).
	var/list/lost_machines = list()
	var/reclaim_delay = 3 MINUTES
	/// Harvesters drawing from one tap before the rest go to the fort instead.
	var/drawers_per_tap = 2
	/// With no machine to take, he looks again only this often, rather than every think.
	var/machine_scan_interval = 10 SECONDS
	var/next_machine_scan = 0
	/// Only machines within this many tiles of a turf his territory has claimed are taken; none nearer, none at all.
	var/machine_reach = 10
	/// How far from him the flood fill looks for machines, and whether one is running now.
	var/machine_scan_range = 60
	var/machine_scanning = FALSE
	/// He only plays the eating animation this often, however many loads come in.
	var/next_eat_animation = 0

/// Takes machines until he holds MachineCap() of them. Finding them is a flood fill, so it runs off the think.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/TakeMachines()
	for(var/obj/machinery/vending/V as anything in lost_machines)
		if(QDELETED(V))
			lost_machines -= V
	if(machine_scanning || world.time < next_machine_scan || length(held_machines) >= MachineCap())
		return
	ScanMachines()

/// Floods out from him over the ground his followers can walk, gates included, nearest first, and takes each stocked
/// machine near his territory (see NearTerritory()) that it comes up beside, until he holds enough. A machine behind
/// a wall is only as near as the walk round it. Gives up at machine_scan_range tiles, and with too few found, tries
/// again machine_scan_interval later.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/ScanMachines()
	set waitfor = FALSE
	machine_scanning = TRUE
	var/list/wanted = list()
	for(var/obj/machinery/vending/V in GLOB.machines)
		if(V.z == z && !held_machines[V] && lost_machines[V] <= world.time && PrinceStocked(V) && NearTerritory(get_turf(V)))
			wanted[get_turf(V)] = V
	// gates only open to a follower, so one stands in for the household
	var/mob/living/simple_animal/hostile/prince_follower/requester = length(harvesters) ? harvesters[1] : null
	var/obj/item/card/id/card = requester?.access_card
	var/turf/start = get_turf(src)
	var/list/reached = list()
	reached[start] = TRUE
	var/list/queue = list(start)
	var/i = 1
	while(length(wanted) && i <= length(queue) && length(held_machines) < MachineCap())
		var/turf/T = queue[i]
		i++
		for(var/d in GLOB.alldirs)
			var/turf/N = get_step(T, d)
			if(!N)
				continue
			var/obj/machinery/vending/V = wanted[N]
			if(V)
				wanted -= N
				TakeMachine(V)
				continue
			if(reached[N] || get_dist(N, start) > machine_scan_range || !PrinceFlowStep(T, d, requester, card))
				continue
			reached[N] = TRUE
			queue += N
		if(!(i % 300))
			CHECK_TICK
			if(QDELETED(src) || torn_down)
				return
	machine_scanning = FALSE
	if(length(held_machines) < MachineCap())
		next_machine_scan = world.time + machine_scan_interval

/// Whether a turf his territory has claimed lies within machine_reach tiles of T.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/NearTerritory(turf/T)
	for(var/turf/X as anything in RANGE_TURFS(machine_reach, T))
		if(territory.Contains(X))
			return TRUE
	return FALSE

/// Puts a tap site on V, if it is still his to take.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/TakeMachine(obj/machinery/vending/V)
	if(QDELETED(V) || held_machines[V] || !PrinceStocked(V))
		return
	var/obj/structure/prince_site/tap/S = new(get_turf(V), src, null, "tap", V)
	if(QDELETED(S))
		lost_machines[V] = world.time + reclaim_delay
		return
	Own(S)
	held_machines[V] = S
	PlanRoute(V)

/// A machine's site or tap is gone. Its slot frees now; he will not take it again before until.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/MachineLost(obj/machinery/vending/V, until)
	held_machines -= V
	DropRoute(V)
	if(until)
		lost_machines[V] = until

/// A tap site on V was grown: the tap takes its place.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/TapGrown(obj/structure/prince_site/tap/S)
	var/obj/machinery/vending/V = S.machine
	var/obj/structure/prince_tap/tap = new(get_turf(S), src, V)
	S.completed = TRUE
	qdel(S)
	if(QDELETED(tap))
		MachineLost(V, world.time + reclaim_delay)
		return
	Own(tap)
	held_machines[V] = tap
	DrawPaths()

/// Eats a harvester's load: everything in it is gone.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/Eat(list/items)
	for(var/obj/item/I as anything in items)
		qdel(I)
	items.Cut()
	if(world.time < next_eat_animation)
		return
	next_eat_animation = world.time + 3 SECONDS
	flick("prince_slug_out", src)
	addtimer(CALLBACK(src, PROC_REF(EndEatAnimation)), 1 SECONDS)
	playsound(src, 'sound/items/eatfood.ogg', 40, TRUE)

/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/EndEatAnimation()
	flick("prince_slug_in", src)

/// Whether a vending machine has anything left to give.
/proc/PrinceStocked(obj/machinery/vending/V)
	for(var/datum/data/vending_product/R in V.product_records)
		if(R.amount > 0 && R.product_path)
			return TRUE
	return FALSE

// The tap site: a site like the fort's, but on a machine, breakable, and finished by him rather than a ring.

/obj/structure/prince_site/tap
	name = "half-grown root tap"
	desc = "Roots are creeping over the machine, feeling for the slot."
	// over the machine, so clicks on the tile reach it
	layer = ABOVE_OBJ_LAYER
	max_integrity = 50
	resistance_flags = NONE
	/// The machine it is growing over.
	var/obj/machinery/vending/machine
	/// Set when it became a tap, so its deletion does not count as the machine being lost.
	var/completed = FALSE

/obj/structure/prince_site/tap/Initialize(mapload, new_prince, new_ring, new_kind, obj/machinery/vending/new_machine)
	machine = new_machine
	// sits on the machine where it is drawn, wall-mounted ones included
	if(machine)
		pixel_x = machine.pixel_x
		pixel_y = machine.pixel_y
	. = ..()
	if(!machine)
		return INITIALIZE_HINT_QDEL
	RegisterSignal(machine, COMSIG_PARENT_QDELETING, PROC_REF(OnMachineDeleted))

/obj/structure/prince_site/tap/Destroy()
	if(machine)
		UnregisterSignal(machine, COMSIG_PARENT_QDELETING)
		if(!completed && prince && !prince.torn_down)
			prince.MachineLost(machine, world.time + prince.reclaim_delay)
	machine = null
	return ..()

/obj/structure/prince_site/tap/proc/OnMachineDeleted(datum/source)
	SIGNAL_HANDLER
	prince?.MachineLost(machine)
	UnregisterSignal(machine, COMSIG_PARENT_QDELETING)
	machine = null
	qdel(src)

/obj/structure/prince_site/tap/Complete()
	prince?.TapGrown(src)

/obj/structure/prince_site/tap/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	prince?.MakeFoe(user)

/obj/structure/prince_site/tap/bullet_act(obj/projectile/P)
	. = ..()
	prince?.MakeFoe(P.firer)

/obj/structure/prince_site/tap/attack_animal(mob/living/simple_animal/M)
	. = ..()
	prince?.MakeFoe(M)

// The tap. It stands on the machine's tile and seals it: the machine refuses hands and items while it stands, with
// no change to the vending code. It withers when the machine is empty, and breaking it frees the machine.

/obj/structure/prince_tap
	name = "root tap"
	desc = "Roots have grown over the machine and boarded it shut. One of them is plunged into the slot."
	icon = 'ModularLobotomy/_Lobotomyicons/prince_structures.dmi'
	icon_state = "tap"
	anchored = TRUE
	density = FALSE
	layer = ABOVE_OBJ_LAYER
	max_integrity = 750
	var/mob/living/simple_animal/hostile/distortion/advanced/prince/prince
	var/obj/machinery/vending/machine
	/// The machine's interaction flags before it was sealed, put back when the tap goes.
	var/old_interaction_flags
	/// Set when the machine ran dry, so he never takes it again.
	var/withered = FALSE
	/// No harvester tries for it again before this, after one found no way to it.
	var/unreachable_until = 0

/obj/structure/prince_tap/Initialize(mapload, new_prince, obj/machinery/vending/new_machine)
	. = ..()
	prince = new_prince
	machine = new_machine
	if(!machine)
		return INITIALIZE_HINT_QDEL
	pixel_x = machine.pixel_x
	pixel_y = machine.pixel_y
	Seal()

/obj/structure/prince_tap/Destroy()
	if(machine && prince && !prince.torn_down)
		prince.MachineLost(machine, withered ? INFINITY : world.time + prince.reclaim_delay)
	Unseal()
	prince = null
	return ..()

/obj/structure/prince_tap/proc/Seal()
	old_interaction_flags = machine.interaction_flags_atom
	machine.interaction_flags_atom &= ~(INTERACT_ATOM_ATTACK_HAND | INTERACT_ATOM_UI_INTERACT)
	SStgui.close_uis(machine)
	RegisterSignal(machine, COMSIG_PARENT_ATTACKBY, PROC_REF(RefuseItem))
	RegisterSignal(machine, COMSIG_PARENT_QDELETING, PROC_REF(OnMachineDeleted))

/obj/structure/prince_tap/proc/Unseal()
	if(!machine)
		return
	machine.interaction_flags_atom = old_interaction_flags
	UnregisterSignal(machine, list(COMSIG_PARENT_ATTACKBY, COMSIG_PARENT_QDELETING))
	machine = null

/obj/structure/prince_tap/proc/RefuseItem(datum/source, obj/item/I, mob/user)
	SIGNAL_HANDLER
	to_chat(user, span_warning("The roots have [source] shut."))
	return COMPONENT_NO_AFTERATTACK

/obj/structure/prince_tap/proc/OnMachineDeleted(datum/source)
	SIGNAL_HANDLER
	prince?.MachineLost(machine)
	UnregisterSignal(machine, list(COMSIG_PARENT_ATTACKBY, COMSIG_PARENT_QDELETING))
	machine = null
	qdel(src)

/// Takes up to count items out of the machine's stock onto its turf. Withers once the stock is gone.
/obj/structure/prince_tap/proc/Draw(count)
	. = list()
	if(!machine)
		return
	for(var/datum/data/vending_product/R in shuffle(machine.product_records))
		while(count > 0 && R.amount > 0 && R.product_path)
			R.amount--
			count--
			. += new R.product_path(get_turf(src))
		if(count <= 0)
			break
	if(!PrinceStocked(machine))
		withered = TRUE
		visible_message(span_notice("[src] withers away from the empty machine."))
		qdel(src)

/obj/structure/prince_tap/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	prince?.MakeFoe(user)

/obj/structure/prince_tap/bullet_act(obj/projectile/P)
	. = ..()
	prince?.MakeFoe(P.firer)

/obj/structure/prince_tap/attack_animal(mob/living/simple_animal/M)
	. = ..()
	prince?.MakeFoe(M)
