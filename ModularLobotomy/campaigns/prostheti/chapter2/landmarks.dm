// =============================================
// Prostheti Innovations — Chapter 2 Map Landmarks
// =============================================
// Self-deleting landmarks that store turfs in GLOB lists.
//
// HUB MAP LANDMARKS (prostheti_innovations.dmm):
// - medical_bed_1 through medical_bed_4: Patient beds in Medical Wing (player buckle targets)
// - penny_medical_bed: Penny's bed in Medical Wing
// - clyde_medical_stand: Where Clyde stands during confrontation cutscene
//
// FACTORY MAP LANDMARKS (competitor_factory.dmm):
// - Uses mission_player_spawn from mission_landmarks.dm for player spawns
// - Uses mission_mob_spawn from mission_landmarks.dm for enemy placement
// - penny_companion_spawn: Where Penny's combat companion spawns

// =============================================
// Medical Wing — Patient Bed Landmarks (Hub Map)
// =============================================
// Players are buckled to these beds after extraction from the factory.
// Place 4 beds in the Medical Wing area, near each other.

/obj/effect/landmark/prostheti_npc_spawn/medical_bed_1
	name = "Medical bed 1"
	landmark_id = "medical_bed_1"

/obj/effect/landmark/prostheti_npc_spawn/medical_bed_2
	name = "Medical bed 2"
	landmark_id = "medical_bed_2"

/obj/effect/landmark/prostheti_npc_spawn/medical_bed_3
	name = "Medical bed 3"
	landmark_id = "medical_bed_3"

/obj/effect/landmark/prostheti_npc_spawn/medical_bed_4
	name = "Medical bed 4"
	landmark_id = "medical_bed_4"

/obj/effect/landmark/prostheti_npc_spawn/penny_medical_bed
	name = "Penny medical bed"
	landmark_id = "penny_medical_bed"

/obj/effect/landmark/prostheti_npc_spawn/clyde_medical_stand
	name = "Clyde medical stand"
	landmark_id = "clyde_medical_stand"

// =============================================
// Factory Mission — Penny Companion Spawn (Factory Map)
// =============================================

/obj/effect/landmark/prostheti_npc_spawn/penny_companion
	name = "Penny companion spawn"
	landmark_id = "penny_companion_spawn"

// =============================================
// Factory Mission — Rally Point Spawn (Hub Map)
// =============================================
// Where the mission rally point object spawns in the Training Yard.

/obj/effect/landmark/prostheti_npc_spawn/rally_point
	name = "Rally point spawn"
	landmark_id = "rally_point_spawn"

// =============================================
// Factory Mission — Boss Room Door Landmark (Factory Map)
// =============================================
// Persistent landmark placed on the same turf as the boss room door.
// Stores a reference to the door for bolting (trap) and unbolting (Zwei breach).
// Also used by the Zwei rescue cutscene as the breach entry point.

/obj/effect/landmark/prostheti_npc_spawn/boss_door
	name = "Boss room door"
	landmark_id = "boss_door"
	/// The airlock sitting on this turf
	var/obj/machinery/door/airlock/door

/obj/effect/landmark/prostheti_npc_spawn/boss_door/Initialize(mapload)
	. = ..()
	// Parent returns INITIALIZE_HINT_QDEL — override to persist
	. = INITIALIZE_HINT_NORMAL
	// Register in mob landmarks so BeginMission() can find us by type on z-level
	GLOB.prostheti_mob_landmarks += src
	// Doors may not be fully initialized yet; find ours after a short delay
	addtimer(CALLBACK(src, PROC_REF(FindDoor)), 3 SECONDS)

/obj/effect/landmark/prostheti_npc_spawn/boss_door/Destroy()
	GLOB.prostheti_mob_landmarks -= src
	door = null
	return ..()

/// Finds and stores the airlock on our turf.
/obj/effect/landmark/prostheti_npc_spawn/boss_door/proc/FindDoor()
	for(var/obj/machinery/door/airlock/D in get_turf(src))
		door = D
		break

/// Bolts the boss room door shut.
/obj/effect/landmark/prostheti_npc_spawn/boss_door/proc/BoltDoor()
	if(door)
		door.bolt()

/// Unbolts the boss room door.
/obj/effect/landmark/prostheti_npc_spawn/boss_door/proc/UnboltDoor()
	if(door)
		door.unbolt()

// =============================================
// Factory Mission — Boss Room Trigger (Factory Map)
// =============================================
// Persistent invisible landmark placed one tile inside the boss room.
// Tracks mission participants via Crossed(). When all have entered,
// triggers the trap: bolts the door and spawns the Factory Director.

/obj/effect/landmark/boss_room_trigger
	name = "boss room trigger"
	icon = 'icons/effects/effects.dmi'
	icon_state = "yourpath"
	alpha = 0
	anchored = TRUE
	/// Participants who have crossed this trigger
	var/list/mob/living/crossed_participants = list()
	/// Whether the trap has already fired
	var/triggered = FALSE
	/// The mission datum that owns this trigger
	var/datum/prostheti_mission/factory_infiltration/mission

/obj/effect/landmark/boss_room_trigger/Initialize(mapload)
	. = ..()
	GLOB.prostheti_mob_landmarks += src

/obj/effect/landmark/boss_room_trigger/Destroy()
	GLOB.prostheti_mob_landmarks -= src
	crossed_participants.Cut()
	mission = null
	return ..()

/obj/effect/landmark/boss_room_trigger/Crossed(atom/movable/AM, oldloc)
	. = ..()
	if(triggered)
		return
	if(!mission)
		return
	if(!isliving(AM))
		return
	if(!(AM in mission.participants))
		return
	if(AM in crossed_participants)
		return
	crossed_participants += AM
	CheckAllCrossed()

/// Checks if all mission participants have crossed; if so, fires the trap.
/obj/effect/landmark/boss_room_trigger/proc/CheckAllCrossed()
	if(!mission || !length(mission.participants))
		return
	if(length(crossed_participants) >= length(mission.participants))
		TriggerTrap()

/// Fires the boss room trap — bolts door, spawns director.
/obj/effect/landmark/boss_room_trigger/proc/TriggerTrap()
	triggered = TRUE
	if(mission)
		mission.OnBossRoomTrapTriggered()

/// Resets the trigger for Broken Fate. Clears tracked players and re-arms.
/obj/effect/landmark/boss_room_trigger/proc/ResetTrigger()
	crossed_participants.Cut()
	triggered = FALSE

// =============================================
// Factory Mission — Mob Spawn Subtypes
// =============================================
// These are placed on the factory away map (competitor_factory.dmm).
// They use the persistent mission_mob_spawn pattern from mission_landmarks.dm.

/obj/effect/landmark/mission_mob_spawn/factory_worker
	name = "factory worker spawn"
	mob_type = /mob/living/simple_animal/hostile/prostheti/factory_worker

/obj/effect/landmark/mission_mob_spawn/factory_heavy
	name = "factory heavy spawn"
	mob_type = /mob/living/simple_animal/hostile/prostheti/factory_worker/heavy

/obj/effect/landmark/mission_mob_spawn/factory_director
	name = "factory director spawn"
	mob_type = /mob/living/simple_animal/hostile/prostheti/factory_director
	segment_id = "office"
	/// Director spawn is deferred until the boss room trap triggers
	var/spawn_enabled = FALSE

/// Only spawns the director if the trap has enabled spawning.
/obj/effect/landmark/mission_mob_spawn/factory_director/SpawnMob()
	if(!spawn_enabled)
		return
	return ..()
