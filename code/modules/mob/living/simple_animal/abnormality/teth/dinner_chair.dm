/mob/living/simple_animal/hostile/abnormality/dinner_chair
	name = "wooden chair"
	desc = "Bar brawl essential."
	icon = 'icons/obj/chairs.dmi'
	icon_state = "wooden_chair"
	icon_living = "wooden_chair"
	icon_dead = "wooden_chair"
	maxHealth = 400
	health = 400
	threat_level = TETH_LEVEL
	move_to_delay = 4
	damage_coeff = list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 2)
	melee_damage_lower = 8
	melee_damage_upper = 12
	melee_damage_type = RED_DAMAGE
	attack_verb_continuous = "slams into"
	attack_verb_simple = "slam into"
	attack_sound = 'sound/weapons/genhit1.ogg'
	can_breach = FALSE
	start_qliphoth = 3
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(70, 70, 65, 65, 65),
		ABNORMALITY_WORK_INSIGHT = list(70, 70, 65, 65, 65),
		ABNORMALITY_WORK_ATTACHMENT = list(30, 30, 25, 25, 25),
		ABNORMALITY_WORK_REPRESSION = list(10, 10, 5, 0, 0),
	)
	work_damage_amount = 6
	work_damage_type = WHITE_DAMAGE

	ego_list = list(
		/datum/ego_datum/weapon/liminal,
		/datum/ego_datum/armor/liminal,
	)
	gift_type = /datum/ego_gifts/liminal
	abnormality_origin = ABNORMALITY_ORIGIN_ORIGINAL

	observation_prompt = "You examine the chair closely. It seems like an ordinary dinner chair, but..."
	observation_choices = list(
		"The wood grain forms impossible patterns" = list(TRUE, "You notice the wood grain seems to spiral inward infinitely, like a portal to somewhere else."),
		"It's just a normal chair" = list(FALSE, "You dismiss your concerns. It's just a chair, after all."),
	)

	var/list/trapped_employees = list()
	var/list/original_locations = list()
	var/list/backrooms_locations = list()
	var/list/backrooms_effects = list() // Track status effects

/mob/living/simple_animal/hostile/abnormality/dinner_chair/PostSpawn()
	..()
	// Find all backrooms landmarks
	for(var/obj/effect/landmark/backrooms_spawn/L in GLOB.landmarks_list)
		backrooms_locations += get_turf(L)

	// Fallback if no landmarks exist
	if(!LAZYLEN(backrooms_locations))
		var/turf/T = locate(1, 1, z)
		if(T)
			backrooms_locations += T
		else
			backrooms_locations += get_turf(src)

/mob/living/simple_animal/hostile/abnormality/dinner_chair/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time)
	. = ..()
	// Handle Repression work - rescue trapped employees
	if(work_type == ABNORMALITY_WORK_REPRESSION)
		if(LAZYLEN(trapped_employees))
			var/mob/living/carbon/human/rescued = pick(trapped_employees)
			RescueFromBackrooms(rescued)
			to_chat(user, span_notice("You manage to pull [rescued] back from that strange place!"))
		else
			to_chat(user, span_notice("There's no one to rescue."))
		return

	// Handle Insight work - increase Qliphoth counter
	if(work_type == ABNORMALITY_WORK_INSIGHT)
		datum_reference.qliphoth_change(2)
		to_chat(user, span_notice("The chair seems more stable now."))
		return

	// All other work types decrease Qliphoth counter
	datum_reference.qliphoth_change(-1)

/mob/living/simple_animal/hostile/abnormality/dinner_chair/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	// 70% chance to send to backrooms on bad work (except Repression)
	if(work_type != ABNORMALITY_WORK_REPRESSION && prob(70))
		SendToBackrooms(user)

/mob/living/simple_animal/hostile/abnormality/dinner_chair/proc/SendToBackrooms(mob/living/carbon/human/H)
	if(!H || (H in trapped_employees))
		return

	trapped_employees += H
	original_locations[H] = get_turf(H)

	to_chat(H, span_userdanger("You suddenly feel yourself falling through the chair..."))
	to_chat(H, span_warning("You find yourself in a space between realities. The walls are yellow and damp, the carpet is moldy and endless."))
	to_chat(H, span_warning("You can hear a faint buzzing of fluorescent lights that shouldn't exist here."))

	playsound(get_turf(H), 'sound/effects/podwoosh.ogg', 50, TRUE)

	// Pick a random backrooms location
	var/turf/destination = pick(backrooms_locations)
	H.forceMove(destination)

	H.Stun(30)
	H.adjustSanityLoss(20)

	// Apply backrooms status effect
	var/datum/status_effect/backrooms_ambience/B = H.apply_status_effect(/datum/status_effect/backrooms_ambience)
	if(B)
		backrooms_effects[H] = B

/mob/living/simple_animal/hostile/abnormality/dinner_chair/proc/RescueFromBackrooms(mob/living/carbon/human/H)
	if(!H || !(H in trapped_employees))
		return

	trapped_employees -= H
	var/turf/return_turf = original_locations[H]
	if(!return_turf)
		return_turf = get_turf(src)

	original_locations -= H

	// Remove status effect
	if(backrooms_effects[H])
		H.remove_status_effect(/datum/status_effect/backrooms_ambience)
		backrooms_effects -= H

	to_chat(H, span_nicegreen("You feel a pull back to reality!"))
	playsound(get_turf(H), 'sound/magic/teleport_app.ogg', 50, TRUE)

	H.forceMove(return_turf)

/mob/living/simple_animal/hostile/abnormality/dinner_chair/ZeroQliphoth(mob/living/carbon/human/user)
	var/list/potential_victims = list()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.z != z)
			continue
		if(H.stat == DEAD)
			continue
		if(H in trapped_employees)
			continue
		if(!H.mind)
			continue
		potential_victims += H

	if(!LAZYLEN(potential_victims))
		return

	var/victims_count = min(rand(1, 3), LAZYLEN(potential_victims))

	for(var/i in 1 to victims_count)
		if(!LAZYLEN(potential_victims))
			break
		var/mob/living/carbon/human/victim = pick_n_take(potential_victims)
		SendToBackrooms(victim)
		to_chat(victim, span_userdanger("The chair has claimed you!"))

	visible_message(span_danger("[src] seems to shimmer with an otherworldly energy before returning to normal."))
	datum_reference.qliphoth_change(3)

/mob/living/simple_animal/hostile/abnormality/dinner_chair/Destroy()
	for(var/mob/living/carbon/human/H in trapped_employees)
		RescueFromBackrooms(H)
	return ..()

/mob/living/simple_animal/hostile/abnormality/dinner_chair/death(gibbed)
	for(var/mob/living/carbon/human/H in trapped_employees)
		RescueFromBackrooms(H)
		to_chat(H, span_notice("With the chair destroyed, you are freed from that liminal space."))
	density = FALSE
	animate(src, alpha = 0, time = 5 SECONDS)
	QDEL_IN(src, 5 SECONDS)
	..()

// Backrooms landmark for mapping
/obj/effect/landmark/backrooms_spawn
	name = "backrooms spawn"
	icon_state = "x2"

/area/fishboat/backrooms
	name = "???"

// Status effect for ambient backrooms audio
/datum/status_effect/backrooms_ambience
	id = "backrooms_ambience"
	duration = -1 // Permanent until removed
	alert_type = null
	var/next_sound_time = 0

/datum/status_effect/backrooms_ambience/tick()
	if(world.time >= next_sound_time)
		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			H.playsound_local(get_turf(H), 'sound/ambience/VoidsEmbrace.ogg', 50, FALSE, pressure_affected = FALSE)
			to_chat(H, span_warning("You hear something in the distance... or is it right behind you?"))
		// Next sound in 5-10 minutes (converted to deciseconds)
		next_sound_time = world.time + rand(3000, 6000) // 300-600 seconds = 5-10 minutes

/datum/status_effect/backrooms_ambience/on_apply()
	. = ..()
	// Play the sound immediately when first applied
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.playsound_local(get_turf(H), 'sound/ambience/VoidsEmbrace.ogg', 50, FALSE, pressure_affected = FALSE)
	next_sound_time = world.time + rand(3000, 6000)
