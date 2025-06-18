// Helper procs and extensions for NPC witness system

// Extension to track last damage for witnessing
/mob/living/carbon/human/wandering_npc
	var/list/last_damage_data = null

/mob/living/carbon/human/wandering_npc/proc/register_npc_witness_attack(mob/attacker)
	last_damage_data = list(
		"time" = world.time,
		"attacker" = attacker
	)

	// Alert nearby NPCs
	for(var/mob/living/carbon/human/wandering_npc/NPC in viewers(7, src))
		if(NPC.stat == CONSCIOUS && NPC.has_camera)
			NPC.witness_attack(attacker, src)

// Hook into attack procs
/mob/living/carbon/human/wandering_npc/attack_hand(mob/living/carbon/human/M)
	. = ..()
	if(M.a_intent == INTENT_HARM)
		register_npc_witness_attack(M)

/mob/living/carbon/human/wandering_npc/attackby(obj/item/I, mob/living/user, params)
	. = ..()
	register_npc_witness_attack(user)

/mob/living/carbon/human/wandering_npc/bullet_act(obj/projectile/P, def_zone, piercing_hit = FALSE)
	. = ..()
	if(P.firer)
		register_npc_witness_attack(P.firer)

// Photo taking integration
/obj/item/camera/proc/take_npc_evidence_photo(mob/user, atom/target, photo_name)
	if(!user || !target)
		return null

	var/obj/item/photo/P = new /obj/item/photo(get_turf(user))
	P.name = photo_name
	P.pixel_x = rand(-10, 10)
	P.pixel_y = rand(-10, 10)

	return P

// Admin verb to spawn NPCs for testing
/client/proc/spawn_wandering_npc()
	set name = "Spawn Wandering NPC"
	set category = "Debug"

	var/npc_type = input("Choose NPC type", "NPC Type") in list("Wanderer", "Housed", "Cancel")
	if(npc_type == "Cancel")
		return

	var/turf/T = get_turf(mob)
	if(!T)
		return

	switch(npc_type)
		if("Wanderer")
			var/mob/living/carbon/human/wandering_npc/NPC = new(T)
			NPC.npc_type = "wanderer"
			log_admin("[key_name(src)] spawned a wandering NPC at [COORD(T)]")
		if("Housed")
			new /mob/living/carbon/human/wandering_npc/housed(T)
			log_admin("[key_name(src)] spawned a housed NPC at [COORD(T)]")

// Admin verb to create landmarks
/client/proc/create_npc_landmark()
	set name = "Create NPC Landmark"
	set category = "Debug"

	var/landmark_type = input("Choose landmark type", "Landmark Type") in list("Wander Point", "House Door", "Association Dropoff", "NPC Spawn", "Housed Spawn", "Cancel")
	if(landmark_type == "Cancel")
		return

	var/turf/T = get_turf(mob)
	if(!T)
		return

	switch(landmark_type)
		if("Wander Point")
			new /obj/effect/landmark/wandering_npc_point(T)
		if("House Door")
			new /obj/effect/landmark/house_door_landmark(T)
		if("Association Dropoff")
			new /obj/effect/landmark/association_dropoff(T)
		if("NPC Spawn")
			new /obj/effect/landmark/wandering_npc_spawn(T)
		if("Housed Spawn")
			new /obj/effect/landmark/housed_npc_spawn(T)

	log_admin("[key_name(src)] created [landmark_type] landmark at [COORD(T)]")
