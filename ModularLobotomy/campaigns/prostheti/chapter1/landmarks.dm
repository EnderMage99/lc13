// =============================================
// Prostheti Innovations — Chapter 1 Map Landmarks
// =============================================
// Self-deleting landmarks that store turfs in GLOB lists.
// Place these on the Prostheti hub map (prostheti_innovations.dmm).
//
// LANDMARK PLACEMENT GUIDE:
// - chapter_gate (x1-3): Place at chokepoints leading away from the chapter select terminal.
//   Blocks movement until a chapter is selected. Auto-deletes once chapter starts.
// - penny_waypoint (x5-8): Scatter across Design Floor + Factory Floor hallways.
// - prostheti_duel/player_spawn/penny: Inside the Training Yard, near the entrance.
// - prostheti_duel/fixer_spawn/penny: Inside the Training Yard, opposite the player spawn.
// - penny_yard_destination: Inside the Training Yard, between player/fixer spawns.
// - training_yard_door: On the locked door between Factory Floor and Training Yard.

// =============================================
// Chapter Gate — Blocks Movement Until Chapter Selected
// =============================================
// Invisible dense barrier placed at doorways/chokepoints near the entrance.
// Players must interact with the chapter select terminal before proceeding.
// Once a chapter is selected, all gates on the z-level delete themselves.

/obj/structure/prostheti_chapter_gate
	name = "chapter gate"
	desc = "You should select a chapter before proceeding."
	icon = 'icons/effects/effects.dmi'
	icon_state = "info" // Visible in map editor only — alpha = 0 hides it in-game
	alpha = 0
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE
	move_resist = INFINITY

/// Allows passage once a chapter has been selected; blocks all living mobs otherwise.
/obj/structure/prostheti_chapter_gate/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(.)
		return
	var/datum/campaign_controller/prostheti/campaign = GLOB.prostheti_campaign
	if(campaign?.chapter_selected)
		return TRUE
	if(isliving(mover))
		var/mob/living/L = mover
		if(L.client)
			to_chat(L, span_warning("You need to select a chapter at the directory terminal first."))
	return FALSE

/// Registers to listen for chapter selection so it can self-delete.
/obj/structure/prostheti_chapter_gate/Initialize(mapload)
	. = ..()
	// If a chapter was already selected before this initialized, just delete
	var/datum/campaign_controller/prostheti/campaign = GLOB.prostheti_campaign
	if(campaign?.chapter_selected)
		return INITIALIZE_HINT_QDEL
	// Poll for chapter selection — SSobj process would work but a simple timer loop is lighter
	StartWaiting()

/// Periodically checks if a chapter has been selected and self-deletes when it has.
/obj/structure/prostheti_chapter_gate/proc/StartWaiting()
	addtimer(CALLBACK(src, PROC_REF(CheckGate)), 1 SECONDS)

/// Timer callback: if chapter is selected, delete self; otherwise reschedule.
/obj/structure/prostheti_chapter_gate/proc/CheckGate()
	if(QDELETED(src))
		return
	var/datum/campaign_controller/prostheti/campaign = GLOB.prostheti_campaign
	if(campaign?.chapter_selected)
		qdel(src)
		return
	addtimer(CALLBACK(src, PROC_REF(CheckGate)), 1 SECONDS)

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
	// Delay door check so the door has time to initialize first
	addtimer(CALLBACK(src, PROC_REF(LockDoor)), 3 SECONDS)
	// Override parent's INITIALIZE_HINT_QDEL — we need to persist until LockDoor fires
	return INITIALIZE_HINT_NORMAL

/// Bolts the door shut so players can't access the Training Yard early, then self-deletes.
/obj/effect/landmark/prostheti_npc_spawn/training_door/proc/LockDoor()
	var/turf/T = get_turf(src)
	for(var/obj/machinery/door/D in T)
		D.locked = TRUE
		D.update_icon()
	qdel(src)
