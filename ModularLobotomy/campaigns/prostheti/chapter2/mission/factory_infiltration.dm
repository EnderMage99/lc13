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
	var/mob/living/simple_animal/hostile/ui_npc/penny_companion/penny_companion
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
	/// Boss room door landmark (for bolting/unbolting and Zwei breach)
	var/obj/effect/landmark/prostheti_npc_spawn/boss_door/boss_door_landmark
	/// Boss room entry trigger landmark
	var/obj/effect/landmark/boss_room_trigger/boss_trigger
	/// Director mob spawn landmark (deferred spawning)
	var/obj/effect/landmark/mission_mob_spawn/factory_director/director_landmark
	/// Reference to the rally point (persists for re-entry after Broken Fate)
	var/obj/structure/mission_rally/factory_infiltration/rally_point
	/// The boss room safe object
	var/obj/structure/prostheti_safe/boss_safe
	/// Whether the boss room trap has been triggered
	var/trap_triggered = FALSE

/datum/prostheti_mission/factory_infiltration/Destroy()
	if(penny_companion && !QDELETED(penny_companion))
		qdel(penny_companion)
	penny_companion = null
	director = null
	penny_ui_npc = null
	campaign = null
	rally_point = null
	boss_door_landmark = null
	boss_trigger = null
	director_landmark = null
	boss_safe = null
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
	LoadMissionMap("_maps/Quests/competitor_factory.dmm")

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

	// Spawn Penny companion (qdel any existing one first to prevent duplication)
	if(penny_companion && !QDELETED(penny_companion))
		qdel(penny_companion)
	penny_companion = new(penny_spawn_turf)
	penny_companion.ApplyTrainingData()
	penny_companion.mission = src
	if(length(participants))
		penny_companion.Leader = participants[1]

	// Move Penny's hub NPC to nullspace (companion replaces her)
	for(var/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch2/P in campaign.current_npcs)
		penny_ui_npc = P
		P.forceMove(null)
		break

	// Find boss room landmarks on the factory z-level
	for(var/obj/effect/landmark/prostheti_npc_spawn/boss_door/BD in GLOB.prostheti_mob_landmarks)
		if(mission_level && BD.z == mission_level.z_value)
			boss_door_landmark = BD
			break
	for(var/obj/effect/landmark/boss_room_trigger/BT in GLOB.prostheti_mob_landmarks)
		if(mission_level && BT.z == mission_level.z_value)
			boss_trigger = BT
			boss_trigger.mission = src
			break
	for(var/obj/effect/landmark/mission_mob_spawn/factory_director/DL in mob_landmarks)
		director_landmark = DL
		break
	// Find the boss room safe on the factory z-level
	for(var/obj/structure/prostheti_safe/S in world)
		if(mission_level && S.z == mission_level.z_value)
			boss_safe = S
			break

	// Teleport players to factory
	TeleportParticipants()
	mission_state = PROSTHETI_MISSION_ACTIVE

// =============================================
// Boss Room Trap
// =============================================

/// Called by the boss_room_trigger when all participants have entered the boss room.
/// The safe unlock is handled by Penny's area check — this just marks the trap as triggered.
/datum/prostheti_mission/factory_infiltration/proc/OnBossRoomTrapTriggered()
	trap_triggered = TRUE

/// Called by Penny's TriggerSafeUnlock(). Penny walks to the safe, opens it, boss drops.
/datum/prostheti_mission/factory_infiltration/proc/OnSafeUnlocked()
	if(!penny_companion || !boss_safe)
		return

	// Penny walks to the safe
	var/turf/safe_turf = get_turf(boss_safe)
	if(safe_turf)
		penny_companion.Leader = null
		walk_to(penny_companion, boss_safe, 1, penny_companion.move_to_delay)

	sleep(20)	// Give Penny time to walk there
	walk(penny_companion, 0)	// Stop walking

	// Penny tries to unlock it
	penny_companion.face_atom(boss_safe)
	penny_companion.say("Let me see if I can crack this...")
	sleep(20)	// 2 second do_after equivalent

	// Safe opens — empty
	boss_safe.OpenSafe()
	penny_companion.say("It's... empty?")
	sleep(10)

	// 3x3 warning effect around director spawn point
	var/turf/spawn_turf
	if(director_landmark)
		spawn_turf = get_turf(director_landmark)
	if(!spawn_turf)
		spawn_turf = safe_turf
	for(var/turf/open/T in range(1, spawn_turf))
		new /obj/effect/temp_visual/seismic_warning(T)
	playsound(spawn_turf, 'sound/effects/meteorimpact.ogg', 80, FALSE)

	sleep(15)	// Warning duration (1.5s)

	// Boss drops down
	if(director_landmark)
		director_landmark.spawn_enabled = TRUE
		director_landmark.SpawnMob()
		director = director_landmark.spawned_mob
	if(director)
		// Collect teleport spots for Borrowed Time
		for(var/obj/effect/landmark/prostheti_npc_spawn/boss_teleport/TP in GLOB.prostheti_mob_landmarks)
			if(mission_level && TP.z == mission_level.z_value)
				director.teleport_spots += get_turf(TP)
		director.penny_target = penny_companion
		RegisterSignal(director, COMSIG_DIRECTOR_EXECUTION, PROC_REF(OnDirectorExecution))
		playsound(director, 'sound/effects/meteorimpact.ogg', 100, FALSE)
		for(var/mob/living/P in participants)
			if(P.client)
				shake_camera(P, 7, 3)
		director.say("You brought children into my office to crack my safe? How flattering.")

	// Close and bolt the door
	if(boss_door_landmark)
		boss_door_landmark.BoltDoor()

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

	sleep(15)

	// Show "A few hours later..." text on the black screen
	var/style = "font-family: 'Baskerville'; text-align: center; color: #FFFFFF; font-size: 14pt; font-style: italic;"
	var/list/text_overlays = list()
	for(var/mob/living/P in participants)
		if(!P?.client)
			continue
		var/obj/effect/overlay/T = new()
		T.alpha = 0
		T.maptext_height = 80
		T.maptext_width = 424
		T.layer = FLOAT_LAYER
		T.plane = SPLASHSCREEN_PLANE
		T.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA
		T.screen_loc = "Center-6,Center"
		T.maptext = "<span style=\"[style]\">A few hours later...</span>"
		P.client.screen += T
		animate(T, alpha = 255, time = 10)
		text_overlays += list(list("client" = P.client, "overlay" = T))

	sleep(40)	// Hold text for 4 seconds

	// Fade out text
	for(var/list/entry in text_overlays)
		var/client/C = entry["client"]
		var/obj/effect/overlay/OL = entry["overlay"]
		if(C && OL)
			animate(OL, alpha = 0, time = 10)
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(fade_blurb), C, OL, 0), 10)

	sleep(15)

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

	// --- Post-Confrontation State ---
	// Clyde walks back to his office from the medical wing
	var/turf/clyde_office = GLOB.prostheti_npc_landmarks["clyde_spawn"]
	for(var/mob/living/simple_animal/hostile/ui_npc/prostheti/clyde_wells/ch2/clyde in campaign.current_npcs)
		if(clyde_office)
			walk_to(clyde, clyde_office, 0, clyde.move_to_delay)
		break

	// Penny stays at the medical wing, then starts wandering from there
	if(penny_ui_npc)
		var/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch2/penny = penny_ui_npc
		penny.StartPostConfrontationWandering()

	// Hector is gone — move to nullspace
	for(var/mob/living/simple_animal/hostile/ui_npc/prostheti/hector/ch2/hector in campaign.current_npcs)
		hector.forceMove(null)
		hector.in_cutscene = TRUE
		break

	// Deactivate the rally point (stays visible but non-interactive)
	if(rally_point && !QDELETED(rally_point))
		rally_point.mission_active = TRUE
		rally_point.signup_open = FALSE

	// Clear active mission reference
	if(campaign)
		campaign.active_mission = null

	// Complete the chapter
	campaign.CompleteChapter(2)
	mission_state = PROSTHETI_MISSION_COMPLETE

// =============================================
// Broken Fate Override
// =============================================

/// Chapter-specific reset logic for Broken Fate party wipe.
/datum/prostheti_mission/factory_infiltration/OnBrokenFate()
	// Reset boss room trap (ResetZLevelMobs already ran — director may have respawned)
	trap_triggered = FALSE
	if(boss_door_landmark)
		boss_door_landmark.UnboltDoor()
	if(boss_trigger)
		boss_trigger.ResetTrigger()
	// Disable deferred director spawning and qdel any director that ResetZLevelMobs respawned
	if(director_landmark)
		director_landmark.spawn_enabled = FALSE
		if(director_landmark.spawned_mob && !QDELETED(director_landmark.spawned_mob))
			qdel(director_landmark.spawned_mob)
			director_landmark.spawned_mob = null
	director = null

	// Qdel old companion before respawning
	if(penny_companion && !QDELETED(penny_companion))
		qdel(penny_companion)
		penny_companion = null

	// Reset the safe
	if(boss_safe)
		boss_safe.ResetSafe()

	// Respawn Penny companion
	if(penny_spawn_turf)
		penny_companion = new(penny_spawn_turf)
		penny_companion.ApplyTrainingData()
		penny_companion.mission = src
		if(length(participants))
			penny_companion.Leader = participants[1]

	// Move Penny's hub NPC back from nullspace to Training Yard
	if(penny_ui_npc)
		var/turf/penny_turf = GLOB.prostheti_npc_landmarks["penny_yard_destination"]
		if(penny_turf)
			penny_ui_npc.forceMove(penny_turf)

	// Reset rally point for re-entry
	if(rally_point && !QDELETED(rally_point))
		rally_point.ResetForReentry()

	extraction_started = FALSE
