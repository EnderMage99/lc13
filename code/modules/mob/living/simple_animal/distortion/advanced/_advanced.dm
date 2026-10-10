// The shared base for territory distortions. New distortions subtype this.
/mob/living/simple_animal/hostile/distortion/advanced
	name = "advanced distortion"
	desc = "The shape of someone's heart, settling into the place around it."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "lantern"
	maxHealth = 1000
	health = 1000
	melee_damage_lower = 10
	melee_damage_upper = 15
	melee_damage_type = RED_DAMAGE
	obj_damage = 50
	/// Off: the stock patrol paths without the card. Wander() does the roaming instead.
	can_patrol = FALSE
	/// The ground it has claimed. Made in Initialize(), reverted in Teardown().
	var/datum/distortion_territory/territory
	/// Territory datum to create; a subtype swaps in its own.
	var/territory_type = /datum/distortion_territory
	/// Turfs claimed at spawn, about one alleyway room.
	var/territory_start_size = 25
	/// How often the territory grows. It never stops until the source does.
	var/territory_growth_interval = 60 SECONDS
	/// Most turfs it may ever hold, roughly a fifth of the city map's open turfs.
	var/territory_cap = 2000
	/// Growth per tick as this divided by the square root of the size: fast at first, always slowing. Null grows
	/// by 15% of the size instead. See the territory's GrowthAmount() for how long a value takes to reach the cap.
	var/territory_growth_rate
	/// Claimed sizes at which stages 1 to 3 begin; stage 4 is the cap. Null uses the territory's own.
	var/list/territory_stages
	/// Stage at which ApplyCenterEffects() first runs. It runs again on every stage after, on a larger set.
	var/gimmick_stage = 2
	/// Area types the territory may claim, with subtypes. Empty means anywhere.
	var/list/territory_areas
	/// Temporary visuals the territory plays on random claimed turfs near players. The shared ones are at the end of this file.
	var/list/oddities = list(
		/obj/effect/temp_visual/distortion_oddity/shade,
		/obj/effect/temp_visual/distortion_oddity/skitter,
		/obj/effect/temp_visual/distortion_oddity/paper,
		/obj/effect/temp_visual/distortion_oddity/fog,
	)
	/// Shows the claimed turfs with coloured overlays. Testing only.
	var/territory_debug = TRUE
	/// Roams to random turfs inside its territory. FALSE for place-like distortions that stand still.
	var/wanders = TRUE
	/// Time spent standing at each wander destination.
	var/wander_pause = 8 SECONDS
	/// Turns back when it strays too far outside the territory.
	var/leashed = TRUE
	/// Turfs past the edge it may go before turning back.
	var/leash_slack = 7
	/// How long it stands still before heading home.
	var/return_pause = 3 SECONDS
	/// TRUE: ignores attacks while returning. FALSE: fights a living attacker, then resumes once they are down.
	var/hard_return = FALSE
	/// Mobs a faction-friendly distortion will fight anyway. See Provoke().
	var/list/provoked_by = list()
	/// How often Notice() may run for the same human.
	var/notice_cooldown = 5 SECONDS
	/// Last claimed turf it stood on; the return destination.
	var/turf/leash_exit
	/// Set while it is heading home.
	var/returning = FALSE
	/// Set while an attack has pulled it out of a return; the leash waits for the fight to end.
	var/return_interrupted = FALSE
	var/next_return_attempt = 0
	var/list/noticed = list()
	/// Everything spawned that must go when the distortion does. Add to it with Own().
	var/list/owned = list()
	/// Set once Teardown() has run so a death followed by a Destroy() does not run it twice.
	var/torn_down = FALSE

/mob/living/simple_animal/hostile/distortion/advanced/Initialize(mapload)
	. = ..()
	// access_card is the simple_animal var the bots use; with every access the pathfinder plans through any door
	access_card = new(src)
	access_card.access = get_all_accesses()
	patrol_cooldown_time = wander_pause
	var/turf/origin = NearestOpenTurf(get_turf(src))
	if(!origin)
		return INITIALIZE_HINT_QDEL
	territory = new territory_type(src, origin)
	territory.debug = territory_debug
	territory.Claim(territory_start_size)
	territory.StartGrowing(territory_growth_interval)

/// Spawn-anywhere fallback: the turf itself if open, otherwise the closest open turf within 3.
/mob/living/simple_animal/hostile/distortion/advanced/proc/NearestOpenTurf(turf/T)
	if(!T)
		return null
	if(!T.density)
		return T
	for(var/i in 1 to 3)
		for(var/turf/candidate in RANGE_TURFS(i, T))
			if(!candidate.density)
				return candidate
	return null

/mob/living/simple_animal/hostile/distortion/advanced/death(gibbed)
	Teardown()
	return ..()

/mob/living/simple_animal/hostile/distortion/advanced/Destroy()
	Teardown()
	return ..()

/// Removes everything the distortion made. Safe to call more than once.
/// Anything a subtype spawns goes through Own() so this is the only cleanup it needs.
/mob/living/simple_animal/hostile/distortion/advanced/proc/Teardown()
	if(torn_down)
		return
	torn_down = TRUE
	ConsumeStoredHuman()
	QDEL_NULL(territory)
	for(var/atom/thing in owned)
		qdel(thing)
	owned.Cut()
	noticed.Cut()
	provoked_by.Cut()
	QDEL_NULL(access_card)

/// Adds a spawned thing to owned so Teardown() removes it. It leaves the list by itself if deleted sooner.
/mob/living/simple_animal/hostile/distortion/advanced/proc/Own(atom/movable/thing)
	// a cleanable can merge into one already on the turf and be gone on arrival
	if(QDELETED(thing))
		return
	owned += thing
	RegisterSignal(thing, COMSIG_PARENT_QDELETING, PROC_REF(OnOwnedDeleted))

/mob/living/simple_animal/hostile/distortion/advanced/proc/OnOwnedDeleted(datum/source)
	SIGNAL_HANDLER
	owned -= source

/// A human stored inside by BecomeDistortion() does not survive the distortion's death
/mob/living/simple_animal/hostile/distortion/advanced/proc/ConsumeStoredHuman()
	var/turf/T = get_turf(src)
	for(var/mob/living/carbon/human/person in src)
		if(T)
			person.forceMove(T)
		person.unequip_everything()
		qdel(person)

/// The territory took a turf. Per-distortion claim effects go here.
/mob/living/simple_animal/hostile/distortion/advanced/proc/OnTurfClaimed(turf/T)
	return

/// The territory crossed a size threshold. Stages run 0 to 4.
/mob/living/simple_animal/hostile/distortion/advanced/proc/OnStageChange(old_stage, new_stage)
	return

/// The territory finished a growth tick. For effects that follow its shape as it spreads.
/mob/living/simple_animal/hostile/distortion/advanced/proc/OnTerritoryGrown()
	return

/// Called by the territory after OnStageChange(). From gimmick_stage on, hands the centre to ApplyCenterEffects():
/// the first start_size turfs at gimmick_stage, four times as many at each stage after.
/mob/living/simple_animal/hostile/distortion/advanced/proc/UpdateCenter(new_stage)
	if(new_stage < gimmick_stage)
		return
	var/count = territory_start_size * (4 ** (new_stage - gimmick_stage))
	ApplyCenterEffects(territory.CenterTurfs(count))

/// The middle of the territory visibly becomes this distortion's own thing.
/mob/living/simple_animal/hostile/distortion/advanced/proc/ApplyCenterEffects(list/turfs)
	return

/// Opens doors, breaks anything breakable in the way (doors that will not open included), and while wandering
/// passes straight through mobs.
/mob/living/simple_animal/hostile/distortion/advanced/Bump(atom/A)
	if(isliving(A) && !target && !client && length(patrol_path))
		forceMove(get_turf(A))
		return
	if(istype(A, /obj/machinery/door))
		var/obj/machinery/door/D = A
		if(D.operating)
			return
		if(D.density && D.open())
			return
	if(isobj(A))
		var/obj/O = A
		if(O.density && !(O.resistance_flags & INDESTRUCTIBLE))
			O.attack_animal(src)
			return
	return ..()

/// The pathfinder's step test, with breakable dense objects and doors the card opens allowed through, since Bump()
/// will clear them. Airlocks and window doors already check the card in their own CanAStarPass().
/turf/proc/DistortionReachable(requester, turf/T, ID, simulated_only)
	if(!T || T.density || (simulated_only && SSpathfinder.space_type_cache[T.type]))
		return FALSE
	var/rdir = get_dir(T, src)
	for(var/obj/O in T)
		if(O.CanAStarPass(ID, rdir, requester))
			continue
		if(!(O.resistance_flags & INDESTRUCTIBLE))
			continue
		if(istype(O, /obj/machinery/door) && !istype(O, /obj/machinery/door/airlock) && !istype(O, /obj/machinery/door/window))
			var/obj/machinery/door/D = O
			if(D.check_access(ID))
				continue
		return FALSE
	return TRUE

/// The stock patrol_to() with the card passed, so the path may run through doors. Walks with the stock patrol_move().
/mob/living/simple_animal/hostile/distortion/advanced/proc/WalkTo(turf/destination)
	patrol_reset()
	patrol_path = get_path_to(src, destination, TYPE_PROC_REF(/turf, Distance_cardinal), 0, 200, adjacent = TYPE_PROC_REF(/turf, DistortionReachable), id = access_card)
	if(!length(patrol_path))
		return FALSE
	patrol_move(patrol_path[patrol_path.len])
	return TRUE

// Wander. Walks to a random claimed turf once idle, wander_pause after the last walk ended.
/mob/living/simple_animal/hostile/distortion/advanced/proc/Wander()
	if(!wanders || returning || length(patrol_path) || !CanStartPatrol())
		return
	// the distortion parent's CanStartPatrol() leaves out the stock cooldown test, which is what makes wander_pause apply
	if(patrol_cooldown > world.time)
		return
	if(SSmaptype.maptype in SSmaptype.autopossess)
		return
	WalkTo(territory.RandomTurf())

// Leash. It may chase and roam a little past the edge, then it stops, turns round and walks back
// to the turf it left by. Being hit on the way pulls it into a fight unless hard_return is set.
/mob/living/simple_animal/hostile/distortion/advanced/Life()
	. = ..()
	if(stat == DEAD || client)
		return
	if(territory.Contains(loc))
		leash_exit = loc
		if(returning)
			EndReturn()
		return_interrupted = FALSE
		NoticeNearby()
	else if(returning)
		if(!length(patrol_path) && world.time > next_return_attempt)
			WalkHome()
		return
	else if(leashed && leash_exit && !(return_interrupted && target) && get_dist(src, leash_exit) > leash_slack)
		StartReturn()
		return
	Wander()

/mob/living/simple_animal/hostile/distortion/advanced/proc/StartReturn()
	returning = TRUE
	return_interrupted = FALSE
	LoseTarget()
	patrol_reset()
	next_return_attempt = world.time + return_pause

/// Paths to the exit turf, or to any claimed turf if that fails, and tries again shortly if neither works.
/mob/living/simple_animal/hostile/distortion/advanced/proc/WalkHome()
	next_return_attempt = world.time + 5 SECONDS
	if(WalkTo(leash_exit))
		return
	WalkTo(territory.RandomTurf())

/mob/living/simple_animal/hostile/distortion/advanced/proc/EndReturn()
	returning = FALSE
	patrol_reset()

/// This is called when a living attacker hits the distortion while it is returning. It stops the return and provokes the attacker.
/mob/living/simple_animal/hostile/distortion/advanced/proc/InterruptReturn(mob/living/attacker)
	if(!returning || hard_return || !istype(attacker) || attacker.stat > stat_attack)
		return
	returning = FALSE
	return_interrupted = TRUE
	patrol_reset()
	Provoke(attacker)

/mob/living/simple_animal/hostile/distortion/advanced/LoseTarget(stop_movement = TRUE)
	. = ..()
	if(return_interrupted && leashed && territory && !territory.Contains(loc))
		StartReturn()

/mob/living/simple_animal/hostile/distortion/advanced/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	InterruptReturn(user)

/mob/living/simple_animal/hostile/distortion/advanced/bullet_act(obj/projectile/P)
	. = ..()
	if(isliving(P.firer))
		InterruptReturn(P.firer)

/mob/living/simple_animal/hostile/distortion/advanced/attack_animal(mob/living/simple_animal/M, damage)
	. = ..()
	InterruptReturn(M)

/mob/living/simple_animal/hostile/distortion/advanced/attack_hand(mob/living/carbon/human/M)
	. = ..()
	if(M.a_intent == INTENT_HARM)
		InterruptReturn(M)

// Hostility. Passive distortions set faction = list("neutral") and the stock faction check ignores humans;
// Provoke() makes an exception for one person at a time. Notice() is where a passive one reacts to people.
/mob/living/simple_animal/hostile/distortion/advanced/CanAttack(atom/the_target)
	if(returning)
		return FALSE
	. = ..()
	if(.)
		return
	if(!(the_target in provoked_by) || !isliving(the_target))
		return FALSE
	var/mob/living/L = the_target
	return L.stat <= stat_attack

/// Makes `by` a target regardless of faction, and goes for them now if nothing else is being fought.
/mob/living/simple_animal/hostile/distortion/advanced/proc/Provoke(mob/living/by)
	if(!istype(by))
		return
	provoked_by |= by
	if(target || stat == DEAD || AIStatus == AI_OFF || client)
		return
	if(AIStatus == AI_IDLE)
		toggle_ai(AI_ON)
	FindTarget(list(by), 1)

/// Calls Notice() for each human in view that the faction check spares, once per human per notice_cooldown.
/mob/living/simple_animal/hostile/distortion/advanced/proc/NoticeNearby()
	if(stat == DEAD || AIStatus == AI_OFF)
		return
	for(var/mob/living/carbon/human/H in view(vision_range, src))
		if(!faction_check_mob(H) || (H in provoked_by) || H.stat == DEAD)
			continue
		if(noticed[H] > world.time)
			continue
		if(isnull(noticed[H]))
			RegisterSignal(H, COMSIG_PARENT_QDELETING, PROC_REF(OnNoticedDeleted))
		noticed[H] = world.time + notice_cooldown
		Notice(H)

/mob/living/simple_animal/hostile/distortion/advanced/proc/OnNoticedDeleted(datum/source)
	SIGNAL_HANDLER
	noticed -= source

/// A human is nearby and this distortion is not hostile to them. Watching, following, speaking go here.
/mob/living/simple_animal/hostile/distortion/advanced/proc/Notice(mob/living/carbon/human/H)
	return

///Some basic temporary visual effects for distortions to use. For now, they are used as random effects that spawn on the territory's turfs.
/obj/effect/temp_visual/distortion_oddity
	randomdir = FALSE
	layer = ABOVE_OBJ_LAYER
	duration = 3 SECONDS

/// A patch of shadow deepens on the floor and fades again.
/obj/effect/temp_visual/distortion_oddity/shade
	icon = 'icons/turf/areas.dmi'
	icon_state = "dark"
	alpha = 0
	duration = 4 SECONDS

/obj/effect/temp_visual/distortion_oddity/shade/Initialize(mapload)
	. = ..()
	animate(src, alpha = 120, time = duration * 0.4, easing = SINE_EASING)
	animate(alpha = 0, time = duration * 0.6)

/// A small shape darts across the tile and is gone before it can be examined.
/obj/effect/temp_visual/distortion_oddity/skitter
	icon = 'icons/mob/animal.dmi'
	icon_state = "mouse_gray"
	color = "#303030"
	alpha = 180
	duration = 1.2 SECONDS

/obj/effect/temp_visual/distortion_oddity/skitter/Initialize(mapload)
	. = ..()
	var/move_dir = pick(GLOB.cardinals)
	setDir(move_dir)
	var/dx = (move_dir == EAST ? 1 : (move_dir == WEST ? -1 : 0)) * 40
	var/dy = (move_dir == NORTH ? 1 : (move_dir == SOUTH ? -1 : 0)) * 40
	pixel_x = -dx
	pixel_y = -dy
	animate(src, pixel_x = dx, pixel_y = dy, alpha = 0, time = duration, easing = SINE_EASING | EASE_IN)

/// A scrap of paper blows across a couple of tiles and vanishes.
/obj/effect/temp_visual/distortion_oddity/paper
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paper"
	alpha = 200
	duration = 2.5 SECONDS

/obj/effect/temp_visual/distortion_oddity/paper/Initialize(mapload)
	. = ..()
	var/move_dir = pick(GLOB.cardinals)
	var/dx = (move_dir == EAST ? 1 : (move_dir == WEST ? -1 : 0)) * 64
	var/dy = (move_dir == NORTH ? 1 : (move_dir == SOUTH ? -1 : 0)) * 64
	animate(src, pixel_x = dx, pixel_y = dy + 8, time = duration * 0.6, easing = SINE_EASING | EASE_OUT)
	animate(pixel_x = dx * 1.3, pixel_y = dy * 1.3, alpha = 0, time = duration * 0.4)

/// A patch of low mist rolls through and thins out.
/obj/effect/temp_visual/distortion_oddity/fog
	icon = 'icons/effects/96x96.dmi'
	icon_state = "smoke"
	color = "#9aa0a8"
	pixel_x = -32
	pixel_y = -32
	alpha = 0
	layer = ABOVE_MOB_LAYER
	duration = 6 SECONDS

/obj/effect/temp_visual/distortion_oddity/fog/Initialize(mapload)
	. = ..()
	animate(src, alpha = 90, time = duration * 0.4)
	animate(alpha = 0, pixel_x = -32 + rand(-16, 16), time = duration * 0.6)
