/turf/proc/DistortionReachable(requester, turf/T, ID, simulated_only)
	// Same thing as AStar.dm:189, however removing !LinkBlockedWithAccess(T,requester, ID), since distortions will have their own way to checking which turfs they can pass.
	//Mainly to avoid stuff like tables or barricades in the way.
	if(!T || T.density || (simulated_only && SSpathfinder.space_type_cache[T.type]))
		return FALSE
	//We check the direction of the next turf.
	var/rdir = get_dir(T, src)
	for(var/obj/O in T)
		//This line checks the tags between the requester and the turf.
		//Like, if the requester has PASSGLASS, and the turf has the tag PASSGLASS as well. It will return true.
		if(O.CanAStarPass(ID, rdir, requester))
			continue
		// We don't want the distortion trying to pass through unbreakable objects.
		if(!(O.resistance_flags & INDESTRUCTIBLE))
			continue
		return FALSE
	return TRUE

// Overrides the default Destroy() to make use of the new DistortionReachable proc.
/mob/living/simple_animal/hostile/distortion/advanced/patrol_to(turf/target_location)
	if(isnull(target_location))
		return FALSE
	patrol_reset()
	patrol_path = GetPatrolPath(target_location)
	if(!length(patrol_path))
		return FALSE
	patrol_move(patrol_path[patrol_path.len])
	return TRUE

//Making this a helper proc to make sure it's useable in other parts of advanced distortion.
/mob/living/simple_animal/hostile/distortion/advanced/proc/GetPatrolPath(turf/destination)
	return get_path_to(src, destination, TYPE_PROC_REF(/turf, Distance_cardinal), 0, 200, adjacent = TYPE_PROC_REF(/turf, DistortionReachable), id = access_card)

// For some reason distortion CanStartPatrol doesn't check for patrol_cooldown, so we are checking it here.
/mob/living/simple_animal/hostile/distortion/advanced/CanStartPatrol()
	if(returning)
		return FALSE
	if(patrol_cooldown > world.time)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/distortion/advanced/SelectPatrolLocation()
	return territory.RandomTurf()

//Overriding this in order to use GetPatrolPath instead of the default get_path_to.
/mob/living/simple_animal/hostile/distortion/advanced/PatrolSelect()
	if(SSmaptype.maptype in SSmaptype.autopossess)
		return FALSE
	var/turf/destination = SelectPatrolLocation()
	if(!isturf(destination))
		destination = get_turf(destination)
	if(!destination)
		return FALSE
	SEND_SIGNAL(src, COMSIG_PATROL_START, src, destination)
	SEND_GLOBAL_SIGNAL(src, COMSIG_GLOB_PATROL_START, src, destination)
	patrol_path = GetPatrolPath(destination)
	return patrol_path

//This how we will break the objects that are in the way of the distortion.
//Also, if the distortion is patrolling, it will not be blocked by people walking in front of it.
/mob/living/simple_animal/hostile/distortion/advanced/Bump(atom/A)
	if(isliving(A) && !client && !target && length(patrol_path))
		forceMove(get_turf(A))
		return
	var/turf/blocked = get_turf(A)
	. = ..()
	//Checking the turf of blocked again, in case PushAM(AM, move_force()) is triggered and it pushes the object away.
	if(client || !isobj(A) || QDELETED(A) || get_turf(A) != blocked)
		return
	var/obj/O = A
	if(IsSmashable(O))
		O.attack_animal(src)

// This is called every life tick, and handles the leash system for the distortion.
/mob/living/simple_animal/hostile/distortion/advanced/proc/UpdateLeash()
	// Hey! Are we within out terrioty? Mark this spot as where we should return to if we leave our territory.
	if(territory.Contains(loc))
		leash_exit = loc
		if(returning)
			EndReturn()
		return_interrupted = FALSE
		return

	// If we are currently returning to our leash exit, if we don't have a path back to it we attempt to make a new path.
	if(returning)
		if(!length(patrol_path) && world.time > next_return_attempt)
			WalkHome()
		return

	//We got interrupted while returning? Then we don't try to return until we are done with our target.
	if(return_interrupted && target)
		return
	// If we are not in out territory, and we are too far away from out leash exit, we start returning to it.
	if(leashed && leash_exit && get_dist(src, leash_exit) > leash_slack)
		StartReturn()

// Screw the person we are chasing, we got to head back home!
/mob/living/simple_animal/hostile/distortion/advanced/proc/StartReturn()
	returning = TRUE
	return_interrupted = FALSE
	LoseTarget()
	patrol_reset()
	next_return_attempt = world.time + return_pause

// Let's wandering back to our territory- oh? we are missing a leash exit? I guess we will walk back to a random turf in our territory.
/mob/living/simple_animal/hostile/distortion/advanced/proc/WalkHome()
	next_return_attempt = world.time + return_pause
	if(patrol_to(leash_exit))
		return
	patrol_to(territory.RandomTurf())

/mob/living/simple_animal/hostile/distortion/advanced/proc/EndReturn()
	returning = FALSE
	patrol_reset()

// No need to get into fights while coming back home.
/mob/living/simple_animal/hostile/distortion/advanced/CanAttack(atom/the_target)
	if(returning)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/distortion/advanced/faction_check_mob(mob/trg, exact_match)
	if(trg in provoked_by)
		return FALSE
	return ..()

// Adds a mob to a list of mobs, that the distortion will always target, even if they share a faction with the distortion.
/mob/living/simple_animal/hostile/distortion/advanced/proc/Provoke(mob/living/by)
	if(!istype(by))
		return
	if(!(by in provoked_by))
		provoked_by += by
		RegisterSignal(by, COMSIG_PARENT_QDELETING, PROC_REF(OnProvokerDeleted))
	if(target || stat == DEAD || AIStatus == AI_OFF || client)
		return
	if(AIStatus == AI_IDLE)
		toggle_ai(AI_ON)
	FindTarget(list(by), TRUE)

/mob/living/simple_animal/hostile/distortion/advanced/proc/OnProvokerDeleted(datum/source)
	SIGNAL_HANDLER
	provoked_by -= source

/mob/living/simple_animal/hostile/distortion/advanced/PostDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	InterruptReturn(source)

/mob/living/simple_animal/hostile/distortion/advanced/proc/InterruptReturn(mob/living/attacker)
	if(!returning || hard_return || !istype(attacker) || attacker.stat > stat_attack)
		return
	returning = FALSE
	return_interrupted = TRUE
	patrol_reset()
	Provoke(attacker)

// If we lose a target while we are not in our territory, we start returning to our leash exit.
/mob/living/simple_animal/hostile/distortion/advanced/LoseTarget(stop_movement = TRUE)
	. = ..()
	if(return_interrupted && leashed && territory && !territory.Contains(loc))
		StartReturn()
