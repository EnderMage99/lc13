// Wandering NPC system for city gamemode
// These NPCs wander between landmarks, take photos of crimes, and report to associations

/mob/living/carbon/human/wandering_npc
	name = "city resident"
	real_name = "city resident"
	// Home turf is defined in housed subtype
	var/obj/effect/landmark/current_landmark // Current destination
	var/list/visited_landmarks = list() // Track visited locations
	var/landmark_wait_time = 5 SECONDS
	var/next_wander_time = 0
	var/has_camera = FALSE
	var/obj/item/camera/npc_camera
	var/list/witnessed_crimes = list() // Prevent spam reporting same incident
	var/npc_type = "wanderer" // "wanderer" or "housed"
	var/photo_cooldown = 0 // Cooldown for taking photos
	var/flee_end_time = 0 // When to stop fleeing
	var/mob/flee_target = null // Who we're running from
	var/list/pending_photo_deliveries = list() // Track scheduled photo deliveries
	var/is_wandering = FALSE // Track if currently wandering
	var/last_movement_check = 0 // Last time we verified movement

/mob/living/carbon/human/wandering_npc/Initialize()
	. = ..()
	// Defer setup to avoid sleep in Initialize
	addtimer(CALLBACK(src, PROC_REF(setup_npc)), 0)

/mob/living/carbon/human/wandering_npc/proc/setup_npc()
	// Set up as a basic human
	set_species(/datum/species/human)

	// Give them a random appearance
	randomize_human(src)

	// Equip with civilian outfit
	equipOutfit(/datum/outfit/wandering_npc)

	// Start wandering behavior
	if(npc_type == "wanderer")
		addtimer(CALLBACK(src, PROC_REF(start_wandering)), 2 SECONDS)
		// Start watchdog timer to prevent getting stuck
		addtimer(CALLBACK(src, PROC_REF(check_wandering_status)), 2 MINUTES, TIMER_STOPPABLE | TIMER_LOOP)

/mob/living/carbon/human/wandering_npc/Destroy()
	npc_camera = null
	return ..()

/mob/living/carbon/human/wandering_npc/death(gibbed)
	// Stop any movement immediately
	walk(src, 0)
	flee_target = null
	flee_end_time = 0
	
	// Cancel all pending photo deliveries
	for(var/timer_id in pending_photo_deliveries)
		deltimer(timer_id)
	pending_photo_deliveries.Cut()
	
	return ..()

/datum/outfit/wandering_npc
	name = "Wandering NPC"
	uniform = /obj/item/clothing/under/suit/charcoal
	shoes = /obj/item/clothing/shoes/sneakers/black
	back = /obj/item/storage/backpack

/datum/outfit/wandering_npc/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	. = ..()
	if(visualsOnly)
		return

	// Add money to backpack
	var/obj/item/stack/spacecash/cash = new(H.back)
	cash.amount = rand(600, 1000)

	// 25% chance for camera
	if(prob(25))
		var/obj/item/camera/C = new(H.back)
		var/mob/living/carbon/human/wandering_npc/NPC = H
		NPC.has_camera = TRUE
		NPC.npc_camera = C

// Watchdog to prevent getting stuck
/mob/living/carbon/human/wandering_npc/proc/check_wandering_status()
	// Only check wanderer type NPCs that are alive
	if(npc_type != "wanderer" || stat != CONSCIOUS)
		return
		
	// Don't interfere if fleeing
	if(flee_end_time > world.time)
		return
		
	// Don't interfere if waiting at landmark
	if(next_wander_time > world.time)
		return
		
	// Check if we should be wandering but aren't
	if(!is_wandering)
		// Give a small grace period after various activities
		if(world.time - last_movement_check > 10 SECONDS)
			// Force start wandering
			visible_message(span_notice("[src] looks around and starts walking again."))
			start_wandering()
			last_movement_check = world.time

// Fleeing behavior
/mob/living/carbon/human/wandering_npc/proc/start_fleeing(mob/threat)
	if(stat != CONSCIOUS || !threat)
		return

	// Stop current wandering
	walk(src, 0)
	is_wandering = FALSE

	// Set flee state
	flee_target = threat
	flee_end_time = world.time + 5 SECONDS

	// Panic dialogue
	say(pick("AAAH!", "Oh no!", "Help!", "Get away from me!", "Someone help!"))

	// Run away from threat at increased speed
	walk_away(src, threat, 7, 2) // Run 7 tiles away at speed 2 (faster than normal)

/mob/living/carbon/human/wandering_npc/proc/stop_fleeing()
	walk(src, 0)
	flee_target = null
	flee_end_time = 0
	
	// Only say things and resume wandering if alive
	if(stat == CONSCIOUS)
		say(pick("That was scary...", "I think I'm safe now.", "I need to calm down..."))
		// Resume wandering after a moment
		addtimer(CALLBACK(src, PROC_REF(start_wandering)), 2 SECONDS)

// Wandering behavior
/mob/living/carbon/human/wandering_npc/proc/start_wandering()
	if(stat != CONSCIOUS)
		return

	// Don't wander if we're fleeing
	if(flee_end_time > world.time)
		return

	// Find a new landmark to wander to
	var/list/possible_landmarks = list()
	for(var/obj/effect/landmark/wandering_npc_point/L in GLOB.wandering_npc_landmarks)
		if(L.z == z && L != current_landmark)
			possible_landmarks += L

	if(!length(possible_landmarks))
		// Try again later if no landmarks found
		addtimer(CALLBACK(src, PROC_REF(start_wandering)), 10 SECONDS)
		return

	// Pick a random landmark
	current_landmark = pick(possible_landmarks)

	// Start moving towards it
	walk_to(src, current_landmark, 1, 4)
	is_wandering = TRUE
	last_movement_check = world.time

	// Check if we've arrived
	addtimer(CALLBACK(src, PROC_REF(check_arrival)), 2 SECONDS)

/mob/living/carbon/human/wandering_npc/proc/check_arrival()
	if(stat != CONSCIOUS)
		return

	if(get_dist(src, current_landmark) <= 1)
		// We've arrived!
		walk(src, 0) // Stop walking
		is_wandering = FALSE
		visited_landmarks |= current_landmark

		// Wait at landmark
		next_wander_time = world.time + landmark_wait_time
		last_movement_check = world.time
		addtimer(CALLBACK(src, PROC_REF(start_wandering)), landmark_wait_time)
	else
		// Keep checking
		addtimer(CALLBACK(src, PROC_REF(check_arrival)), 2 SECONDS)

// Crime witnessing behavior
/mob/living/carbon/human/wandering_npc/proc/witness_attack(mob/living/attacker, mob/living/victim)
	// Start fleeing from the attacker
	start_fleeing(attacker)

	if(!has_camera || !npc_camera || stat != CONSCIOUS)
		return

	// Don't report the same incident twice
	var/incident_key = "[attacker.real_name]_[victim.real_name]_[world.time]"
	if(incident_key in witnessed_crimes)
		return

	witnessed_crimes += incident_key

	// Check photo cooldown
	if(world.time < photo_cooldown)
		return // Still flee, but don't take photo

	// Set photo cooldown to 1 minute
	photo_cooldown = world.time + 1 MINUTES

	// Take a photo while fleeing
	visible_message(span_notice("[src] quickly snaps a photo while running away!"))

	// Create and send the photo report
	addtimer(CALLBACK(src, PROC_REF(send_crime_photo), attacker, victim, "assault"), 1 SECONDS)

/mob/living/carbon/human/wandering_npc/proc/witness_corpse(mob/living/carbon/human/corpse)
	if(!has_camera || !npc_camera || stat != CONSCIOUS)
		return

	// Don't report the same body twice
	var/incident_key = "corpse_[corpse.real_name]_[corpse.timeofdeath]"
	if(incident_key in witnessed_crimes)
		return

	witnessed_crimes += incident_key

	// Check photo cooldown
	if(world.time < photo_cooldown)
		return

	// Set photo cooldown to 1 minute
	photo_cooldown = world.time + 1 MINUTES

	// Take a photo
	visible_message(span_notice("[src] gasps and takes a photo of the body!"))

	// Create and send the photo report
	addtimer(CALLBACK(src, PROC_REF(send_crime_photo), corpse, null, "corpse"), 1 SECONDS)

/mob/living/carbon/human/wandering_npc/proc/send_crime_photo(mob/target, mob/victim, crime_type)
	if(!npc_camera || !target)
		return

	// Set camera name for the photo
	var/old_default_name = npc_camera.default_picture_name
	switch(crime_type)
		if("assault")
			npc_camera.default_picture_name = "Evidence: [target.name] attacking [victim.name]"
		if("corpse")
			npc_camera.default_picture_name = "Evidence: Body of [target.name]"

	// Take the photo using the camera
	npc_camera.pictures_left = max(1, npc_camera.pictures_left) // Ensure we have at least 1 photo

	// Remove camera from backpack temporarily
	var/obj/item/storage/backpack/B = back
	if(B && (npc_camera in B.contents))
		npc_camera.forceMove(src)

	// Use camera's captureimage to take photo centered on target
	if(npc_camera.can_target(target, src, TRUE))
		npc_camera.captureimage(target, src, TRUE)

		// Find the newly created photo in our contents
		for(var/obj/item/photo/P in contents)
			// Store the photo in backpack instead of sending immediately
			if(B)
				P.forceMove(B)
				P.desc = "Evidence of [crime_type] - waiting to be delivered."
			break

	// Put camera back in backpack
	if(B)
		npc_camera.forceMove(B)

	npc_camera.default_picture_name = old_default_name

	say("I need to get this evidence to safety...")
	
	// Schedule photo delivery after 45 seconds
	var/timer_id = addtimer(CALLBACK(src, PROC_REF(deliver_photos)), 45 SECONDS, TIMER_STOPPABLE)
	pending_photo_deliveries += timer_id

/mob/living/carbon/human/wandering_npc/proc/deliver_photos()
	// Only deliver if still alive
	if(stat != CONSCIOUS)
		return
		
	// Find association landmark
	var/obj/effect/landmark/association_dropoff/dropoff
	for(var/obj/effect/landmark/association_dropoff/A in GLOB.association_landmarks)
		if(A.z == z)
			dropoff = A
			break
			
	if(!dropoff)
		say("I can't find where to deliver these photos...")
		return
		
	// Get backpack
	var/obj/item/storage/backpack/B = back
	if(!B)
		return
		
	// Deliver all photos in backpack
	var/photos_delivered = 0
	for(var/obj/item/photo/P in B.contents)
		P.forceMove(dropoff.loc)
		P.desc += " Submitted by [real_name] after surviving to deliver evidence."
		photos_delivered++
		
	if(photos_delivered)
		say("I've successfully delivered [photos_delivered] photo\s to the association!")
		visible_message(span_notice("[src] looks relieved as they finish their delivery."))
	
	// Clear this delivery from pending list
	pending_photo_deliveries.Cut()

// Life() checks for witnessing crimes
/mob/living/carbon/human/wandering_npc/Life()
	. = ..()
	if(stat != CONSCIOUS)
		return

	// Check if we should stop fleeing
	if(flee_end_time && world.time >= flee_end_time)
		stop_fleeing()

	// Check for attacks in view
	for(var/mob/living/carbon/human/wandering_npc/L in view(7, src))
		// Check if being attacked
		if(L.last_damage_data && world.time - L.last_damage_data["time"] < 2 SECONDS)
			var/mob/attacker = L.last_damage_data["attacker"]
			if(attacker && attacker != L)
				witness_attack(attacker, L)

		// Check for corpses
		if(L.stat == DEAD && ishuman(L))
			witness_corpse(L)

// Landmark for wandering points
/obj/effect/landmark/wandering_npc_point
	name = "wandering npc landmark"
	icon_state = "x"

GLOBAL_LIST_EMPTY(wandering_npc_landmarks)

/obj/effect/landmark/wandering_npc_point/Initialize()
	. = ..()
	GLOB.wandering_npc_landmarks += src

/obj/effect/landmark/wandering_npc_point/Destroy()
	GLOB.wandering_npc_landmarks -= src
	return ..()

// Association dropoff point for photos
/obj/effect/landmark/association_dropoff
	name = "association dropoff"
	icon_state = "x2"

GLOBAL_LIST_EMPTY(association_landmarks)

/obj/effect/landmark/association_dropoff/Initialize()
	. = ..()
	GLOB.association_landmarks += src

/obj/effect/landmark/association_dropoff/Destroy()
	GLOB.association_landmarks -= src
	return ..()

// Spawn building with one-way exit
/obj/effect/landmark/wandering_npc_spawn
	name = "wandering npc spawn"
	icon_state = "x3"

/obj/effect/landmark/wandering_npc_spawn/Initialize()
	. = ..()
	// Spawn an NPC here
	INVOKE_ASYNC(src, PROC_REF(spawn_npc))

/obj/effect/landmark/wandering_npc_spawn/proc/spawn_npc()
	var/mob/living/carbon/human/wandering_npc/NPC = new(loc)
	NPC.npc_type = "wanderer"

// One-way exit door
/obj/machinery/door/airlock/public/glass/npc_exit
	name = "exit only"
	desc = "This door only opens from the inside."
	req_access = list() // No access required from inside

/obj/machinery/door/airlock/public/glass/npc_exit/allowed(mob/M)
	// Only allow opening from the inside (same tile or behind the door)
	var/turf/T = get_turf(M)
	if(!T)
		return FALSE

	// Check if they're on the "inside" based on dir
	var/turf/inside_turf = get_step(src, turn(dir, 180))
	if(T == loc || T == inside_turf)
		return TRUE

	return FALSE

/obj/machinery/door/airlock/public/glass/npc_exit/CanAStarPass(obj/item/card/id/ID, to_dir, atom/movable/caller, no_id = FALSE)
	// NPCs can always exit
	if(istype(caller, /mob/living/carbon/human/wandering_npc))
		return TRUE
	return ..()
