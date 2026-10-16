// The den. The nearest turfs to the origin become rock, his spikes stand on them, and three heads on spears watch:
// one of them the person he judged wrong, the only place that name is written. The drag brings the hunted here.

/// The base's centre hook, after every stage change. The den reaches den_radius at spawn and further per stage.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/UpdateCenter(new_stage)
	GrowDen(new_stage)

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/GrowDen(stage)
	if(torn_down)
		return
	ApplyCenterEffects(DenFill(den_radius + den_radius_growth * stage))
	BreakStructures()
	SweepFloor()
	FillSpikes(spikes_base + stage)

/// The den's floor: a flood fill from the origin, cardinal steps through open claimed turfs within radius, never through
/// a closed turf and never through a door, so the rock fills the room he spawned in and no further.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/DenFill(radius)
	var/turf/origin = territory.Center()
	var/list/result = list(origin)
	var/list/seen = list()
	seen[origin] = TRUE
	var/i = 1
	while(i <= result.len)
		var/turf/T = result[i++]
		for(var/dir in GLOB.cardinals)
			var/turf/next = get_step(T, dir)
			if(!next || seen[next] || !isopenturf(next) || get_dist(origin, next) > radius || !territory.Contains(next))
				continue
			seen[next] = TRUE
			if(locate(/obj/machinery/door) in next)
				continue
			result += next
	return result

/// Floors become rock and any wall touching one, corners included, becomes rock, each remembered with what it was.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/ApplyCenterEffects(list/turfs)
	for(var/turf/open/T in turfs)
		if(!converted[T] && !istype(T, floor_type))
			converted[T] = T.type
			T.ChangeTurf(floor_type)
		for(var/dir in GLOB.alldirs)
			var/turf/next = get_step(T, dir)
			if(!next || converted[next] || !isclosedturf(next) || istype(next, wall_type))
				continue
			converted[next] = next.type
			next.ChangeTurf(wall_type)

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/DenTurfs()
	var/list/den = list()
	for(var/turf/T in converted)
		if(istype(T, floor_type))
			den += T
	return den

/// Whatever stood on the den floor that is not his is broken as the rock comes in. Doors of any kind are left.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/BreakStructures()
	for(var/turf/T in DenTurfs())
		for(var/obj/structure/S in T)
			if((S in owned) || istype(S, /obj/structure/mineral_door))
				continue
			S.deconstruct(FALSE)

/// Den floor tiles against a wall and clear of every door, nearest the middle first: where the hooks, the heads
/// and the pile go, so nothing of his stands in a doorway or the middle of the room.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/WallSideTurfs()
	var/list/result = list()
	for(var/turf/T in DenTurfs())
		if(T == territory.Center() || (locate(/obj/machinery/door) in T))
			continue
		var/by_wall = FALSE
		var/by_door = FALSE
		for(var/turf/next in RANGE_TURFS(1, T))
			if(next == T)
				continue
			if(locate(/obj/machinery/door) in next)
				by_door = TRUE
				break
			if(isclosedturf(next) && get_dist(T, next) == 1 && (get_dir(T, next) in GLOB.cardinals))
				by_wall = TRUE
		if(by_wall && !by_door)
			result += T
	return result

/// Everything loose on the den floor is swept to one wall-side tile. Runs with every growth of the den.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/SweepFloor()
	if(!pile_turf)
		var/list/sides = WallSideTurfs()
		pile_turf = sides.len ? sides[sides.len] : null
	if(!pile_turf)
		return
	for(var/turf/T in DenTurfs())
		if(T == pile_turf)
			continue
		for(var/obj/item/I in T)
			if(I.anchored)
				continue
			I.forceMove(pile_turf)

/// Keeps the den at its hook count, one per free wall-side tile, never on the pile.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/FillSpikes(wanted)
	for(var/turf/T in WallSideTurfs())
		if(spikes.len >= wanted)
			return
		if(T == pile_turf || T.is_blocked_turf(exclude_mobs = TRUE))
			continue
		var/obj/structure/kitchenspike/bunnyman/S = new(T, src)
		spikes += S
		Own(S)

// The drag. At hard crit the hitting stops; he picks them up, the way Baroputian carries what it finds, and walks
// home with them over his shoulder. Nothing gets them off him until he sets them on a spike.

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/StartDrag()
	hunt_state = "dragging"
	LoseTarget()
	walk(src, 0)
	patrol_reset()
	hunt_target.remove_status_effect(/datum/status_effect/incapacitating/immobilized)
	PickUp(hunt_target)

/// Into his contents, their appearance drawn over his shoulder. Only if they are within reach.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/PickUp(mob/living/carbon/human/M)
	if(carried)
		return TRUE
	if(!M.Adjacent(src))
		return FALSE
	carried = M
	visible_message(span_danger("[src] hauls [carried] up over one shoulder and turns for home."), ignored_mobs = list(carried))
	to_chat(carried, span_userdanger("You are hauled up over his shoulder. The street goes by upside down."))
	carried.forceMove(src)
	carry_overlay = new /mutable_appearance(carried)
	carry_overlay.pixel_y = 20
	carry_overlay.pixel_x = 16
	carry_overlay.layer = layer + 0.1
	var/matrix/m180 = matrix()
	m180.Turn(180)
	carry_overlay.transform = m180
	add_overlay(carry_overlay)
	return TRUE

/// Sets them down on T, or where he stands. The one way out of his hold, used by the spike, the hunt's end and Teardown().
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/SetDown(turf/T)
	if(!carried)
		return
	cut_overlay(carry_overlay)
	carry_overlay = null
	var/mob/living/carbon/human/H = carried
	carried = null
	H.forceMove(T || get_turf(src))

/// Each tick of the drag. Not yet picked up, he goes to them, dead or alive. On den rock, they go on a spike.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/DragTick()
	if(QDELETED(hunt_target))
		EndHunt()
		return
	if(!PickUp(hunt_target))
		if(!length(patrol_path))
			WalkTo(get_turf(hunt_target))
		return
	if(istype(loc, floor_type))
		SpikeTarget()
		return
	if(!length(patrol_path))
		WalkTo(territory.Center())

/// In the den: onto a free spike, the mark lifted now that they are where he wanted them. With every spike taken he
/// drives a new one into a wall-side tile first; only with no wall left are they set down on the rock. Then the hunt
/// is over, and the next waits hunt_pause.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/SpikeTarget()
	var/mob/living/carbon/human/H = carried
	var/obj/structure/kitchenspike/bunnyman/free = FreeSpike()
	if(!free)
		FillSpikes(spikes.len + 1)
		free = FreeSpike()
	if(free)
		SetDown(get_turf(free))
		free.Spike(H)
		H.remove_status_effect(/datum/status_effect/bunnyman_mark/perpetrator)
	EndHunt()

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/FreeSpike()
	for(var/obj/structure/kitchenspike/bunnyman/S in spikes)
		if(!S.has_buckled_mobs())
			return S
	return null

/// His meat spike. Nobody is hurt by it, nobody gets off it alone, nobody takes it apart. Another person can pull
/// someone free with the stock 30 s hold. Someone who dies on it loses their head to a pike on the same tile.
/obj/structure/kitchenspike/bunnyman
	name = "meat hook"
	desc = "A butcher's hook, driven into the rock. Something has hung here before."
	var/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/distortion

/obj/structure/kitchenspike/bunnyman/Initialize(mapload, new_distortion)
	. = ..()
	distortion = new_distortion

/obj/structure/kitchenspike/bunnyman/Destroy()
	distortion = null
	return ..()

/obj/structure/kitchenspike/bunnyman/crowbar_act(mob/living/user, obj/item/I)
	to_chat(user, span_warning("It is driven too deep into the rock."))
	return TRUE

/obj/structure/kitchenspike/bunnyman/deconstruct(disassembled)
	return

/obj/structure/kitchenspike/bunnyman/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	if(distortion)
		distortion.OnThingAttacked(src, user)

/obj/structure/kitchenspike/bunnyman/bullet_act(obj/projectile/P)
	. = ..()
	if(distortion)
		distortion.OnThingAttacked(src, P.firer)

/// Broken by damage: whoever did it is marked if he saw, and it is gone, anyone on it let down.
/obj/structure/kitchenspike/bunnyman/obj_destruction(damage_flag)
	if(distortion)
		distortion.OnThingBroken(src)
	qdel(src)

/// Only he puts people on it. Anyone else can only pull someone off.
/obj/structure/kitchenspike/bunnyman/attack_hand(mob/user)
	if(has_buckled_mobs())
		for(var/mob/living/L in buckled_mobs)
			user_unbuckle_mob(L, user)
		return
	to_chat(user, span_notice("It is not yours to use."))

/obj/structure/kitchenspike/bunnyman/user_unbuckle_mob(mob/living/buckled_mob, mob/living/carbon/human/user)
	if(buckled_mob == user)
		to_chat(user, span_warning("You cannot get yourself off it. Someone else will have to."))
		return
	if(distortion)
		distortion.OnUnhookTried(src, user)
	. = ..()
	if(!buckled_mob.buckled && distortion)
		distortion.OnUnhooked(src, user, buckled_mob)

/// Up and on, no blood. Whatever the hunt did to them is mended: the den is a prison, not an execution.
/obj/structure/kitchenspike/bunnyman/proc/Spike(mob/living/M)
	M.forceMove(drop_location())
	M.adjustBruteLoss(-M.getBruteLoss())
	M.setDir(SOUTH)
	buckle_mob(M, force = TRUE)
	var/matrix/m180 = matrix(M.transform)
	m180.Turn(180)
	animate(M, transform = m180, time = 3)
	M.pixel_y = M.base_pixel_y + PIXEL_Y_OFFSET_LYING
	M.visible_message(span_danger("[src] takes [M]."), span_userdanger("You are hung up. You are not going anywhere on your own."))
	if(M.stat == DEAD)
		distortion.HeadWanted(M)
	else
		RegisterSignal(M, COMSIG_LIVING_DEATH, PROC_REF(OnSpikedDeath))

/// Down and off, no blood, and standing exactly as they were before: the spike's turn and drop undone outright.
/obj/structure/kitchenspike/bunnyman/release_mob(mob/living/M)
	UnregisterSignal(M, COMSIG_LIVING_DEATH)
	M.transform = matrix()
	M.pixel_y = M.base_pixel_y
	visible_message(span_danger("[M] comes down off [src]."))
	unbuckle_mob(M, force = TRUE)

/// Died hanging. The body stays where it hangs, and he comes for the head himself.
/obj/structure/kitchenspike/bunnyman/proc/OnSpikedDeath(mob/living/carbon/human/M)
	SIGNAL_HANDLER
	UnregisterSignal(M, COMSIG_LIVING_DEATH)
	if(distortion)
		distortion.HeadWanted(M)

/// A head on his ground: someone who died on his hooks, planted at the edge where it is seen. It cannot be taken down.
/obj/structure/headpike/bunnyman
	name = "head on a spear"
	var/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/distortion

/obj/structure/headpike/bunnyman/Initialize(mapload, new_distortion, obj/item/bodypart/head/head)
	. = ..()
	distortion = new_distortion
	if(head)
		head.forceMove(src)
		victim = head
	else
		victim = new(src)
	if(!victim.real_name)
		victim.real_name = random_unique_name(prob(50))
	spear = new(src)
	name = "[victim.real_name] on a spear"
	update_icon()

/obj/structure/headpike/bunnyman/attack_hand(mob/user)
	to_chat(user, span_warning("It is set into the rock. It is not coming down."))
	return TRUE

/obj/structure/headpike/bunnyman/Destroy()
	distortion = null
	return ..()

/obj/structure/headpike/bunnyman/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	if(distortion)
		distortion.OnThingAttacked(src, user)

/obj/structure/headpike/bunnyman/bullet_act(obj/projectile/P)
	. = ..()
	if(distortion)
		distortion.OnThingAttacked(src, P.firer)

/obj/structure/headpike/bunnyman/obj_destruction(damage_flag)
	if(distortion)
		distortion.OnThingBroken(src)
	return ..()

/obj/structure/headpike/bunnyman/examine(mob/user)
	. = ..()
	. += span_notice("It did not look twice either.")

/turf/open/floor/plating/ashplanet/rocky/bunnyman
	name = "rock floor"
	desc = "Bare rock, worn smooth down the middle. Something is dragged along it often."

/turf/closed/indestructible/rock/bunnyman
	name = "rock"
	desc = "Rock where a wall was. It is cold, and it is not going anywhere."
