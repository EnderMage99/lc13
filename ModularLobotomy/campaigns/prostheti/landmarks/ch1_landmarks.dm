// =============================================
// Prostheti Innovations — Chapter 1 Map Landmarks
// =============================================
// Self-deleting landmarks that store turfs in GLOB lists.
// Place these on the Prostheti hub map (prostheti_innovations.dmm).
//
// LANDMARK PLACEMENT GUIDE:
// - penny_waypoint (x5-8): Scatter across Design Floor + Factory Floor hallways.
// - prostheti_duel/player_spawn/penny: Inside the Training Yard, near the entrance.
// - prostheti_duel/fixer_spawn/penny: Inside the Training Yard, opposite the player spawn.
// - penny_yard_destination: Inside the Training Yard, between player/fixer spawns.
// - training_yard_door: On the locked door between Factory Floor and Training Yard.

// =============================================
// Penny Waypoint — Patrol Destinations
// =============================================
// Penny will pick a random waypoint and walk to it, dwell for a while, then
// pick another. Place 5-8 of these spread across Design Floor and Factory Floor.

/obj/effect/landmark/penny_waypoint
	name = "Penny waypoint"
	icon_state = "x"

/obj/effect/landmark/penny_waypoint/Initialize(mapload)
	. = ..()
	GLOB.penny_waypoints += get_turf(src)
	return INITIALIZE_HINT_QDEL

// =============================================
// Prostheti Duel Landmarks — Echo Office Pattern
// =============================================
// Each NPC with can_duel has their own duel area with dedicated landmarks.
// The fixer_id must match the duel_area_id on the NPC.

/// Base landmark for Prostheti training duels.
/obj/effect/landmark/prostheti_duel
	name = "prostheti duel landmark"
	icon_state = "x2"
	/// Which NPC's duel area this belongs to — must match duel_area_id on the NPC
	var/fixer_id

/// Where the player is teleported to for the duel.
/obj/effect/landmark/prostheti_duel/player_spawn
	name = "prostheti duel player spawn"

/// Where the combat mob spawns for the duel.
/obj/effect/landmark/prostheti_duel/fixer_spawn
	name = "prostheti duel fixer spawn"

// Penny duel area landmarks
/obj/effect/landmark/prostheti_duel/player_spawn/penny
	fixer_id = "penny"

/obj/effect/landmark/prostheti_duel/fixer_spawn/penny
	fixer_id = "penny"

// =============================================
// Penny Yard Destination
// =============================================
// Where Penny walks to during the introduction cutscene.
// Place inside the Training Yard between the player/fixer spawns.

/obj/effect/landmark/prostheti_npc_spawn/penny_yard
	name = "Penny yard destination"
	landmark_id = "penny_yard_destination"

// =============================================
// Training Yard Door Marker
// =============================================
// Marks the turf of the locked door between Factory Floor and Training Yard.
// Penny's ch1 NPC finds the door on this turf during FindReferences().

/obj/effect/landmark/prostheti_npc_spawn/training_door
	name = "Training yard door"
	landmark_id = "training_door"

/obj/effect/landmark/prostheti_npc_spawn/training_door/Initialize(mapload)
	. = ..()
	// Bolt the door shut so players can't access the Training Yard early
	var/turf/T = get_turf(src)
	for(var/obj/machinery/door/D in T)
		D.locked = TRUE
		D.update_icon()
