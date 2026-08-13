// Every global list, global proc and define the Door to Nowhere content uses, gathered out of
// the three files it is split across: the base abnormality (teth/door_to_nowhere.dm), the LCL
// specimen (lcl_door_to_nowhere.dm) and the LCE liminal armor (lce_ego/lce_armor.dm).

// realm of sealed regrets SYSTEM
// A standalone system for trapping players in an alternate dimension of regret and repentance
// Can be used by any game mechanic without requiring specific abnormalities

GLOBAL_LIST_EMPTY(repentance_trapped_players)         // List of all trapped players
GLOBAL_LIST_EMPTY(repentance_return_locations)        // Original locations to return players to
GLOBAL_LIST_EMPTY(repentance_status_effects)          // Status effects applied to trapped players
GLOBAL_LIST_EMPTY(repentance_spawn_points)            // Valid spawn locations in the dimension

/// Initializes repentance dimension spawn locations from landmarks
/proc/InitializeRepentanceLocations()
	GLOB.repentance_spawn_points = list()
	for(var/obj/effect/landmark/repentance_spawn/L in GLOB.landmarks_list)
		GLOB.repentance_spawn_points += get_turf(L)

	// Fallback if no landmarks exist - use z-level 1,1,1
	if(!LAZYLEN(GLOB.repentance_spawn_points))
		var/turf/T = locate(1, 1, 1)
		if(T)
			GLOB.repentance_spawn_points += T

/// Sends a player to the realm of sealed regrets
/// H - The human to send
/// send_message - Optional custom message to display (null = use default)
/// spin_effect - Whether to apply violent spinning effect
/// Returns TRUE if successful
/proc/SendToRepentanceDimension(mob/living/H, send_message = null, spin_effect = TRUE)
	if(!H || QDELETED(H))
		return FALSE

	// Already trapped check
	if(H in GLOB.repentance_trapped_players)
		return FALSE

	// Initialize spawn points if needed
	if(!LAZYLEN(GLOB.repentance_spawn_points))
		InitializeRepentanceLocations()

	// Add to global tracking
	GLOB.repentance_trapped_players += H
	GLOB.repentance_return_locations[H] = get_turf(H)

	// Display message
	if(send_message)
		to_chat(H, span_userdanger(send_message))
	else
		to_chat(H, span_userdanger("You are pulled into a strange dimension!"))

	// Apply spinning effect if requested
	if(spin_effect)
		playsound(get_turf(H), 'sound/abnormalities/dinner_chair/ragdoll_effect.ogg', 75, TRUE)
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(RepentanceViolentSpin), H)
		// Wait for spinning to finish before teleporting
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(RepentanceFinishTeleport), H), 12 SECONDS)
	else
		RepentanceFinishTeleport(H)

	return TRUE

/// Violent spinning effect for dimension transport
/proc/RepentanceViolentSpin(mob/living/M)
	if(!M || QDELETED(M))
		return

	var/matrix/initial_matrix = matrix(M.transform)
	for(var/i in 1 to 120) // 12 seconds at 0.1 second intervals
		if(!M || QDELETED(M))
			return

		// Violent rotation
		initial_matrix = matrix(M.transform)
		initial_matrix.Turn(rand(45, 180))

		// Extreme position changes
		var/x_shift = rand(-10, 10)
		var/y_shift = rand(-10, 10)
		initial_matrix.Translate(x_shift, y_shift)

		animate(M, transform = initial_matrix, time = 1, loop = 0, easing = pick(LINEAR_EASING, SINE_EASING, CIRCULAR_EASING))

		// Rapid direction changes
		M.setDir(pick(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST))

		sleep(1)

	// Reset transformation
	animate(M, transform = null, time = 5, loop = 0)

/// Completes the teleportation to realm of sealed regrets
/proc/RepentanceFinishTeleport(mob/living/H)
	if(!H || QDELETED(H) || !(H in GLOB.repentance_trapped_players))
		return

	to_chat(H, span_warning("You find yourself in the realm of sealed regrets."))
	to_chat(H, span_warning("The air is heavy with regret and the weight of unspoken apologies."))

	playsound(get_turf(H), 'sound/effects/podwoosh.ogg', 50, TRUE)

	// Pick a random repentance dimension location
	var/turf/destination
	if(LAZYLEN(GLOB.repentance_spawn_points))
		destination = pick(GLOB.repentance_spawn_points)
	else
		destination = locate(1, 1, 1) // Emergency fallback

	if(destination)
		H.forceMove(destination)

	H.Stun(30)

	// The confession recorder and the sanity hit are for people. Anything else the dimension
	// takes - an LCL specimen pulled in by the hands - just arrives.
	if(ishuman(H))
		var/mob/living/carbon/human/victim = H
		victim.adjustSanityLoss(20)

		// Spawn an empty tape recorder for them to record their regrets
		var/obj/item/taperecorder/empty/recorder = new /obj/item/taperecorder/empty(destination)
		to_chat(victim, span_notice("A tape recorder materializes before you, as if the dimension itself wants to hear your confession..."))

		// Try to put it in their hand if possible
		if(!victim.put_in_hands(recorder))
			// If hands are full, place it next to them
			recorder.forceMove(get_step(destination, pick(NORTH, SOUTH, EAST, WEST)))

	// Apply repentance dimension status effect
	var/datum/status_effect/repentance_ambience/B = H.apply_status_effect(/datum/status_effect/repentance_ambience)
	if(B)
		GLOB.repentance_status_effects[H] = B

/// Rescues a player from the realm of sealed regrets
/// H - The human to rescue
/// return_turf - Optional specific return location (null = use saved location)
/// rescue_message - Optional custom message (null = use default)
/// Returns TRUE if successful
/proc/RescueFromRepentanceDimension(mob/living/H, turf/return_turf = null, rescue_message = null)
	if(!H || QDELETED(H))
		return FALSE

	// Not trapped check
	if(!(H in GLOB.repentance_trapped_players))
		return FALSE

	// Remove from global tracking
	GLOB.repentance_trapped_players -= H

	// Determine return location
	if(!return_turf)
		return_turf = GLOB.repentance_return_locations[H]
	if(!return_turf)
		// Find a safe station turf as fallback
		for(var/turf/T in GLOB.station_turfs)
			if(!T.density)
				return_turf = T
				break
	if(!return_turf)
		return_turf = locate(1, 1, 1) // Ultimate fallback

	GLOB.repentance_return_locations -= H

	// Remove status effect
	if(GLOB.repentance_status_effects[H])
		H.remove_status_effect(/datum/status_effect/repentance_ambience)
		GLOB.repentance_status_effects -= H

	// Display message
	if(rescue_message)
		to_chat(H, span_nicegreen(rescue_message))
	else
		to_chat(H, span_nicegreen("You feel a pull back to reality!"))

	playsound(get_turf(H), 'sound/magic/teleport_app.ogg', 50, TRUE)

	// Teleport back
	H.forceMove(return_turf)

	return TRUE

/// Checks if a player is trapped in the realm of sealed regrets
/proc/IsTrappedInRepentance(mob/living/H)
	if(!H)
		return FALSE
	return (H in GLOB.repentance_trapped_players)

/// Returns a list of all trapped players
/proc/GetRepentanceTrappedList()
	return GLOB.repentance_trapped_players.Copy()

/// Rescues all trapped players (for emergency use)
/proc/RescueAllFromRepentance(rescue_message = "The dimension collapses, ejecting everyone!")
	for(var/mob/living/H in GLOB.repentance_trapped_players.Copy())
		RescueFromRepentanceDimension(H, null, rescue_message)

/*			THE SHRINE REGISTER			*/

// Add to globals
GLOBAL_LIST_EMPTY(regret_shrines)

/*			FINDING A DOOR			*/

/// The door the projection stands beside. Either kind counts, the LCL specimen first.
/proc/FindDoorToNowhere()
	for(var/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/D in GLOB.mob_living_list)
		return D
	for(var/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/D in GLOB.abnormality_mob_list)
		return D
	return null

/proc/AnyDoorToNowhereExists()
	return !isnull(FindDoorToNowhere())

/*			WHO IS INSIDE THE REALM			*/

///Everything living standing in the Realm, the door's own spirit aside. Scans GLOB.mob_living_list
///rather than GLOB.player_list, which is Login/Logout bookkeeping and misses anyone currently SSD.
/proc/GetRealmOccupants()
	var/list/found = list()
	for(var/mob/living/L in GLOB.mob_living_list)
		if(QDELETED(L) || istype(L, /mob/living/simple_animal/hostile/regret_spirit))
			continue
		if(!istype(get_area(L), /area/fishboat/repentance))
			continue
		found += L
	return found

/*			THE WHISPER			*/

//Inlined rather than span_revennotice(), whose class is light purple on the dark chat theme
//and near-black navy on the light one.
#define DTN_WHISPER_COLOUR "#c099e2"

/proc/DTNWhisperText(text, bold = FALSE)
	return "<span style='color: [DTN_WHISPER_COLOUR][bold ? "; font-weight: bold" : ""]'>[text]</span>"

///Whispers reach no channel observers can hear, so they are echoed to ghosts by hand.
/proc/RelayWhisperToGhosts(atom/movable/speaker, message, mob/target)
	if(!speaker || !message)
		return
	for(var/mob/dead/observer/O in GLOB.dead_mob_list)
		var/line = "[FOLLOW_LINK(O, speaker)] [DTNWhisperText("<b>[speaker]</b> whispers:", TRUE)] [DTNWhisperText("\"[message]\"")]"
		if(target)
			line += " [DTNWhisperText("to")] [FOLLOW_LINK(O, target)] [span_name("[target]")]"
		to_chat(O, line)

/*			PROJECTING OUT OF A BODY			*/

///transfer_to() fires Login() on the destination, and /mob/living/Login() dumps the whole
///stored memory to chat. Projecting and returning would reprint the abno's instructions every
///time, so the memory is held aside across the swap. The Notes verb still shows it on demand.
/proc/QuietMindTransfer(datum/mind/M, mob/destination)
	if(!M || !destination)
		return
	var/saved_memory = M.memory
	M.memory = ""
	M.transfer_to(destination)
	M.memory = saved_memory

/*			THE SEAL REGISTER			*/

///mob -> the door holding them. A flat GLOB so the reality void, in the shared abnormality
///file, can test for a seal without referencing an LCL type.
GLOBAL_LIST_EMPTY(dtn_sealed_captives)

/// TRUE if this mob is being held inside the Realm by a sealing door.
/proc/IsSealedByDoor(mob/living/carbon/human/H)
	if(!H)
		return FALSE
	return !isnull(GLOB.dtn_sealed_captives[H])

///The only exit from a seal: dropped beside the door, killed, immunity stamped. Walking out,
///Disgorge, the void and the door's death all route here.
/proc/EjectSealedCaptive(mob/living/carbon/human/H)
	var/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/D = GLOB.dtn_sealed_captives[H]
	if(!D || QDELETED(D))
		GLOB.dtn_sealed_captives -= H
		return FALSE
	return D.ReleaseSealed(H)

/*			THE BUILD PALETTE			*/

///category name -> list(label -> typepath). Built once, on the first Furnish press.
GLOBAL_LIST_EMPTY(dtn_build_palette)

///Labels each path by its own name, falling back to the last path segment then the full path.
///Many of these share a name - every carpet is "carpet" - and a collision would drop an entry.
/proc/DTNAddToPalette(list/into, list/paths)
	for(var/path in paths)
		var/atom/A = path
		var/label = initial(A.name)
		if(!label)
			label = "[path]"
		if(into[label])
			var/list/bits = splittext("[path]", "/")
			label = "[label] ([bits[bits.len]])"
		if(into[label])
			label = "[path]"
		into[label] = path

///Walls are drawn only from the indestructible tree, so placed walls cannot be broken.
/proc/BuildDTNPalette()
	var/list/walls = list()
	DTNAddToPalette(walls, list(
		/turf/closed/indestructible,
		/turf/closed/indestructible/r_wall,
		/turf/closed/indestructible/rust,
		/turf/closed/indestructible/sandstone,
		/turf/closed/indestructible/oldshuttle,
		/turf/closed/indestructible/wood,
		/turf/closed/indestructible/syndicate,
		/turf/closed/indestructible/necropolis,
		/turf/closed/indestructible/brick,
		/turf/closed/indestructible/abductor,
		/turf/closed/indestructible/alien,
		/turf/closed/indestructible/reinforced/cheap,
	))
	DTNAddToPalette(walls, subtypesof(/turf/closed/indestructible/reinforced/cheap))

	var/list/floors = list()
	DTNAddToPalette(floors, list(/turf/open/floor/lce))
	DTNAddToPalette(floors, subtypesof(/turf/open/floor/lce))
	DTNAddToPalette(floors, list(
		/turf/open/floor/plating,
		/turf/open/floor/plating/rust,
		/turf/open/floor/plating/sandy_dirt,
		/turf/open/floor/plating/ironsand,
		/turf/open/floor/wood,
		/turf/open/floor/stone,
		/turf/open/floor/bronze,
		/turf/open/floor/bluespace,
		/turf/open/floor/eighties,
		/turf/open/floor/glass,
		/turf/open/floor/glass/reinforced,
		/turf/open/floor/fakespace,
		/turf/open/floor/fakepit,
		/turf/open/floor/facility/halls,
		/turf/open/floor/distortion/another_day,
		/turf/open/floor/plasteel/cult,
		/turf/open/floor/plasteel/vaporwave,
		/turf/open/floor/holofloor/grass,
		/turf/open/floor/holofloor/snow,
		/turf/open/floor/holofloor/wood,
		/turf/open/floor/mineral/plastitanium,
		/turf/open/floor/mineral/plastitanium/red,
		/turf/open/floor/mineral/titanium/tiled,
		/turf/open/floor/mineral/titanium/tiled/blue,
		/turf/open/floor/mineral/titanium/tiled/purple,
		/turf/open/floor/mineral/titanium/tiled/white,
		/turf/open/floor/mineral/titanium/tiled/yellow,
		/turf/open/floor/mineral/titanium/white,
		/turf/open/floor/mineral/titanium/yellow,
		/turf/open/floor/carpet,
		/turf/open/floor/carpet/black,
		/turf/open/floor/carpet/blue,
		/turf/open/floor/carpet/cyan,
		/turf/open/floor/carpet/donk,
		/turf/open/floor/carpet/executive,
		/turf/open/floor/carpet/green,
		/turf/open/floor/carpet/lone,
		/turf/open/floor/carpet/orange,
		/turf/open/floor/carpet/purple,
		/turf/open/floor/carpet/red,
		/turf/open/floor/carpet/royalblack,
		/turf/open/floor/carpet/royalblue,
	))

	var/list/tables = list()
	DTNAddToPalette(tables, list(
		/obj/structure/table,
		/obj/structure/table/wood,
		/obj/structure/table/wood/fancy,
		/obj/structure/table/wood/fancy/black,
		/obj/structure/table/wood/fancy/blue,
		/obj/structure/table/wood/fancy/cyan,
		/obj/structure/table/wood/fancy/green,
		/obj/structure/table/wood/fancy/orange,
		/obj/structure/table/wood/fancy/purple,
		/obj/structure/table/wood/fancy/red,
		/obj/structure/table/wood/fancy/royalblack,
		/obj/structure/table/wood/fancy/royalblue,
		/obj/structure/table/reinforced,
		/obj/structure/table/bronze,
		/obj/structure/table/glass,
		/obj/structure/table/abductor,
		/obj/structure/rack,
	))

	var/list/seating = list()
	DTNAddToPalette(seating, list(
		/obj/structure/chair,
		/obj/structure/chair/wood,
		/obj/structure/chair/wood/wings,
		/obj/structure/chair/bronze,
		/obj/structure/chair/comfy,
		/obj/structure/chair/stool,
		/obj/structure/chair/stool/bar,
	))
	DTNAddToPalette(seating, subtypesof(/obj/structure/chair/comfy))

	var/list/bedding = list()
	DTNAddToPalette(bedding, list(/obj/structure/bed))
	DTNAddToPalette(bedding, subtypesof(/obj/structure/bed))
	DTNAddToPalette(bedding, list(
		/obj/structure/dresser,
		/obj/structure/closet/cabinet,
		/obj/structure/closet/crate/bin,
		/obj/structure/bookcase,
	))

	var/list/openings = list()
	DTNAddToPalette(openings, list(
		/obj/structure/regret_door/custom, //Skips generate_regret_identity() and its spirit mob.
		/obj/structure/mineral_door,
	))
	DTNAddToPalette(openings, subtypesof(/obj/structure/mineral_door))
	DTNAddToPalette(openings, list(
		/obj/structure/window/fulltile,
		/obj/structure/window/bronze/fulltile,
		/obj/structure/window/reinforced/lce/fulltile,
		/obj/structure/curtain,
		/obj/structure/curtain/bounty,
		/obj/structure/barricade/wooden,
		/obj/structure/barricade/wooden/crude,
	))

	var/list/fixtures = list()
	DTNAddToPalette(fixtures, list(
		/obj/machinery/light,
		/obj/item/candle,
		/obj/structure/fluff,
		/obj/structure/fluff/street_light,
		/obj/structure/fluff/empty_terrarium,
		/obj/structure/fluff/fokoff_sign,
		/obj/structure/fluff/arc,
		/obj/structure/fluff/arc/angela,
	))

	var/list/machines = list()
	DTNAddToPalette(machines, list(
		/obj/machinery/jukebox/unlocked,
		/obj/machinery/computer/slot_machine,
		/obj/machinery/computer/arcade,
	))
	DTNAddToPalette(machines, subtypesof(/obj/machinery/computer/arcade))

	GLOB.dtn_build_palette = list(
		"Walls" = walls,
		"Floors" = floors,
		"Tables" = tables,
		"Seating" = seating,
		"Beds & Storage" = bedding,
		"Doors & Windows" = openings,
		"Fixtures & Lighting" = fixtures,
		"Machines" = machines,
	)

GLOBAL_LIST_INIT(dtn_build_dirs, list(
	"South" = SOUTH,
	"North" = NORTH,
	"East" = EAST,
	"West" = WEST,
	"Whichever way I am facing" = NORTHWEST,
))
