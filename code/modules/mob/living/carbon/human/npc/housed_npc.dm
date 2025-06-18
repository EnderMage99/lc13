// Housed NPC variant - NPCs that live in houses and protect their homes

/mob/living/carbon/human/wandering_npc/housed
	name = "homeowner"
	real_name = "homeowner"
	npc_type = "housed"
	var/obj/effect/landmark/house_door_landmark/door_landmark
	var/turf/home_turf // Use different name to avoid conflict
	var/list/warned_intruders = list()
	var/warning_cooldown = 0
	var/doorbell_response_active = FALSE

/mob/living/carbon/human/wandering_npc/housed/Initialize()
	. = ..()
	// Store home turf
	home_turf = get_turf(src)

	// Find the closest door landmark
	var/min_distance = INFINITY
	for(var/obj/effect/landmark/house_door_landmark/L in GLOB.house_door_landmarks)
		if(L.z != z)
			continue
		var/dist = get_dist(src, L)
		if(dist < min_distance)
			min_distance = dist
			door_landmark = L

/datum/outfit/housed_npc
	name = "Housed NPC"
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black
	back = /obj/item/storage/backpack

/datum/outfit/housed_npc/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	. = ..()
	if(visualsOnly)
		return

	// Add money to backpack (less than wanderers)
	var/obj/item/stack/spacecash/cash = new(H.back)
	cash.amount = rand(400, 600)

	// Add random household items
	if(prob(50))
		new /obj/item/lighter(H.back)
	if(prob(30))
		new /obj/item/storage/wallet(H.back)
	if(prob(20))
		new /obj/item/flashlight(H.back)

/mob/living/carbon/human/wandering_npc/housed/equipOutfit(outfit, visualsOnly = FALSE)
	. = ..(new /datum/outfit/housed_npc, visualsOnly)

// Check for intruders
/mob/living/carbon/human/wandering_npc/housed/Life()
	. = ..()
	if(!. || stat != CONSCIOUS)
		return

	// Check for intruders in our home
	if(world.time > warning_cooldown)
		var/area/A = get_area(src)
		if(istype(A, /area/city/house))
			for(var/mob/living/carbon/human/H in A)
				if(H == src || !H.ckey) // Ignore self and other NPCs
					continue

				if(!(H in warned_intruders))
					warn_intruder(H)

/mob/living/carbon/human/wandering_npc/housed/proc/warn_intruder(mob/living/carbon/human/intruder)
	warned_intruders += intruder
	warning_cooldown = world.time + 10 SECONDS

	say("Hey! What are you doing in my house? Get out!")

	// Start 5 second timer
	addtimer(CALLBACK(src, PROC_REF(report_intruder), intruder), 5 SECONDS)

/mob/living/carbon/human/wandering_npc/housed/proc/report_intruder(mob/living/carbon/human/intruder)
	// Check if they're still in our house
	if(!intruder || intruder.z != z)
		warned_intruders -= intruder
		return

	var/area/A = get_area(src)
	var/area/intruder_area = get_area(intruder)

	if(A != intruder_area || !istype(A, /area/city/house))
		warned_intruders -= intruder
		return

	// Send radio message about home invasion
	var/message = "[intruder.real_name] is invading my home at [A.name]! Send help!"

	// Use radio to announce
	say(message)
	to_chat(intruder, span_warning("The homeowner has reported you to the authorities!"))

	say("I'm calling the association! The police are on their way!")

	// Clear them from warned list after some time
	addtimer(CALLBACK(src, PROC_REF(clear_warned), intruder), 30 SECONDS)

/mob/living/carbon/human/wandering_npc/housed/proc/clear_warned(mob/living/carbon/human/intruder)
	warned_intruders -= intruder

// Doorbell response
/mob/living/carbon/human/wandering_npc/housed/proc/respond_to_doorbell()
	if(doorbell_response_active || !door_landmark || stat != CONSCIOUS)
		return

	doorbell_response_active = TRUE

	say("Coming!")
	var/turf/door_turf = get_turf(door_landmark)
	for(var/obj/machinery/door/locked_door in door_turf.contents)
		locked_door.open()

	// Walk to door
	walk_to(src, door_landmark, 0, 2)

	// Check when we arrive
	addtimer(CALLBACK(src, PROC_REF(check_door_arrival)), 1 SECONDS)

/mob/living/carbon/human/wandering_npc/housed/proc/check_door_arrival()
	if(get_dist(src, door_landmark) <= 1)
		// We're at the door
		walk(src, 0)
		dir = door_landmark.dir

		say(pick("Yes? Who is it?", "Can I help you?", "What do you want?"))

		// Wait a bit then return home
		addtimer(CALLBACK(src, PROC_REF(return_home)), rand(3 SECONDS, 5 SECONDS))
	else
		// Keep checking
		addtimer(CALLBACK(src, PROC_REF(check_door_arrival)), 1 SECONDS)

/mob/living/carbon/human/wandering_npc/housed/proc/return_home()
	doorbell_response_active = FALSE

	if(!home_turf)
		return

	say(pick("Nobody there...", "Must have left.", "Hmm..."))

	// Walk back to original position
	walk_to(src, home_turf, 0, 2)

	// Stop walking when we get home
	addtimer(CALLBACK(src, PROC_REF(stop_walking)), 3 SECONDS)

/mob/living/carbon/human/wandering_npc/housed/proc/stop_walking()
	walk(src, 0)

// House door landmark
/obj/effect/landmark/house_door_landmark
	name = "house door landmark"
	icon_state = "x4"
	var/obj/structure/doorbell/connected_doorbell

GLOBAL_LIST_EMPTY(house_door_landmarks)

/obj/effect/landmark/house_door_landmark/Initialize()
	. = ..()
	GLOB.house_door_landmarks += src

	// Create doorbell next to this landmark
	var/turf/bell_turf = get_step(src, turn(dir, 90))
	if(bell_turf)
		connected_doorbell = new /obj/structure/doorbell(bell_turf)
		connected_doorbell.connected_landmark = src

/obj/effect/landmark/house_door_landmark/Destroy()
	GLOB.house_door_landmarks -= src
	if(connected_doorbell)
		qdel(connected_doorbell)
	return ..()

// Doorbell structure
/obj/structure/doorbell
	name = "doorbell"
	desc = "A simple doorbell. Ring it to get the homeowner's attention."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "doorctrl"
	anchored = TRUE
	density = FALSE
	var/obj/effect/landmark/house_door_landmark/connected_landmark
	var/ring_cooldown = 0

/obj/structure/doorbell/attack_hand(mob/user)
	. = ..()
	if(world.time < ring_cooldown)
		to_chat(user, span_warning("You just rang it! Give them a moment."))
		return

	ring_cooldown = world.time + 5 SECONDS

	// Visual feedback
	flick("doorctrl1", src)
	playsound(src, 'sound/machines/ding.ogg', 50, TRUE)

	user.visible_message(span_notice("[user] rings the doorbell."), \
		span_notice("You ring the doorbell."))

	// Find the NPC in this house
	if(connected_landmark)
		var/area/A = get_area(connected_landmark)
		for(var/mob/living/carbon/human/wandering_npc/housed/NPC in A)
			if(NPC.stat == CONSCIOUS)
				NPC.respond_to_doorbell()
				break

// House NPC spawn landmark
/obj/effect/landmark/housed_npc_spawn
	name = "housed npc spawn"
	icon_state = "x5"

/obj/effect/landmark/housed_npc_spawn/Initialize()
	. = ..()
	// Spawn a housed NPC here
	INVOKE_ASYNC(src, PROC_REF(spawn_npc))

/obj/effect/landmark/housed_npc_spawn/proc/spawn_npc()
	new /mob/living/carbon/human/wandering_npc/housed(loc)

// House area definition
/area/city/house
	name = "Residential House"
	icon_state = "house"
