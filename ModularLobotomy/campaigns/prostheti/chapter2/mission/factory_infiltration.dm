// =============================================
// Prostheti Innovations — Factory Infiltration Mission (Chapter 2)
// =============================================
// The core mission datum for Chapter 2's factory infiltration.
// Extends prostheti_mission (mission_base.dm) for Broken Fate support.
//
// Flow:
// 1. Rally point calls BeginMission() with signed-up players
// 2. Map loaded, players teleported, Penny companion spawned
// 3. Players fight through factory workers to director's office
// 4. Director at 400 HP → execution trigger → Zwei rescue cutscene
// 5. Extraction → medical wing → Clyde confrontation → chapter complete

/datum/prostheti_mission/factory_infiltration
	/// Penny companion mob reference
	var/mob/living/simple_animal/hostile/prostheti/penny_companion/penny_companion
	/// Penny companion spawn turf on the factory z-level
	var/turf/penny_spawn_turf
	/// Whether extraction has started (prevents double-triggering)
	var/extraction_started = FALSE
	/// The Factory Director mob (for signal registration)
	var/mob/living/simple_animal/hostile/prostheti/factory_director/director
	/// Reference to Penny's ch2 ui_npc (moved to nullspace during mission)
	var/mob/living/penny_ui_npc
	/// Reference to campaign controller
	var/datum/campaign_controller/prostheti/campaign

/datum/prostheti_mission/factory_infiltration/Destroy()
	if(penny_companion && !QDELETED(penny_companion))
		qdel(penny_companion)
	penny_companion = null
	director = null
	penny_ui_npc = null
	campaign = null
	return ..()

// =============================================
// Mission Start
// =============================================

/// Called by rally point after signup closes. Loads map, spawns Penny, teleports players.
/datum/prostheti_mission/factory_infiltration/proc/BeginMission(list/mob/living/players)
	campaign = GLOB.prostheti_campaign
	if(!campaign)
		CRASH("Factory infiltration mission started without campaign controller")

	// Load the factory away map
	LoadMissionMap("_maps/templates/prostheti_campaign/competitor_factory.dmm")

	// Collect spawn turfs from the loaded z-level
	for(var/turf/T in GLOB.prostheti_player_spawns)
		if(mission_level && T.z == mission_level.z_value)
			spawn_turfs += T
	// Collect mob landmarks
	for(var/obj/effect/landmark/mission_mob_spawn/L in GLOB.prostheti_mob_landmarks)
		if(mission_level && L.z == mission_level.z_value)
			mob_landmarks += L

	// Add participants
	for(var/mob/living/P in players)
		AddParticipant(P)

	// Find Penny companion spawn
	penny_spawn_turf = GLOB.prostheti_npc_landmarks["penny_companion_spawn"]
	// If landmark not on factory z-level, use first player spawn as fallback
	if(!penny_spawn_turf && length(spawn_turfs))
		penny_spawn_turf = spawn_turfs[1]

	// Spawn Penny companion
	penny_companion = new(penny_spawn_turf)
	penny_companion.ApplyTrainingData()
	if(length(participants))
		penny_companion.leader = participants[1]

	// Move Penny's hub NPC to nullspace (companion replaces her)
	for(var/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch2/P in campaign.current_npcs)
		penny_ui_npc = P
		P.forceMove(null)
		break

	// Find the director mob for signal registration
	for(var/mob/living/simple_animal/hostile/prostheti/factory_director/D in GLOB.mob_list)
		if(mission_level && D.z == mission_level.z_value)
			director = D
			director.penny_target = penny_companion
			RegisterSignal(director, COMSIG_DIRECTOR_EXECUTION, PROC_REF(OnDirectorExecution))
			break

	// Teleport players to factory
	TeleportParticipants()
	mission_state = PROSTHETI_MISSION_ACTIVE

// =============================================
// Director Execution Signal Handler
// =============================================

/// Triggered when the Factory Director's health drops to 400.
/datum/prostheti_mission/factory_infiltration/proc/OnDirectorExecution(datum/source)
	SIGNAL_HANDLER
	// Disable Broken Fate — players are supposed to lose from here
	SetWipeEnabled(FALSE)
	// Trigger Zwei rescue cutscene (async — it has sleeps)
	INVOKE_ASYNC(src, PROC_REF(ZweiRescueCutscene))

// =============================================
// Zwei Rescue Cutscene
// =============================================
// See chapter2/cutscenes/zwei_rescue.dm for the full cutscene logic.
// This proc delegates to the cutscene proc.

/// Runs the full Zwei rescue and extraction sequence.
/datum/prostheti_mission/factory_infiltration/proc/ZweiRescueCutscene()
	// Freeze all players for the cutscene
	for(var/mob/living/P in participants)
		ADD_TRAIT(P, TRAIT_IMMOBILIZED, "zwei_cutscene")

	// Run the rescue cutscene (defined in cutscenes/zwei_rescue.dm)
	RunZweiRescue(src)

// =============================================
// Extraction & Medical Wing
// =============================================

/// Extracts all participants from the factory to the medical wing.
/datum/prostheti_mission/factory_infiltration/proc/CompleteExtraction()
	if(extraction_started)
		return
	extraction_started = TRUE

	// Fade to black for all participants
	for(var/mob/living/P in participants)
		P.overlay_fullscreen("extraction", /atom/movable/screen/fullscreen/broken_fate_bg)

	sleep(30)	// Hold black for 3 seconds

	// Clean up factory z-level
	if(penny_companion && !QDELETED(penny_companion))
		qdel(penny_companion)
		penny_companion = null
	// Qdel all remaining mobs on factory z-level
	for(var/mob/living/simple_animal/M in GLOB.mob_list)
		if(mission_level && M.z == mission_level.z_value && !(M in participants))
			qdel(M)

	// Move participants to medical wing beds
	var/list/bed_ids = list("medical_bed_1", "medical_bed_2", "medical_bed_3", "medical_bed_4")
	for(var/i in 1 to min(length(participants), length(bed_ids)))
		var/mob/living/P = participants[i]
		var/turf/bed_turf = GLOB.prostheti_npc_landmarks[bed_ids[i]]
		if(!P || !bed_turf)
			continue
		P.forceMove(bed_turf)
		P.revive(full_heal = TRUE)
		// Prevent self-unbuckle and buckle to bed lying down
		P.can_buckle_to = FALSE
		for(var/obj/structure/bed/B in bed_turf)
			B.buckle_mob(P, force = TRUE)
			break
		ADD_TRAIT(P, TRAIT_IMMOBILIZED, "zwei_cutscene")

	// Move Penny's hub NPC to medical bed
	var/turf/penny_bed = GLOB.prostheti_npc_landmarks["penny_medical_bed"]
	if(penny_ui_npc && penny_bed)
		penny_ui_npc.forceMove(penny_bed)
		for(var/obj/structure/bed/B in penny_bed)
			B.buckle_mob(penny_ui_npc, force = TRUE)
			break

	// Move Clyde to medical wing standing position
	var/turf/clyde_stand = GLOB.prostheti_npc_landmarks["clyde_medical_stand"]
	for(var/mob/living/simple_animal/hostile/ui_npc/prostheti/clyde_wells/ch2/clyde in campaign.current_npcs)
		if(clyde_stand)
			clyde.forceMove(clyde_stand)
		break

	sleep(15)	// Brief pause

	// Fade in — players "wake up"
	for(var/mob/living/P in participants)
		P.clear_fullscreen("extraction", 15)

	sleep(20)	// Let fade complete

	// Run Clyde confrontation cutscene (defined in cutscenes/clyde_confrontation.dm)
	RunClydeConfrontation(src)

// =============================================
// Post-Confrontation — Chapter Complete
// =============================================

/// Called after the Clyde confrontation cutscene finishes.
/datum/prostheti_mission/factory_infiltration/proc/ChapterComplete()
	// Unbuckle all participants and restore self-buckle ability
	for(var/mob/living/P in participants)
		REMOVE_TRAIT(P, TRAIT_IMMOBILIZED, "zwei_cutscene")
		P.can_buckle_to = initial(P.can_buckle_to)
		if(P.buckled)
			P.buckled.unbuckle_mob(P, force = TRUE)

	// Unbuckle Penny
	if(penny_ui_npc && penny_ui_npc.buckled)
		penny_ui_npc.buckled.unbuckle_mob(penny_ui_npc, force = TRUE)
	// Set Penny's cutscene flag so players can talk to her
	if(penny_ui_npc)
		var/mob/living/simple_animal/hostile/ui_npc/prostheti/P = penny_ui_npc
		P.in_cutscene = FALSE

	// Set shared var for post-confrontation dialogue gating
	for(var/mob/living/simple_animal/hostile/ui_npc/prostheti/npc in campaign.current_npcs)
		npc.SetSharedVar("clyde_confrontation_complete", TRUE)

	// Complete the chapter
	campaign.CompleteChapter(2)
	mission_state = PROSTHETI_MISSION_COMPLETE

// =============================================
// Broken Fate Override
// =============================================

/// Chapter-specific reset logic for Broken Fate party wipe.
/datum/prostheti_mission/factory_infiltration/OnBrokenFate()
	// Qdel old companion before respawning
	if(penny_companion && !QDELETED(penny_companion))
		qdel(penny_companion)
		penny_companion = null

	// Respawn Penny companion
	if(penny_spawn_turf)
		penny_companion = new(penny_spawn_turf)
		penny_companion.ApplyTrainingData()
		if(length(participants))
			penny_companion.leader = participants[1]

	// Reset director execution state
	for(var/mob/living/simple_animal/hostile/prostheti/factory_director/D in GLOB.mob_list)
		if(mission_level && D.z == mission_level.z_value)
			director = D
			director.execution_triggered = FALSE
			director.can_act = TRUE
			director.status_flags &= ~GODMODE
			director.penny_target = penny_companion
			RegisterSignal(director, COMSIG_DIRECTOR_EXECUTION, PROC_REF(OnDirectorExecution))
			break

	// Move Penny's hub NPC back to Training Yard
	if(penny_ui_npc)
		var/turf/penny_turf = GLOB.prostheti_npc_landmarks["penny_spawn"]
		if(penny_turf)
			penny_ui_npc.forceMove(penny_turf)

	extraction_started = FALSE
