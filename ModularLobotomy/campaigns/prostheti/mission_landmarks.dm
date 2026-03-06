// =============================================
// Prostheti Innovations — Mission Landmarks
// =============================================
// Persistent mob spawn landmarks for away missions and player spawn markers.
// Mob spawn landmarks persist across Broken Fate resets to enable respawning.

GLOBAL_LIST_EMPTY(prostheti_mob_landmarks)		// All mission_mob_spawn landmarks
GLOBAL_LIST_EMPTY(prostheti_player_spawns)		// Player spawn turfs for missions

// =============================================
// Mob Spawn Landmark — Persistent
// =============================================
// Each hostile mob on the away mission map is placed via one of these instead
// of placing mobs directly in the map editor. The landmark persists as the
// respawn point for Broken Fate resets.

/obj/effect/landmark/mission_mob_spawn
	name = "mission mob spawn"
	icon_state = "x"
	/// The mob type path to spawn (e.g., /mob/living/simple_animal/hostile/prostheti/factory_worker)
	var/mob_type
	/// Reference to the currently spawned mob
	var/mob/living/spawned_mob
	/// Which mission segment this landmark belongs to (for selective spawning)
	var/segment_id = ""

/obj/effect/landmark/mission_mob_spawn/Initialize(mapload)
	. = ..()
	GLOB.prostheti_mob_landmarks += src
	// Spawn the initial mob
	if(mob_type)
		SpawnMob()

/obj/effect/landmark/mission_mob_spawn/Destroy()
	GLOB.prostheti_mob_landmarks -= src
	if(spawned_mob && !QDELETED(spawned_mob))
		qdel(spawned_mob)
	spawned_mob = null
	return ..()

/// Spawns a fresh mob at this landmark's turf.
/obj/effect/landmark/mission_mob_spawn/proc/SpawnMob()
	if(!mob_type)
		return
	var/turf/T = get_turf(src)
	if(!T)
		return
	spawned_mob = new mob_type(T)

/// Qdels the existing mob and spawns a fresh copy. Used during Broken Fate reset.
/obj/effect/landmark/mission_mob_spawn/proc/RespawnMob()
	if(spawned_mob && !QDELETED(spawned_mob))
		qdel(spawned_mob)
		spawned_mob = null
	SpawnMob()

// =============================================
// Player Spawn Landmark — Self-Deleting
// =============================================
// Marks player spawn turfs on away mission maps. Adds its turf to the global
// list and qdels — the turf reference persists.

/obj/effect/landmark/mission_player_spawn
	name = "mission player spawn"
	icon_state = "x"

/obj/effect/landmark/mission_player_spawn/Initialize(mapload)
	. = ..()
	GLOB.prostheti_player_spawns += get_turf(src)
	return INITIALIZE_HINT_QDEL

// =============================================
// NPC Spawn Landmarks — Self-Deleting
// =============================================
// Marks where specific NPCs should be placed. Stores the turf in the GLOB
// assoc list with a key for identification.

/obj/effect/landmark/prostheti_npc_spawn
	name = "prostheti npc spawn"
	icon_state = "x"
	/// Key used to store this turf in GLOB.prostheti_npc_landmarks
	var/landmark_id = ""

/obj/effect/landmark/prostheti_npc_spawn/Initialize(mapload)
	. = ..()
	if(landmark_id)
		GLOB.prostheti_npc_landmarks[landmark_id] = get_turf(src)
	return INITIALIZE_HINT_QDEL

// --- Specific NPC spawn landmark subtypes ---

/obj/effect/landmark/prostheti_npc_spawn/clyde
	name = "Clyde Wells spawn"
	landmark_id = "clyde_spawn"

/obj/effect/landmark/prostheti_npc_spawn/penny
	name = "Penny Wells spawn"
	landmark_id = "penny_spawn"

/obj/effect/landmark/prostheti_npc_spawn/hector
	name = "Hector spawn"
	landmark_id = "hector_spawn"
