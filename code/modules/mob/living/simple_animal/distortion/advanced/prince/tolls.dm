// Toll gates. Past his two rings he holds the streets instead: from stage 2 on, tolls_per_stage for each stage past
// the first, on his ground or within toll_reach of him. Each closes a corridor exactly three tiles wide: a wall, a toll gate in the middle, a wall, a watchtower
// one step out in front of each wall, and a nursery behind one of them, which his summons can travel to (see
// nursery.dm). They are laid out as sites for the harvesters, after the rings. Anyone not a Foe may pay to go through.

/mob/living/simple_animal/hostile/distortion/advanced/prince
	/// His toll gates, each a ring of its own, nearest first.
	var/list/tolls = list()
	var/tolls_per_stage = 2
	/// A search that finds no corridor is tried again this much later.
	var/toll_retry = 60 SECONDS
	var/next_toll_search = 0
	var/toll_searching = FALSE
	/// Two toll gates stand at least this far apart.
	var/toll_spacing = 8
	/// How far from him a toll gate may stand, on his ground or off it, and most turfs one search walks.
	var/toll_reach = 40
	var/toll_search_max = 8000
	/// Rows of plain corridor a toll gate needs ahead of it and behind it.
	var/toll_clearance = 2

/// tolls_per_stage for each stage past the first.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/TollCap()
	return tolls_per_stage * max(0, territory.stage - 1)

/// Plans toll gates until he has TollCap(), or no corridor is left for one. It searches, so it runs off the caller.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/BuildTolls()
	set waitfor = FALSE
	if(toll_searching)
		return
	toll_searching = TRUE
	while(length(tolls) < TollCap())
		var/list/new_plan = FindTollSpot()
		if(QDELETED(src) || torn_down)
			return
		if(!new_plan)
			break
		tolls += new /datum/prince_ring/toll(src, new_plan)
	toll_searching = FALSE
	next_toll_search = world.time + toll_retry

/// Walks out from him up to toll_reach tiles, on his ground or off it, nearest first, to the first corridor a toll
/// gate fits across, and returns its plan. It walks through his rings, but not past a toll gate, so one corridor never gets two. A gate faces away
/// from the ground already walked. Null if none fits.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/FindTollSpot()
	var/turf/start = get_turf(src)
	var/outer = ring_first + (max_rings - 1) * ring_step
	var/list/taken = list()
	for(var/datum/prince_ring/R as anything in rings)
		for(var/turf/T as anything in R.plan)
			taken[T] = TRUE
	var/list/tolled = list()
	for(var/datum/prince_ring/R as anything in tolls)
		for(var/turf/T as anything in R.plan)
			taken[T] = TRUE
			tolled[T] = TRUE
	var/list/walked = list()
	walked[start] = TRUE
	var/list/queue = list(start)
	var/i = 1
	while(i <= length(queue) && length(queue) < toll_search_max)
		var/turf/from = queue[i++]
		// clear of the rings, with room for the towers in front of it
		if(get_dist(start, from) >= outer + 3)
			for(var/out in GLOB.cardinals)
				if(!walked[get_step(from, turn(out, 180))])
					continue
				var/list/found = TollAt(from, out, taken)
				if(found)
					return found
		for(var/step_dir in GLOB.cardinals)
			var/turf/T = get_step(from, step_dir)
			if(!T || walked[T] || tolled[T] || get_dist(start, T) > toll_reach || !PrinceWalkable(from, T))
				continue
			walked[T] = TRUE
			queue += T
		if(!(i % 300))
			CHECK_TICK
	return null

/// The plan for a toll gate on middle, facing out, or null if it does not fit. The corridor must run toll_clearance
/// rows ahead of and behind the gate's row, every row three clear turfs between real walls, so a gate never stands at
/// an opening. Walls either side of the gate, towers in front of the walls, the nursery behind one of them.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/TollAt(turf/middle, out, list/taken)
	var/back = turn(out, 180)
	var/list/sides = list(turn(out, 90), turn(out, -90))
	for(var/row in -toll_clearance to toll_clearance)
		var/turf/mid = row ? get_ranged_target_turf(middle, row > 0 ? out : back, abs(row)) : middle
		if(!TollSpot(mid, taken))
			return null
		for(var/side in sides)
			var/turf/beside = get_step(mid, side)
			if(!TollSpot(beside, taken))
				return null
			// walls of the city, not furniture or windows
			var/turf/past = get_step(beside, side)
			if(!past || !isclosedturf(past))
				return null
	for(var/datum/prince_ring/toll/other as anything in tolls)
		if(get_dist(middle, other.gate) < toll_spacing)
			return null
	var/list/new_plan = list()
	new_plan[middle] = "toll"
	for(var/side in sides)
		var/turf/beside = get_step(middle, side)
		new_plan[beside] = "wall"
		new_plan[get_step(beside, out)] = "tower"
	new_plan[get_step(get_step(middle, sides[1]), back)] = "nursery"
	return new_plan

/// Clear open ground that no ring or toll gate already uses: nothing solid on it, so no piece is built over a
/// structure.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/TollSpot(turf/T, list/taken)
	return PrinceGround(T) && !taken[T] && !T.is_blocked_turf(TRUE)

// A toll gate's plan, kept and built like a ring's: sites for the harvesters, and a site again when a piece breaks.

/datum/prince_ring/toll
	/// The turfs of its toll gate and its nursery.
	var/turf/gate
	var/turf/nest

/datum/prince_ring/toll/New(new_prince, list/new_plan)
	plan = new_plan
	for(var/turf/T as anything in plan)
		if(plan[T] == "toll")
			gate = T
		else if(plan[T] == "nursery")
			nest = T
	. = ..(new_prince, 0)
	// a trail from him to the nursery, a thread until it stands
	prince.PlanTollRoute(src)

/datum/prince_ring/toll/Destroy()
	gate = null
	nest = null
	return ..()

/// The nursery's trail is laid once it stands, and goes back to a thread while it regrows.
/datum/prince_ring/toll/Track(turf/T, atom/movable/piece)
	. = ..()
	if(T == nest && prince && !prince.torn_down)
		prince.DrawPaths()

/// Planned when found, not from a square.
/datum/prince_ring/toll/Plan()
	return

// The toll gate itself. His own pass for free; anyone else not a Foe offers it toll ahn, and it lets them through for
// pass_time. The money goes to him.

/obj/structure/prince_fort/gate/toll
	name = "toll gate"
	desc = "A root gate lacquered red, with a gold coin over it and a slot in the coin just wide enough for a bill. A toll is paid here."
	icon_state = "toll"
	base_state = "toll"
	// a warm glow, so it reads as a place to pay from down the street
	light_range = 2
	light_power = 0.8
	light_color = "#f0c440"
	/// What it takes, in ahn.
	var/toll = 50
	/// How long it lets a payer through for.
	var/pass_time = 10 SECONDS
	/// Who paid, and until when they may pass.
	var/list/paid = list()

/obj/structure/prince_fort/gate/toll/Destroy()
	paid.Cut()
	return ..()

/obj/structure/prince_fort/gate/toll/SnapHint()
	return " The gold coin above it gleams: it wants [toll] ahn."

/obj/structure/prince_fort/gate/toll/PassNote()
	return "His own pass for free. Anyone else uses [toll] ahn on it, cash or a holochip, to pass for [DisplayTimeText(pass_time)]. It will not take a Foe's money."

/obj/structure/prince_fort/gate/toll/LetsThrough(atom/movable/AM)
	return ..() || paid[AM] > world.time

/obj/structure/prince_fort/gate/toll/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(paid[mover] > world.time)
		return TRUE

/// Money is offered, not swung. Anything else is an attack as usual.
/obj/structure/prince_fort/gate/toll/attackby(obj/item/I, mob/living/user, params)
	if(!istype(I, /obj/item/stack/spacecash) && !istype(I, /obj/item/holochip))
		return ..()
	Pay(I, user)
	return TRUE

/obj/structure/prince_fort/gate/toll/proc/Pay(obj/item/money, mob/living/user)
	if(!risen)
		to_chat(user, span_warning("It has not finished growing."))
		return
	if(prince && PrinceFoe(user, prince))
		to_chat(user, span_warning("The slot clamps shut. It will not take a Foe's money."))
		return
	if(!TakeToll(money, user))
		to_chat(user, span_warning("That is not enough. It wants [toll] ahn."))
		return
	for(var/mob/payer as anything in paid)
		if(paid[payer] <= world.time)
			paid -= payer
	paid[user] = world.time + pass_time
	playsound(src, 'sound/effects/cashregister.ogg', 30, TRUE)
	to_chat(user, span_notice("The slot swallows the money, and the gate's leaves part for you."))
	Open()

/// Takes toll from money, handing back change for a bill worth more. FALSE if there is not enough.
/obj/structure/prince_fort/gate/toll/proc/TakeToll(obj/item/money, mob/living/user)
	if(istype(money, /obj/item/holochip))
		var/obj/item/holochip/chip = money
		return chip.spend(toll) > 0
	var/obj/item/stack/spacecash/cash = money
	if(!cash.value || cash.get_item_credit_value() < toll)
		return FALSE
	var/bills = CEILING(toll / cash.value, 1)
	var/change = bills * cash.value - toll
	cash.use(bills)
	if(change)
		user.put_in_hands(new /obj/item/stack/spacecash/c1(get_turf(user), change))
	return TRUE
