// =============================================
// Prostheti Innovations — Zwei Rescue Cutscene (Chapter 2)
// =============================================
// Triggered when the Factory Director's health drops to 400 HP.
// The Zwei Association breaches the office, kills the director,
// and rescues the players and Penny.
//
// Sequence:
// 1. Director seizes Penny (handled by director mob's ExecutionSequence)
// 2. COMSIG_DIRECTOR_EXECUTION fires → mission datum calls this
// 3. Door breach → Zwei spawn → director killed → Penny revived
// 4. Players unfreeze → extraction begins
//
// Global proc — no src, so uses sleep() + manual QDELETED checks.

/// Runs the full Zwei rescue cutscene. Called by the mission datum.
/proc/RunZweiRescue(datum/prostheti_mission/factory_infiltration/mission)
	if(!mission)
		return

	var/mob/living/simple_animal/hostile/prostheti/factory_director/director = mission.director
	var/mob/living/simple_animal/hostile/ui_npc/penny_companion/penny = mission.penny_companion

	// --- Door Breach ---
	var/turf/breach_turf
	if(mission.boss_door_landmark)
		breach_turf = get_turf(mission.boss_door_landmark)
		// Unbolt and open the door as part of the breach
		mission.boss_door_landmark.UnboltDoor()
		if(mission.boss_door_landmark.door)
			INVOKE_ASYNC(mission.boss_door_landmark.door, TYPE_PROC_REF(/obj/machinery/door, open))
	else if(director && !QDELETED(director))
		breach_turf = get_step(get_turf(director), pick(GLOB.cardinals))
		if(!breach_turf)
			breach_turf = get_turf(director)

	if(!breach_turf && length(mission.spawn_turfs))
		breach_turf = mission.spawn_turfs[1]

	// Breach effects
	if(breach_turf)
		playsound(breach_turf, 'sound/effects/meteorimpact.ogg', 100, FALSE)
		new /obj/effect/temp_visual/cult/sparks(breach_turf)	// TEMP — needs door breach debris visual

	// Screen shake for all participants
	for(var/mob/living/P in mission.participants)
		if(P.client)
			shake_camera(P, 10, 3)

	// Stagger director away from Penny
	if(director && !QDELETED(director))
		var/stagger_dir = pick(GLOB.cardinals)
		var/turf/stagger_turf = get_step(director, stagger_dir)
		if(stagger_turf)
			animate(director, pixel_x = director.base_pixel_x - 16, time = 2)
			director.forceMove(stagger_turf)
			animate(director, pixel_x = director.base_pixel_x, time = 2)
		director.say("What—?!")

	sleep(10)

	// --- Spawn Zwei Squad ---
	var/list/zwei_mobs = list()

	// Lead Fixer
	var/mob/living/simple_animal/hostile/prostheti/zwei_lead/lead = new(breach_turf)
	zwei_mobs += lead
	lead.say("Zwei Association — contract fulfilled. Area secured.")

	sleep(3)

	// 3 Standard Fixers
	for(var/i in 1 to 3)
		var/turf/fixer_turf = get_step(breach_turf, pick(GLOB.cardinals))
		if(!fixer_turf)
			fixer_turf = breach_turf
		var/mob/living/simple_animal/hostile/prostheti/zwei_fixer/fixer = new(fixer_turf)
		zwei_mobs += fixer
		sleep(3)

	// --- Zwei Clean Up Factory Workers ---
	// Standard fixers engage remaining factory workers automatically
	// via faction hostility — prostheti_competitor vs zwei

	// --- Lead Fixer Executes Director ---
	sleep(15)

	if(director && !QDELETED(director) && lead && !QDELETED(lead))
		// Walk lead to director
		var/list/path_turfs = getline(get_turf(lead), get_turf(director))
		for(var/turf/T in path_turfs)
			if(T == get_turf(lead))
				continue
			lead.forceMove(T)
			sleep(2)
			if(QDELETED(lead))
				break

		if(!QDELETED(lead) && !QDELETED(director))
			lead.face_atom(director)

			director.say("This is my factory. You have no authority—")
			sleep(10)

			if(!QDELETED(lead))
				lead.say("Contract says otherwise.")
				sleep(10)

			// Execute director — single shot
			if(!QDELETED(director))
				playsound(director, 'sound/weapons/gun/shotgun/shot.ogg', 80, FALSE)
				for(var/mob/living/P in mission.participants)
					if(P.client)
						shake_camera(P, 7, 2)
				director.death()
				sleep(10)
				if(!QDELETED(director))
					qdel(director)
				mission.director = null

	// --- Revive Penny ---
	if(penny && !QDELETED(penny) && penny.is_downed && lead && !QDELETED(lead))
		// Lead walks to Penny
		var/list/penny_path = getline(get_turf(lead), get_turf(penny))
		for(var/turf/T in penny_path)
			if(T == get_turf(lead))
				continue
			lead.forceMove(T)
			sleep(2)
			if(QDELETED(lead))
				break

		if(!QDELETED(lead))
			lead.say("Target secured. Get her up.")
			sleep(5)

		// A fixer revives Penny
		if(!QDELETED(penny))
			penny.can_be_revived = TRUE
			penny.GetUp()
			sleep(10)

			penny.say("I... we had it under control.")
			sleep(20)

	// --- Players Regain Movement ---
	for(var/mob/living/P in mission.participants)
		REMOVE_TRAIT(P, TRAIT_IMMOBILIZED, "zwei_cutscene")

	sleep(20)

	// --- Clean Up Zwei Mobs ---
	for(var/mob/M in zwei_mobs)
		if(!QDELETED(M))
			qdel(M)

	// --- Begin Extraction ---
	mission.CompleteExtraction()
