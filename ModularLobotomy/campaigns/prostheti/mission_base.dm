// =============================================
// Prostheti Innovations — Base Mission Datum (Broken Fate System)
// =============================================
// Parent type for ALL campaign away missions. Contains the full Broken Fate
// party wipe reset system. Chapter-specific subtypes override OnBrokenFate()
// for custom reset logic.
//
// The away z-level is NOT destroyed on wipe — it is reset in place and reused
// when players re-enter, avoiding duplicate z-levels and expensive map loading.

/datum/prostheti_mission
	/// Toggle — FALSE during scripted death moments (e.g., Ch2 boss fight)
	var/wipe_enabled = TRUE
	/// Prevents double-triggering during the Broken Fate cinematic
	var/wipe_in_progress = FALSE
	/// Assoc list: participant mob => their hub turf before teleport
	var/list/return_turfs = list()
	/// The loaded away z-level — persists across Broken Fate resets
	var/datum/space_level/mission_level
	/// All mission_mob_spawn landmarks on the z-level
	var/list/obj/effect/landmark/mission_mob_spawn/mob_landmarks = list()
	/// Player spawn turfs on the away z-level
	var/list/turf/spawn_turfs = list()
	/// The player mobs inside the mission (max 4)
	var/list/mob/living/participants = list()
	/// Current mission state
	var/mission_state = PROSTHETI_MISSION_SIGNUP
	/// Map template for loading
	var/datum/map_template/mission_template
	/// Grace period timer ID for wipe check
	var/wipe_grace_timer
	/// Assoc list: participant mob => list of tracked item refs (snapshot on entry)
	var/list/tracked_items = list()

/datum/prostheti_mission/Destroy()
	// Unregister all participant signals
	for(var/mob/living/P in participants)
		UnregisterSignal(P, list(COMSIG_LIVING_DEATH, COMSIG_MOB_STATCHANGE))
	participants.Cut()
	return_turfs = null
	mob_landmarks = null
	spawn_turfs = null
	mission_template = null
	mission_level = null
	tracked_items = null
	return ..()

/// Adds a player to the mission and registers wipe-detection signals.
/datum/prostheti_mission/proc/AddParticipant(mob/living/player)
	if(!player || (player in participants))
		return
	participants += player
	RegisterSignal(player, COMSIG_LIVING_DEATH, PROC_REF(OnParticipantDeath))
	RegisterSignal(player, COMSIG_MOB_STATCHANGE, PROC_REF(OnParticipantStatChange))
	// Snapshot the player's items for Broken Fate recovery
	SnapshotPlayerItems(player)

/// Removes a player from participant tracking.
/datum/prostheti_mission/proc/RemoveParticipant(mob/living/player)
	if(!player || !(player in participants))
		return
	UnregisterSignal(player, list(COMSIG_LIVING_DEATH, COMSIG_MOB_STATCHANGE))
	participants -= player

/// Signal handler for participant death.
/datum/prostheti_mission/proc/OnParticipantDeath(mob/living/source)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(CheckForWipe))

/// Signal handler for participant stat change (covers unconscious, etc.)
/datum/prostheti_mission/proc/OnParticipantStatChange(mob/living/source)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(CheckForWipe))

/// Checks if ALL participants are downed/dead. If so, starts a 3-second grace
/// period before confirming the wipe.
/datum/prostheti_mission/proc/CheckForWipe()
	if(!wipe_enabled || wipe_in_progress)
		return
	if(!length(participants))
		return

	// Check if all participants are downed or dead
	for(var/mob/living/P in participants)
		if(P.stat < UNCONSCIOUS) // Someone is still up
			// Cancel any pending grace timer
			if(wipe_grace_timer)
				deltimer(wipe_grace_timer)
				wipe_grace_timer = null
			return

	// All participants are down — start grace period if not already started
	if(!wipe_grace_timer)
		wipe_grace_timer = addtimer(CALLBACK(src, PROC_REF(ConfirmWipe)), 3 SECONDS, TIMER_STOPPABLE)

/// Called after the grace period. Rechecks the wipe condition, then triggers
/// Broken Fate if still all down.
/datum/prostheti_mission/proc/ConfirmWipe()
	wipe_grace_timer = null
	if(!wipe_enabled || wipe_in_progress)
		return

	// Recheck — someone might have been revived during the grace period
	for(var/mob/living/P in participants)
		if(P.stat < UNCONSCIOUS)
			return

	// Confirmed wipe
	TriggerBrokenFate()

/// Runs the full Broken Fate sequence:
/// cinematic → revive → teleport to hub → reset z-level → call OnBrokenFate()
/datum/prostheti_mission/proc/TriggerBrokenFate()
	wipe_in_progress = TRUE

	// Step 0: Apply GODMODE to all participants so nothing can hurt them during reset
	for(var/mob/living/P in participants)
		if(P)
			P.status_flags |= GODMODE

	// Step 1: Return ghosted players to their bodies
	for(var/mob/living/P in participants)
		if(!P)
			continue
		if(!P.client && P.mind?.current == P)
			for(var/mob/dead/observer/ghost in GLOB.player_list)
				if(ghost.mind?.current == P)
					P.key = ghost.key
					qdel(ghost)
					break

	// Step 2: Clear insanity AI controllers and panic status effects
	for(var/mob/living/P in participants)
		if(!P)
			continue
		if(istype(P.ai_controller, /datum/ai_controller/insane))
			QDEL_NULL(P.ai_controller)
		for(var/datum/status_effect/panicked_type/panic in P.status_effects)
			P.remove_status_effect(panic.type)

	// Step 3: Teleport all participants back to their return turfs on the hub
	for(var/mob/living/P in participants)
		var/turf/return_turf = return_turfs[P]
		if(return_turf)
			P.forceMove(return_turf)

	// Step 4: Revive, restore sanity, and immediately show Broken Fate overlay
	for(var/mob/living/P in participants)
		if(!P)
			continue
		P.revive(full_heal = TRUE)
		if(ishuman(P))
			var/mob/living/carbon/human/H = P
			H.adjustSanityLoss(-INFINITY, forced = TRUE)
		P.overlay_fullscreen("broken_fate_bg", /atom/movable/screen/fullscreen/broken_fate_bg)

	// Step 4b: Clear lingering visual/alert state from death
	sleep(20)
	for(var/mob/living/P in participants)
		if(!P)
			continue
		// Remove all blind client colours (remove_client_colour only removes one at a time)
		var/blind_removed = TRUE
		while(blind_removed)
			blind_removed = FALSE
			for(var/datum/client_colour/monochrome/blind/cc in P.client_colours)
				qdel(cc)
				blind_removed = TRUE
				break
		P.clear_alert("not_enough_oxy")
		P.clear_fullscreen("blind")
		// Remove GODMODE now that cleanup is done
		P.status_flags &= ~GODMODE

	// Step 5: Return tracked items that were dropped during the mission
	RestoreTrackedItems()

	// Step 6: Reset z-level mobs from landmarks
	ResetZLevelMobs()

	// Step 7: Call chapter-specific reset logic
	OnBrokenFate()

	// Step 8: Update mission state
	mission_state = PROSTHETI_MISSION_READY
	wipe_in_progress = FALSE
	wipe_enabled = TRUE

	// Step 9: Show Broken Fate text on top of the already-applied overlay
	ShowBrokenFateText(participants)

	// Step 10: Hold screen for 4 seconds then fade out
	sleep(40)
	for(var/mob/living/P in participants)
		if(P)
			P.clear_fullscreen("broken_fate_bg", 15)

/// Snapshots a player's current items (contents + storage contents) for Broken Fate recovery.
/datum/prostheti_mission/proc/SnapshotPlayerItems(mob/living/player)
	var/list/items = list()
	for(var/obj/item/I in player.contents)
		items += I
		// Also track items inside storage containers the player is carrying
		if(istype(I, /obj/item/storage))
			for(var/obj/item/sub in I.contents)
				items += sub
	tracked_items[player] = items

/// Returns any tracked items that are no longer on their owner back to them.
/datum/prostheti_mission/proc/RestoreTrackedItems()
	for(var/mob/living/P in tracked_items)
		if(!P || QDELETED(P))
			continue
		var/list/items = tracked_items[P]
		if(!length(items))
			continue
		for(var/obj/item/I in items)
			if(QDELETED(I))
				continue
			if(I.loc == P)
				continue	// Already on the player
			I.forceMove(P)

/// Empty in base type — overridden by chapter subtypes for custom reset logic
/// on the z-level and hub-side cleanup.
/datum/prostheti_mission/proc/OnBrokenFate()
	return

/// Toggle for scripted moments where dying is intentional.
/datum/prostheti_mission/proc/SetWipeEnabled(enabled)
	wipe_enabled = enabled
	if(!enabled && wipe_grace_timer)
		deltimer(wipe_grace_timer)
		wipe_grace_timer = null

/// Called when players choose to re-enter from hub — forceMove to spawn turfs.
/datum/prostheti_mission/proc/ReenterMission()
	if(mission_state != PROSTHETI_MISSION_READY)
		return
	for(var/i in 1 to min(length(participants), length(spawn_turfs)))
		var/mob/living/P = participants[i]
		var/turf/T = spawn_turfs[i]
		if(P && T)
			P.forceMove(T)
	mission_state = PROSTHETI_MISSION_ACTIVE

/// Iterates all mob landmarks on the z-level: qdels existing mobs, spawns fresh.
/datum/prostheti_mission/proc/ResetZLevelMobs()
	for(var/obj/effect/landmark/mission_mob_spawn/landmark in mob_landmarks)
		landmark.RespawnMob()

/// Loads the away mission z-level from the template map.
/datum/prostheti_mission/proc/LoadMissionMap(map_path)
	mission_template = new /datum/map_template()
	mission_template.mappath = map_path
	mission_template.name = "Prostheti Mission"
	mission_state = PROSTHETI_MISSION_LOADING
	mission_level = mission_template.load_new_z()
	if(!mission_level)
		CRASH("Failed to load Prostheti mission map: [map_path]")
	return mission_level

/// Stores participant return turfs and teleports them to the mission z-level.
/datum/prostheti_mission/proc/TeleportParticipants()
	for(var/i in 1 to min(length(participants), length(spawn_turfs)))
		var/mob/living/P = participants[i]
		return_turfs[P] = get_turf(P)
		P.forceMove(spawn_turfs[i])
	mission_state = PROSTHETI_MISSION_ACTIVE
